#!/usr/bin/perl -wT
# 
# Handles the external databases integration with the data in this database.
# 
# 
# Kim Brugger (Dec 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;

package page::admin::external;
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

  my $html = &mutagen_html::headline("External databases");

  my $blastdb  = "/usr/local/blastdb/";

  if ($html::parameters{'search'}) {

    my @external = ({name=>"nr",       type=>"blast",    desc =>"Blast against GenBank"},
		    {name=>"sprot",    type=>"blast",    desc =>"Blast against Swiss-Prot"},
		    {name=>"archaea",  type=>"blast",    desc =>"Blast against archaeal genomes"},
		    {name=>"bacteria", type=>"blast",    desc =>"Blast against bacterial genomes"},
		    {name=>"pfam",     type=>"pfam",     desc =>"Search protein domains (pfam)"},
		    {name=>"signalp",  type=>"signalp",  desc =>"Locate signal peptides (signalp)"},
		    {name=>"tmhmm",    type=>"tmhmm",    desc =>"Locate Trans-Membrane genes (tmhmm)"},
		    {name=>"COG",      type=>"blast",    desc =>"Prediction using COG"},
		    {name=>"KEGG",     type=>"blast",    desc =>"Pathway maps using KEGG"},
#		    {name=>"", type=>"", desc=>},
#		    {name=>"", type=>"", desc=>},
		    );
    my @cells;
    
    foreach my $type (@external) {
      next if ($$type{'type'} eq "blast" && 
	       (! -e "$blastdb$$type{name}" &&
		! -e "$blastdb$$type{name}.psq"&&
		! -e "$blastdb$$type{name}.gi"));
      push @cells, [&html::generic_form_element({type=>"submit", name => "$$type{name}", 
						 value => "$$type{desc}"})];
    }

    push @cells, ["Evalue cutoff: ".
		  &html::generic_form_element({type=>"label", name => "evalue", value=>"1e-6"})];

    $conf::klumpen &&
    push @cells, ["Use cluster if possible ?: ".
		  &html::generic_form_element({type=>"radio", name => "cluster", 
					       value => "yes"}) . "Yes".
		  &html::generic_form_element({type=>"radio", name => "cluster", 
					       value => "no", checked => "1"}) . "No"];
					   
    push @cells, ["Email when done to: ".
		  &html::generic_form_element({type=>"label", name => "email"})];

    $html .= html::start_form('mutagen.pl');

    require db::organism;
    require db::version;

    my @organisms = &db::organism::all();

    my %organism_labels=();
    my @oid_list;

    foreach my $organism (@organisms) {
      
      
      my @versions = &db::version::fetch_all($$organism{oid});

      foreach my $version (@versions) {
	$organism_labels{"$$organism{'oid'}.$$version{vid}"} = 
	    "$$organism{'name'} Version: $$version{version}";
	push @oid_list, "$$organism{'oid'}.$$version{vid}";
      }
    }
    
    push @oid_list, "-1";
    $organism_labels{"-1"} = "All in the database";


    $html .= html::start_form('mutagen.pl');
    
    $html .= "<B>What sequences to seach with:</B><BR>".&html::checkbox_table({type=>'checkbox', 
				    name=>'oids',
				    values=>\@oid_list,
				    labels=>\%organism_labels});


    $html .=  &html::style::center(&html::table(\@cells, 1, undef, undef, undef, undef));
    
    $html .= &html::generic_form_element({type=>'hidden', name=>'external', value=>"1"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'page',     value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage',  value=>"external"});
    $html .= &access::session_form();
    $html .= html::end_form();
    
  }
  elsif ($html::parameters{'import'}) {

    if ($html::parameters{import} eq "Import results from external Dbases") {
      # find the files located in the run dir.
      opendir DIR, $conf::runsdir || die "Could not open '$conf::runsdir': $!\n";
      my @files = readdir DIR;
      closedir DIR;
      
      @files = sort {$b cmp $a} @files;
      
      &core::Dump(@files);
      
      foreach my $file (@files) {
	
	# remove the files that refers to the filesystem.
	next if ($file =~ /^\./);

	# only allow files that we know how to import.
	next if ($file !~ /\.tmhmm$/ &&
		 $file !~ /\.signalp$/ &&
		 $file !~ /\.sprot/ &&
		 $file !~ /\.archaea/ &&
		 $file !~ /\.bacteria/ &&
		 $file !~ /\.nr/ &&
		 $file !~ /\.COG/ &&
		 $file !~ /\.KEGG/ &&
		 $file !~ /\.pfam/ 
		 );

	my $href = "../cbin/mutagen.pl?page=admin&subpage=external&import=$file" . 
	    &access::session_link();

	$html .= "<A HREF='$href'> Import data from file: $file to the database</a><BR>";
      }
    }
    else {
      $html .=  "<h3>Importing data $html::parameters{import}</h3>\n";

      
      if ($html::parameters{'import'} =~ /^(\d{4}-\d{4}-\d{4}\.\w+)$/ ||
	  $html::parameters{'import'} =~ /^(\d{4}-\d{4}-\d{4}\.\w+.out)$/) {

	$html .= "<h3>Started the import, this could take a while</h3>";
	require parser;
	&kernel::create_child(\&parser::magic, "$conf::runsdir/$1");
      }
      else {
	$html .= "<h3> Unknown report file, please alter the name and try again.</h3>";
      }
    }
  }
  elsif ($html::parameters{'external'}) {
    return run_external();
  }
  elsif ($html::parameters{'delete'}) {
    return run_delete();
  }
  else {
    $html .= html::start_form('mutagen.pl');

    my @cells;
  
    push @cells, [&html::generic_form_element({type=>"submit", name => "search", 
					       value => "Search against external Dbases"}),

		  &html::generic_form_element({type=>"submit", name => "import", 
					       value => "Import results from external Dbases"}),

		  &html::generic_form_element({type=>"submit", name => "delete", 
					       value => "Delete old searches"})];
    
    $html .=  &html::style::center(&html::table(\@cells, 1, undef, undef, undef, undef));
    
    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"external"});
    $html .= &access::session_form();
    $html .= html::end_form();
  }

 
  return $html;
}




