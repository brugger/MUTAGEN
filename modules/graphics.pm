#!/usr/bin/perl -wT
# 
# Graphic module, which will make gene maps and much more(tm)
# 
# 
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;

use GD;

package graphics;
require Exporter;
require AutoLoader;

# set the version for version checking
my $VERSION     = "0.01";

my @ISA = qw(VERSION Exporter AutoLoader);

our @EXPORT = qw();
@ISA = qw(Exporter AutoLoader);
@EXPORT = qw();

#exported variables
use vars qw (%colours);

my $indexline_height = 16;

sub indexline_height {
  my ($barheight) = @_;
  return (GD::gdSmallFont->height + $barheight+2) if ($barheight);
  return (GD::gdSmallFont->height + $indexline_height+2);
}

sub indexline {
  my ($image, $pos, $width, $start, $stop, $colour, $barheight, $bar_delta) = @_;

  $image->line(20,$pos, $width - 20, $pos, $colour);

  if ($barheight) {
    $image->line(20,$pos,20,$pos + $barheight, $colour);
    $image->string(GD::gdSmallFont,20-(GD::gdSmallFont->width),
		   $pos+GD::gdSmallFont->height/2 + $barheight-2, $start, $colour);
    $indexline_height = $barheight;
  }
  else { 
    $image->line(20,$pos - 5,20,$pos + 5, $colour);
    $image->string(GD::gdSmallFont,20-(GD::gdSmallFont->width),
		   $pos+GD::gdSmallFont->height/2, $start, $colour);
  }

  # Apparently something odd happens here, so this is the way to do it. (perl vs me: 1 - 0) 
  my $delta = $stop-$start;
  my $st = undef;

  if (($delta) > 1000000) {
    $st = 1000000;
  }
  elsif (!$st && $delta > 100000) {
    $st = 100000;
  }
  elsif (!$st && $delta > 10000) {
    $st = 10000;
  }
  elsif (!$st && $delta > 1000) {
    $st = 1000;
  }
  else {
    $st = 100;
  }

  $st = $bar_delta if ($bar_delta);

#  print STDERR "ST :: $st\n";

  # Thea rest of the vertical index lines
  for (my $i = $start + $st-1; $i < $stop; $i+=$st) {
    
    # We like to make the line is whole numbers ($st idents)
    my $mod_i = $i;
    $mod_i /= $st;
    $mod_i =~ s/\.\d+$//;
    $mod_i *= $st;


#    print STDERR "MOD_I === $mod_i  -- ".($mod_i - $start) . "|||". ($st/3)."\n";    
    next if ($start - $mod_i >  - ($st/3));
    next if ($stop - $mod_i <  ($st/3));


    
    my $step = (($width-40)*($mod_i-$start)/($stop-$start+1))+20;

    if ($barheight) {
      $image->line($step,$pos,$step,$pos + $barheight, $colour);
      $image->string(GD::gdSmallFont,$step-(GD::gdSmallFont->width),
  		     $pos+GD::gdSmallFont->height/2 + $barheight-2, $mod_i, $colour);

    }
    else {
      $image->line($step,$pos - 5,$step,$pos + 5, $colour);
      $image->string(GD::gdSmallFont,$step-(GD::gdSmallFont->width),
  		     $pos+GD::gdSmallFont->height/2, $mod_i, $colour);
    }
  }

  #The last vertical index line
  if (1) {

    if ($barheight) {
      $image->line($width - 20,$pos,$width - 20,$pos + $barheight, $colour);
      $image->string(GD::gdSmallFont,$width -40-(GD::gdSmallFont->width),
  		     $pos+GD::gdSmallFont->height/2 + $barheight-2, $stop, $colour);
    }
    else {
      $image->line($width - 20,$pos - 5,20,$pos + 5, $colour);
      $image->string(GD::gdSmallFont,$width - 40 -(GD::gdSmallFont->width),
  		     $pos+GD::gdSmallFont->height/2, $stop, $colour);
    }
  }

  return $image;
}



