#!/usr/bin/perl -wT
# 
# 
# 
# 
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;
use html;

package page::annotate;
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

my @secondary = (
		 "Information storage and processing",
		 "..Translation, ribosomal structure and biogenesis",
		 "..RNA processing and modification",
		 "..Transcription",
		 "..Replication, recombination and repair",
		 "..Chromatin structure and dynamics",

		 "Cellular processes and signaling",
		 "..Cell cycle control, cell division, chromosome partitioning",
		 "..Nuclear structure",
		 "..Defense mechanisms",
		 "..Signal transduction mechanisms",
		 "..Cell wall, membrane, envelope biogenesis",
		 "..Cell motility",
		 "..Cytoskeleton",
		 "..Extracellular structures",
		 "..Intracellular trafficking, secretion, and vesicular transport",
		 "..Posttranslational modification, protein turnover, chaperones",

		 "Metabolism",
		 "..Energy production and conversion",
		 "..Carbohydrate transport and metabolism",
		 "..Amino acid transport and metabolism",
		 "..Nucleotide transport and metabolism",
		 "..Coenzyme transport and metabolism",
		 "..Lipid transport and metabolism",
		 "..Inorganic ion transport and metabolism",
		 "..Secondary metabolites biosynthesis, transport and catabolism",

		 "Poorly Characterized",
		 "..General function prediction only",
		 "..Function unknown", 
		 "-- None selected --");

my %Full_secondary = (
		      "..Translation, ribosomal structure and biogenesis" => "Information storage and processing",
		      "..RNA processing and modification" => "Information storage and processing",
		      "..Transcription" => "Information storage and processing",
		      "..Replication" => "Information storage and processing",
		      "..Replication, recombination and repair" => "Information storage and processing",
		      "..Chromatin structure and dynamics" => "Information storage and processing",

		      "..Cell cycle control, cell division, chromosome partitioning" => "Cellular processes and signaling",
		      "..Nuclear structure" => "Cellular processes and signaling",
		      "..Defense mechanisms" => "Cellular processes and signaling",
		      "..Signal transduction mechanisms" => "Cellular processes and signaling",
		      "..Cell wall/membrane/envelope biogenesis" => "Cellular processes and signaling",
		      "..Cell motility" => "Cellular processes and signaling",
		      "..Cytoskeleton" => "Cellular processes and signaling",
		      "..Extracellular structures" => "Cellular processes and signaling",
		      "..Intracellular trafficking, secretion, and vesicular transport" => "Cellular processes and signaling",
		      "..Posttranslational modification, protein turnover, chaperones" => "Cellular processes and signaling",
		      
		      "..Energy production and conversion" => "Metabolism",
		      "..Carbohydrate transport and metabolism" => "Metabolism",
		      "..Amino acid transport and metabolism" => "Metabolism",
		      "..Nucleotide transport and metabolism" => "Metabolism",
		      "..Coenzyme transport and metabolism" => "Metabolism",
		      "..Lipid transport and metabolism" => "Metabolism",
		      "..Inorganic ion transport and metabolism" => "Metabolism",
		      "..Secondary metabolites biosynthesis, transport and catabolism" => "Metabolism",
		      
		      "..General function prediction only" => "Poorly Characterized",
		      "..Function unknown" => "Poorly Characterized", 
		      
		      );


sub run {
  my $html;
  
  return &core::no_access if (&access::check_access($html::parameters{gid}, undef, undef, undef));

  if ($html::parameters{'class1'} ||
      $html::parameters{'class2'} ||
      $html::parameters{'class3'} ||
      $html::parameters{'class4'} ||
      $html::parameters{'class5'}) {

    return(&annotation_page());

  }
  elsif ($html::parameters{'saveAnno'} || $html::parameters{'update_annotation'}) {
    $html = save_annotation();
  }
  elsif ($html::parameters{'delete'}) {
    $html = delete_annotation();
  }
  elsif ($html::parameters{'finalise'}) {
    $html = finalise_annotation();
  }
  elsif ($html::parameters{'unfinalise'}) {
    $html = unfinalise_annotation();
  }
  else {
    return(&annotation_page());
  }


  return $html;
}



