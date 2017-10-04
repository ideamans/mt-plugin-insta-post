package MT::InstaPost::CMS;

use utf8;
use strict;

use URI;
use MT::Util qw(perl_sha1_digest_hex);
use MT::InstaPost::Util;
use MT::InstaPost::Util::Instagram;
use MT::InstaPost::Subscription::Handler;

sub menus {
    # Menus
    my $reg = {
        'settings:insta_post' => {
            label => 'Instagram Posting',
            order => 3000,
            mode => 'cfg_insta_post',
            permit_action => 'create_post',
            view => [ MT->version_number >= 6 ? qw/website blog/ : qw/blog/ ],
            condition => sub {
                my $app = MT->instance;
                my $user = $app->user or return 0;
                return 1 if $user->permissions(0)->can_do('administer');
                my $config = plugin_config(0);
                $config->{ip_subscription_id} ? 1 : 0;
            },
        },
    };

    $reg;
}

sub web_service_template {
    my $app = MT->instance;

    # Only on system scope
    return '' if $app->blog;

    my $config = plugin_config(0);
    if ( my $client_id = $config->{ip_client_id} ) {

        # Are there already authorized users to this client?
        $config->{ip_linkages} = MT->model('author.insta_post')->count({
            ip_client_id => $client_id,
        });
    }

    # Callback URL
    $config->{ip_redirect_uri} = oauth2_callback_uri;

    # Unreachable?
    $config->{reachable_url} = 1 if $config->{ip_redirect_uri} =~ m!^https?://!i;

    # Subscription handlers
    $config->{ip_subscription_handlers} = [ map {
        { key => $_->id, label => $_->label, selected => ( $config->{ip_default_subscription_handler} eq $_->id )? 1: 0 }
    } MT::InstaPost::Subscription::Handler->all ];

    # Build template
    my $tmpl = plugin->load_tmpl( 'config.tmpl', $config );
    $tmpl->build;
}

sub save_web_service_config {
    my ( $eh, $app ) = @_;
    my %hash = $app->param_hash;

    my $config = plugin_config(0);
    my $client_id = $hash{ip_client_id};
    my $client_secret = $hash{ip_client_secret};

    # Need requesting subscription if entered client_id is defferent from config
    my $resubscribe = ( $config->{ip_client_id} || '' ) ne $client_id ? 1 : 0;

    # Reset last error and save default handler anyway
    plugin_config( 0, {
        ip_last_error => '',
        ip_default_subscription_handler => $hash{ip_default_subscription_handler} || 'simple_post',
    } );

    # Check input values
    if ( ( $client_id and !$client_secret ) or ( !$client_id and $client_secret ) ) {
        plugin_config( 0, { ip_last_error => plugin->translate('Both of client id and client secret required.') });
        return;
    }

    if ( $resubscribe and !$client_id ) {
        plugin_config( 0, { ip_last_error => plugin->translate('Client id is empty.') });
        return;
    }

    # Request new subscribe if client_id and secret passed and changed
    if ( $client_id && ( !$config->{ip_subscription_id} || $resubscribe ) ) {

        # Generate SHA1 random hash as verify token and save settings once
        my $verify_token = perl_sha1_digest_hex;
        plugin_config( 0, {
            ip_client_id => $client_id,
            ip_client_secret => $client_secret,
            ip_verify_token => $verify_token,
        } );

        my $config = plugin_config(0);

        # Request new subscription
        # The server calling back within the request to mt-insta-post.cgi
        if ( my $subscription_id = new_subscribe( $eh, $app ) ) {

            # Success! Save subscription id
            plugin_config( 0, { ip_subscription_id => $subscription_id } );
        } elsif ( my $error = $eh->errstr ) {

            # Error
            plugin_config( 0, { ip_last_error => $error } );
        }
    }

    1;
}

