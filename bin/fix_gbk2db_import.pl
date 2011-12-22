#!/usr/bin/perl -wT
# 
# The original import of gbk files had a problem with missing annotations
# and missing gene names. 
#
# It is always nice to clean up oens own mess, so do not run this unless 
# you know what it does and how it is done. This could F**** up the database
#
#
# Kim Brugger (Oct 2008), contact: brugger@bio.ku.dk

use Getopt::Std;
use strict;
use Data::Dumper;

use lib '/data/www/sulfolobus.org/modules/';
use lib '/usr/local/perllib/';

use core;
use parser::genbank;

use db;
use db::organism;
use db::version;
use db::sequence;
use db::gene;
use db::genefinder;
use db::annotation;

use Data::Dumper;
my %opts;

getopts('i:s:h', \%opts); 
$opts{"h"} && die USAGE();

if (! $opts{"i"}) {
  USAGE();
}

my $genbank_hash = &parser::genbank::parse($opts{"i"});
my $sid = $opts{ 's' };

print STDERR "The file contains ". @{$$genbank_hash{'features'}} . " features.\n";

foreach my $feature (@{$$genbank_hash{'features'}}) {

  # Since the genes are often found as both a gene and a CDS
  # we will just store the CDS's.
  if ($$feature{'feature_type'} && 
      $$feature{'feature_type'} eq "CDS") {


    next if ($$feature{ 'intron' });

    ($$feature{'start'}, $$feature{'stop'}) = ($$feature{'stop'}, $$feature{'start'}) 
	if ($$feature{'start'} > $$feature{'stop'});
    my $gene_ref = db::gene::sameStopPos($sid, $$feature{'stop'}, $$feature{'complement'});

    # Could not find the gene based on  the stop codon, check and see if 
    # we can find it base on the startpos
    if ( ! $gene_ref ) {      
      $gene_ref = db::gene::sameStartPos($sid, $$feature{'start'}, $$feature{'complement'});
      die "Could not position this gene: " .Dumper($feature) if (! $gene_ref );
    }
      
    my $gid = $$gene_ref{ 'gid' };

    # We can fix the name of this gene.
    if ( $$gene_ref{ name } =~ /_/ ) {
      my %call_hash = ( gid  => $gid,
			name => $$feature{ '/locus_tag' });

      &db::gene::update( \%call_hash);
      print "Sat name for $$feature{ '/locus_tag' } \n";
    }

    # check and see if there is an annotation for this gene in 
    # the database, jump if there is an annotation already.
    my $annotation_ref = db::annotation::all( $gid, 1);
    next if ( $annotation_ref );


    # then save the annotaion that was found in the genbank file.
    if ($$feature{"/comment"}) {
      $$feature{"/comment"} =~ s/^\'//;
      $$feature{"/comment"} =~ s/\'$//;
    }

    # We should have at least these information items.
    my %call_hash = (
		  'gid' => $gid, 
		  'gene_name'       => $$feature{"/gene_name"} || $$feature{"/protein_id"},
		  'start_codon'     => $$feature{"/codon_start"},
		  'gene_product'    => $$feature{"/product"},
		  'comment'         => $$feature{"/note"} || $$feature{"/comment"},
		  'annotator_name'  => "From the genbank file",
		  'state'           => "show");

    $call_hash{"conf_in_gene"} = $$feature{"/gene-confidence"} if ($$feature{"/gene-confidence"});
    $call_hash{"conf_in_func"} = $$feature{"/function-confidence"} if ($$feature{"/function-confidence"});

    $call_hash{"evidence"} = $$feature{"/evidence"} if ($$feature{"/evidence"});
    $call_hash{"EC_number"} = $$feature{"/EC_number"} if ($$feature{"/EC_number"});
    $call_hash{"TAG"} = $$feature{"/TAG"} if ($$feature{"/TAG"});

#    $call_hash{""} = $$feature{"/"} if ($$feature{"/"});
#    $call_hash{""} = $$feature{"/"} if ($$feature{"/"});

    if ($$feature{"/function"}) {
      $call_hash{"general_function"} = $$feature{"/function"};
      
#      my ($prim, $sec) = split ("/", $$feature{"/function"}, 2);
#      $call_hash{"primary_function"} = $prim;
#      $call_hash{"secondary_function"} = $sec;
    }

#    print Dumper(\%call_hash);
    
    my $aid = &db::annotation::save(\%call_hash);
    
#    print STDERR "*";
  }

}

print STDERR "\n";



sub USAGE {
  $0 =~ s/.*\///;
  die "USAGE : $0 -i inputfile  -s[equence id (sid)]\n";
}
