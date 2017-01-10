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

Also needs the non-core File::HomeDir.

=cut

use File::HomeDir;
use Term::ReadLine;

my $hist_file = File::Spec->catfile(File::HomeDir::home, '.calc_history');
my $term = Term::ReadLine->new('Simple Perl calc');
$term->ReadHistory($hist_file);
$term->Attribs->{MinLength} = 0; # Turns off history adding in readline() call.

# Ensure that we write the history file even when the script dies or is
# Ctrl-c-d.
# http://mail.pm.org/pipermail/melbourne-pm/2007-January/002214.html
$SIG{INT} = $SIG{TERM} = sub { $term->WriteHistory($hist_file); $term->free_line_state; $term->cleanup_after_signal; print "\n"; exit };
my $prompt = "calc> ";
my $OUT = $term->OUT || \*STDOUT;
my $prev_line = '';
my $prev_res = '';
my $line = @ARGV ? join(' ', @ARGV) : $term->readline($prompt);
while ( defined $line ) {
    last unless defined $line; # Handle Crtl-d.
    if ( $line =~ m{\S}xms ) {
        my ($processed, $meta) = process_line($line, $prev_line, $prev_res);
        my $res = eval($processed);
        if ( $@ ) {
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
        $prev_res = $res;
    }
    $line = $term->readline($prompt);
}
print "\n";
$term->WriteHistory($hist_file);
exit;


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
        $meta->{currency} = $1 eq '$' ? '$' : '£';
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
