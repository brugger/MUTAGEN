#!/usr/bin/perl -w
#
#
# 

use strict;

use LWP;
use HTTP::Request::Common;

my $infile = shift || die "Usage: $0 infile";

my $number_of_seqs = `egrep ^\\> $infile | wc -l`;


if ($number_of_seqs > 2000) {
  print STDERR "The server cannot analyse more than 2000 sequences at a time, have to split the input file\n";
  my @files = split_fasta($infile, 1000);

  foreach my $file (@files) {
    run_signalp ($file);
    `rm $file`;
#    die "---\n";
#    print STDERR "Treating $file\n";
  }
}
else {
  run_signalp ($infile);
}

sub run_signalp {
  my ($filename) = @_;

  my $browser = new LWP::UserAgent;
  my $url = "http://www.cbs.dtu.dk/cgi-bin/nph-webface";
  $browser->agent("MUTAGENic agent");


  my $response = $browser->request(POST $url, 
				   Content_Type => 'form-data', 
				   Content => ['configfile' => '/usr/opt/www/pub/CBS/services/SignalP-2.0/signalp.cf',
					       'sfile' => [$filename],
					       'orgtype' => 'euk',
					       'method' => 'hmm',
					       'trunc' => '70',
					       'format' => 'summary',
					       'graphmode' => ''
					       ]
				   );


  die "Could not get '$url': ", $response->status_line , "\n"
      unless $response->is_success;
#  print $response->content;

#print $response->content;
  print STDERR "The sequences have been submitted, looking for the redirection link ...\n";
  my $redirection = "";
  $response->content =~ /replace\(\"(.*)\"\)/;
  $redirection = $1;

  while () {

    $response = $browser->get ("$redirection");

    
    die  "Could not get '$redirection': ", $response->status_line , "\n"
	unless $response->is_success;

    last if ($response->content =~ /The job has finished/ ||
	     $response->content =~ /SignalP V2.0 World Wide Web Server/);
    # Create a more intelligent algorithm later
    my $sleep = 5;
    print STDERR "We have been redirected again, so we will wait $sleep seconds before next poll\n$redirection\n";
    sleep($sleep);
    
  }

  print STDERR "The result is found at $redirection\n";
  $response = $browser->get ("$redirection");

  die "Could not get '$redirection': ", $response->status_line , "\n"
      unless $response->is_success;

#print $response->content;

  my ($gid, $prediction, $pep_pro, $anc_pro);
  foreach my $line (split ("\n",$response->content)) {

    # this is a gid
    if ($line =~ /^\>(\S*?) /) {
      $gid = $1;
      # a hack since CBS ruins the format of our header lines ...
      $gid =~ s/(\S+?)_(\d+).*/$1:$2/;
    }

    if ($line =~ /Prediction: (.*)$/) {
      $prediction = $1;
    }

    if ($line =~ /Signal peptide probability: (.*)/) {
      $pep_pro = $1;
    }

    if ($line =~ /Signal anchor probability: (.*)/) {
      $anc_pro = $1;
    }

    if ($line =~ /Max cleavage site probability/) {
      if ($pep_pro > 0.6 || $anc_pro > 0.6) {
	if ($pep_pro <  $anc_pro) {
	  print "$gid\t$prediction\t$anc_pro\n";
	}
	else {
	  print "$gid\t$prediction\t$pep_pro\n";
	}
      }

      ($gid, $prediction, $pep_pro, $anc_pro) = ("","","","");
    }

  }
}

sub split_fasta {
  my ($filename, $max_length) = @_;
  my ($o_file, $prefix, $i, @o_files) = ("", 0, 0);
  my ($name, $sequence) = ("","");

  open INFILE,  "$filename"    or die "Could not open '$filename': $!";
  open OUTFILE, "> $filename.$prefix" or die "Could not open '$filename.$prefix': $!";
  push @o_files, "$filename.$prefix";
  while (<INFILE>) {
#    chomp;
    if ($name && /^\>/) {
      print OUTFILE ">$name\n",$sequence;
      $i++;
      # no more entries in this file, create a new one.
      if ($i >= $max_length) {
	close OUTFILE or die "Could not close '$filename.$prefix': $!";
	$prefix++;
	open OUTFILE, "> $filename.$prefix" or die "Could not open '$filename.$prefix': $!";
	push @o_files, "$filename.$prefix";
	$i = 0;
      }
    }  
    if (/^\>(.*)/) {
      $name = $1;
      $name =~ s/(.*?) /$1/;
      $sequence = "";
    }
    else {
      $sequence .= $_;
    }
    
  }
    
  if ($name) {
    print OUTFILE ">$name\n",$sequence;
  }
    
  close OUTFILE or die "Could not close '$filename.$prefix': $!";
  return @o_files;
}