# 
# 
# 
# Kim Brugger (22 Jun 2005)
sub run_delete {
  my $html = "<h3> For now, log on and do it manually</h3>";

  return $html;
}


# 
# Runs an external perdiction method.
# 
# Kim Brugger (09 Mar 2004)
sub run_external {
  
  require db::organism;
  require db::gene;
  my $html = "";
  
  my $tmpin = &kernel::tmpfile();
  my $datefile = "$conf::runsdir/".&kernel::timefile();
  my $tmpout = &kernel::tmpfile();
  my $run = "";
  open OUTFILE, "> $tmpin" || die "Could not open '$tmpin': $!\n";

  #
  # Check and see if we want all of the genes in the database
  # or only some from a specific organism/sequence.


  my $oids = $html::parameters{'oids'};
  $oids = [$oids] if (ref $oids ne "ARRAY");

  foreach my $oid (@$oids) {
    if ($oid == -1) {
      close OUTFILE;
      open OUTFILE, "> $tmpin" || die "Could not open '$tmpin': $!\n";
      my @genes = db::gene::all();
      
      foreach my $gene (@genes) {
	print OUTFILE ">gid:$$gene{'gid'} $$gene{'name'}\n".
	    &kernel::nicefasta(&kernel::translate($$gene{'sequence'},0));
      }
      last;
    }
    else {

      $oid =~ /(\d+)\.(\d+)/;
      my @genes = db::gene::fetch_organism($1, $2, undef, undef, undef);
	
      foreach my $gene (@genes) {
	print OUTFILE ">gid:$$gene{'gid'} $$gene{'name'}\n".
	    &kernel::nicefasta(&kernel::translate($$gene{'sequence'},0));
      }
    }
  }

  close OUTFILE;

  #
  # Check for the running of a blast thing first.
  # 
  if ($html::parameters{'nr'} || $html::parameters{'sprot'} || 
      $html::parameters{'archaea'} || $html::parameters{'bacteria'} ||
      $html::parameters{'COG'} || $html::parameters{'KEGG'}) {

    my $blastall = $conf::blastall;
    my $blastdb  = $conf::localdbs;

    $blastall = $conf::cblastall if ($html::parameters{cluster} && 
				     $html::parameters{cluster} eq "yes");

    my $db = "nr"    
	if ($html::parameters{'nr'} && (-e $blastdb."nr" || -e $blastdb."nr.psq"));
    $db = 'sprot'    
	if ($html::parameters{'sprot'} && -e $blastdb."sprot");
    $db = 'archaea'  
	if ($html::parameters{'archaea'} && (-e $blastdb."archaea"  || -e $blastdb."archaea.gi"));
    $db = 'bacteria' 
	if ($html::parameters{'bacteria'} && (-e $blastdb."bacteria" || -e $blastdb."bacteria.gi"));
    $db = 'COG' 
	if ($html::parameters{'COG'} && (-e $blastdb."COG" || -e $blastdb."COG.psq"));
    $db = 'KEGG'
	if ($html::parameters{'KEGG'} && (-e $blastdb."KEGG" || -e $blastdb."KEGG.psq"));

    $run = "$blastall -d $blastdb$db -p blastp -FF -i $tmpin -o $tmpout ";

    if ($html::parameters{evalue} =~ /(\d+\.\d+)/) {
      $run .= "-e $1";
    }
    elsif ($html::parameters{evalue} =~ /(\d+e-\d+)/) {
      $run .= "-e $1";
    }
    else {
      $run .= "-e 1";
    }
    $run .= "; ";
      
    $datefile .= ".$db";
    
    if ($html::parameters{cluster} && $html::parameters{cluster} eq "yes") {
      $run .= "mv $tmpout.out $datefile ;";
    }
    else {
      $run .= "mv $tmpout $datefile ;";
    }
					   
    $run .= "rm  $tmpin ;";
    $datefile =~ s/\/.*\///;
    my $email = $1 if ($html::parameters{email} =~ /(\w+@\w+.*)/);
    $run .= "echo 'The external DBase search is finished and are store in $datefile' | mailx -s 'MUTAGEN report' '$email'"
	if ($email);

#    print STDERR "$run\n";

    &kernel::create_system_child($run);
  }
  #
  # Then the pfam search.
  #
  elsif ($html::parameters{'pfam'}) {
    my $db = "/usr/local/blastdb/Pfam_ls";
    my $hmmpfam = "/usr/local/bin/hmmpfam";
    # should we use the cluster ??
    
    $hmmpfam = $conf::chmmpfam if ($html::parameters{cluster});
    
    $run = "$hmmpfam  ";
    if ($html::parameters{evalue} =~ /(\d+\.\d+)/) {
      $run .= "-E $1";
    }
    elsif ($html::parameters{evalue} =~ /(\d+e-\d+)/) {
      $run .= "-E $1";
    }
    else {
      $run .= "-E 1";
    }

    $run .= " -d $db  -i $tmpin -o  $tmpout;";
    $datefile .= ".pfam";

    print STDERR "$run";

    if ($html::parameters{cluster}) {
      $run .= "mv $tmpout.out $datefile ;";
    }
    else {
      $run .= "mv $tmpout $datefile ;";
    }

    

    $run .= "rm  $tmpin ;";
    $datefile =~ s/\/.*\///;
    my $email = $1 if ($html::parameters{email} =~ /(\w+@\w+)/);
    $run .= "echo 'The external DBase search is finished and are store in $datefile' | mailx -s 'MUTAGEN report' '$email'"
	if ($email);
    
    &kernel::create_system_child($run);
  }
  #
  # Running the signalp search at CBS.
  #
  elsif ($html::parameters{'signalp'}) {
    
    require signalp;
    
    $datefile .= ".signalp";
    &kernel::create_child(\&signalp::run, $tmpin, $datefile);
  }
  elsif ($html::parameters{'tmhmm'}) {

    require tmhmm;

    $datefile .= ".tmhmm";
    &kernel::create_child(\&tmhmm::run, $tmpin, $datefile);
  }

  $html .= "<h3>The data is now being computed, please check back later for import of the data.<h3>";
  
  return $html;
}





BEGIN {

}

END {

}

1;


