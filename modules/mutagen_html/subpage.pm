#!/usr/bin/perl -wT
# 
# Contains functions that creates subpages from the database.
# These subpages is used in various places in the code.
#
# 
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;

package mutagen_html::subpage;
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

# add the information that comes from the automatic data collection methods

#
# Basic gene information, it is possible to select between a normal, 
# compressed and full version of this.
#
sub gid_info {
  my ($gid) = @_;

  return &access::no_access if (&access::check_access($gid, undef, undef));

  require db::gene;
  my $gene = &db::gene::fetch($gid);
  
  my @cells;

  $$gene{'org_name'} =~ s/^(.)\w+ (.*)/$1. $2/;
  push @cells, [{value =>"<B>Organism:</B>"}, {value =>$$gene{'org_name'}, colspan => 9}];
  
  $$gene{'name'} = "&nbsp;" if (!$$gene{'name'});



  push @cells, [{value => "<B>Gene name:</B>"}, 
		{value => $$gene{'name'}, colspan=>2}, 
		{value => "<B>Gene length ".($$gene{'type'} eq "ORF" ? "(AA)" : "(DNA)") .":</B>"},
		{value => $$gene{'type'} eq "ORF" ? (1+$$gene{'stop'} - $$gene{'start'})/3 -1:
		     (1+$$gene{'stop'} - $$gene{'start'})-3},

		{value =>"<B>Gene ID:</B>"}, {value =>"gid:$$gene{'gid'}", colspan=>2}
		];

  push @cells, [{value =>"<B>Gene strand:</B>"}, 
		{value =>$$gene{'strand'} ? "Minus" : "Plus"},
		{value =>"<B>Gene type:</B>"}, 
		{value =>$$gene{'type'}},
		{value => "<B>Gene start:</B>"}, 
		{value => $$gene{'strand'} ? $$gene{'stop'} : $$gene{'start'}},
		{value =>"<B>Gene stop:</B>"},   
		{value => $$gene{'strand'} ? $$gene{'start'} : $$gene{'stop'}},

		];

  push @cells, [{value =>"<B>Gene score:</B>"},
		{value => $$gene{'Score'}}] if ($$gene{'Score'});

  my @adc_table = ();
  
  require db::adc;
  my @adcs = db::adc::fetch($$gene{'gid'});

  foreach my $adc (@adcs) {
    my @res;

#    print STDERR "$conf::basedir$order{$$adc{'source'}}{'report_dir'}gid:$$gene{'gid'}.blast\n";

    if (-e "$conf::basedir$global::dborder{$$adc{'source'}}{'report_dir'}gid:$$gene{'gid'}.blast" ||
	-e "$conf::basedir$global::dborder{$$adc{'source'}}{'report_dir'}gid:$$gene{'gid'}.blast.gz") {

      my $href = "../cbin/mutagen.pl?page=misc&showreport=$global::dborder{$$adc{'source'}}{'report_dir'}gid:$$gene{'gid'}.blast";
      $href .= &access::session_link();

      push @res, [{value =>$global::dborder{$$adc{'source'}}{'name'}},
		  {value =>"<A HREF='$href'>$$adc{'name'}</A>", colspan=>3},
		  {value =>$global::dborder{$$adc{'source'}}{'score'}}, {value =>$$adc{'score'}}];

      if ($$adc{'source'} eq "cog") {
	$$adc{'name'} =~ /(COG\d+)/;
	push @res, [{value =>"<B>COG class</B>"},
		    {value =>"<A HREF='http://www.ncbi.nlm.nih.gov/COG/new/release/cow.cgi?cog=$1'>$$adc{'other'}</A>", colspan=>5}];

      }

    }
    elsif (-e "$conf::basedir$global::dborder{$$adc{'source'}}{'report_dir'}gid:$$gene{'gid'}.pfam" ||
	-e "$conf::basedir$global::dborder{$$adc{'source'}}{'report_dir'}gid:$$gene{'gid'}.pfam.gz") {

      my $href = "../cbin/mutagen.pl?page=misc&showreport=$global::dborder{$$adc{'source'}}{'report_dir'}gid:$$gene{'gid'}.pfam";      
      $href .= &access::session_link();

      push @res, [{value =>$global::dborder{$$adc{'source'}}{'name'}},
		  {value =>"<A HREF='$href'>$$adc{'name'}</A>".
		       " <A HREF=http://pfam.wustl.edu/cgi-bin/getdesc?name=$$adc{'other'} target=_PFAM>PFAM dscr</A>", colspan=>3},
		  {value =>$global::dborder{$$adc{'source'}}{'score'}}, {value =>$$adc{'score'}}];
    }
    #
    # This we cannot easily check with the file checker, so lets see if there is a report in the 
    # returned array from ADC. This time the pfam stuff.
    elsif ($conf::dbreports && $$adc{report} && $$adc{source} eq "pfam") {

      my $href = "../cbin/mutagen.pl?page=misc&gid=$$gene{'gid'}&showreportdb=$$adc{source}";
      $href .= &access::session_link();

      push @res, [{value =>$global::dborder{$$adc{'source'}}{'name'}},
		  {value =>"<A HREF='$href'>$$adc{'name'}</A>".
		       " <A HREF=http://pfam.wustl.edu/cgi-bin/getdesc?name=$$adc{'other'} target=_PFAM>PFAM dscr</A>", colspan=>3},
		  {value =>$global::dborder{$$adc{'source'}}{'score'}}, {value =>$$adc{'score'}}];
    }
    #
    # This we cannot easily check with the file checker, so lets see if there is a report in the 
    # returned array from ADC.
    elsif ($conf::dbreports && $$adc{report} && $$adc{source}) {

      my $href = "../cbin/mutagen.pl?page=misc&gid=$$gene{'gid'}&showreportdb=$$adc{source}";
      $href .= &access::session_link();

      push @res, [{value =>$global::dborder{$$adc{'source'}}{'name'}},
		  {value =>"<A HREF='$href'>$$adc{'name'}</A>", colspan=>3},
		  {value =>$global::dborder{$$adc{'source'}}{'score'}}, {value =>$$adc{'score'}}];
      
    }
    else {
      push @res, [{value =>$global::dborder{$$adc{'source'}}{'name'}},
		  {value =>$$adc{'name'}, colspan=>3},
		  {value =>$global::dborder{$$adc{'source'}}{'score'}}, {value =>$$adc{'score'}}];
    }


    $adc_table[$global::dborder{$$adc{'source'}}{position}] = \@res;
  }

  foreach my $adc (@adc_table) {
    push @cells, @$adc if $adc;
  }

  # see if the gene is part of one or more pathways....
  
  require db::pathways;
  my $pathways = &db::pathways::pathways_by_gid($$gene{'gid'});
  if (@$pathways) {
    foreach my $pathway (@$pathways){
      
      $pathway = "<A HREF='mutagen.pl?page=sequence&subpage=pathways&pid=$$pathway{'pid'}".
	  &access::session_link()."' TARGET=pathway>$$pathway{'description'}</A>";
    }
    my $pathway_list = join("&nbsp;&nbsp;", @$pathways);
    
    push @cells, [{value=>"<B>Pathways</B>"},
		  {value =>$pathway_list, colspan=>5}];
  }



  my $html = html::advanced_table(\@cells, 1, 1, 1, undef, 1, "980", "menu");

  return  $html;
}


