#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

my ($beg, $end, $siz, $n, $num, $out, $raw, $tag, $txt, $fh_out, $label, @note);
my $b = '<b>'; my $eb = '</b>';
my $pos = 0; my $i = 0;
GetOptions(
           "num"   => \$num,
           "out=s" => \$out,
           "raw=s" => \$raw,
           "tag=s" => \$tag
          );
die "No raw ML input file specified." unless $raw;
open FHraw, $raw or die "Can't open $raw for reading";
if ($out) { open $fh_out, ">", $out; *STDOUT = $fh_out; }
while(<>) {
  next if /^#|^$/;
  ($beg, $end, $label, @note) = split, /\t/;
  $siz = $end + 1 - $beg;
  $n = read FHraw, $txt, $beg - $pos;
  print $txt;
  if ($tag) { print "[$tag] "; }
  if ($num) { printf "[%d] ", $num++; }
  $pos += $n;
  $n = read FHraw, $txt, $siz;
  print "$b$txt$eb";
  print " [$label <u>@note</u>] ";
  $pos += $n;
}
while(read FHraw, $txt, 8192 > 0) { print $txt; }
