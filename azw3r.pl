#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

my ($inp, $buf, $loc, $n, $hl, $raw); my $highlight=0; my $note=0; my $pos=0;
my $b00 = pack 'C3', (2, 0, 0); my $c00 = pack 'C3', (3, 0, 0);
my $c0 = pack 'C2', (3, 0); my $offset = 0;
GetOptions(
           "inp=s" => \$inp,
           "h"     => \$highlight,
           "n"     => \$note,
           "offset=i" => \$offset,
           "raw=s" => \$raw
          );
if ($raw) { open FHraw, $raw or die "Can't open $raw for reading"; }
$note = 1 unless $highlight or $note;
my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, @misc) = stat($inp)
or die "Can't stat input file: '$inp'.\n";
open(FHazw3r, "<", $inp) or die "Can't open input file: '$inp'.\n";
$n = read FHazw3r, $buf, $size;
while ($pos < $size) {
  if ($highlight) {
    if (($loc = index $buf, 'annotation.personal.highlight', $pos) > -1) {
      warn "File synch lost looking for highlight beginning."
        if unpack('C', substr($buf, $loc + 29, 1)) != 3;
      my $hblen = unpack('n', substr($buf, $loc + 31, 2));
      my $hbeg = substr($buf, $loc + 33, $hblen); $pos = $loc + 33 + $hblen;
      warn "File synch lost looking for highlight end."
        if unpack('C', substr($buf, $pos, 1)) != 3;
      my $helen = unpack('n', substr($buf, $pos + 2, 2));
      my $hend = substr($buf, $pos + 4, $helen); $pos = $pos + 4 + $helen;
      if ($raw) {
        seek FHraw, $hbeg + $offset, 0;
        $n = read FHraw, $hl, $hend - $hbeg + 1;
      }
      print "$hbeg\t$hend\tHighlight:";
      if ($raw) { print "\t'$hl'\n"; } else { print "\n"; }
    }
    
  }
  if ($note) {
    if (($loc = index $buf, 'annotation.personal.note', $pos) > -1) {
      warn "File synch lost looking for note beginning."
        if unpack('C', substr($buf, $loc + 24, 1)) != 3;
      my $nblen = unpack('n', substr($buf, $loc + 26, 2));
      my $nbeg = substr($buf, $loc + 28, $nblen); $pos = $loc + 28 + $nblen;
      warn "File synch lost looking for note end."
        if unpack('C', substr($buf, $pos, 1)) != 3;
      my $nelen = unpack('n', substr($buf, $pos + 2, 2));
      my $nend = substr($buf, $pos + 4, $nelen); $pos = $pos + 4 + $nelen;
      $loc = index $buf, $b00, $pos;
      my $flen = unpack('n', substr($buf, $loc+2, 2)); $pos = $loc+2 + $flen;
      $loc = index $buf, $b00, $pos;
      $flen = unpack('n', substr($buf, $loc+2, 2)); $pos = $loc+2 + $flen;
      $loc = index $buf, $c00, $pos;
      $flen = unpack('n', substr($buf, $loc+2, 2)); $pos = $loc+2 + $flen;
      $loc = index $buf, $c0, $pos;
      $flen = unpack('n', substr($buf, $loc+2, 2)); $pos = $loc+4;
      my $notestr = substr $buf, $pos, $flen;
      print "$nbeg\t$nend\tNote:\t'$notestr'\n";
    }
  }
  $pos ++;
}
