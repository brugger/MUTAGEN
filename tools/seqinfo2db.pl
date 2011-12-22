#!/usr/bin/perl -wT
# 
# Transfer information from external methods to the db.
# 
# 
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;

use lib '/data/www/sulfolobus.org/modules/';
use db::adc;
use db::gene;
use core;

use Data::Dumper;

my $post_sprot   ="faa.best_sp_blast";
my $post_cog     ="faa.best_cog_blast";
my $post_gbk     ="faa.best_nr_blast";
my $post_local   ="faa.best_local_blast";

my $post_pfam    ="faa.pfam";
my $post_tmhmm   ="faa.tmhmm";
my $post_signalp ="faa.signalp";


my $prefix = shift || Usage();
# Remove trailing '.' if they exists.
$prefix =~ s/\.*$//;


transfer("sprot", "$prefix.$post_sprot");


# 
# Transfer information from a single datasource to the db
# 
# Kim Brugger (28 Nov 2003)
sub  transfer {
  my ($origin, $filename) = @_;

  open (FIL, $filename) || return;
  print STDERR "Transfering $origin information\n";

  while (<FIL>) {
    chomp;
    my @fields = split/\t/;

    my $gid = $fields[0];
    die "Wrongly formated line: '$_'\n" if ($gid !~ /^gid:\d+$/);
    $gid =~ s/^gid:(\d+)$/$1/;
    
    my %call_hash = (gid    => $gid,
		     name   => $fields[1],
		     score  => $fields[2],
		     origin => $origin);
    
    &db::adc::save(\%call_hash);

    # set the colour in the gene table
    %call_hash = ('gid' => $gid,
		  "colour" => $core::gene_colours{$origin});

    db::gene::update(\%call_hash);

    print STDERR "*";
  }
  print STDERR "\n";
  
}



