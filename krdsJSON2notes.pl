#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use JSON;

my ($inp, $buf, $loc, $n, $hl, $raw); my $highlight=0; my $note=0;
GetOptions(
           "inp=s" => \$inp,
           "h"     => \$highlight,
           "n"     => \$note,
           "raw=s" => \$raw
          );
if ($raw) { open FHraw, $raw or die "Can't open $raw for reading"; }
$note = 1 unless $highlight or $note;
open(FH, "<", $inp) or die "Can't open JSON input file: '$inp'";
my $json = do { local $/; <FH> };
close FH;
my %krds = %{decode_json($json)};
my @names = keys %krds;
for (@names) {
  next unless /annotation.cache.object/;
  my %annotations = %{$krds{$_}};
  if ($highlight) {
    my @notes = $annotations{'annotation.personal.highlight'};
    @notes = @{$notes[0]};
    for my $n (@notes) {
      if ($raw) {
        seek FHraw, $n->{startPosition}, 0;
        read FHraw, $hl, $n->{endPosition} - $n->{startPosition} + 1;
        $hl = "\t'$hl'";
      } else { $hl = ''; }
      print "$n->{startPosition}\t$n->{endPosition}\tHighlight:$hl\n";
    }
  }
  if ($note) {
    my @notes = $annotations{'annotation.personal.note'};
    @notes = @{$notes[0]};
    for my $n (@notes) {
      print "$n->{startPosition}\t$n->{endPosition}\tNote:\t'$n->{note}'\n";
    }
  }
}
