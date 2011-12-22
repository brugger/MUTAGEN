#!/usr/bin/perl -wT
# 
# DB handle to the gene info
# 
# 
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;

use db;

package db::gene;
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
# fetches information about a gene + sequence + automatic information
# if it also exists.  This have problems if the gene contains introns
# or are spanning base 1.
#
sub fetch {
  my ($gid) = @_; 

#  my $s = "SELECT gene.*, auto.*, sequence.oid ";
  my $s = "SELECT gene.*, organism.name as org_name, sequence.oid, sequence.vid ";
  $s .= ", SUBSTRING(sequence.sequence, (gene.start), (gene.stop-gene.start+1)) AS sequence ";
  $s .= "FROM gene, sequence, organism WHERE ";
  $s .= "gene.gid = '$gid' AND gene.sid = sequence.sid AND organism.oid = sequence.oid";

#  print STDERR "db_core::_fetch_gene::$s\n";
  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;
  my $info = $sth->fetchrow_hashref;


  # If intron, remove the intron problem
  if ($info && $$info{intron}) {
    $$info{'sequence'} = intron_free_seq($info);
  }
  

  # The DNA in reversed if the gene is found on the complement strand.
  if ($info && $$info{strand}) {
    $$info{'sequence'} = &kernel::revDNA($$info{'sequence'});
  }

  return $info if ($info);
  #  return undef;
  # If there is no information in the automatic table
  # the function falls back to just returning the orf information.

  $s = "SELECT gene.*, sequence.oid, sequence.vid ";
  $s .= ", SUBSTRING(sequence.sequence, (gene.start), (gene.stop-gene.start+1)) AS sequence ";
  $s .= "FROM gene, sequence WHERE  ";
  $s .= "gene.gid = '$gid' AND ";
  $s .= "gene.sid = sequence.sid ";
  
#  print STDERR "db_core::_fetch_gene::$s\n";
  $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;
  $info = $sth->fetchrow_hashref;

  # If intron, remove the intron problem
  if ($info && $$info{intron}) {
    $$info{'sequence'} = intron_free_seq($info);
  }

  # The DNA in reversed if the gene is found on the complement strand.
  if ($info && $$info{strand}) {
    $$info{'sequence'} = &kernel::revDNA($$info{'sequence'});
  }

  # if no result $info == undef, otherwise a hashref with containing the results
  return $info;
}



#
# Extracts the correct sequence if the gene contains an intron or
# spans base 1
#
sub intron_free_seq {
  my ($gene) = @_;


  if ($$gene{intron} && $$gene{intron} =~ /-/) {
    require db::sequence;
    my ($istart, $istop) = split("->", $$gene{intron});
    my ($gstart, $gstop) = ($$gene{start}, $$gene{stop});
    
    my $seq1 = &db::sequence::sub_sequence($$gene{sid}, $gstop-1, $istart - $gstop + 1);
    my $seq2 = &db::sequence::sub_sequence($$gene{sid}, $istop-1, $gstart - $istop + 1);

    $$gene{sequence} = $$seq1{sequence} . $$seq2{sequence};

  }
  
  return $$gene{sequence};

}


# 
# Fetch all genes related to a organism + assembly or sequence. Both extractions 
# can be limited by giving a range that the genes have to be within.
# If an oid but no vid is given the latest vid is used.
sub fetch_organism {
  my ($oid, $vid, $sid, $start, $stop) = @_;

  my $s;

  if ($oid) {
    # if no vid, we find one the fits with the organism.
    if (!$vid) {
      require db::version;
      my $vid_ref = &db::version::latest($oid);
      $vid = $$vid_ref{'vid'};
    }

    $s = "SELECT gene.*, sequence.oid as oid, ";
    $s .= "SUBSTRING(sequence.sequence, (gene.start), (gene.stop-gene.start+1)) AS sequence ";
    $s .= "FROM gene, sequence ";
    $s .= "WHERE sequence.oid = '$oid' AND sequence.sid = gene.sid AND sequence.vid = '$vid'";
  }
  else {
    $s = "SELECT gene.*  ";
    $s .= ", SUBSTRING(sequence.sequence, (gene.start), (gene.stop-gene.start+1)) AS sequence ";
    $s .= " FROM gene, sequence ";
    $s .= "WHERE gene.sid = '$sid' and sequence.sid = gene.sid";
  }

  if ($start && $stop) {     
    $s .= " AND gene.start <= $stop AND gene.stop >= $start";
  }
  elsif ($start) {     
    $s .= " AND gene.stop >= $start";
  }
  elsif ($stop) {
    $s .= " AND gene.start <= $stop";
  }
  
#  print STDERR "db_core::_fetch_genes::$s\n";
  
  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;
  my @_genes;
  while ( my $info = $sth->fetchrow_hashref ) {

    # If intron, remove the intron problem
    if ($info && $$info{intron}) {
      $$info{'sequence'} = intron_free_seq($info);
    }

    # If the gene is on the reverse strand, the DNA gets reversed
    if ($info && $$info{strand} && $$info{'sequence'}) {
      $$info{'sequence'} = &kernel::revDNA($$info{'sequence'});
    }
    push @_genes, $info;
  }
  
  # returns an array of references to hash elements.
  return @_genes;
}

