#!/usr/bin/perl -wT
# 
# Handles the acces for the sequences, so here we can add/delete groups for different sequences.
# 
# 
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;

package page::admin::sequences;
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

  $html .= &mutagen_html::headline("Handling of sequence");
  

  if ($html::parameters{'upload_seq'}) {
    $html .= upload_seq();
  }
  elsif ($html::parameters{'edit_seq'}) {
    $html .= edit_seq();
  }
  elsif ($html::parameters{'del_seq'}) {
    $html .= del_seq();
  }
  elsif ($html::parameters{'rename_seq'}) {
    $html .= rename_seq();
  }
  elsif ($html::parameters{'rename_genes'}) {
    $html .= rename_genes();
  }
  elsif ($html::parameters{'upload_info'}) {
    $html .= upload_info();
  }
  elsif ($html::parameters{'del_info'}) {
    $html .= del_info();
  }
  elsif ($html::parameters{'find_genes'}) {
    $html .= find_genes();
  }
  elsif ($html::parameters{'buildbs'}) {
    $html .= buildbs($html::parameters{'sure'});
  }
  elsif ($html::parameters{'del_dbs'}) {
    $html .= del_dbs($html::parameters{'sure'});
  }
  elsif ($html::parameters{'clusters'}) {
    $html .= clusters($html::parameters{'sure'});
  }
  elsif ($html::parameters{'orfinder'}) {
    $html .= orfinder($html::parameters{'sure'});
  }
  elsif ($html::parameters{'add_group_org'}) {
    $html .= add_group_org($html::parameters{'sure'});
  }
  elsif ($html::parameters{'del_group_org'}) {
    $html .= del_group_org($html::parameters{'sure'});
  }
  elsif ($html::parameters{'free_group_org'}) {
    $html .= free_group_org($html::parameters{'sure'});
  }
  elsif ($html::parameters{'overview_org'}) {
    $html .= overview_org($html::parameters{'sure'});
  }


  else {
    my @cells = ([[
		   &html::generic_form_element({type=>'submit', name=>'upload_seq', 
						value=>"Upload sequence"}), 
		   
		   &html::generic_form_element({type=>'submit', name=>'upload_info', 
						value=>"Upload sequence info"}),
		   
		   &html::generic_form_element({type=>'submit', name=>'find_genes', 
						value=>"(Re-)Find genes     "})
		   ],
		  
		  [
		   &html::generic_form_element({type=>'submit', name=>'edit_seq', 
						value=>"Edit sequence     "}),
		   &html::generic_form_element({type=>'submit', name=>'clusters', 
						value=>"Clustering of genes   "}),
		   &html::generic_form_element({type=>'submit', name=>'buildbs', 
						value=>"Build local DBases  "})
		   ], 
		  
		  
		  [
		   &html::generic_form_element({type=>'submit', name=>'del_seq', 
						value=>"Delete sequence "}),
		   
		   &html::generic_form_element({type=>'submit', name=>'del_info', 
						value=>"Delete sequence info "}),
		   
		   &html::generic_form_element({type=>'submit', name=>'del_dbs', 
						value=>"Delete local DBases"})
		   ],

		  [
		   &html::generic_form_element({type=>'submit', name=>'rename_seq', 
						value=>"Rename sequences"}), 

		   &html::generic_form_element({type=>'submit', name=>'rename_genes', 
						value=>"Rename genes"}), 

		   &html::generic_form_element({type=>'submit', name=>'orfinder', 
						value=>"Run ORFinder           "})
		   ]

		  ]);
    

    $html .= html::start_form('mutagen.pl');
    $html .= html::style::center(html::table(@cells, 1));

    if (!$conf::limit) {

      $html .= "<CENTER>".html::style::h2("Organism access")."<CENTER>";
      
      @cells = ([[
		  &html::generic_form_element({type=>'submit', name=>'add_group_org', 
					       value=>"Add group to organism"}), 
		  
		  &html::generic_form_element({type=>'submit', name=>'del_group_org', 
					       value=>"Delete group from organism"}),
		  
		  &html::generic_form_element({type=>'submit', name=>'free_group_org', 
					       value=>"Free organism (no groups)"}),
		  
		  &html::generic_form_element({type=>'submit', name=>'overview_org', 
					       value=>"Sequence access overview"})
		  
		  ],
		 
		 
		 ]);
      $html .= html::style::center(html::table(@cells, 1));
    }
    

    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"sequences"});

    $html .= &access::session_form();
    $html .= html::end_form();
  }
  
  return $html;
}



# 
# Upload a new sequence to the database
# 
# Kim Brugger (26 Feb 2004)
sub upload_seq {

  my $html = "";


  if ($html::parameters{"upload_seq"} eq "Submit") {
    require db::organism;
    require db::sequence;
    require db::genefinder;
    require db::annotation;
    require db::version;
    
    my $ERROR = undef;

    if ($html::parameters{upload}) {
      my $file = &html::save_upload_file("upload");

      if (!$file) {
	$ERROR .= "<h3>ERROR</h3>Could not open the file, it might be to big or try again later\n";
	goto ERROR;
      }

      $html .=  "FILE:: $file\n";

      if ($html::parameters{'type'} eq "fasta") {
	
	my $sequences = &kernel::read_fasta($file);
	if (!$sequences) {
	  $ERROR .= "<h3>ERROR</h3>Wrong format of the file, test that format is right and try again\n";
	  goto ERROR;
	}

	my $organism = &db::organism::fetch($html::parameters{'org_name'});
	if (! $organism) {
	  $html::parameters{'org_name'} =~ /^(.).*? (.{3}).*/;
	  my $alias = "$1$2" if ($1 && $2);
	  
	  $alias = $html::parameters{'org_alias'} if ($html::parameters{'org_alias'});
	  my %call_hash = ("name"  => $html::parameters{'org_name'},
			   "alias" => $alias);
	  
	  &db::organism::save(\%call_hash);
	  
	  # and finally fetch the information we just saved.
	  $organism = &db::organism::fetch($html::parameters{'org_name'});
	}
	
	# Find the next vid (version id) for this sequence/organism.  The
	# function checks if this is a new sequence etc, just belive in the
        # return value of the function call.
	my $vid = &db::version::next($$organism{"oid"});
	
	$html .=  "Read the sequence file with ".(keys %{$sequences})." sequences<BR>";
	foreach my $key (keys %{$sequences}) {
	  chomp $$sequences{$key}{'name'};
	  &db::sequence::save($$organism{'oid'}, $vid, $$sequences{$key}{'name'}, $$sequences{$key}{'sequence'});
	}
	$html .=  "Transfered the sequence(s) to the database\n";

	
      }
      elsif ($html::parameters{'type'} eq "gbk") {
	require parser::genbank;

	my $genbank_hash = &parser::genbank::parse($file);

	if (!$genbank_hash || !$$genbank_hash{'sequence'} || !$$genbank_hash{'sequence_name'}) {
	  $ERROR .= "<h3>ERROR</h3>Wrong format of the file, test that format is right and try again\n";
	  goto ERROR;
	}

	$$genbank_hash{organism} = $html::parameters{'org_name'} if ($html::parameters{'org_name'});

	my $organism = &db::organism::fetch("$$genbank_hash{organism}");
	if (! $organism) {
	  $$genbank_hash{organism} =~ /^(.).*? (.{3}).*/;
	  my $alias = "$1$2";

	  $alias = $html::parameters{'org_alias'} if ($html::parameters{'org_alias'});

	  my %call_hash = ("name" => $$genbank_hash{organism},
			   "alias" => $alias);
	  
	  &db::organism::save(\%call_hash);
	  
	  # and finally fetch the information we just saved.
	  $organism = &db::organism::fetch("$$genbank_hash{organism}");
	}
	
	# Find the next vid (version id) for this sequence/organism.  The
	# function checks if this is a new sequence etc, just belive in the
        # return value of the function call.
	my $vid = &db::version::next($$organism{"oid"});

        # Now that we have both the sequence and the rest of the information
        # required, lets store the information in the database.

	$$genbank_hash{'sequence_name'} = $html::parameters{'seq_name'} if ($html::parameters{'seq_name'});

	my $sid = &db::sequence::save($$organism{oid}, $vid, 
				      $$genbank_hash{"sequence_name"}, $$genbank_hash{"sequence"});
	
	
	$html .=  "<BR>The file contains ". @{$$genbank_hash{'features'}} . " features.<BR>\n";
	
	
	foreach my $feature (@{$$genbank_hash{'features'}}) {

#	  &core::Dump($feature);
	    
	  # Since the genes are often found as both a gene and a CDS
	  # we will just store the CDS's.
	  if ($$feature{'feature_type'} && 
	      $$feature{'feature_type'} eq "CDS") {
	    

	    my $name = $$feature{"/locus_tag"} || $$feature{"/gene"};

	    if (not defined $name) {
	      $name = $$organism{alias}."_$$feature{'start'}-$$feature{'stop'}" 
 		  if (!$$feature{'complement'});
	      $name = $$organism{alias}."_$$feature{'stop'}-$$feature{'start'}" 
		  if ( $$feature{'complement'});
	    }
	    
	    my %call_hash = ('name'       => $name,
			     'start'      => $$feature{'start'},
			     'stop'       => $$feature{'stop'},
			     'strand'     => $$feature{'complement'},
			     'intron'     => $$feature{'intron'},
			     'sid'        => "$sid",
			     'type'       => "ORF",
			     'source'     => "GenBank");

#	    &core::Dump(\%call_hash);

	    my $fid = &db::genefinder::save(\%call_hash);

	    # then save the annotaion that was found in the genbank file.

	    if ($$feature{"/comment"}) {
	      $$feature{"/comment"} =~ s/^\'//;
	      $$feature{"/comment"} =~ s/\'$//;
	    }

	    # We should have at least these information items.
	    %call_hash = ('fid' => $fid,
			  'gene_name'       => $$feature{"/gene_name"} || $$feature{"/protein_id"},
			  'start_codon'     => $$feature{"/codon_start"},
			  'gene_product'    => $$feature{"/product"},
			  'comment'         => $$feature{"/note"} || $$feature{"/comment"},
			  'annotator_name'  => "From the genbank file",
			  'state'           => "show");

	    $call_hash{"conf_in_gene"} = $$feature{"/gene-confidence"} if ($$feature{"/gene-confidence"});
	    $call_hash{"conf_in_func"} = $$feature{"/function-confidence"} if ($$feature{"/function-confidence"});

	    $call_hash{"evidence"} = $$feature{"/evidence"} if ($$feature{"/evidence"});
	    $call_hash{"EC_number"} = $$feature{"/EC_number"} if ($$feature{"/EC_number"});
	    $call_hash{"TAG"} = $$feature{"/TAG"} if ($$feature{"/TAG"});

            #    $call_hash{""} = $$feature{"/"} if ($$feature{"/"});
            #    $call_hash{""} = $$feature{"/"} if ($$feature{"/"});
	    
	    if ($$feature{"/function"}) {
	      my ($prim, $sec) = split ("/", $$feature{"/function"}, 2);
	      $call_hash{"general_function"} = "$prim/$sec";
	    }

	    my $aid = &db::annotation::save(\%call_hash);
	    
	  }
	  elsif ($$feature{'feature_type'} && $$feature{'feature_type'} ne "source") {

	    my $name = $$feature{"/locus_tag"} || $$feature{"/gene"};

	    if (not defined $name) {
	      $name = $$organism{alias}."_$$feature{'start'}-$$feature{'stop'}" 
 		  if (!$$feature{'complement'});
	      $name = $$organism{alias}."_$$feature{'stop'}-$$feature{'start'}" 
		  if ( $$feature{'complement'});
	    }

	    
	    my %call_hash = ('name'       => $name,
			     'start'      => $$feature{'start'},
			     'stop'       => $$feature{'stop'},
			     'strand'     => $$feature{'complement'},
			     'intron'     => $$feature{'intron'},
			     'type'       => $$feature{'feature_type'},
			     'sid'        => "$sid",
			     'source'     => "GenBank");

	    my $fid = &db::genefinder::save(\%call_hash);
	    
	    # We should have at least these information items.
	    %call_hash = ('fid' => $fid,
			  'gene_name'       => $$feature{"/gene_name"} || $$feature{"/protein_id"},
			  'start_codon'     => $$feature{"/codon_start"},
			  'gene_product'    => $$feature{"/product"},
			  'comment'        => $$feature{"/note"} || $$feature{"/comment"},
			  'annotator_name'  => "From the genbank file",
			  'state'           => "show");

	    $call_hash{"conf_in_gene"} = $$feature{"/gene-confidence"} if ($$feature{"/gene-confidence"});
	    $call_hash{"conf_in_func"} = $$feature{"/function-confidence"} if ($$feature{"/function-confidence"});

	    $call_hash{"evidence"} = $$feature{"/evidence"} if ($$feature{"/evidence"});
	    $call_hash{"EC_number"} = $$feature{"/EC_number"} if ($$feature{"/EC_number"});
	    $call_hash{"TAG"} = $$feature{"/TAG"} if ($$feature{"/TAG"});

            #    $call_hash{""} = $$feature{"/"} if ($$feature{"/"});
            #    $call_hash{""} = $$feature{"/"} if ($$feature{"/"});

	    my $aid = &db::annotation::save(\%call_hash);
	    
	  }	  	    
	}
      }
      else {
	$ERROR .= "<h3>ERROR</h3>Unknown file type, reload the page and try again\n";
      }

    }
    else {
      $ERROR .= "<h3>ERROR</h3>No filename submitted, please try again\n";
    }

    if ($ERROR) {
    ERROR:
      return($ERROR);
    }

  }
  else {
    $html .= html::start_multiform('mutagen.pl');

    my @cells;
  
    push @cells, ["What format is file are you are uploading ?",

		  &html::generic_form_element({type=>"radio", 
					       name=>"type", 
					       value=>"fasta"})."fasta".
    
		  &html::generic_form_element({type=>"radio",
					       name=>"type", 
					       value=>"gbk", 
					       checked=>1}). "GenBank<BR>"];
    
    push @cells,  ["Organism name (only mandatory for fasta)",
		   &html::generic_form_element({type=>"label",
						name=>"org_name",
						value=>""})."<BR>"];
    
    push @cells, ["Organism alias (not required)",
		  &html::generic_form_element({type=>"label",
					       name=>"org_alias",
					       value=>""})];
    
    push @cells, ["Sequence name (not required)",
		  &html::generic_form_element({type=>"label",
					       name=>"seq_name",
					       value=>""})];

    push @cells, ["Sequence type:",
		  &html::generic_form_element({type=>'radio', name=>'otype', 
					       value=>'organism', checked=>1})."Organism ".
		  &html::generic_form_element({type=>'radio', name=>'otype', 
					     value=>'virus'})."Virus".

		  &html::generic_form_element({type=>'radio', name=>'naming', 
					     value=>'plasmid'})."Plasmid"
		  ];
    

    push @cells, ["Name of the file:<BR>",
		  &html::generic_form_element({type=>'file', name=>'upload'})];
    
    push @cells, [&html::generic_form_element({type=>'reset'}),
		  &html::generic_form_element({type=>"submit", name => "upload_seq", value => "Submit"})];
    

    $html .= &html::table(\@cells, 1);
    
    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"sequences"});
    $html .= &access::session_form();
    $html .= html::end_form();
  }

 
  return $html;
}

