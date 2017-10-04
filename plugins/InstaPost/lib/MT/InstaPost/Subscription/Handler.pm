package MT::InstaPost::Subscription::Handler;

use strict;

use Carp qw(confess);
use MT::Util;
use MT::InstaPost::Util;
use MT::InstaPost::Subscription::Notification;
use base qw( MT::ErrorHandler );

sub subscribe {
    my $pkg = shift;
    my ( $eh, $json ) = @_;

    my $ctx = {};
    my $app = $ctx->{app} = MT->instance;

    my $hashes = $ctx->{subscription_hashes} = parse_json( $json, error_handler => $eh, ref => 'ARRAY' )
        or return;

    $app->run_callbacks('ip_received_subscription', $pkg, $eh, $hashes);

    my %duplication;
    foreach my $hash ( @$hashes ) {

        $ctx->{subscription_hash} = $hash;

        my $notify = MT::InstaPost::Subscription::Notification->new($hash);
        $ctx->{notify} = $notify;

        # TODO callback to skip verify
        unless ( $notify->verify ) {
            debug_log($notify->errstr);
            next;
        }

        # TODO callback to lookup media
        foreach my $author ( $notify->authors ) {

            $ctx->{author} = $author;

            my $handler = $ctx->{handler} = $pkg->produce($author->ip_subscription_handler, $author, $ctx);
            unless ( $handler->handle_subscription( $notify, $ctx ) ) {

                # Mail?
                debug_log($handler->errstr) if $handler->errstr;
                next;
            }
        }
    }

    1;
}

sub produce {
    my $pkg = shift;
    my $key = shift;
    my $author = shift;

    # Produce handler object
    my $handlers = MT->registry(qw/insta_post subscription_handlers/)
        or return;
    my $handler = $handlers->{$key};

    my $label = $handler->{label} or next;
    my $package = $handler->{package} or next;
    eval qq{require $package} or next;

    my $object = $package->new(
        id => $key,
        registry => $handler,
        plugin => $handler->{plugin},
        label => $label,
        default_config => $pkg->load_default_config,
        author => $author,
    );

    $object;
}

sub load_default_config {
    my $pkg = shift;
    if ( @_ ) {
        my $json = shift;
        $json = MT::Util::to_json($json) if ref $json;
        $json ||= {};
        plugin_config( 0, {
            ip_default_subscription_handler_config_json => $json,
        });
    } else {
        my $config = plugin_config(0);
        my $json = {};
        eval {
            $json = MT::Util::from_json($config->{ip_default_subscription_handler_config_json});
        };
        $json;
    }
}

sub all {
    my $pkg = shift;

    my $handlers = MT->registry(qw/insta_post subscription_handlers/);
    die 'No handlers' if ref $handlers ne 'HASH';

    my @handlers = sort {
        $a->order <=> $b->order
    } map {
        $pkg->produce($_, @_);
    } keys %$handlers;

    @handlers;
}

sub new {
    my $pkg = shift;
    my %config = @_;

    my $self = $pkg->SUPER::new(@_);
    $self->{$_} = $config{$_} foreach keys %config;

    $self;
}

sub id {
    my $self = shift;
    $self->{id} = $_[0] if @_;
    $self->{id};
}

sub order { shift->{registry}->{order} || 1000 }

sub condition { 1 }

sub label {
    my $self = shift;
    $self->{label} = $_[0] if @_;
    $self->{label};
}

sub author {
    my $self = shift;
    $self->{author} = $_[0] if @_;
    $self->{author};
}

sub author_config {
    my $self = shift;
    my $key = shift;

    my $author = $self->{author} or return {};
    $self->{author_config} = $author->ip_config || {}
        unless defined $self->{author_config};

    $key ? $self->{author_config}->{$key} : %{$self->{author_config}};
}

sub default_config {
    my $self = shift;
    my $key = shift;

    $self->{default_config} = {}
        unless defined $self->{default_config};

    $key ? $self->{default_config}->{$key} : %{$self->{default_config}};
}

sub config_param {
    my $self = shift;
    my %author_config = $self->author_config;
    my %default_config = $self->default_config;

    foreach my $key ( keys %default_config ) {
        $author_config{$key} = $default_config{$key};
    }

    \%author_config;
}

sub config_template {
    my $self = shift;
    my $app = MT->instance;

    my $config_template = $self->{registry}{config_template} or return '';
    my $plugin = $self->{plugin} or return '';
    my $id = $plugin->{id};

    my $tmpl = qq{<mt:include name="$config_template" component="$id">};
    $app->run_callbacks('ip_subscription_handler_config_template', $self, \$tmpl);

    $tmpl;
}

sub validate_config {
    my $self = shift;
    1;
}

sub handle_common {
    my $self = shift;
    return 1;
}

sub handle_subscription {
    my $self = shift;
    my ( $notify, $ctx ) = @_;
    my $app = $ctx->{app};
    my $author = $ctx->{author};

    # Call pre hook
    $app->run_callbacks('ip_pre_handle_subscription', $self, $notify, $ctx);

    # Extract media
    my $media = $ctx->{media} = $notify->media($self->author->ip_access_token);
    unless ( $media ) {
        debug_log($notify->errstr);
        return;
    }

    # Blog and config
    my $blog_id = $ctx->{blog_id} = $author->ip_blog_id;
    my $blog = $ctx->{blog} = MT->model('blog')->load($blog_id)
        or return $self->error(plugin->translate('No blog for author setting: [_1]', $author->ip_blog_id));
    my $config = $ctx->{config} = $self->config_param;

    # Handle media
    $self->handle_media($media, $blog, $config, $ctx) or return;

    # Call post hook
    $app->run_callbacks('ip_post_handle_subscription', $self, $notify, $ctx);

    1;
}

sub handle_media {
    my $self = shift;
    my ( $media, $blog, $config, $ctx ) = @_;

    # Should be override

    1;
}

1;