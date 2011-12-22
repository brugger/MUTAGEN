#!/usr/bin/perl -wT
# 
# Makes it possible to search the database.
# 
# 
# Kim Brugger (Dec 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;
use db;

package db::search;
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



# 
# Fetches a gene with a gid.
# 
# Kim Brugger (11 Dec 2003)
sub gid  {
  my ($gid, $filter) = @_;

  $gid =~ s/gid:(\d+).*/$1/;

  my $s = "SELECT * FROM gene WHERE gid = '$gid' or name ='%$gid%'";

#  print STDERR "--$s\n";

  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;
  my $info = $sth->fetchrow_hashref;
  
  return ($$info{'gid'}) if ($info);
  return "";

  my @res = ($info);
  return (@res) if ($info);
  return "";
}



# 
# Fetches a gene with a gid.
# 
# Kim Brugger (11 Dec 2003)
sub gene_name  {
  my ($word, $filter) = @_;


  my $s = "SELECT gid FROM gene WHERE name = '$word'";

#  print STDERR "--$s\n";

  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;
  my $info = $sth->fetchrow_hashref;
  
  return ($$info{'gid'}) if ($info);
  return "";

  my @res = ($info);
  return (@res) if ($info);
  return "";
}



# 
# Seach through the annotations
# 
# Kim Brugger (11 Dec 2003)
sub annotations  {
  my ($word, $filter) = @_;

  my $s = "SELECT gid FROM annotation WHERE ";

  $s .= "gid like '%$word%' ";# if (!$filter || $$filter{'gid'});
  $s .= "OR gene_name like '%$word%' ";
  $s .= "OR conf_in_gene like '%$word%' ";
  $s .= "OR EC_number like '%$word%' ";
  $s .= "OR conf_in_func like '%$word%' ";
  $s .= "OR gene_product like '%$word%' ";
  $s .= "OR comment like '%$word%' ";
  $s .= "OR evidence like '%$word%' ";
#  $s .= "OR primary_function like '%$word%' ";
#  $s .= "OR secondary_function like '%$word%' ";
#  $s .= "OR TAG like '%$word%' ";
#  $s .= "OR final like '%$word%' ";
  $s .= "OR annotator_name like '%$word%' ";
#  $s .= "OR uid like '%$word%' ";

  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;
  
  my @res;

  while (my $info = $sth->fetchrow_hashref) {
    push @res, $$info{'gid'};
  }
  return @res;
}


# 
# Searches through the ADC table.
# 
# Kim Brugger (11 Dec 2003)
sub adc  {
  my ($word, $filter) = @_;
  
  my $s = "SELECT gid FROM adc WHERE ";
  $s .= "gid like '%$word%' ";# if (!$filter || $$filter{'gid'});
  $s .= "OR name like '%$word%' ";
#  $s .= "OR source like '%$word%' ";
  $s .= "OR other like '%$word%'";


  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;
  
  my @res;

  while (my $info = $sth->fetchrow_hashref) {
    push @res, $$info{'gid'};
  }
  return @res;

}



BEGIN {

}

END {

}

1;


