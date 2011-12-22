#!/usr/bin/perl -wT
# 
# Handles the automatic generated data, from blasting e&.
# 
# 
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;
use db;

package db::adc;
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
# Fetches all ADC entries based on either oid or oid and source.
# 
# Kim Brugger (28 Nov 2003)
sub fetch  {
  my ($gid, $source) = @_;

  my $s = "SELECT * FROM adc WHERE gid = '$gid'";
  $s.= " AND source = '$source'" if ($source);

#  print STDERR "db::adc::fetch::$s\n";

  my $sth = $db::dbh->prepare($s);
  $sth->execute  || die $DBI::errstr;
  
  my @res = ();
  while (my $info = $sth->fetchrow_hashref) {
    push @res, $info;
  }

  return @res;
}


# 
# Saves a the adc information
# 
# Kim Brugger (28 Nov 2003)
sub save  {
  my ($hash_ref) = @_;
  
  my $s = "INSERT INTO adc SET ";

  my @parts;

  # Build the rest of the sql here ...
  foreach my $key (keys %$hash_ref) {
    # one should not meddle with the id's since it ruins the system
#    next if ($key eq 'gid');
    push @parts, "$key = ".$db::dbh->quote($$hash_ref{$key});
  }
  # collect everything ...
  $s .= join (', ', @parts);

#  print STDERR "db::adc::save::$s\n";

  my $sth = $db::dbh->prepare($s);
  $sth->execute  ||   ( die $DBI::errstr );

  # Returns the id if the newly created gene
  return $sth->{mysql_insertid};
}


# 
# update the adc information, 
# 
# Kim Brugger (28 Nov 2003)
sub update  {
  my ($hash_ref) = @_;
  
  my $s = "UPDATE adc SET ";

  my @parts;

  # Build the rest of the sql here ...
  foreach my $key (keys %$hash_ref) {
    # one should not meddle with the id's since it ruins the system
    next if ($key eq 'gid');
    next if ($key eq 'source');
    push @parts, "$key = ".$db::dbh->quote($$hash_ref{$key});
  }
  # collect everything ...
  $s .= join (', ', @parts);
  $s .= " WHERE gid = '$$hash_ref{'gid'}' AND source = '$$hash_ref{'source'}'";

#  print STDERR "db::adc::update::$s\n";

  my $sth = $db::dbh->prepare($s);
  $sth->execute  ||   ( die $DBI::errstr );

  # Returns the id if the newly created gene
  return $sth->{mysql_insertid};
}



# 
# Fetches all the auto collected data related to one gid.
# 
# Kim Brugger (17 Jun 2005)
sub fetch_all {
  my ($gid) = @_;

  my $s = "SELECT * FROM ADC WHERE gid = '$gid'";

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
# Deletes a entry linked to a gid
# 
# Kim Brugger (17 Jun 2005)
sub delete_all {
  my ($gid) = @_;
  
  my $s = "DELETE FROM adc WHERE gid ='$gid'";

  my $sth = $db::dbh->prepare($s);
  $sth->execute  ||   print STDERR "db_core::_delete_gene::$s\n" && die $DBI::errstr ;

  # Returns the id if the newly created gene
  return undef;
}


BEGIN {

}

END {

}

1;


