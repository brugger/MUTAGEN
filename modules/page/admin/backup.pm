#!/usr/bin/perl -wT
# 
# Makes it possible to back up the system using the web interface and restore the database 
# if something has been broken in it.
# 
# Kim Brugger (Feb 2004), contact: brugger@mermaid.molbio.ku.dk

use strict;

package page::admin::backup;
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

  $html .= &mutagen_html::headline("System backup");

  if ($html::parameters{'create_bu'}) {

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) =
	gmtime(time);
    
    $year += 1900;
    $mon++;

    my $now = sprintf("%d-%02d%02d-%02d%02d", $year, $mon, $mday, $hour, $min);

    system "$conf::mysqldump -u$conf::mysql_user -p$conf::mysql_passwd $conf::mysql_dbase > $conf::backupdir/$now\.sql";
    $html .= "Backed up the database in file $now\.sql";
  }
  elsif ($html::parameters{'restore_bu'}) {

    # find the files located in the backup dir.
    opendir DIR, $conf::backupdir || die "Could not open '$conf::backupdir': $!\n";
    my @files = readdir DIR;
    closedir DIR;

    @files = sort {$b cmp $a} @files;

    foreach my $file (@files) {
      next if ($file !~ /\.sql$/);
      my $href = "../cbin/mutagen.pl?page=admin&subpage=backup&restore=$file";
      $href .= &access::session_link();
      $html .= "<A HREF='$href'> Restore back from file: $file</a><BR>"
    }
  }
  elsif ($html::parameters{'restore'} &&
	 $html::parameters{'restore'} =~ /^(\d{4}-\d{4}-\d{4}\.sql)$/ &&
	 -e "$conf::backupdir$html::parameters{'restore'}") {
    my $file = $1;
    
    # first delete the tables.
    system  "echo 'drop table adc, annotation, gene, genefinder, groups, organism, sequence, session, user, version' | $conf::mysql -u$conf::mysql_user -p$conf::mysql_passwd $conf::mysql_dbase";
    system "$conf::mysql -u$conf::mysql_user -p$conf::mysql_passwd $conf::mysql_dbase < $conf::backupdir$file";
    $html .= "Restored the database from file $file";
    
  }
  else {
    my @cells = ([[
		   &html::generic_form_element({type=>'submit', name=>'create_bu', 
						value=>"Create new backup"}), 
		   
		   &html::generic_form_element({type=>'submit', name=>'restore_bu', 
						value=>"Restore backup (rollback)"})
		   ],
		  ]);
    
    
    $html .= html::start_form('mutagen.pl');
    $html .= html::style::center(html::table(@cells, 1));
    $html .= &html::generic_form_element({type=>'hidden', name=>'page',    value=>"admin"});
    $html .= &html::generic_form_element({type=>'hidden', name=>'subpage', value=>"backup"});

    $html .= &access::session_form();
    $html .= html::end_form();
  }



  return $html;
}


BEGIN {

}

END {

}

1;


