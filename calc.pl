#!/usr/bin/perl

use strict;
use warnings;

=head1 NAME

calc.pl - Simple perl REPL calculator

=head1 SYNOPSIS

    $ calc.pl
    calc> 2 * pi * 32
    201.0619264
    calc> 

=head1 DESCRIPTION

Based upon the sample code from https://metacpan.org/pod/Term::ReadLine

To get readline working properly on OSX, I installed Term::ReadLine::GNU
following the instructions from
L<http://blogs.perl.org/users/aristotle/2013/07/easy-osx-termreadlinegnu.html>

Readline is already installed, but the Makefile doesn't pick it up, so make
homebrew install some temporary symlinks.

    dave> brew install readline
    dave> brew link --force readline
    dave> sudo su -
    root> cpan Term::ReadLine::GNU
    root> exit
    dave> brew unlink readline

=cut

use Term::ReadLine;

my $pi = 3.1415926;
my $term = Term::ReadLine->new('Simple Perl calc');
$term->Attribs->{MinLength} = 0;
my $prompt = "calc> ";
my $OUT = $term->OUT || \*STDOUT;
my $prev_line = '';
my $prev_res = '';
while ( defined ($_ = $term->readline($prompt)) ) {
    my $line = $_;
    next unless $line =~ m{\S}xms;
    $line =~ s{\bpi\b}{$pi}gixms;
    $line =~ s{[@]}{$prev_res}gixms;
    my $res = eval($line);
    warn $@ if $@;
    print $OUT $res, "\n" unless $@;
    $term->addhistory($line) unless $line eq $prev_line;
    $prev_line = $line;
    $prev_res = $res;
}
print "\n";

exit;

__END__

=head1 LICENSE

This script is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

=cut
