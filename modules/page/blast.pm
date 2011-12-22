#!/usr/bin/perl -wT
# 
# Blast interface for the database.
# 
# 
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;

use html;
use db::sequence;
use db::organism;
use core;

package page::blast;
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

  my $html  ="";
  if (!$html::parameters{'blasting'}) {
    $html = &blast_page();
  }
  else {
    $html = &blasting();
  }
  return ($html, 1);
}

sub blast_page {
  my $html = "";

  $html .= &html::style::center(html::style::h1("Web-blast page"));
  $html .= &html::style::hr("70%");
  $html .= &html::style::break();

  $html .= html::start_form('mutagen.pl');
  
  my  @cells;

  @cells = [&html::generic_form_element({type=>'reset'}),
	    &html::generic_form_element({type=>'submit', name=>'blasting', value=>'Blast sequence'})
	    ];

  $html .= &html::table(\@cells, 0, 5,5);

  $html.= '<B>Enter sequence here: </B><BR>'. 
    &html::generic_form_element({type=>'textarea', 
				value=>'', 
				name=>'seqin', 
				cols=>'80',
				rows=>'8'});

   @cells = ["<B>Blast type: </B><BR>",
	     &html::generic_form_element({type=>'popup', 
					  name=>'blasttype',
					  values =>['blastp', 'blastn', 'blastx', 'tblastn', 'tblastx'], 
					  size=>'7'})];

  push @cells, ["<B>Use filter: </B>", 
		&html::generic_form_element({type=>'radio', name=>'filter', 
					     value=>'Yes', checked=>1})."Yes".
		&html::generic_form_element({type=>'radio', name=>'filter', 
					     value=>'No'})."No"];

  push @cells, ["<B>E-value: </B>",&html::generic_form_element({type=>'label', 
								name=>'evalue', 
								value=>'1.0', 
								size=>10})];

  $html .= &html::table(\@cells, 0, 5,5);

  my @organisms = sort sort_organisms &db::organism::all();
  
  my %organism_labels=();
  my $all_organisms;
  my @organism_list;
  my $all_plasmids;
  my @plasmid_list;
  my $all_viruses;
  my @virus_list;

  foreach my $organism (@organisms) {
    next if (&access::check_access(undef, undef, $$organism{oid}));
    
    $organism_labels{$$organism{'oid'}} = $$organism{'name'};

    if ($$organism{type} eq "organism") {
      push @organism_list, $$organism{oid};
      $all_organisms .= " $$organism{oid}";
    }
    elsif ($$organism{type} eq "plasmid") {
      push @plasmid_list, $$organism{oid}; 
      $all_plasmids .= " $$organism{oid}";
    }
    elsif ($$organism{type} eq "virus") {
      push @virus_list, $$organism{oid}; 
      $all_viruses .= " $$organism{oid}";
    }
  }

  $organism_labels{'local_organisms'} = "<b>All local organisms</b>";
  push @organism_list, 'local_organisms';

  $organism_labels{'local_plasmids'} = "<b>All local plasmids</b>";
  push @plasmid_list, 'local_plasmids';

  $organism_labels{'local_viruses'} = "<b>All local viruses</b>";
  push @virus_list, 'local_viruses';


#  &core::Dump(\@oid_list, $local_list);

  $html .= &html::style::h3("Genomes in the Database:");

  $html .= &html::checkbox_table({type=>'checkbox', 
				  name=>'localdbs',
				  values=>\@organism_list,
				  labels=>\%organism_labels},3);
  
  $html .= "<BR>";
  $html .= &html::style::h3("Viruses in the Database:");

  
  $html .= &html::checkbox_table({type=>'checkbox', 
				  name=>'localdbs',
				  values=>\@virus_list,
				  labels=>\%organism_labels},2);

  $html .= "<BR>";
  $html .= &html::style::h3("Plasmids in the database:");
  $html .= &html::checkbox_table({type=>'checkbox', 
				  name=>'localdbs',
				  values=>\@plasmid_list,
				  labels=>\%organism_labels},3);

  $html .= &html::style::h3("Genomes from the NCBI database:");

  # 
  my ($archaea, $bacteria, $labels) = build_organims_index();

  if (@$archaea > 0) {
    $html .=  "<h4>Archael genomes : </h4>\n";

#    &core::Dump($archaea);

    $html .= &html::checkbox_table({type=>'checkbox', 
				    name=>'external',
				    values=>$archaea,
				    labels=>$labels},3);
  }

  if (@$bacteria > 0) {
    $html .= "<h4>Bacterial genomes : </h4>\n";
    
    $html .= &html::checkbox_table({type=>'checkbox', 
				    name=>'external',
				    values=>$bacteria,
				    labels=>$labels},3);
  }

  my (@external, %elabel);
 

    if (-e "$conf::localdbs/nr") {
      push @external, "nr" ;
      $elabel{nr} = "NCBI NR";
    }
    
    if (-e "$conf::localdbs/sprot") {
      push @external, "sprot";
      $elabel{sprot} = "SPROT";
    }
    
    if (-e "$conf::localdbs/COG") {
      push @external, "COG";
      $elabel{COG} = "COG";
    }
   

  if (0&&@external) {
  
    $html .= &html::style::h3("Other databases:");
    $html .= &html::checkbox_table({type=>'checkbox', 
				    name=>'external',
				    values=>\@external,
				    labels=>\%elabel});
  }
  

  @cells = [&html::generic_form_element({type=>'reset'}),
	    &html::generic_form_element({type=>'submit', name=>'blasting', value=>'Blast sequence'})
	    ];

  $html .= &html::table(\@cells, 0, 5,5);

  $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"blast"});

  $html .= &access::session_form();
  $html .= &html::end_form();
  
  return $html;
}


