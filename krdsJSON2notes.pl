#!/usr/bin/perl
use strict;
use warnings;
use JSON;

open FH, "<", shift @ARGV or die "Can't open JSON input file";
my $json = do { local $/; <FH> };
close FH;
my %krds = %{decode_json($json)};
my @names = keys %krds;
for (@names) {
  next unless /annotation.cache.object/;
  my %annotations = %{$krds{$_}};
  my @notes = $annotations{'annotation.personal.note'};
  @notes = @{$notes[0]};
  for my $n (@notes) {
    print "$n->{startPosition}\t$n->{endPosition}\tNote:\t'$n->{note}'\n";
  }
  @notes = $annotations{'annotation.personal.highlight'};
  @notes = @{$notes[0]};
  for my $n (@notes) {
    print "$n->{startPosition}\t$n->{endPosition}\tHighlight:\n";
  }
}