sub cfg_insta_post {
    my ( $app ) = @_;
    my $q = $app->param;

    # Require blog
    my $blog = $app->blog or $app->return_to_dashboard( redirect => 1 );

    # TODO permission check

    my $config = plugin_config(0);
    $app->user->uncache_object;
    my $author = MT->model('author.insta_post')->load($app->user->id);

    #$author = bless $author, MT->model('author.insta_post');
    #$author = MT->model('author.insta_post')->load($author->id);

    my %param;
    foreach my $prop ( qw/ip_user_id ip_client_id ip_blog_id ip_access_token/ ) {
        $param{$prop} = $author->$prop;
    }

    # Administer?
    # TODO rewrite to can_do
    $param{is_administer} = $author->permissions(0)->can_do('administer');
    $param{cfg_web_services_uri} = $app->mt_uri( mode => 'cfg_web_services', args => { blog_id => 0 } );

    # State
    $param{state} = 'not_setup';
    $param{$_} = 0 foreach qw/setup authorized this_client this_blog/;

    if ( my $subscription_id = $config->{ip_subscription_id} ) {
        $param{setup} = 1;

        # Auth url
        my $client_id = $config->{ip_client_id};
        my $callback_uri = oauth2_callback_uri($blog->id);
        my $oauth2_uri = URI->new('https://api.instagram.com/oauth/authorize/');
        $oauth2_uri->query_form({
            client_id => $config->{ip_client_id},
            redirect_uri => $callback_uri,
            response_type => 'code',
            scope => 'basic',
        });
        $param{oauth2_uri} = $oauth2_uri->as_string;

        # Current state
        if ( $author->ip_subscription_id ) {
            $param{authorized} = 1;
            $param{ip_username} = $author->ip_config->{username} || plugin->translate('Unknown User');
            $param{remove_uri} = $app->mt_uri( mode => 'remove_cfg_insta_post', args => { blog_id => $blog->id } );

            # Already authorized
            if ( $subscription_id eq $author->ip_subscription_id ) {
                $param{this_subscription} = 1;

                if ( !$author->ip_blog_id ) {

                    # Authorized but linked not yet
                    $param{state} = 'ready';

                } elsif ( $blog->id == $author->ip_blog_id ) {

                    # Authorized about this blog
                    $param{state} = 'ready';
                    $param{this_blog} = 1;

                    # Configurable
                    # Subscription handlers
                    $param{ip_subscription_handlers} = [ map {
                        my $config_param = $_->config_param;

                        {
                            key => $_->id,
                            label => $_->label,
                            selected => ( $author->ip_subscription_handler eq $_->id ) ? 1: 0,
                            config_template => $_->config_template,
                            %$config_param,
                        }
                    } MT::InstaPost::Subscription::Handler->all($author) ];

                } else {

                    # Authorized but not this blog
                    $param{state} = 'different_blog';

                    if ( my $current = MT->model('blog')->load($author->ip_blog_id) ) {
                        $param{current_blog} = $current->name;
                        $param{current_blog_link} = $app->mt_uri( mode => 'cfg_insta_post', args => {
                            blog_id => $current->id,
                        });
                    } else {
                        $param{current_blog} = plugin->translate('Unknown blog');
                    }
                }
            } else {
                $param{state} = 'different_subscription';
            }
        } else {

            # Not authorized
            $param{state} = 'not_authorized';
        }
    } else {

        # Not ready as system
    }

    # Messages
    foreach my $k ( qw/saved removed authorized error/ ) {
        $param{$k} = $q->param($k);
    }

    plugin->load_tmpl('cfg_insta_post.tmpl', \%param);
}

sub save_cfg_insta_post {
    my ( $app ) = @_;
    my $q = $app->param;
    my $blog = $app->blog or return $app->translate('Invalid request');

    $app->user->uncache_object;
    my $author = MT->model('author.insta_post')->load($app->user->id);

    # Save config json
    if ( my $sh = $q->param('subscription_handler') ) {
        $author->ip_subscription_handler($sh);

        my %config;
        my %hash = $app->param_hash;
        foreach my $k ( keys %hash ) {
            $config{$k} = $hash{$k} if $k =~ /^ip_/;
        }

        $author->ip_config( sub {
            my $json = shift;
            $json->{$_} = $config{$_} foreach keys %config;
        });

        $author->save;
    }

    # Redirect to saved
    $app->redirect( $app->uri( mode => 'cfg_insta_post', args => {
        blog_id => $blog->id,
        saved => 1,
    } ) );
}

sub remove_cfg_insta_post {
    my ( $app ) = @_;

    # Require blog
    my $blog = $app->blog or return $app->translate('Invalid request');

    $app->user->uncache_object;
    my $author = MT->model('author.insta_post')->load($app->user->id);

    $author->ip_user_id(0);
    $author->ip_blog_id(0);
    $author->ip_client_id('');
    $author->ip_subscription_id('');
    $author->ip_access_token('');
    $author->ip_config( {} );
    $author->save;

    # Redirect to saved
    $app->redirect( $app->uri( mode => 'cfg_insta_post', args => {
        blog_id => $blog->id,
        removed => 1,
    } ) );
}

sub oauth2_callback {
    my ( $app ) = @_;
    my $blog = $app->blog;
    my $q = $app->param;
    my $config = plugin_config(0);
    my $author = $app->user;
    $author = bless $author, MT->model('author.insta_post');

    my $redirector = sub {
        $app->redirect($app->uri( mode => 'cfg_insta_post', args => {
            blog_id => $blog->id,
            @_
        } ));
    };

    my $code = $q->param('code')
        or return $redirector->( error => plugin->translate('Redirection not passed code.') );

    my $auth = access_token($app, $blog->id, $code)
        or return $redirector->( error => $app->errstr );

    $author->ip_user_id($auth->{user}->{id});
    $author->ip_blog_id($blog->id);
    $author->ip_client_id($config->{ip_client_id});
    $author->ip_subscription_id($config->{ip_subscription_id});
    $author->ip_access_token($auth->{access_token});

    $author->ip_config( sub {
        shift->{username} = $auth->{user}->{username};
    } );

    $author->save;

    $redirector->( authorized => 1);
}

1;