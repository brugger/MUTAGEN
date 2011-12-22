#!/usr/bin/perl -wT
# 
# The general parser interface.
# 
# 
# Kim Brugger (Dec 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;

package parser;
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

my %subdirs = ("nr"       => "GBK",
	       "sprot"    => "SP",
	       "cog"      => "COG",
	       "kegg"     => "KEGG",
	       "archaea"  => "archaea",
	       "bacteria" => "bacteria",
	       "local"    => "local",
	       "pfam"     => "pfam");


require db::adc;
# 
# Magic function that identifies the file type based on name, and imports the 
# content into the databasese.
#
# Kim Brugger (17 Jun 2005)
sub magic {
  my ($infile) = @_;
  
  if ($infile =~ /\.nr/) {
    &blast2db($infile, undef, "nr", undef, $conf::dbreports);
  }
  elsif ($infile =~ /\.sprot/) {
    &blast2db($infile, undef, "sprot", undef, $conf::dbreports);
  }
  elsif ($infile =~ /\.archaea/) {
    &blast2db($infile, undef, "archaea", undef, $conf::dbreports);
  }
  elsif ($infile =~ /\.bacteria/) {
    &blast2db($infile, undef, "bacteria", undef, $conf::dbreports);
  }
  elsif ($infile =~ /\.COG/) {
    &COG2db($infile, $conf::dbreports);
  }
  elsif ($infile =~ /\.KEGG/) {
    &KEGG2db($infile, $conf::dbreports);
  }
  elsif ($infile =~ /\.pfam/) {
    &pfam2db($infile, $conf::dbreports);
  }
  elsif ($infile =~ /\.tmhmm/) {
    &tmhmm2db($infile, $conf::dbreports);
  }
  elsif ($infile =~ /\.signalp/) {
    &signalp2db($infile, $conf::dbreports);
  }
  
}



#
# Transfers best hits from the blast-reports to the database and
# places the reports in the correct directories/database.
#
# Kim Brugger (10 Mar 2004)

sub blast2db {
  
  my ($infile,      #
      $min_e,       # If the output should be limited based on evalue
      $source,      # What the source was (database name/alias).
      $remove_self, # checks that the query != best-hit
      $store_db,    # database or directory storage ??
      ) = @_;
  
  require parser::blast;
  my @blasthashes = parser::blast::bestHits($infile);

  foreach my $report (@blasthashes) {
    
    next if ($min_e && $min_e < $$report{'exept'});
    
    #trim the name so it only consists of a gid:[number] tag.
    $$report{'qname'} =~ s/^gid:(\d+).*/gid:$1/;
    
    $$report{'qname'} =~ /^gid:(\d+)/;

    my $gid = $1;

    my %call_hash = (gid    => $gid,
		     name   => $$report{'sname'},
		     score  => $$report{'exept'},
		     source => $source);


    if (&db::adc::fetch($gid, $source)) {
      &db::adc::update(\%call_hash);
    }
    else {
      &db::adc::save(\%call_hash);
    }
  }

  
  if ($store_db) {
    &blastreports2db($infile, $source);    
  }
  else {
    # Finally save the file in the correct directory
    require parser::blast;
    &parser::blast::report2files($infile, $conf::reportsdir."$subdirs{$source}", 1);
  }
}


# 
# 
# 
# Kim Brugger (23 Mar 2004)
sub pfam2db {
  my ($infile,      # Where is the infile
      $store_db,    # database or directory storage ??
      ) = @_;  


  require parser::pfam;
  my $pfams = &parser::pfam::bestHit($infile);

  foreach my $pfam (@$pfams) {
    
    $$pfam{'qname'} = $1 if ($$pfam{'qname'} && $$pfam{'qname'} =~ m/^gid:(\d+)/);
    next if (!$$pfam{'qname'} || !$$pfam{'hits'}[0]);

    
    if ($$pfam{'hits'}[0] && $$pfam{'hits'}[0]{'desc'}) {


      my %call_hash = (gid    => $$pfam{'qname'},
		       name   => $$pfam{'hits'}[0]{'desc'},
		       score  => $$pfam{'hits'}[0]{'evalue'},
		       source => "pfam",
		       other  => $$pfam{'hits'}[0]{'id'});


      my %call_hash2 = (gid    => $$pfam{'qname'},
		       name   => "desc",
		       score  => "evalue",
		       source => "pfam",
		       other  => "id");

      if (&db::adc::fetch($$pfam{'qname'}, "pfam")) {
	&db::adc::update(\%call_hash);
      }
      else {
	&db::adc::save(\%call_hash);
      }
    }
  }


  if ($store_db) {
    &pfamreports2db($infile);    
  }
  else {
    require parser::pfam;
    &parser::pfam::report2files($infile, $conf::reportsdir."pfam/", 1);
  }
}



