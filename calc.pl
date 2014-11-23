#!/usr/bin/perl

use strict;
use warnings;

while (defined (my $cal = <STDIN>)) {
    chomp $cal;
    last unless length $cal;

    my $res = eval qq{$cal};

    print "$cal := $res\n" if $res;

    print $@ if $@;
}