#
# The small toolbar above the GENE information
#
sub fid_tools {
  my ($fid) = @_;

  return &access::no_access if (&access::check_access(undef, undef, undef, $fid));

  my $href = "../cbin/mutagen.pl?fid=$fid";
  $href .= "&seid=$html::parameters{'seid'}" if ($html::parameters{'seid'});

  my $html = "";

  my @links = ();
  push @links, {name=>"Get sequence", link=>"$href&page=misc&gene_seq=1",  
		target => "bottom", group=>""};

  push @links, {name=>"Get flanked sequence", link=>"$href&page=misc&gene_flank=1",  
		target => "bottom", group=>""};

  push @links, {name=>"Delete genefinding", link=>"$href&page=misc&delete_genefinder=1", 
		target => "bottom", group=>"user"};

  push @links, {name=>"Alter gene", link=>"$href&page=misc&change_finder_start=1",  
		target => "bottom", group=>"user"};

  # Change the array to a table.
  my @cells = ();
  foreach my $link (@links) {
    
    next if ($$link{group} && !access::uid_group($html::parameters{uid}, $$link{group}));

    push @cells, {value=>"<A HREF=\'$$link{'link'}\' target='$$link{'target'}'>$$link{name}</A>", bgcolor=>"#666666"};
  }

  $html .= html::style::center(html::advanced_table([\@cells], 1, 1, 1, "#888888", 0, "98%", "menu"));

  return $html;
}

#
# Basic genefinder information, it is possible to select between a normal, 
# compressed and full version of this.
#
sub fid_info {
  my ($fid) = @_;

  return &access::no_access if (&access::check_access(undef, undef, undef, $fid));

  require db::genefinder;
  my $genefinder = &db::genefinder::fetch($fid);
  
  my @cells;

  $$genefinder{'org_name'} =~ s/^(.)\w+ (.*)/$1. $2/;
  push @cells, [{value =>"<B>Source:</B>"}, {value =>$$genefinder{'source'}, colspan => 9}];


  push @cells, [{value => "<B>Genefinder name:</B>"}, {value => $$genefinder{'name'}}, 
		{value =>"<B>gid:</B>"}, {value =>$$genefinder{'gid'}},
		{value => "<B>Gene length ".($$genefinder{'type'} eq "ORF" ? "(AA)" : "(DNA)") .":</B>"},
		{value => $$genefinder{'type'} eq "ORF" ? (1+$$genefinder{'stop'} - $$genefinder{'start'})/3 :
		     (1+$$genefinder{'stop'} - $$genefinder{'start'})}
		];

  push @cells, [{value => "<B>Genefinder start:</B>"}, {value => $$genefinder{'strand'} ? 
							    $$genefinder{'stop'} : $$genefinder{'start'}},
		{value =>"<B>Genefinder stop:</B>"},   {value => $$genefinder{'strand'} ? 
							    $$genefinder{'start'} : $$genefinder{'stop'}},
		{value =>"<B>Genefinder strand:</B>"}, {value =>$$genefinder{'strand'} ? "Minus" : "Plus"}];

  push @cells, [{value =>"<B>Genefinder score:</B>"}, {value =>$$genefinder{'Score'}}] 
      if ($$genefinder{'Score'});

  my $html = html::advanced_table(\@cells, 1, 1, 1, undef, 1, "700", "menu");

  return  $html;
}