# 
# Upload infomation belonging to a sequence
# 
# Kim Brugger (26 Feb 2004)
sub rename_genes {

  require db::organism;
  require db::version;
  require db::sequence;
  require db::gene;

  my $html ="";
  my $ERROR = undef;

  if ($html::parameters{'rename_genes'} eq "Submit" && 
      $html::parameters{'sure'} && $html::parameters{'sure'} eq "Yes") {

    $html .= "<h3>Update genes names (NOT DEBUGGED !!!!!!!)</h3>";

    my ($oid, $vid, $naming, $prefix) = ($html::parameters{oid}, $html::parameters{vid},
					 $html::parameters{naming},$html::parameters{prefix});
    
    $naming = "SS";
    #for each of the sequences that belong to this oid,vid set.
    foreach my $sequence ( &db::sequence::fetch_organism($oid, $vid)) {
      
      my @genes = &db::gene::fetch_organism(undef, undef, $$sequence{sid});

      if ($naming eq "POS") {
	@genes = sort {$$a{start} <=> $$b{start}} @genes;
      }
      elsif ($naming eq "AA" || $naming eq "DNA"){
	@genes = sort {($$a{stop} - $$a{start})<=> ($$b{stop} - $$b{start})} @genes;
      }


      my %used = ();
      foreach my $gene (@genes) {
	if ($naming eq "AA" || $naming eq "DNA") {
	  my $length = 0;
	  $length = ($$gene{stop} - $$gene{start}+1)/3 if ($naming eq "AA");
	  $length = ($$gene{stop} - $$gene{start}+1)   if ($naming eq "DNA");
	  $used{$length}++;
	}
      }

      my $i = 0;
      my %letters = ();
      foreach my $gene (@genes) {
	$i++;
	if ($naming eq "POS") {
	  $$gene{name} = "$prefix$i";
	}
	elsif ($naming eq "AA" || $naming eq "DNA") {
	  my $length = 0;
	  $length = ($$gene{stop} - $$gene{start}+1)/3 if ($naming eq "AA");
	  $length = ($$gene{stop} - $$gene{start}+1)   if ($naming eq "DNA");
	  
	  if ($used{$length} > 1) {
	    $letters{$length}++ if ($letters{$length});
	    $letters{$length} = "a" if (!$letters{$length});

	    $length .= $letters{$length};

	  }
	  $$gene{name} = "$prefix$length";

	}
	elsif ($naming eq "SS"){
	  $$gene{name} = "$prefix$$sequence{name}\_$$gene{start}-$$gene{stop}" 
	      if ($$gene{strand} == 0);

	  $$gene{name} = "$prefix$$sequence{name}\_$$gene{stop}-$$gene{start}" 
	      if ($$gene{strand} == 1);
	}

	&db::gene::update($gene);
      }
    }
    
    
    
    


  }
  elsif ($html::parameters{'rename_genes'} eq "Submit") {
    
    
    $html::parameters{'oid'} =~ /^(\d+)\.(\d+)\Z/;
    my ($oid, $vid) = ($1, $2);

    $html .= html::start_multiform('mutagen.pl');

    my $organism = &db::organism::fetch($oid);
    my $sequences = &db::organism::fetch($oid);
    $html .= "<H2>Alter genesnames in the '$$organism{name}' organism</H2>";

    my @cells;
    push @cells, ["Name prefix:",
		  &html::generic_form_element({type=>"label",
					       name=>"prefix",
					       value=>"$$organism{name}"})];


    push @cells, ["Naming method:",
		  &html::generic_form_element({type=>'radio', name=>'naming', 
					       value=>'POS', checked=>1})."Based on gene position &nbsp;".
		  &html::generic_form_element({type=>'radio', name=>'naming', 
					     value=>'AA'})."Named by AA size&nbsp;".
		  &html::generic_form_element({type=>'radio', name=>'naming', 
					     value=>'DNA'})."Named by DNA size&nbsp;".
		  &html::generic_form_element({type=>'radio', name=>'naming', 
					     value=>'SS'})."Sequencename_start-stop&nbsp;"
		  ];

    push @cells, ["",
		  &html::generic_form_element({type=>"submit", name => "rename_genes", value => "Submit"})];

    $html .= &html::table(\@cells, 1);
    
    $html .= &html::generic_form_element({type=>'hidden', name=>'oid',     value=>"$oid"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'vid',     value=>"$vid"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'sure',    value=>"Yes"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"sequences"});

    $html .= &access::session_form();
    $html .= html::end_form();
    
  }
  else {
    
    $html .= html::start_multiform('mutagen.pl');
    my @cells;
    my @organisms = &db::organism::all();
    @organisms = sort {$$a{name} cmp $$b{name}} @organisms;
    
    my %organism_labels = ();
    my @oid_list;

    
    foreach my $organism (@organisms) {
      my @versions = &db::version::fetch_all($$organism{oid});
      
      foreach my $version(@versions) {
	$organism_labels{"$$organism{'oid'}.$$version{'vid'}"} = "$$organism{'name'} Version: $$version{'vid'}";
	push @oid_list, "$$organism{'oid'}.$$version{'vid'}";
      }
    }

    push @cells, ["What genes in what sequences do you want to alter the name(s) of ?",
		  
		  &html::generic_form_element({type=>"popup", 
					       name=>"oid", 
					       values=>\@oid_list,
					       labels=>\%organism_labels})];
    push @cells, ["<BR><BR>&nbsp;",
		  &html::generic_form_element({type=>"submit", name => "rename_genes", value => "Submit"})];
    

    $html .= &html::table(\@cells, 1);
    
    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"sequences"});

    $html .= &access::session_form();
    $html .= html::end_form();
  }
  
  return $html;
}



