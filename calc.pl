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

=cut

use Term::ReadLine;

my $pi = 3.1415926;
my $term = Term::ReadLine->new('Simple Perl calc');
$term->Attribs->{MinLength} = 0; # Turns off history adding in readline() call.
my $prompt = "calc> ";
my $OUT = $term->OUT || \*STDOUT;
my $prev_line = '';
my $prev_res = '';
my $line = @ARGV ? join(' ', @ARGV) : $term->readline($prompt);
while ( defined $line ) {
    next unless $line =~ m{\S}xms;
    $line =~ s{\bpi\b}{$pi}gixms;
    $line =~ s{[@]}{$prev_res}gixms;
    my $res = eval($line);
    warn $@ if $@;
    print $OUT $res, "\n" unless $@;
    $term->addhistory($line) unless $line eq $prev_line;
    $prev_line = $line;
    $prev_res = $res;
    $line = $term->readline($prompt);
}
print "\n";

exit;

__END__

=head1 LICENSE

This script is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

=cut