# 
# For for finalising a annotation for a gene
# 
# Kim Brugger (18 Dec 2003)
sub finalise_annotation  {

  return $access::no_access if (&access::check_access($html::parameters{gid}, undef, undef, undef));

  my $html = "";

  if ($html::parameters{'finalise_gene'} && 
      $html::parameters{'finalise'} && 
      $html::parameters{'finalise'} eq "Yes") {
    
    my %call_hash = (aid => $html::parameters{'aid'}, 
		     final => "1");
    require db::annotation;
    &db::annotation::update(\%call_hash);

    $html .= "<H3>Finalised the annotation</H3>";

  }
  elsif ($html::parameters{'finalise_gene'}) {
    
    $html .= "<H3>Finalisation cancelled</H3>";
  }
  else {
    $html .= &html::start_form();
    $html .= "<H3>Are you sure that you want to finalise this annotation ?</H3>";
    $html .= &html::generic_form_element({type=>"radio", 
					  name=>"finalise", 
					  value=>"Yes"})."Yes".
		    &html::generic_form_element({type=>"radio",
						 name=>"finalise", 
						 value=>"No", 
						 checked=>1}). "No";
    
    $html .= "&nbsp;".&html::generic_form_element({type=>"submit", name => "finalise_gene", value => "Finalise"});
    
    $html .= "&nbsp;".&html::generic_form_element({type=>"hidden", name => "page", value => "annotate"});
    $html .= "&nbsp;".&html::generic_form_element({type=>"hidden", name => "aid", value => $html::parameters{'aid'}});
  }

  $html .= &html::end_form();
}

# 
# For for unfinalising a annotation for a gene
# 
# Kim Brugger (18 Dec 2003)
sub unfinalise_annotation  {

  my $html = "";

  if ($html::parameters{'unfinalise_gene'} && 
      $html::parameters{'unfinalise'} && 
      $html::parameters{'unfinalise'} eq "Yes") {
    
    my %call_hash = (aid => $html::parameters{'aid'}, 
		     final => "0");
    require db::annotation;
    &db::annotation::update(\%call_hash);

    $html .= "<H3>Un-finalised the annotation</H3>";

  }
  elsif ($html::parameters{'ufinalise_gene'}) {
    
    $html .= "<H3>Un-finalisation cancelled</H3>";
  }
  else {
    $html .= &html::start_form();
    $html .= "<H3>Are you sure that you want to un-finalise this annotation ?</H3>";
    $html .= &html::generic_form_element({type=>"radio", 
					  name=>"unfinalise", 
					  value=>"Yes"})."Yes".
		    &html::generic_form_element({type=>"radio",
						 name=>"unfinalise", 
						 value=>"No", 
						 checked=>1}). "No";
    
    $html .= "&nbsp;".&html::generic_form_element({type=>"submit", name => "unfinalise_gene", value => "Un-finalise"});
    
    $html .= "&nbsp;".&html::generic_form_element({type=>"hidden", name => "page", value => "annotate"});
    $html .= "&nbsp;".&html::generic_form_element({type=>"hidden", name => "aid", value => $html::parameters{'aid'}});
  }

  $html .= &html::end_form();
}

# 
# For for deleting an annotation for a gene
# 
# Kim Brugger (18 Dec 2003)
sub delete_annotation  {

  my $html = "";

  if ($html::parameters{'delete_gene'} && 
      $html::parameters{'delete'} && 
      $html::parameters{'delete'} eq "Yes") {
    
    my %call_hash = (aid => $html::parameters{'aid'}, 
		     state => "deleted");

    require db::annotation;
    &db::annotation::update(\%call_hash);

    $html .= "<H3>Deleted the annotation</H3>";

  }
  elsif ($html::parameters{'delete_gene'}) {
    
    $html .= "<H3>Deletion cancelled</H3>";
  }
  else {
    $html .= &html::start_form();
    $html .= "<H3>Are you sure that you want to delete this annotation ?</H3>";
    $html .= &html::generic_form_element({type=>"radio", 
					  name=>"delete", 
					  value=>"Yes"})."Yes".
		    &html::generic_form_element({type=>"radio",
						 name=>"delete", 
						 value=>"No", 
						 checked=>1}). "No";
    
    $html .= "&nbsp;".&html::generic_form_element({type=>"submit", name => "delete_gene", value => "Delete"});
    
    $html .= "&nbsp;".&html::generic_form_element({type=>"hidden", name => "page", value => "annotate"});
    $html .= "&nbsp;".&html::generic_form_element({type=>"hidden", name => "aid", value => $html::parameters{'aid'}});
  }

  $html .= &html::end_form();
}



