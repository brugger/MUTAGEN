#!/usr/bin/perl -wT
# 
# 
# 
# 
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;

use db;

package db::cluster;
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


sub fetch {
  my ($cid) = @_;

  my $s = "SELECT gene.gid, gene.sid, gene.name, version.version, organism.name as org_name, version, ((gene.stop - gene.start+1)/3) as length ";
  $s .= "FROM gene, sequence, organism, version WHERE gene.cid ='$cid' ";
  $s .= "AND gene.sid = sequence.sid AND sequence.oid = organism.oid ";
  $s .= "AND sequence.vid = version.vid ";

  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;
  my @res;
  
  while ( my $info = $sth->fetchrow_hashref ) {
    push @res, $info;
  }
  
  # returns an array of references to hash elements.
  return @res;
}


# 
# delete all cluster information in the database
# 
# Kim Brugger (16 Mar 2004)
sub delete_all {
  
  my $s = "UPDATE gene set cluster = NULL, cid = NULL, ccolour = NULL";

  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;
  
  return undef;
}


BEGIN {

}

END {

}

1;


