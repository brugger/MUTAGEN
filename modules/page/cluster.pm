#!/usr/bin/perl -wT
# 
# 
# 
# 
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;

package page::cluster;
require Exporter;
require AutoLoader;

# set the version for version checking
my $VERSION     = "0.01";

my @ISA = qw(VERSION Exporter AutoLoader);

our @EXPORT = qw();
@ISA = qw(Exporter AutoLoader);
@EXPORT = qw();


sub run {

  require mutagen_html;

  my $html;
  if ($html::parameters{'plot'} && $html::parameters{'plot'} eq "Sequence alignment (coffee)") {
    $html = &coffee_align($html::parameters{'gids'});
    return ($html, 1);
  }
  if ($html::parameters{'plot'} && $html::parameters{'plot'} eq "Sequence alignment (muscle)") {
    $html = &muscle_align($html::parameters{'gids'});
    return ($html, 1);
  }
  elsif ($html::parameters{'plot'} && $html::parameters{'plot'} eq "Genomic neighbourhood") {

    my $top = &homology_plot($html::parameters{'gids'});
    my $bottom = &mutagen_html::empty_web_page();
    $html .= &mutagen_html::make_form_page ("sequence", $top, 390, $bottom, 0);

    print STDERR $html;
    return ($html, 2);
  }
  elsif ($html::parameters{'plot'} && $html::parameters{'plot'} eq "Sequences in fasta format") {
    $html = sequences($html::parameters{'gids'});
    return ($html, 1);
  }
  else {
    $html .= homology_page($html::parameters{'cid'});
    return ($html, 1);
  }
 
  
}

# 
# Makes a table that displays all the protrins that are linked to a cluster id (cid)
# 
# Kim Brugger (01 Dec 2003)
sub homology_page  {
  my ($cid) = @_;
  require db::cluster;
  
  my @genes = &db::cluster::fetch($cid);

  my @cells = ();
  push @cells,  ["gid", "name", "organism", "version", "length (AA)"];
  use Data::Dumper;

#  print STDERR Dumper \@genes;
  
  foreach my $gene (@genes) {
    $$gene{'length'} =~ s/\.\d+//;
    push @cells, [&html::generic_form_element({type=>"checkbox", name=>"gids", value=> $$gene{'gid'}})."gid:$$gene{'gid'}", 
		  $$gene{'name'}, $$gene{'org_name'}, $$gene{'version'}, $$gene{'length'}];
  }

  my $html = "<h2>Cluster list of members with cid = cid:$cid</h2>";
  

  $html .= &html::start_form("../cbin/mutagen.pl", undef, "comparrison");
  $html .= &html::table(\@cells, 1, 2, 2);
  

  
#  $html .= &html::generic_form_element({type=>"submit", name=>"plot", value=>"Sequence alignment (coffee)"}) . "&nbsp;";
  $html .= &html::generic_form_element({type=>"submit", name=>"plot", value=>"Sequence alignment (muscle)"}) . "&nbsp;";
  $html .= &html::generic_form_element({type=>"submit", name=>"plot", value=>"Sequences in fasta format"}) . "&nbsp;";
  $html .= &html::generic_form_element({type=>"submit", name=>"plot", value=>"Genomic neighbourhood"}) . "&nbsp;";


  $html .= &html::generic_form_element({type=>"hidden", name=>"page", value=>"cluster"});

  $html .= &access::session_form();
  $html .= &html::end_form();

  return $html;
}


sub sequences {
  my ($gids) = @_;
  require mutagen_html::subpage;

  my $html = "";
  foreach my $gid (@{$gids}) {
    $html .= mutagen_html::subpage::gene_seq($gid);
  }

  return $html;
}



# Multiple alignment using muscle.
# 
# 
# Kim Brugger (05 Jul 2005)
sub muscle_align {
  my ($gids) = @_;

  require core;
  require db::gene;
  my $tmp_fasta = &kernel::tmpname; 
  
  open OUTFILE, "> $tmp_fasta" or die "Could not open '$tmp_fasta': $!\n";
  foreach my $gid (@{$gids}) {
    my $gene = &db::gene::fetch($gid);
    $$gene{'sequence'} = &kernel::translate($$gene{'sequence'});
    print OUTFILE ">gid:$$gene{'gid'}\n" . &kernel::nicefasta($$gene{'sequence'}) . "\n";
  }

  my $run = "$conf::muscle -clw -in $tmp_fasta -out $tmp_fasta.aln";

  system "cd ../tmp;$run > /dev/null 2>&1";

  my $html = "<H3>The Report</H3><PRE>\n";
  open (INFIL, "< $tmp_fasta.aln") || die "Could not open muscle-report '$tmp_fasta.aln': $!";
  while (<INFIL>) {
    $html .= $_;
  }

  close (INFIL) || die "Could not close muscle-report '$tmp_fasta.aln': $!";
  
  $html .= "<PRE>\n";

  system "rm /$tmp_fasta* \n";

  return $html;
}



