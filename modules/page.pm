#!/usr/bin/perl -wT
# 
# Handles fall through page handling for those Quazzzzy sub_pages of D00M
# Actually, I cannot be buggered to re-design 
# this part of the code right now.
# 
# Kim Brugger (Dec 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;

package page;
require Exporter;
require AutoLoader;

# set the version for version checking
my $VERSION     = "0.01";

my @ISA = qw(VERSION Exporter AutoLoader);

our @EXPORT = qw();
@ISA = qw(Exporter AutoLoader);
@EXPORT = qw();


require Exporter;
require AutoLoader;

#exported variables.
use vars qw ();

sub run {

  my $html = "";

  require mutagen_html::subpage;
  
  if ($html::parameters{'gidinfo'} && $html::parameters{'gidinfo'} ne "") {
    return &access::no_access 
	if (&access::check_access($html::parameters{'gidinfo'}, undef, undef));

    $html =(&mutagen_html::subpage::gid_tools() ."<BR>".
	    &mutagen_html::subpage::gid_info($html::parameters{'gidinfo'}).
	    &mutagen_html::subpage::annotation_info($html::parameters{'gidinfo'}, 0).
#	    &mutagen_html::subpage::wiki_entry($html::parameters{'gidinfo'}, 0).
	    "");
    return ($html,0);
  }
  elsif ($html::parameters{'fidinfo'} && $html::parameters{'fidinfo'} ne "") {
    $html =( &mutagen_html::subpage::fid_tools($html::parameters{'fidinfo'}) ."<BR>".
	     &mutagen_html::subpage::fid_info($html::parameters{'fidinfo'}).
	     "");
    return ($html,0);
  }
  elsif ($html::parameters{'gene_seq'} && $html::parameters{'gene_seq'} == 1) {    
    $html .= &mutagen_html::subpage::gene_seq($html::parameters{'gid'}, $html::parameters{'fid'});
    return ($html,0);
  }
  elsif ($html::parameters{'gene_flank'} && $html::parameters{'gene_flank'} == 1) {
    $html .= &mutagen_html::subpage::gene_flank($html::parameters{'gid'}, $html::parameters{'fid'});
    return ($html,0);
  }
  elsif ($html::parameters{'showreport'}) {
    $html .= &mutagen_html::subpage::show_report($html::parameters{'showreport'});
    return ($html,0);
  }
  elsif ($html::parameters{'showreportdb'}) {
    $html .= &mutagen_html::subpage::show_dbreport($html::parameters{'gid'}, $html::parameters{'showreportdb'});
    return ($html,0);
  }
  elsif ($html::parameters{'buttonreport'}) {
    my $report = "gid:$html::parameters{'buttonreport'}";

    if ($html::parameters{'showSP'}) {
      $report = "reports/SP/$report.blast";
    }
    if ($html::parameters{'showSPure'}) {
      $report = "reports/SPure/$report.blast";
    }
    elsif ($html::parameters{'showLocal'}) {
      $report = "reports/local/$report.blast";
    }
    elsif ($html::parameters{'showGBK'}) {
      $report = "reports/GBK/$report.blast";
    }
    elsif ($html::parameters{'showCOG'}) {
      $report = "reports/COG/$report.blast";
    }
    elsif ($html::parameters{'showPfam'}) {
      $report = "reports/pfam/$report.pfam";
    }
    elsif ($html::parameters{'showInternal'}) {
      $report = "reports/internal/$report.blast";
    }

    print STDERR "Showing $report\n";

    $html .= &mutagen_html::subpage::show_report($report);
    return ($html,0);
  }
  elsif ($html::parameters{'new_gene'}) {
    $html .= &mutagen_html::subpage::add_gene($html::parameters{'sid'}, $html::parameters{'start'}, 
		       $html::parameters{'stop'}, $html::parameters{'gene_type'}, 
		       $html::parameters{'strand'},$html::parameters{''});
    return ($html,0);
  }
  elsif ($html::parameters{'delete_gene'}) {
    $html .= &mutagen_html::subpage::delete_gene($html::parameters{'gid'}, $html::parameters{'sure'});

    return ($html,0);
  }
  elsif ($html::parameters{'change_start'}) {
    $html .= &mutagen_html::subpage::change_start($html::parameters{'gid'}, $html::parameters{'new_start'}, 
						  $html::parameters{'new_name'}, $html::parameters{'gene_type'}, 
						  $html::parameters{'sure'});

    return ($html,0);
  }
  elsif ($html::parameters{'change_finder_start'}) {
    $html .= &mutagen_html::subpage::change_finder_start($html::parameters{'fid'}, 
				  $html::parameters{'new_start'}, 
				  $html::parameters{'new_stop'}, 
				  $html::parameters{'sure'});


    return ($html,0);
  }
  else {
    return ("", 1);
  }

  return ($html,2);
}


BEGIN {

}

END {

}

1;




BEGIN {

}

END {

}

1;


