package MT::InstaPost::Subscription::Handler::SimplePost;

use strict;
use base qw( MT::InstaPost::Subscription::Handler::EntryPost );
use MT::InstaPost::Util;

sub handle_entry {
    my $self = shift;
    my ( $entry, $config, $ctx ) = @_;
    my $app = $ctx->{app};
    my @send_to = ( $ctx->{author} );

    if ( $config->{ip_save_as_draft} ) {

        # Send confirm email
        send_mail( \@send_to, undef, 'ip_simple_post_email_confirm', $ctx );
    } else {

        $entry->status(MT::Entry::RELEASE());
        $entry->save or return $self->error($entry->errstr);

        # Rebuild
        $app->rebuild_entry(
            Entry             => $entry,
            BuildDependencies => 1,
            BuildIndexes      => 1
        );

        # Send complate email
        send_mail( \@send_to, undef, 'ip_simple_post_email_complete', $ctx );
    }

    1;
}

1;