# 
# Shows the annotations for a gene, it is possible to just show the last annotation.
# 
# Kim Brugger (11 Dec 2003)
# Altered the 18 Dec 2003, Kim Brugger
sub annotation_info  {
  my ($gid, $last) = @_;

  return &access::no_access if (&access::check_access($gid));

  require db::annotation;
  
#  my @annotations = &db::annotation::all($gid, $last);
  my @annotations = &db::annotation::all($gid);
  
  return "" if (@annotations == 0);

  my $html = "<BR>";
  
  foreach my $annotation (@annotations) {

    next if ($$annotation{'state'} && $$annotation{'state'} eq "deleted");

    # build a top header with tools.
    my $href = "../cbin/mutagen.pl?page=annotate&gid=$html::parameters{'gidinfo'}";
    $href .= "&seid=$html::parameters{'seid'}" if ($html::parameters{'seid'});

    my @links = ();
    
#    &core::Dump($annotation);
   
    if (! $$annotation{final} || $$annotation{final} == 0) {
      push @links, {name=>"Finalise", link=>"$href&finalise=1&aid=$$annotation{'aid'}", 
		    target => "bottom", group=>"user"};
    }
    else {
      push @links, {name=>"Un-finalise", link=>"$href&unfinalise=1&aid=$$annotation{'aid'}", 
		    target => "bottom", group=>"admin"};
    }
      
    push @links, {name=>"Edit", link=>"$href&edit=1&aid=$$annotation{'aid'}",
		  target => "annotate", group=>"user"};
    
    push @links, {name=>"Delete", link=>"$href&delete=1&aid=$$annotation{'aid'}",
		  target => "bottom", group=>"user"};

#    push @links, {name=>"Transfer", link=>"$href&transfer=1&aid=$$annotation{'aid'}",
#		  target => "bottom", group=>""};
    
    my @cells1 = ();
    foreach my $link (@links) {
      next if ($$link{group} && !access::uid_group($html::parameters{uid}, $$link{group}));

      push @cells1, {value=>"<A HREF='$$link{link}' target='$$link{target}'>$$link{name}</A>", 
		     bgcolor=>"#888888"};
    }

    $html .= (html::advanced_table([\@cells1], 1, 1, 1, "#aaaaaa", 0, "700","menu")) if (@cells1);


    $$annotation{'datetime'} = &core::datetime2date($$annotation{'datetime'});
    $$annotation{'start_codon'} = 1 if (!$$annotation{'start_codon'});
    $$annotation{'EC_number'} = "-.-.-.-" if (!$$annotation{'EC_number'});
    $$annotation{'uid'} = "--" if (!$$annotation{'uid'});
    my @cells;

    $$annotation{'gene_name'} = "&nbsp;" if (!$$annotation{'gene_name'});

    push @cells, [{value=> "<B>Gene product:</B>"}, {value=> $$annotation{'gene_product'}, colspan => 3},
		  {value=> "<B>Gene name:</B>"}, {value=> $$annotation{'gene_name'}},
		  {value=> "<B>EC number:</B>"}, {value=> $$annotation{'EC_number'}},
		  {value=> "<B>Start codon:</B>"}, {value=> $$annotation{'start_codon'}}];

#    push @cells, [
#		  {value=> "<B>EC number:</B>"}, {value=> $$annotation{'EC_number'}},
#		  {value=> "<B>Start codon:</B>"}, {value=> $$annotation{'start_codon'}}];

    push @cells, [{value=> "<B>Comment:</B>"}, {value=> $$annotation{'comment'}, colspan => 9}] 
	if ($$annotation{'comment'});

    push @cells, [{value=> "<B>Evidence:</B>"}, {value=> $$annotation{'evidence'}, colspan => 9}]
	if ($$annotation{'evidence'});

#    push @cells, [{value=> "<B>Primary function:</B>"}, {value=> $$annotation{'primary_function'}, colspan => 9}];

#    push @cells, [{value=> "<B>Secondary function:</B>"}, {value=> $$annotation{'secondary_function'}, colspan => 9}];

    push @cells, [{value=> "<B>Function category:</B>"}, {value=> "$$annotation{'secondary_function'}", colspan => 9}] if ($$annotation{'primary_function'}||$$annotation{'secondary_function'});


    push @cells, [{value=> "<B>Confidence in function:</B>"}, {value=> $$annotation{'conf_in_func'}},
		  {value=> "<B>Confidence in gene:</B>"}, {value=> $$annotation{'conf_in_gene'}},
		  {value=> "<B>TAG:</B>"}, {value=> $$annotation{'TAG'} ? "Yes" : "No"}] if (0);



    push @cells, [{value=> "<B>Conf. in function:</B>"}, {value=> $$annotation{'conf_in_func'}},
		  {value=> "<B>Conf. in gene:</B>"}, {value=> $$annotation{'conf_in_gene'}},
		  {value=> "<B>TAG:</B>"}, {value=> $$annotation{'TAG'} ? "Yes" : "No"}] 
		      if ($$annotation{'conf_in_func'} || 
			  $$annotation{'conf_in_gene'} || 
			  $$annotation{'TAG'});

    
    push @cells, [{value=> "<B>Annotators name</B>"}, {value=> $$annotation{'annotator_name'}, colspan => 3},
		  {value=> "<B>uid</B>"}, {value=> $$annotation{'uid'}},
		  {value=> "<B>Annotation date:</B>"},{value=> $$annotation{'datetime'}, colspan => 9}]
		      if (!($conf::html_level & $conf::html_light));

    if (0) {
    push @cells, [{value=> "<B>State</B>"}, {value=> $$annotation{'state'}},
		  {value=> "<B>Aid:</B>"}, {value=> $$annotation{'aid'}, colspan => 1},
		  {value=> "<B>Finalised</B>"}, {value=> $$annotation{'final'} ? "Yes":"No"}];
  }
#  push @cells, ["", $$annotation{''}];

#    $html .= &html::advanced_table(\@cells, 1, 1, 1, undef, "30%")."<BR>\n";

    $html .= &html::advanced_table(\@cells, 1, 1, 1, undef, 1, "980","menu")."<BR\n>";
  }

  return $html;
}



