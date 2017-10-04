package MT::InstaPost::Subscription::Notification;

use strict;
use base qw(MT::ErrorHandler);
use Digest::MD5;
use MT::Util;
use MT::InstaPost::Util;
use MT::InstaPost::Util::Instagram;

sub new {
    my $pkg = shift;
    my $hash = shift || {};
    my $self = $pkg->SUPER::new(@_);

    $self->{hash} = $hash;

    $self;
}

sub verify {
    my $self = shift;
    my $hash = $self->{hash};

    foreach my $key ( qw/changed_aspect object object_id subscription_id data/ ) {
        return $self->error(plugin->translate( 'Subscription notification has no [_1]', $key ))
            unless defined $hash->{$key};
    }

    return $self->error(plugin->translate('changed_aspect is not media'))
        if $hash->{changed_aspect} ne 'media';

    return $self->error(plugin->translate('object is not user'))
        if $hash->{object} ne 'user';

    return $self->error(plugin->translate('data is not hash'))
        if ref $hash->{data} ne 'HASH';

    return $self->error(plugin->translate('data has no media_id'))
        unless $hash->{data}->{media_id};

    1;
}

sub authors {
    my $self = shift;
    my $hash = $self->{hash};

    # Authors linked with current subscription
    my $terms = { ip_user_id => $hash->{object_id} };
    $terms->{ip_subscription_id} = $hash->{subscription_id} if $hash->{subscription_id};
    my @authors = MT->model('author.insta_post')->load($terms);

    @authors;
}

sub media {
    my $self = shift;
    my ( $token ) = @_;
    my $hash = $self->{hash};

    # Lookup media with API
    my $media_id = $hash->{data}->{media_id};
    lookup_media($self, $media_id, $token);
}

sub digest {
    my $self = shift;
    my $hash = $self->{hash} or return;

    my $json = MT::Util::to_json($hash) || '';
    my $digest = Digest::MD5::md5_hex($json);

    $digest;
}

1;