sub BOX {
  my ($image, $width, $height, $colour, $xoffset, $yoffset) = @_;

  # Box surrounding
  $image->line(0+$xoffset,        $height-1+$yoffset, $width-1+$xoffset, $height-1+$yoffset, $colour);
  $image->line(0+$xoffset,        0+$yoffset,         $width-1+$xoffset, 0+$yoffset,         $colour);
  $image->line(0+$xoffset,        0+$yoffset,         0+$xoffset,        $height-1+$yoffset, $colour);
  $image->line($width-1+$xoffset, 0+$yoffset,         $width-1+$xoffset, $height-1+$yoffset, $colour);

  #box Cross.
  $image->line(0+$xoffset,        $height-1+$yoffset, $width+$xoffset, 0+$yoffset,         $colour);
  $image->line(0+$xoffset,        0+$yoffset,         $width+$xoffset, $height-1+$yoffset, $colour);

  return $image;

}


BEGIN {

}

END {

}

sub make_palette {
  my ($image) = @_;

  # the first colour made is the background, so lets make 
  # sure that the first colour allocated is white. 
  # GOD how I hate the stupidity of the GD package.
  $colours{white} = $image->colorAllocate(255,255,255);

  foreach my $key (keys %global::colours) {
    my ($r,$g,$b) = @{$global::colours{$key}};
    $colours{$key} = $image->colorAllocate($r,$g,$b);
  }

  return undef;
}

