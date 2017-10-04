package MT::InstaPost::Util::Instagram;

use strict;
use warnings;
use base qw( Exporter );
use MT::InstaPost::Util;
use URI;
use HTTP::Request::Common;

our @EXPORT = qw(
    oauth2_callback_uri new_subscribe access_token lookup_media
);

sub API {
    my ( $req, %args ) = @_;
    my $default = $args{default};

    # Setup user agent
    my $ua = MT->new_ua;
    my $setup = $args{setup};
    $setup->($ua) if $setup;

    # Request HTTP
    my $res = $ua->request($req);
    my $rcontent = $args{content};
    $$rcontent = $res->content if $rcontent;

    # Parse response expecting JSON HASH
    $args{ref} ||= 'HASH';
    my $json = parse_json($res->content, %args);
    my $eh = $args{eh};

    # Handle error if response is not success or has error_message
    if ( my $message = eval { $json->{meta}->{error_message} } ) {
        $eh->error(plugin->translate('API response has an error: [_1]. Status line: [_2]', $message, $res->status_line)) if $eh;
        return $default;
    } elsif ( !$res->is_success ) {
        $eh->error(plugin->translate('API response has an error status: [_1]. Response: [_2]', $res->status_line, $res->content)) if $eh;
        return $default;
    }

    $json;
}

sub oauth2_callback_uri {
    my ( $blog_id ) = @_;
    my $app = MT->instance;

    # Build OAuth2 callback URI
    $app->base . $app->uri(
        mode => 'ip_oauth2_callback',
        args => { $blog_id ? ( blog_id => $blog_id ) : () }
    );
}

sub new_subscribe {
    my ( $eh, $app ) = @_;
    my $config = plugin_config(0);

    my $ua = MT->new_ua;
    my $url = 'https://api.instagram.com/v1/subscriptions/';
    my $callback_url;
    {
        local $app->{is_admin} = 0;
        $callback_url = $app->base . $app->mt_path;
        $callback_url .= '/' if $callback_url !~ m!/$!;
        $callback_url .= $app->config('InstaPostScript');
    }

    # Call API to create subscription
    my $content;
    my $json = API( POST($url, {
        client_id => $config->{ip_client_id},
        client_secret => $config->{ip_client_secret},
        object => 'user',
        aspect => 'media',
        verify_token => $config->{ip_verify_token},
        callback_url => $callback_url,
    }), eh => $eh, content => \$content ) or return;

    my $subscription_id = eval { $json->{data}->{id} }
        or return $eh->error( plugin->translate('API resposne seems good, but can not get subscription Id: [_1]', $content) );

    $subscription_id;
}

sub access_token {
    my ( $eh, $blog_id, $code ) = @_;
    my $config = plugin_config(0);

    # Call API to get access token
    my $content;
    my $json = API( POST('https://api.instagram.com/oauth/access_token', {
        client_id => $config->{ip_client_id},
        client_secret => $config->{ip_client_secret},
        grant_type => 'authorization_code',
        redirect_uri => oauth2_callback_uri($blog_id),
        code => $code,
    }), eh => $eh, content => \$content ) or return;

    # Check response: requires access_token, user id, username
    unless ( my $token = $json->{access_token} ) {
        $eh->error(plugin->translate('Cannot get access_token: [_1]', $content)) if $eh;
        return;
    }

    my $user;
    unless ( $user = $json->{user} ) {
        $eh->error(plugin->translate('Cannot get user information: [_1]', $content)) if $eh;
        return;
    }

    unless ( my $user_id = $user->{id} ) {
        $eh->error(plugin->translate('Cannot get user id: [_1]', $content)) if $eh;
        return;
    }

    unless ( my $user_name = $user->{username} ) {
        $eh->error(plugin->translate('Cannot get user name: [_1]', $content)) if $eh;
        return;
    }

    $json;
}

sub lookup_media {
    my ( $eh, $media_id, $token ) = @_;

    my $url = "https://api.instagram.com/v1/media/$media_id?access_token=$token";
    my $json = API( GET($url), eh => $eh ) or return;

    $json;
}

1;
