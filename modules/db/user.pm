#!/usr/bin/perl -wT
# 
# The functions used for handling the user/group/login information.
# 
# 
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;
use Digest::MD5;

use db;

package db::user;
require Exporter;
require AutoLoader;

# set the version for version checking
my $VERSION     = "0.01";

my @ISA = qw(VERSION Exporter AutoLoader);

our @EXPORT = qw();
@ISA = qw(Exporter AutoLoader);

use vars qw ();

#
# Fetch the user information
#
sub fetch_user {
  my ($uid) = @_;

#  my $s = "SELECT id, name, password FROM user WHERE id = '$uid' OR name = '$uid'";
  my $s = "SELECT * FROM user WHERE uid = '$uid' OR name = '$uid'";

# &core::LOG("db_login::_fetch_user::$s");
  my $sth = $db::dbh->prepare($s);
  $sth->execute || &core::LOG($DBI::errstr);
  return ($sth->fetchrow_hashref);
}

#
# Save the user information, if a uid has been included or that the name is not unique
# the function returns a 0, and does not try to save the information.
#
sub save_user {
  my ($hash_ref) = @_;

  if (fetch_user($$hash_ref{'uid'}) ||
      fetch_user($$hash_ref{'name'})) {
    return (update_user($hash_ref));
  }

#  return 0 if ($$old_user{uid});
	       
  my $s = "INSERT INTO user SET ";

  my @parts;

  # Build the rest of the sql here ...
  foreach my $key (keys %$hash_ref) {
    # one should not meddle with the id's since it ruins the system
    next if ($key eq 'uid');
    push @parts, "$key = ".$db::dbh->quote($$hash_ref{$key});
  }
  # collect everything ...
  $s .= join (', ', @parts);

#  print STDERR "db_login::_save_user::$s\n";

  my $sth = $db::dbh->prepare($s);
  $sth->execute  || &core::LOG($DBI::errstr) && &core::LOG("db_login::_save_user::$s\n");

  # Returns the id if the newly created gene
  return $sth->{mysql_insertid};
}

#
# Fetch all the users, being use in the handling of users and groups
#
sub fetch_users {

  my $s = "SELECT * FROM user\n";
#  print STDERR "db_login::_fetch_users::$s";
  my $sth = $db::dbh->prepare($s);
  $sth->execute  || die $DBI::errstr;
  my @_res;
  while (my $info = $sth->fetchrow_hashref) {
    push @_res, $info;
  }

  return @_res;
}


#
# Updates the user from the database.
#
sub update_user {
  my ($hash_ref) = @_;

  my $s = "UPDATE user SET ";

  my @parts;
  # Build the rest of the sql here ...
  foreach my $key (keys %{$hash_ref}) {
    # one should not meddle with the id's since it ruins the system
    next if ($key eq 'uid');
    push @parts, "$key = ".$db::dbh->quote($$hash_ref{$key});
  }

  # collect and make sure we update the right table.
  $s .= join (', ', @parts) ." WHERE uid ='$$hash_ref{'uid'}'";

#    print STDERR Dumper($call_hash);
  
#  print STDERR "db_login::_update_user::$s\n\n";
  my $sth = $db::dbh->prepare($s);
  $sth->execute  || die $DBI::errstr;;

  # Returns the id if the newly created gene
  return return $$hash_ref{'uid'};
}

#
# Deletes the user from the database.
#
sub delete_user {
  my ($uid) = @_;

  my $s = "DELETE FROM user WHERE uid = '$uid'\n";
#  print STDERR "db_login::_delete_user::$s;
  $db::dbh->do($s);
  return undef;
}

#
# logs the user, this is used for statistics and tracing.
#
sub log_user {
  my ($uid) = @_;

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) = gmtime(time);
  my $now = ($year + 1900).sprintf("%02d%02d%02d%02d%02d",
				   ($mon+1),($mday),($hour+1),($min),($sec+1));

