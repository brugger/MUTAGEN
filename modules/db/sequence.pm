#!/usr/bin/perl -wT
# 
# Handles the sequence data in the database ...
# 
# 
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;

use db;

package db::sequence;
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

# returns information about a sequence
sub fetch {
  my ($sid) = @_;
  
  my $s = "SELECT *, LENGTH(sequence) as length  ";
  $s .= "FROM sequence WHERE sid = '$sid'";

#  print STDERR "db_core::_fetch_sequence::$s\n";
  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;
  
  my $info = $sth->fetchrow_hashref;
  return $info;
}

# Fetches all sequences that belongs to a singel organism. If no aid
# is given, the latest is used.
# if vid == -1 all the sequence from the organisms are returned
sub fetch_organism {
  my ($oid, $vid) = @_;

  my $s;
  if ($vid && $vid == -1) {

    $s = "SELECT sequence.*, length(sequence.sequence) FROM sequence WHERE oid = '$oid'";

  }
  else {

    # if no vid, we find one the fits with the organism.
    if (!$vid) {
      require db::version;
      my $vid_ref = db::version::latest($oid);
      $vid = $$vid_ref{'vid'};
    }

    $s = "SELECT sequence.*, length(sequence.sequence) as length FROM sequence, organism"; 
    $s .= " WHERE organism.oid = '$oid' ";
    $s .= " AND sequence.vid = '$vid'";
    $s .= " AND organism.oid = sequence.oid";
  }

#  print STDERR "db_core::_fetch_sequences::$s\n";
  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;

  my @res;

  while (  my $info = $sth->fetchrow_hashref) {
    push @res, $info;
  }

  #return an array of hash references.
  return (@res);
}



# 
# 
# 
# Kim Brugger (05 Jul 2005)
sub update {
  my ($hash_ref) = @_;
  
  my $s = "UPDATE sequence SET ";

  my @parts;
  # Build the rest of the sql here ...
  foreach my $key (keys %{$hash_ref}) {
    # one should not meddle with the id's since it ruins the system
    next if ($key eq 'sid');
    push @parts, "$key = ".$db::dbh->quote($$hash_ref{$key});
  }

  # collect and make sure we update the right table.
  $s .= join (', ', @parts) ." WHERE sid ='$$hash_ref{'sid'}'";

#  print STDERR "\ndb_core::_update_gene::$s\n\n";
  my $sth = $db::dbh->prepare($s);
  $sth->execute  || die $DBI::errstr;;

  # Returns the id if the newly created gene
  return $sth->{mysql_insertid};

}


# 
# Fetches all the sids and names, oids and vids from the database.
# 
# Kim Brugger (29 Feb 2004)
sub all {

  my $s = "SELECT sid, name, vid, oid FROM sequence";

#  print STDERR "db_core::_delete_sequence::$s\n";

  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;

  my @res;
  while (my $info = $sth->fetchrow_hashref) {
    push @res, $info;
  }

  return @res;
}


sub delete {
  my ($sid) = @_;
  
  my $s = "DELETE FROM sequence WHERE sid = '$sid'";

#  print STDERR "db_core::_delete_sequence::$s\n";

  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;
  
  return undef;
}


sub fetch_ids {
  my $s = "select name, sid from sequence";

#  print STDERR "db_core::_fetch_sequence_ids::$s\n";
  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;

  my @res;

  while (  my $info = $sth->fetchrow_hashref) {
    push @res, $info;
  }

  #return an array of hash references.
  return (@res);
}

# where origin is genbank, manual or something else. If vid is undef, the latest assembly version is used instead.
sub save {
  my ($oid, $vid, $sequence_name, $sequence) = @_;

  # if no vid, we find one the fits with the organism.
  if (!$vid) {
    my $vid_ref = &db::version::latest($oid);
    $vid = $$vid_ref{'vid'};
  }


  # Here we do not save the sequence, but all the rest of the information.
  my $s = "INSERT INTO sequence (oid, vid, name, sequence)".
      " VALUES ('$oid', '$vid', '$sequence_name', '')\n";

#  print STDERR "db_core::_save_sequence::$s\n";
  my $sth = $db::dbh->prepare($s);
  $sth->execute  || die $DBI::errstr;;

  my $sid =  $sth->{mysql_insertid};  

  # save the information in small pieces, one fragment at the time.
  my $step = 100000;
  for (my $i=0; $i<length($sequence);$i += $step) {

    my $sub_seq = substr($sequence, $i, $step);
    
    $s = "UPDATE sequence SET sequence = CONCAT(sequence, '$sub_seq') ".
	" WHERE sid = '$sid'";

    $sth = $db::dbh->prepare($s);
    $sth->execute  || die $DBI::errstr;;

  }


  # returns the sid created.
  return $sid;
}

# If stop == undef the sequence from start to end is found instead.
sub sub_sequence {
  my ($sid, $start, $length) = @_;
 
  my $s = "SELECT sequence.sid as sid, sequence.name as sequence_name, ";
  $start++;

  # if both the start and the length is given
  if ($start && $length) {
    $s .= "SUBSTRING(sequence.sequence, $start, $length) AS sequence ";
  }
  elsif ($start) {
    # If no length, just to the end of the string
    $s .= "SUBSTRING(sequence.sequence, $start) AS sequence ";
  } 
  elsif ($length) {
  # Hack so sequence is extraced from then length to the end  of the sequence
    $s .= "SUBSTRING(sequence.sequence, $length) AS sequence ";
  }

  $s .= "FROM sequence WHERE  ";
  $s .= "sid = '$sid' ";

#  print STDERR "db_core::_fetch_sub_sequence::$s\n";
  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;
  
  my $info = $sth->fetchrow_hashref;

  return $info;
}

#
# locates a sub string in the sequence, this only finds the first occurence,
# and only perfect copies, to be SURE that the string is unique.
# 
sub locate_substr {
  my ($sid, $subseq) = @_;

  $subseq =~ tr/[acgt]/[ACGT]/;

  my $s = "SELECT LOCATE('$subseq',  sequence) as position from sequence where sid ='$sid'";

  print STDERR "$s\n";
  
  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;
  
  my $info = $sth->fetchrow_hashref;

  return $$info{position};
}

#
# substitues a sub string in the sequence
# 
sub substitute_substr {
  my ($sid, $oldstring, $newstring) = @_;

  $newstring =~ tr/[acgt]/[ACGT]/;
  $oldstring =~ tr/[acgt]/[ACGT]/;

#  my $s = "SELECT LOCATE('$subseq',  sequence) as position from sequence where sid ='$sid'";
  my $s = "UPDATE sequence SET sequence = REPLACE(sequence, '$oldstring', '$newstring') WHERE sid = '$sid'";
  
  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;
  
  return locate_substr($sid, $newstring);
}


BEGIN {

}

END {

}

1;


