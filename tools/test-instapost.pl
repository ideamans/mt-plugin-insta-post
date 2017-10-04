#!/usr/bin/perl
package MT::InstaPost::Test;
use strict;
use warnings;
use FindBin;
use lib ("$FindBin::Bin/../lib", "$FindBin::Bin/../extlib");
use Test::More;

use MT;
use base qw( MT::Tool );

my $VERSION = 0.1;
sub version { $VERSION }

sub help {
    return <<'HELP';
OPTIONS:
    -h, --help             shows this help.
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

    use_ok('MT::InstaPost::L10N::en_us');
    use_ok('MT::InstaPost::L10N::ja');
    use_ok('MT::InstaPost::Subscription::Handler');
    use_ok('MT::InstaPost::Subscription::Notification');
    use_ok('MT::InstaPost::Subscription::Handler::SimplePost');
    use_ok('MT::InstaPost::App');
    use_ok('MT::InstaPost::Author');
    use_ok('MT::InstaPost::CMS');
    use_ok('MT::InstaPost::L10N');
    use_ok('MT::InstaPost::Util');
}

__PACKAGE__->main() unless caller;

done_testing();