# 
# Upload infomation belonging to a sequence
# 
# Kim Brugger (26 Feb 2004)
sub rename_seq {

  require db::organism;
  require db::version;
  require db::sequence;

  my $html ="";
  my $ERROR = undef;

  if ($html::parameters{'rename_seq'} eq "Submit" && 
      $html::parameters{'sure'} && $html::parameters{'sure'} eq "Yes") {


    my %call_hash = (oid   => $html::parameters{oid},
		     alias => $html::parameters{org_alias},,
		     name  => $html::parameters{org_name});

#    &core::Dump(\%call_hash);
    &db::organism::update(\%call_hash);
    
    foreach my $parameter (keys %html::parameters) {
      if ($parameter =~ /sequence_name_(\d+)\Z/) {
	my %call_hash2 = (sid  => $1,
			 name => $html::parameters{$parameter});

#	&core::Dump(\%call_hash2);
	
	&db::sequence::update(\%call_hash2);
	
      }
    }

    $html .= "<h3>Update organism and sequence names</h3>";
    
  }
  elsif ($html::parameters{'rename_seq'} eq "Submit") {
    
    $html .= "<H2>Alter organism/sequence names</H2>";
    
    $html::parameters{'oid'} =~ /^(\d+)\.(\d+)\Z/;
    my ($oid, $vid) = ($1, $2);

    $html .= html::start_multiform('mutagen.pl');

    my $organism = &db::organism::fetch($oid);
    my $sequences = &db::organism::fetch($oid);

    my @cells;
    push @cells, ["Organism oid:","$$organism{oid}"];

    push @cells, ["Organism name:",
		  &html::generic_form_element({type=>"label",
					       name=>"org_name",
					       value=>"$$organism{name}"})];

    push @cells, ["Organism alias:",
		  &html::generic_form_element({type=>"label",
					       name=>"org_alias",
					       value=>"$$organism{alias}"})];
		  
				

    foreach my $sequence ( &db::sequence::fetch_organism($oid, $vid)) {

      push @cells, ["Sequence name",
		  &html::generic_form_element({type=>"label",
					       name=>"sequence_name_$$sequence{sid}",
					       value=>$$sequence{name}})];
    }

    push @cells, ["",
		  &html::generic_form_element({type=>"submit", name => "rename_seq", value => "Submit"})];
    
    $html .= &html::table(\@cells, 1);
    
    $html .= &html::generic_form_element({type=>'hidden', name=>'oid',     value=>"$oid"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'sure',    value=>"Yes"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"sequences"});

    $html .= &access::session_form();
    $html .= html::end_form();
    
  }
  else {
    
    $html .= html::start_multiform('mutagen.pl');

    my @cells;
    my @organisms = &db::organism::all();
    @organisms = sort {$$a{name} cmp $$b{name}} @organisms;
    
    my %organism_labels = ();
    my @oid_list;

    
    foreach my $organism (@organisms) {
      my @versions = &db::version::fetch_all($$organism{oid});
      
      foreach my $version(@versions) {
	$organism_labels{"$$organism{'oid'}.$$version{'vid'}"} = "$$organism{'name'} Version: $$version{'vid'}";
	push @oid_list, "$$organism{'oid'}.$$version{'vid'}";
      }
    }

    push @cells, ["What organism do you want to alter the name(s) of ?",
		  
		  &html::generic_form_element({type=>"popup", 
					       name=>"oid", 
					       values=>\@oid_list,
					       labels=>\%organism_labels})];
    push @cells, ["<BR><BR>&nbsp;",
		  &html::generic_form_element({type=>"submit", name => "rename_seq", value => "Submit"})];
    

    $html .= &html::table(\@cells, 1);
    
    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"sequences"});

    $html .= &access::session_form();
    $html .= html::end_form();
  }
  
  return $html;
}


# 
# Upload infomation belonging to a sequence
# 
# Kim Brugger (26 Feb 2004)
sub upload_info {

  my $html ="";

  require db::genefinder;

  my $ERROR = undef;
  

  if ($html::parameters{'upload_info'} eq "Submit") {
    
    my $file = &html::save_upload_file("upload");
    
    if (!$file) {
      $ERROR .= "<h3>ERROR</h3>Could not open the file, it might be to big or try again later\n";
      goto ERROR;
    }
    open INFILE, $file || die "Could not open '$file': $!";
    my $count = 0;
    while (<INFILE>) {

      # lets skip the comment (lines beginning with #).
      next if (/^\#/);

      # fields: <seqname> <source> <feature> <start> <end> <score> <strand> <frame> [attributes] [comments]
      my ($seqname, $source, $feature, $start, $stop, $score, $strand, $frame, $attributes, $comment) =
	  split ("\t");

      next if (!$start || !$stop);

      ($start, $stop) = ($stop, $start) if ($start > $stop);

      if ($feature eq "CDS") {
	$feature = "ORF";
      }
      else {
	next;
      }
#        elsif ($feature =~ /RNA/) {
#  	$feature = "RNA";
#        }
#        else {
#  	$feature = "other";
#        }
      
  
      my %call_hash = (
		       'start' => $start,
		       'stop'  => $stop,
		       'strand' => $strand eq "+" ? 0 : 1,
		       'sid' => $html::parameters{'sid'},
		       'type' => $feature,
		       'source' => $html::parameters{'source'},
		       'score' => $score);

      &db::genefinder::save(\%call_hash);
      $count++;
    }
    $html .= "<H3>Transfered $count genes/features</H3>";
  }
  else {
    
    $html .= html::start_multiform('mutagen.pl');

    my @cells;
  
    require db::sequence;
    require db::version;
    my @sequences = &db::sequence::all();
    @sequences = sort {$$a{name} cmp $$b{name}} @sequences;
    
    my %sequence_labels = ();
    my @sid_list;

    
    foreach my $sequence (@sequences) {
      my $version = &db::version::fetch($$sequence{vid});
      
      $sequence_labels{$$sequence{'sid'}} = "$$sequence{'name'} version: $$version{version}";
      push @sid_list, $$sequence{sid};
    }

    push @cells, ["What sequence does the data belong ?",

		  &html::generic_form_element({type=>"popup", 
					       name=>"sid", 
					       values=>\@sid_list,
					       labels=>\%sequence_labels,
					       checked=>1})];


    push @cells, ["What format is file are you are uploading ?",

		  &html::generic_form_element({type=>"radio", 
					       name=>"type", 
					       value=>"gff2", 
					       checked=>1})."GFF2".
    
		  &html::generic_form_element({type=>"radio",
					       name=>"type", 
					       value=>"mutagen"}). "mutagen"];
    
    push @cells, ["<BR>Name of the source:<BR>",
		  &html::generic_form_element({type=>'label', name=>'source'})];
    

    push @cells, ["<BR>Name of the file:<BR>",
		  &html::generic_form_element({type=>'file', name=>'upload'})];
    
    push @cells, ["<BR><BR>&nbsp;",
		  &html::generic_form_element({type=>"submit", name => "upload_info", value => "Submit"})];
    

    $html .= &html::table(\@cells, 1);
    
    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"sequences"});

    $html .= &access::session_form();
    $html .= html::end_form();
  }
  
  return $html;
}


# 
# Deletes a sequence and all infomation belonging to it from the database
# 
# Kim Brugger (26 Feb 2004)
sub del_seq {

  require db::organism;
  require db::version;

  my $html = "";

  if ($html::parameters{'sure'} eq "yes") {
    $html .= "<h3>Deleted this organism/these organisms:</h3>";

    require db::gene;
    require db::organism;
    require db::sequence;
    require db::genefinder;
    require db::annotation;

    my $organisms = $html::parameters{'organisms'};
    $organisms = [$organisms] if (ref $organisms ne "ARRAY");
    foreach my $organism (@$organisms) {
     
      $organism =~ /(\d+)\.(\d+)/;
      my ($oid, $vid) = ($1, $2);
      my $organism = &db::organism::fetch($oid);
      my $version  = &db::version::fetch($vid);

      $html .=  "$$organism{name} Version: $$version{version}<BR>";

      # first delete the sequence from the database
      my @sequences = &db::sequence::fetch_organism ($oid, $vid);
      foreach my $sequence (@sequences) {
	&db::sequence::delete($$sequence{sid});
      }

      # now it is the genes turn.
      my @genes = &db::gene::fetch_organism($oid, $vid);
      foreach my $gene (@genes) {
	&db::gene::delete($$gene{gid});

	# while we are at it delete the genefinder 
	foreach my $fid (&db::genefinder::fetch_by_gid($$gene{gid})) {
	  &db::genefinder::delete($$fid{fid});
	}

	# and annotation information.
	foreach my $aid (&db::annotation::all($$gene{gid})) {
	  &db::annotation::delete($$aid{aid});
	}
	# and the auto-collected information.
	&db::adc::delete_all($$gene{gid});


      }
      # We do not delete stuff from the organisms tables. It is better
      # to keep track of what have been here.  And new version of the
      # organisms might come back later.
      &db::version::delete($vid);
    }

    
  }
  elsif ($html::parameters{'sure'} eq "no") {
    $html .= "<h3>Are you sure you want to remove this organism/these organisms ???</h3>";
    
    $html .= html::start_form('mutagen.pl');

    my $organisms = $html::parameters{'organisms'};
    $organisms = [$organisms] if (ref $organisms ne "ARRAY");

    foreach my $oid (@$organisms) {

      $oid =~ /(\d+)\.(\d+)/;
      my $organism = &db::organism::fetch($1);
      my $version  = &db::version::fetch($2);

      $html .=  "$$organism{name} Version: $$version{version}<BR>";
    }
    

    $html .=  &html::generic_form_element({type=>"submit",
					   name=>"sure",
					   value=>"yes"});
    $html .=  "&nbsp;".&html::generic_form_element({type=>"submit",
					   name=>"sure",
					   value=>"no"});
    
    $html .= &html::generic_form_element({type=>"hidden", name=> 'page',    value=> "admin"});
    $html .= &html::generic_form_element({type=>"hidden", name=> 'subpage', value=> "sequences"});
    $html .= &html::generic_form_element({type=>"hidden", name=> 'del_seq', value=> "1"});
    $html .= &html::generic_form_element({type=>"hidden", name=> 'organisms', value=> join("\0", $html::parameters{organisms})});
    $html .= &access::session_form();
    $html .= html::end_form();
    
  }
  else {
    $html .=  "<h3>Select organism(s) to remove from the database:</h3>";

    my @organisms = db::organism::all();

    my %organism_labels=();
    my @oid_list;

   
    foreach my $organism (@organisms) {

      my @versions = &db::version::fetch_all($$organism{oid});
      
      foreach my $version (@versions) {
	$organism_labels{"$$organism{'oid'}.$$version{vid}"} = 
	    "$$organism{'name'} Version: $$version{version}";
	push @oid_list, "$$organism{oid}.$$version{vid}";
      }
    }

    $html .= html::start_form('mutagen.pl');
    $html .= &html::checkbox_table({type=>'radiobuttons', 
				    name=>'organisms',
				    values=>\@oid_list,
				    labels=>\%organism_labels});
     
    
    $html .= &html::generic_form_element({type=>"hidden", name=> 'page',    value=> "admin"});
    $html .= &html::generic_form_element({type=>"hidden", name=> 'subpage', value=> "sequences"});
    $html .= &html::generic_form_element({type=>"hidden", name=> 'sure',    value=> "no"});

    $html .= &html::generic_form_element({type=>'submit', name=>'del_seq', 
					  value=>"Delete sequence(s) "});
    $html .= &access::session_form();
    $html .= html::end_form();
  }




  return $html;
}