sub build_organims_index {
  my (@archaea, @bacteria, %labels);

  my $dump = "";
  open INFILE, "$conf::localdbs/archaea.list" or goto BACTERIA;
#  open INFILE, "/tmp/archaea.list" or goto BACTERIA;
  $dump = join("", <INFILE>);
  close INFILE or die "Could not close '$conf::localdbs/archaea.list': $1";
  $dump =~ m/^\$VAR1 = (.*)$/s;
  $dump = $1;

  my $archaea = eval $dump || die "Could not eval '$dump': $! || $@";
  foreach my $key (sort keys %{$archaea}) {
    next if ($key =~ /All archaea/);
    $labels{$$archaea{$key}} = $key;
    push @archaea, "$$archaea{$key}";
  }

  $labels{$$archaea{"All archaea"}} = "<b>All archaea</b>";
  push @archaea, "$$archaea{'All archaea'}";


 BACTERIA:
  $dump = "";
  #  print STDERR "Opening $blast_dir$archea_list\n";
  open INFILE, "$conf::localdbs/bacteria.list" or goto NONE;
  $dump = join("", <INFILE>);
  close INFILE or die "Could not close '$conf::localdbs/bacteria.list': $1";
  #  print STDERR "$dump\n";
  $dump =~ m/^\$VAR1 = (.*)$/s;
  $dump = $1;

  my $bacteria = eval $dump;
  foreach my $key (sort keys %{$bacteria}) {
    next if ($key =~ /All bacteria/);

    $labels{$$bacteria{$key}} = $key;
    push @bacteria, "$$bacteria{$key}";
  }

  $labels{$$bacteria{"All bacteria"}} = "<b>All bacteria</b>";
  push @bacteria, "$$bacteria{'All bacteria'}";


#  $labels{"bacteria"} = "All bacteria";
#  push @bacteria, "bacteria";

 NONE:


  return (\@archaea, \@bacteria, \%labels);
  
  
  
}

sub sort_organisms {
  my ($A, $B) = ($a, $b);
  $$A{name} cmp $$B{name}
}

