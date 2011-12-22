#!/usr/bin/perl -wT
# 
# Build the clustering information for MUTAGEN.
# 
# 
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;
use Data::Dumper;

use lib '/data/www/sulfolobus.org/modules/';
use core::cluster;

$0 =~ s/^.*\/(\w+)$/$1/;
my $infile = shift or die "Usage: $0 [infile]\n";

# run the clustering with default parameters.
print core::cluster::cluster_genes($infile);



