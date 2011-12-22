#!/usr/bin/perl -wT
# 
# Transforms blast-, pfam, signalp- and tmhmm-reports into a tabular
# format that can be transfered into the database.
# 
# The program can either be called with specific functions, and later
# it will try and "guess" the type of file, but the latter will come 
# when I have a bit more time.
#
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;
use Getopt::Std;
use Data::Dumper;

my %opts = ();
getopts('b:p:t:s:h', \%opts);

use lib '/data/www/sulfolobus.org/modules/';

if ($opts{'b'}) {
  blast2tab($opts{'b'});
}
elsif ($opts{'p'}) {
  pfam2tab($opts{'p'});
}
elsif ($opts{'t'}) {
  tmhmm2tab($opts{'t'});
}
elsif ($opts{'s'}) {
  signalp2tab($opts{'s'});
}
else {
  $0 =~ s/^.*\/(\w+)$/$1/;
  print "Usage: $0 -b(last) -p(fam) -t(mhmm) -s(ignalp)\n";
}

# 
# 
# 
# Kim Brugger (23 Feb 2004)
sub blast2tab  {
  my ($infile,      #
      $min_e,       # If the output should be limited based on evalue
      $remove_self, # checks that the query != best-hit
      ) = @_;

  require parser::blast;
  my @blasthashes = parser::blast::bestHits($infile);

  foreach my $report (@blasthashes) {
    
    #trim the name so it only consists of a gid:[number] tag.
    $$report{'qname'} =~ s/^(gid:\d+).*/$1/;

    print "$$report{'qname'}\t$$report{'sname'}\t$$report{'exept'}\n";
  }
  
}

# 
# 
# 
# Kim Brugger (27 Nov 2003)
sub blast2tab__OLD  {
  die "This function is obsolete\n";

  my ($infile,      #
      $min_e,       # If the output should be limited based on evalue
      $remove_self, # checks that the query != best-hit
      ) = @_;

  require parser::blast;
  my @blasthashes = parser::blast::parse($infile);

  foreach my $report (@blasthashes) {
    
    #trim the name so it only consists of a gid:[number] tag.
    $$report{'qname'} =~ s/^(gid:\d+).*/$1/;

    my ($hit_name, $hit_score) = ("","");

    # This is a bit magic, but accessing deep datastructures,
    # in data structures is a bit difficult.
    if ($$report{'hits'}[0]) {
      $hit_name = $$report{'hits'}[0]{'sname'};
      $hit_name =~ s/^(.*?\]).*/$1/;

      $hit_score = $$report{'hits'}[0]{'facts'}[0]{'Expect'};

      print "$$report{'qname'}\t$hit_name\t$hit_score\n";
    }
  }
  
}

# 
# 
# 
# Kim Brugger (27 Nov 2003)
sub pfam2tab  {
  my ($infile,      #
      ) = @_;

  require parser::pfam;
  my @pfams = parser::pfam::parse($infile);

  foreach my $pfam (@pfams) {
    $$pfam{'qname'} = $1 if ($$pfam{'qname'} =~ /^(gid:\d+)/);
    
    
    my ($hit_name, $hit_score) = ("","");
    if ($$pfam{'hits'}[0]) {
      $hit_name  = $$pfam{'hits'}[0]{'desc'};
      $hit_score = $$pfam{'hits'}[0]{'evalue'};

      print "$$pfam{'qname'}\t$hit_name\t$hit_score\n";
    }
  }

}

# 
# Checks that the gid name looks ok, otherwise refomat it
# 
# Kim Brugger (27 Nov 2003)
sub tmhmm2tab  {
  my ($infile,      #
      ) = @_;

  open FIL, $infile or die "Could not open '$infile': $!";
  while (<FIL>) {
    if (/^gid[:_-](\d+).*?\t(\d+)\t(\d+)$/) {
      $_= "gid:$1\t$2\t$3\n";
    }
    print;
  }

}

# 
# 
# 
# Kim Brugger (27 Nov 2003)
sub signalp2tab  {
  my ($infile,      #
      ) = @_;

  open FIL, $infile or die "Could not open '$infile': $!";
  while (<FIL>) {
    if (/^gid[:_-](\d+).*?\t([\w ]+)\t([\d.]+)$/) {
      $_= "gid:$1\t$2\t$3\n";
    }
    print;
  }

}
