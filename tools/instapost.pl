#!/usr/bin/perl
package MT::InstaPost::Tool;
use strict;
use warnings;
use FindBin;
use lib ("$FindBin::Bin/../lib", "$FindBin::Bin/../extlib");

use MT;
use base qw( MT::Tool );

my $VERSION = 0.1;
sub version { $VERSION }

sub help {
    return <<'HELP';
OPTIONS:
    -h, --help             this.
HELP
}

sub usage {
    return '[--help]';
}


## options
my ( $blog_id, $user_id, $verbose );

sub options {
    return (
    )
}

sub main {
    my $mt = MT->instance;
    my $class = shift;

    $verbose = $class->SUPER::main(@_);

    eval "use MT::InstaPost::SubscriptionHandler;";


    my $json = <<"JSON";
[{"changed_aspect": "media", "object": "user", "object_id": "957531804", "time": 1392085949, "subscription_id": 4075879, "data": {"media_id": "653186742993303469_957531804"}}]
JSON
    my $eh = MT::ErrorHandler->new;
    my $res = MT::InstaPost::SubscriptionHandler->subscribe($eh, $json);

    print STDERR $eh->errstr, "\n" unless defined $res;
}

__PACKAGE__->main() unless caller;