sub make_3frame_genes {
  my ($image, $genes, $height, $width, $start, $stop, $yoffset, $ORF_space) = @_;

  require graphics;
  
  # How large the indicator bar is 
  my $barheight = 1;
  my $gene_map_height = $height/2 - &graphics::indexline_height($barheight) - 7;
  # calcute the offset for complementary strand, such as numbers and bar-lines.
  my $comp_offset     =  &graphics::indexline_height($barheight) + 5+$gene_map_height +2;

  &graphics::indexline($image, $gene_map_height+$yoffset+5, $width, $start, $stop, $graphics::colours{'black'}, $barheight);
#  print STDERR &graphics::indexline_height(). "------>>>> \n";

  my $ORF_size = ($gene_map_height - $ORF_space *2)/3;
#  print STDERR "my $ORF_size = ($gene_map_height - $ORF_space *2)/3;\n";
  my $i=110;

  my $html = "";
      
  foreach my $gene (@$genes) {
    # check that the gene is defined.
    next if (!$gene || ref $gene ne "HASH");

    # ensure that the start postion is ALWAYS lowest.
    ($$gene{'start'},$$gene{'stop'}) = ($$gene{'stop'},$$gene{'start'}) 
	if ($$gene{'start'}>=$$gene{'stop'});

    my ($x1, $x2, $y1, $y2, $colour, $marking);

    # there is a problem if there is an intron or a gene is broken
    # into two fragments by base 1 (KEN STEDMAN YOUR BASTARD: 3 TIMES
    # IS A SIN!!!)  then a long gene. This we have to fix here. So
    # lets roll up the sleves and get cracking..
    
    if ($$gene{intron} && $$gene{intron} =~ /-/) {
      my ($istart, $istop) = split("->", $$gene{intron});
      my ($ostart, $ostop) = ($$gene{start}, $$gene{stop});

      print STDERR "($istart - $istop) ==== ($$gene{start} - $$gene{stop});\n";
      $$gene{start} = $ostop;
      $$gene{stop} = $istart;
      print STDERR "($istart - $istop) ==== ($$gene{start} - $$gene{stop});\n";
      
      $$gene{type} = "INTRON";
      $$gene{colour} = 42;
      
      if (1) {
	my %rest_gene = %$gene;
	$rest_gene{start} = $istop;
	$rest_gene{stop}  = $ostart;
	print STDERR "($rest_gene{start} $rest_gene{stop}) ==== ($$gene{start} - $$gene{stop});\n";
	delete $rest_gene{intron};
	push @$genes, \%rest_gene;
      }
    }


    # next step is to actually draw the normal gene.
    if ($global::gene_types{$$gene{type}}{map_pos} == 1) {
      
      my $frame = ($$gene{'start'})%3;
      $x1 = ($width-40)/($stop-$start)*($$gene{'start'}-$start)+20;
      $x2 = ($width-40)/($stop-$start)*($$gene{'stop'}-$start)+20;
      $y1 = $yoffset+$frame*$ORF_space+$frame*$ORF_size;
      $y1 += $comp_offset if ($$gene{strand});
      $y2 = $y1+$ORF_size-1;

    }
    else {

      $x1 = ($width-40)/($stop-$start)*($$gene{'start'}-$start)+20;
      $x2 = ($width-40)/($stop-$start)*($$gene{'stop'}-$start)+20;

      $y1 = $yoffset+3*$ORF_space+3*$ORF_size-8;
      $y2 = $y1+6;
    }

    # if the genes has been annotated, but a box around the gene.
    $marking = $$gene{colour};
    $marking /= 100;
    $marking %= 10;
    $colour = $$gene{colour} %= 100;

    # check wether we should frame the gene (meaning that the gene is annotated)
    if (($marking & 1) == 1) {

      my $poly2 = new GD::Polygon;
      $poly2->addPt($x1, $y1);
      $poly2->addPt($x2, $y1);
      $poly2->addPt($x2, $y2);
      $poly2->addPt($x1, $y2);
      
      $image->filledPolygon($poly2, $graphics::colours{'black'});
      $x1++;$x2--;$y1++;$y2--;
    }

    my $poly2 = new GD::Polygon;

    $poly2->addPt($x1, $y1);
    $poly2->addPt($x2, $y1);
    $poly2->addPt($x2, $y2);
    $poly2->addPt($x1, $y2);
 
#    &core::Dump($gene);

    $image->filledPolygon($poly2, $graphics::colours{$colour});

    # a cross showing that the gene is TAGGED !!
    if ($marking && $marking == 2) {

      my $poly2 = new GD::Polygon;
      $image->line($x1, $y1, $x2, $y2, $graphics::colours{'black'});
      $image->line($x1, $y2, $x2, $y1, $graphics::colours{'black'});
    }

#    print STDERR "$$gene{'gid'}--$$gene{'start'} -- $$gene{'stop'}--$y1\-$y2\n" if ($i<20); $i++;
#    print STDERR "$$gene{'gid'}--$$gene{'start'} -- $$gene{'stop'}--$x1\-$x2\n" if ($i<20); $i++;

    my $href = "../cbin/mutagen.pl?page=misc&gidinfo=$$gene{'gid'}" . &access::session_link();
    $html .= "<AREA HREF='$href'".
	" TARGET='bottom' SHAPE=RECT COORDS='$x1,$y1,$x2,$y2' onmouseover=\"return overlib('gid:$$gene{'gid'} $$gene{'name'}');\" onmouseout=\"return nd();\">\n";

  }

#  &graphics::BOX($image, $width-40, $gene_map_height, $blue, 20, $yoffset);
#  &graphics::BOX($image, $width-40, $gene_map_height, $blue, 20, $yoffset+$comp_offset);

  return $html;
}