# 
# Deletes a sequence and all infomation belonging to it from the database
# 
# Kim Brugger (26 Feb 2004)
sub del_info {

  require db::organism;
  require db::version;

  my $html = "";

  if ($html::parameters{'sure'} eq "yes") {
    $html .= "<h3>Deleted gene information from this organism/these organisms:</h3>";

    require db::gene;
    require db::organism;
    require db::sequence;
    require db::genefinder;
    require db::annotation;
    require db::adc;

    my $organisms = $html::parameters{'organisms'};
    $organisms = [$organisms] if (ref $organisms ne "ARRAY");
    foreach my $organism (@$organisms) {
     
      $organism =~ /(\d+)\.(\d+)/;
      my ($oid, $vid) = ($1, $2);
      my $organism = &db::organism::fetch($oid);
      my $version  = &db::version::fetch($vid);

      $html .=  "$$organism{name} Version: $$version{version}<BR>";

      # now it is the genes turn.
      my @genes = &db::gene::fetch_organism($oid, $vid);
      foreach my $gene (@genes) {
	&db::gene::delete($$gene{gid});

	# while we are at it delete the genefinder 
	foreach my $fid (&db::genefinder::fetch_by_gid($$gene{gid})) {
	  &db::genefinder::delete($$fid{fid});
	}

	# and annotation information.
	foreach my $aid (&db::annotation::all($$gene{gid})) {
	  &db::annotation::delete($$aid{aid});
	}

	# and the auto-collected information.
	&db::adc::delete_all($$gene{gid});

      }
     
    }

    
  }
  elsif ($html::parameters{'sure'} eq "no") {
    $html .= "<h3>Are you sure you want to remove the  gene information related to this organism/these organisms ???</h3>";
    
    $html .= html::start_form('mutagen.pl');

    my $organisms = $html::parameters{'organisms'};
    $organisms = [$organisms] if (ref $organisms ne "ARRAY");

    foreach my $oid (@$organisms) {

      $oid =~ /(\d+)\.(\d+)/;
      my $organism = &db::organism::fetch($1);
      my $version  = &db::version::fetch($2);

      $html .=  "$$organism{name} Version: $$version{version}<BR>";
    }
    

    $html .=  &html::generic_form_element({type=>"submit",
					   name=>"sure",
					   value=>"yes"});
    $html .=  "&nbsp;".&html::generic_form_element({type=>"submit",
					   name=>"sure",
					   value=>"no"});
    
    $html .= &html::generic_form_element({type=>"hidden", name=> 'page',    value=> "admin"});
    $html .= &html::generic_form_element({type=>"hidden", name=> 'subpage', value=> "sequences"});
    $html .= &html::generic_form_element({type=>"hidden", name=> 'del_seq', value=> "1"});
    $html .= &html::generic_form_element({type=>"hidden", name=> 'organisms', value=> join("\0", $html::parameters{organisms})});
    $html .= &access::session_form();
    $html .= html::end_form();
    
  }
  else {
    $html .=  "<h3>Select organism(s) to remove  the gene information from the database:</h3>";

    my @organisms = db::organism::all();

    my %organism_labels=();
    my @oid_list;

   
    foreach my $organism (@organisms) {

      my @versions = &db::version::fetch_all($$organism{oid});
      
      foreach my $version (@versions) {
	$organism_labels{"$$organism{'oid'}.$$version{vid}"} = 
	    "$$organism{'name'} Version: $$version{version}";
	push @oid_list, "$$organism{oid}.$$version{vid}";
      }
    }

    $html .= html::start_form('mutagen.pl');
    $html .= &html::checkbox_table({type=>'checkbox', 
				    name=>'organisms',
				    values=>\@oid_list,
				    labels=>\%organism_labels});
     
    
    $html .= &html::generic_form_element({type=>"hidden", name=> 'page',    value=> "admin"});
    $html .= &html::generic_form_element({type=>"hidden", name=> 'subpage', value=> "sequences"});
    $html .= &html::generic_form_element({type=>"hidden", name=> 'sure',    value=> "no"});

    $html .= &html::generic_form_element({type=>'submit', name=>'del_seq', 
					  value=>"Delete sequence(s) "});
    $html .= &access::session_form();
    $html .= html::end_form();
  }




  return $html;
}


# 
# Edit a sequence in the database
# 
# Kim Brugger (26 Feb 2004)
sub edit_seq  {
 
  my $html = "";


  if ($html::parameters{alter} && $html::parameters{alter} eq "yes") {

    my $ERROR = undef;

    my ($sid, $old, $new) = 
	($html::parameters{'sid'},
	 $html::parameters{'old'},
	 $html::parameters{'new'});

    
    if (!$sid) {
      $ERROR .= "<h3>ERROR</h3>No sequence selected<BR>";
    }
    if (!$old || !$new) {
      $ERROR .= "<h3>ERROR</h3>There have to be sequence in both fields<BR>";
    }      

    goto ERROR if ($ERROR);

    my $old_pos = &db::sequence::locate_substr($sid, $old);

    
    # check and see that the old-sequence are really present in the sequence
    if (!$old_pos) {
      $ERROR .= "<h3>ERROR</h3>Could not find the substring in the sequence, make sure that it is in the";
      $ERROR .= "right orientation and try again (you can also blast to make sure). $sid, $old\n";
      goto ERROR;
    }


    # finally change the sequence, since things seems to be ok (scary shit this stuff).
    my $new_start = &db::sequence::substitute_substr($sid, $old, $new);

    if (length ($old) == length($new)) {
      $html .= "The two sequence are of the same length, so no frameshifts have occured\n";
      $html .=  "but the following gene sequences have been altered:<BR>";
      
      # find the genes that have been affected by this update and report it to the user
      my @genes = &db::gene::fetch_organism (undef, undef, $sid, $new_start, $new_start + length($new));
      foreach my $gene (@genes) {
	$html .= "<a href='../cbin/mutagen.pl?page=misc&gidinfo=$$gene{gid}'>gid:$$gene{gid} infomation</a>&nbsp;";
	$html .= "<a href='../cbin/mutagen.pl?gid=$$gene{gid}&page=sequence&subpage=browse&ORFmap=1' target='_nbrowser'>Browse gene map</A>";

      }
      
    }
    else {
      my $gene_diff = length ($new) - length($old);
      
      $html .= "Finding genes that have altered gene start and/or stops position ($gene_diff nucleotides)...\n";
      
      $html .= "The following gene sequences have possible been affected by the change:<BR>";
      my @genes = &db::gene::fetch_organism (undef, undef, $sid, $new_start, $new_start + length($new));
      foreach my $gene (@genes) {
	$html .=  "gid:$$gene{gid}<BR>";
      }
      
      $html .= "<HR>The following genes sequences have had their start and stop positions altered:<BR>";
      
      @genes = &db::gene::fetch_organism (undef, undef, $sid, $new_start+length($new));
      foreach my $gene (@genes) {
	$html .= "gid:$$gene{gid}\n";
	
	if ($$gene{start} > $new_start) {
	  $$gene{start} += $gene_diff;
	  $$gene{stop} += $gene_diff;
	  
	}
	elsif ($$gene{start} < $new_start &&
	       $$gene{stop} > $new_start + length($new)) {
	  $$gene{stop} += $gene_diff;
	}
	
	#undefine the sequence key in the hash so we can store the gene
	delete ($$gene{'sequence'});
	&db::gene::update($gene);
      }
      # now update the infomation found in the genefinder as well

      $html .= "<HR>The following genefinders have had their start and/or stop positions altered:<BR>";
      foreach my $gfinders (@{&db::genefinder::sequence($sid, $new_start+length($new))}){
	foreach my $gfinder (@$gfinders) {
	  $html .= "fid:$$gfinder{'fid'} <BR>";
	
	  if ($$gfinder{start} > $new_start) {
	    $$gfinder{start} += $gene_diff;
	    $$gfinder{stop} += $gene_diff;
	    
	  }
	  elsif ($$gfinder{start} < $new_start &&
		 $$gfinder{stop} > $new_start + length($new)) {
	    $$gfinder{stop} += $gene_diff;
	  }
	  
	  &db::genefinder::update($gfinder);
	  
	}
      }

      $html .= "Updated all the genes .... (The best code ever, NEAT)\n";
    }  
    
    return $html;
    
  ERROR:
    return $ERROR;
  }
  else {
    
    my @cells;
    
    my @sequences = &db::sequence::all();
    @sequences = sort {$$a{name} cmp $$b{name}} @sequences;
    
    my %sequence_labels = ();
    my @sid_list;

    
    foreach my $sequence (@sequences) {
      
      my $version = &db::version::fetch($$sequence{vid});
      
      $sequence_labels{$$sequence{'sid'}} = "$$sequence{'name'} version: $$version{version}";
      push @sid_list, $$sequence{sid};
    
    }

    push @cells, ["What sequence should be editied ? :",
		  &html::generic_form_element({type=>"popup", 
					       name=>"sid", 
					       values=>\@sid_list,
					       labels=>\%sequence_labels})];

    
    
    push @cells, ["Old sequence: ", &html::generic_form_element({type=>"text", 
								 name=>"old", 
								 size=>"70",
								 value=>""})];
    push @cells, ["New sequence: ", &html::generic_form_element({type=>"text", 
								 size=>"70",
								 name=>"new", 
								 value=>""})];

  
    

    $html .= html::start_form('mutagen.pl');
    $html .= &html::table(\@cells, 1);
    $html .= &html::generic_form_element({type=>"hidden", name=> 'page',    value=> "admin"});
    $html .= &html::generic_form_element({type=>"hidden", name=> 'subpage', value=> "sequences"});
    $html .= &html::generic_form_element({type=>"hidden", name=> 'alter',   value=> "yes"});
    
    $html .= &html::generic_form_element({type=>'submit', name=>'edit_seq', 
					  value=>"Change sequence(s) "});

    $html .= &access::session_form();
    $html .= html::end_form();
  }

  return $html;
}


