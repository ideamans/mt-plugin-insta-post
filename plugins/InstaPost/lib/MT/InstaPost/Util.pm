package MT::InstaPost::Util;

use utf8;
use strict;
use base qw(Exporter);
use Carp qw(confess);
use URI;
use HTTP::Request::Common;
use MT::Util;
use MT::Log;
use Data::Dumper;

our @EXPORT = qw(_dumper plugin plugin_config parse_json
    send_mail debug_log
);

sub _dumper {
    print STDERR Dumper($_) foreach @_;
}

sub plugin { MT->component('InstaPost') }

sub plugin_config {

    # Get or set config hash
    my ( $blog_id, $arg, @args ) = @_;
    my $scope = $blog_id ? "blog:$blog_id" : 'system';

    my %config;
    plugin->load_config(\%config, $scope);

    # If passed arg:
    if ( $arg ) {

        if ( ref $arg eq 'CODE' ) {

            # Run the CODE
            $arg->(\%config);
        } elsif ( ref $arg eq 'ARRAY' ) {

            # Override keys in array with last hash
            my $hash = shift @args;
            if ( ref $hash eq 'HASH' ) {
                $config{$_} = $hash->{$_} foreach @$arg;
            }
        } elsif ( ref $arg eq 'HASH' ) {

            # Override as a hash
            foreach my $k ( keys %$arg ) {
                $config{$k} = $arg->{$k};
            }
        }
        plugin->save_config(\%config, $scope);
    }

    \%config;
}

sub parse_json {
    my ( $json, %args ) = @_;
    my $eh = $args{eh};
    my $default = $args{default};
    my $ref = $args{ref};

    # Check if the JSON is string
    if ( !ref $json ) {
        $json = eval { $json = MT::Util::from_json($json) };

        # Parse error
        if ( !$json ) {
            $eh->error(plugin->translate('Bad format JSON: [_1]: [_2]', $@, $json)) if $eh;
            return $default;
        }
    }

    # Expected type?
    if ( $ref && ref $json ne $ref ) {
        $eh->error(plugin->translate('The JSON has unexpected type. Expected [_1] but [_2]: [_3]', $ref, ref $json, $json))
            if $eh;
        return $default;
    }

    $json;
}

sub send_mail {
    my $send_to = shift;

    # Send to each if send_to is an array
    if ( ref $send_to eq 'ARRAY' ) {
        foreach my $to ( @$send_to ) {
            send_mail( $to, @_ );
        }
        return 1;
    }

    my ( $subject, $template, $param ) = @_;
    my $app = MT->instance;

    # Return if silent and not forced.
    return if $app->config('InstaPostMailSilent') and !$param->{force};

    require MT::Mail;

    # Check From and Reply To address
    my $from_addr;
    my $reply_to;
    if ( $app->config->EmailReplyTo ) {
        $reply_to = $app->config->EmailAddressMain;
    }
    else {
        $from_addr = $app->config->EmailAddressMain;
    }
    $from_addr = undef if $from_addr && !MT::Util::is_valid_email($from_addr);
    $reply_to  = undef if $reply_to  && !MT::Util::is_valid_email($reply_to);

    unless ( $from_addr || $reply_to ) {
        $app->log(
            {   message =>
                    MT->translate("System Email Address is not configured."),
                level    => MT::Log::ERROR(),
                class    => 'system',
                category => 'email'
            }
        );
        return;
    }

    # Detect and check To address
    my $to_addr;
    if ( !ref $send_to ) {
        $to_addr = $send_to;
    } elsif ( UNIVERSAL::isa( $send_to, 'MT::Author' ) ) {
        $to_addr = $send_to->email;
    }

    unless ( MT::Util::is_valid_email($to_addr) ) {
        $app->log(
            {   message =>
                    plugin->translate("Invalid email address to send: [_1]"),
                level    => MT::Log::ERROR(),
                class    => 'system',
                category => 'email'
            }
        );
        return;
    }

    # Build the template.
    my $body = $app->build_email( $template, $param );

    # If subject is empty use the first line as subject
    ( $subject, $body ) = split(/\n/, $body, 2) unless defined $subject;

    # Email header
    my %head = (
        To => $to_addr,
        $from_addr ? ( From       => $from_addr ) : (),
        $reply_to  ? ( 'Reply-To' => $reply_to )  : (),
        Subject => $subject,
    );

    # Send email
    my $charset = $app->config->MailEncoding || $app->config->PublishCharset;
    $head{'Content-Type'} = qq(text/plain; charset="$charset");
    MT::Mail->send( \%head, $body );
}

# Debug log helper
my %LOG_LEVELS = (
    info => MT::Log::INFO(),
    warning => MT::Log::WARNING(),
    error => MT::Log::ERROR(),
    security => MT::Log::SECURITY(),
    debug => MT::Log::DEBUG(),
);

sub debug_log {
    my ( $msg, %args ) = @_;
    return unless $MT::DebugMode;
    $msg or return;

    _dumper($msg) if MT->instance->config('STDERR');

    $args{level} = $LOG_LEVELS{$args{level}}
        if $args{level} && $LOG_LEVELS{$args{level}};

    MT->instance->log(
        {
            message  => $msg,
            level    => $args{level} || MT::Log::DEBUG(),
            class    => $args{class} || 'plugin',
            category => $args{category} || 'InstaPost'
        }
    );
}

1;