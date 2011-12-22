#!/usr/bin/perl -wT
# 
# 
# 
# 
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;

package page::sequence::browse;
require Exporter;
require AutoLoader;

# set the version for version checking
my $VERSION     = "0.01";

my @ISA = qw(VERSION Exporter AutoLoader);

our @EXPORT = qw();
@ISA = qw(Exporter AutoLoader);
@EXPORT = qw();

#exported variables, this will be sweet.
use vars qw ();

# 
# Select what sequence and what area if the selected sequence that should be displayed.
# 
# Kim Brugger (03 Dec 2003)
sub sequence_select {
  require db::sequence;

  return &access::no_access if (&access::check_access(undef, undef, $html::parameters{oid}));
  my $html = "";#&html::style::h3("Select sequence");
  $html .= &mutagen_html::headline("Sequence browser");
  

  my @sequence = db::sequence::fetch_organism($html::parameters{'oid'});

#  use Data::Dumper;
#  print STDERR Dumper(\@sequence);

  my %labels;
  for (my $i = 0;$i<@sequence;$i++) {
    $labels{$sequence[$i]{'sid'}} = "$sequence[$i]{'name'} &nbsp (length $sequence[$i]{'length'})";#$sequence[$i]{'name'};
    $sequence[$i] = $sequence[$i]{'sid'};#"$sequence[$i]{'name'} &nbsp (length $sequence[$i]{'length'})";
  }
  
  my @cells = [{value=>&html::generic_form_element({type=>"menu", 
						    name=>"sid", 
						    values=>\@sequence, 
						    labels=>\%labels,
						    size=>"7",
						    defaults=>[$sequence[0]]}), rowspan=>8}];
  
  #
  # Some of these choices will be removed later when the user profile works.
  #
  if (!$conf::html_level & $conf::html_light) {
    push @cells, [{value=>"Maximum gene score"}, 
		  {value=>&html::generic_form_element({type=>"text", 
						       name=>"score", 
						       value=>"5"}).
							   "Use filter".
                   &html::generic_form_element({type=>"checkbox",
						name=>"filter_score",
						checked=>"1"})}];
  }
  push @cells, [{value=>"Minimum gene length (AA)"}, 
		{value=>&html::generic_form_element({type=>"text", 
						     name=>"length", 
						     value=>"100"}).
						     "Use filter".
						     &html::generic_form_element({type=>"checkbox",
										  name=>"filter_length",
										  checked=>"0"})}];

  push @cells,  [{value=>"Start position"}, 
		 {value=>&html::generic_form_element({type=>"text", 
						      name=>"start", 
						      value=>"1"})}];
  push @cells,  [{value=>"Stop position"}, 
		 {value=>&html::generic_form_element({type=>"text", 
						      name=>"stop", 
						      value=>"-1"})." (-1 equals then end of the sequence)"}];
  push @cells,  [{value=>"Show hidden genes"}, 
				   {value=>&html::generic_form_element({type=>"radio", 
									name=>"hidden", 
									value=>"Yes"})."Yes".
				   &html::generic_form_element({type=>"radio", 
								name=>"hidden", 
								value=>"No", 
								checked=>1}). "No"}];

  push @cells, [{value=>&html::generic_form_element({type=>"submit", 
						     name=>"ORFmap", 
						     value=>"Submit"})}];
  
  $html .= &html::start_form();
  $html .= &html::advanced_table(\@cells, 1, 3, 3, undef, 1);

  $html .= &html::generic_form_element({type=>"hidden", name=>"page",    value=>"sequence"});
  $html .= &html::generic_form_element({type=>"hidden", name=>"subpage", value=>"browse"});
  $html .= &access::session_form();
  $html .= &html::end_form();
  
  return $html;
  
}

