#!/usr/bin/perl -w
# 
# 
# 
# 
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;
use Data::Dumper;



my @reports = reformat(shift);

#print Dumper \@reports;

report2files (\@reports, "tmp", );

#print Dumper (
# (parse(shift));


sub report2files {
  my ($reports, $outdir, $compress ) = @_;

  foreach my $report (@$reports) {
    $report =~ /(gid:\d+)/;
    
    my $gid = $1;
    
    die "Could not find gid in the report\n" if (!$gid);
    
    open OUTFILE, "> $outdir\/$gid\.pfam" or die "Could not open '$outdir\/$gid\.pfam': $!\n";
    print OUTFILE $report;
    close OUTFILE or die "Could not close '$outdir\/$gid\.pfam': $!";

    system "gzip $outdir\/$gid\.pfam" if ($compress);
  }
  

}

# Alters the pfam report, so that the hits are ordered according to score
# instead of occurrence in the pfam dbase
# 
# Kim Brugger (29 Nov 2003)
sub reformat {
  my($infile) = @_;

  open FIL, $infile or die "Could not open '$infile': $!\n";
  
  my @pfams;
  my %pfam = ();
  my @hit_list = ();
  my $report = "";
  while (<FIL>) {

    s/^(Query sequence: gid:\d+).*$/$1/;
    $report .= $_;

    if (/^Query sequence: (.*)$/) {
      $pfam{'qname'} = $1;
      $pfam{'qname'} = $1 if ($pfam{'qname'} =~ /^(gid:\d+)/);
    }

    # This is the ordered list of hits, so the first hit is the best, 
    # This is going to be used for making a ordered list of the 
    # unordererd alignments located below in the report.
    if (/Scores for sequence family classification/) {
      # trow away the next two lines .
      $report .= <FIL> . <FIL>;
      while (<FIL>) {
	$report .= $_;
	chomp;
	if (/^([\w|-]+)\W+(.*?) +-{0,1}(\d+\.\d)\W+(.*?)\W+\d$/) {
	  push @hit_list, $1;
	}
	last if (/^\W*$/);
      }
    }

#    print Dumper (@hit_list);
    
    # Here comes the alignments.
    if (/^Alignments of top-scoring domains/) {      
#      print "looking for alignments\n";
      my $alignment = "";
      my ($id, $last_id) = ("","");
      while (<FIL>) {
	if (/([\w|-]+): domain \d+ of \d+, from \d+ to \d+: score -{0,1}[\d|\.]+, E = .*/) {
	  $id = $1;
	  # If the variable contains an alignment save this.
	  if ($alignment && $last_id) {
	    # Find where the alignment belongs, by going througt the ordered hit list.
	    for (my $i = 0;$i < @hit_list;$i++) {
#	      print "($hit_list[$i] eq $last_id $id) $_$alignment\n";
	      if ($hit_list[$i] eq $last_id) {
		$hit_list[$i] = "$alignment";
#		$id = "";
		$alignment = "";
		last;
	      }
	    }
	  }
	  $last_id = $id; 
	  $id = "";
	}


	if (/^\/\//) {
	  if ($alignment) {
	    # Find where the alignment belongs, by going througt the ordered hit list.
	    for (my $i = 0;$i < @hit_list;$i++) {
	      if ($hit_list[$i] eq $last_id ) {
		$hit_list[$i] = "$alignment\n";
		$id = "";
		last;
	      }
	    }
	  }

	  push @pfams, $report . join("", @hit_list) ."//\n";
	  @hit_list = ();
	  $report = "";
	  $alignment ="";
#	  goto LAST;
	  last;
	}
	$alignment .= $_;
	
      }
    }
    
    # Last line in the report.
  }

 LAST:

  return @pfams;
}





sub parse {
  my ($infile) = @_;


  open FIL, $infile or die "Could not open '$infile': $!\n";
  
  my @pfams;
  my %pfam = ();
  my @hit_list = ();
  while (<FIL>) {

    if (/^Query sequence: (.*)$/) {
      $pfam{'qname'} = $1;
      $pfam{'qname'} = $1 if ($pfam{'qname'} =~ /^(gid:\d+)/);
    }
    if (/^Accession: *?(.*?)$/) {
      $pfam{'Accession'} = $1;
    }
    if (/^Description: *?(.*?)$/) {
      $pfam{'Description'} = $1;
    }

    # This is the ordered list of hits, so the first hit is the best, 
    # This is going to be used for making a ordered list of the 
    # unordererd alignments located below in the report.
    if (/Scores for sequence family classification/) {
      # trow away the next two lines .
      <FIL>;<FIL>;
      while (<FIL>) {
	chomp;
	if (/^([\w|-]+)\W+(.*?) +-(\d+\.\d)\W+(.*?)\W+\d$/) {
	  push @hit_list, {id=>$1, name=>$2};
	}
	last if (/^\W*$/);
	
      }
    }
    
    # Here comes the alignments.
    if (/^Alignments of top-scoring domains/) {
#      print "looking for alignments\n";
      while ((<FIL>)) {
	if (/([\w|-]+): domain \d+ of \d+, from (\d+) to (\d+): score (-{0,1}[\d|\.]+), E = (.*)/) {
#	  print "$1 -- $2 -- $3 -- $4 -- $5\n";
	  for (my $i = 0;$i < @hit_list;$i++) {
	    if ($hit_list[$i]{id} eq $1 ) {
	      $hit_list[$i] = {id =>     $1, 
			       desc =>   $hit_list[$i]{name},
			       to =>     $2,
			       from =>   $3,
			       score =>  $4,
			       evalue => $5};
	      last;
	    }
	  }
	}
	last if (/\/\//); 
      }
    }
    # Last line in the report.
    if (/\/\//) {
      my %pf = %pfam;
      my @hl = @hit_list;
      $pf{'hits'} = \@hl;
      push @pfams, \%pf;
      %pfam = ();
      @hit_list = ();
    }
  }

  return @pfams;
}

