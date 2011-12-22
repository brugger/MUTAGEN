#!/usr/bin/perl -wT
# 
# Functions for handling sessions, and functions related to the sessions.
# 
# 
# Kim Brugger (Oct 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;
use Digest::MD5;

package db::session;
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
# Creates a new session id (seid), and places it in the database.  The
# function returns the created session id, that is a md5 based
# calculation.
#
sub new {
  my ($uid, $hostname) = @_;

  my $offset = $conf::gracetime;
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) = gmtime(time + $offset*60);
  # the database does not understand the hour 24, so just write hour == 0 and add a day.
  if ($hour == 23) {
    $mday++; $hour = 0;
  }
  my $time = ($year + 1900).sprintf("%02d%02d%02d%02d%02d",
				       ($mon+1),($mday),($hour+1),($min),($sec));

  my $md5_ground = "$$\-$uid\-$hostname\-$time";

  my $md5 = &Digest::MD5::md5_hex($md5_ground);
  $md5 =~ s/\ .*//;
  chomp $md5;
  
  my $s  = "insert into session (seid, uid, hostname, gracetime) VALUES ";
  $s .= "('$md5', '$uid', '$hostname', '$time')";

  $db::dbh->do($s) || die $DBI::errstr;;

  return $md5;
}

sub fetch {
  my ($session_id) = @_;

  my $s = "select * from session, user where seid = '$session_id' AND user.uid = session.uid";

  my $sth = $db::dbh->prepare($s);
  $sth->execute || die $DBI::errstr;

  my $info = $sth->fetchrow_hashref;
  return $info;
}

#
# Updates the automatic logout time, this is updated 
#
sub extend_gracetime {
  my ($uid, $session) = @_;
  my $offset = $conf::gracetime;

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) = gmtime(time + $offset*180);

  # the database does not understand the hour 24, so just write hour == 0 and add a day.
  if ($hour == 23) {
    $mday++;
    $hour = 0;
  }

  my $time = ($year + 1900).sprintf("%02d%02d%02d%02d%02d",
				       ($mon+1),($mday),($hour+1),($min),($sec));

  my $s = "UPDATE session SET gracetime = '$time' WHERE seid = '$session'";
  

  $db::dbh->do($s) || die $DBI::errstr;;

}

#
# Log the user out of the system, so next time one have to check the password,
#
sub log_out {
  my ($uid, $session) = @_;

  if (0) {
    my $s = "UPDATE user SET login = '0' WHERE uid = '$uid'\n";
    my $sth = $db::dbh->prepare($s);
    $sth->execute || die $DBI::errstr;
  }

  if ($session) {
#    my $s = "delete from  session where ses = '$ses'\n";
    my $s = "UPDATE session SET active = '0' WHERE session = '$session'\n";
    my $sth = $db::dbh->prepare($s);
    $sth->execute || die $DBI::errstr;
  }
}

#
#
#
sub session2user {
  my ($session_id) = @_;

  my $session = _fetch_session($session_id);

#  print STDERR Dumper($session);

  return $$session{name};
}

BEGIN {

};

END {

}

1;
