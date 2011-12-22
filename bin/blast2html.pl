#!/usr/bin/perl -wT
# 
# HTML tagge a blast report, and even creats a nice graphical picture to go with it.
# 
# 
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;
use Getopt::Std;

use GD;
use Data::Dumper;

use lib '/data/www/sulfolobus.org/modules/';
require blast;

# The system can use overlib to show information on the maps or just rely on the NCBI like look.

my %opts = ();
getopts("i:u:o:", \%opts);


## Misc inits
my %dbs = (); # Hash containing links to all sequence databases.
my ($blastfile, $outfile, $session);

$blastfile = $opts{i};

$opts{o} =~ /(\S+)/;
$outfile = $1;


#print STDERR "$0: ($blastfile, $outfile, $session)\n";
my %db = ('gi' => "http://www.ncbi.nlm.nih.gov:80/entrez/viewer.fcgi?cmd=Retrieve&dopt=Brief&db=Protein&list_uids=",
	  'gi2' => "http://www.ncbi.nlm.nih.gov/htbin-post/Entrez/query?db=n&form=6&dopt=g&uid=",
	  'embl' => "http://www.ebi.ac.uk/htbin/expasyfetch?",
	  'sprot' => "http://www.expasy.org/cgi-bin/niceprot.pl?",
	  'pir' => "http://www-nbrf.georgetown.edu/cgi-bin/nbrfget?",
	  'cog' => "http://www.ncbi.nlm.nih.gov/cgi-bin/COG/palox?",
	  'mutagen' => "../cbin/ORFinfo.pl?gid="
	  );


my $report_nr = 1;
my @imagemap;
run();

sub run {
  my @blasthashes = parse_blast($blastfile);

  #print STDERR Dumper(@blasthashes);
  my $html = "";
  foreach my $report (@blasthashes) {
    
    push @imagemap, drawimage("$outfile$report_nr.png", $report, $report_nr);
    $report_nr++;
  }
  
  $html .= markup_report($blastfile, "$outfile");
  
  open (OUTFILE,"> $outfile.html") or die "Could not open $outfile.html: $!";
  print OUTFILE $html;
  close (OUTFILE);
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
      $html .= "$1<A HREF='../cbin/ORFinfo.pl?gid=$2'>gid:$2</A>$3\n";
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
  return $html;
}


sub add_db_link {
  my ($link) = (@_);

  my $return = "";

#  print STDERR "LINK ::: $link\n";

  # Add links to external databases.
  if ($link =~ /^gid|gid(\d+)(.*)$/) {
    $return = "<A HREF='$db{'mutagen'}$1'>gid:$1</A>$2\n";
  }
  elsif ($link =~ /^gid:(\d+)(.*)$/) {
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

sub parse_blast {

  # Created by Kim Brugger Fall 2002
  my ($filename, # Name of the file containing the blast repport
      ) = (@_);
  #
  # blastreport parse function. That are capable of parsing a blastn or blastp
  # report from NCBI blast.
  # The program returns an array of hashes containing the information

  open (FIL, $filename) || die "Could not open file : $filename : $!";
  
  my @blasthashes;

  my $report = "";
  while(<FIL>){
    my @hits;
    my %blasthash=();
    if(/(BLASTP|BLASTN|BLASTX|TBLASTN|TBLASTX)/){
      while(<FIL>){	

	# Check to see if we are at the end of the report
	if(/^S2:/ || /^Matrix:/){
	  if (%blasthash) {
	    push @blasthashes, \%blasthash;
	  }
	  last;
	}
	
      NEXT_HIT:
	if (/^(Query= )(.*)$/){
	  chomp;
	  $blasthash{"qname"}=$2;
	  
	  while(<FIL>){
	    if (/\s*\((.+) letters\)/){
	      $blasthash{"qlength"} = $1;
	      $blasthash{"qlength"} =~ s/\,//g;
#	      print Dumper(\%blasthash);
	      last;	
	    }	
	  }
	}
	elsif(/^>(.*)/){
	  my (%hit, @facts);
	  chomp;
	  $hit{"sname"}=$1;
	  my $fullname = 0;

	  while(<FIL>){
	    # make sure we get the full name of the hit (tm)
	    if (/^\s*Length = (\d*)/){
	      $hit{"slength"}=$1;
	      $fullname=1;
	      #now we find "length" followed by an empty line followed by " Score"
	      my %fact = ();
#	      $_=<FIL>;
	      while (<FIL>) {
#		if (/^ Score =\s*(.*?) bits \((\d+)\), Expect = (\d*.*)/) {
		if (/^ Score =.*? bits \((.*?)\), Expect = (.*?)$/) {
#		  print STDERR "SCORE = '$_";
		  if (%fact) {
		    my %fact_copy;
		    %fact_copy = %fact;
		    push @facts, \%fact_copy ;
		    %fact  = ();
		  }
		  $fact{"Score"}=$1;
		  $fact{"Expect"}=$3;
		}
		if (/^ Score =.*? bits \((.*?)\), Expect\(.*?\) = (.*?)$/) {
#		  print STDERR "SCORE = '$_";
		  if (%fact) {
		    my %fact_copy;
		    %fact_copy = %fact;
		    push @facts, \%fact_copy ;
		    %fact  = ();
		  }
		  $fact{"Score"}=$1;
		  $fact{"Expect"}=$3;
		}
		elsif (/^ Identities = (\d*\/\d* \(\d*\%\)), Positives = (\d*\/\d* \(\d*\%\))(, Gaps = (\d*\/\d* \(\d*\%\))|)/) {
		  $fact{"Identities"}=$1;
		  $fact{"Positives"}=$2;
		  $fact{"Gaps"}=$4 || 0;
		}
		elsif(/^ Identities = (\d*)\/\d* \(\d*\%\)(, Gaps = (\d*\/\d* \(\d*\%\))|)/) {
		  $fact{"Identities"}=$1;
		  $fact{"Gaps"}=$3 || 0;
		}
		elsif (/Sbjct:\s*(\d*)\s*[\w\-\*]+\s*(\d*)/) {
#		  print STDERR "ssart $_ $1, $2 $fact{'sstart'}\n";
#		  print STDERR Dumper(\%fact);
		  $fact{"sstart"} = $1 if (!$fact{"sstart"});
		  $fact{"sstop"} = $2;
		}
		elsif (/Query: (\d*)\s*[\w\-\*]+\s*(\d*)/) {
#		  chomp;
#		  print STDERR "qsart '$1', '$2' $fact{'qstart'}, $_";
		  $fact{"qstart"} = $1 if (not defined $fact{'qstart'});
		  $fact{"qstop"} = $2;
		}
		  
#		print STDERR "looking for > $_";
		if (/^\>/ || /  Database/) {
		  push @facts, \%fact if (%fact);
		  $hit{'facts'} = \@facts;
#		  print STDERR "GOTO $_\n";
		  push @hits, \%hit;
#		  print STDERR Dumper(\@hits);
		  goto NEXT_HIT;
		}
	      }
	    }
	    elsif (!$fullname) {
	      chomp;
	      s/^\s*/ /;
	      $hit{"sname"}.= " $_";
	      next;
	    }
	  }

	  push @hits, \%hit  if (%hit);
	} 
	$blasthash{'hits'} = \@hits;
      } 
    }
  }

 END:
  close FIL || die "Could not close file $filename: $!";

#  print STDERR "------||||||".Dumper(\@blasthashes);
  return @blasthashes;
}


sub sequence_id {
  my ($name) = @_;

  $name =~ s/\ .*$//;
  
  return $name;
}

## Sort functions
sub bynumber { $a <=> $b }
