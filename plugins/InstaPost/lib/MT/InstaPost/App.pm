package MT::InstaPost::App;

use strict;
use base qw( MT::App );
use MT::InstaPost::Util;
use MT::InstaPost::Subscription::Handler;

sub id {'insta_post'}

sub init {
    my $app = shift;
    $app->SUPER::init(@_) or return;
    $app->set_no_cache;
    $app->{default_mode} = 'subscription_callback';
    $app;
}

sub core_methods {
    { subscription_callback => \&subscription_callback };
}

sub subscription_callback {
    my ( $app ) = @_;

    my ( $code, $message, $response );
    if ( uc($app->request_method) eq 'GET' ) {
        ( $code, $message, $response ) = _callback_hub_charenge(@_);
    } else {
        ( $code, $message, $response ) = _post_image(@_);
    }

    $app->{no_print_body} = 1;
    $app->response_code("$code $message");
    $app->send_http_header('text/plain');
    $app->print_encode($response);
}

sub _callback_hub_charenge {
    my ( $app ) = @_;
    my $config = plugin_config(0);
    my %hash = $app->param_hash;

    # Basicly hide for security reason
    my $code = 404;
    my $message = 'Not Found';
    my $response = 'Not Found';

    # Verify client by callback with verify_token
    eval {
        if ( $hash{'hub.mode'} eq 'subscribe' ) {
            if ( $hash{'hub.verify_token'} eq $config->{ip_verify_token} ) {
                $code = 200;
                $message = 'OK';
                $response = $hash{'hub.challenge'};
            }
        }
    };

    ( $code, $message, $response );
}

sub _post_image {
    my ( $app ) = @_;
    my $q = $app->param;

    my $json = $q->param('POSTDATA');
    my $res = MT::InstaPost::Subscription::Handler->subscribe($app, $json)
        or debug_log($app->errstr);

    ( 200, 'OK', '' );
}

1;