# 
# Shows the annotations for a gene, it is possible to just show the last annotation.
# 
# Kim Brugger (11 Dec 2003)
# Altered the 18 Dec 2003, Kim Brugger
sub wiki_entry  {
  my ($gid, $last) = @_;

  return &access::no_access if (&access::check_access($gid));

  require db::gene;
  require MediaWiki;

  my $gene_ref = &db::gene::fetch( $gid );
  my $ORFname = $$gene_ref{ name };

  # connect to the wiki.
  my $mw = MediaWiki->new(
			  host  => 'wiki.sulfolobus.org/',
#                            host  => 'en.wikipedia.org/',
			  path  => 'wiki/', # Can be empty on 3rd-level domain Wikis
			  debug => 0,# Optional. 0=no debug msgs, 1=some msgs, 2=more msgs
			  );


  
  my $entry_lines_ref = $mw->getHtmlPage(title => "$ORFname", section => '');
  my $entry = join("\n",@$entry_lines_ref);


  $entry =~ s/\<a /<a class='wikilink' /mg;
  $entry =~ s/class="external text"//mg;

  my @cells = ();
  push @cells, [{value => "<a href='http://wiki.sulfolobus.org/wiki/$ORFname'> <img src='../graphics//annotation.png'></a>\n"}];
  push @cells, [{value => $entry}];

  my $html .= "<BR>". &html::advanced_table(\@cells, 0, 0, 0, undef, 1, "980","wiki")."<BR\n>";
  

  return $html;
}



#
# The small toolbar above the GENE information
#
sub gid_tools {

  return &access::no_access if (&access::check_access($html::parameters{'gidinfo'}, undef, undef, undef));

  my $href = "../cbin/mutagen.pl?gid=$html::parameters{'gidinfo'}";
  $href .= "&seid=$html::parameters{'seid'}" if ($html::parameters{'seid'});

  my $html;

  my @links = ();


  require db::gene;
  my $gene = &db::gene::fetch($html::parameters{'gidinfo'});

  # Check and see if the gene is member of a cluster.
  if ($$gene{'cid'}) {
    require db::cluster;
    
    my $genes = &db::cluster::fetch($$gene{'cid'});
    
    push @links, {name=>"Gene cluster", link=>"$href&cid=$$gene{'cid'}&page=cluster", 
		target => "bottom", group=>""};

  }

  push @links, {name=>"Annotate", link=>"$href&page=annotate&annotate=$html::parameters{'gidinfo'}", 
		target => "annotate", group=>"user"};

  push @links, {name=>"Get gene sequence", link=>"$href&page=misc&gene_seq=1",  
		target => "bottom", group=>""};

  push @links, {name=>"Get flanked sequence", link=>"$href&page=misc&gene_flank=1",  
		target => "bottom", group=>""};

  push @links, {name=>"ORF browser", link=>"$href&page=sequence&subpage=browse&ORFmap=$html::parameters{'gidinfo'}",  
		target => "_top", group=>""};

  push @links, {name=>"Sequence browser", link=>"$href&page=sequence&subpage=browse&RAWmap=$html::parameters{'gidinfo'}",    
		target => "seq_browser", group=>""};

#  push @links, {name=>"Full/Compressed view", link=>"$href&page=sequence&full_view=1",  
#		target => "bottom", group=>""};

  push @links, {name=>"Delete gene", link=>"$href&page=misc&delete_gene=1", 
		target => "bottom", group=>"user"};

  push @links, {name=>"Alter gene", link=>"$href&page=misc&change_start=1",  
		target => "bottom", group=>"user"};


  push @links, {name=>"Genefinders", link=>"$href&page=sequence&subpage=browse&gfinders=1",
		target => "gfinders", group=>""} if (!($conf::html_level & $conf::html_light));


  # Change the array to a table.
  my @cells = ();
  foreach my $link (@links) {
    next if ($$link{group} && !access::uid_group($html::parameters{uid}, $$link{group}));

    push @cells, {value=>"<A HREF=\'$$link{'link'}\' target='$$link{'target'}'>$$link{name}</A>", bgcolor=>"#666666"};
  }

  $html .= html::style::center(html::advanced_table([\@cells], 1, 1, 1, "#888888", 0, "98%","menu"));

  return $html;
}