# 
# Save the information that was placed into the annotation form.
# 
# Kim Brugger (10 Dec 2003)
sub save_annotation  {

  my $html = "<H3>Saved annotation</h3>";

  my %call_hash = ( gid => $html::parameters{'gid'});

  $call_hash{'gene_name'} = $html::parameters{'gene_name'} if ($html::parameters{'gene_name'});
  $call_hash{'start_codon'} = $html::parameters{'start_codon'} if ($html::parameters{'start_codon'} =~ /^\d+$/);
  $call_hash{'conf_in_gene'} = $html::parameters{'gconf'} if ($html::parameters{'gconf'});
  $call_hash{'EC_number'} = $html::parameters{'ec'} if ($html::parameters{'ec'});
  $call_hash{'conf_in_func'} = $html::parameters{'fconf'} if ($html::parameters{'fconf'});
  $call_hash{'gene_product'} = $html::parameters{'product'} if ($html::parameters{'product'});
  $call_hash{'comment'} = $html::parameters{'comment'} if ($html::parameters{'comment'});
  $call_hash{'evidence'} = $html::parameters{'evidence'} if ($html::parameters{'evidence'});
  $call_hash{'primary_function'} = undef;#$html::parameters{'primary'} if ($html::parameters{'primary'});

  if ($html::parameters{'secondary'}) {
    $call_hash{'secondary_function'} = $html::parameters{'secondary'}; 
    my $full = $Full_secondary{$call_hash{'secondary_function'}};
    $call_hash{'secondary_function'} =~ s/\.\./\//;
    $call_hash{'secondary_function'} = "$full$call_hash{'secondary_function'}";
  }

  $call_hash{'TAG'} = 1 if ($html::parameters{'tag'} && $html::parameters{'tag'} eq "on");

#  $call_hash{'annotator_name'} = $html::parameters{''} if ($html::parameters{''})
#  $call_hash{'uid'} = $html::parameters{''} if ($html::parameters{''})
#  $call_hash{''} = $html::parameters{''} if ($html::parameters{''})
  
  require db::annotation;

  my $aid;
  if ($html::parameters{'update_annotation'}) {
    $call_hash{aid} = $html::parameters{'update_annotation'};
    $aid = &db::annotation::update(\%call_hash);
  }
  else {
    $aid = &db::annotation::save(\%call_hash);
  }
  require mutagen_html::subpage;
  $html .= &mutagen_html::subpage::annotation_info($html::parameters{'gid'}, 1);

  print STDERR "AID == $aid";

  my $annotation = &db::annotation::fetch($aid);

  my @cells;
  push @cells, ["Annotation date:", &core::datetime2date($$annotation{'datetime'})];


  push @cells, ["Aid:", $aid];
  push @cells, ["Start codon:", $$annotation{'start_codon'}];
  push @cells, ["Confidence in gene:", $$annotation{'conf_in_gene'}];
  push @cells, ["Gene name:", $$annotation{'gene_name'}];
  push @cells, ["Gene product:", $$annotation{'gene_product'}];
  push @cells, ["EC number:", $$annotation{'EC_number'}];
  push @cells, ["Confidence in function:", $$annotation{'conf_in_func'}];
  push @cells, ["Comment:", $$annotation{'comment'}];
  push @cells, ["Evidence:", $$annotation{'evidence'}];
  push @cells, ["Primary function:", $$annotation{'primary_function'}];
  push @cells, ["Secondary function:", $$annotation{'secondary_function'}];
  push @cells, ["TAG:", $$annotation{'TAG'} ? "Yes" : "No"];
  push @cells, ["Finalised", $$annotation{'final'} ? "Yes":"No"];
  push @cells, ["Annotators name", $$annotation{'annotator_name'}];
  push @cells, ["uid", $$annotation{'uid'}];
  push @cells, ["State", $$annotation{'state'}];
#  push @cells, ["", $$annotation{''}];



  return $html .= &html::table(\@cells, 1, 3, 1, undef, "60%");

}




