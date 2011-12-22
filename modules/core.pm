#!/usr/bin/perl -wT
# 
# Core function for the MUTAGEN v4 system, these functions are a wide variety of
# commonly used functions.
# 
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;
use Data::Dumper;

package core;
require Exporter;
require AutoLoader;

use conf;
use global;
use html;
use db;
use access;
use kernel;
# set the version for version checking
my $VERSION     = "0.01";

my @ISA = qw(Exporter AutoLoader);

our @EXPORT = qw();

@ISA = qw(Exporter AutoLoader);

$ENV{PATH} = "/usr/bin:/bin/:/usr/local/bin";

use vars qw ();


# 
# Converts datetime (from mysql) to a normal date.
# 
# Kim Brugger (11 Dec 2003)
sub datetime2date  {
  my ($date) = @_;

  return undef if (!$date);

  $date =~ s/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/$3\/$2-$1 $4:$5:$6/;
  return $date;
}



#
# Sorts gene_names if they are in the form of ContigID_START_STOP
#
sub gene_sort {
  my ($A,$B) = ($a, $b);

  # remove leading > if it is found in the gene name
  $A =~ s/^>//;
  $B =~ s/^>//;

  my ($a_contig, $a_start, $a_stop) = split /[-_]/, $A;
  my ($b_contig, $b_start, $b_stop) = split /[-_]/, $B;

  ($a_start, $a_stop) = ($a_stop, $a_start)
      if ($a_start > $a_stop);

  ($b_start, $b_stop) = ($b_stop, $b_start)
      if ($b_start > $b_stop);

  return ($a_contig cmp $b_contig) || ($a_start <=> $b_start) || ($a_stop <=> $b_stop);
}

sub contigsort {
  my ($A,$B) = @_;

  $A =~ s/[a-zA-Z_\.\-\ \(\)]//g;
  $B =~ s/[a-zA-Z_\.\-\ \(\)]//g;

  return ($B <=> $A);
}


# 
# Extract the nucleotide sequence, from the database.
# 
# Kim Brugger (04 Feb 2004)
sub extract_sequence  {
  my ($sid, $name, $start, $stop) = @_;


#  print STDERR "$sid, $name, $start, $stop\n";
  
  require db::sequence;
  my $sequence = "";
  my $seq_name = "";
      
  # if a start and stop position exists, extract only the sequence between these the
  # start and the stop position. 

  if ($start && $stop && 
      $start <  $stop) {
    $sequence = &db::sequence::sub_sequence($sid, 
					    $start-1,
					    $stop-$start+1);
   
    $seq_name = ">sid:$sid $name\_$start-$stop";
    $sequence = $$sequence{'sequence'};
  }
  elsif ($start && $stop && 
	 $start  > $stop) {
    $sequence = &db::sequence::sub_sequence($sid, 
					    $stop-1,
					    $start-$stop+1);


    $seq_name = ">sid:$sid $name\_$stop-$start";
    $sequence = $$sequence{'sequence'};
    $sequence = &kernel::revDNA($sequence);
  }
  elsif ($start && 
	 $start  > 1) {
    $sequence = &db::sequence::sub_sequence($sid, 
					    $stop-1,
					    $start-$stop+1);
    
    $seq_name = ">sid:$sid $name\_$stop-$start";
    $sequence = $$sequence{'sequence'};
  }
  elsif ($stop && 
	 $stop  > 1) {
    $sequence = &db::sequence::sub_sequence($sid, 
					    0,
					    $html::parameters{'stop'});
    
    $seq_name = ">sid:$sid $name\_$stop-$start";
    $sequence = $$sequence{'sequence'};
  }
  elsif ($start && 
	 $start  > 1) {
    $sequence = &db::sequence::sub_sequence($sid, 
					    $start);
    
    $seq_name = ">sid:$sid $name\_$stop-$start";
  }
  else {
    $sequence = &db::sequence::fetch($sid); 
    
    $seq_name = ">sid:$sid Full sequence from the database";
    $sequence = $$sequence{'sequence'};
  }    
  
#  &core::Dump($sequence);

  return ($seq_name, $sequence);
}


