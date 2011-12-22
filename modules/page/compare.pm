#!/usr/bin/perl -wT
# 
# 
# 
# 
# Kim Brugger (May 2004), contact: brugger@mermaid.molbio.ku.dk

use strict;

package page::compare;
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

  my $html .= &mutagen_html::headline("Select sequences to align");

  if ($html::parameters{'align'}) {

    return ("<h3>One cannot create alignments using only one sequence</h3>", 1)
	if (ref $html::parameters{sids} ne "ARRAY");


    $html = &make_aligmnent_map($html::parameters{sids});

    my $top_size = 80*@{$html::parameters{sids}}+90;

    $html = &mutagen_html::make_form_page ("sequence", $html, $top_size, &mutagen_html::empty_web_page());

    return ($html, 2);

  }
  else {

    require db::sequence;
    require db::organism;

    # fetches all the organism names from the database.
    $html .= html::start_form('mutagen.pl');
    my @sequences = sort sort_organisms &db::sequence::all();
    
    my %sequence_labels=();

    # we split thing into viruses and plasmids 
    my @plasmid_list;
    my @virus_list;

    foreach my $sequence (@sequences) {
      my $organism = &db::organism::fetch($$sequence{'oid'});
      next if ($$organism{'type'} eq "organism");
      $sequence_labels{$$sequence{'sid'}} = $$sequence{'name'};

      push @plasmid_list, $$sequence{sid} if ($$organism{'type'} eq "plasmid");
      push @virus_list, $$sequence{sid}   if ($$organism{'type'} eq "virus");

    }
    

    if (@virus_list > 2) {
    
      $html .= &html::style::h3("Select sequences to align (viruses):");
      $html .= &html::checkbox_table({type=>'checkbox', 
				      name=>'sids',
				      values=>\@virus_list,
				      labels=>\%sequence_labels},2);
    }


    if (@plasmid_list > 2) {
      $html .= &html::style::h3("Select sequences to align (plasmids):");
      $html .= &html::checkbox_table({type=>'checkbox', 
				      name=>'sids',
				      values=>\@plasmid_list,
				      labels=>\%sequence_labels},2);
    }
    
    $html .= "<BR>\n";

    $html .= &html::generic_form_element({type=>'submit', name=>'align', value=>'Align sequences'});
    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"compare"});
    $html .= &access::session_form();

    $html .=  &html::end_form();
    
  }  
  
  return ($html, 1);


}


sub make_aligmnent_map {
  my ($sids) = @_;

  require graphics;
  
  require db::sequence;
  require db::gene;
  use  GD;

  my $gene_box_height = 70;
  my $box_space = 10;
  
  my ($width, $height) = (1000, ($gene_box_height) * @{$sids} + $box_space*(@{$sids}-1) + 5);
  my $image = new GD::Image($width, $height);
  $image->interlaced(1); 

  my $outfile = &kernel::tmpname();

#  print STDERR "$width, $height";

  &graphics::make_palette($image);

  my $html = "<CENTER>";
  $html .= "<div id='overDiv' style='position:absolute; visibility:hidden;'></div>\n";
  $html .= "<script langauge='JavaScript' src='../overlib.js'></script>\n";

  $html .="<IMG src='$outfile.png' USEMAP=#map1 ISMAP>\n";
  $html.= "<MAP NAME=map1>\n";

  my $step = 5;
  my $border = 10000;



  my %clusters = ();
  foreach my $sid (@{$sids}) {
    
    my @gids = &db::gene::fetch_organism(undef, undef, $sid);

    # first find all the clusters with at least one member in this picture.
    foreach my $gene (@gids) {
      if ($$gene{cid}) {      
	$clusters{$$gene{cid}}++;
      }
    }
  }


  
  foreach my $sid (@{$sids}) {
    
    my $sequence = &db::sequence::fetch($sid);

    my ($start, $stop) = (1, $$sequence{length});
    my @gids = &db::gene::fetch_organism(undef, undef, $sid);

    $html .= make_clustered_genes($image, \@gids, $gene_box_height - 20, $width, 
				  $start, $stop, $step, \%clusters);
      
    &graphics::make_title($image, $$sequence{'name'}, $width, 0, $step+$gene_box_height-20);
    
    $step += $gene_box_height+$box_space;
  }

#    last;
  $html.= "</MAP>\n";

  # print the picture.
  open (FIL, "> $outfile.png") or die "Could not open '$outfile.png': $!) : $!";
  binmode FIL;
  print FIL $image->png;
  close (FIL);

  return $html;
  

}