# 
# Edit information belonging to a sequence
# 
# Kim Brugger (26 Feb 2004)
sub edit_info  {

}


# 
# Find genes based on the infomation in the genefinder table
# 
# Kim Brugger (26 Feb 2004)
sub find_genes {

  my $html = "";
  
  require db::sequence;
  require db::version;
  require db::genefinder;
  require db::organism;
  require db::gene;
  require db::annotation;

  if ($html::parameters{'source'}) {

    # find the organism (we might need the alias for naming some ORFs later)
    my $organism = &db::organism::fetch($html::parameters{sid});

    # First construct the ranking hash
    my %ranking = ();

    my $max = 0;
    # If we have multiple types of finders they will be in array
    if (ref $html::parameters{'source'} eq "ARRAY") {
      foreach my $source (@{$html::parameters{'source'}}) {
	$ranking{$source} = {startscore=>$html::parameters{"score_$source"}, 
#			     colour=>$html::parameters{"score_$source"}, 
			     triumph=>$html::parameters{"triumph"} eq "triumph_$source" ? 1:0, 
			     ignore=>$html::parameters{"ignore_$source"} || 0, 
			     alt_start=>$html::parameters{"alt_start_$source"} || 0};
	$max = $html::parameters{"score_$source"} if ($max < $html::parameters{"score_$source"});
      }
    }
    # we only have one type of genefinder for this gene, so we handle it slightly differenct
    else {
      my $source = $html::parameters{'source'};
      $ranking{$source} = {startscore=>$html::parameters{"score_$source"}, 
#			   colour=>$html::parameters{"score_$source"}, 
			   triumph=>$html::parameters{"triumph"} eq "triumph_$source" ? 1:0, 
			   ignore=>$html::parameters{"ignore_$source"} || 0, 
			   alt_start=>$html::parameters{"alt_start_$source"} || 0};
      $max = $html::parameters{"score_$source"};
    }


#    print STDERR "MAX ====== $max\n";
#    &core::Dump(\%ranking);

    # get the genes that belong to the sequence
    my $gene_groups = db::genefinder::sequence($html::parameters{sid});

    $html .=  "We have " . @$gene_groups . " different gene groups\n";

    my @genes;
    foreach my $group (@$gene_groups) {
      next if (! $$group[0]);
  
      my %starts;
      foreach my $gene (@$group) {
    
	next if ($ranking{$$gene{source}}{"ignore"});
	
	my $real_start = $$gene{'start'};
	$real_start = $$gene{'stop'} if ($$gene{'strand'} == 1);
    
	# this rules tells the program that only trust in this 
	# start position if it exists.
	if ($ranking{$$gene{source}}{"triumph"}) {
      
	  %starts = ();
	  $starts{$real_start} = {
	    'name'       => $$gene{'name'},
	    'start'      => $$gene{'start'},
	    'stop'       => $$gene{'stop'},
	    'strand'     => $$gene{'strand'},
	    'sid'        => $$gene{'sid'},
	    'source'     => $$gene{'source'},
	    'score'      => $$gene{'score'},
	    'type'       => $$gene{'type'},
	    'startscore' => $ranking{$$gene{source}}{"startscore"}};

	  if ($ranking{$$gene{source}}{"startscore"} == $max) {
	    $starts{$real_start}{colour} = 8  if ($$gene{type} eq "ORF");
	    $starts{$real_start}{colour} = 50  if ($$gene{type} eq "RNA");
	  }
	}
	
	# if the gene already exists, add the scores, and keep the best source
	if ($starts{$real_start}) {
	  
	  # changes the start pos score.
	  $starts{$real_start}{'startscore'} += $ranking{$$gene{source}}{'startscore'};
	  
	  if ($ranking{$$gene{source}}{startscore} > $ranking{$starts{$real_start}{source}}{startscore}) {
	    
	    $starts{$real_start}{'score'}  = $$gene{'score'};
	    $starts{$real_start}{'source'} = $$gene{'source'};
	    
	    if ($ranking{$$gene{source}}{"startscore"} == $max) {
	      $starts{$real_start}{colour} = 8  if ($$gene{type} eq "ORF");
	      $starts{$real_start}{colour} = 50  if ($$gene{type} eq "RNA");
	    }	      

	  }
	}
	# else add a new entry.
	else {
	  $starts{$real_start} = {
	    'name'       => $$gene{'name'},
	    'start'      => $$gene{'start'},
	    'stop'       => $$gene{'stop'},
	    'strand'     => $$gene{'strand'},
	    'sid'        => $$gene{'sid'},
	    'source'     => $$gene{'source'},
	    'score'      => $$gene{'score'},
	    'type'       => $$gene{'type'},
	    'fid'        => $$gene{'fid'},
	    'startscore' => $ranking{$$gene{source}}{"startscore"}};

	  if ($ranking{$$gene{source}}{"startscore"} == $max) {
	    $starts{$real_start}{colour} = 8  if ($$gene{type} eq "ORF");
	    $starts{$real_start}{colour} = 50  if ($$gene{type} eq "RNA");
	  }	      
	}
      }
      
      my @sorted_starts = sort {$starts{$b}{startscore} <=> $starts{$a}{startscore}} keys %starts;
      
      #
      # Check and see if one of the gene finders have an alternative start pos.
      #
      if (@sorted_starts) {
	
	for (my $i = 1; $i < @sorted_starts; $i++) {
	  if ($ranking{$starts{$sorted_starts[$i]}{source}}{'alt_start'}) {
	    $starts{$sorted_starts[0]}{'alt_start'} = 1;
	    # we only need to report one alternative start codon
	    last;
	  }
	}
      }

      push @genes, $starts{$sorted_starts[0]};
      %starts = ();
    }
    
    #Sort the genes accoring to start codon (so the gids get ordered.
    @genes = sort {$$a{start} <=> $$b{start}} @genes;
    foreach my $gene (@genes) {

      # first save the gene information in the gene table

      my $name = $$gene{'name'};
      if (!$name) {
	
	$name = $$organism{alias}."_$$gene{'start'}-$$gene{'stop'}" if (!$$gene{'strand'});
	$name = $$organism{alias}."_$$gene{'stop'}-$$gene{'start'}" if ( $$gene{'strand'});
      }

      my %call_hash = (
		       'name'       => $name,
		       'start'      => $$gene{'start'},
		       'stop'       => $$gene{'stop'},
		       'strand'     => $$gene{'strand'},
		       'sid'        => $$gene{'sid'},
		       'score'      => $$gene{'score'},
		       'type'       => $$gene{'type'},
		       'colour'     => $$gene{'colour'},
		       'altstart'   => $$gene{'alt_start'},
		       'fid'        => $$gene{'fid'},);


      # check and see if there is an old gene at this position, 
      # if so inherit its gid, otherwise save this as a new gene.

      my $gid = &db::gene::sameStopPos($$gene{'sid'}, $$gene{'stop'}, 
				       $$gene{'strand'});

      if ($gid) {

	$gid = $$gid{gid};

	my %reset = ('gid'    => $gid,
		     'colour' => 'NULL');

	&db::gene::update(\%reset);

#	print STDERR "GID :: $gid == $call_hash{name}\n";
	$call_hash{gid} = $gid;
	&db::gene::update(\%call_hash);
      }
      else {
#	print STDERR "GID :: ----- == $call_hash{name}\n";
	$gid = &db::gene::save(\%call_hash);
      }
      # then backlink to the gene table so we know which genefinder 
      # has been used, or at least the most importaint one.
      
      my $genefinders = &db::genefinder::sameStopPos($$gene{'sid'}, $$gene{'stop'}, $$gene{'strand'});
      
      foreach my $genefinder (@$genefinders) {
	
	%call_hash = ('fid' => $$genefinder{'fid'},
		      'gid' => $gid);
	
	my $fid = &db::genefinder::update(\%call_hash);
	
	# finally link the gene to an annotation if it exists (genbank transfers).
	my $annotation = &db::annotation::fetch_by_fid($$genefinder{'fid'});
	
	if ($annotation) {
	  $$annotation{'gid'} = $gid;
	  &db::annotation::update($annotation);
	}
      }
      
    }
   
  }
  elsif ($html::parameters{'sid'}) {
    
    my (%methods);

    
    foreach my $gfinders (@{&db::genefinder::sequence($html::parameters{'sid'})}) {
      foreach my $gfinder (@$gfinders) {
	$methods{$$gfinder{'source'}} = 1;
      }
    }

    my @cells;

    push @cells, ["Source", "Score", "Triumph","Ignore", "Alt. start"];


    $html .= html::start_form('mutagen.pl');
    foreach my $method (sort keys %methods) {
      $html .= &html::generic_form_element({type=>'hidden', name=>"source", value=>$method});
      
      push @cells, [$method, &html::generic_form_element({type=>"label", name=>"score_$method", default=>"10"}),
		    &html::generic_form_element({type=>"radio", name=>"triumph", value=>"triumph_$method", default=>"10"}),
		    &html::generic_form_element({type=>"checkbox", name=>"ignore_$method", default=>"10"}),
		    &html::generic_form_element({type=>"checkbox", name=>"alt_start_$method", default=>"10"})];
      
    }
    

    push @cells, ["<BR><BR>&nbsp;",
		  &html::generic_form_element({type=>"submit", name => "find_genes", value => "Submit"})];
    

    $html .= &html::table(\@cells, 1, undef, undef, undef, "70%");
    
    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"sequences"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'sid', value=>$html::parameters{sid}});
    $html .= &access::session_form();
    $html .= html::end_form();

  }
  else {

    $html .= html::start_form('mutagen.pl');

    my @cells;

    my @sequences = &db::sequence::all();
    @sequences = sort {$$a{name} cmp $$b{name}} @sequences;
    
    my %sequence_labels = ();
    my @sid_list;

    
    foreach my $sequence (@sequences) {
      my $version = &db::version::fetch($$sequence{vid});
      
      $sequence_labels{$$sequence{'sid'}} = "$$sequence{'name'} version: $$version{version}";
      push @sid_list, $$sequence{sid};
    }

    push @cells, ["What sequence do you want to find genes from ?",

		  &html::generic_form_element({type=>"popup", 
					       name=>"sid", 
					       values=>\@sid_list,
					       labels=>\%sequence_labels,
					       checked=>1})];


    push @cells, ["<BR><BR>&nbsp;",
		  &html::generic_form_element({type=>"submit", name => "find_genes", value => "Submit"})];
    

    $html .= &html::table(\@cells, 1);
    
    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"sequences"});
    $html .= &access::session_form();
    $html .= html::end_form();
  }
  
  return $html;
}

