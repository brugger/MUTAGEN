#!/usr/bin/perl -w
# 
# Functions used for handling the users and groups for the admin-script.
# 
# 
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;

package page::admin::user_group;
require Exporter;
require AutoLoader;

# set the version for version checking
my $VERSION     = "0.01";

my @ISA = qw(VERSION Exporter AutoLoader);

our @EXPORT = qw();
@ISA = qw(Exporter AutoLoader);
#@EXPORT = qw(user_group_buttons);
@EXPORT = qw();

use vars qw ();


# 
# From here we control everything.
# 
# Kim Brugger (24 Jun 2004)
sub run {

  my $html = &mutagen_html::headline("User and Groups");

  if ($html::parameters{'add_user'}) {
    $html .= &add_user();
  }
  elsif ($html::parameters{'edit_user'}) {
    $html .= &edit_user();
  }
  elsif ($html::parameters{'del_user'}) {
    $html .= &delete_user();
  }
  elsif ($html::parameters{'add_group'}) {
    $html .= &add_group();
  }
  elsif ($html::parameters{'edit_group'}) {
    $html .= &edit_group();
  }
  elsif ($html::parameters{'del_group'}) {
    $html .= &delete_group();
  }
  elsif ($html::parameters{'user2group'}) {
    $html .= &user2group();
  }
  elsif ($html::parameters{'del_userFgroup'}) {
    $html .= &delete_user_from_group();
  }
  else {
    my @cells = ([[
		   &html::generic_form_element({type=>'submit', name=>'add_user', value=>"Add user"}), 
		   &html::generic_form_element({type=>'submit', name=>'add_group', value=>"Add group"}),
		   &html::generic_form_element({type=>'submit', name=>'user2group', 
						value=>"Add an user to a group"})],
		  [
		   &html::generic_form_element({type=>'submit', name=>'edit_user', value=>"Edit user"}), 
		   &html::generic_form_element({type=>'submit', name=>'edit_group', value=>"Edit group"})],
		  [
		   &html::generic_form_element({type=>'submit', name=>'del_user', value=>"Delete user"}), 
		   &html::generic_form_element({type=>'submit', name=>'del_group', value=>"Delete group"}),
		   &html::generic_form_element({type=>'submit', name=>'del_userFgroup', 
						value=>"Remove an user from a group"})]]);
    
    
    $html .= html::start_form('mutagen.pl');
    $html .= html::style::center(html::table(@cells, 1));
    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"user_group"});

    $html .= access::session_form();
    $html .= html::end_form();
  }
   
  return $html;
}



#
# Makes the form for creating an user.
#
sub add_user {
  my $html = html::style::h3("Add user");


  if ($html::parameters{'add_user'} eq "Save user") {

    if (!$html::parameters{'name'} || !$html::parameters{'password'}) {
      $html .= "Some of the information missed, either a name or a password.<BR>";
    }
    else {
      my %call_hash = ();
      
      $call_hash{'name'}     = $html::parameters{'name'};
      $call_hash{'grid'}      = $html::parameters{'grid'}      if ($html::parameters{'grid'});
      $call_hash{'fullname'} = $html::parameters{'fullname'} if ($html::parameters{'fullname'});
      $call_hash{'email'}    = $html::parameters{'email'}    if ($html::parameters{'email'});
      $call_hash{'homepage'} = $html::parameters{'homepage'} if ($html::parameters{'homepage'});
      $call_hash{'password'} = $html::parameters{'password'} if ($html::parameters{'password'});
      
      my $res = db::user::save_user(\%call_hash);
      if ($res) {
	$html .= "Saved user with the name: '$html::parameters{'name'}'";  
      }
      else {
	$html .= "Could not saved user nameed: '$html::parameters{'name'}', ";
	$html .= "check that the user does not already exists";  
      }
    }
  }
  else {

    require mutagen_html::forms;
    
    $html .= html::start_form('mutagen.pl');
    $html .= html::table([["Login name:",&html::generic_form_element({type=>'text', 
								      name=>'name', 
								      value=>$html::parameters{'name'}})],

			  ["Group:",     &mutagen_html::forms::group_popup()],

			  ["Full name:", &html::generic_form_element({type=>'text', 
								      name=>'fullname', 
								      value=>$html::parameters{'fullname'}})],

			  ["E-mail:",    &html::generic_form_element({type=>'text', 
								      name=>'email', 
								      value=>$html::parameters{'email'}})],

			  ["Homepage:",  &html::generic_form_element({type=>'text', 
								      name=>'homepage', 
								      value=>$html::parameters{'homepage'}})],

			  ["Password:",  &html::generic_form_element({type=>'text', 
								      name=>'password', 
								      value=>$html::parameters{'password'}})],

			  [&html::generic_form_element({type=>'reset'}),
			   &html::generic_form_element({type=>'submit', name=>'add_user', 
							value=>'Save user'})]], 1);
    
    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"user_group"});
    
    $html .= access::session_form();
    $html .= html::end_form();
  }
  return $html;
}