sub blasting {
  use POSIX qw( tmpnam );
  
  my $tmpin    = "..".tmpnam();
  my $tmpout   = "..".tmpnam();
  my $tmphtml  = "..".tmpnam();

  my $run = $conf::blastall;
  my ($program, $filter, $evalue, $dbs);

  $filter = "T" if ($html::parameters{'filter'} =~ /^Yes/);
  $filter = "F" if ($html::parameters{'filter'} !~ /^Yes/);

  if ($html::parameters{'evalue'} =~ /^(\d+\.\d*)$/) {
    $evalue = $1;
  }
  if ($html::parameters{'evalue'} =~ /^(\d+e-\d*)$/) {
    $evalue = $1;
  }
  else {
    $evalue = "1.0";
  }

  if ($html::parameters{'blasttype'} =~ /^(blastn|blastp|blastx|tblastn|tblastx)$/) {
    $program = $1;
  }

  my %bases = ();
  my $dbases = "";


  if (ref $html::parameters{'localdbs'} eq "ARRAY") {
    foreach my $db (@{$html::parameters{'localdbs'}}) {      
      next if ($bases{$db});
      $db =~ /(\d+)/ || $db =~ /(local_\w+)/ || die "Wrongly named database: '$db'\n";
      $dbases .=  "$conf::dbases/$1 ";
      $bases{$db} = 1;
    }
  }
  elsif ($html::parameters{'localdbs'}) {
    ($html::parameters{'localdbs'} =~ /(\d+)/ || 
     $html::parameters{'localdbs'} =~ /(local_\w+)/ || 
     die "Wrongly named database\n");
    $dbases = "$conf::dbases/$1 ";
  }

  &core::Dump($html::parameters{'external'});

  if (ref $html::parameters{'external'} eq "ARRAY") {
    foreach my $dbs (@{$html::parameters{'external'}}) {
      next if ($bases{$dbs});
      
      foreach my $db (split(" ",$dbs)) {
	($db =~ /(nr)/ || $db =~ /(sprot)/ ||
	 $db =~ /(NC_\d+)/ || $db =~ /(COG)/ || 
	 die "Wrongly named database '$db'\n");
	$dbases .=  "$conf::localdbs/$1 ";
	$bases{$db} = 1;
      }
    }
  }
  elsif ($html::parameters{'external'}) {
    ($html::parameters{'external'} =~  /(nr)/ || 
     $html::parameters{'external'} =~ /(sprot)/ || 
     $html::parameters{'external'} =~ /(NC_\d+)/ ||
     $html::parameters{'external'} =~ /(COG)/ || 
     die "Wrongly named database $html::parameters{'external'}\n");

    foreach my $db (split(" ",$html::parameters{'external'})) {
      ($db =~ /(nr)/ || $db =~ /(sprot)/ ||
       $db =~ /(NC_\d+)/ || $db =~ /(COG)/ || 
       die "Wrongly named database '$db'\n");
      $dbases .=  "$conf::localdbs/$1 ";
      $bases{$db} = 1;
    }
    $dbases .=  "$conf::localdbs/$1 ";
  }

  # Here should all the empty lines be removed.
  # An old comment that mean nothing, God I feel dumb.

  my @sequence = split("\n", $html::parameters{'seqin'});
  my @clean = ();
  for(my $i = 0;$i<@sequence;$i++) {
    push @clean, $sequence[$i] if ($sequence[$i] !~ /^\W+$/);
  }

  open INFILE, "> $tmpin" or die "Could not open '$tmpin': $!";
  print INFILE ">no-name\n" if ($clean[0] !~ /\>/);
  print INFILE join("\n", @clean);
  close INFILE or die "Could not open '$tmpin': $!";
  
  $run .= " -p $program -F $filter -e $evalue  -i $tmpin -o $tmpout.blast -d '$dbases'\n";
  print STDERR "RUN :: $run\n";
  system $run;

  return blast2html("$tmpout.blast", "$tmpout");
}