my $dbfile = "local";



# 
# Build databases from the sequence(s) in the database
# 
# Kim Brugger (26 Feb 2004)
sub buildbs {
  my ($db_state) = @_;

  require db::organism;
  require db::sequence;
  require db::gene;
  require db::version;

  my $html = "";

  if ($db_state eq "yes") {
    
    my @organisms = &db::organism::all();

    open (ALL_AA, "> $conf::dbases/local.faa") or 
	die "could not open $conf::dbases/local.faa: $!";

    open (ALL_DNA, "> $conf::dbases/local.fna") or 
	die "could not open $conf::dbases/local.fna: $!";

    open (ALL_OAA, "> $conf::dbases/local_organisms.faa") or 
	die "could not open $conf::dbases/local.faa: $!";

    open (ALL_ODNA, "> $conf::dbases/local_organisms.fna") or 
	die "could not open $conf::dbases/local.fna: $!";

    open (ALL_VAA, "> $conf::dbases/local_viruses.faa") or 
	die "could not open $conf::dbases/local.faa: $!";

    open (ALL_VDNA, "> $conf::dbases/local_viruses.fna") or 
	die "could not open $conf::dbases/local.fna: $!";

    open (ALL_PAA, "> $conf::dbases/local_plasmids.faa") or 
	die "could not open $conf::dbases/local.faa: $!";

    open (ALL_PDNA, "> $conf::dbases/local_plasmids.fna") or 
	die "could not open $conf::dbases/local_plasmids.fna: $!";

    foreach my $organism (@organisms) {
      my ($genome, $genes) = _organism_sequence($organism);

      
      open (OUTFILE,  "> $conf::dbases$$organism{oid}") or 
	  die "could not open $conf::dbases$$organism{oid}: $!";
      print OUTFILE $genome;
      close OUTFILE;
      system "cd $conf::dbases; $conf::formatdb -pF -i $$organism{oid} ";
      system "rm $conf::dbases$$organism{oid}";

      print ALL_DNA $genome;

      open (OUTFILE,  "> $conf::dbases$$organism{oid}") or 
	  die "could not open $conf::dbases$$organism{oid}: $!";
      print OUTFILE $genes;
      close OUTFILE;
      system "cd $conf::dbases; $conf::formatdb -i $$organism{oid}";
      system "rm $conf::dbases$$organism{oid}";

      print ALL_AA $genes;

      if ($$organism{type} eq "organism") {
	print ALL_ODNA $genome;
	print ALL_OAA $genes;
      }
      elsif ($$organism{type} eq "virus") {
	print ALL_VDNA $genome;
	print ALL_VAA $genes;
      }
      elsif ($$organism{type} eq "plasmid") {
	print ALL_PDNA $genome;
	print ALL_PAA $genes;
      }


    }

    close ALL_AA;
    close ALL_DNA;

    close ALL_ODNA;
    close ALL_OAA;

    close ALL_VDNA;
    close ALL_VAA;

    close ALL_PDNA;
    close ALL_PAA;

#    system "cd $conf::dbases; mv local.fna local; $conf::formatdb -i local -pF ; rm local";
#    system "cd $conf::dbases; mv local.faa local; $conf::formatdb -i local; ";
    system "cd $conf::dbases; rm formatdb.log local.*";

    system "cd $conf::dbases; mv local_organisms.fna local_organisms; $conf::formatdb -pF -i local_organisms;";
    system "cd $conf::dbases; mv local_organisms.faa local_organisms; $conf::formatdb -i local_organisms;";

    system "cd $conf::dbases; mv local_plasmids.fna local_plasmids; $conf::formatdb -pF -i local_plasmids -pF ; ";
    system "cd $conf::dbases; mv local_plasmids.faa local_plasmids; $conf::formatdb -i local_plasmids ; ";

    system "cd $conf::dbases; mv local_viruses.fna local_viruses; $conf::formatdb -pF -i local_viruses -pF ; ";
    system "cd $conf::dbases; mv local_viruses.faa local_viruses; $conf::formatdb -i local_viruses  ;";

    system "cd $conf::dbases; rm local_viruses local_plasmids local_organisms;";
    system "cd $conf::dbases; rm formatdb.log";


    $html .= "<b>The databases should now have been created.</b>"
  }
  elsif ($db_state && $db_state eq "no") {
    
    $html .= "<H3>Pheww, they survived this time</H3>";
  }
  else {
    
    $html .= &html::start_form();
    $html .= "<H3>What do you want to (re-)create the localdbases ?</H3>";
    
    $html .= &html::generic_form_element({type=>"radio", 
					  name=>"sure", 
					  value=>"yes"})."Create new databases";

    $html .= &html::generic_form_element({type=>"radio",
					  name=>"sure", 
					  value=>"no", 
					  checked=>1}). "Dont mess with the current databases.";
    
    $html .= "<BR><BR>&nbsp;".
	&html::generic_form_element({type=>"submit", name => "buildbs", value => "Submit"});
    
    $html .= "&nbsp;".&html::generic_form_element({type=>"hidden", name => "page", value => "admin"});
    $html .= "&nbsp;".&html::generic_form_element({type=>"hidden", name => "subpage", value => "sequences"});
    $html .= &access::session_form();
    $html .= &html::end_form();

  }

}


# 
# Build databases from the sequence(s) in the database
# 
# Kim Brugger (26 Feb 2004)
sub buildbs_old {
  my ($db_state) = @_;

  require db::organism;
  require db::sequence;
  require db::gene;
  require db::version;

  my $html = "";

  if ($db_state eq "yes") {
    
    open (ALL_AA,  "> $conf::dbases$dbfile.faa") or die "could not open $conf::dbases$dbfile.faa: $!";
    open (ALL_DNA, "> $conf::dbases$dbfile.fna") or die "could not open $conf::dbases$dbfile.fna: $!";
    
    my @organisms = &db::organism::all();

    foreach my $organism (@organisms) {
      my ($genome, $genes) = _organism_sequence($organism);
      print ALL_DNA $genome;
      print ALL_AA $genes;
    }

    close (ALL_AA)  || die "could not close all_db.fna: $!";
    close (ALL_DNA) || die "could not close all_db.fna: $!";

    # now format and build the blast database files.
    # first format the basic database 
    # first the DNA database
    my $run = "$conf::formatdb -i $conf::dbases$dbfile.fna -pF -oT ";
    system $run;

    # then the AA database
    $run = "$conf::formatdb -i $conf::dbases$dbfile.faa -oT ";
    system $run;

    # for each organism, build an index so we can access subparts of the database
    foreach my $organism (@organisms) {
      _build_index($$organism{'oid'}, $$organism{'name'});
    }
    
    # Remove all the files that is not needed to save space
#    system "rm -f $conf::dbases$dbfile.faa $conf::dbases$dbfile.fna $conf::dbases/*.in $conf::dbases/*.din\n";

    $html .= "<b>The databases should now have been created.</b>"
    
  }
  elsif ($db_state && $db_state eq "no") {
    
    $html .= "<H3>Pheww, they survived this time</H3>";
  }
  else {
    
    $html .= &html::start_form();
    $html .= "<H3>What do you want to (re-)create the localdbases ?</H3>";
    
    $html .= &html::generic_form_element({type=>"radio", 
					  name=>"sure", 
					  value=>"yes"})."Create new databases";

    $html .= &html::generic_form_element({type=>"radio",
					  name=>"sure", 
					  value=>"no", 
					  checked=>1}). "Dont mess with the current databases.";
    
    $html .= "<BR><BR>&nbsp;".
	&html::generic_form_element({type=>"submit", name => "buildbs", value => "Submit"});
    
    $html .= "&nbsp;".&html::generic_form_element({type=>"hidden", name => "page", value => "admin"});
    $html .= "&nbsp;".&html::generic_form_element({type=>"hidden", name => "subpage", value => "sequences"});
    $html .= &access::session_form();
    $html .= &html::end_form();

  }

}


# 
# 
# 
# Kim Brugger (26 Feb 2004)
sub del_dbs {
  my ($sure) = @_;
  
  my $html = "";

  
  if ($sure && $sure eq "yes") { 
   
    if (system "rm -rf $conf::dbases/*" == 0) {
      $html .= "<H3>Deleted the local databases</H3>";
    }
    else {
      $html .= "<h3>Could not delete the local databases, contact the administrator or check the log.</h3>";
    }

  }
  elsif ($sure && $sure eq "no") {
    
    $html .= "<H3>Deletion cancelled</H3>";
  }
  else {
    $html .= &html::start_form();
    $html .= "<H3>Are you sure that you want to delete the local dbases ?</H3>";

    $html .= &html::generic_form_element({type=>"radio", 
					  name=>"sure", 
					  value=>"yes"})."Yes";

    $html .= &html::generic_form_element({type=>"radio",
					  name=>"sure", 
					  value=>"no", 
					  checked=>1}). "No";
    
    $html .= "<BR><BR>&nbsp;".
	&html::generic_form_element({type=>"submit", name => "del_dbs", value => "Submit"});
    
    $html .= "&nbsp;".&html::generic_form_element({type=>"hidden", name => "page", value => "admin"});
    $html .= "&nbsp;".&html::generic_form_element({type=>"hidden", name => "subpage", value => "sequences"});
    $html .= &access::session_form();
    $html .= &html::end_form();
  }


  return $html;
}

