#!/usr/bin/perl -wT
# 
# Functions related to handling organism info
# 
# 
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;

use db;

package db::organism;
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

#
# fetches all information about a organism, based on id, short_name or long_name (in that order)
#
sub fetch {
  my ($oid) = @_;

  my $s = "SELECT * FROM organism WHERE oid = '$oid' OR alias = '$oid' OR name = '$oid'";

#  print STDERR "db_core::_fetch_organism::$s\n";
  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;;
  
  return ($sth->fetchrow_hashref);
}

sub all {

  my $s = "select * from organism";
 
#  print STDERR "db_core::_fetch_organisms::$s\n";
  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;;
  
  my @_res;
  while (my $info = $sth->fetchrow_hashref) {
    push @_res, $info;
  }

  return @_res;
}

#
# the hash_ref have to have include an orgnaism name, and alternatively also a short name (read on)
#
sub save {
  my ($hash_ref)  = @_;

  $$hash_ref{type} = 'organism' if (!$$hash_ref{type});
  $$hash_ref{"subtype"} = '' if (!$$hash_ref{type});

  my $s = "INSERT INTO organism (name, alias, type, subtype) VALUES ('$$hash_ref{'name'}','$$hash_ref{'alias'}', '$$hash_ref{'type'}', '$$hash_ref{'subtype'}')\n";
#  print STDERR "organism::save::$s\n";
  my $sth = $db::dbh->prepare($s);

  
  $sth->execute || die $DBI::errstr;
  
  # returns the oid of the organism created.
  return $sth->{mysql_insertid};
}

#
# Update organism information
#
sub update {
  my ($hash_ref)  = @_;


  my $s = "UPDATE organism SET ";

  my @parts;
  # Build the rest of the sql here ...
  foreach my $key (keys %{$hash_ref}) {
    # one should not meddle with the id's since it ruins the system
    next if ($key eq 'oid');
    push @parts, "$key = ".$db::dbh->quote($$hash_ref{$key});
  }

  # collect and make sure we update the right table.
  $s .= join (', ', @parts) ." WHERE oid ='$$hash_ref{'oid'}'";

  my $sth = $db::dbh->prepare($s);
  $sth->execute  || die $DBI::errstr;;

  return $$hash_ref{'oid'};
}

sub delete {
  my ($oid) = @_;
  
  my $s = "DELETE FROM organism WHERE oid = '$oid'";

#  print STDERR "db_core::_delete_sequence::$s\n";

  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;
  
  return undef;
}


BEGIN {

}

END {

}

1;