sub make_ORF_map {
  require graphics;
  require db::sequence;
  require db::gene;


  # if the function is called with a gid, this means that the browser
  # should happend around this gene.  so the start and stop position
  # is calculated from this gene, and also the gene is coloured
  # differently, just to show that we can also make things a bit nice
  # once in a while.

  my $outfile = &kernel::tmpname() . ".png";

  my ($gid) = $html::parameters{'gid'};
  
  my $border = 10000;

  if ($gid) {
    my $gene = &db::gene::fetch($gid);
    $html::parameters{'start'} = $$gene{'start'} - 10000;
    $html::parameters{'stop'} = $$gene{'stop'} + 10000;
    $html::parameters{'sid'} = $$gene{'sid'};
  }

  return &access::no_access 
      if (&access::check_access(undef, $html::parameters{'sid'}, undef));


  my ($width, $height) = (1000, 190);

  my $image = new GD::Image($width, $height);
  $image->interlaced(1); 

  &graphics::make_palette($image);

#  &graphics::BOX($image, $width, $height-50, $blue, 0, 50);
#  &graphics::BOX($image, $width, 50, $blue, 0, 0);

#  &graphics::BOX($image, $width, $height, $graphics::colours{'red'}, 0, 0);
#  &graphics::BOX($image, $width, $height-150, $graphics::colours{'red'}, 0,150);

  my $sequence = &db::sequence::fetch($html::parameters{'sid'});

  my ($start, $stop) = (1,$$sequence{'length'});
  $start = $html::parameters{'start'} if ($html::parameters{'start'} && $html::parameters{'start'} >= 0);
  $stop = $html::parameters{'stop'} if ($html::parameters{'stop'} && 
					$html::parameters{'stop'} != -1
					&& $html::parameters{'stop'} < $stop);
  ($start, $stop) = ($stop, $start) if ($start > $stop);

#  print STDERR "START == $start STOP == $stop\n";

  my @genes = &db::gene::fetch_organism(undef, undef, $html::parameters{'sid'}, $start, $stop);

  my $html = "<CENTER>";
  $html .= "<div id='overDiv' style='position:absolute; visibility:hidden;'></div>\n";
  $html .= "<script langauge='JavaScript' src='../overlib.js'></script>\n";

  $html .="<IMG src='$outfile' USEMAP=#map1  border='none' ISMAP>\n";
  $html.= "<MAP NAME=map1>\n";

  # alter the gene colours according to highlighting, annotated, tagged e&.
  use db::annotation;
  

  foreach my $gene (@genes) {

    $gene = undef  if ($$gene{'show_gene'} eq "deleted");
#    next  if ($$gene{'show_gene'} eq "deleted");

    my @annotations = &db::annotation::all($$gene{'gid'});

    # Check if we should filter on the gene-length.
    if ($html::parameters{'filter_length'} && 
	$html::parameters{'length'} > ($$gene{'stop'} - $$gene{'start'}+1)/3) {

      $gene = undef;
      next;
    }

    $$gene{'colour'} = 0 if (!$$gene{'colour'});

    # Check if we should filter on the gene-score and only if the gene has a score can we do this.
    if ($html::parameters{'filter_score'} && $$gene{'score'} && 
	$html::parameters{'score'} > $$gene{'score'}) {
      
      $gene = undef;
      next;
    }

    # if this is the highlighted gene
    $$gene{'colour'} = 29  if ($gid && $$gene{'gid'} eq $gid);

    foreach my $annotation ( @annotations) {
      next if ($$annotation{'state'} eq "deleted");
#      $annotation = undef  if ($$annotation{'show_gene'} eq "deleted");
      

      # If the gene is not assigned any default colour we assign one 
      # based on the gene type.
      $$gene{colour} = $global::gene_types{$$gene{type}}{colour} 
	  if (!$$gene{colour});

      $$gene{'colour'} = 19 if ($$annotation{'final'} && $$gene{'colour'}<19);
      
      # pure bit-logic will show the path to highlighting the genes ...
      # I will not explain it, just trust me: it works.
      $$gene{'colour'} += 100 if ($annotation);
      $$gene{'colour'} += 200 if ($$annotation{'TAG'} == 0);
      last;
    }

  }

  

#  &core::Dump(\@genes);

  $html .= &graphics::make_3frame_genes($image, \@genes, $height-60, $width, $start, $stop, 50, 10);

  &graphics::make_title($image, $$sequence{name}, $width, 0, 10);
  
  my $link = "page=sequence&subpage=browse&sid=$html::parameters{'sid'}&ORFmap=1";


  $html .= &graphics::make_arrows($image, $start, $stop, $width, 0, $height-27, $link, $$sequence{'length'});

  # setup the basis link to these links ...
#  my $base_link = "page=sequence&subpage=browse&sid=$html::parameters{'sid'}&sequence_select=1";
  my $base_link = "page=sequence&subpage=browse&sid=$html::parameters{'sid'}&";
  $link .= &access::session_link();

  my @links;# = ({text=>"Colour code", link=>"$base_link&menu=ccodes"});

  $link = "$base_link&menu=zoom";
  $link .= "&start=$start"                  if ($start);
  $link .= "&stop=$stop"                    if ($stop);
  $link .= "&length=$html::parameters{'length'}"                if ($html::parameters{'length'});
  $link .= "&filter_length=$html::parameters{'filter_length'}"  if ($html::parameters{'filter_length'});
  $link .= "&score=$html::parameters{'score'}"                  if ($html::parameters{'score'});
  $link .= "&filter_score=$html::parameters{'filter_score'}"    if ($html::parameters{'filter_score'});


  push @links, {text=>"Zoom", link =>"$link"};

#  push @links, {text=>"Add gene/feature", link=>"$base_link&menu=new_gene"};


  $html .= &graphics::make_menu ($image, \@links, $width, 51, 0, $height-20);

  $html.= "</MAP>\n";

  # print the picture.
  open (FIL, "> $outfile") or die "Could not open '$outfile': $!) : $!";
  binmode FIL;
  print FIL $image->png;
  close (FIL);

  return $html;
}

