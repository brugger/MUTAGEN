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
  print STDERR "The server cannot analyse more than 4000 sequences at a time, have to split the input file\n";
  my @files = split_fasta($infile, 200);

  foreach my $file (@files) {
    run_tmhmm ($file);
    `rm $file`;
#    print STDERR "Treating $file\n";
  }
  
  
}
else {
  run_tmhmm ($infile);
}

sub run_tmhmm {
  my ($filename) = @_;

  my $browser = new LWP::UserAgent;
  my $url = "http://www.cbs.dtu.dk/cgi-bin/nph-webface";
  $browser->agent("MUTAGENic agent");


  my $response = $browser->request(POST $url, 
				   Content_Type => 'form-data', 
				   Content => ['configfile' => '/usr/opt/www/pub/CBS/services/TMHMM-2.0/TMHMM2.cf',
					       'seqfile' => [$filename],
					       'outform' => '-short',
					       ]
				   );


  die "Could not get '$url': ", $response->status_line , "\n"
      unless $response->is_success;

#print $response->content;
  print STDERR "The sequences have been submitted, looking for the redirection link ...\n";
  my $redirection = "";
  $response->content =~ /replace\(\"(.*)\"\)/;
  $redirection = $1;
  while (1) {

    $response = $browser->get ("$redirection");
    
    die  "Could not get '$redirection': ", $response->status_line , "\n"
	unless $response->is_success;
#    print STDERR "\n-----------------------------------\n",$response->content,"\n-----------------------------------\n";
    last if ($response->content =~ /The job has finished/ || 
	     $response->content =~ /TMHMM result/);
    # Create a more intelligent algorithm later
    my $sleep = 15;
    print STDERR "We have been redirected again, so we will wait $sleep seconds before next poll\n$redirection\n";
    sleep($sleep);
    
  }

#print STDERR "The result is found at $redirection\n";
  print STDERR "The result can be found at $redirection\n";
  $response = $browser->get ("$redirection");

  die "Could not get '$redirection': ", $response->status_line , "\n"
      unless $response->is_success;

  foreach my $line (split ("\n",$response->content)) {
    next if ($line !~ /ExpAA=/);

    $line =~ m/^(\S+)\t.*?\tExpAA=(\d+).*?\tPredHel=(\d+)/;
    my ($gid, $score, $helixs) = ($1, $2, $3);
    next if (!$helixs);
    
    $gid =~ s/(\S+)_(\d+)/$1:$2/;
    print "$gid\t$helixs\t$score\n";

    # Zero $1 so we do not get repeats of information
    " " =~ /\ /; 
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





