#!/usr/bin/perl -wT
# 
# This module contains higher level html code for the system, so all pages can be generated 
# here along with special elements like login buttons and common pages.
# 
# Kim Brugger (Nov-Dec 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;
use core;

package mutagen_html;
require Exporter;
require AutoLoader;

# set the version for version checking
my $VERSION     = "0.01";

my @ISA = qw(Exporter AutoLoader);

our @EXPORT = qw();
@ISA = qw(Exporter AutoLoader);

my $PROJECT_NAME = $conf::html_header || "MUTAGEN V4.";

my $BODY_COLOUR  = $conf::html_body || "#719179";
my $VLINK_COLOUR = $conf::html_vlink || "#ffff00";
my $LINK_COLOUR  = $conf::html_link || $VLINK_COLOUR;
my $ALINK_COLOUR = $conf::html_alink || "#ff0000";

# colour of the header
my $HEADER_BG    =  $conf::html_hcolour || "#517159";

my $mutagen_version = "4.0 -- going &#947;";

require mutagen_html::forms;

# 
# A standart headline, so all pages look the same.
# 
# Kim Brugger (03 Dec 2003)
sub headline  {
  my ($title, $subtitle) = @_;

  my $html = "";
  $html .= &html::style::center(&html::style::h1("$title"));
  $html .= &html::style::center(&html::style::h2("$subtitle")) if ($subtitle);
  $html .= &html::style::hr("70%");
  $html .= &html::style::break();

  return $html;
}


