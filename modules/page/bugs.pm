#!/usr/bin/perl -wT
# 
# 
# 
# 
# Kim Brugger (Dec 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;

package page::bugs;
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

sub run {
  
  my $html = "";

    $html .= &html::style::center(html::style::h1("New improved web-blast page"));
  $html .= &html::style::hr("70%");
  $html .= &html::style::break();

  $html .= html::start_form('mutagen.pl');
  
  my  @cells;

  @cells = [&html::generic_form_element({type=>'reset'}),
	    &html::generic_form_element({type=>'submit', name=>'blasting', value=>'Send bug report'})
	    ];

  $html .= &html::table(\@cells, 0, 5,5);

  $html .= "Describe the problem, and please give so much information as possible such as URL, and what you where doing when the problem arose:<BR>";

  $html .= &html::generic_form_element({type=>'textarea', 
					value=>'', 
					name=>'seqin', 
					cols=>'80',
					rows=>'8'});



  @cells = [&html::generic_form_element({type=>'reset'}),
	    &html::generic_form_element({type=>'submit', name=>'blasting', value=>'Send bug report'})
	    ];

  $html .= &html::table(\@cells, 0, 5,5);

  return ($html, 1);
}


BEGIN {

}

END {

}

1;