#
# 
#
sub edit_user {
  my $html = "";

  if ($html::parameters{'edit_uid'} && $html::parameters{'edit_user'} eq "Save user") {

    if (!$html::parameters{'name'} || !$html::parameters{'password'}) {
      $html .= "Some of the information missed, either a name or a password.<BR>";
    }
    else {
      my %call_hash = ();
      
      $call_hash{'name'}     = $html::parameters{'name'};
      $call_hash{'uid'}      = $html::parameters{'edit_uid'} if ($html::parameters{'edit_uid'});
      $call_hash{'grid'}      = $html::parameters{'grid'}    if ($html::parameters{'grid'});
      $call_hash{'fullname'} = $html::parameters{'fullname'} if ($html::parameters{'fullname'});
      $call_hash{'email'}    = $html::parameters{'email'}    if ($html::parameters{'email'});
      $call_hash{'homepage'} = $html::parameters{'homepage'} if ($html::parameters{'homepage'});
      $call_hash{'password'} = $html::parameters{'password'} if ($html::parameters{'password'});
      
      my $res = db::user::save_user(\%call_hash);
      if ($res) {
	$html .= "Updated information for the user with the name: '$html::parameters{'name'}'";  
      }
      else {
	$html .= "Could not saved user nameed: '$html::parameters{'name'}', ";
	$html .= "check that the user does not already exists";  
      }
    }
  }
  elsif ($html::parameters{'edit_uid'}) {
    my $user = &db::user::fetch_user($html::parameters{'edit_uid'});

    require mutagen_html::forms;

    print STDERR "$user GRID == $$user{grid}\n";
    
    $html .= html::start_form('mutagen.pl');
    $html .= html::table([["Login name:",&html::generic_form_element({type=>'text', 
								      name=>'name', value=>$$user{'name'}})],

			  
			  ["Group:",     &mutagen_html::forms::group_popup($$user{'grid'})],

			  ["Full name:", &html::generic_form_element({type=>'text', 
								      name=>'fullname', 
								      value=>$$user{'fullname'}})],
			  
			  ["E-mail:",    &html::generic_form_element({type=>'text', 
								      name=>'email', 
								      value=>$$user{'email'}})],
			  
			  ["Homepage:",  &html::generic_form_element({type=>'text', 
								      name=>'homepage', 
								      value=>$$user{'homepage'}})],
			  
			  ["Password:",  &html::generic_form_element({type=>'text', 
								      name=>'password', 
								      value=>$$user{'password'}})],
			  
			  [&html::generic_form_element({type=>'reset'}),
			   &html::generic_form_element({type=>'submit', 
							name=>'edit_user', value=>'Save user'})]
			  ], 1);
    
    $html .= &html::generic_form_element({type=>'hidden', name=>'edit_uid', value=>$$user{'uid'}});
    
    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"user_group"});
    $html .= &access::session_form();
    $html .= html::end_form();
    
  }
  else {
    
    require mutagen_html::forms;
    $html .= html::start_form('mutagen.pl');
    $html .= html::table([["Select user:", &mutagen_html::forms::user_popup("edit_uid")],
			     [&html::generic_form_element({type=>'reset'}),
			      &html::generic_form_element({type=>'submit', name=>'edit_user', 
							   value=>'Edit user'})]], 1);
    $html .= &html::generic_form_element({type=>'hidden', name=>'ug_function', value=>"1"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"user_group"});
    
    $html .= &access::session_form();
    $html .= html::end_form();
  }

  return $html;
}


#
# 
#
sub delete_user {
  my $html = "";

  if ($html::parameters{'del_uid'}) {
    &db::user::delete_user($html::parameters{'del_uid'});
    $html .= "Deleted the user with UID: $html::parameters{'del_uid'}<br>";
  }
  else {
    require mutagen_html::forms;
    $html .= html::start_form('mutagen.pl');
    $html .= html::table([["Select user:", &mutagen_html::forms::user_popup("del_uid")],
			     [&html::generic_form_element({type=>'reset'}),
			      &html::generic_form_element({type=>'submit', 
							   name=>'del_user', 
							   value=>'Delete user'})]], 1);

    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"user_group"});
    $html .= &access::session_form();
    $html .= html::end_form();
  }

  return $html;
}


