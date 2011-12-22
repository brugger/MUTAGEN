#!/usr/bin/perl -wT
#
# Transfer the sequence, into the database. If there are a file
# present that describes the positions of the genes, these are also
# placed into the database. Otherwise it is possible to do this later
#
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;
use Getopt::Std;
use Term::ReadLine;
use Data::Dumper;

use lib '/data/www/sulfolobus.org/modules/';
use core;
use db;
use db::organism;
use db::version;
use db::gene;
use db::sequence;

my %opts = ();
getopts('A:h', \%opts);

my $prefix = shift || Usage();
$prefix =~ s/\.*$//;

my $sequ_post = ".fna";
my $gene_post = ".genes";
my $tRNA_post = ".tRNA";
my $rRNA_post = ".rRNA";

my $org_name  = "Unknown";
my $org_alias = "test";


Organism_info();

my $organism = &db::organism::fetch($org_name);
my $oid = $$organism{'oid'};
# If the organism did not exis, we create a new entry in the database.
if (!$oid) {
  my %call_hash = (name  => $org_name,
		   alias => $org_alias);

  $oid = &db::organism::save(\%call_hash);
}

# Create the next version id, so we can handle several sequence versions.
my $vid = &db::version::next($oid);


print "Reading the $prefix.* files, that all belong to the organisms '$org_name' ($org_alias).\n";
my $sequences = &core::read_fasta("$prefix$sequ_post");
print "Read the sequence file $prefix$sequ_post\n";
foreach my $key (keys %{$sequences}) {
  chomp $$sequences{$key}{'name'};
#  print STDERR "-->$$sequences{$key}{'name'}\n";
  $$sequences{$key}{sid} = &db::sequence::save($oid, $vid, $$sequences{$key}{'name'}, $$sequences{$key}{'sequence'});
}
print "Transfered the sequence(s) to the database\n";


&genes("$prefix$gene_post");
print "Transfered the gene(s) to the database\n";

#print "Read the tRNA file $prefix.$gene_post\n";
#print "Transfered the tRNA(s) to the database\n";

#print "Read the rRNA file $prefix.$gene_post\n";


sub genes {
  my ($infile) = @_;
  
  open (INFIL, $infile) || die "Could not open the file '$infile': $!" || return;

  my (%call_hash, @gene_names, %genes);

  print "Reading the gene-file: $prefix$gene_post\n";

  while (<INFIL>) {
    s/^\>//; 
    my @fields = split "\t";
    push @gene_names, $fields[0];
    $genes{$fields[0]} = $_;
  }

  @gene_names = sort gene_sort @gene_names;


  print STDERR "Transfering genes : ";
  foreach my $gene_name (@gene_names) {
    my @gene = split /\t/,$genes{$gene_name};

    $gene[0] =~ s/^\>//; 
    $gene[0] =~ /^(.*)_(\d*)-(\d*)$/;    
    my $contig = $1 || die "Could not find the sequence name, $gene[0] ($1, $2, $3)";
  
    ($gene[1], $gene[2]) = ($gene[2], $gene[1]) if ($gene[1] > $gene[2]);

    %call_hash = (
		  'name' => $gene[0],
		  'start' => $gene[1],
		  'stop'  => $gene[2],
		  'strand' => $gene[3] =~ /^direct/i ? 0 : 1,
		  'sid' => $$sequences{$contig}{sid},
		  'colour' => '0',
		  'type' => 'ORF');

#    use Data::Dumper;
#    print STDERR Dumper(\%call_hash) if $gene[3] !~ /^direct/i;

    &db::gene::save(\%call_hash);
    print STDERR "*";
  }
  print STDERR "\n";
}

#
# Prompts the user for information regarding the organism that the sequence comes from.
#
sub Organism_info {
  my $term = new Term::ReadLine 'Transfer DNA sequence to the MUTAGEN database';
  my $OUT = $term->OUT || \*STDOUT;
  $org_name  = $term->readline("Enter the organism name: ");
#  print $OUT "Is this the correct name of the organism? '$organism' (Otherwise therminate the program)\n";
  $org_alias = $term->readline("Enter the organism alias: (not required)");
#  print $OUT "Is this the correct alias of the organism? '$org_alias' (Otherwise therminate the program)\n";
}

#
# Usage of the program
#
sub Usage {
  print STDERR "\nseq2db.pl FILES_PREFIX [.fna, .genes, .tRNA, rRNA, ...]\n";
  print STDERR ".fna: The raw DNA sequence in fasta format, the file may contain several sequences\n";
  print STDERR "Genes (OFS, tRNA\'s etc. are all placed in GFF (v2) formated files\n";
  print STDERR "The genes can be read into the database afterwards, and/or placed \n";
  print STDERR "in multiple file (see manual for more information).";
#  print STDERR ".genes: Genes correlating to the sequence; \n\tsequence_name\tsequence\tstart\tstop\tstring(direct, complement)\n";
#  print STDERR ".tRNA:  Genes correlating to the sequence; \n\tsequence_name\tsequence\tstart\tstop\tstring(direct, complement)\ttRNA-name\n";
#  print STDERR ".rRNA: Genes correlating to the sequence; \n\tsequence_name\tsequence\tstart\tstop\tstring(direct, complement)\trRNA-name\n";
  die "\n";
}



sub gene_sort {
  my ($A,$B) = ($a, $b);

  # remove leading > if it is found in the gene name
  $A =~ s/^>//;
  $B =~ s/^>//;

  my ($a_contig, $a_start, $a_stop) = split /[-_]/, $A;
  my ($b_contig, $b_start, $b_stop) = split /[-_]/, $B;

  ($a_start, $a_stop) = ($a_stop, $a_start)
      if ($a_start > $a_stop);

  ($b_start, $b_stop) = ($b_stop, $b_start)
      if ($b_start > $b_stop);

#  print STDERR "$a $b || ($a_contig <=> $b_contig) || ($a_start <=> $b_start) || ($a_stop <=> $b_stop) $a,$b\n";

  return ($a_contig cmp $b_contig) || ($a_start <=> $b_start) || ($a_stop <=> $b_stop);

}