my %db = ('gi' => "http://www.ncbi.nlm.nih.gov:80/entrez/viewer.fcgi?cmd=Retrieve&dopt=Brief&db=Protein&list_uids=",
	  'gi2' => "http://www.ncbi.nlm.nih.gov/htbin-post/Entrez/query?db=n&form=6&dopt=g&uid=",
	  'embl' => "http://www.ebi.ac.uk/htbin/expasyfetch?",
	  'sprot' => "http://www.expasy.org/cgi-bin/niceprot.pl?",
	  'pir' => "http://www-nbrf.georgetown.edu/cgi-bin/nbrfget?",
	  'cog' => "http://www.ncbi.nlm.nih.gov/cgi-bin/COG/palox?",
	  'mutagen' => "../cbin/mutagen.pl?page=misc".&access::session_link()."&gidinfo="
	  );


my $report_nr = 1;
my @imagemap;


sub blast2html {
  my ($infile, $outfile) = @_;

  require parser::blast;
  my @blasthashes = parser::blast::parse($infile);

  #print STDERR Dumper(@blasthashes);
  my $html = "";
  foreach my $report (@blasthashes) {
    push @imagemap, drawimage("$outfile$report_nr.png", $report, $report_nr);
    $report_nr++;
  }
  
  return $html . markup_report($infile, "$outfile");
}

sub markup_report {
  #created by Kimbrugger Tue Feb 11, 2003 
  my ($blastfile,   # Name of the file we are going to markup
#      $mapinfo,     # the map information we have to enter for the picture
      $picturename, # Name of the picture to include.
      ) = @_;

  my $html;

  $html = "<div id='overDiv' style='position:absolute; visibility:hidden;'></div>\n";
  $html .= "<script langauge='JavaScript' src='../overlib.js'></script>";
  
  $html .= "<PRE>\n";
  open (INFILE, $blastfile) or die "Could not open $blastfile:$!";

  $report_nr = 0;
  while (<INFILE>) {
    if (/^(Query= )gid:(\d+)(.*)$/) {
      $report_nr++;
      my $href = "../cbin/ORFinfo.pl?gid=$2";
      $href .= &access::session_link();

      $html .= "$1<A HREF='$href'>gid:$2</A>$3\n";
      $html .= "<A NAME='A_TOP_$report_nr'>\n";
    }
    elsif(/^(Query= .*$)/) {
      $report_nr++;
      $html .= "$1<A NAME='A_TOP_$report_nr'>\n";
    }
    elsif (/^Sequences producing/) {
      $html .= $_;
      $html .= <INFILE>;
      while (<INFILE>) {
	# If this was the last hit, insert the picture and all the HTML mapping so we can see what is there.
	if (/^$/) {
	  $html .=  "\n</PRE>";
	  $html .= "<FORM NAME='BLASTFORM'>\n";
	  $html .= "<CENTER>\n";
	  $html .= "<H3>Distribution of the Blast Hits on the Query Sequence</a> </H3>\n";
	  $html .= "</CENTER>\n";
	  $html .= "<CENTER>\n";
	  $html .= "<IMG BORDER=0 USEMAP=#HITMAP_$report_nr SRC=$picturename$report_nr.png ISMAP>\n";

	  $html .= $imagemap[$report_nr-1];
	  $html .= "</CENTER>\n";
	  $html .= "</FORM><PRE>\n";
	  last;
	}

	# Add a link to later part in the report
	if (/^(.*)( |\|).*?(\d+) +(\S+\d+)/) {
#	  print STDERR "----||||$1|||$2|||$3|||$4|||\n";
	  my ($id,$evalue) = ($1,$4);
	  $id =~ s/:/_/;
	  $id =~ s/\|/_/g;
	  $id =~ s/\ .*$//;
	  s/ $evalue/\<A HREF='#A_$id\_$report_nr'\>$evalue\<\/A\>/;
	}
	
	#Add a link to external/internal databases
	$html .= add_db_link($_);
      }
    }
    elsif (/^(\>)(.*)( |\||$)/) {
      my ($id) = ($2);
      $id =~ s/:/_/;
      $id =~ s/\|/_/g;
      $id =~ s/\ .*$//;
      s/^\>//;
      $_ = add_db_link($_);
      chomp;
#      s/^\>/\<A HREF='#A_$id'\>\>\<\/A\>/;
      $html .= substr("<A NAME='A_$id\_$report_nr'>>".$_ ."                                          ", 0 , 300) . 
	  "<A HREF='#A_TOP_$report_nr'> Back to the top</A>\n";
    }
    else {
      $html .= $_;
    }
	   
  }
  return $html . "</pre>";
}


