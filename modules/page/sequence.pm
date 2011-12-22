#!/usr/bin/perl -wT
# 
# 
# 
# 
# Kim Brugger (Dec 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;

package page::sequence;
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

sub run {

  my $html = "";
  require mutagen_html;

  if ($html::parameters{'subpage'} && $html::parameters{'subpage'} eq "browse") {
    require page::sequence::browse;
    

    if ($html::parameters{'ORFmap'}) {

      $html .= &page::sequence::browse::make_ORF_map();
      $html = &mutagen_html::make_form_page ("sequence", $html, 290, &mutagen_html::empty_web_page(),0);
      return ($html, 2);
    }
    elsif ($html::parameters{'RAWmap'}) {

      $html .= &page::sequence::browse::make_RAW_map();
      $html = &mutagen_html::make_form_page ("sequence", $html, 320, &mutagen_html::empty_web_page(),1);
      return ($html, 2);
    }
    elsif ($html::parameters{'gfinders'}) {
      $html .= &page::sequence::browse::gfinders($html::parameters{'gid'});
      $html = &mutagen_html::make_form_page ("sequence", $html, 290, &mutagen_html::empty_web_page(),1);
#      print STDERR "$html\n";
      return ($html, 2);
    }
    elsif ($html::parameters{'menu'}) {
      if ($html::parameters{'menu'} eq "zoom") {
	$html .= &page::sequence::browse::zoom();
	return ($html, 0);
      }
      elsif ($html::parameters{'menu'} eq "new_gene") {
	$html .= &page::sequence::browse::new_gene();
	return ($html, 0);
      }
      elsif ($html::parameters{'menu'} eq "ccodes") {
	
      }
      else {
	$html .= &mutagen_html::empty_page();
      }
    }
    
    return ($html,0);

  }
  elsif ($html::parameters{'subpage'} && $html::parameters{'subpage'} eq "export") {
    require page::sequence::export;
    $html .= &page::sequence::export::extract_page();
  }
  elsif ($html::parameters{'orfmap'} && $html::parameters{'orfmap'} ne "") {

    require page::sequence::browse;

    $html .= &page::sequence::browse::make_ORF_map($html::parameters{'orfmap'});
    require mutagen_html;
    $html = &mutagen_html::make_form_page ("sequence", $html, 290, &mutagen_html::empty_web_page(),0);
#    print STDERR "$html\n";
    return ($html, 2);
    
  }
  elsif ($html::parameters{'subpage'} && $html::parameters{'subpage'} eq "pathways") {
    require page::sequence::pathways;
    $html .= &page::sequence::pathways::show_pathway();
  }
  elsif ($html::parameters{'seq_export'}) {
    require page::sequence::export;
    $html .= &page::sequence::export::extract_page();
  }  
  elsif ($html::parameters{'seq_browse'}) {
    require page::sequence::browse;
    $html .= &page::sequence::browse::sequence_select();
  }  
  elsif ($html::parameters{'seq_pathways'}) {
    require page::sequence::pathways;
    $html .= &page::sequence::pathways::pathway_select();
  }  
  else {


    $html .= &mutagen_html::headline("Sequences in the database");

    # The table is to be split up into genomes, viruses and plasmids.
    # So the various types gets inserted here into thir respectively arrays.

    my @ocells = ["<B>Organisms</B>", "&nbsp;","&nbsp;"];
    # If we are using a more "advanced" MUTAGEN setup 
    push @{$ocells[@ocells-1]}, "&nbsp;" 
	if ($conf::html_level & $conf::html_pathways);
    push @{$ocells[@ocells-1]}, "<B>Sequence version</B>" 
	if ($conf::html_level & $conf::html_version);

    my @vcells = ["<B>Viruses</B>", "&nbsp;","&nbsp;"];
    # If we are using a more "advanced" MUTAGEN setup 
    push @{$vcells[@vcells-1]}, "<B>Sequence version</B>" 
	if ($conf::html_level & $conf::html_version);
    

    my @pcells = ["<B>Plasmids</B>", "&nbsp;","&nbsp;"];
    # If we are using a more "advanced" MUTAGEN setup 
    push @{$pcells[@pcells-1]}, "<B>Sequence version</B>" 
	if ($conf::html_level & $conf::html_version);

    my %vcells = ();
    my %pcells = ();

    require db::organism;
    require db::version;

    # fetches all the organism names from the database.

    my @organisms = &db::organism::all();
    @organisms = sort { $$a{'name'} cmp $$b{'name'}}@organisms;

    foreach my $organism (@organisms) {
      
      # Check and see if the user have access to this organism.
      next if (&access::check_access(undef, undef, $$organism{oid}));
      
      # find all the versions for each sequence so the use can select between them
      my @versions = &db::version::fetch_all($$organism{'oid'});
      my %labels = ();
      for (my $i = 0; $i<@versions;$i++) {
	$labels{$versions[$i]{'vid'}} = "Version $versions[$i]{'version'}";
	$versions[$i] = $versions[$i]{'vid'};
      }
      
      my @lcells =  (
		   html::start_form('mutagen.pl').
		     "$$organism{'name'}",
		    
		     &html::generic_form_element({type=>'submit', name=>'seq_browse', 
						  value=>"Browse sequence"}),
		     &html::generic_form_element({type=>'submit', name=>'seq_export', 
						  value=>"Export sequence"}));



      push @lcells, &html::generic_form_element({type=>'submit', name=>'seq_pathways', 
						 value=>"Pathways"}) 
	  if ($$organism{type} eq "organism" && $conf::html_level & $conf::html_pathways);
	    
		    

      
      push @lcells, &html::generic_form_element({type=>'popup', name=>'vid', 
						 values=>\@versions, labels=>\%labels, 
						 default => $versions[@versions-1]})
	  if ($conf::html_level & $conf::html_version);
      

      $lcells[@lcells-1] .= &html::generic_form_element({type=>'hidden',name=>'oid', 
							 value=>$$organism{'oid'}});
      $lcells[@lcells-1] .= &html::generic_form_element({type=>'hidden',name=>'page', 
							       value=>"sequence"});
      $lcells[@lcells-1] .= &access::session_form(). &html::end_form();
      


      
      push @ocells, \@lcells if ($$organism{type} eq "organism");
      push @{$pcells{ $$organism{ 'subtype' }}}, \@lcells if ($$organism{type} eq "plasmid");
      push @{$vcells{ $$organism{ 'subtype' }}}, \@lcells if ($$organism{type} eq "virus");


    }
    
    # now collect all the data in a cells array.
    
    my @cells;

    push @cells, @ocells, []
	if (@ocells >= 2);

    if ( keys %vcells) {
      push @cells, @vcells;
      foreach my $subtype ( sort keys %vcells ) {
	push @cells, ["<B>$subtype</B>", "&nbsp;","&nbsp;"];
	push @cells, @{$vcells{ $subtype }};
      }
    }

    if ( keys %pcells) {
      push @cells, @pcells;
      foreach my $subtype ( sort keys %pcells ) {
	push @cells, ["<B>$subtype</B>", "&nbsp;","&nbsp;"];
	push @cells, @{$pcells{ $subtype }};
      }
    }


    $html .= &html::style::center(&html::table(\@cells, 0, 1, 1, undef, "98%"));


  } 
  return ($html, 1);
}

BEGIN {

}

END {

}

1;