#
# Make the top menu(s) + the MUTAGEN header (tm). 
# The active menu is highlighted, for easier navigation (c)
#
# Kim Brugger (Dec 2003), contact: brugger@mermaid.molbio.ku.dk
sub page_header {
  my ($active_menu, $no_start) = @_;
  $active_menu ="main" if (!$active_menu);
  # link => "rel='stylesheet' href='mutagen.css' type='text/css'"
  my $html = html::start("MUTAGEN: $conf::html_header", $conf::css,
			 {bgcolor => "$BODY_COLOUR", 
			  link => "$LINK_COLOUR", 
			  vlink => "$VLINK_COLOUR"}, $no_start);

  require mutagen_html::forms;

  my $logout_form = &mutagen_html::forms::make_login_logout();
  
  # general header with the name of the project and a logout/login
  # button, this will become sweet.
  $html .= html::style::center( &html::advanced_table([[{"value" => "<img src='../graphics//MUTAGEN-man.png'> ver. $mutagen_version", 
							 "bgcolor" => "$HEADER_BG", align=>"left",
						       "width" => "30%"}, 
							{"value" => "<H1>$PROJECT_NAME</h1>", 
							 "bgcolor" => "$HEADER_BG", align=>"center",
						       "width" => ""},
							{value=>"$logout_form", "bgcolor" => "$HEADER_BG", 
							 align=>"right",
						       "width" => "30%"}]], 
						     0, 0, 0, "$HEADER_BG", undef, "100%", "banner"));

  # now the main page, into this there will be the possibility for
  # adding content, but as things go, this is the genreal setup
  my @links = (
	       {name=>"Back to main", tag=>"main", group=>""},
	       {name=>"Sequence", tag=>"sequence", group=>""},
	       {name=>"Sequence comparison", tag=>"compare", group=>""},
	       {name=>"BLAST", tag=>"blast", group=>""},
	       {name=>"Search", tag=>"search", group=>""},
#	       {name=>"Bug report", tag=>"bugs", group=>""},
	       {name=>"Documentation", tag=>"docs", group=>""},
	       {name=>"Admin", tag=>"admin", group=>"admin"},
	       );

  my @cells = (); my $res; 

  foreach my $link (@links) {
    
    next if ($$link{group} && !access::uid_group($html::parameters{uid}, $$link{group}));

    next if ($$link{tag} eq "compare" && !($conf::html_level & $conf::html_compare));

    my $href = "../cbin/mutagen.pl?page=$$link{tag}";
    $href .= "&seid=$html::parameters{'seid'}" if ($html::parameters{'seid'});

    $res = {value=>"<A HREF=\'$href\' target='_top'>$$link{name}</A>", bgcolor=>"#888888"}
	if ($active_menu && $$link{tag} ne $active_menu || !$active_menu);

    $res = {value=>"<A HREF=\'$href\' target='_top'>$$link{name}</A>", bgcolor=>"#666666"}
	if ($active_menu && $$link{tag} eq $active_menu);

    push @cells, $res;
    $res = undef;
  }

#  push @cells, {value=>"<A href='http://wiki.sulfolobus.org/wiki/'>SulfolobusWiki</a>", bgcolour=>"#666666"};

  
  $html .= html::style::center(html::advanced_table([\@cells], 1, 0, 0, "#888888", 0, "100%", "menu"));

  my $subpage = $html::parameters{'subpage'} if $html::parameters{'subpage'};

  # If the active menu is the admin link, we build another menu
  if ($active_menu && $active_menu eq "admin") {
    my @admin = (
		 {name=>"Handle users and groups",               value=>"user_group", group=>"admin"},
		 {name=>"Handle sequences",                      value=>"sequences", group=>"admin"},
		 {name=>"Handle external databases integration", value=>"external", group=>"admin"},
#		 {name=>"Tweak the scheduler",                   value=>"scheduler", group=>"admin"},
#		 {name=>"General setup",                         value=>"setup", group=>"admin"},
		 {name=>"Backup",                                value=>"backup", group=>"admin"},
		 );
    $html .= submenu(\@admin, $active_menu, $subpage);
  }
  # If the active menu is the admin link, we build another menu
  elsif (0&&$active_menu && $active_menu eq "sequence") {
    my @sequence = (
		 {name=>"Annotate",                              value=>"annotate", group=>""},
		 {name=>"Export sequence",                       value=>"export",   group=>""},
		 );
    $html .= submenu(\@sequence, $active_menu, $subpage);
  }

  if (0 && $active_menu && $active_menu eq "main") {
    my @main = (
		{name=>"Profile", value=>"profile", group=>""},
		{name=>"Users",   value=>"sequences", group=>""},
#		{name=>"Handle external databases integration", value=>"databases", group=>""},
#		{name=>"Tweak the scheduler",                   value=>"scheduler", group=>""},
#		{name=>"General setup",                         value=>"setup", group=>""},
		 );
    $html .= submenu(\@main, $active_menu, $subpage);
  }

# a general ruler to divide the header from the main part of the page
#  $html .= html::style::hr();

  return $html;
}

#
# Makes the sub menu, and the active menu is even highlighted 
#
# Kim Brugger (Dec 2003), contact: brugger@mermaid.molbio.ku.dk
sub submenu {
  my ($menu, $active_menu, $active_sub) = @_;

  my @cells = (); my $res;
  foreach my $link (@$menu) {
    next if ($$link{group} && !access::uid_group($html::parameters{uid}, $$link{group}));


    my $href = "../cbin/mutagen.pl?page=$active_menu&subpage=$$link{value}";
    $href .= "&seid=$html::parameters{'seid'}" if ($html::parameters{'seid'});
    
    $res = {value=>"<A HREF=\'$href\' target='_top'>$$link{name}</A>", bgcolor=>"#666666"}
    if ($active_sub && $$link{value} ne $active_sub || !$active_sub);
    
    $res = {value=>"<A HREF=\'$href\' target='_top'>$$link{name}</A>", bgcolor=>"#444444"}
    if ($active_sub && $$link{value} eq $active_sub);
    
    push @cells, $res;
  }
  
  return html::style::center(html::advanced_table([\@cells], 1, 3, 3, "#666666", 0, "100%", "menu"));
}

