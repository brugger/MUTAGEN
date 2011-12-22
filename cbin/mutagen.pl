#!/usr/bin/perl -wT
# 
# This script controls most of the administrative tasks in this system, 
# I have tried to move as much as possible from the command-line into this
# script, so mere _mortals_ also have a change of doing these things.
#
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;

use lib '/data/www/sulfolobus.org/modules/';
use lib '/usr/local/perllib/';
use conf;
use core;
use mutagen_html;

# The system is designed so there are several main pages, sometime containing sub-pages.
# Each page (or sub-page) is handles in a module, so here we just wonder where to go, 
# and send the program to the corresponding module. Only when the module is needed is the 
# module loaded to ensure a faster program.
&html::dump_params();

#this variable is going to contain all the html code, so we can send it all of in one go.
my $hinsert = "";

# this variable tells how the program should present the result, sometimes we want to show it 
# with the menu, and other times with out. As a default we always make the top menu.

my $make_top_menu = 1;

#
# ------------ HOW THE PROGRAM IS STRUCTURED ------------
#
# The main function of this this script is to guide the code to the
# correct place, this is done on a "page" basis. So all functions are
# linked to a specific page, and the functionality comes from that
# module that is loaded at runtime, so we do not have to lead every
# module every time. So here the program checks for the page variable
# and if it is not found the main page is displayed.
#
#

#&core::LOG("START");
# 
# Handles the login/logout/session thing.
# 
if ($html::parameters{'page'} && $html::parameters{'page'} eq "session") {
  ($hinsert, $make_top_menu) = &access::run();
  
  goto MAKE_HTML if ($hinsert);
}

# 
# Check and see if dont allow guests, and if so make a login page
# 
if (!$conf::guests && !$html::parameters{'seid'}) {
  $html::parameters{'session'} = "login";
  ($hinsert, $make_top_menu) = &access::run();

  goto MAKE_HTML if ($hinsert);
}

#
# If there are a session if (seid) then check the session to se if 
# it is still valid or make a new login in form.
# 
if ($html::parameters{'seid'}) {
  my $session;
  $session = &access::login();

  if ($session ne "1") {
#    print STDERR "Makes a new login form\n";
    ($hinsert) = &access::make_login_page();

    goto MAKE_HTML;
  }
}

# 
# Handle the menu system, and make sure that the correct pages are made.
# 
# 
if ($html::parameters{'page'}) {
  
  if ($html::parameters{'page'} eq "sequence") {
    require page::sequence;
    ($hinsert, $make_top_menu) = &page::sequence::run();
  }
  elsif ($html::parameters{'page'} eq "compare") {
    require page::compare;
    ($hinsert, $make_top_menu) = &page::compare::run();
  }
  elsif ($html::parameters{'page'} eq "blast") {
    require page::blast;
    ($hinsert, $make_top_menu) = &page::blast::run();
  }
  elsif ($html::parameters{'page'} eq "search") {
    require page::search;
    ($hinsert, $make_top_menu) = &page::search::run();
  }
  elsif ($html::parameters{'page'} eq "annotate") {
    require page::annotate;
    $hinsert = &page::annotate::run();
  }
  elsif ($html::parameters{'page'} eq "subpage") {
    require page::misc;
    ($hinsert, $make_top_menu) = &page::misc::run();
  }
  elsif ($html::parameters{'page'} eq "admin") {
    require page::admin;
    $hinsert = page::admin::run();
  }
  elsif ($html::parameters{'page'} eq "cluster") {
    require page::cluster;
    ($hinsert, $make_top_menu) = &page::cluster::run();
  }
  # Currently not functionally
#  elsif ($html::parameters{'page'} eq "bugs") {
#    require page::bugs;
#    ($hinsert, $make_top_menu) = &page::bugs::run();
#  }
  elsif ($html::parameters{'page'} eq "docs") {
    require page::docs;
    ($hinsert, $make_top_menu) = &page::docs::run();
  }
  # finally the fallthrough/default option.
  # This also catches all the subpages...
  else {
    require page;
    ($hinsert, $make_top_menu) = &page::run();
  }
}


MAKE_HTML:

$make_top_menu = 0 if (!$make_top_menu);

# This is the default frontpage display
if (!$hinsert && -e "frontpage") {
  open INFIL, "frontpage" || die "Could not open 'frontpage': $!\n";
  $hinsert = join("\n", <INFIL>);
  close INFIL;
}

$hinsert .= q(<script type="text/javascript">
var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
</script>
<script type="text/javascript">
var pageTracker = _gat._getTracker("UA-5136001-2");
pageTracker._trackPageview();
</script>);

my $html = "";
# A normal page
if ($make_top_menu == 1) {
  $html = &mutagen_html::make_page($hinsert, $html::parameters{'page'});
}
# Here we just make the html-header. This is not often used.
elsif ($make_top_menu == 2) {
  $html = &html::head().$hinsert;
}
# Nice colours, without a menu
elsif ($make_top_menu == 0) {
  $html = &mutagen_html::empty_page($hinsert, $html::parameters{'page'});
}
print "$html\n";

#&core::LOG("STOP");

