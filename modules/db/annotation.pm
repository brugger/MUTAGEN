#!/usr/bin/perl -wT
# 
# Transfer/deletes/updates the annotations.
# 
# 
# Kim Brugger (Dec 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;
use db;

package db::annotation;
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
# fetch an annotation
# 
# Kim Brugger (10 Dec 2003)
sub fetch  {
  my ($aid) = @_;

  my $s = "SELECT * FROM annotation WHERE aid = '$aid'";

  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;

  return $sth->fetchrow_hashref;
}


# 
# fetches all annotations belonging to a gid.
# 
# Kim Brugger (10 Dec 2003)
sub all  {
  my ($gid, $latest) = @_;

  my $s = "SELECT * FROM annotation WHERE gid = '$gid'";
  $s .= " LIMIT 0,1" if ($latest);

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
# stores an annotation
# 
# Kim Brugger (10 Dec 2003)
sub save  {
  my ($hash_ref) = @_;

  my $s = "INSERT INTO annotation SET ";

  my @parts;

  # Build the rest of the sql here ...
  foreach my $key (keys %$hash_ref) {
    # one should not meddle with the id's since it ruins the system
#    next if ($key eq 'gid');
    push @parts, "$key = ".$db::dbh->quote($$hash_ref{$key});
  }
  # collect everything ...
  $s .= join (', ', @parts);

#  print STDERR "db_core::_save_gene::$s\n";

  my $sth = $db::dbh->prepare($s);
  $sth->execute  ||   ( die $DBI::errstr );

  # Returns the id if the newly created gene
  return $sth->{mysql_insertid};
}


# 
# updates an annotation
# 
# Kim Brugger (10 Dec 2003)
sub update  {
  my ($hash_ref) = @_;
  
  my $s = "UPDATE annotation SET ";

  my @parts;
  # Build the rest of the sql here ...
  foreach my $key (keys %{$hash_ref}) {
    # one should not meddle with the id's since it ruins the system
    next if ($key eq 'aid');
    push @parts, "$key = ".$db::dbh->quote($$hash_ref{$key});
  }

  # collect and make sure we update the right table.
  $s .= join (', ', @parts) ." WHERE aid ='$$hash_ref{'aid'}'";

#  print STDERR "\ndb_core::_update_gene::$s\n\n";

  my $sth = $db::dbh->prepare($s);
  $sth->execute  || die $DBI::errstr;;

  # Returns the id if the newly created gene
  
  return $$hash_ref{aid};
}

# 
# fetches an annotation based on the fid
# 
# Kim Brugger (10 Dec 2003)
sub fetch_by_fid  {
  my ($fid) = @_;
  
  my $s = "SELECT * FROM annotation WHERE fid = '$fid'";


  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;

  return $sth->fetchrow_hashref;
}



# 
# Deletes an annotation
# 
# Kim Brugger (27 Feb 2004)
sub delete {
  my ($aid) = @_;

  my $s = "DELETE FROM annotation WHERE aid = '$aid'";

  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;

  return undef;
}




BEGIN {

}

END {

}

1;


