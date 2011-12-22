#!/usr/bin/perl -wT
# 
# Reads an gbk file into the database, making it possible to browse
# the genome afterwards.
#
# Kodet af kim brugger (brugger@mermaid.molbio.ku.dk) Feb 2004

use Getopt::Std;
use strict;

use lib '/data/www/sulfolobus.org/modules/';
use lib '/data/www/sulfolobus.org/modules/';

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

getopts('i:t:s:h', \%opts); 
$opts{"h"} && die $0." :  [-i inputfile]\n";

if (! $opts{"i"}) {
  print STDERR "ERROR : no input file argument\n";
  die $0."  -i inputfile -t[ype: organism, plasmid or virus] -s[ub-type: conjugative or cryptic]\n";
}

$opts{t} = "organism" if (!$opts{t});

if ($opts{"t"} ne "organism" &&
    $opts{"t"} ne "plasmid"  &&
    $opts{"t"} ne "virus") {
  print STDERR "ERROR : wrong sequence type: '$opts{'t'}'\n";
  die $0."  -i inputfile -t[ype: organism, plasmid or virus]\n";
}


my $genbank_hash = &parser::genbank::parse($opts{"i"});

print ">$$genbank_hash{organism}\n";

#print Dumper ($genbank_hash);

# Since we now have the genbank in a good and easily accessible 
# format, lets place the data into the database.


# first add the organism to the database, but first check and see if it 
# is already present there.

my $organism = &db::organism::fetch("$$genbank_hash{organism}");

if (! $organism) {
  $$genbank_hash{organism} =~ /^(.).*? (.{3}).*/;
  my $alias = "$1$2";

  my %call_hash = ("name" => $$genbank_hash{organism},
		   "alias" => $alias,
		   "type" => $opts{"t"});

  $call_hash{"subtype"} = $opts{"s"} if ($opts{"s"});

#  print STDERR Dumper(\%call_hash);
  &db::organism::save(\%call_hash);
  
  # and finally fetch the information we just saved.
  $organism = &db::organism::fetch("$$genbank_hash{organism}");
}

# Find the next vid (version id) for this sequence/organism.  The
# function checks if this is a new sequence etc, just belive in the
# return value of the function call.
my $vid = &db::version::next($$organism{"oid"});


# Now that we have both the sequence and the rest of the information
# required, lets store the information in the database.

my $sid = &db::sequence::save($$organism{oid}, $vid, 
			      $$genbank_hash{"sequence_name"}, $$genbank_hash{"sequence"});


print STDERR "The file contains ". @{$$genbank_hash{'features'}} . " features.\n";

foreach my $feature (@{$$genbank_hash{'features'}}) {

  # Since the genes are often found as both a gene and a CDS
  # we will just store the CDS's.
  if ($$feature{'feature_type'} && 
      $$feature{'feature_type'} eq "CDS") {
    
    my %call_hash = ('name'       => $$feature{"/locus_tag"} || 
		     $$feature{"/gene"} || $$feature{"/protein_id"} || $$feature{"/note"},
		     'start'      => $$feature{'start'},
		     'stop'       => $$feature{'stop'},
		     'strand'     => $$feature{'complement'},
		     'intron'     => $$feature{'intron'},
		     'type'       => $$feature{'feature_type'},
		     'sid'        => "$sid",
		     'source'     => "GenBank");
    
#    print Dumper($feature, \%call_hash);

    my $fid = &db::genefinder::save(\%call_hash);

    $call_hash{fid} = $fid;

    delete $call_hash{source};
    
    my $gid = &db::gene::save(\%call_hash);

    # then save the annotaion that was found in the genbank file.

    if ($$feature{"/comment"}) {
      $$feature{"/comment"} =~ s/^\'//;
      $$feature{"/comment"} =~ s/\'$//;
    }

    # We should have at least these information items.
    %call_hash = ('fid' => $fid,
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

    my $aid = &db::annotation::save(\%call_hash);
    
    print STDERR "*";
  }
  elsif ($$feature{'feature_type'} && 
	 $$feature{'feature_type'} eq "rRNA") {

  }
  elsif ($$feature{'feature_type'} &&
	 $$feature{'feature_type'} eq "tRNA") {

  }  
  else {
#    print STDERR "-";
  }
}

print STDERR "\n";



sub store {
  my ($dbh, $feature) = @_;

  my ($contig, $start, $stop, $compliment);

  if ($$feature{CDS} =~ /complement\((\w+?)\.\.(\w+?)\)/) {
    ($start, $stop, $compliment) = ($1,$2, 1);
  }
  elsif ($$feature{CDS} =~ /(\w+?)\.\.(\w+)/) {
    ($start, $stop, $compliment) = ($1,$2, 0);
  }
  else {
    print STDERR "$$feature{CDS}\n";
    return;
#    exit;
  }
#  print $$feature{CDS}."------$start, $stop, $compliment\n";

  my %call = ('name'       =>$$feature{"/protein_id"},
	      'start'      => $start,
	      'stop'       => $stop,
	      'compliment' => $compliment,
	      'sid'        => "--",
	      'colour'     => '--',
	      'origin'     => "genbank");

  my $gid = _save_gene($dbh, \%call);

  my %call_hash = ('gid' => $gid,
		   'allele' => $$feature{"/allele"}, 
		   'codon_start' => $$feature{"/codon_start"},
		   'db_xref' => $$feature{"/db_xref"},
		   'EC_number' => $$feature{"/EC_number"},
		   'evidence' => $$feature{"/evidence"}, 
		   'exception' => $$feature{"/exception"}, 
		   'function' => $$feature{"/function"}, 
		   'gene' => $$feature{"/gene"}, 
		   'label' => $$feature{"/label"}, 
		   'map' => $$feature{"/map"}, 
		   'note' => $$feature{"/note"}, 
		   'product' => $$feature{"/product"}, 
		   'protein_id' => $$feature{"/protein_id"},
		   'standard_name' => $$feature{"/standard_name"});

  _save_gbk($dbh, \%call_hash);
  print STDERR "*";
}

