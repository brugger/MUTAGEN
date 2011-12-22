#!/usr/bin/perl -wT
# 
# 
# 
# 
# Kim Brugger (Dec 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;

package mutagen_html::forms;
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
# A popmenu with all the gene types sorted by the array_pos
# 
# Kim Brugger (30 Jun 2005)
sub genetypes_popup {
  my ($gid) = @_;

  my $default;

  if ($gid) {
    require db::gene;
    my $gene = &db::gene::fetch($gid);
    $default = $$gene{type};
  }
  $default = "Other" if (!$default);

  my @types;
  foreach my $key (sort {$global::gene_types{$a}{array_pos} <=> $global::gene_types{$b}{array_pos}} 
		    keys %global::gene_types) {
    push @types,  $key;
  }

  return &html::generic_form_element({type=>"popup", 
				      name=>"gene_type", 
				      values=>\@types,
				      defaults=>[$default]})  
}


#
# Generates a popup-meny based on the sids.
#
sub sequence_popup {

  my @sequences = db::sequence::all();
  my %labels = ();

  for (my $i=0; $i < @sequences; $i++) {

    
    $labels{$sequences[$i]{sid}} = $sequences[$i]{name};
    $sequences[$i] = $sequences[$i]{sid};
  }

  return html::generic_form_element({type=>'popup', name=>'sid', values=>\@sequences, labels=>\%labels});
}

#
# Generates a popup-meny based on the sids.
#
sub organism_popup {

  my @organisms = &db::organism::all();
  my %labels = ();

  for (my $i=0; $i < @organisms; $i++) {

    
    $labels{$organisms[$i]{oid}} = $organisms[$i]{name};
    $organisms[$i] = $organisms[$i]{oid};
  }

  return html::generic_form_element({type=>'popup', name=>'oid', values=>\@organisms, labels=>\%labels});
}


#
# Generates a popup-meny based on an array of uids.
#
sub uids_popup {
  my ($uids, $label) = @_;
  my %labels;

  foreach my $uid (@{$uids}) {
    my $user = &db::user::fetch_user($uid);
    $labels{$uid} = $$user{name};
  }

  return html::generic_form_element({type=>'popup', 
				     name=>$label, 
				     values=>$uids, 
				     labels=>\%labels}) 
      if ($label);

  return html::generic_form_element({type=>'popup', 
				     name=>'uid', 
				     values=>$uids, 
				     labels=>\%labels}); 


}

#
# Makes a popup menu with the users
#
sub user_popup {
  my ($label) = @_;
  

  my @users = db::user::fetch_users();
  my %labels = ();

  for (my $i=0; $i < @users; $i++) {
    $labels{$users[$i]{uid}} = $users[$i]{name};
    $users[$i] = $users[$i]{uid};
  }

  return html::generic_form_element({type=>'popup', 
				     name=>$label, 
				     values=>\@users, 
				     labels=>\%labels}) 
      if ($label);

  return html::generic_form_element({type=>'popup', 
				     name=>'uid', 
				     values=>\@users, 
				     labels=>\%labels});
}

#
# Generates a popup-meny based on an array of grids.
#
sub grids_popup {
  my (@grids) = @_;
  my %labels;

  foreach my $grid (@grids) {
    my $group = &db::user::fetch_group($grid);
    $labels{$grid} = $$group{name};
  }

  return html::generic_form_element({type=>'popup', name=>'grid', values=>\@grids, labels=>\%labels});
}


#
# Makes a popup menu with the groups
#
sub group_popup {
  my ($default) = @_;

  my @groups = db::user::fetch_groups();
  my %labels = ();

  for (my $i=0; $i < @groups; $i++) {
    $labels{$groups[$i]{grid}} = $groups[$i]{name};
    $groups[$i] = $groups[$i]{grid};
  }


  return html::generic_form_element({type=>'popup', name=>'grid', values=>\@groups, labels=>\%labels,
				     defaults=>[$default]})
      if ($default);

  return html::generic_form_element({type=>'popup', name=>'grid', values=>\@groups, labels=>\%labels});
}

#
# Make the login/logout button that is found in upper right corner.
#
sub make_login_logout {
  my $logout_form;
 
  # making the login/logout button, depending on the state of the
  # url, things change.
  if ($html::parameters{'seid'}) {

    $logout_form = html::start_form('../cbin/mutagen.pl');
    $logout_form .= &html::generic_form_element({type=>'submit', name=>'session', value=>"Logout as $html::parameters{'username'}"});
    $logout_form .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>'session'});
    $logout_form .= html::end_form();
  }
  else {
    # making the head of the page, logo and login/logout possibilities
    $logout_form = html::start_form('../cbin/mutagen.pl');
    $logout_form .= &html::generic_form_element({type=>'submit', name=>'session', value=>'Login'});
    $logout_form .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>'session'});
    $logout_form .= html::end_form();
  }

  return $logout_form;
}


# 
# Makes nice blast buttons
# 
# Kim Brugger (28 Nov 2003)
sub blast_buttons {
  my ($gid) = @_;
  
  my @cells = ();
  
  my $html .= &html::start_form("../cbin/mutagen.pl", undef, "BLASTREPPORT");

  push @cells, &html::generic_form_element({type=>"submit", name=>"showSP", value=>"Hits in SWISS-PROT"})
      if (-e "../reports/SP/gid:$gid.blast" || -e "../reports/SP/gid:$gid.blast.gz");

  push @cells, &html::generic_form_element({type=>"submit", name=>"showSPure", value=>"Hits in SPure"})
      if (-e "../reports/SPure/gid:$gid.blast" || -e "../reports/SPure/gid:$gid.blast.gz");

  push @cells, &html::generic_form_element({type=>"submit", name=>"showLocal", value=>"Hits in local-db"})
      if (-e "../reports/local/gid:$gid.blast.gz" || -e "../reports/local/gid:$gid.blast");

  push @cells, &html::generic_form_element({type=>"submit", name=>"showGBK", value=>"Hits in GBK"})
      if (-e "../reports/GBK/gid:$gid.blast.gz" || -e "../reports/GBK/gid:$gid.blast");

  push @cells, &html::generic_form_element({type=>"submit", name=>"showCOG", value=>"Hits in COG"})
      if (-e "../reports/COG/gid:$gid.blast.gz" || -e "../reports/COG/gid:$gid.blast");
  
  push @cells, &html::generic_form_element({type=>"submit", name=>"showPfam", value=>"Hits in Pfam"})
      if (-e "../reports/pfam/gid:$gid.pfam.gz" || -e "../reports/pfam/gid:$gid.pfam");

  push @cells, &html::generic_form_element({type=>"submit", name=>"showInternal", value=>"Hits in internal db"})
      if (-e "../reports/internal/gid:$gid.blast.gz" || -e "../reports/internal/gid:$gid.blast");


  $html .= &html::table([\@cells], 1, 2, 2);


  $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>'misc'});
  $html .= &html::generic_form_element({type=>'hidden', name=>'buttonreport',    value=>"$gid"});
  
  $html .= &access::session_form();

  $html .= &html::end_form();
  
  return $html;
}

BEGIN {

}

END {

}

1;