# 
# The annotation page, with all the nice small box'es
# 
# Kim Brugger (28 Nov 2003)
sub annotation_page  {

  my ($gid, $values) = ($html::parameters{'gid'}, \%html::parameters);

  my $html = "";
  
  my @cells;

  require mutagen_html;
  $html .= &mutagen_html::forms::blast_buttons($gid);

  
  my $form .= &html::start_form("../cbin/mutagen.pl");  


  my $gene_product_default = "";
  my $gene_name_default = "";
  my $comment_default = "";
  my $EC_default = "";
  my $start_default = "1";
  my $evidence_default = "";
  my $primary_default = "-- None selected --";
  my $secondary_default = "-- None selected --";
  my $gene_confidence_default = "-- None selected --";
  my $function_confidence_default = "-- None selected --";
  my $TAG = 0;

  if (($html::parameters{'class1'} || 
      $html::parameters{'class2'} || 
      $html::parameters{'class3'} || 
      $html::parameters{'class4'} || 
      $html::parameters{'class5'} || 
      $html::parameters{'edit'}) && $html::parameters{'aid'}) {


#    print STDERR "FETCHING PARAMETERS ..... \n";
    require db::annotation;
    my $aid = &db::annotation::fetch($html::parameters{'aid'});

    &core::Dump($aid);

    $gene_product_default = $$aid{'gene_product'} if ($$aid{'gene_product'});
    $gene_name_default = $$aid{'gene_name'} if ($$aid{'gene_name'});
    $comment_default = $$aid{'comment'} if ($$aid{'comment'});
    $EC_default = $$aid{'EC_number'} if ($$aid{'EC_number'});
    $start_default = $$aid{'start_codon'} if ($$aid{'start_codon'});
    $evidence_default = $$aid{'evidence'} if ($$aid{'evidence'});

#    $primary_default = $$aid{'primary_function'} if ($$aid{'primary_function'});

    if ($$aid{'secondary_function'}) {
      $secondary_default = $$aid{'secondary_function'};
      $secondary_default =~ s/.*?\//../;
    }

    $gene_confidence_default = $$aid{'conf_in_gene'} if ($$aid{'conf_in_gene'});
    $function_confidence_default = $$aid{'conf_in_func'} if ($$aid{'conf_in_func'});
    
    $TAG = $$aid{'TAG'} if ($$aid{'TAG'});

  }

  if ($html::parameters{'class1'} || 
      $html::parameters{'class2'} || 
      $html::parameters{'class3'} || 
      $html::parameters{'class4'} || 
      $html::parameters{'class5'}) {
    
    
    $secondary_default = "..Function unknown";
    
    $function_confidence_default ="Very unsure";  
    
    $gene_confidence_default = "Hypothetical"
	if ($html::parameters{'class1'} || 
	    $html::parameters{'class2'});
    
    $gene_confidence_default = "Confident"
	if ($html::parameters{'class3'} || 
	    $html::parameters{'class4'} || 
	    $html::parameters{'class5'});
    
    $gene_product_default = "Hypothetical protein" if ($html::parameters{'class1'});
    $gene_product_default = "protein similar to " if ($html::parameters{'class2'});
    $gene_product_default = "Conserved Crenarchaeal protein " if ($html::parameters{'class3'});
    $gene_product_default = "Conserved Archaeal protein " if ($html::parameters{'class4'});
    $gene_product_default = "Universally conserved protein " if ($html::parameters{'class5'});
  }


  push @cells, [{value=>"<a href='../annotation_help.html\#gname' target='manual'>Gene name</a>"},
		{value=>"<a href='../annotation_help.html\#start' target='manual'>Start codon</a>"},
		{value=>"<a href='../annotation_help.html\#gene_conf' target='manual'>Confidence in gene:</a>"}];
  
  my @gconf = ("Confirmed", "Confident", "Hypothetical", "Not a gene", "-- None selected --");

  push @cells, [{value=>&html::generic_form_element({type=>"text", name=>"gene_name", value=>$gene_name_default, size=>10})},
		{value=>&html::generic_form_element({type=>"text", name=>"start_codon", value=>$start_default})},
		{value=>&html::generic_form_element({type=>"popup", name=>"gconf", 
						     values=>\@gconf, default=> $gene_confidence_default})}];

  

  push @cells, [{value=>"<a href='../annotation_help.html\#gname' target='manual'>EC number</a>", colspan=>2},
		{value=>"<a href='../annotation_help.html\#start' target='manual'>Confidence in function</a>"}];

  my @fconf = ("Confirmed", 
	       "Very confident", 
	       "Confident", 
	       "Ambiguous", 
	       "Putative", 
	       "Very unsure",
	       "-- None selected --");


  push @cells, [{value=>&html::generic_form_element({type=>"text", name=>"ec", size=>10, value=>$EC_default}), colspan=>2},
		{value=>&html::generic_form_element({type=>"popup", name=>"fconf", 
						     values=>\@fconf, default=>$function_confidence_default})}];



  push @cells, [{value=>"<a href='../annotation_help.html\#gname' target='manual'>Gene product</a>", colspan=>3}];
  push @cells, [{value=>&html::generic_form_element({type=>"text", name=>"product", value=>$gene_product_default, size=>50}), colspan=>3}];

  push @cells, [{value=>"<a href='../annotation_help.html\#gname' target='manual'>Comment</a>", colspan=>3}];
  push @cells, [{value=>&html::generic_form_element({type=>"textarea", name=>"comment", rows=>5, cols=>50, value=>$comment_default}), colspan=>3}];
  
  push @cells, [{value=>"<a href='../annotation_help.html\#gname' target='manual'>Evidence</a>", colspan=>3}];
  push @cells, [{value=>&html::generic_form_element({type=>"text", name=>"evidence", value=>$evidence_default, size=>40}), colspan=>3}];


  push @cells, [{value=>"<a href='../annotation_help.html\#gname' target='manual'>Function category</a>", colspan=>3}];
  push @cells, [{value=>&html::generic_form_element({type=>"popup", name=>"secondary", 
						     values=>\@secondary, default=>$secondary_default}), colspan=>3}];


  push @cells, [{value=>&html::generic_form_element({type=>"checkbox", name=>"tag", checked => $TAG})."Note to sequencers: Recheck raw sequence", colspan=>3}];

  push @cells, [{value=>&html::generic_form_element({type=>"submit", name=>"saveAnno", value=>'Submit your annotation'}), colspan=>3}];


  $form .= &html::advanced_table(\@cells, 1, 5, 1, undef, 1);

  $form .= &html::generic_form_element({type=>"hidden", name=>"gid", value=>$gid});
  $form .= &html::generic_form_element({type=>"hidden", name=>"page", value=>"annotate"});

  if ($html::parameters{'edit'} && $html::parameters{'aid'}) {
    $form .= &html::generic_form_element({type=>"hidden", 
					  name=>"update_annotation", 
					  value=>$html::parameters{'aid'}});

    $form .= &html::generic_form_element({type=>"hidden", 
					  name=>"aid", 
					  value=>$html::parameters{'aid'}});
    
    $form .= &html::generic_form_element({type=>"hidden", 
					  name=>"edit", 
					  value=>$html::parameters{'aid'}});
  }



  if (1) {
    # This can be used for easing the annotation by having predetermined classes.
    $form .= &html::table([[&html::generic_form_element({type=>"submit", name=>"class1", value=>'Class 1'}),
			    &html::generic_form_element({type=>"submit", name=>"class2", value=>'Class 2'}),
			    &html::generic_form_element({type=>"submit", name=>"class3", value=>'Class 3'}),
			    &html::generic_form_element({type=>"submit", name=>"class4", value=>'Class 4'}),
			    &html::generic_form_element({type=>"submit", name=>"class5", value=>'Class 5'})]], 1, 2, 0);
  }

  $form .= &access::session_form();
  $form .= &html::end_form();
  require mutagen_html::subpage;
  return $html. &html::table([[$form, &mutagen_html::subpage::gid_info($gid)]], 1);
}


BEGIN {

}

END {

}

1;


