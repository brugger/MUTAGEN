#!/usr/bin/perl -w
# 
# 
# 
# 
# Kim Brugger (Mar 2004), contact: brugger@mermaid.molbio.ku.dk

use strict;

my ($i,$count, $seq) = (0, 0, undef);
while (<>) {
  next if (/\>/);

  $seq .= $_;

  if ($i == 100) {
    print ">$count\n$seq";
    $seq = "";
    $count++;
    $i = 0;
  }

  $i++;
}

if ($seq) {
  print ">$count\n$seq";
  $seq = "";
  $count++;
}
