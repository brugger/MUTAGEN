#!/usr/bin/perl -wT
# 
# 
# 
# 
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;


package page::search;
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
  $html .= &html::style::center(html::style::h1("Search the database"));
  $html .= &html::style::hr("70%");
  $html .= &html::style::break();

  if ($html::parameters{'search'} && $html::parameters{'words'}) {
    $html .= &simple_search_db();
  }
  else {
    $html .= &search_page();
#    $html .= &advanced_search_page();
  }

  return ($html, 1);
}

# 
# Seaches the database (simple mode)
# 
# Kim Brugger (11 Dec 2003)
sub simple_search_db  {
  use db::search;
  use db::gene;
  use db::annotation;
  use db::version;
  use db::organism;

  my $html = "";

  $html::parameters{'words'} =~ s/^ *(.*) *$/$1/; 
  my @words = split / /, $html::parameters{'words'};

  $html .= "<P>Made a search with : <B> @words</B><BR>";
  my @hits = ();
  # Each of the words get checked against the database.
  foreach my $word (@words) {
    # always search for the gid.
    if ($word =~ /gid:(\d+)/) {
      push @hits, &db::search::gid ($1, undef);
    }
    
    push @hits, &db::search::gene_name ($word, undef);
    push @hits, &db::search::annotations ($word, undef) if ($html::parameters{'manual'});
    push @hits, &db::search::adc ($word, undef)  if ($html::parameters{'adc'});
  }

  
  $html .= "<P> There are 2 links for each hit, the first link gives the ORF information 
               and makes it possible to go to the annotation page, the other link gives 
               the ORF browser, where the ORF in question is highlighted in yellow.<BR><BR>";

  @hits = sort @hits if (@hits);

  my $count = 1;

  # Order the hits so the best hit comes at the top.
  my @orded_by_num_hits;

  for (my $i = 0; $i < @hits; $i++) {
    if ($hits[$i+1] && $hits[$i] == $hits[$i+1]) {
      $count++; next;
    }
    
    push @orded_by_num_hits, [$count, $hits[$i]];
    $count =1;
  }

  @orded_by_num_hits = sort {$$b[0] <=> $$a[0]} @orded_by_num_hits;

  my @cells = ();
  push @cells,  ["<B>Gene id</B>", "<B>Number of hits</B>", "<B>Link to ORF browser</B>", 
		 "<B>Gene product</B>", "<B>Organism</B>", "<B>Version</B>"];

  foreach my $hit (@orded_by_num_hits) {
    next if (!$$hit[1]);

    my $orf = &db::gene::fetch ($$hit[1]);
#    next if !check_s_groups($dbh, $query->param("username"), 0, 0, 0, $$orf{'gid'});

    my @annotation = &db::annotation::all($$orf{'gid'}, 1);
    my $gene_name = $$orf{'name'};
    $gene_name = $annotation[0]{'gene_product'} if ($annotation[0] && $annotation[0]{'gene_name'});
    
    my $version = &db::version::fetch_by_gid($$orf{'gid'});

    my $organism = &db::organism::fetch($$orf{'oid'});

    $$organism{'name'} =~ s/^(.).*? (.*)$/$1. $2/;


    push @cells, ["<a href='../cbin/mutagen.pl?page=misc&gidinfo=$$orf{'gid'}".
		  &access::session_link()."'> gid:$$orf{'gid'}</A>", 
		  "$$hit[0] hits with the word(s) where found", 
		  "<A HREF='../cbin/mutagen.pl?page=sequence&subpage=browse&ORFmap=1&gid=$$orf{'gid'}".
		  &access::session_link()."'>ORF Browser</A>", 
		  $gene_name, 
		  $$organism{'name'},
		  "$$version{'version'}"];
  }

  $html .= &html::table(\@cells, 1, 5,2, undef, "");
  
  return $html;
}

sub search_page {

  my $html = "";

  $html .= html::start_form('mutagen.pl');

  my @cells = [&html::generic_form_element({type=>'reset'}),
	       &html::generic_form_element({type=>'submit', name=>'search', value=>'Search the database'})
	       ];
#  $html .= &html::table(\@cells, 0, 5,5);

  push @cells, ["Word(s) to search for:",
		&html::generic_form_element({type=>'text', name=>'words', value=>'', size=>'40'})
		];

  push @cells, ["Manual annotation:",
		&html::generic_form_element({type=>'checkbox', name=>'manual', value=>'', checked=>'1'})
		];

  push @cells, ["Automatic collected data:",
		&html::generic_form_element({type=>'checkbox', name=>'adc', value=>''})
		];

  push @cells, [&html::generic_form_element({type=>'reset'}),
		&html::generic_form_element({type=>'submit', name=>'search', value=>'Search the database'})
		];

  $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"search"});
  $html .= &access::session_form();

  $html .= &html::table(\@cells, 0, 5,5);

  $html .= &html::end_form();


  return $html;
}

sub advanced_search_page {

  my $html = "";

  $html .= &html::style::center(html::style::h1("Search the database"));
  $html .= &html::style::hr("70%");
  $html .= &html::style::break();

  $html .= html::start_form('mutagen.pl');

  my @cells = [&html::generic_form_element({type=>'reset'}),
	       &html::generic_form_element({type=>'submit', name=>'search', value=>'Search the database'})
	       ];

  push @cells, ["Word(s) to search for:",
		&html::generic_form_element({type=>'text', name=>'search', value=>'', size=>'40'})
		];

  push @cells, ["gid:",
		&html::generic_form_element({type=>'text', name=>'gid', value=>'', size=>'40'})
		];

  push @cells, ["Gene name:",
		&html::generic_form_element({type=>'text', name=>'name', size=>'40'})
		];

  push @cells, ["Gene product:",
		&html::generic_form_element({type=>'text', name=>'product', size=>'40'})
		];

  push @cells, ["Comment:",
		&html::generic_form_element({type=>'text', name=>'comment', size=>'40'})
		];


  require db::organism;

  my @organisms = ("All", &db::organism::all());
  my %labels = ();
  
  for (my $i = 1; $i<@organisms; $i++) {    
    $organisms[$i]{'name'} =~ s/^(.).*? (.*)$/$1. $2/;
    $labels{$organisms[$i]{'oid'}} = $organisms[$i]{'name'};
    $organisms[$i] = $organisms[$i]{'oid'};
  }

  
  push @cells, ["Organism:",
		&html::generic_form_element({type=>'popup', name=>'organism', values=>\@organisms, labels=>\%labels})
		];

#  push @cells, ["Manual annotation:",
#		&html::generic_form_element({type=>'checkbox', name=>'search', value=>'', checked=>'1'})
#		];

#  push @cells, ["Automatic collected data:",
#		&html::generic_form_element({type=>'checkbox', name=>'search', value=>''})
#		];

  push @cells, [&html::generic_form_element({type=>'reset'}),
		&html::generic_form_element({type=>'submit', name=>'search', value=>'Search the database'})
		];

  $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"search"});

  $html .= &html::table(\@cells, 1, 5,1);
  


  $html .= &html::end_form();

  return $html;


}

BEGIN {

}

END {

}

1;


