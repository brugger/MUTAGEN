#!/usr/bin/perl -wT
# 
# Handles the login/logout/session thing.
# and group access.
# 
# Kim Brugger (Dec 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;

use Net::hostent;
use Socket;

use db::session;

package access;
require Exporter;
require AutoLoader;

# set the version for version checking
my $VERSION     = "0.01";

my @ISA = qw(VERSION Exporter AutoLoader);

our @EXPORT = qw();
@ISA = qw(Exporter AutoLoader);
@EXPORT = qw();

#exported variables.
use vars qw ($profile);


# 
# The main function of this program that call all the other sub rutines for this page.
# 
# Kim Brugger (03 Dec 2003)
sub run  {
  
  my $html = "";
  $html .= &html::style::center(html::style::h1("Login page to MUTAGEN"));
  $html .= &html::style::hr("70%");
  $html .= &html::style::break();

  $html::parameters{'session'} =~ tr/[A-Z]/[a-z]/;

  if ($html::parameters{'session'} && $html::parameters{'session'} eq "login") {
    if (!&login(0)) {
      $html .= make_login_page();
    }
  }
  elsif ($html::parameters{'session'} && $html::parameters{'session'} =~ /^logout/) {
    &logout(); 
 }
  else {
    $html = "<h2>You have been successfully logged in (?).</h2>";
  }

  return ($html, 1);
}


#
# Makes a login page, where the user can enter username and password.
# 
# Kim Brugger (Dec 2003), contact: brugger@mermaid.molbio.ku.dk
sub make_login_page {
  

  my $html .= html::start_form('mutagen.pl');
  $html .= html::style::center(
			     html::table([["Login name:",
					   &html::generic_form_element({type=>'text', name=>'name',     
									value=> $html::parameters{'name'}})],
					  ["Password:",  &html::generic_form_element({type=>'password', name=>'password', 
										      value=> ""})],
					  [&html::generic_form_element({type=>'reset'}),
					   &html::generic_form_element({type=>'submit', name=>'session', value=>'login'})]], 1));
  
  if (1) {
    my $skip = "name password";
    foreach my $key (keys %html::parameters) {
      next if ($key eq "session" && $html::parameters{$key} eq "login");

      $html .= &html::generic_form_element({type=>'hidden', name=>$key, value=>$html::parameters{$key}})
	  if ($skip !~ /$key/);
    }
  }

  $html .= html::end_form();
}


#
# Logs in the user, if silent this function is silent, might not be usefull in this new and improved design.
#
sub login {
  my ($silent) = @_;
  
  my ($session, $gracetime) = (undef, undef);

  # what host s/he originates from, translated into their IP number
  # so there are no cheating here.
  my $remote_host = $html::remote_host;
  my $host_info = &Net::hostent::gethost($remote_host);
  $remote_host = &Socket::inet_ntoa($host_info->addr) if ( $host_info);

  # we have a login situation ...
  if ($html::parameters{'session'} && $html::parameters{'session'} eq "login" && 
      $html::parameters{'name'} && $html::parameters{'password'}) {

    my $user_info = &db::user::fetch_user($html::parameters{'name'});
    my ($uid, $dname, $dpass) = ($$user_info{uid}, $$user_info{name}, $$user_info{password});
    
    # general checking for user parameters to check if we should let them in.
    # Does the user exists in the database ?
    # Check if the password is correct, otherwise make a new login screen
    goto LOGIN if (!$dpass || $html::parameters{'password'} ne $dpass);

    # since this is a new session, create a unique id for it if thers
    # is no session running, otherwise reinvoke the old session, and
    # continue.

    if ($html::parameters{'seid'}) {
      &db::session::extend_gracetime($uid, $html::parameters{'seid'});
    }
    else {
      $session = &db::session::new($uid, $remote_host);
      $html::parameters{'seid'} = "$session";
    }
  }

  if ($html::parameters{'seid'}) {  
    
    $session = $html::parameters{'seid'};
    my $session_info = &db::session::fetch($session);

    goto LOGIN if (not defined $session_info ||  !$$session_info{active});
   
    # Fetch the user information
    my ($uid, $dname, $dpass) = ($$session_info{uid}, $$session_info{name}, $$session_info{password});
 
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) = gmtime(time);
    my $now = ($year + 1900).sprintf("%02d%02d%02d%02d%02d",
				     ($mon+1),($mday),($hour+1),($min),($sec+1));

    # Remove the delimiters from the datatime 
    $$session_info{gracetime} =~ s/[-:\ ]//g;
    # check to see if the session is constant with the remote host and the grace time looks ok.
    if ($remote_host ne $$session_info{hostname} ||
	$$session_info{gracetime} < $now) {
      &core::LOG("no good grace or bad host name ($remote_host ne $$session_info{hostname}) ($$session_info{gracetime} < $now)\n");
      goto LOGIN;
    }

    # Add the new values to the CGI we use ...
    $html::parameters{'username'} = $$session_info{name};
    $html::parameters{'uid'} = $$session_info{uid};

    &db::session::extend_gracetime($uid, $session);
    
#    &db::user::log_user($uid);

    return 1;
  }
  
 LOGIN:
  
  
  return 0;
}