sub coffee_align {
  my ($gids) = @_;

  require core;
  require db::gene;
  my $tmp_fasta = &kernel::tmpname; 
  
  open OUTFILE, "> $tmp_fasta" or die "Could not open '$tmp_fasta': $!\n";
  foreach my $gid (@{$gids}) {
    my $gene = &db::gene::fetch($gid);
    $$gene{'sequence'} = &kernel::translate($$gene{'sequence'});
    print OUTFILE ">gid:$$gene{'gid'}\n" . &kernel::nicefasta($$gene{'sequence'}) . "\n";
  }

  my $run = "$conf::t_coffee $tmp_fasta";

  system "cd ../tmp;$run > /dev/null 2>&1";

  my $html = "<H3>The Report</H3><PRE>\n";
  open (INFIL, "< $tmp_fasta.aln") || die "Could not open t_coffe-report '$tmp_fasta.aln': $!";
  while (<INFIL>) {
    $html .= $_;
  }

  close (INFIL) || die "Could not close t_coffe-report '$tmp_fasta.aln': $!";
  
  $html .= "<PRE>\n";

  system "rm /$tmp_fasta* \n";

  return $html;
}

sub homology_plot {
  my ($gids) = @_;
  
  require graphics;
  
  require db::sequence;
  require db::gene;
  use  GD;

  my $gene_box_height = 70;
  my $box_space = 10;
  
  my ($width, $height) = (1000, ($gene_box_height) * @{$gids} + $box_space*(@{$gids}-1) + 5);
  my $image = new GD::Image($width, $height);
  $image->interlaced(1); 

#  print STDERR "$width, $height";

  &graphics::make_palette($image);

  my $outfile = &kernel::tmpname();

  my $html = "<CENTER>";
  $html .= "<div id='overDiv' style='position:absolute; visibility:hidden;'></div>\n";
  $html .= "<script langauge='JavaScript' src='../overlib.js'></script>\n";

  $html .="<IMG src='$outfile.png' USEMAP=#map1 ISMAP>\n";
  $html.= "<MAP NAME=map1>\n";

  my $step = 5;
  my $border = 10000;
  


  my %clusters = ();
  foreach my $gid (@{$gids}) {
    
    my $gene = &db::gene::fetch($gid);
    my $sequence = &db::sequence::fetch($$gene{'sid'});

    my ($start, $stop) = ($$gene{'start'} - $border, $$gene{'stop'}+$border);
    $start = 1 if ($start <1);
    $stop = $$sequence{'length'} if ($stop> $$sequence{'length'});

    my @genes = &db::gene::fetch_organism(undef, undef, $$gene{'sid'}, $start, $stop);
    foreach my $gene (@genes) {
      if ($$gene{cid}) {      
	$clusters{$$gene{cid}}++;
      }
    }
    
  }

  foreach my $gid (@{$gids}) {
    
    my $gene = &db::gene::fetch($gid);
    my $sequence = &db::sequence::fetch($$gene{'sid'});

    my ($start, $stop) = ($$gene{'start'} - $border, $$gene{'stop'}+$border);
    $start = 1 if ($start <1);
    $stop = $$sequence{'length'} if ($stop> $$sequence{'length'});

    my @genes = &db::gene::fetch_organism(undef, undef, $$gene{'sid'}, $start, $stop);

#    &graphics::BOX($image, $width-40, $gene_box_height, $graphics::colours{'blue'}, 20, $step);


    $html .= make_clustered_genes($image, \@genes, $gene_box_height - 20, $width, $start, $stop, $step, \%clusters);

    &graphics::make_title($image, $$sequence{'name'}, $width, 0, $step+$gene_box_height-20);

    $step += $gene_box_height+$box_space;


#    last;
  }
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

#exported variables.
use vars qw ();

BEGIN {

}

END {

}

1;