# 
# 
# 
# Kim Brugger (23 Mar 2004)
sub COG2db {
  my ($infile,
      $store_db,    # database or directory storage ??
      ) = @_;  
  
#  print STDERR "READING DATA FROM $infile\n";


  require COG;
  my $cogs = &COG::prediction($infile);

  foreach my $cog (@$cogs) {
    $$cog{gid} = $1 if ($$cog{gid} =~ /^gid:(\d+)/);
    
    my %call_hash = ("gid"    => $$cog{'gid'},
		     "name"   => $$cog{'name'},
		     "other"  => $$cog{'other'},
		     "source" => "COG");


    if (&db::adc::fetch($$cog{gid}, "cog")) {
      &db::adc::update(\%call_hash);
    }
    else {
      &db::adc::save(\%call_hash);
    }
  }
 
  if ($store_db) {
    print STDERR "Storing the reports in the database\n";
    &blastreports2db($infile, "COG");    
  }
  else {
    require parser::blast;
    &parser::blast::report2files($infile, $conf::reportsdir."$subdirs{cog}", 1);
  }

}

# Creates and stores a kegg map for each pathway.
#
# Currently this does not take organism and version into account
# so lets fix this as soon as possible.
# 
# Kim Brugger (23 Mar 2004)
sub KEGG2db {
  my ($infile,
      $store_db,    # database or directory storage ??
      ) = @_;  
  
  print STDERR "READING DATA FROM $infile\n";

  require KEGG;
  require db::pathways;
  require db::gene;
  
  my ($pathways, $ec2genes, $pathway_names) = &KEGG::link_pathways($infile);

  foreach my $pathway (keys %$pathways) {

    my %organisms = ();
    
    my %genes = ();
    foreach my $ec ( split (" ", $$pathways{$pathway})) {
      foreach my $ec_gene (split(" ",$$ec2genes{$ec})) {

	$ec_gene =~ m/gid:(\d+)/;
	#find where the gene is comming from.
	my $gene = &db::gene::fetch($1);
#	print STDERR "GIDDD $ec $ec_gene $1 $$gene{oid} $$gene{vid}\n";
	$organisms{$$gene{oid}}{$$gene{vid}}{$ec_gene} = $ec;

	$genes{$ec_gene} = $ec;
      }
    }

#    print STDERR "PATHWAY == $pathway\n";
#    &core::Dump(\%organisms);

    foreach my $oid (keys %organisms) {      
      foreach my $vid (keys %{$organisms{$oid}}) {


	next if ((keys %{$organisms{$oid}{$vid}}) <= 2);

	my %call_hash = (oid => $oid,
			 vid => $vid,
			 name => $pathway,
			 description => $$pathway_names{$pathway},
			 gids_ecs => \%{$organisms{$oid}{$vid}});

	&core::Dump(\%call_hash);

	my @ECs;
	foreach my $gid (keys %{$organisms{$oid}{$vid}}) {
	  push @ECs, $organisms{$oid}{$vid}{$gid};
	}

#	print STDERR "FETCHING PICTURE \n";
	my $picture = &KEGG::create_picture($pathway, \@ECs);

	if ($store_db) {
	print STDERR "STORING PICTURE IN DB\n";
	  $call_hash{picture} = $picture;
	  my $pid = &db::pathways::save(\%call_hash);
	}
	else {
	  my $pid = &db::pathways::save(\%call_hash);

	  print STDERR "SAVING IN ::$conf::reportsdir$subdirs{kegg}/$pid.gif\n";
	  open OUTFIL, ">$conf::reportsdir$subdirs{kegg}/$pid.gif" or die "$!\n";
	  binmode OUTFIL;
	  print OUTFIL $picture;
	  close OUTFIL;
	}   
      } 
    }    
  }
}