# 
# Extracts the sequence for a gene, and returns the sequence (even translated)
# 
# Kim Brugger (25 Nov 2003)
# 
sub gene_seq {
  my ($gid, $fid) = @_;

  
  my $html = "";

  if ($gid) {
    return &access::no_access if (&access::check_access($gid, undef, undef, undef));

    require db::gene;
    my $gene = &db::gene::fetch($gid);
    
    $html = "<PRE>>gid:$$gene{'gid'} $$gene{'name'}\n";
    $html .= &kernel::nicefasta($$gene{'sequence'});
    
    $html .= ">gid:$$gene{'gid'} $$gene{'name'}\n";
    $$gene{'sequence'} = &kernel::translate($$gene{'sequence'});
    $html .= &kernel::nicefasta($$gene{'sequence'}) . "<PRE>";
  }
  elsif ($fid) {
    return &access::no_access if (&access::check_access(undef, undef, undef, undef, $fid));
    require db::genefinder;
    my $genefinder = &db::genefinder::fetch($fid);
    
    $html = "<PRE>>fid:$$genefinder{'fid'} $$genefinder{'name'}\n";
    $html .= &kernel::nicefasta($$genefinder{'sequence'});
    
    $html .= ">fid:$$genefinder{'fid'} $$genefinder{'name'}\n";
    $$genefinder{'sequence'} = &kernel::translate($$genefinder{'sequence'});
    $html .= &kernel::nicefasta($$genefinder{'sequence'}) . "<PRE>";
  }

  return $html;
}


# 
# Enables the user to extract sequence surounding a gene (or any fragment)
# 
# Kim Brugger (25 Nov 2003)
sub gene_flank {
  my ($gid, $fid) = @_;

  return &access::no_access if ($gid && &access::check_access($gid, undef, undef, undef));
  return &access::no_access if ($fid && &access::check_access(undef, undef, undef, $fid));


  my $html;
  #
  # Check and se if the user have selected a range, otherwise make a form.
  #
  if ($html::parameters{'get_flank'}) {
    require db::sequence;

    $html = "<h1>FLANKED SEQUENCE</h1>";

    $html .= "<PRE>";
    if ($html::parameters{'start'} < $html::parameters{'stop'}) {
      my $subseq = &db::sequence::sub_sequence($html::parameters{'sid'}, 
					       $html::parameters{'start'}-1,
					       $html::parameters{'stop'}-$html::parameters{'start'}+1);
      $html .= "\n>sid:$$subseq{'sid'} $$subseq{'name'}_$html::parameters{'start'}-$html::parameters{'stop'}\n";
      $html .= &kernel::nicefasta($$subseq{'sequence'}) . "\n";

      if ($html::parameters{'translate'} && $html::parameters{'translate'} eq "Yes") {
	$html .= ">sid:$$subseq{'sid'} $$subseq{'name'}_$html::parameters{'start'}-$html::parameters{'stop'}\n";
	$html .= &kernel::nicefasta(&kernel::translate($$subseq{'sequence'})). "\n";
      }
      elsif ($html::parameters{'translate'} && $html::parameters{'translate'} eq "Six") {
	$html .= &kernel::six_frames($$subseq{'sequence'}). "\n";
      }      

    }
    else {
      my $subseq = &db::sequence::sub_sequence($html::parameters{'sid'}, 
					       $html::parameters{'stop'}-1,
					       $html::parameters{'start'} - $html::parameters{'stop'} +1);

      $html .= ">sid:$$subseq{'sid'} $$subseq{'name'}_$html::parameters{'stop'}-$html::parameters{'start'}\n";
      $html .= &kernel::nicefasta(&core::revDNA($$subseq{'sequence'})) ."\n";

      if ($html::parameters{'translate'} && $html::parameters{'translate'} eq "Yes") {
	$html .= ">sid:$$subseq{'sid'} $$subseq{'name'}_$html::parameters{'start'}-$html::parameters{'stop'}\n";
	$html .= &kernel::nicefasta(&kernel::translate(&kernel::revDNA($$subseq{'sequence'}))) ."\n";
      }
      elsif ($html::parameters{'translate'} && $html::parameters{'translate'} eq "Six") {
	$html .= &kernel::six_frames(&core::revDNA($$subseq{'sequence'})). "\n";
      }      
    }
    $html .= "</PRE>";
  }
  else {
    require db::gene;
    require db::genefinder;

    my @cells;
    my $gene;
    $gene = &db::genefinder::fetch($fid) if ($fid);
    $gene = &db::gene::fetch($gid) if ($gid);
    
    my $default = $$gene{'strand'} ? $$gene{'stop'} : $$gene{'start'};
    print STDERR "DEFAULT :: $default ($gid, $fid)\n";
    push @cells, [{value=>"Start position:"}, 
		 {value=>&html::generic_form_element({type=>"text", 
						      name=>"start", 
						      value=>$default})}];
    $default = $$gene{'strand'} ? $$gene{'start'} : $$gene{'stop'};

    push @cells, [{value=>"Stop position:"}, 
		  {value=>&html::generic_form_element({type=>"text", 
						      name=>"stop", 
						      value=>$default})}];

    push @cells,  [{value=>"Translate:"}, 
		   {value=>&html::generic_form_element({type=>"radio", 
							name=>"translate", 
							value=>"No",
							checked=>1})."No".
		    &html::generic_form_element({type=>"radio",
						 name=>"translate", 
						 value=>"Yes"}). "Yes".
		    &html::generic_form_element({type=>"radio",
						 name=>"translate", 
						 value=>"Six"}). "All frames"}];

    push @cells, [{value=>&html::generic_form_element({type=>"reset"})}, 
		  {value=>&html::generic_form_element({type=>"submit", 
						       name=>"get_flank", 
						       value=>"Submit"})}];

    $html .= "<h3>Extract sequence</h3>";
    $html .= &html::start_form();
    $html .= &html::advanced_table(\@cells, 1, 1, 1, undef, 1);

    $html .= &html::generic_form_element({type=>"hidden", name=>"sid",    value=>$$gene{'sid'}});
    $html .= &html::generic_form_element({type=>"hidden", name=>"gene_flank",    value=>"1"});
    $html .= &html::generic_form_element({type=>"hidden", name=>"page",    value=>"misc"});
    
    $html .= &access::session_form();
    $html .= &html::end_form();
  }

  return $html;
}



