#!/usr/bin/perl -wT
# 
# DataBase handle to the genefinder info
# 
# 
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;

use db;

package db::genefinder;
require Exporter;
require AutoLoader;

# set the version for version checking
my $VERSION     = "0.01";

my @ISA = qw(VERSION Exporter AutoLoader);

our @EXPORT = qw();
@ISA = qw(Exporter AutoLoader);
@EXPORT = qw();

#exported variables
use vars qw ();


# 
# 
# 
# Kim Brugger (24 Feb 2004)
sub fetch {
  my ($fid) = @_;

#  my $s = "SELECT gene.*, auto.*, sequence.oid ";
  my $s = "SELECT genefinder.*, organism.name as org_name, sequence.oid ";
  $s .= ", SUBSTRING(sequence.sequence, (genefinder.start), (genefinder.stop-genefinder.start+1)) AS sequence ";
  $s .= "FROM genefinder, sequence, organism WHERE ";
  $s .= "genefinder.fid = '$fid' AND genefinder.sid = sequence.sid AND organism.oid = sequence.oid";

#  print STDERR "db_core::_fetch_gene::$s\n";
  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;
  my $info = $sth->fetchrow_hashref;

  # The DNA in reversed if the gene is found on the complement strand.
  if ($info && $$info{strand}) {
    $$info{'sequence'} = &kernel::revDNA($$info{'sequence'});
  }

  return $info;
}


# 
# 
# 
# Kim Brugger (24 Feb 2004)
sub sequence {
  my ($sid, $start, $stop) = @_;

  my @gene_groups;

  
  # sort the genes from the plus strand first (same stop position)
  my $s = "SELECT * FROM genefinder WHERE sid = '$sid' AND strand = '0' ";
  
  if ($start && $stop) {     
    $s .= " AND genefinder.start <= $stop AND genefinder.stop >= $start";
  }
  elsif ($start) {     
    $s .= " AND genefinder.stop >= $start";
  }
  elsif ($stop) {
    $s .= " AND genefinder.start <= $stop";
  }

  $s .= " ORDER BY stop";

  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;

  my ($last_stop, @groups) = (-1);
  while (my $info = $sth->fetchrow_hashref) {
    
    if ($last_stop != $$info{stop} && @groups) {
      # Since we want to save the information as a ref, ve first have
      # to make a unique array to ref.
      my @g = @groups;
      push @gene_groups, \@g;

      @groups = ();
    }

    push @groups, $info;
    $last_stop = $$info{'stop'};
  }

  if (@groups) {
    my @g = @groups;
    push @gene_groups, \@g;
  }

#  return \@gene_groups;

#  @gene_groups = ();
  
  # then sort the genes from the minus strand (same start pos (really the stop))
  $s = "SELECT * FROM genefinder WHERE sid = '$sid' AND strand = '1'";

  if ($start && $stop) {     
    $s .= " AND genefinder.start <= $stop AND genefinder.stop >= $start";
  }
  elsif ($start) {     
    $s .= " AND genefinder.stop >= $start";
  }
  elsif ($stop) {
    $s .= " AND genefinder.start <= $stop";
  }

  $s .= " ORDER BY stop";

  $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;
  
  ($last_stop, @groups) = (-1);
  while (my $info = $sth->fetchrow_hashref) {
    if ($last_stop != $$info{start} && @groups) {
      # Since we want to save the information as a ref, ve first have
      # to make a unique array to ref.
      my @g = @groups;
      push @gene_groups, \@g;

      @groups = ();
    }

    push @groups, $info;
    $last_stop = $$info{'start'};
  }
  
  if (@groups) {
    my @g = @groups;
    push @gene_groups, \@g;
  }

  return \@gene_groups;
}


# 
# 
# 
# Kim Brugger (24 Feb 2004)
sub fetch_by_gid {
  my ($gid) = @_;

  my $s = "SELECT * FROM genefinder WHERE gid = '$gid'";

  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;
  
  my @res;

  while (my $info = $sth->fetchrow_hashref) {
    push @res, $info;
  }

  return \@res;
}


# 
# 
# 
# Kim Brugger (24 Feb 2004)
sub save {
  my ($hash_ref) = @_;

  my $s = "INSERT INTO genefinder SET ";

  my @parts;

  # Build the rest of the sql here ...
  foreach my $key (keys %$hash_ref) {
    # one should not meddle with the id's since it ruins the system
    next if ($key eq 'gid');
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
# 
# 
# Kim Brugger (24 Feb 2004)
sub update {
  my ($hash_ref) = @_;
  
  my $s = "UPDATE genefinder SET ";

  my @parts;
  # Build the rest of the sql here ...
  foreach my $key (keys %{$hash_ref}) {
    # one should not meddle with the id's since it ruins the system
    next if ($key eq 'fid');
    push @parts, "$key = ".$db::dbh->quote($$hash_ref{$key});
  }

  # collect and make sure we update the right table.
  $s .= join (', ', @parts) ." WHERE fid ='$$hash_ref{'fid'}'";

#  print STDERR "\ndb_core::_update_gene::$s\n\n";
  my $sth = $db::dbh->prepare($s);
  $sth->execute  || die $DBI::errstr;;

  # Returns the id if the newly created gene
#  print STDERR ".........$$hash_ref{'fid'}......";
  return $$hash_ref{'fid'};

#  return $sth->{mysql_insertid};
}


# 
# Find if a gene exists based on stop pos, sid and strand.
# 
# Kim Brugger (23 Feb 2004)
sub sameStopPos {
  my ($sid, $stoppos, $strand) = @_;

  my $s = "SELECT genefinder.* ";
  $s .= "FROM genefinder WHERE sid = '$sid' and stop = '$stoppos' AND strand = '$strand'";

#  print STDERR "db::genefinder::sameStopPos::$s\n";
  
  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;

  my @res;

  while (my $info = $sth->fetchrow_hashref) {
    push @res, $info;
  }
  
  return \@res;
}





# 
# 
# 
# Kim Brugger (14 Apr 2005)
sub delete {
  
  die "Not constructed yet\n\n";

}



BEGIN {

}

END {

}

1;