#
# Return the common genbank header
#
sub gbk_header {
  my ($organism, $assembly, $sequence, $start, $stop) = @_;

#  print STDERR "$start --------->>>>> $stop\n";
  
  my $res = "";
  
  $res .= "LOCUS       sid:$$sequence{'sid'}                 DNA\n";
  $res .= "DEFINITION  $$organism{name}\n";
  $res .= "ACCESSION   sid:$$sequence{'sid'}\n";
  $res .= "VERSION     $$assembly{'version'} aid:$$assembly{'aid'}\n";
  $res .= "KEYWORDS    .\n";
  $res .= "SOURCE      $$sequence{name}\n";
  $res .= "ORGANISM    $$organism{name}\n";
  $res .= "FEATURES    Location/Qualifiers\n";
  
  $res .= "     source          1..$$sequence{length}\n" if (!$start && !$stop);
  $res .= "     source          $start..$stop\n" if ($start && $stop);
  $res .= "     source          $start..$$sequence{length}\n" if (!$stop && $start);
  
  $res .= "                     /organism=\"$$organism{name}\"\n";
  
  return $res;
}



#
# Print the text as a genbank entry (with right amount of left spacing)
#
sub gbkentry {
  my ($seq) =  @_;
  chomp ($seq);
  my $j = 0;
  my $count = length $seq;                                                       
  my $res = "";
  while ($j < $count) {
    $res .= "                     " . substr($seq, $j, 58). "\n";
    $j += 58;
  } 
  
  return $res;
}


#
# format DNA sequence in the genbank format (with numbers and spaces)
#
sub gbk_DNAsequence {
  my ($seq) = @_;
  
  my $count = 1;
  my @sequences = gbk_split_sequence($seq);
  
  my $res = "";
  
  while (@sequences) {
    $res .= sprintf("%10d %s %s %s %s %s %s\n", 
           $count, shift(@sequences)||"", shift(@sequences)||"", shift(@sequences)||"", 
           shift(@sequences)||"", shift(@sequences)||"", shift(@sequences)||"");
        $count += 60;
  }

  $res .= "\/\/\n";

  return $res;
}


#
# Split the sequence nicely with spaces .... (stupid format !!!!)
#
sub gbk_split_sequence {
  my ($seq) = @_;
  my $j = 0;
  my $count = length $seq;                                                       
  my @res;
  while ($j < $count) {
    push @res, substr($seq, $j, 10);
    $j += 10;
  } 
  
  return @res;
}

sub Dump {
  my (@data) = @_;
  use Data::Dumper;

  &LOG();
  print STDERR Dumper(@data);

  return undef;
}


sub LOG {
  my ($message) = @_;

  my $remote_host = $html::remote_host;
  if (0) {
    my $host_info = &Net::hostent::gethost($remote_host);
    $remote_host = $$host_info[0];
  }
  #    0    1    2     3     4    5     6     7
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) = gmtime(time);
  $year +=1900;$hour++;$mon++;
  printf STDERR ("%s @ %02d/%02d-%4d %02d:%02d:%02d\n",
		$remote_host,$mday,$mon,$year,$hour,$min,$sec);
  if ($message) {
    while (chomp $message){;}
    print STDERR "$message\n";
  }
}


sub BEGIN {
  my $LOG_FILE = ">> $conf::errlog";

  # if we can write to the file do it, if the file do not exists, but we can 
  # write to the directory create the file.
  if (($conf::use_mutagen_log && -w $conf::errlog) || 
      (!-e $conf::errlog && -w $conf::errdir)) {
    open (STDERR, $LOG_FILE) || print STDERR  "Could not open logfile '$LOG_FILE': $!\n";
  }


  

}

1;
