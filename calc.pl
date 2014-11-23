#!/usr/bin/perl

use strict;
use warnings;

my $cal = join ' ', @ARGV;

exit unless length $cal;

my $res = eval qq{$cal};

print "$cal := $res\n";

print $@ if $@;

exit;