sub make_3frame_raw {
  my ($image, $genes, $sequence, $height, $width, $start, $stop, $yoffset, $ORF_space) = @_;

  require graphics;

  use GD;
  
  # How large the indicator bar is 
  my $barheight = 10;
  my $gene_map_height = $height/2 - &graphics::indexline_height($barheight) - 7;
  # calcute the offset for complementary strand, such as numbers and bar-lines.
  my $comp_offset     =  &graphics::indexline_height($barheight) + 5+$gene_map_height +2;

  &graphics::indexline($image, $gene_map_height+$yoffset+5, $width, 
		       $start, $stop, $graphics::colours{'black'}, $barheight, 50);

  my $ORF_size = ($gene_map_height - $ORF_space *2)/3;
#  print STDERR "my $ORF_size = ($gene_map_height - $ORF_space *2)/3;\n";
  my $i=110;

  my $html = "";
  
#  $start--;
      
  foreach my $gene (@$genes) {
    
    # check that the gene is defined.
    next if (!$gene || ref $gene ne "HASH");

    ($$gene{'start'},$$gene{'stop'}) = ($$gene{'stop'},$$gene{'start'}) 
	if ($$gene{'start'}>=$$gene{'stop'});

    my $frame = ($$gene{'start'})%3;

    my $x1 = (($width-40)*($$gene{'start'}-$start))/($stop-$start+1)+20;
    my $x2 = (($width-40)*($$gene{'stop'}-$start))/($stop-$start+1)+20;

    my $y1 = $yoffset+$frame*$ORF_space+$frame*$ORF_size-20;
    # Here we will make sure that the genes on the minus strand gets
    # moved to the downpart of the picture.
    $y1 += $comp_offset+19 if ($$gene{strand});
    my $y2 = $y1+$ORF_size-1;

    # The gene can also be locate on the DNA level, so lets position those here.
    if ($global::gene_types{$$gene{type}}{map_pos} == 0) {

      $x2 += gdLargeFont->width;
      $y1 = $yoffset+3*$ORF_space+3*$ORF_size-11;
      # Here we will make sure that the genes on the minus strand gets
      # moved to the downpart of the picture.
      $y1 += 17 if ($$gene{strand});
      $y2 = $y1+$ORF_size-2;
    }
    else {
      # Make the picture look a bit better by adding a single 
      # extra "letter" at the ends of the ORFS.
      if (!$$gene{strand}) {
	$x1 -= gdLargeFont->width; 
#	$x2 -= gdLargeFont->width/2;
      }
      else {
	$x1 += gdLargeFont->width; 
	$x2 += gdLargeFont->width*2;
      }
    }

    # if the genes has been annotated, but a box around the gene.
    my $marking = $$gene{colour};
    $marking /= 100;
    $marking %= 10;
    my $colour = $$gene{colour} %= 100;

    # check wether we should frame the gene (meaning that the gene is annotated)
    if (($marking & 1) == 1) {

      my $poly2 = new GD::Polygon;
      $poly2->addPt($x1, $y1);
      $poly2->addPt($x2, $y1);
      $poly2->addPt($x2, $y2);
      $poly2->addPt($x1, $y2);
      
      $image->filledPolygon($poly2, $graphics::colours{'black'});
      $x1++;$x2--;$y1++;$y2--;
    }

    my $poly2 = new GD::Polygon;

    $poly2->addPt($x1, $y1);
    $poly2->addPt($x2, $y1);
    $poly2->addPt($x2, $y2);
    $poly2->addPt($x1, $y2);
 
    $image->filledPolygon($poly2, $graphics::colours{$colour});


    # a cross showing that the gene is TAGGED !!
    if (($marking & 2) == 2) {

      my $poly2 = new GD::Polygon;
      $image->line($x1, $y1, $x2, $y2, $graphics::colours{'black'});
      $image->line($x1, $y2, $x2, $y1, $graphics::colours{'black'});
    }

#    print STDERR "$$gene{'gid'}--$$gene{'start'} -- $$gene{'stop'}--$y1\-$y2\n" if ($i<20); $i++;

    my $href = "../cbin/mutagen.pl?page=misc&gidinfo=$$gene{'gid'}". &access::session_link();

    $html .= "<AREA HREF='$href'".
	" TARGET='bottom' SHAPE=RECT COORDS='$x1,$y1,$x2,$y2' onmouseover=\"return overlib('gid:$$gene{'gid'} $$gene{'name'}');\" onmouseout=\"return nd();\">\n";

  }


  $start--;$stop--;

  # add the sequence to the picture.
  use GD;
  
  my $at_the_end = ($stop >= length($sequence));

  #first the DNA sequence 
  my $seq = substr($sequence, $start, $stop-$start+1);
  $image =  DNA_sequence($image, 20, 87, $seq);

  # Things are a bit more difficult with the minus strand...
  # First the DNA sequence.
  $seq = reverse(&kernel::revDNA($seq));
  $image =  DNA_sequence($image, 20, 104, $seq, 1);
  
  # add the AA in the first 3 frames (plus strand).
  for (my $i = 0 ; $i < 3; $i++) {
    my $sub_seq = substr ($sequence, $start+$i, $stop-$start+1-$i);

    # first create the sequence we want to put into the picture.
    # An importaint note is that the sting is spaced & padded with '-'
    $sub_seq = &kernel::translate($sub_seq, 1);
    $sub_seq = "-"x$i. join ("--", split //, $sub_seq);
    $sub_seq .= "-"x($stop-$start+1-length($sub_seq));

    # calculate the position of the sequence.

    my $frame = ($start+$i+1)%3;

    my $y1 = $yoffset-20+$frame*$ORF_space+$frame*$ORF_size;

    $image =  sequence($image, 20, $y1, $sub_seq);
  }
  
  # add the anti-sense DNA and AA in all 3 frames.
  for (my $i = 0 ; $i < 3; $i++) {
#    print STDERR "seq from ". ($start)." to ".($stop-$start+1)."\n";

    my $sub_seq = &kernel::revDNA(substr ($sequence, $start, $stop-$start+1-$i));

    $sub_seq = reverse (&kernel::translate($sub_seq, 1));
    $sub_seq = join ("--", split //, $sub_seq)."-"x$i;
    $sub_seq = "-"x($stop-$start+1-length($sub_seq)).$sub_seq;

    my $frame = ($stop-$i+2)%3;

    my $y1 = $yoffset-20+$frame*$ORF_space+$frame*$ORF_size+$comp_offset+19;

    $image =  sequence($image, 20, $y1, $sub_seq);
  }

#  &graphics::BOX($image, $width-40, $gene_map_height, $blue, 20, $yoffset);
#  &graphics::BOX($image, $width-40, $gene_map_height, $blue, 20, $yoffset+$comp_offset);

  return $html;
}


# 
# Enters a centered title for a picture (or a name for a sequence)
# 
# Kim Brugger (11 Dec 2003)
sub make_title {
  my ($image, $text, $width, $xoffset, $yoffset) = @_;

  my $text_width += (length($text) * GD::gdLargeFont->width);
  
  my $xpos = ($width - $text_width - $xoffset) /2;
  
  $image->string(GD::gdLargeFont, , $xpos, 
		 $yoffset, $text, $graphics::colours{'blue'});

}


#
# Makes the DNA sequence for the RAW browsee
#
sub DNA_sequence {
  my ($image, $X1, $Y1, $DNAseq, $rev) = @_;
  
  $image->string(gdLargeFont,$X1,$Y1, $DNAseq, $graphics::colours{'black'});

  my $sequence = $DNAseq;
  $sequence = reverse ($sequence) if ($rev);

  if ($sequence =~ /ATG/) {
    # Mark the start codon sequence
    $sequence =~ s/(.*?)(ATG)/" "x(length($1)) . $2/ge;
    $sequence =~ s/(.*ATG)(.*)\Z/$1." "x(length($2))/ge;
    
    $sequence = reverse ($sequence) if ($rev);

    $image->string(gdLargeFont,$X1,$Y1, $sequence, $graphics::colours{'red'});
  }

  $sequence = $DNAseq;
  $sequence = reverse ($sequence) if ($rev);

  if ($sequence =~ /TTG/) {
    # Mark the start codon sequence
    $sequence =~ s/(.*?)(TTG)/" "x(length($1)) . $2/ge;
    $sequence =~ s/(.*TTG)(.*)\Z/$1." "x(length($2))/ge;

    $sequence = reverse ($sequence) if ($rev);

    $image->string(gdLargeFont,$X1,$Y1, $sequence, $graphics::colours{'red'});
  }

  $sequence = $DNAseq;
  $sequence = reverse ($sequence) if ($rev);
			 
  if ($sequence =~ /GTG/){	 
    # Mark the start codon sequence
    $sequence =~ s/(.*?)(GTG)/" "x(length($1)) . $2/ge;
    $sequence =~ s/(.*GTG)(.*)\Z/$1." "x(length($2))/ge;
    
    $sequence = reverse ($sequence) if ($rev);
    $image->string(gdLargeFont,$X1,$Y1, $sequence, $graphics::colours{'red'});
  }


  $sequence = $DNAseq;
  $sequence = reverse ($sequence) if ($rev);
			 
  if ($sequence =~ /TAG/){	 
    # Mark the start codon sequence
    $sequence =~ s/(.*?)(TAG)/" "x(length($1)) . $2/ge;
    $sequence =~ s/(.*TAG)(.*)\Z/$1." "x(length($2))/ge;
    
    $sequence = reverse ($sequence) if ($rev);
    $image->string(gdLargeFont,$X1,$Y1, $sequence, $graphics::colours{'blue'});
  }

  if ($sequence =~ /TAA/){	 
    # Mark the start codon sequence
    $sequence =~ s/(.*?)(TAA)/" "x(length($1)) . $2/ge;
    $sequence =~ s/(.*TAA)(.*)\Z/$1." "x(length($2))/ge;
    
    $sequence = reverse ($sequence) if ($rev);
    $image->string(gdLargeFont,$X1,$Y1, $sequence, $graphics::colours{'blue'});
  }

  if ($sequence =~ /TGA/){	 
    # Mark the start codon sequence
    $sequence =~ s/(.*?)(TGA)/" "x(length($1)) . $2/ge;
    $sequence =~ s/(.*TGA)(.*)\Z/$1." "x(length($2))/ge;
    
    $sequence = reverse ($sequence) if ($rev);
    $image->string(gdLargeFont,$X1,$Y1, $sequence, $graphics::colours{'blue'});
  }


  return $image;
}

#
# Makes the AA for the RAW browsee
#
sub sequence {
  my ($image, $X1, $Y1, $sequence) = @_;

  $image->string(gdLargeFont,$X1,$Y1, $sequence, $graphics::colours{'black'});

  $sequence =~ s/[^M]/ /g;

  $image->string(gdLargeFont,$X1,$Y1, $sequence, $graphics::colours{'red'});

  return $image;
}


sub make_menu {
  my ($image, $menu, $width, $space, $xoffset, $yoffset) = @_;

  my $text_width = 0;
  foreach my $text (@$menu){
    $text_width += (length($$text{'text'}) * GD::gdSmallFont->width) + $space;
  }
  $text_width -= $space;

  my $html = "";
  my $xpos = ($width - $text_width + $xoffset*2) /2;
  foreach my $text (@$menu){

    $image->string(GD::gdSmallFont, , $xpos, 
		   $yoffset, $$text{'text'}, $graphics::colours{'blue'});

    $image->line($xpos, GD::gdSmallFont->height + $yoffset,
		 $xpos + (length($$text{'text'}) * GD::gdSmallFont->width), GD::gdSmallFont->height + $yoffset,
		 $graphics::colours{'red'});
    
    my $href = "../cbin/mutagen.pl?$$text{'link'}" . &access::session_link();

    $html .= qq/<AREA HREF='$href'/;
    $html .= "SHAPE=RECT COORDS='$xpos,$yoffset";
    $html .= ",".($xpos + (length($$text{'text'}) * GD::gdSmallFont->width));
    $html .= ",".(GD::gdSmallFont->height + $yoffset)."' target='bottom'>\n";

    $xpos += (length($$text{'text'}) * GD::gdSmallFont->width) + $space;
  }

  return $html;
}

sub make_arrows {
  my ($image, $start, $stop, $width, $xoffset, $yoffset, $link, $length) = @_;
#  require graphics;
  my $delta = $stop - $start;
  
  my $html = "";

  # the left arrow
  if ($start>1) {
    my $apoly = new GD::Polygon;
    $apoly->addPt(10, $yoffset + 8);
    $apoly->addPt(20, $yoffset - 2 );
    $apoly->addPt(20, $yoffset + 4);
    $apoly->addPt(30, $yoffset + 4);
    $apoly->addPt(30, $yoffset + 13);
    $apoly->addPt(20, $yoffset + 13);
    $apoly->addPt(20, $yoffset + 18);
    $image->filledPolygon($apoly, $graphics::colours{'blue'});

    $html .= "<AREA HREF='../cbin/mutagen.pl?$link". &access::session_link();
#    $html .= "page=sequence&subpage=annotate&ssubpage=seqselect";
#    $html .= "sid=$contigsession=$session";

    if ($start - $delta <=0) {
      $html .= "&start=0";
      $html .= "&stop=$delta";
    }
    else {
      $html .= "&start=".($start-$delta);
      $html .= "&stop=".($stop-$delta);
    }
#    $html .= "&easy=".($easy);
    $html .= "&delta=".($delta);

    $html .= "' TARGET='_top' SHAPE=POLY COORDS='";

    $html .= "10,".($yoffset+8).",20,".($yoffset-2).",20,".($yoffset+4).",30,";
    $html .= ($yoffset+4).",30,". ($yoffset+13).",20,".($yoffset+13).",20,".($yoffset+18)."' >\n";

    my $pos = "";
    $pos .= "(".($start-$delta).",".($stop-$delta).")" if ($start-$delta>0);
    $pos .= "(1,".($stop-$delta).")" if ($start-$delta<=0);

    $image->string(GD::gdSmallFont, 35, $yoffset, $pos, $graphics::colours{'blue'});
  }

#  if ($stop != $$contig_ref{'length'}) {

#  print STDERR "if ($stop < $length) {\n";

  if ($stop < $length) {
    my $apoly = new GD::Polygon;
    $apoly->addPt($width - 10, $yoffset + 8);
    $apoly->addPt($width - 20, $yoffset - 2 );
    $apoly->addPt($width - 20, $yoffset + 4);
    $apoly->addPt($width - 30, $yoffset + 4);
    $apoly->addPt($width - 30, $yoffset + 13);
    $apoly->addPt($width - 20, $yoffset + 13);
    $apoly->addPt($width - 20, $yoffset + 18);
    $image->filledPolygon($apoly, $graphics::colours{'blue'});

#    $html .= "<AREA HREF='../cbin/sequence_select.pl?";
#    $html .= "sid=$contig&session=$session";
    $html .= "<AREA HREF='../cbin/mutagen.pl?$link";

    $html .= &access::session_link();
    $html .= "&start=".($stop);
    $html .= "&stop=".($stop+$delta);
    $html .= "&delta=".($delta);
#    $html .= "&easy=".($easy);
    $html .= "' TARGET='_top' SHAPE=POLY COORDS='";

    $html .= ($width-10).",".($yoffset+8).",".($width-20).",".($yoffset-2).
	",".($width-20).",".($yoffset+4).",".($width-30).",";
    $html .=  ($yoffset+4).",".($width-30).",". ($yoffset+13).",".($width-20).
	",".($yoffset+13).",".($width-20).",".($yoffset+18)."' >\n";

    my $pos .= "(".($start+$delta).",".($stop+$delta).")";
    $image->string(GD::gdSmallFont, $width - 35 - GD::gdSmallFont->width*length($pos), 
		   $yoffset, $pos, $graphics::colours{'blue'});
  }
  
  return $html;
}

1;