#
# 
#
sub add_group {
  my $html =  "";

  if ($html::parameters{'groupname'}) {
    if (&db::user::save_group($html::parameters{'groupname'})) {
      $html .= "Saved group with the name: '$html::parameters{'groupname'}'";  
    }
    else {
      $html .= "Could not saved group nameed: '$html::parameters{'groupname'}', ";
      $html .= "check that the group does not already exists";  
    }
  }
  else {
    $html .= html::style::h3("Add group");
    
    $html .= html::start_form('mutagen.pl');
    $html .= html::table([["Group name:",&html::generic_form_element({type=>'text', 
								    name=>'groupname', 
								      value=>""})],
			  
			  [&html::generic_form_element({type=>'reset'}),
			   &html::generic_form_element({type=>'submit', 
							name=>'add_group', 
							value=>'Save group'})]], 1);
    
    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"user_group"});
    $html .= &access::session_form();
    $html .= html::end_form();
  }

  return $html;
}


#
# 
#
sub delete_group {
  my $html = "";

  if (!$html::parameters{'grid'}) {
    $html .= html::style::h3("Select group to delete");

    require mutagen_html::forms;
    $html .= html::start_form('mutagen.pl');
    $html .= html::table([["Select group:", &mutagen_html::forms::group_popup()],
			     [&html::generic_form_element({type=>'reset'}),
			      &html::generic_form_element({type=>'submit', name=>'del_group', value=>'Delete group'})]], 1);
    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"user_group"});
    $html .= &access::session_form();
    $html .= html::end_form();
  }
  else {
    &db::user::delete_group($html::parameters{'grid'});
    $html .= "Deleted the group<br>";
  }
  return $html;
}


#
# 
#
sub edit_group {
  my $html = "";



  if ($html::parameters{'grid'} && $html::parameters{'edit_group'} eq "Save group") {
    my %call_hash;
    $call_hash{'grid'} = $html::parameters{'grid'};
    $call_hash{'name'} = $html::parameters{'groupname'} if ($html::parameters{'groupname'});
    $call_hash{'uids'} = $html::parameters{'uids'}      if ($html::parameters{'uids'});
    &db::user::update_group(\%call_hash);
    $html .= "Updated group with the name: '$html::parameters{'groupname'}'";  
  }
  elsif ($html::parameters{'grid'}) {

    my $group = &db::user::fetch_group($html::parameters{'grid'});
    $html .= html::start_form('mutagen.pl');
    $html .= html::table([["Group name:",&html::generic_form_element({type=>'text', name=>'groupname', value=>$$group{'name'}})],
			     [&html::generic_form_element({type=>'reset'}),
			      &html::generic_form_element({type=>'submit', name=>'edit_group', value=>'Save group'})]], 1);
    
    $html .= &html::generic_form_element({type=>'hidden', name=>'grid', value=>$$group{'grid'}});
    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"user_group"});
    $html .= &access::session_form();
    $html .= html::end_form();
  }
  else {
    require mutagen_html::forms;

    $html .= html::style::h3("Edit group");
    $html .= html::start_form('mutagen.pl');
    $html .= html::table([["Select group:", &mutagen_html::forms::group_popup()],
			     [&html::generic_form_element({type=>'reset'}),
			      &html::generic_form_element({type=>'submit', name=>'edit_group', value=>'Edit group'})]], 1);
    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"user_group"});
    $html .= &access::session_form();
    $html .= html::end_form();
  }
  return $html;
}


