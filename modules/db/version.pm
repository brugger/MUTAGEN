#!/usr/bin/perl -wT
# 
# Handles the version tables.
# 
# 
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;

use db;

package db::version;
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

# fetches version information
sub fetch {
  my ($vid) = @_;

  my  $s  = "SELECT * from version WHERE vid ='$vid'";
  
#  print STDERR "db_core::_fetch_assembly::$s\n";
  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;
  
  # returns a hash referecne where the information can later be collected from.
  return ($sth->fetchrow_hashref);
}

sub latest {
  my ($oid) = @_;

  my $s = "SELECT vid, version FROM version where oid = '$oid' ORDER by vid DESC LIMIT 0, 1";

#  print STDERR "db_core::_fetch_latest_assembly::$s\n";
  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;

  # returns a hash referecne where the information can later be collected from.
  return ($sth->fetchrow_hashref);
}

sub delete {
  my ($vid) = @_;

  my $s = "DELETE FROM version WHERE vid = '$vid'";

  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;

  return undef;
}

sub fetch_all {
  my ($oid) = @_;

  my $s = "SELECT * FROM version where oid = '$oid'\n";

  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;
  
  my @res;
  
  while (my $info = $sth->fetchrow_hashref) {
    push @res, $info;
  }
  
  # Return the array of hash references
  return @res;
}

# creates the next assebly id for an organism
sub next {
  my ($oid) = @_;

  my $s = "INSERT INTO version (oid, version) values ";
  $s .= "('$oid', '". __calculate_next($oid)."')";

  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;

  # returns the assembly id (aid)
  return $sth->{mysql_insertid};  
}

# finds the next version for sequence. (HIDDEN FUNCTION)
sub __calculate_next {
  my ($oid)  = @_;

  my $s = "select (version + 1) as next from version where ";
  $s .= "oid = '$oid' order by next desc limit 0,1";

  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;
  
  my @res;
  
  my $info = $sth->fetchrow_hashref;
  $sth->finish;
  return $$info{'next'} if ($info);
  # if no result, the next one must be the first.
  return 1;
}


# 
# fetches the version information based on gid nummer
# 
# Kim Brugger (11 Dec 2003)
sub fetch_by_gid  {
  my ($gid) = @_;

  my $s = "SELECT version.* FROM version, sequence, gene WHERE ";
  $s .= "gene.gid = '$gid' AND gene.sid=sequence.sid AND sequence.vid = version.vid";

  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;

  # returns a hash referecne where the information can later be collected from.
  return ($sth->fetchrow_hashref);
}


BEGIN {

}

END {

}

1;


