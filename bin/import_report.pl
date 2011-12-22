#!/usr/bin/perl -wT
# 
# 
# 
# 
# 
# 
# 
#
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;
use Getopt::Std;
use Data::Dumper;

use lib '/data/www/sulfolobus.org/modules/';
use core;
use db;

$0 =~ s/^.*\/(\w+)$/$1/;
my $infile = shift or die "Usage: $0 [infile]\n";

#
# We can expect 4 different types of files: blast, pfam, tmhmm and signalp
#

require core::report;

# 
# As always we handle the blast first (In the beginning was ...)
# 


if ($infile =~ /(nr)/ ||
    $infile =~ /(sprot)/ ||
    $infile =~ /(archaea)/ ||
    $infile =~ /(bacteria)/) {

  my $source = $1;
  
  &core::report::blast($infile, undef, $source, 1, undef);
}
elsif ($infile =~ /pfam/) {
  &core::report::pfam($infile);
}
elsif ($infile =~ /cog/) {
  &core::report::cog($infile);
}
elsif ($infile =~ /signalp/) {
  &core::report::signalp($infile);
}
elsif ($infile =~ /tmhmm/) {
  &core::report::tmhmm($infile);
}

print STDERR "Imported the information found in '$infile'\n";

