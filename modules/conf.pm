#!/usr/bin/perl -wT
# 
# Setup of the system, so just alter the path names from here. I will try to
# collect all setup stuff here.
# 
# Kim Brugger (Mar 2004), contact: brugger@mermaid.molbio.ku.dk

use strict;

package conf;
require Exporter;
require AutoLoader;

# set the version for version checking
my $VERSION     = "0.01";

my @ISA = qw(VERSION Exporter AutoLoader);

our @EXPORT = qw();
@ISA = qw(Exporter AutoLoader);
@EXPORT = qw();


#exported variables.
use vars qw ($basedir
	     $blastall
	     $formatdb
	     $tmpdir
	     $bindir
	     $sbindir

	     $guests
	     $dbases
	     $localdbs
	     $errdir
	     $errlog
	     $mysqldump
	     $mysql
	     $reportsdir
	     $backupdir
	     $runsdir
	     $gracetime
	     $mysql_dbase
	     $mysql_user
	     $mysql_passwd

	     $cblastall
	     $chmmpfam
	     $t_coffee
	     $muscle
	     
	     $use_mutagen_log
	     $dbreports	     
	     $html_compare
	     $html_pathways
	     $html_light
	     $html_version
	     $html_level

	     $html_header
	     $html_body 
	     $html_link
	     $html_alink
	     $html_vlink
	     $html_hcolour
	     $css

	     $klumpen
	     $limit
	     );

BEGIN {

  # some basic directories, edit for your own system. But this setup should
  # work for most systems, every thing is kept neat with in a single directory.
  $basedir  = "/data/www/sulfolobus.org/";

  # you probably do not need to alter these 
  $tmpdir     = $basedir."tmp/";
  $reportsdir = $basedir. "reports/";
  $backupdir  = $basedir. "backup/";
  $runsdir    = $basedir. "runs/";
  $tmpdir     = $basedir. "tmp/";
  $bindir     = $basedir. "bin/"; 
  $sbindir    = $basedir. "sbin/"; 

  $dbases     = $basedir. "blastdb/";
  $errdir     = $basedir. "log/";
  $errlog     = $errdir.  "mutagen_4.errlog";


  # Setup some local behaviour and information to connect to databases etc

  # do you allow guests ?? (people do not have to login, but cannot annotate.)
  $guests = 1; # Yes
#  $guests = 0; # No

  # Time in minuttes before people gets logged out automatically
  $gracetime = 30;
  
  # Information for connecting to the database.
  $mysql_dbase  = "sulfolobus";
  $mysql_user   = "sulfolobus";
  $mysql_passwd = "sulfolobus";

  # Should be fill up the apache log or the local log
  $use_mutagen_log = 1; # Use the local one
#  $use_mutagen_log = 0; # Use apaches log system.


  # where the reports from the different external databases
  # should be saved.
  $dbreports = 1; # In the database
#  $dbreports = 0; # In a subdir structute


  # How should the things be presented:
  # works with |'ing (masking) the following values. 
  # Add a values and things will appear/disappear.
  # DO NOT ALTER THESE VALUES THOUGH.
  $html_compare  = 1;
  $html_pathways = 2;
  $html_version  = 4;
  $html_light    = 8;
  # Alter this:
  $html_level    = $html_compare | $html_pathways | $html_light;# |$html_compare | $html_version;
  
  # The system relies on some external installed programmes, please
  # alter the paths so the system knows where these programs dwell.

  # NCBI blast package.
  $blastall  = "/usr//bin/blastall";
  $formatdb  = "/usr//bin/formatdb";
  $localdbs  = "/usr/local/blastdb/";

  $mysqldump = "/usr/bin/mysqldump";
  $mysql     = "/usr/bin/mysql";

  # for making multiple alignments
  $t_coffee  = "/usr/bin/t_coffee";
  $muscle    = "/usr/bin/muscle";


  # Setup for the html stuff, uncomment if you want to change the
  # default colours and headers, uncomment and alter things and it
  # will work almost like magic(tm).

  # The header name 
  $html_header  = "The Sulfolobus Database";
  #colour scheme
#  $html_body    = "#719179";
#  $html_link    = "#ffff00";
#  $html_alink   = "#ff0000";
#  $html_vlink   = "#ffff00";
#  $html_hcolour = "#517159";
  $css = "../cbin/mutagen.css";

  # for "klumpen" our local cluster system, dont mess with this, 
  # it will not work for you anyway
  $klumpen = 1;
  $cblastall = "sudo -u klumpen /usr/local/bin/cblastall";
  $chmmpfam = "sudo -u klumpen /usr/local/bin/chmmpfam";
  $limit   = 1; # add limited access....
}

END {

}

1;


