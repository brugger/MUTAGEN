#!/usr/bin/perl -wT
# 
# Creates the blastdb, with the sequences from the local database.
# All the sequences will be placed in a single file, to limit space and 
# speed things up, so I do not have to create special dbs on the fly.
#
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;
use Data::Dumper;
use lib '/data/www/sulfolobus.org/modules/';

require db::organism;
require db::sequence;
require db::gene;
require db::version;
require core;

my $blastdir = "/home/bugger/public_html/MUTAGEN_4/blastdb/";
my $formatdb = "/usr/local/bin/formatdb";
my $dbfile = "local";
&run();

sub run {

  open (ALL_AA,  "> $blastdir$dbfile.faa") or die "could not open $blastdir$dbfile.faa: $!";
  open (ALL_DNA, "> $blastdir$dbfile.fna") or die "could not open $blastdir$dbfile.fna: $!";

  my @organisms = &db::organism::all();

  foreach my $organism (@organisms) {
    my ($genome, $genes) = organism_sequence($organism);
    print ALL_DNA $genome;
    print ALL_AA $genes;
  }

  close (ALL_AA)  || die "could not close all_db.fna: $!";
  close (ALL_DNA) || die "could not close all_db.fna: $!";


  # now format and build the blast database files.
  # first format the basic database 
  # first the DNA database
  my $run = "$formatdb -i $blastdir$dbfile.fna -pF -oT ";
  system $run;

  # then the AA database
  $run = "$formatdb -i $blastdir$dbfile.faa -oT ";
  system $run;

  # for each organism, build an index so we can access subparts of the database
  foreach my $organism (@organisms) {
    build_index($$organism{'oid'}, $$organism{'name'});
  }
  
  # Remove all the files that is not needed to save space
  system "rm -f $blastdir/$dbfile.faa $blastdir/$dbfile.fna $blastdir/*.in $blastdir/*.din\n";
}

sub build_index {
  my ($oid, $name) = @_;

  $name =~ s/^(.).*? (.*)/$1. $2/;
  # build index's for each of the genomes
  my $run = "$formatdb -B $blastdir$oid.gi -F $blastdir$oid.in -t \"$name\"";
  system $run;
  
  #and linke the index to the AA-genome database
  $run = "$formatdb -i $blastdir$dbfile.faa -F $blastdir$oid.gi -L $blastdir$oid -t \"$name\"";
  system $run;
  
  # build index's for each of the genomes
  $run = "$formatdb -B $blastdir$oid.gid -F $blastdir$oid.din -t \"$name\"";
  system $run;
  
  #and linke the index to the DNA-genome database
  $run = "$formatdb -pF -i $blastdir$dbfile.fna -F $blastdir$oid.gid -L $blastdir$oid -t \"$name\"";
  system $run;
}

sub organism_sequence {
  my ($organism) = @_;
  
  # First find information about the organism, and version
  print "ORGANISM $$organism{name} HAS OID = $$organism{oid}\n";
  my $version = &db::version::latest($$organism{oid});
  if (! $version ) {
    print STDERR "Could not find an assembly id for '$$organism{name}'\n";
    return -1;
  }
  print "Organism has version : '$$version{version}' aka vid:$$version{vid}\n";


  # find all the DNA sequence, and save it
  my @sequences = &db::sequence::fetch_organism($$organism{oid}, $$version{vid});
  open (OUTFILE, "> $blastdir/$$organism{'oid'}.din") or die "could not open $blastdir/$$organism{'oid'}.din: $!";
  my $DNA;
  foreach my $sequence (@sequences) {
    print OUTFILE "$$sequence{sid}\n";
    $DNA .= ">gi|$$sequence{sid} $$sequence{name} [$$organism{name}] version: $$version{vid}\n";
    $DNA .= &core::nicefasta($$sequence{sequence});
  }
  close (OUTFILE) || die "could not close $$organism{'short_name'}.fna: $!";

  # now all the genes (in AA format), and lets save them also.
  my @genes = &db::gene::fetch_organism($$organism{oid}, $$version{vid});
  open (OUTFILE, ">> $blastdir/$$organism{'oid'}.in") or die "could not open $blastdir/$$organism{'oid'}.in: $!";
  my $AA;
  foreach my $gene (@genes) {
    # We only want to have the genes that can be described as ORFs in the AA db :)
    if ($$gene{type} eq 'ORF') {
      print OUTFILE "$$gene{gid}\n";
      
      $$gene{sequence} = &core::translate($$gene{sequence});
      $AA .= ">gi|$$gene{gid} $$gene{name} [$$organism{'name'}]\n";
      $AA .= &core::nicefasta($$gene{sequence});
    }
  }
  close (OUTFILE) or die "could not close $$organism{'short_name'}.faa: $!";


  return ($DNA,$AA);
}
