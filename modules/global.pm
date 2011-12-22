#!/usr/bin/perl -wT
# 
# Global setup for variables that affect the program
# 
# 
# Kim Brugger (Jun 2005), contact: brugger@mermaid.molbio.ku.dk

use strict;

package global;
require Exporter;
require AutoLoader;

# set the version for version checking
my $VERSION     = "0.01";

my @ISA = qw(VERSION Exporter AutoLoader);

our @EXPORT = qw();
@ISA = qw(Exporter AutoLoader);
@EXPORT = qw();

#exported variables.
use vars qw (%dborder
	     %gene_types
	     %colours
	     );

BEGIN {

  # The order the databases results are shown in the gene_info subpage.
  # Here the position of the report (report_dir), the names/values shown
  # in the browser and the order (position) are set. Finally the colour
  # displayed in the sequence browser can also be controlled here.
  %dborder = ("sprot"    => {position => 1, 
				name =>  "<B>SWISS-PROT description:</B>", 
				score => "<B>SWISS-PROT E-value:</B>",
				report_dir => "reports/SP/",
				colour => 3},
		 
	      "sprot_pure" => {position => 10, 
			       name =>  "<B>S-pure description:</B>", 
			       score => "<B>SWISS-PROT E-value:</B>",
			       report_dir => "reports/SPure/",
			       colour => 3},
	      
	      "COG"     => {position => 2, 
			    name =>  "<B>COG description:</B>", 
#			    score => "<B>COG E-value:</B>",
			    report_dir => "reports/COG/",
			    colour => 4},
	      
	      "nr"      => {position => 3, 
			    name =>  "<B>GenBank description:</B>", 
			    score => "<B>GenBank E-value:</B>",
			    report_dir => "reports/GBK/",
			    colour => 5},
	      
	      "pfam"    => {position => 4, 
			    name =>  "<B>Pfam description:</B>", 
			    score => "<B>Pfam E-value:</B>",
			    report_dir => "reports/pfam/",
			    colour => 5},
	      
	      "archaea" => {position => 5, 
			    name =>  "<B>Archaeal genomes:</B>", 
			    score => "<B>Archaeal E-value:</B>",
			    report_dir => "reports/archaea/",
			    colour => 6},
	      
	      "bacteria"=> {position => 6, 
			    name =>  "<B>Bacterial genomes:</B>", 
			    score => "<B>Bacterial E-value:</B>",
			    report_dir => "reports/bacteria/",
			    colour => 6},
	      
	      "tmhmm"   => {position => 7, 
			    name =>  "<B>TMHMM :</B>", 
			    score => "<B>tmhmm score:</B>",
			    report_dir => "",
			    colour => 7},
	      
	      "signalp" => {position => 8, 
			    name =>  "<B>Signalp description:</B>", 
			    score => "<B>Signalp score:</B>",
			    report_dir => "",
			    colour => 7});
  

  # Genetypes: This is the types of genes that we operate with
  # The map_pos shows where the gene should be in the browser window.
  # 0: On the DNA sequence level/baseline
  # 1: On the AA sequence level/ORFs
  # The array_pos show the names place in a popup-menu
  # Colour: is the colour assigned to the feature by default,
  # this can be overruled by the colours assigned by the dbase predictions.
  %gene_types = ("ORF" => {map_pos => 1,
			   array_pos => 1,
			   colour => 8},
		 "CDS" => {map_pos => 1,
			   array_pos => 1,
			   colour => 8},

		 "INTRON" => {map_pos => 1,
			      array_pos => 1,
			      colour => 42},

		 "Pseudo gene" => {map_pos => 1,
				   array_pos => 2,
				   colour => 11},
		 "Misc feature" => {map_pos => 0,
				    array_pos => 3,
				    colour => 12},
		 "Repeat region" => {map_pos => 0,
				     array_pos => 4,
				     colour => 12},
		 "tRNA" => {map_pos => 0,
			    array_pos => 5,
			    colour => 13},
		 "rRNA" => {map_pos => 0,
			    array_pos => 6,
			    colour => 14},
		 "noncoding RNA" => {map_pos => 0,
				     array_pos => 7,
				     colour => 15},
		 "Other" => {map_pos => 0,
			     array_pos => 8,
			     colour => 16});




  # Colours: this is the colours used in all the graphical work. Change 
  # them here for better looks or special needs
  
  %colours = (
	      # First some colours with names (we like logical names this time around)
	      black => [0,0,0],
	      gray   => [200, 200, 200],
	      red    => [255, 0,   0],
	      blue   => [0,   0,   255],
	      green  => [0,   0,   255],

	      # Then the numbered colours, for making homology plots
	      0 => [ 100, 100, 100], # Default gray_2
	      1 => [ 255, 255, 255],
	      2 => [  24,  24, 109],
	      3 => [  98, 146, 232],
	      4 => [  70,  59, 136],
	      5 => [ 129, 109, 250],
	      6 => [  63, 103, 220],
	      7 => [   0,   0, 250],
	      8 => [  29, 141, 250],
	      9 => [   0, 187, 250],
	      10 => [132, 202, 230],
	      11 => [ 93, 155, 156],
	      12 => [100, 201, 166],
	      13 => [0,98,0],
	      14 => [83.25,105046,0],
	      15 => [45,136.25,85.25],
	      16 => [121.5,247,0],
	      17 => [0,250,0],
	      18 => [151,201,49],
	      19 => [250,250,0],
	      20 => [136.25,67.75,18.75],
	      21 => [156.75,80.5,44],
	      22 => [201,130.5,61.75],
	      23 => [239.25,160.75,94],
	      24 => [174.5,33.25,33.25],
	      25 => [245,125.5,119.25],
	      26 => [250,137.25,0],
	      27 => [250,0,0],
	      28 => [250,103,176.5],
	      29 => [172.5,47,94],
	      30 => [250,0,250],
	      31 => [150,49,200],
	      32 => [135.25,42.25,221.5],
	      33 => [201,194,112.75],
	      34 => [233.25,225.5,130.5],
	      35 => [136.25,136.25,0],
	      36 => [136.25,114.75,0],
	      37 => [250,181.25,14.75],
	      38 => [201,146,11.75],
	      39 => [136.25,69.25,69.25],
	      40 => [136.25,25.5,25.5],
	      41 => [201,100,0],
	      42 => [136.25,27.5,96],
	      43 => [136.25,100,136.25],
	      44 => [0,63.75,0],
	      45 => [63.75,25,25],
	      46 => [60,47.5,30],
	      47 => [190,250,190],
	      48 => [170,170,250],
	      49 => [140,100,190],
	      50 => [200, 0,   170], # Purple for the RNA's	      
  );


}

END {

}

1;