sub make_RAW_map {
  require graphics;
  require db::sequence;
  require db::gene;

  use GD;
  my $outfile = &kernel::tmpname() . ".png";

  # if the function is called with a gid, this means that the browser
  # should happend around this gene.  so the start and stop position
  # is calculated from this gene, and also the gene is coloured
  # differently, just to show that we can also make things a bit nice
  # once in a while.

  my ($gid) = $html::parameters{'gid'};
  
  my $border = 100;

  if ($gid) {
    my $gene = &db::gene::fetch($gid);
    if ($$gene{strand} == 0) {
      $html::parameters{'start'} = $$gene{'start'} - $border;
      $html::parameters{'stop'} = $$gene{'start'} + $border*2;
    }
    else {
      $html::parameters{'start'} = $$gene{'stop'} - $border;
      $html::parameters{'stop'} = $$gene{'stop'} + $border*2;
    }
      $html::parameters{'sid'} = $$gene{'sid'};
  }

  return &core::no_access if (&access::check_access(undef, $html::parameters{'sid'}, undef));

  my $sequence = &db::sequence::fetch($html::parameters{'sid'});
  my ($start, $stop) = (1,$$sequence{'length'});
  $start = $html::parameters{'start'} if ($html::parameters{'start'} && $html::parameters{'start'} >= 0);
  $stop = $html::parameters{'stop'} if ($html::parameters{'stop'} && 
					$html::parameters{'stop'} != -1
					&& $html::parameters{'stop'} < $stop);

  ($start, $stop) = ($stop, $start) if ($start > $stop);


#  print STDERR "START == $start STOP == $stop\n";

  my ($width, $height) = (100, 220);
  $width = gdLargeFont->width * ($stop - $start +1) + 40;

#  print STDERR "WIDTH $width , HEIGHT $height\n";

  my $image = new GD::Image($width, $height);
  $image->interlaced(1); 

  &graphics::make_palette($image);

#  &graphics::BOX($image, $width, $height-50, $blue, 0, 50);
#  &graphics::BOX($image, $width, 50, $blue, 0, 0);

#  &graphics::BOX($image, $width, $height, $graphics::colours{'red'}, 0, 0);
#  &graphics::BOX($image, $width, $height-150, $graphics::colours{'red'}, 0,150);


  my @genes = &db::gene::fetch_organism(undef, undef, $html::parameters{'sid'}, $start, $stop);

  my $html = "<CENTER>";
  $html .= "<div id='overDiv' style='position:absolute; visibility:hidden;'></div>\n";
  $html .= "<script langauge='JavaScript' src='../overlib.js'></script>\n";

  $html .="<IMG src='$outfile' USEMAP=#map1 ISMAP>\n";
  $html.= "<MAP NAME=map1>\n";

  # alter the gene colours according to highlighting, annotated, tagged e&.
  use db::annotation;
  foreach my $gene (@genes) {

     $gene = undef if ($$gene{'show_gene'} eq "deleted");


    my @annotations = &db::annotation::all($$gene{'gid'});

    # Check if we should filter on the gene-length.
    if ($html::parameters{'filter_length'} && 
	$html::parameters{'length'} > ($$gene{'stop'} - $$gene{'start'}+1)/3) {

      $gene = undef;
      next;
    }

    # Check if we should filter on the gene-score and only if the gene has a score can we do this.
    if ($html::parameters{'filter_score'} && $$gene{'score'} && 
	$html::parameters{'score'} > $$gene{'score'}) {

      $gene = undef;
      next;
    }

    # if this is the highlighted gene
    $$gene{'colour'} = 20  if ($gid && $$gene{'gid'} eq $gid);

    foreach my $annotation ( @annotations) {
      next if ($$annotation{'state'} eq "deleted");
      $$gene{'colour'} = 19 if ($$annotation{'final'} && $$gene{'colour'}<19);
      
      # pure bit-logic will show the path to highlighting the genes ...
      # I will not explain it, just trust me: it works.
      $$gene{'colour'} += 100 if ($annotation);
      $$gene{'colour'} += 200 if ($$annotation{'TAG'});
      last;
    }

  }

  $html .= &graphics::make_3frame_raw($image, \@genes, $$sequence{'sequence'}, 
				      $height-60, $width, $start, $stop, 50, 1);

  &graphics::make_title($image, $$sequence{name}, $width, 0, 10);

  my $link = "page=sequence&subpage=browse&sid=$html::parameters{'sid'}&RAWmap=1";
  $html .= &graphics::make_arrows($image, $start, $stop, $width, 0, 193, $link, $$sequence{'length'});

  # setup the basis link to these links ...
#  my $base_link = "page=sequence&subpage=browse&sid=$html::parameters{'sid'}&sequence_select=1";
  my $base_link = "page=sequence&subpage=browse&sid=$html::parameters{'sid'}&";

  my @links = ({text=>"Colour code", link=>"$base_link&menu=ccodes"});

  $link = "$base_link&menu=zoom";
  $link .= "&start=$start"                  if ($start);
  $link .= "&stop=$stop"                    if ($stop);
  $link .= "&length=$html::parameters{'length'}"                if ($html::parameters{'length'});
  $link .= "&filter_length=$html::parameters{'filter_length'}"  if ($html::parameters{'filter_length'});
  $link .= "&score=$html::parameters{'score'}"                  if ($html::parameters{'score'});
  $link .= "&filter_score=$html::parameters{'filter_score'}"    if ($html::parameters{'filter_score'});
  push @links, {text=>"Zoom", link =>"$link"};

  push @links, {text=>"Add gene/feature", link=>"$base_link&menu=new_gene"};

  $html .= &graphics::make_menu ($image, \@links, $width, 51, 0, 200);

  $html.= "</MAP>\n";

#  $image = AddSequence($image, , $start, $stop, 60, 2);

  # print the picture.
  open (FIL, "> $outfile") or die "Could not open '$outfile': $!) : $!";
  binmode FIL;
  print FIL $image->png;
  close (FIL);

  return $html;
}