sub make_clustered_genes {
  require graphics;
  my ($image, $genes, $height, $width, $start, $stop, $yoffset, $clusters) = @_;

  my $barheight = 2;
  my $gene_map_height = ($height - &graphics::indexline_height($barheight) - 7)/2;
  my $comp_offset     =  &graphics::indexline_height($barheight) + 5+$gene_map_height +2;

  # this does not work since this next lines relies on the two lines above and vice versa. This SUCKS!!!!!
  &graphics::indexline($image, $gene_map_height+$yoffset, $width, $start, $stop, $graphics::colours{'black'}, $barheight);
#  print STDERR &graphics::indexline_height(). "------>>>>$height<<<< $gene_map_height ||| $gene_map_height\n";

  my $ORF_size = ($gene_map_height-5);
#  print STDERR "my $ORF_size = ($gene_map_height - $ORF_space *2)/3;\n";
  my $i=110;

  my $html = "";


      
  foreach my $gene (@$genes) {
    ($$gene{'start'},$$gene{'stop'}) = ($$gene{'stop'},$$gene{'start'}) 
	if ($$gene{'start'}>=$$gene{'stop'});

    my $x1 = ($width-40)/($stop-$start)*($$gene{'start'}-$start)+20;
    my $x2 = ($width-40)/($stop-$start)*($$gene{'stop'}-$start)+20;
    my $y1 = $yoffset;
    $y1 += $comp_offset if ($$gene{strand});
    my $y2 = $y1+$ORF_size;
	
    my $poly = new GD::Polygon;

    $poly->addPt($x1, $y1);
    $poly->addPt($x2, $y1);
    $poly->addPt($x2, $y2);
    $poly->addPt($x1, $y2);
 

    # If the gene is the member of a cluster, paint the gene that colour
    if ($$gene{ccolour} && $$clusters{$$gene{cid}} > 1) {

      $image->filledPolygon($poly, $graphics::colours{$$gene{ccolour}});

      my $poly2 = new GD::Polygon;
      $poly2->addPt($x1+1, $y1+1);
      $poly2->addPt($x2-1, $y1+1);
      $poly2->addPt($x2-1, $y2-1);
      $poly2->addPt($x1+1, $y2-1);
      
      $image->polygon($poly, $graphics::colours{'black'});
    }
    # Otherwise make it an empty box with black out lines.
    else {
      my $poly2 = new GD::Polygon;

      $poly2->addPt($x1+1, $y1+1);
      $poly2->addPt($x2-1, $y1+1);
      $poly2->addPt($x2-1, $y2-1);
      $poly2->addPt($x1+1, $y2-1);
      
      $image->filledPolygon($poly, $graphics::colours{'black'});
      $image->filledPolygon($poly2, $graphics::colours{'white'});
    }

    my $href = "../cbin/mutagen.pl?page=misc&gidinfo=$$gene{'gid'}" . &access::session_link();
#    my $href .= &core::
    $html .= "<AREA HREF='$href'".
	" TARGET='bottom' SHAPE=RECT COORDS='$x1,$y1,$x2,$y2' onmouseover=\"return overlib('gid:$$gene{'gid'} $$gene{'name'}');\" onmouseout=\"return nd();\">\n";

  }
  return $html;
  
}


sub sort_organisms {
  my ($A, $B) = ($a, $b);
  $$A{name} cmp $$B{name}
}

BEGIN {

}

END {

}

1;