sub add_db_link {
  my ($link) = (@_);

  my $return = "";

#  print STDERR "LINK ::: $link\n";

  # Add links to external databases.
  if ($link =~ /^gid:(\d+)(.*)$/) {
    $return = "<A HREF='$db{'mutagen'}$1'>gid:$1</A>$2\n";
  }
  elsif ($link =~ /^gid|gid(\d+)(.*)$/) {
    $return = "<A HREF='$db{'mutagen'}$1'>gid:$1</A>$2\n";
  }
  elsif ($link =~/^sp:(.*?)($| .*$)/) {
    $return = "<A HREF='$db{'sprot'}$1'>sp:$1</A>$2\n";
  }
  elsif ($link =~/^sp\|(.*?)\|($|.*$)/) {
    $return = "<A HREF='$db{'sprot'}$1'>sp:$1</A> $2\n";
  }
  elsif ($link =~/^COG:(.*?)($| .*$)/) {
    $return = "<A HREF='$db{'cog'}$1'>COG:$1</A>$2\n";
  }
  elsif ($link =~/^ref\|(.*?)\|($|.*$)/) {
    $return = "<A HREF='$db{'gi'}$1'>ref:$1</A>$2\n";
  }
  elsif ($link =~/^gb\|(.*?)\|($|.*$)/) {
    $return = "<A HREF='$db{'gi'}$1'>gi:$1</A> $2\n";
  }
  elsif ($link =~ /^gi\|(\d+)(.*)$/) {
    if($link =~ /assembly:\ +\d+/)  {
      $link =~ /^gi\|(\d+)(.*)$/;
      $return = "sid:$1$2\n";
    }
    elsif ($1< 10000000) {
      $return = "<A HREF='$db{'mutagen'}$1'>gid:$1</A>$2\n";
    }
    else {
      $return = "<A HREF='$db{'gi'}$1'>gi:$1</A>$2\n";
    }
  }
  elsif ($link =~/^emb\|(.*?)\|($|.*$)/) {
    $return = "<A HREF='$db{'embl'}$1'>emb:$1</A> $2\n";
  }
  else {
    $return = $link;
  }

  return $return;	 
}