sub _build_index {
  my ($oid, $name) = @_;

  $name =~ s/^(.).*? (.*)/$1. $2/;
  # build index's for each of the genomes
  my $run = "$conf::formatdb -B $conf::dbases$oid.gi -F $conf::dbases$oid.in -t \"$name\"";
  system $run;
  
  #and linke the index to the AA-genome database
  $run = "$conf::formatdb -i $conf::dbases$dbfile.faa -F $conf::dbases$oid.gi -L $conf::dbases$oid -t \"$name\"";
  system $run;
  
  # build index's for each of the genomes
  $run = "$conf::formatdb -B $conf::dbases$oid.gid -F $conf::dbases$oid.din -t \"$name\"";
  system $run;
  
  #and linke the index to the DNA-genome database
  $run = "$conf::formatdb -pF -i $conf::dbases$dbfile.fna -F $conf::dbases$oid.gid -L $conf::dbases$oid -t \"$name\"";
  system $run;
}

sub _organism_sequence {
  my ($organism) = @_;
  
  # First find information about the organism, and version
  my $version = &db::version::latest($$organism{oid});
  if (! $version ) {
    print STDERR "Could not find an assembly id for '$$organism{name}'\n";
    return -1;
  }
  print STDERR "Organism has version : '$$version{version}' aka vid:$$version{vid}\n";

  # find all the DNA sequence, and save it
  my @sequences = &db::sequence::fetch_organism($$organism{oid}, $$version{vid});
  my $DNA;
  foreach my $sequence (@sequences) {
    $DNA .= ">sid:$$sequence{sid} $$sequence{name} [$$organism{name}] version: $$version{vid}\n";
    $DNA .= &kernel::nicefasta($$sequence{sequence});
  }

  # now all the genes (in AA format), and lets save them also.
  my @genes = &db::gene::fetch_organism($$organism{oid}, $$version{vid});
  my $AA;
  foreach my $gene (@genes) {
    # We only want to have the genes that can be described as ORFs in the AA db :)
    if ($$gene{type} eq 'ORF' || $$gene{type} eq 'CDS') {
      $$gene{sequence} = &kernel::translate($$gene{sequence});
      $AA .= ">gid:$$gene{gid} $$gene{name} [$$organism{'name'}]\n";
      $AA .= &kernel::nicefasta($$gene{sequence});
    }
  }


  return ($DNA,$AA);
}


sub _organism_sequence_old {
  my ($organism) = @_;
  
  # First find information about the organism, and version
#print   "ORGANISM $$organism{name} HAS OID = $$organism{oid}\n";
  my $version = &db::version::latest($$organism{oid});
  if (! $version ) {
    print STDERR "Could not find an assembly id for '$$organism{name}'\n";
    return -1;
  }
#  print "Organism has version : '$$version{version}' aka vid:$$version{vid}\n";


  # find all the DNA sequence, and save it
  my @sequences = &db::sequence::fetch_organism($$organism{oid}, $$version{vid});
  open (OUTFILE, ">$conf::dbases/$$organism{'oid'}.din") or die "could not open $conf::dbases/$$organism{'oid'}.din: $!";
  my $DNA;
  foreach my $sequence (@sequences) {
    print OUTFILE "$$sequence{sid}\n";
    $DNA .= ">gi|$$sequence{sid} $$sequence{name} [$$organism{name}] version: $$version{vid}\n";
    $DNA .= &kernel::nicefasta($$sequence{sequence});
  }
  close (OUTFILE) || die "could not close $$organism{'short_name'}.fna: $!";

  # now all the genes (in AA format), and lets save them also.
  my @genes = &db::gene::fetch_organism($$organism{oid}, $$version{vid});
  open (OUTFILE, ">> $conf::dbases/$$organism{'oid'}.in") or die "could not open $conf::dbases/$$organism{'oid'}.in: $!";
  my $AA;
  foreach my $gene (@genes) {
    # We only want to have the genes that can be described as ORFs in the AA db :)
    if ($$gene{type} eq 'ORF') {
      print OUTFILE "$$gene{gid}\n";
      
      $$gene{sequence} = &kernel::translate($$gene{sequence});
      $AA .= ">gi|$$gene{gid} $$gene{name} [$$organism{'name'}]\n";
      $AA .= &kernel::nicefasta($$gene{sequence});
    }
  }
  close (OUTFILE) or die "could not close $$organism{'short_name'}.faa: $!";


  return ($DNA,$AA);
}


# 
# Handles the cluster stuff for the system.
# 
# Kim Brugger (16 Mar 2004)
sub clusters {
  my ($sure) = @_;

  my $html = "";
  
  if ($html::parameters{'create_clu'}) {
    
    my $tmpin  = &kernel::tmpfile();
    my $tmpout = &kernel::tmpfile();
#    print STDERR "CLUSTER::: things will be saved in : $tmpfile\n";
    open OUTFILE, "> $tmpin" || die "Could not open '$tmpin': $!\n";

    require db::gene;
    my @genes = &db::gene::all();
    
    foreach my $gene (@genes) {
      print OUTFILE ">gid:$$gene{'gid'} $$gene{'name'}\n".
	  &kernel::nicefasta(&kernel::translate($$gene{'sequence'},0));
    }
    
    system "$conf::formatdb -pT -i $tmpin";
    
    my $datefile = &kernel::timefile() . ".cluster";
    my $blastall = $conf::blastall;
    
    my $run = "$blastall -d $tmpin -p blastp -e 0.1 -FF -i $tmpin -o $tmpout; ";
    $run .= "mv $tmpout $conf::runsdir/$datefile; ";
    $run .= "rm $tmpin; ";

    &kernel::create_system_child($run);
    
#    print STDERR "RUNNING :: $run\n";
    
    $html .= "<h3>The data is now being computed, please check back later to import of the data.<h3>";
    
  }
  elsif ($html::parameters{'delete_clu'}) {
    
    require db::cluster;

    &db::cluster::delete_all();
    
    $html .= "<h3> Deleted all the cluster information, well you can recalculate it...</H3>";
    
  }
  elsif ($html::parameters{import_clu}) {
 
    if ($html::parameters{'minpos'}) {

      require cluster;

      $html .= "<h3>Debugging Junk</h3><PRE>\n";
      my $clusters = cluster::cluster_genes($conf::runsdir.$html::parameters{'file'}, 
					    $html::parameters{'minpos'}, $html::parameters{'maxgap'}, 
					    $html::parameters{'mindiff'}, $html::parameters{'maxdiff'});



      my @colours = (1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16,17, 18, 19,
		     20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32,33, 34, 35, 36, 37, 38, 39,
		     40, 41, 42, 43, 44, 45, 46, 47, 48, 49);


      foreach my $cluster ( @$clusters) {

	

#	print STDERR  "CID : $cid == " . join(",", @members) . "\n";
	@colours = (1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16,17, 18, 19,
		    20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32,33, 34, 35, 36, 37, 38, 39,
		    40, 41, 42, 43, 44, 45, 46, 47, 48, 49) 
	    if (!@colours);
	
	my $colour = pop @colours;
	$cluster =~ s/gid://g;
	my @members = split(" ", $cluster);
	next if (@members <=1);
	my $cid = $members[0];
	foreach my $member (@members) {
	  next if (!$member);
	  my %call_hash = (gid =>     $member, 
			   cid =>     $cid, 
			   ccolour => $colour);
	  
	  &db::gene::update(\%call_hash);
	}    

	$html .= "CID:$cid == @members\n";;
      }
      $html .= "</PRE>";
    }
    else {
      my @cells;
    
      opendir DIR, $conf::runsdir || die "Could not open '$conf::runsdir': $!\n";
      my @files = readdir DIR;
      closedir DIR;
      
      @files = sort {$b cmp $a} @files;

      my @tmp;
      for (my $i = 0; $i< @files; $i++) {
	push @tmp, $files[$i] if ($files[$i] =~ /\.cluster$/);
      }
      
      @files = @tmp;

      push @cells, ["Select sequence", 
		  html::generic_form_element({type=>'popup', name=>'file', values=>\@files, })];

      push @cells, ["Minumum \% positives: ",
		    &html::generic_form_element({type=>"label", name => "minpos", value=>"80"})];
      
      push @cells, ["Maximum gaps allowed: ",
		    &html::generic_form_element({type=>"label", name => "maxgaps", value=>"10"})];
      
      push @cells, ["Minumum \% length difference: ",
		    &html::generic_form_element({type=>"label", name => "mindiff", value=>"80"})];
      
      push @cells, ["Maximum \% length difference: ",
		    &html::generic_form_element({type=>"label", name => "maxdiff", value=>"115"})];
      
      push @cells, ["&nbsp",
		    &html::generic_form_element({type=>"submit", name=>"import_clu", 
						 value=>"Start Import"})];
      
      $html .= html::start_form('mutagen.pl');
      
      $html .= html::style::center(html::table(\@cells, 1));
      
      $html .= &html::generic_form_element({type=>'hidden', name=>'page',     value=>"admin"});
      $html .= &html::generic_form_element({type=>'hidden', name=>'subpage',  value=>"sequences"});
      $html .= &html::generic_form_element({type=>'hidden', name=>'clusters', value=>"1"});
      
      $html .= &access::session_form();
      $html .= html::end_form();
    }
  }
  elsif ($html::parameters{import_tribe}) {
    if ($html::parameters{'file'}) {

      require tribe_mcl;


      $html .= "<h3>Clustering genes using tribe-mcl</h3><PRE>\n";
      my $clusters =  &tribe_mcl::cluster_genes($conf::runsdir.$html::parameters{'file'}, 
						$html::parameters{'I'});
      
      $html .= "<PRE>\n";

      my @colours = (1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16,17, 18, 19,
		     20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32,33, 34, 35, 36, 37, 38, 39,
		     40, 41, 42, 43, 44, 45, 46, 47, 48, 49);
      foreach my $cluster (@$clusters) {
	@colours = (1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16,17, 18, 19,
		    20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32,33, 34, 35, 36, 37, 38, 39,
		    40, 41, 42, 43, 44, 45, 46, 47, 48, 49) 
	    if (!@colours);

	chomp $cluster;
	$cluster =~ s/gid://g;
	my @members = split (" ",$cluster);
	next if (@members <= 1);
	my $cid = $members[0];
	my $colour = pop @colours;

	require db::gene;
	foreach my $member (@members) {
	  next if (!$member);
	  my %call_hash = (gid =>     $member, 
			   cid =>     $cid, 
			   ccolour => $colour);
	  
	  &db::gene::update(\%call_hash);
	}
	$html .= "CID:$cid == @members\n";;
	
      }    
      
      $html .= "</PRE>";
    }
    else {
      my @cells;
    
      opendir DIR, $conf::runsdir || die "Could not open '$conf::runsdir': $!\n";
      my @files = readdir DIR;
      closedir DIR;
      
      @files = sort {$b cmp $a} @files;

      my @tmp;
      for (my $i = 0; $i< @files; $i++) {
	push @tmp, $files[$i] if ($files[$i] =~ /\.cluster$/);
      }
      
      @files = @tmp;

      push @cells, ["Select sequence", 
		  html::generic_form_element({type=>'popup', name=>'file', values=>\@files, })];

      push @cells, ["Matrix inflation value (2.0-10.0: ",
		    &html::generic_form_element({type=>"label", name => "I", value=>"2.0"})];
      
      push @cells, ["&nbsp",
		    &html::generic_form_element({type=>"submit", name=>"import_tribe", 
						 value=>"Start Import"})];
      
      $html .= html::start_form('mutagen.pl');
      
      $html .= html::style::center(html::table(\@cells, 1));
      
      $html .= &html::generic_form_element({type=>'hidden', name=>'page',     value=>"admin"});
      $html .= &html::generic_form_element({type=>'hidden', name=>'subpage',  value=>"sequences"});
      $html .= &html::generic_form_element({type=>'hidden', name=>'clusters', value=>"1"});
      
      $html .= &access::session_form();
      $html .= html::end_form();
    }
  } 
  else {
    my @cells = ([[
		   &html::generic_form_element({type=>'submit', name=>'create_clu', 
						value=>"Calculate new gene clusters"}), 
		   
		   &html::generic_form_element({type=>'submit', name=>'import_clu', 
						value=>"Calculated gene clusters (MUT)"}),

		   &html::generic_form_element({type=>'submit', name=>'import_tribe', 
						value=>"Calculate clusters using tribe-mcl (EXP)"}),

		   &html::generic_form_element({type=>'submit', name=>'delete_clu', 
						value=>"Delete current gene cluster information"})
		   ],
		  ]);
    
    
    $html .= html::start_form('mutagen.pl');
    $html .= html::style::center(html::table(@cells, 1));
    $html .= &html::generic_form_element({type=>'hidden', name=>'page',     value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage',  value=>"sequences"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'clusters', value=>"1"});
    

    $html .= &access::session_form();
    $html .= html::end_form();
  }

  
  return $html;
}

# 
# Runs a simple orfinder on a selected sequence
# 
# Kim Brugger (16 Mar 2004)
sub orfinder {
  my ($sure) = @_;

  my $html = "";
  
  if ($html::parameters{'sid'}) {
    
    require db::sequence;
    require tools::ORFinder;
    my $sequence = &db::sequence::fetch($html::parameters{'sid'});

    my @genes = tools::ORFinder::FindORFs($html::parameters{min}, $$sequence{sequence});
    
    require db::genefinder;
	
    foreach my $gene (@genes) {

      if ($$sequence{name} =~ /\ /) {
	$$sequence{name} =~ s/^(.).*? (\w{3}).*/$1$2/;
      }

      my $name = $$sequence{name};
      $name .= "_$$gene{'start'}-$$gene{'stop'}" 
	  if ($$gene{'strand'} eq "+");
      $name .= "_$$gene{'stop'}-$$gene{'start'}" 
	  if ($$gene{'strand'} eq "-");

      
      

      my %call_hash = ('name'       => $name,
		       'start'      => $$gene{'start'},
		       'stop'       => $$gene{'stop'},
		       'strand'     => $$gene{'strand'} eq "+" ? 0 : 1,
		       'sid'        => $html::parameters{'sid'},
		       'source'     => "ORFinder");
      
      my $fid = &db::genefinder::save(\%call_hash);
    }
    
  }
  else {
    $html .= html::start_multiform('mutagen.pl');
    
    require db::sequence;
    require db::version;
    
    my @cells;
  
    my @sequences = &db::sequence::all();
    @sequences = sort {$$a{name} cmp $$b{name}} @sequences;
    
    my %sequence_labels = ();
    my @sid_list;

    
    foreach my $sequence (@sequences) {
      my $version = &db::version::fetch($$sequence{vid});
      
      $sequence_labels{$$sequence{'sid'}} = "$$sequence{'name'} version: $$version{version}";
      push @sid_list, $$sequence{sid};
    }

    push @cells, ["What sequence to analyse ?",

		  &html::generic_form_element({type=>"popup", 
					       name=>"sid", 
					       values=>\@sid_list,
					       labels=>\%sequence_labels,
					       checked=>1})];


    push @cells, ["<BR>Name of the source:<BR>",
		  &html::generic_form_element({type=>'label', name=>'source', value=>'ORFinder'})];

    push @cells, ["<BR>Minimum length:<BR>",
		  &html::generic_form_element({type=>'label', name=>'min', value=>'40'})];
    

    push @cells, ["<BR><BR>&nbsp;",
		  &html::generic_form_element({type=>"submit", name => "orfinder", value => "Submit"})];
    

    $html .= &html::table(\@cells, 1);
    
    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"sequences"});

    $html .= &access::session_form();
    $html .= &html::end_form();
  }
  
  return $html;
}