sub save {
  my ($hash_ref) = @_;
  
  my $s = "INSERT INTO gene SET ";

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

sub update {
  my ($hash_ref) = @_;
  
  my $s = "UPDATE gene SET ";

  my @parts;
  # Build the rest of the sql here ...
  foreach my $key (keys %{$hash_ref}) {
    # one should not meddle with the id's since it ruins the system
    next if ($key eq 'gid');
    push @parts, "$key = ".$db::dbh->quote($$hash_ref{$key});
  }

  # collect and make sure we update the right table.
  $s .= join (', ', @parts) ." WHERE gid ='$$hash_ref{'gid'}'";

#  print STDERR "\ndb_core::_update_gene::$s\n\n";
  my $sth = $db::dbh->prepare($s);
  $sth->execute  || die $DBI::errstr;;

  # Returns the id if the newly created gene
  return $sth->{mysql_insertid};
}


sub delete {
  my ($gid) = @_;
  
  my $s = "DELETE FROM gene WHERE gid ='$gid'";

#  print STDERR "db_core::_delete_genes::$s\n";

  my $sth = $db::dbh->prepare($s);
  $sth->execute  ||   print STDERR "db_core::_delete_gene::$s\n" && die $DBI::errstr ;

  # Returns the id if the newly created gene
  return undef;
}


# Get all the sequence from all the genes in the database, used for prediction methods.
sub all {

  my $s = "SELECT gene.*, sequence.oid ";
  $s .= ", SUBSTRING(sequence.sequence, (gene.start), (gene.stop-gene.start+1)) AS sequence ";
  $s .= "FROM gene, sequence WHERE gene.sid = sequence.sid";
  
#  print STDERR "db_core::_fetch_genes::$s\n";
  
  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;
  my @_genes;
  while ( my $info = $sth->fetchrow_hashref ) {

    # If intron, remove the intron problem
    if ($info && $$info{intron}) {
      $$info{'sequence'} = intron_free_seq($info);
    }

    # If the gene is on the reverse strand, the DNA gets reversed
    if ($info && $$info{strand} && $$info{'sequence'}) {
      $$info{'sequence'} = &kernel::revDNA($$info{'sequence'});
    }

    push @_genes, $info;
  }
  
  # returns an array of references to hash elements.
  return @_genes;
}


# 
# Find if a gene exists based on stop pos and sid.
# 
# Kim Brugger (23 Feb 2004)
sub sameStopPos {
  my ($sid, $stoppos, $strand) = @_;

  my $s = "SELECT gene.* ";
  $s .= "FROM gene WHERE gene.sid = '$sid' and stop = '$stoppos' AND strand = '$strand'";

#  print STDERR "db_core::_fetch_genes::$s\n";
  
  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;
  
  return $sth->fetchrow_hashref;
}


# 
# Find if a gene exists based on stop pos and sid.
# 
# Kim Brugger (Oct 2008), contact: brugger@bio.ku.dk
sub sameStartPos {
  my ($sid, $start, $strand) = @_;

  my $s = "SELECT gene.* ";
  $s .= "FROM gene WHERE gene.sid = '$sid' and start = '$start' AND strand = '$strand'";

#  print STDERR "db_core::_fetch_genes::$s\n";
  
  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;
  
  return $sth->fetchrow_hashref;
}


BEGIN {

}

END {

}

1;