# 
# shows the reports in the database, either blast or pfam so far
# 
# Kim Brugger (09 Dec 2003)
sub show_report  {
  my ($report) = @_;

  my $html;
  require conf;

  my $o_report = $report;

  $report =~ /gid:(\d+)/;
  return &access::no_access if (&access::check_access($1, undef, undef, undef));
  
  if ($report =~ /^(reports\/\w+\/gid:\d+\.\w+)$/ &&
      not $conf::dbreports) {
    $report = $1;
    
    if ( -e $conf::basedir.$report ||
	 -e $conf::basedir.$report.".gz") {
      
      # check to see if the report is compressed, then uncompress it to a tmp file.
      if (-e $conf::basedir.$report.".gz") {
	
	my $tmp = &kernel::tmpfile();
	
	system "gunzip -c $conf::basedir$report.gz > $tmp";
	print STDERR "gunzip -c $conf::basedir$report.gz > $tmp\n";
	
	$report = $tmp;
      }   
      else {
	$report = $conf::basedir.$report;
      }
    }
  }
  elsif ($report =~ /^(reports\/\w+\/gid:\d+\.\w+)$/ &&
	  $conf::dbreports) {
      
    require db::adc;
    $report =~ /(\w+)\/gid:(\d+)\.(.*)/;

    my @adc = &db::adc::fetch($2, $1);
    $report = &kernel::tmpfile();

    open OUT, "> $report" or die "Could not open '$report': $!\n";
    print OUT $adc[0]->{report};
    close OUT;
  }
  else {
    return "<h3>Could not find the report</h3>";
  }

 
  use POSIX qw( tmpnam);
  require page::blast;
  my $tmpout    = &kernel::tmpname();
  
  # if it is a blast report, we make it nice and graphically
  if ($o_report =~ /blast/) {
    $html = page::blast::blast2html ($report, $tmpout);
  }
  # Other reports just gets displayed.
  elsif ($o_report =~ /pfam/) { 
    require parser::pfam;
    $html = "<h3>Pfam</h3><PRE>".(join("\n",parser::pfam::reformat ($report, $tmpout)))."</PRE>";
    
  }
  else {
    $html = "".page::blast::blast2html ($report, $tmpout);
  }
    
  return $html;
}


# 
# shows the reports from the database, either blast or pfam so far
# 
# Kim Brugger (09 Dec 2003)
sub show_dbreport  {
  my ($gid, $source) = @_;

  my $html;

  require db::adc;
  my @adc = &db::adc::fetch($gid, $source);
  my $report = &kernel::tmpfile();
  
  open OUT, "> $report" or die "Could not open '$report': $!\n";
  print OUT $adc[0]->{report};
  close OUT;

 
  use POSIX qw( tmpnam);
  require page::blast;
  my $tmpout    = &kernel::tmpname();
  
  # if it is a blast report, we make it nice and graphically
  if ($source =~ /blast/) {
    $html = page::blast::blast2html ($report, $tmpout);
  }
  # Other reports just gets displayed.
  elsif ($source =~ /pfam/) { 
    require parser::pfam;
    $html = "<h3>Pfam</h3><PRE>".(join("\n",parser::pfam::reformat ($report, $tmpout)))."</PRE>";
    
  }
  else {
    $html = "".page::blast::blast2html ($report, $tmpout);
  }
    
  return $html;
}




# 
# Add a new gene/feature to a sequence
# 
# Kim Brugger (25 Feb 2004)
sub add_gene {
  my ($sid, $start, $stop, $type, $strand) = @_;

  return &access::no_access if (&access::check_access(undef, $sid, undef, undef));


  require db::sequence;
  require db::gene;
  require db::genefinder;

  my $html = "";

  # first make sure that the start is lower than the stop.
  ($start, $stop) = ($stop, $start) if ($start > $stop);

  my $sequence = &db::sequence::fetch($sid);

  $$sequence{'name'} =~ s/^(.).*? (\w{3}).*/$1$2/;
  my $name = "$$sequence{'name'}\_";

  if ($strand eq "minus") {
    $name .= "$stop\-$start";
    $strand = 1;
  }
  else {
    $name .= "$start\-$stop";
    $strand = 0;
  }

  # Since we have the possibility for keeping the data from multiple gene finders
  # We first save this as a new finding and then updates the gene. 
  my %call_hash = (
		   'start'      => $start,
		   'stop'       => $stop,
		   'strand'     => $strand,
		   'sid'        => $sid,
		   'type'       => $type,
		   'name'       => $name,
		   'source'     => "Human",
		   'score'      => "0");

#  &core::Dump(\%call_hash);

  my $fid = &db::genefinder::save(\%call_hash);

  %call_hash = (
		'start'      => $start,
		'stop'       => $stop,
		'strand'     => $strand,
		'sid'        => $sid,
		'type'       => $type,
		'name'       => $name,
		'fid'        => $fid,
		'altstart'   => 1,
		'score'      => "0");


#  &core::Dump(\%call_hash);

  my $gid = &db::gene::save(\%call_hash);

  $html .= " Created a new gene/feature. Now named: $name with gid:$gid";

  return $html;
  
}

