#!/usr/bin/perl -wT
# 
# Code for exporting the sequence from the database.
# 
# Kim Brugger (Dec 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;

package page::sequence::export;
require Exporter;
require AutoLoader;

# set the version for version checking
my $VERSION     = "0.01";

my @ISA = qw(VERSION Exporter AutoLoader);

our @EXPORT = qw();
@ISA = qw(Exporter AutoLoader);
@EXPORT = qw();

#exported variables.
use vars qw ();

sub extract_page {
  
  my $html = "";
  
  # 
  # Makes the sequence extraction form
  # 
  if ($html::parameters{'seq_export'}) {

    $html .= &mutagen_html::headline("Extract sequences");

    $html .= html::start_form('mutagen.pl');

    require db::organism;
    require db::version;

    my $organism = &db::organism::fetch($html::parameters{'oid'});
    my $version  = &db::version::fetch($html::parameters{'vid'});
    
    
    my @cells= ["<H3>Extract sequence from '$$organism{'name'}' seq. version: $$version{'version'}</H3>"];
    
    my @left;
    # The left box, that have the full sequence extraction (in serveral different formats)
    
    push @left, ["Export type"], 
    [&html::generic_form_element({type=>"popup", name=>"etype", 
				  values =>["Genome sequence", 
					    "ORF sequence (AA)",
					    "ORF sequence (DNA)",
					    "GenBank"]})];

    push @left, ["Gene score"];
    push @left, [&html::generic_form_element({type=>"text", 
					      name=>"gene_score", 
					      value =>"5"}).
		 "Use filter".
		 &html::generic_form_element({type=>"checkbox",
					      name=>"filter_score",
					      checked=>"1"})];
    

    push @left, ["Minimum gene length"];
    push @left, [&html::generic_form_element({type=>"text", 
					      name=>"gene_length", 
					      value =>"100"}).
		 "Use filter".
		 &html::generic_form_element({type=>"checkbox",
					      name=>"filter_length",
					      checked=>"0"})];

    push @left, ["Start position"];
    push @left, [&html::generic_form_element({type=>"text", 
					      name=>"start_pos", 
					      value =>"1"}).
		 "Use filter".
		 &html::generic_form_element({type=>"checkbox",
					      name=>"filter_start",
					      checked=>"0"})];

    push @left, ["Stop position"];
    push @left, [&html::generic_form_element({type=>"text", 
					      name=>"stop_pos", 
					      value =>"-1"}) ." (-1 equals then end of the sequence)".
		 "  Use filter".
		 &html::generic_form_element({type=>"checkbox",
					      name=>"filter_stop",
					      checked=>"0"})];

    push @left, ["Translate:  (only works for genome sequence)"];
    push @left, [&html::generic_form_element({type=>"radio", 
					      name=>"translate", 
					      value=>"Yes"})."Yes".
		 &html::generic_form_element({type=>"radio",
					      name=>"translate" , 
					      value=>"No", 
					      checked=>1}). "No".
		 &html::generic_form_element({type=>"radio",
					      name=>"translate" , 
					      value=>"Six"}). "All frames"];
  

    push @left, [&html::generic_form_element({type=>"submit", name=>"extract", value =>"Extract sequence"})];
    
    require db::sequence;
    my @sequences = db::sequence::fetch_organism($html::parameters{'oid'}, $html::parameters{'vid'});
    my %labels = ();
    
    push @cells, [&html::table(\@left, 1, 5)];
    $html .= &html::style::center(&html::table(\@cells, 1, 5, 5, undef, "98%"));
    
    $html .= &html::generic_form_element({type=>'hidden',name=>'oid', value=>$html::parameters{'oid'}});
    $html .= &html::generic_form_element({type=>'hidden',name=>'vid', value=>$html::parameters{'vid'}});
    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"sequence"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"export"});

    $html .= &access::session_form();
    $html .= &html::end_form();
  }

  #
  # Extract a the sequence  the user requested. The sequence can even be translated 
  # in all different frames, and displayed in different formats.
  elsif ($html::parameters{'extract'}) {

    $html .= &mutagen_html::headline("Extract sequences");

    # here we handles 3 different types of sequence extraction, and
    # all of them extracts all of the genes from an organism, but the
    # output will be formated in different formats.

    my $result = "";
    
    require db::sequence;

    my @seq_hash = &db::sequence::fetch_organism($html::parameters{'oid'}, 
						 $html::parameters{'vid'});

    my $sid = $seq_hash[0]{'sid'};


    my ($start, $stop) = (undef, undef);
    
    $start = $html::parameters{'start_pos'} if ($html::parameters{'start_pos'} && 
						$html::parameters{'filter_start'} &&
						$html::parameters{'start_pos'} >= 1);
    
    $stop  = $html::parameters{'stop_pos'}  if ($html::parameters{'stop_pos'} && 
						$html::parameters{'filter_stop'} &&
						$html::parameters{'stop_pos'} > 1);
    
    #
    # Here the raw genome sequence is extracted, and it is also
    # possible to translate teh sequence
    # 
    if ($html::parameters{'etype'} eq "Genome sequence") {


      $start = 1 if ($stop && !$start);
      
      my ($seq_name, $seq) =  (&core::extract_sequence ($sid, $seq_hash[0]{'name'}, 
							$start, $stop));
      
      $result = "\n$seq_name\n" . &kernel::nicefasta($seq);

      # check to see if the user want to translate the sequence extracted.
      # All six frams (both strands) are translated in this case
      if ($html::parameters{'translate'} && $html::parameters{'translate'} eq "Six") {
	$result .= &kernel::six_frames($seq);
      }
      # Or just the current frame on the wanted strand strand
      elsif ($html::parameters{'translate'} && $html::parameters{'translate'} eq "Yes") {
	$result .= ">translated\n" . &kernel::nicefasta(&kernel::translate($seq, 1));
      }
      
    }
    # The export is ORFS either as AA or DNA.
    elsif ($html::parameters{'etype'} eq "ORF sequence (AA)" ||
	   $html::parameters{'etype'} eq "ORF sequence (DNA)") {
      
      require db::gene;

      my @genes = &db::gene::fetch_organism(undef, undef, $sid, $start, $stop);

      # sort the genes according to gid (sometime they are shuffled)
      @genes = sort {$$a{'gid'} <=> $$a{'gid'}} @genes;

      foreach my $gene (@genes) {

	next if ($html::parameters{'filter_score'} && $$gene{'score'} &&
		 $html::parameters{'gene_score'} < $$gene{'score'});

	next if ($html::parameters{'filter_length'} &&
		 $html::parameters{'gene_length'} > ($$gene{'stop'} - $$gene{'start'} +1)/3);
	  

	$$gene{'sequence'} = &kernel::translate($$gene{'sequence'}, 0) 
	    if ($html::parameters{'etype'} eq "ORF sequence (AA)");
	$$gene{'sequence'} =~ s/\.$//;

	$result .= ">gid:$$gene{'gid'} $$gene{'name'}\n". &kernel::nicefasta($$gene{'sequence'});
      }

    }
    # Finally the extract as GenBank.
    elsif ($html::parameters{'etype'} eq "GenBank") {
      require db::gene;
      require db::sequence;
      require db::organism;
      require db::version;

      my @genes = &db::gene::fetch_organism(undef, undef, $sid, $start, $stop);

      my ($seq_name, $seq) =  (&core::extract_sequence ($sid, $seq_hash[0]{'name'}, 
							$start, $stop));

      my $sequence = &db::sequence::fetch($sid);
      my $organism = &db::organism::fetch($$sequence{'oid'});
      my $version  = &db::version::fetch($html::parameters{'vid'});

      $start = 1 if ($stop && !$start);

      # first add the common GBK-header
      $result = &core::gbk_header ($organism, $version, $sequence, $start, $stop);

      # foreach gene print the required information.
      foreach my $gene (@genes) {

	next if ($html::parameters{'filter_score'} && $$gene{'score'} &&
		 $html::parameters{'gene_score'} < $$gene{'score'});	 


	next if ($html::parameters{'filter_length'} &&
		 $html::parameters{'gene_length'} > ($$gene{'stop'} - $$gene{'start'} +1)/3);

	$result .= "     gene            ";
	$result .= "complement($$gene{start}..$$gene{stop})\n"
	    if ($$gene{'strand'});
	$result .= "$$gene{start}..$$gene{stop}\n"
	    if (!$$gene{'strand'});
	$result .= "                     /gene=\"$$gene{name}\"\n";
	
	$result .= sprintf("     %-10s      ", $$gene{'type'});
	$result .= "complement($$gene{start}..$$gene{stop})\n"
	    if ($$gene{'strand'});
	$result .= "$$gene{start}..$$gene{stop}\n"
	    if (!$$gene{'strand'});
	$result .= "                     /gene=\"$$gene{name}\"\n";
	
	$$gene{sequence} = &kernel::translate($$gene{sequence});
	
	$$gene{sequence} =~ s/\.$//;

	# Fetch the latest annotation information (comes later).
	my @annotation_arr = undef;	

	if (@annotation_arr) {
	  my $annotation = $annotation_arr[0];

	  $result .= &core::gbkentry("/note=\"$$annotation{'description'}\"") 
	      if ($$annotation{'description'});
	  
	  $$annotation{start_codon} = 1 if (!$$annotation{start_codon});
	  $result .= &core::gbkentry("/start_codon=\"$$annotation{start_codon}\"");
	  $result .= &core::gbkentry("/trans_table=\"11\"");
	  
	  $result .= &core::gbkentry("/product=\"$$annotation{gene_product}\"")
	      if ($$annotation{gene_product});
	  
	  $result .= &core::gbkentry("/protein_id1/=\"gid:$$gene{gid}\"");
	  $result .= &core::gbkentry("/function=\"$$annotation{primary_function}/$$annotation{secondary_function}\"")
	      if ($$annotation{primary_function} && $$annotation{secondary_function});
	  $result .= &core::gbkentry("/function=\"$$annotation{primary_function}\"")
	      if ($$annotation{primary_function} && !$$annotation{secondary_function});
	  $result .= &core::gbkentry("/EC_number=\"$$annotation{EC_number}\"") 
	      if ($$annotation{EC_number});
	}
	else {
	  $result .= &core::gbkentry("/protein_id=\"gid:$$gene{gid}\"");
	  $result .= &core::gbkentry("/codon_start=\"1\"");
	  $result .= &core::gbkentry("/product=\"Gene not annotated.\"") ;
	}


	# ending with printing the sequence...
	$result .=  &core::gbkentry("/translation=\"$$gene{sequence}\"");
      }   
      $result .= "ORIGIN\n";
      $result .= &core::gbk_DNAsequence($seq);
    }


    $html .= "<PRE>";
    $html .= "$result";
    $html .= "</PRE>";

    
  }

  return $html;
  
}


BEGIN {

}

END {

}

1;