sub logout {
  my  $seid = $html::parameters{'seid'};
 

  my $html = "There is no such session active";
}

#
# Checks if there is a seid, and returns a module to a link
#
sub session_link {
  return "&seid=$html::parameters{'seid'}" if ($html::parameters{'seid'});
  return "";
}

#
# Checks if there is a seid, and returns hidden input element to a form
#
sub session_form {
  return &html::generic_form_element({type=>'hidden', name=>'seid', value=>$html::parameters{'seid'}})
      if ($html::parameters{'seid'});
  return "";
}


# 
# 
# 
# Kim Brugger (01 Jun 2004)
sub no_access {

  return "<H2>NO ACCESS TO THIS PAGE</H2> If you truly feels you should have access to this page please contact your administrator and describe how you got to this page.";
  
}


# 
# Check and see if the user have access to the information (s)he is asking for.
#
# In this case the function returns _0_ if the user is OK!!!!
#
# Kim Brugger (01 Jun 2004)
sub check_access {
  my ($gid, $sid, $oid, $fid) = @_;

  # turns off the sequence check code.
  return 0 if ($conf::limit);

  require db::organism;

  my $res = 0;

  if ($fid) {
    require db::genefinder;
    require db::organism;

    my $genefinder = &db::genefinder::fetch($fid);
    my $organism = &db::sequence::fetch($$genefinder{'oid'});

    $res = &check_uid($html::parameters{uid}, $$organism{grids});
  }
  elsif ($gid) {
    require db::gene;
    require db::sequence;
    require db::organism;

    my $gene = &db::gene::fetch($gid);
    my $sequence = &db::sequence::fetch($$gene{'sid'});
    my $organism = &db::sequence::fetch($$sequence{'oid'});

    $res = &check_uid($html::parameters{uid}, $$organism{grids});
  }
  elsif ($sid) {
    require db::sequence;
    require db::organism;

    my $sequence = &db::sequence::fetch($sid);
    my $organism = &db::sequence::fetch($$sequence{'oid'});

    $res = &check_uid($html::parameters{uid}, $$organism{grids});
  }
  elsif ($oid) {
    require db::organism;

    my $organism = &db::organism::fetch($oid);

    $res = &check_uid($html::parameters{uid}, $$organism{grids});
  }

  return !$res;
}



# 
# Checks and see if an uid is member of one of the group (name)
# Returns 1 for success.
# Kim Brugger (01 Jun 2004)
sub uid_group {
  my ($uid, $group) = @_;

#  print STDERR "uid: $uid GROUP: $group\n";

  return 1 if (! $group || $group eq "");
  return 0 if (! $uid || $uid eq "");

#  print STDERR "'$uid' '$group'\n";

  require db::user;
  my @groups = &db::user::groups($uid);
#  &core::Dump(@groups);
  foreach my $mgroup (@groups) {
#    print STDERR "$$mgroup{name} ===> $group\n";
    return 1 if ($$mgroup{name} eq $group);
  }

  return 0;
}


# 
# Checks and see if an uid is member of one of the groups (array) 
# Returns 1 for success.
# Kim Brugger (01 Jun 2004)
sub check_uid {
  my ($uid, $groups) = @_;

  return 0 if (! $uid);
  return 1 if (! defined $groups || $groups eq "");

  require db::user;
  my @ugroups = &db::user::groups($uid);
  
  
  for (my $i=0;$i<@ugroups;$i++) {
    $ugroups[$i] = ${$ugroups[$i]}{grid};
  }
  
  return &check_grids(\@ugroups, $groups);
}


# 
# Reports if a grid is in a list of grids
# Return 1 if the grid is in the grids.
# 
# Kim Brugger (28 May 2004)
sub check_grids {
  my ($grids1, $grids2) = @_;

  return 1 if (!defined $grids2 || $grids2 eq "");

  # if grids1 is not an array, lets make it one..
  $grids1 = [$grids1] if (not ref $grids1 eq "ARRAY");
  

  my @grids2 = id_unpack($grids2);# || [$grids];
  @grids2 = [$grids2] if (!@grids2);


  for (my $i=0; $i< @$grids1; $i++) {
    for (my $j=0; $j< @grids2; $j++) {
      return 1 if $$grids1[$i] == $grids2[$j];
    }
  }
  
  return 0;
}

# 
# Removes a grid from a list of grids.
# 
# Kim Brugger (28 May 2004)
sub remove {
  my ($grid, $grids) = @_;

  return "" if (!defined $grids);

#  print STDERR "'$grids'\n";
  my @grids = &id_unpack($grids);
  @grids = [$grids] if (!@grids);

  for (my $i=0; $i< @grids; $i++) {
    delete $grids[$i] if $grid == $grids[$i];
  }


  return id_pack(@grids);
}


# 
# pack ids to a string
# 
# Kim Brugger (28 May 2004)
sub id_pack {
  my (@ids) = @_;

  return join(":",sort @ids);
}


# 
# unpack ids to a string
# 
# Kim Brugger (28 May 2004)
sub id_unpack {
  my ($ids) = @_;

  return undef if (!$ids);
  
  my @ids = split(":",$ids);
  return @ids;
}


BEGIN {

}

END {

}

1;


