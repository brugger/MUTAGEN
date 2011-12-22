#!/usr/bin/perl -wT
# 
# Read genes into the database. The genes should be in the gff format, 
# so we can both handle RNA, ORFs and general everything else.
# 
# Kim Brugger (Feb 2004), contact: brugger@mermaid.molbio.ku.dk

use strict;
use Getopt::Std;
use Data::Dumper;

use lib '/data/www/sulfolobus.org/modules/';
use core;
use db;
use db::organism;
use db::sequence;
use db::version;
use db::gene;
use db::genefinder;

my %opts = ();
getopts('i:s:h', \%opts);

die "Usage: $0 -i(nfile) -s(id) -h(elp)\n" if ($opts{'h'} || !$opts{'s'});

my $sid = $opts{'s'};

open (INFILE, $opts{'i'}) || die "Could not open '$opts{'i'}': $!\n";

while (<INFILE>) {

  # lets skip the comments (lines beginning with #).
  next if (/^\#/);

  # fields: <seqname> <source> <feature> <start> <end> <score> <strand> <frame> [attributes] [comments]

  my ($seqname, $source, $feature, $start, $stop, $score, $strand, $frame, $attributes, $comments) =
      split ("\t");

  ($start, $stop) = ($stop, $start) if ($start > $stop);

  if ($feature eq "CDS" || $feature eq "ORF") {
    $feature = "ORF";
  }
  elsif ($feature =~ /RNA/) {
    $feature = "RNA";
  }
  else {
    $feature = "other";
  }
  
  

  my %call_hash = (
		   'start' => $start,
		   'stop'  => $stop,
		   'strand' => $strand eq "+" ? 0 : 1,
		   'sid' => $sid,
#	      'colour' => 'gray',
		   'type' => $feature,
		   'source' => $source,
		   'score' => $score);

  &db::genefinder::save(\%call_hash);
  print STDERR "*";

}

print STDERR "\n";
