package MT::InstaPost::Author;

use strict;
use base qw( MT::Author );

use MT::Util;
use MT::InstaPost::Util;
use MT::InstaPost::Subscription::Handler;

__PACKAGE__->install_properties(
    {   column_defs => {
            'ip_user_id'           => 'integer',
            'ip_blog_id'           => 'integer',
            'ip_client_id'         => 'string(255)',
            'ip_subscription_id'   => 'string(255)',
            'ip_access_token'      => 'string(255)',
            'ip_subscription_handler'
                                   => 'string(128)',
            'ip_config_json'       => 'text',
        },
        indexes => {
            ip_user_id => 1,
            ip_subscription_id => 1,
            ip_client_id => 1,
        },
        datasource => 'author',
        class_type => 'author',
    }
);

sub ip_config {
    my $self = shift;
    my ( $arg ) = @_;

    my $json = {};
    eval {
        $json = MT::Util::from_json($self->ip_config_json);
    };

    if ( defined $arg ) {
        if ( ref $arg eq 'CODE' ) {
            $arg->( $json );
        } elsif ( ref $arg eq 'HASH' ) {
            $json = $arg;
        }
        $self->ip_config_json( MT::Util::to_json($json) );
    }

    $json;
}

1;