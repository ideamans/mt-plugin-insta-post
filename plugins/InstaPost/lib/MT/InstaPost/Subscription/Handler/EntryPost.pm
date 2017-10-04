package MT::InstaPost::Subscription::Handler::EntryPost;

use strict;
use base qw(MT::InstaPost::Subscription::Handler);
use MT::InstaPost::Util;

sub handle_media {
    my $self = shift;
    my ( $media, $blog, $config, $ctx ) = @_;
    my $app = $ctx->{app};
    my $author = $ctx->{author};

    # Check duplication
    # Because Instagram seems to send duplicate subscription sometimes...
    my $media_id = $media->{data}->{id};
    return if MT->model('entry')->exist({
        blog_id => $blog->id,
        ip_media_id => $media_id,
    });

    # Title and body from media text
    my $text = $media->{data}->{caption}->{text} || plugin->translate('Instagram');
    my ( $title, $body ) = split(/\n/, $text, 2);
    $body ||= '';
    $title =~ s/^\s*//s; $title =~ s/\s+$//s;
    $body =~ s/^\s+//s; $body =~ s/\s+$//s;
    $body = "<p>$body</p>" if length($body) > 0;

    my $permalink = $media->{data}->{link}
        or return $self->error(plugin->translate('No link in media data'));

    my $link = $permalink;
    $link =~ s!^https?://!//!;
    $link .= 'embed/';

    my $width = $app->config('InstaPostEmbedWidth') || 612;
    my $height = $app->config('InstaPostEmbedHeight') || 710;
    my $embed = qq{<iframe src="$link" width="$width" height="$height" frameborder="0" scrolling="no" allowtransparency="true"></iframe>};

    my $entry = MT->model('entry')->new;
    my $orig_entry = $entry->clone;

    $entry->set_values({
        blog_id         => $blog->id,
        author_id       => $author->id,
        created_by      => $author->id,
        allow_comments  => $blog->allow_comments_default,
        allow_pings     => $blog->allow_pings_default,
        convert_breaks  => $blog->convert_paras,
        title           => $title,
        text            => join( "\n", grep { length($_) } ($body, $embed) ),
        status          => MT::Entry::HOLD(),
        ip_media_id     => $media_id,
    });

    MT->run_callbacks( 'api_pre_save.entry', $app, $entry, $orig_entry ) or return;

    $entry->save or return $self->error($entry->errstr);

    my %merge = (
        text            => $text,
        permalink       => $permalink,
        embed_width     => $width,
        embed_height    => $height,
        embed           => $embed,
        entry           => $entry,
        orig_entry      => $orig_entry,
        entry_link      => $entry->permalink,
        edit_link       => $app->can('mt_uri') ? $app->mt_uri(mode => 'view', args => {id => $entry->id, blog_id => $blog->id}) : '',
        cfg_link        => $app->can('mt_uri') ? $app->mt_uri(mode => 'cfg_insta_post', args => {blog_id => $blog->id}) : '',
        instagram_link  => $permalink,
    );

    foreach my $k (keys %merge) {
        $ctx->{$k} = $merge{$k};
    }

    $app->run_callbacks('ip_pre_handler_common', $ctx);

    $self->handle_entry($entry, $config, $ctx) or return;

    # Callback post_save
    MT->run_callbacks( 'api_post_save.entry', $app, $entry, $orig_entry );

    $app->run_callbacks('ip_post_handler_common', $ctx);

    1;
}

1;