# 
# Alter the gene infomation, start, stop, type etc.
# 
# Kim Brugger (25 Feb 2004)
sub change_start {
  my ($gid, $start, $name, $type, $sure) = @_;

  return &access::no_access if (&access::check_access($gid, undef, undef, undef));

  require db::sequence;
  require db::gene;
  require db::genefinder;

  my $html = &mutagen_html::headline("Alter gene information");
  my $gene = &db::gene::fetch($gid);

  if (defined $sure && $sure eq "yes") {

    # Since we have the possibility for keeping the data from multiple gene finders
    # We first save this as a new finding and then updates the gene. 
    my %call_hash = (
		     'start'      => $$gene{strand} ? $$gene{start} : $start,
		     'stop'       => $$gene{strand} ? $start : $$gene{stop},
		     'strand'     => $$gene{strand},
		     'sid'        => $$gene{sid},
		     'type'       => $type || $$gene{type},
		     'name'       => $name || $$gene{name},
		     'source'     => "Human",
		     'gid'        => $$gene{gid},
		     'score'      => "0");
    
    my $fid = &db::genefinder::save(\%call_hash);
    
    $$gene{'fid'} = $fid;

    delete ($call_hash{'source'});
    $call_hash{'altstart'} = 1;
    $call_hash{'colour'}   = $$gene{colour};
    $call_hash{'fid'}      = $fid;
    $call_hash{'start'}    = $$gene{strand} ? $$gene{start} : $start;
    $call_hash{'type'}     = $type || $$gene{type};
    $call_hash{'name'}     = $name || $$gene{name};

    &db::gene::update(\%call_hash);
    
    $html .= " Altered the start position of gene/feature with gid:$$gene{'gid'} / $fid";

  }
  elsif ($sure eq "no") {
    $html .= "<H3>Alteration of gene cancelled</H3>";
  }
  elsif ($sure eq "choice") {
    $html .= &html::start_form();
    $html .= "<H3>";
    $html .= "Are you sure that you want to change this gene gid:$$gene{gid} with these changes:<BR>";
    $html .= "Start codon from '$$gene{start}' to '$start'<BR>";
    $html .= "Name '$$gene{name}' to '$name' <BR>";
    $html .= "Gene type from '$$gene{type}' to '$type' <BR>";
    $html .= "</H3>";

    $html .= &html::generic_form_element({type=>"radio", 
					  name=>"sure", 
					  value=>"yes"})."Yes";

    $html .= &html::generic_form_element({type=>"radio",
					  name=>"sure", 
					  value=>"no", 
					  checked=>1}). "No";
    
    $html .= "<BR>&nbsp;".&html::generic_form_element({type=>"submit", name => "change_start", 
						       value => "Update gene information"});
    
    $html .= "&nbsp;".&html::generic_form_element({type=>"hidden", name => "page", value => "misc"});

    $html .= "&nbsp;".&html::generic_form_element({type=>"hidden", name => "new_start", value => "$start"});
    $html .= "&nbsp;".&html::generic_form_element({type=>"hidden", name => "gene_type", value => "$type"});
    $html .= "&nbsp;".&html::generic_form_element({type=>"hidden", name => "new_name", value =>  "$name"});

    $html .= "&nbsp;".&html::generic_form_element({type=>"hidden", name => "gid", value => $gid});

    $html .= &access::session_form();
    $html .= &html::end_form();
  }
  else {
    
    my @cells;
    
    push @cells,  ["New gene name", 
		   &html::generic_form_element({type=>"text", 
						name=>"new_name", 
						value=>$$gene{name}})];
    push @cells,  ["New start position", 
		   &html::generic_form_element({type=>"text", 
						name=>"new_start", 
						value=>$$gene{strand} ? 
						    $$gene{stop} : $$gene{start}})];

    push @cells,  ["Gene type", &mutagen_html::forms::genetypes_popup($$gene{gid})];


    push @cells, ["&nbsp;", &html::generic_form_element({type=>"submit", 
							 name=>"change_start", 
							 value=>"Submit"})];
    
    $html .= &html::start_form();
    $html .= &html::table(\@cells, 1, 3, 3, undef);

    $html .= &html::generic_form_element({type=>"hidden", name=>"page",    value=>"misc"});
    $html .= &html::generic_form_element({type=>"hidden", name=>"gid", value=>"$gid"});
    $html .= &html::generic_form_element({type=>"hidden", name=>"sure", value=>"choice"});
    $html .= &access::session_form();
    $html .= &html::end_form();
    
  }
  return $html;

}

