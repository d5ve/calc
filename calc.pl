#!/usr/bin/perl

use Term::ReadLine;

my $term = Term::ReadLine->new('Simple Perl calc');
my $prompt = "calc> ";
my $OUT = $term->OUT || \*STDOUT;
while ( defined ($_ = $term->readline($prompt)) ) {
  my $res = eval($_);
  warn $@ if $@;
  print $OUT $res, "\n" unless $@;
  $term->addhistory($_) if /\S/;
}
print "\n";