#  my $s = "INSERT INTO log (user) values ('$username')\n";
  my $s = "UPDATE user SET lasttime = '$now' WHERE uid = '$uid'\n";
#  print STDERR "db_login::_log_user::$s";
  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;
  return undef;
}  

#
# Log the user out of the system, so next time one does not have to check the password,
#
sub log_in {
  my ($uid) = @_;

  my $s = "UPDATE user SET login = '1' WHERE uid= '$uid'\n";
#  print STDERR "db_login::_log_in::$s;
  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;
}

#
# returns a list of group id that a user belongs to.
#
sub groups {
  my ($uid) = @_;
  
  return undef if (!$uid);

  my $s = "SELECT groups.grid, groups.name FROM groups WHERE ";
  $s .= "(uids = '$uid' ";
  $s .= "OR uids like '$uid,%' OR uids like '%:$uid' ";
  $s .= "OR uids like '%:$uid:')\n";

#  print STDERR "db_login::groups::$s\n";
  my $sth = $db::dbh->prepare($s);
  $sth->execute  || die $DBI::errstr;
  my @_res;

  while (my $info = $sth->fetchrow_hashref) {
    push @_res, $info;
  }

  $s = "SELECT g.grid, g.name from groups g, user u where uid = '$uid' AND u.grid = g.grid";

#  print STDERR "db_login::groups::$s\n";

  $sth = $db::dbh->prepare($s);
  $sth->execute  || die $DBI::errstr;

  if (my $info = $sth->fetchrow_hashref){ 
    push @_res, $info;
  } 

  return @_res;

  # return a list of group id's
}

#
# Fetches the goup information (currently only name)
#
sub fetch_group {
  my ($group_id) = @_;

  my $s = "SELECT * FROM groups WHERE grid = '$group_id' OR name = '$group_id'\n";
  my $sth = $db::dbh->prepare($s);
  $sth->execute  || die $DBI::errstr;
  return $sth->fetchrow_hashref;
}

#
# Fetches all the groups, as an array of hash references.
#
sub fetch_groups {

  my $s = "SELECT groups.* FROM groups\n";
  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;
  my @_res;
  while (my $info = $sth->fetchrow_hashref) {
    push @_res, $info;
  }
  
  return @_res;
}

#
# Save group information.
#
sub save_group {
  my ($group_name) = @_;

  return 0 if (db::user::fetch_group($group_name));

  my $s = "INSERT INTO groups (name) VALUES ('$group_name')\n";
  my $sth = $db::dbh->prepare($s);
  $sth->execute  || die $DBI::errstr;;

  return $sth->{mysql_insertid};
}

#
# save group information.
#
sub update_group {
  my ($hash_ref) = @_;

  my $s = "UPDATE groups SET ";

  my @parts;
  # Build the rest of the sql here ...
  foreach my $key (keys %{$hash_ref}) {
    # one should not meddle with the id's since it ruins the system
    next if ($key eq 'uid');
    push @parts, "$key = ".$db::dbh->quote($$hash_ref{$key});
  }

  # collect and make sure we update the right table.
  $s .= join (', ', @parts) ." WHERE grid ='$$hash_ref{'grid'}'";

#  print STDERR "db_login::_update_group::$s\n\n";
  my $sth = $db::dbh->prepare($s);
  $sth->execute  || die $DBI::errstr;;

  # Returns the id if the newly created gene
  return return $$hash_ref{'uid'};
}

# deletes a group
sub delete_group {
  my ($grid) = @_;

  my $s = "DELETE FROM groups WHERE grid = '$grid'\n";
#  print STDERR $s;
  $db::dbh->do($s);
  return undef;
}

# fetches all memberships in groups for users.
sub fetch_user_group_links {

  my $s = "SELECT * FROM user_group\n";
  my $sth = $db::dbh->prepare($s);
  $sth->execute  || die $DBI::errstr;

  my @_res;
  while (my $info = $sth->fetchrow_hashref) {
    push @_res, $info;
  }

  return @_res;
}


1;