# 
# Alter start/stop  codon for a genefinder.
# 
# Kim Brugger (25 Feb 2004)
sub change_finder_start {
  my ($gid, $start, $sure) = @_;

  return &access::no_access if (&access::check_access($gid, undef, undef, undef));

  require db::sequence;
  require db::gene;
  require db::genefinder;

  my $html = &mutagen_html::headline("Change start/stop position for a genefinder");
  my $gene = &db::genefinder::fetch($gid);

  if ($sure && $sure eq "yes" && $start && $start > 0) {

#    &core::Dump($gene);
 
    
    # Since we have the possibility for keeping the data from multiple gene finders
    # We first save this as a new finding and then updates the gene. 

    print STDERR "$$gene{strand} --> $$gene{start}, $start\n";
    print STDERR "		     'start'      => $$gene{strand} ? $$gene{start} : $start,
		     'stop'       => $$gene{strand} ? $start : $$gene{stop},\n";

    my %call_hash = (
		     'start'      => $$gene{strand} ? $$gene{start} : $start,
		     'stop'       => $$gene{strand} ? $start : $$gene{stop},
		     'strand'     => $$gene{strand},
		     'sid'        => $$gene{sid},
		     'type'       => $$gene{type},
		     'source'     => "Human",
		     'score'      => "0");
    
#    &core::Dump(\%call_hash);
    
    my $fid = &db::genefinder::save(\%call_hash);
    
    
    $$gene{'fid'} = $fid;

    delete ($call_hash{'source'});
    $call_hash{'altstart'} = 1;
    $call_hash{'colour'}   = $$gene{colour};
    $call_hash{'fid'}      = $fid;

#    &core::Dump(\%call_hash);
    &db::gene::update(\%call_hash);
    
    $html .= " Altered the start position of gene/feature with gid:$$gene{'gid'} / $fid";

  }
  elsif ($sure eq "no") {
    $html .= "<H3>Change of start codon cancelled</H3>";
  }
  elsif ($sure eq "choice") {
    $html .= &html::start_form();
    $html .= "<H3>Are you sure that you want to change start codon from $$gene{start} to $start for this gene ?</H3>";

    $html .= &html::generic_form_element({type=>"radio", 
					  name=>"sure", 
					  value=>"yes"})."Yes";

    $html .= &html::generic_form_element({type=>"radio",
					  name=>"sure", 
					  value=>"no", 
					  checked=>1}). "No";
    
    $html .= "<BR>&nbsp;".&html::generic_form_element({type=>"submit", name => "change_start", 
						       value => "Change position"});
    
    $html .= "&nbsp;".&html::generic_form_element({type=>"hidden", name => "page", value => "misc"});
    $html .= "&nbsp;".&html::generic_form_element({type=>"hidden", name => "new_start", value => "$start"});
    $html .= "&nbsp;".&html::generic_form_element({type=>"hidden", name => "gid", value => $gid});

    $html .= &access::session_form();
    $html .= &html::end_form();
  }
  else {
    

    my @cells;
    
    push @cells,  ["New start position", 
		   &html::generic_form_element({type=>"text", 
						name=>"new_start", 
						value=>$$gene{strand} ? $$gene{stop} : $$gene{start}})];


    push @cells,  ["New stop position", 
		   &html::generic_form_element({type=>"text", 
						name=>"new_start", 
						value=>$$gene{strand} ? $$gene{start} : $$gene{stop}})];

    push @cells, ["&nbsp;", &html::generic_form_element({type=>"submit", 
							 name=>"change_start", 
							 value=>"Submit"})];
    
    $html .= &html::start_form();
    $html .= &html::table(\@cells, 1, 3, 3, undef);

    $html .= &html::generic_form_element({type=>"hidden", name=>"page",    value=>"misc"});
    $html .= &html::generic_form_element({type=>"hidden", name=>"gid", value=>"$gid"});
    $html .= &html::generic_form_element({type=>"hidden", name=>"sure", value=>"choice"});
    $html .= &access::session_form();
    $html .= &html::end_form();
    
  }
  return $html;

}


# 
# make it possible to delete a gene (or two)
# 
# Kim Brugger (25 Feb 2004)
sub delete_gene {
  my ($gid, $sure) = @_;

  return &access::no_access if (&access::check_access($gid, undef, undef, undef));
  my $html = &mutagen_html::headline("Delete gene");

  if ($sure && $sure eq "yes") { 
   
    my %call_hash = (gid => $gid,
		     show_gene => "deleted");
    
    require db::gene;
    &db::gene::update(\%call_hash);

    $html .= "<H3>Deleted the gene</H3>";

  }
  elsif ($sure && $sure eq "no") {
    
    $html .= "<H3>Deletion cancelled</H3>";
  }
  else {
    $html .= &html::start_form();
    $html .= "<H3>Are you sure that you want to delete this gene ?</H3>";

    $html .= &html::generic_form_element({type=>"radio", 
					  name=>"sure", 
					  value=>"yes"})."Yes";

    $html .= &html::generic_form_element({type=>"radio",
					  name=>"sure", 
					  value=>"no", 
					  checked=>1}). "No";
    
    $html .= "&nbsp;".&html::generic_form_element({type=>"submit", name => "delete_gene", value => "Delete"});
    
    $html .= "&nbsp;".&html::generic_form_element({type=>"hidden", name => "page", value => "misc"});
    $html .= "&nbsp;".&html::generic_form_element({type=>"hidden", name => "gid", value => $gid});
    $html .= &access::session_form();
    $html .= &html::end_form();
  }


  return $html;
}



BEGIN {

}

END {

}

1;


