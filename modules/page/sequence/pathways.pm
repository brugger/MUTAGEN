#!/usr/bin/perl -wT
# 
# 
# 
# 
# Kim Brugger (Apr 2005), contact: brugger@mermaid.molbio.ku.dk
use strict;

package page::sequence::pathways;
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

sub pathway_select {
  my ($oid) = @_;

  my $html .= &mutagen_html::headline("Pathways page");

  $html .= html::start_form('mutagen.pl');

  require db::organism;
  require db::version;

  my $organism = &db::organism::fetch($html::parameters{'oid'});
  my $version  = &db::version::fetch($html::parameters{'vid'});
  
  
  my @cells= ["<H3>Pathways identified in '$$organism{'name'}'</H3>"];


  # Identify the pathways in this organism
  require db::pathways;

  my $pathways = &db::pathways::organism($$organism{'oid'});

  @$pathways = sort {$$a{description} cmp $$b{description}} @$pathways;

  foreach my $pathway (@$pathways) {
    push @cells, ["<A HREF='mutagen.pl?page=sequence&subpage=pathways&pid=$$pathway{pid}'>$$pathway{description}</A>"];
    
  }


  $html .= &html::style::center(&html::table(\@cells, 1, 5, 5, undef, "98%"));
  
  $html .= &html::generic_form_element({type=>'hidden',name=>'oid', value=>$html::parameters{'oid'}});
  $html .= &html::generic_form_element({type=>'hidden',name=>'vid', value=>$html::parameters{'vid'}});
  $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"sequence"});
  $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"export"});
  $html .= &access::session_form();
  $html .= &html::end_form();

  return $html;

}

sub show_pathway {

  require db::pathways;
  my $pid = $html::parameters{'pid'};

  my $pathway = &db::pathways::fetch($pid);

  my $html = "";
  
  # The pictures are kept in the database
  if ($conf::dbreports) {
    
    my $tmpfil = &kernel::tmpname() . ".gif";
    
    open OUTFIL, ">$tmpfil" or die "Could not open '$tmpfil': $!\n";
    binmode OUTFIL;
    print OUTFIL $$pathway{picture};
    close OUTFIL;
    $html = &html::style::center("<IMG BORDER=0 SRC='$tmpfil' ISMAP>\n");

  }
  else {
    $html = &html::style::center("<IMG BORDER=0 SRC='../reports/KEGG/$pid\.gif' ISMAP>\n");
  }
  # since a EC number can have multiple gids we have to make a list
  # using the ever ready and very useful hash....
  my %ECs = ();

  foreach my $gene (@{$$pathway{genes}}){
    
    $$gene{'url'} = "<A HREF='mutagen.pl?page=misc&".&access::session_link().
	"&gidinfo=$$gene{gid}' TARGET=ginfo>gid:$$gene{'gid'}</A> &nbsp;";
    
    $ECs{$$gene{'EC'}} .= " $$gene{'url'}" if ($ECs{$$gene{'EC'}});
    $ECs{$$gene{'EC'}} =   "$$gene{'url'}" if (!$ECs{$$gene{'EC'}});
  }

  my @cells;
  foreach my $EC (sort {my $A = $a; $A =~ s/ec://; 
			      my $B = $b; $B =~ s/ec://; 
			      my ($a1, $a2, $a3, $a4) = split(/\./, $A);
			      my ($b1, $b2, $b3, $b4) = split(/\./, $B);

			      $a1 <=> $b1 || $a2 <=> $b2 || $a3 <=> $b3 || $a4 <=> $b4
			    } keys %ECs) {
    push @cells, [$EC, $ECs{$EC}];
  }
  $html .= &html::table(\@cells, 1, 5, 1, undef);


  return $html;
}




BEGIN {

}

END {

}

1;


