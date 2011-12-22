#!/usr/bin/perl -wT
# 
# Extract all genes or a genome based on a organism basis.
# 
# 
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;
use Getopt::Std;

use lib '/data/www/sulfolobus.org/modules/';
use lib '/usr/local/perllib/';

require core;
require db;
require db::gene;
require db::sequence;
require db::organism;

my %opts = ();

getopts('o:v:Ag', \%opts);
my $name = $opts{'o'} || $opts{'A'} || undef;
$0 =~ s/.*\///;
die "$0 -o (organism-name |-id |-shortname) -v(ersion-id) | -A(ll) | -g(enome sequence) \n" if (!$name);

if ($opts{'o'}) {
  my ($organism) = id_organism ($opts{'o'}, $opts{'v'});
  
  if ($opts{'g'}) {
    extract_genome($organism);
  }
  else {
    extract_organism($organism);
  }
}
else {
  extract_all();
}

########################################################################
#     functions
######################################################################## 

sub id_organism {
  my ($organism, $version) = @_;

  require db::version;
  require db::organism;
  
  $organism = &db::organism::fetch($organism);

  if (!$organism) {
    print STDERR "UNKNOWN ORGANISM '$name'\n";
    return -1;
  }
    
  print STDERR "ORGANISM HAS ID = $$organism{oid}\n";

  if ($version) {
    #things look fine, find the version id that corresponds to version -1

    $version = &db::version::fetch($$organism{'oid'}, $version);


    use Data::Dumper;
    print STDERR Dumper($version);


    if ($$version{'oid'}  != $$organism{'oid'}) {
      die "No such version for organism '$$organism{'name'}'\n";
    }
  }
  else {
    $version = &db::version::latest($$organism{oid});
    if (! $version ) {
      die "Could not find an version id for '$name'\n";
    }
  }
  
  print STDERR "Version version : '$$version{version}' aka vid:$$version{vid}\n";

  $$organism{'vid'} = $$version{'vid'};

  return ($organism) if ($$organism{'oid'} && $$version{'vid'});
  return undef;
}

sub extract_organism {
  my ($organism) = @_;

  my @genes = &db::gene::fetch_organism($$organism{'oid'}, $$organism{'vid'});

  

  foreach my $gene (@genes) {
    if ($$gene{type} eq 'ORF') {
#      print ">gid:$$gene{gid} $$gene{start} $$gene{stop} $$gene{compliment} [$$organism{'name'}]\n";
      print ">gid:$$gene{gid} $$gene{name} [$$organism{'name'}]\n";
      
      $$gene{sequence} = &kernel::translate($$gene{sequence});
      print &kernel::nicefasta($$gene{sequence});
#      print $$gene{sequence}. "\n";
    }
  }
}

sub extract_genome {
  my ($organism) = @_;

#  &core::Dump($organism);

  my @sequences = &db::sequence::fetch_organism($$organism{'oid'}, $$organism{'vid'});

  foreach my $sequence (@sequences) {
    print ">sid:$$sequence{sid} $$sequence{name} [$$organism{name}] version: $$organism{vid}\n";
    print (&kernel::nicefasta($$sequence{sequence}));
  }

}



sub extract_all {

  my @genes = db::gene::all();
  
  my %organisms;

  foreach my $gene (@genes) {
    if ($$gene{type} eq 'ORF') {
      
      # If the organism name for the sequence is unknown, we find it and puts it in
      # a nice hash table and thus saves some time.
      if (! $organisms{$$gene{'oid'}}) {
	my $organism = &db::organism::fetch($$gene{'oid'});
	$organisms{$$gene{'oid'}} = $$organism{'name'};
      }
      
      print ">gid:$$gene{gid} $$gene{name} [$organisms{$$gene{'oid'}}]\n";
      $$gene{sequence} = &kernel::translate($$gene{sequence});
      print &kernel::nicefasta($$gene{sequence});
    }
  }
}