# 
# Import signalp report to the database.
# 
# Kim Brugger (23 Mar 2004)
sub signalp2db {
  my ($infile) = @_;  
  
  open INFILE, $infile or
      die "Could not open '$infile': $! \n";

  while (<INFILE>) {
    chomp;
    my ($gid, $name, $score) = split(/\t/);
    
    if ($gid =~ s/.*?(\d+).*/$1/) {
      my %call_hash = ('gid'    => $gid, 
		       'name'   => $name, 
		       'score'  => $score, 
		       'source' => "signalp");

      my @adc = &db::adc::fetch ($gid, "signalp");
      if ($adc[0]) {
	&db::adc::update(\%call_hash);
      }
      else {
	&db::adc::save(\%call_hash);
      }
    }
  }
  
}


# 
# Import tmhmm reports to the database
# 
# Kim Brugger (23 Mar 2004)
sub tmhmm2db {
  my ($infile) = @_;  

  open INFILE, $infile or
      die "Could not open '$infile': $! \n";

  while (<INFILE>) {
    chomp;
    my ($gid, $tms, $score) = split(/\t/);
    
    if ($gid =~ s/.*?(\d+).*/$1/) {
      my %call_hash = ('gid'    => $gid, 
		       'name'   => $tms, 
		       'score'  => $score, 
		       'source' => "tmhmm");

      my @adc = &db::adc::fetch ($gid, "tmhmm");
      if ($adc[0]) {
	&db::adc::update(\%call_hash);
      }
      else {
	&db::adc::save(\%call_hash);
      }
    }
  }
}


# 
# Saves the blastfiles in the database. 
# 
# Kim Brugger (21 Jun 2005)
sub blastreports2db {
  my ($infile, $source) = @_;

  return if (!$infile &&  !$source);

  open (INFILE, $infile) || die ("Could not open '$infile': $!");
  
  my $report = "";
  my $gid;

  while (<INFILE>){
    if (/^(BLASTP|BLASTN|BLASTX|TBLASTN|TBLASTX)/ && $report) {

      my @adc = &db::adc::fetch($gid, $source);
      # If there is no entry, then we dont store it
      if (@adc) {
#	die "NO ENTRY: '$gid' '$source' '@adc'\n" if (!@adc);
      
	$adc[0]->{report} = $report;
	&db::adc::update($adc[0]);
      
	#rest the variables so we are ready to the next report.
      }
      $report  ="";
      $gid = "";
    }
    
    $gid = $1 if (/Query= gid:(\d+)/);
    $report .=  $_;
  }


  #
  # One should always remember the last report
  #
  if ($report) {
    my @adc = &db::adc::fetch($gid, $source);
    # If there is no entry, then we dont store it
    return if (!@adc);
    
    $adc[0]->{report} = $report;
    &db::adc::update($adc[0]);
  }
  
}




# 
# Save pfam reports from a infile to the database.
# 
# Kim Brugger (Jun 2005), contact: brugger@mermaid.molbio.ku.dk
sub pfamreports2db {
  my ($infile) = @_;

  open (INFILE, $infile) || die ("could not open '$infile': $!");
  
  my $report = undef;
  my $gid;

  while (<INFILE>){
    if (/^Query sequence:/ && $gid) {

      my @adc = &db::adc::fetch($gid, "pfam");
      # If there is no entry, then we dont store it
      goto EXIT if (!$adc[0]);

      $adc[0]->{report} = $report;
      &db::adc::update($adc[0]);

    EXIT:

      #rest the variables so we are ready to the next report.
      $report  = "";
      $gid = "";

    }
    
    $report .=  $_;
    $gid = $1 if (/Query sequence: gid:(\d+)/);

  }

  if ($report) {
    my @adc = &db::adc::fetch($gid, "pfam");
    # If there is no entry, then we dont store it
    return if (!$adc[0]);
    
    $adc[0]->{report} = $report;
    &db::adc::update($adc[0]);
  }  

}


BEGIN {

}

END {

}

1;


