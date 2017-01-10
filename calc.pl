#!/usr/bin/env perl

use strict;
use warnings;

=head1 NAME

calc.pl - Simple perl REPL calculator

=head1 SYNOPSIS

    $ calc.pl
    calc> 2 * pi
    6.2831852
    calc> @ * 10
    62.831852
    calc> $5,300.27 * 2.03
    $10,759.5481

=head1 DESCRIPTION

Based upon the sample code from https://metacpan.org/pod/Term::ReadLine

To get readline working properly on OSX, I installed Term::ReadLine::Gnu
following the instructions from
L<http://blogs.perl.org/users/aristotle/2013/07/easy-osx-termreadlinegnu.html>

Readline is already installed, but the Makefile doesn't pick it up, so make
homebrew install some temporary symlinks.

    dave> brew install readline
    dave> brew link --force readline
    dave> sudo su -
    root> cpan Term::ReadLine::Gnu
    root> exit
    dave> brew unlink readline

Also needs the non-core File::HomeDir for storing the history file.

=cut

use File::HomeDir;
use POSIX ();
use Term::ReadLine;

my $hist_file = File::Spec->catfile(File::HomeDir::home, '.calc_history');
my $term = Term::ReadLine->new('Simple Perl calc');
$term->ReadHistory($hist_file);
$term->Attribs->{MinLength} = 0; # Turns off history adding in readline() call.

# Ensure that we write the history file even if the script dies or after Ctrl-c.
# See read_line() below for info about the signal work needed.
$SIG{INT} = $SIG{TERM} = $SIG{HUP} = sub { exit };

my $prompt = "calc> ";
my $OUT = $term->OUT || \*STDOUT;
my $prev_line = '';
if ( my @hist = $term->history_list() ) {
    $prev_line = $hist[-1];
}
my $prev_res = '';
my $line = @ARGV ? join(' ', @ARGV) : read_line($prompt);
while ( defined $line ) {
    last unless defined $line;    # Handle Crtl-d.
    if ( $line =~ m{\S}xms ) {
        my ( $processed, $meta ) = process_line( $line, $prev_line, $prev_res );
        my $res = eval($processed);
        if ($@) {
            warn $@;
        }
        else {
            if ( $meta->{currency} && $res =~ m{ \A [\d.-]+ \d }xms ) {
                $res = commify($res);
                $res =~ s{ (\d) }{$meta->{currency}$1}xms;
            }
            print $OUT $res, "\n";
        }
        $term->addhistory($line) unless $line eq $prev_line;
        $prev_line = $line;
        $prev_res  = $res;
    }
    $line = read_line($prompt);
}
exit;

END {
    $term->WriteHistory($hist_file);
    print "\n";
}

#
# Subroutines.
#

# Wrapper around readline() to allow signals to work without needing to hit enter.
# http://mail.pm.org/pipermail/melbourne-pm/2007-January/002214.html
sub read_line {
    my $prompt = shift;

    sub unsafe_signals {
        $term->free_line_state; # Just give readline a chance to cleanup after itself.
        $term->cleanup_after_signal;
        exit;
    }

    my $sigset     = POSIX::SigSet->new();
    my $sigaction  = POSIX::SigAction->new( \&unsafe_signals, $sigset, 0 );
    my $old_action = POSIX::SigAction->new;

    # Set up our unsafe signal handler.
    POSIX::sigaction( &POSIX::SIGINT, $sigaction, $old_action );    # Save the default one.
    POSIX::sigaction( &POSIX::SIGHUP, $sigaction );
    POSIX::sigaction( &POSIX::SIGTERM, $sigaction );

    my $line = $term->readline($prompt);

    # Restore the real signal handler.
    POSIX::sigaction( &POSIX::SIGINT,  $old_action );
    POSIX::sigaction( &POSIX::SIGHUP,  $old_action );
    POSIX::sigaction( &POSIX::SIGTERM, $old_action );

    return $line;
}


# Apply transforms to the input to make the calc more useful (but less
# general-purpose).
sub process_line {
    my $line      = shift;
    my $prev_line = shift;
    my $prev_res  = shift;

    my $meta;

    $line =~ s{[@]}{$prev_res}gixms;

    my $pi = 3.1415926;
    $line =~ s{\bpi\b}{$pi}gixms;

    # Handle currency.
    if ( $line =~ m{ ([£\$]) }xms ) {
        $meta->{currency} = $1 eq '$' ? '$' : '£'; # Something was weird if I just set it to $1 here. Unicode!
    }
    $line =~ s{ [\$£,] }{}xmsg;

    # Treat x as *.
    $line =~ s{x}{*}xmsg;

    return ($line, $meta);
}

# Add thousands separator to numbers.
# http://www.perlmonks.org/?node_id=2145
sub commify {
    local $_ = shift;
    s{(?<!\d|\.)(\d{4,})}{my $n = $1; $n=~s/(?<=.)(?=(?:.{3})+$)/,/g; $n; }eg;
    return $_;
}

__END__

=head1 LICENSE

This script is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

=cut
