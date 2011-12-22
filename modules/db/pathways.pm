#!/usr/bin/perl -wT
# 
# 
# 
# 
# Kim Brugger (Apr 2005), contact: brugger@mermaid.molbio.ku.dk
use strict;

package db::pathways;
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
# Fetch a pathway with all the gids belongiong to it...
# 
# Kim Brugger (07 Apr 2005)
sub fetch {
  my ($pid) = @_;

  my $s = "SELECT * FROM pathway WHERE pid = '$pid'";

  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;

  my $pathway = $sth->fetchrow_hashref;
  
  $s = "SELECT gid, EC FROM pathway_gid where pid = '$pid'";

  my @res;

  $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;

  while (my $info = $sth->fetchrow_hashref){
    push @res, $info;
  }

  $$pathway{genes} = \@res;

  return $pathway;
}


# 
# Fetches all the pathways belonging to an organism
# 
# Kim Brugger (07 Apr 2005)
sub organism {
  my ($oid) = @_;

  my $s = "SELECT * FROM pathway WHERE oid = '$oid'";

  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;

  my @res;
  while (my $info = $sth->fetchrow_hashref){
    push @res, $info;
  }

  return \@res;
}



# 
# 
# 
# Kim Brugger (07 Apr 2005)
sub fetch_by_oid_and_name {
  my ($oid, $vid, $name) = @_;

  my $s = "SELECT * FROM pathway WHERE oid = '$oid' and vid = '$vid' and name = '$name'";

  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;

  return $sth->fetchrow_hashref;
}

# 
# 
# 
# Kim Brugger (07 Apr 2005)
sub pathways_by_gid {
  my ($gid) = @_;

  my $s = "SELECT pathway.pid, description FROM pathway, pathway_gid WHERE gid = '$gid' ";
  $s .= "AND pathway.pid = pathway_gid.pid";

  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;

  my @res;
  
  while (my $info = $sth->fetchrow_hashref) {
    push @res, $info;
  }

  @res = sort {$$a{'description'} cmp $$b{'description'}} @res;

  return \@res;
}


# 
# Fetches all pathways in the database...
# 
# Kim Brugger (07 Apr 2005)
sub all {
  
}


# 
# Save a pathway
# 
# Kim Brugger (07 Apr 2005)
sub save {
  my ($hash_ref) = @_;

  # The hash_ref should contain the following data:
  # oid: Organism id
  # name: pathway_name
  # description: Pathway description
  # gids_ecs: an hash with a gid EC number relation ship.

  # First check and see if this pathway is already definded. If it is
  # delete the old entry.
  my $old_pid = fetch_by_oid_and_name($$hash_ref{oid}, $$hash_ref{vid},$$hash_ref{name});
  if ($old_pid) {
    &delete($$old_pid{pid});
  }

  my $s = "INSERT INTO pathway SET ";

  my @parts;


  # Build the rest of the sql here ...
  foreach my $key (keys %$hash_ref) {
    # one should not meddle with the id's since it ruins the system
    next if ($key eq 'gids_ecs');
    push @parts, "$key = ".$db::dbh->quote($$hash_ref{$key});
  }
  # collect everything ...
  $s .= join (', ', @parts);

#  print STDERR "db_core::_save_pathway::$s\n";

  my $sth = $db::dbh->prepare($s);
  $sth->execute  ||   ( die $DBI::errstr );

  # Returns the id if the newly created gene
  my $pid = $sth->{mysql_insertid};

  return undef if (!$pid);

#  print STDERR "PID == $pid";
  
  foreach my $key (keys %{$$hash_ref{gids_ecs}}) {

    my $gid = $key;
    $gid =~ s/gid://;
    
    $s = "INSERT INTO pathway_gid SET pid = '$pid', gid = '$gid', EC='${$$hash_ref{gids_ecs}}{$key}'";
    
    print STDERR "$s\n";

    my $sth = $db::dbh->prepare($s);
    $sth->execute  ||   ( die $DBI::errstr );

  }
  
  
  return $pid;
}



# 
# Update/Alter the data in a pathway. Just add code...
# 
# Kim Brugger (07 Apr 2005)
sub update {
  
}


# 
# Deteles a pathway and all the data related to it. No lose ends (tm)
# 
# Kim Brugger (07 Apr 2005)
sub delete {
  my ($pid) = @_;

  my $s = "DELETE FROM pathway where pid = '$pid'";

  my $sth = $db::dbh->prepare($s);
  $sth->execute  ||   print STDERR "db::pathway::delete::$s\n" && die $DBI::errstr ;

  $s = "DELETE FROM pathway_gid where pid = '$pid'";

  $sth = $db::dbh->prepare($s);
  $sth->execute  ||   print STDERR "db::pathway::delete::$s\n" && die $DBI::errstr ;


  # Returns the id if the newly created gene
  return undef;



  
}




BEGIN {

}

END {

}

1;