#
# the page tail, which is basically my email, so people can see who did this code.
#
# Kim Brugger (Dec 2003), contact: brugger@mermaid.molbio.ku.dk
sub page_tailer {

  # finally a tail, with the possibility for contacting
  # ME-ME-ME-ME-ME-ME-ME-ME-ME-ME-ME-ME !!!!!! or the sysadmin
  my $html = html::style::hr();
  $html .= html::contact("Kim Brugger", 'brugger@dac.molbio.ku.dk');
  $html .=  html::end();

  return $html;
}

#
# Easy making a html page code, neat and sweet !!
#
# Kim Brugger (Dec 2003), contact: brugger@mermaid.molbio.ku.dk
sub make_page {
  my ($content, $active_menu) = @_;
  
  my $html = page_header($active_menu);
  $html .= $content;
  $html .= page_tailer();

  return $html;
}

#
# Make a page that consists of 2 forms, this is to display the maps
#
# Kim Brugger (Dec 2003), contact: brugger@mermaid.molbio.ku.dk
sub make_form_page {
  my ($active_menu, $top, $topsize, $bottom, $top_horizontal_scroll) = @_;

  my $topfile    =  &kernel::tmpname().".html"; 
  my $bottomfile =  &kernel::tmpname().".html";

  my $html = "";#html::head();

  $html.= "<HTML>\n";
  $html.= "  <HEAD>\n";
  $html.= "  <TITLE>Main annotation page</TITLE>\n";
  $html.= "  <link rel='stylesheet' href='$conf::css' type='text/css' />"
      if ($conf::css);

  $html.= "  </HEAD>\n";
  $html.= "  <FRAMESET rows='$topsize,*' scrolling='no'>\n";
  $html.= "    <FRAME src='$topfile' name='top' scrolling='no'>\n" 
      if (!$top_horizontal_scroll);
  $html.= "    <FRAME src='$topfile' name='top' scrolling='auto'>\n" 
      if ($top_horizontal_scroll);
  $html.= "    <FRAME src='$bottomfile' name='bottom'>\n";
  $html.= "  </FRAMESET>\n";
  $html.= "</HTML>\n";

  open (OUTFILE, "> $topfile") || die "could not open '$topfile': $!";
  print OUTFILE  &page_header($html::parameters{'page'}, 1);
  print OUTFILE $top;
  close (OUTFILE) || die "Could not close '$topfile': $!";

  open (OUTFILE, "> $bottomfile") || die "could not open '$bottomfile': $!";
  print OUTFILE  html::start("MUTAGEN $mutagen_version", 
			     $conf::css,
			     {bgcolor => "$BODY_COLOUR", 
			      link => "$LINK_COLOUR", 
			      vlink => "$VLINK_COLOUR"}, 1);
  print OUTFILE $bottom;
  close (OUTFILE) || die "Could not close '$bottomfile': $!";
  
  return $html;
}

#
# Return an empty web page, so we can have some nice empty pages.
#
# Kim Brugger (Dec 2003), contact: brugger@mermaid.molbio.ku.dk
sub empty_web_page {
  return "<HTML></HTML>";
}

#
# Creas a html header without a menu, but sill with colours, should
# not be called directly.
#
# Kim Brugger (Dec 2003), contact: brugger@mermaid.molbio.ku.dk
sub empty_head {
  my ($no_start) = @_;
  return html::start("MUTAGEN $mutagen_version", 
		     $conf::css, 
		     {bgcolor => "$BODY_COLOUR", 
		      link => "$LINK_COLOUR", 
		      vlink => "$VLINK_COLOUR"}, 
		     $no_start);
}


#
# Creas a html page with out a menu, but sill with colours
#
# Kim Brugger (Dec 2003), contact: brugger@mermaid.molbio.ku.dk
sub empty_page {
  my ($content) = @_;

  return &empty_head(0). "$content</BODY></HTML>";
}

1;