sub drawimage {
  use GD;

  # Created by Kim Brugger Fri Feb  7, 2003 
  my ($imagename,   # the name of the image where we will save the results.
      $blastinfo, # hash containing the information needed for creating the picture.
      $report_id, # the report number for multiple reports in one search
      ) = @_;

#  print STDERR Dumper($blastinfo);

  # Number of hits is needed for calculating the height of the picture we are going to make
  return undef  if (! $blastinfo);
  my $numberofhits = @{$$blastinfo{hits}};

  ## Inits and calculation of image size
  my $font = gdMediumBoldFont;
  my $fontheight = $font->height;
  my $imagewidth = 650;
  my $imageheight = (4 + $numberofhits + 4) * $fontheight;
  my $hitmap = "<MAP NAME='HITMAP_$report_id'>\n";
  my $image = new GD::Image($imagewidth,$imageheight);
  $image->interlaced('true'); 

  ## Allocate the colors we use
  my $white = $image->colorAllocate(255,255,255);
  my $black = $image->colorAllocate(0,0,0);
  my $red = $image->colorAllocate(255,0,0);
  my $green = $image->colorAllocate(0,205,0);
  my $yellow = $image->colorAllocate(247,174,10);
  my $grey = $image->colorAllocate(130,130,130);
  my $blue = $image->colorAllocate(25,25,205);

  my %colors = ( 0 => $grey, 100 => $green, 150 => $yellow,
                 200 => $red );

  ## Paint a black frame around the image to make it look nice on a white background
  $image->rectangle(0,0,$imagewidth-1,$imageheight-1,$black);

  ## Draw querysequence a ruler so we can navigate easier
  my $spos = $font->width;
  my $line = $fontheight;
  my $start = $spos; 
  my $stop = $imagewidth - $fontheight;
  $image->filledRectangle($start,$line,$stop,$line+$fontheight/2-1,$blue);
  $line += $fontheight / 2;
  my $unit = ($stop - $start) / $$blastinfo{'qlength'}; 
  my $delta = 1;
  for (my $i=1; 1; $i*=10) {
    my $tmp = $$blastinfo{'qlength'}/$i;
    if (($tmp/5) > 10) {
      $delta = $i * 5; 
      next; 
    }
    elsif ($tmp > 10) {
      $delta = $i; 
      next; 
    }
    last; 
  }

  for (my $i=0; $i<=$$blastinfo{'qlength'}/$delta; $i++) {
    my $pos = $i*$delta*$unit;
    $image->line($spos+$pos,$line,$spos+$pos,$line+$fontheight/2-1,$blue);
    next if ($i%5 != 0);
    $image->string($font,$spos+$pos,$line+$fontheight/2,$i*$delta,$black); 
  }

  $line += $fontheight * 2.5;

  ## Draw sequences
  foreach my $hit (@{$$blastinfo{hits}}) {

    ## Proceed sequence name
    my $id = sequence_id($$hit{'sname'});
    $id =~ s/:/_/;
    $id =~ s/\|/_/g;
    $id =~ s/\ .*$//;

    my $desc = "$$hit{'sname'}" || $id;

    ## Proceed HSP
    foreach my $hsp (@{$$hit{'facts'}}) {
      
      my $score = $$hsp{'Score'} || 1;
      my $begin =  $$hsp{'qstart'};
      my $end =  $$hsp{'qstop'};
      
      ($begin, $end) = ($end, $begin) if ($begin >= $end);
#      print STDERR "blast2html::$begin -> $end ($desc)\n";

      
      $begin = $begin * $unit + $start;
      
      $end = $end * $unit + $start;
      my $color = 0;

      foreach (sort bynumber keys %colors) {
	if ($score > $_) {
	  $color = $colors{$_}; 
	  next; 
	}
	last; 
      }
      $image->filledRectangle($begin, $line + $fontheight / 4,
			      $end, $line + $fontheight * 3/4, $color);
      
      
      my $coord = "'$begin,".($line + $fontheight / 4).",$end,".($line + $fontheight * 3/4) . "'";

      $hitmap .= "<AREA SHAPE=RECT COORDS=$coord HREF=#A_$id\_$report_id alt='$desc'";
      $hitmap .=  "onmouseover=\"return overlib('$desc');\" onmouseout=\"return nd();\">\n";
    }
    
    ## Handle the next sequence on the next line.
    $line += $fontheight; 
  }
  
  
  ## Draw a coluor legend so the user can se what the colours mean
  $line += $fontheight;
  my $nbcol = scalar keys %colors;
  my $lencol = ($stop - $start) / $nbcol;
  my $pos = $start; my $prec = 0;
  foreach (sort bynumber keys %colors) {
    my $color = $colors{$_};
    $image->filledRectangle($pos,$line,$pos+$lencol-10,$line+$fontheight,$color);
    $image->string($font,$pos,$line+$fontheight,"Score > $_",$black);
    $pos += $lencol; 
  }

  ## Convert image to png and save it
  open(IMAGE,"> $imagename") or die "Could not open $imagename: $!";
  print IMAGE $image->png;
  close(IMAGE);

  $hitmap .= "</MAP>";

  return $hitmap; 
}


sub sequence_id {
  my ($name) = @_;

  $name =~ s/\ .*$//;
  
  return $name;
}

## Sort functions
sub bynumber { $a <=> $b }


BEGIN {

}

END {

}

1;