# 
# Show all the alternative start codons etc ... (admin code)
# 
# Kim Brugger (25 Feb 2004)
sub gfinders  {
  my ($gid) = @_;

  require graphics;
  require db::sequence;
  require db::genefinder;
  require db::gene;


  return &access::no_access if (&access::check_access($gid, undef, undef));


  use GD;

  my $outfile = &kernel::tmpname() . ".png";
  
  my $gene = &db::gene::fetch($gid);

  my $genefinders = &db::genefinder::fetch_by_gid($gid);

  my ($start, $stop) = (undef,undef);
  foreach my $genefinder (@$genefinders) {
    $start = $$genefinder{'start'} if (!$start || $start > $$genefinder{'start'});
    $stop  = $$genefinder{'stop'}  if (!$stop  || $stop  < $$genefinder{'stop'});
  }

  my $space = 30;
  my $offset = 80;
  print STDERR "GFINDERS:::::SS::::: $start -> $stop\n";

  my ($width, $height) = (1000, $offset + (@$genefinders+1)*$space);
  $width = gdLargeFont->width * ($stop - $start +101) + $space;
  my $image = new GD::Image($width, $height);
  $image->interlaced(1); 

  &graphics::make_palette($image);
  
  my $html = "<CENTER>";
  $html .= "<div id='overDiv' style='position:absolute; visibility:hidden;'></div>\n";
  $html .= "<script langauge='JavaScript' src='../overlib.js'></script>\n";

  $html .="<IMG src='$outfile' USEMAP=#map1 ISMAP>\n";
  $html.= "<MAP NAME=map1>\n";

  my $sequence = undef;

  if ($$gene{strand}) {
    (undef, $sequence) = &core::extract_sequence($$gene{'sid'}, "gfinder", $stop + 100, $start);
    &graphics::indexline($image, (@$genefinders+1)*$space + $offset-40, $width, 
			 $stop, $start, $graphics::colours{'black'}, 10, -50);
  }
  else {
    (undef, $sequence) = &core::extract_sequence($$gene{'sid'}, "gfinder", $start - 100, $stop);
    &graphics::indexline($image, (@$genefinders+1)*$space + $offset-40, $width, 
			 $start, $stop, $graphics::colours{'black'}, 10, 50);
  }

  &graphics::DNA_sequence($image, 20, (@$genefinders+1)*$space + $offset-40, $sequence);

  # Draw each gene into the genemap
  my ($x1, $y1, $x2, $y2);
  my $i = 1;
  foreach my $genefinder (@$genefinders) {

    if ($$genefinder{strand}) {
      (undef, $sequence) = &core::extract_sequence($$gene{'sid'}, "gfinder", 
						   $$genefinder{stop}, $$genefinder{start});

      ($x1, $y1, $x2, $y2) = 	
	  (20 + gdLargeFont->width *abs($stop+100 - $$genefinder{stop}),
	   $i*$space,
	   20 + gdLargeFont->width *abs($width - 20),
	   $i*$space + gdLargeFont->height);


    }
    else {
      (undef, $sequence) = &core::extract_sequence($$gene{'sid'}, "gfinder", 
						   $$genefinder{start}, $$genefinder{stop});

      ($x1, $y1, $x2, $y2) = 	
	  (20 + gdLargeFont->width *abs($start-100 - $$genefinder{start}),
	   $i*$space,
	   20 + gdLargeFont->width *abs($width - 20),
	   $i*$space + gdLargeFont->height);

    }
    
    $sequence = &kernel::translate($sequence, 1);
    $sequence = join ("--", split //, $sequence)."--";
#    $sequence .= "--"x($stop-$start+1-length($sub_seq));

    &graphics::sequence($image, $x1,$y1, $sequence);
    my $href = "../cbin/mutagen.pl?page=misc&fidinfo=$$genefinder{'fid'}";
    $href .= &access::session_link();
    
    $html .= "<AREA HREF='$href'".
	" TARGET='bottom' SHAPE=RECT COORDS='$x1,$y1,$x2,$y2' onmouseover=\"return overlib('fid:$$genefinder{'fid'} $$genefinder{'name'}');\" onmouseout=\"return nd();\">\n";

    $i++;
  }

  $$gene{sequence} = &kernel::translate($$gene{sequence}, 1);
  $$gene{sequence} = join ("--", split //, $$gene{sequence})."--";

  ($x1, $y1, $x2, $y2) =
      (20 + gdLargeFont->width *abs($start-100 - $$gene{start}),
       $i*$space,
       20 + gdLargeFont->width *abs($width - 20),
       $i*$space + gdLargeFont->height);

  &graphics::sequence($image, $x1,$y1, $$gene{sequence});
  my $href = "../cbin/mutagen.pl?page=misc&gidinfo=$$gene{'gid'}";
  $href .= &access::session_link();

  $html .= "<AREA HREF='$href'".
      " TARGET='bottom' SHAPE=RECT COORDS='$x1,$y1,$x2,$y2' onmouseover=\"return overlib('gid:$$gene{'gid'} $$gene{'name'}');\" onmouseout=\"return nd();\">\n";
  
  $html.= "</MAP>\n";

  open (FIL, "> $outfile") or die "Could not open '$outfile': $!) : $!";
  binmode FIL;
  print FIL $image->png;
  close (FIL);

  return $html;
}


sub zoom {
  my $html = "";

  return &access::no_access if (&access::check_access(undef, $html::parameters{'sid'}, undef));
  
  my @cells;

  my $def = 5;
  $def = $html::parameters{'score'}  if ($html::parameters{'score'});

  my $def2 = 1;
  $def2 = 0 if (defined $html::parameters{'filter_score'} && 
		($html::parameters{'filter_score'} eq "off" || 
		 $html::parameters{'filter_score'} eq 0));
  

  if (!$conf::html_level & $conf::html_simple) {
    push @cells, ["Maximum gene score", 
		  &html::generic_form_element({type=>"text",
					       name=>"score",
					       value=>$def}).
		  "Use filter".
		  &html::generic_form_element({type=>"checkbox",
					       name=>"filter_score",
					       checked=>$def2})];
  }

  $def = 100;
  $def = $html::parameters{'length'}  if ($html::parameters{'length'});
  $def2 = 0;
  $def2 = 1 if ($html::parameters{'filter_length'});

  push @cells, ["Minimum gene length (AA)", 
		&html::generic_form_element({type=>"text",
					     name=>"length",
					     value=>$def}).
		"Use filter".
		&html::generic_form_element({type=>"checkbox",
					     name=>"filter_length",
					     checked=>$def2})];
  $def = "1";
  $def = $html::parameters{'start'} if ($html::parameters{'start'} && $html::parameters{'start'} >=1);
  push @cells,  ["Start position", 
		 &html::generic_form_element({type=>"text",
					      name=>"start",
					      value=>$def})];
  $def = "-1";
  $def = $html::parameters{'stop'} if ($html::parameters{'stop'} && $html::parameters{'start'} >=1);
  push @cells,  ["Stop position", 
		 &html::generic_form_element({type=>"text",
					      name=>"stop",
					      value=>$def})
		 ." (-1 equals then end of the sequence)"];
  $def = 0;
  $def = $html::parameters{'Yes'} if ($html::parameters{'Yes'});
  $def2 = 1;
  $def2 = $html::parameters{'No'} if ($html::parameters{'No'});
  
  push @cells,  ["Show hidden genes", 
		 &html::generic_form_element({type=>"radio",
					      name=>"hidden",
					      value=>"Yes",
					      checked=>$def})."Yes".
		 &html::generic_form_element({type=>"radio",
					      name=>"hidden",
					      value=>"No",
					      checked=>$def2}). "No"];

  push @cells, ["", &html::generic_form_element({type=>"submit", 
						    name=>"ORFmap", 
						    value=>"Submit"})];
  
  $html .= &html::start_form("../cbin/mutagen.pl", undef,"_top");
  $html .= &html::table(\@cells, 1, 3, 3, undef);

  $html .= &html::generic_form_element({type=>"hidden", name=>"page",    value=>"sequence"});
  $html .= &html::generic_form_element({type=>"hidden", name=>"subpage", value=>"browse"});
  $html .= &html::generic_form_element({type=>"hidden", name=>"sid", value=>"$html::parameters{'sid'}"});
  $html .= &access::session_form();
  $html .= &html::end_form();
  
  return $html;
  
}

#
# The add a new gene page
# 
sub new_gene {

  return &access::no_access if (&access::check_access(undef, $html::parameters{'sid'}, undef));

  my $html = "";
  
  my @cells;

  push @cells,  ["Start position", 
		 &html::generic_form_element({type=>"text", 
					      name=>"start", 
					      value=>""})];
  push @cells,  ["Stop position", 
		 &html::generic_form_element({type=>"text", 
					      name=>"stop", 
					      value=>""})];

  push @cells,  ["Gene type", &mutagen_html::forms::genetypes_popup()];

  push @cells,  ["Strand", 
		 &html::generic_form_element({type=>"radio", 
					      name=>"strand", 
					      value=>"plus", 
					      checked=>1})."Plus".
		 &html::generic_form_element({type=>"radio", 
					      name=>"strand", 
					      value=>"minus"})."Minus"];

  push @cells, ["&nbsp;", &html::generic_form_element({type=>"submit", 
						    name=>"add_gene", 
						    value=>"Submit"})];
  
  $html .= &html::start_form();
  $html .= &html::table(\@cells, 1, 3, 3, undef);

  $html .= &html::generic_form_element({type=>"hidden", name=>"page",    value=>"misc"});
  $html .= &html::generic_form_element({type=>"hidden", name=>"new_gene",value=>"1"});
  $html .= &html::generic_form_element({type=>"hidden", name=>"sid", value=>"$html::parameters{'sid'}"});
  $html .= &access::session_form();
  $html .= &html::end_form();
  
  return ($html);
}


BEGIN {

}

END {

}

1;