#
# 
#
sub user2group {
  my $html = "";

  require mutagen_html::forms;

  if (!$html::parameters{'grid'} || !$html::parameters{'add_uid'}) {
    $html .= html::start_form('mutagen.pl');
    $html .= html::table([["User name:", &mutagen_html::forms::user_popup("add_uid")],
			     ["Group name:",&mutagen_html::forms::group_popup()],
			     [&html::generic_form_element({type=>'reset'}),
			      &html::generic_form_element({type=>'submit', 
							   name=>'user2group', 
							   value=>'Add user to group'})]], 1);

    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"user_group"});
    $html .= &access::session_form();
    $html .= html::end_form();
  }
  else {

    require access;
    print STDERR "$html::parameters{'grid'}, $html::parameters{'add_uid'}\n";
    if (access::check_uid($html::parameters{'grid'}, $html::parameters{'add_uid'})) {
      $html .= "The user are already member of the group\n";
      return $html;
    }

    my $group = &db::user::fetch_group($html::parameters{'grid'});

    my %call_hash = ();
    $call_hash{'grid'} = $html::parameters{'grid'};
    $call_hash{'uids'} = &access::id_pack(&access::id_pack(&access::id_unpack($$group{'uids'}),
							    $html::parameters{'add_uid'}));

    &db::user::update_group(\%call_hash);
    $html .= "Added an user to the group named: '$$group{'name'}'<BR>";
  }

  return $html;
}	 

		  
#
# 
#
sub delete_user_from_group {
  my $html = "";

  if ($html::parameters{'grid'} && !$html::parameters{'del_uid'}) {
    my $group = &db::user::fetch_group($html::parameters{'grid'});

    require mutagen_html::forms;
    $html .= html::start_form('mutagen.pl');

    my @uids = split(":", $$group{'uids'});

    $html .= html::table([["Select an user:",&mutagen_html::forms::uids_popup(\@uids, "del_uid")],
			     [&html::generic_form_element({type=>'reset'}),
			      &html::generic_form_element({type=>'submit', 
							   name=>'del_userFgroup', 
							   value=>'Select user to remove'})]], 1);

    $html .= &html::generic_form_element({type=>'hidden', name=>'grid', value=>$html::parameters{'grid'}});
    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"user_group"});
    $html .= &access::session_form();
    $html .= html::end_form();
  }
  elsif ($html::parameters{'grid'} && $html::parameters{'del_uid'}) {
    my $group = &db::user::fetch_group($html::parameters{'grid'});


    my @uids;
    # Check to se if the uid are already found in the group
    if ($$group{uids} =~ /:/) {
      foreach my $uid (split (":", $$group{uids})) {
	if ($uid != $html::parameters{'del_uid'}) {
	  push @uids, $uid;
	}
      }
    }
    else {
      if ($$group{uids} != $html::parameters{'del_uid'}) {
	push @uids, $$group{uids};
      }
    }

    my %call_hash = ();
    $call_hash{'grid'} = $html::parameters{'grid'};
    $call_hash{'uids'} = join(":", @uids);
    
    &db::user::update_group(\%call_hash);
    $html .= "Removed a user from the group named: '$$group{'name'}'<BR>";
  }
  else {
    require mutagen_html::forms;
    $html .= html::start_form('mutagen.pl');
    $html .= html::table([["Select group:",&mutagen_html::forms::group_popup()],
			     [&html::generic_form_element({type=>'reset'}),
			      &html::generic_form_element({type=>'submit', 
							   name=>'del_userFgroup', 
							   value=>'Select group'})]], 1);

    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"user_group"});
    $html .= &access::session_form();
    $html .= html::end_form();
  }
  return $html;
}


#
#
#
sub user_group {

  if ($html::parameters{'ug_function'}) {
    if ($html::parameters{'ug_function'} ne "1") {
      if ($html::parameters{'ug_function'} eq "Add user") {
#	return make_user();
      }
      elsif ($html::parameters{'ug_function'} eq "Edit user") {
	return edit_user();
      }
      elsif ($html::parameters{'ug_function'} eq "Delete user") {
	return delete_user();
      }
      elsif ($html::parameters{'ug_function'} eq "Add group") {
	return make_group();
      }
      elsif ($html::parameters{'ug_function'} eq "Edit group") {
	return edit_group();
      }
      elsif ($html::parameters{'ug_function'} eq "Delete group") {
	return delete_group();
      }
      elsif ($html::parameters{'ug_function'} eq "Add an user to a group") {
	return add_user2group();
      }
      elsif ($html::parameters{'ug_function'} eq "Remove an user from a group") {
	return remove_user_from_group();
      }
    }
    elsif ($html::parameters{'save_user'}) {
      return save_user();
    }
    elsif ($html::parameters{'edit_user'}) {
      return edit_user();
    }
    elsif ($html::parameters{'delete_user'}) {
      return delete_user();
    }
    elsif ($html::parameters{'save_group'}) {
      return save_group();
    }
    elsif ($html::parameters{'edit_group'}) {
      return edit_group();
    }
    elsif ($html::parameters{'delete_group'}) {
      return delete_group();
    }
    elsif ($html::parameters{'add_user2group'}) {
      return add_user2group();
    }
    elsif ($html::parameters{'remove_user_from_group'}) {
      return remove_user_from_group();
    }
  }

};

BEGIN { 

};

END { 

};

1;