# 
# Controls access to a sequence based on grid's. Here we add them
# 
# Kim Brugger (28 May 2004)
sub add_group_org {
  my ($sure) = @_;

  require mutagen_html::forms;

  my $html = "<h3>Organism access</h3>\n";


  if ($html::parameters{'oid'} || $html::parameters{'grid'}) {

    require db::organism;

    my $organism = &db::organism::fetch($html::parameters{'oid'});

    if (&access::($html::parameters{'grid'}, $$organism{'grids'})) {
      $html .= "<h2>The group already has access to this organism</h2>";
      return $html;
    }
      

    my %call_hash = ();
    $call_hash{'oid'} = $html::parameters{'oid'};
    $call_hash{'grids'} = &access::id_pack(&access::id_unpack($$organism{'grids'}), 
					   $html::parameters{'grid'}) 
	if ($$organism{'grids'});

    $call_hash{'grids'} = &access::id_pack($html::parameters{'grid'})
	if (!$$organism{'grids'});

    &db::organism::update(\%call_hash);
    $html .= "Added group access to $$organism{'name'}<BR>";
  }
  else {
    $html .= &html::start_form('mutagen.pl');
    $html .= &html::table([["Group:", &mutagen_html::forms::group_popup()],
			  ["Organism name:",&mutagen_html::forms::organism_popup()],
			  [&html::generic_form_element({type=>'reset'}),
			   &html::generic_form_element({type=>'submit', name=>'add_group_org', 
							value=>'Add group access to organism'})]], 1);

    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"sequences"});

    $html .= &access::session_form();
    $html .= &html::end_form();
  }

  return $html;
}

# 
#  Controls access to a sequence based on grid's. Here we remove them
# 
# Kim Brugger (28 May 2004)
sub del_group_org {
  my $html;

  require mutagen_html::forms;

  if ($html::parameters{'oid'} && $html::parameters{'grid'}) {
    require db::organism;

    my $organism = db::organism::fetch($html::parameters{'oid'});

    my %call_hash = ();
    $call_hash{'oid'} = $html::parameters{'oid'};
    
    my $grids = &access::remove($html::parameters{'grid'}, $$organism{grids});


    $call_hash{'grids'} = $grids;
    &db::organism::update(\%call_hash);
    $html .= "Deleted group id : $html::parameters{'grid'} from $$organism{'name'}. $grids<BR>";


  }  
  elsif ($html::parameters{'oid'}) {

    my $organism = db::organism::fetch($html::parameters{'oid'});

#    &core::Dump($organism);

    $html .= &html::start_form('mutagen.pl');
    $html .= &html::table([["Group name:",&mutagen_html::forms::grids_popup(&access::id_unpack($$organism{grids}))],
			   [&html::generic_form_element({type=>'reset'}),
			    &html::generic_form_element({type=>'submit', name=>'del_group_org', 
							 value=>"Select group to delete from organism $$organism{name}"})]], 1);
    
    $html .= &html::generic_form_element({type=>'hidden', name=>'oid',    value=>$html::parameters{'oid'}});
    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"sequences"});
    
    $html .= &access::session_form();
    $html .= &html::end_form();
    

  }
  else {
    

    $html .= &html::start_form('mutagen.pl');
    $html .= &html::table([["Organism name:",&mutagen_html::forms::organism_popup()],
			   [&html::generic_form_element({type=>'reset'}),
			    &html::generic_form_element({type=>'submit', name=>'del_group_org', 
							 value=>'Select organism to delete a group from'})]], 1);
    
    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"sequences"});
    
    $html .= &access::session_form();
    $html .= &html::end_form();
  }
    
  return $html;
}

# 
#  Controls access to a sequence based on grid's. Here we free them, setting guid == undef.
# 
# Kim Brugger (28 May 2004)
sub free_group_org {

  my $html;

  if ($html::parameters{'oid'}) {

    require db::organism;

    my $organism = db::organism::fetch($html::parameters{'oid'});

    my %call_hash = ();
    $call_hash{'oid'} = $html::parameters{'oid'};
    $call_hash{'grids'} = "";
    &db::organism::update(\%call_hash);
    $html .= "Freeed: $$organism{'name'} to all users.<BR>";

  }
  else {
    
    require mutagen_html::forms;

    $html .= &html::start_form('mutagen.pl');
    $html .= &html::table([["Organism name:",&mutagen_html::forms::organism_popup()],
			   [&html::generic_form_element({type=>'reset'}),
			    &html::generic_form_element({type=>'submit', name=>'free_group_org', 
							 value=>'Select organism to free'})]], 1);
    
    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"sequences"});
    
    $html .= &access::session_form();
    $html .= &html::end_form();
  }
    
  return $html;
}


# 
#  Shows what groups have access to what organisms.
# 
# Kim Brugger (28 May 2004)
sub overview_org {

  my $html;

  require db::organism;
  require db::user;

  my @cells;

  my @organisms = db::organism::all();

  foreach my $organism (@organisms) {
    push @cells, ["<B>".$$organism{'name'} . "</B> access:"];

    if (!$$organism{'grids'}) {
      
      push @cells, [undef,"<B>All</B>"];
      
    }
    else {

      foreach my $grid (access::id_unpack($$organism{'grids'})) {
	
	my $group = &db::user::fetch_group($grid);

	push @cells, [undef, $$group{'name'}]

      }
    }
  }

  $html .= html::style::center(html::table(\@cells, 1, 5, 1,undef,undef));
    
  return $html;
}


BEGIN {

}

END {

}

1;


