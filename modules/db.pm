#!/usr/bin/perl -wT
# 
# Interface to the database, these function have been kept as strict as possible 
# 
# 
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;
use DBI;
use core;

package db;
require Exporter;
require AutoLoader;

use db::user;

# set the version for version checking
my $VERSION     = "0.01";

my @ISA = qw(VERSION Exporter AutoLoader);

our @EXPORT = qw();
@ISA = qw(Exporter AutoLoader);
@EXPORT = qw();

use vars qw ($dbh);






BEGIN {
  $dbh = DBI->connect("dbi:mysql:$conf::mysql_dbase", $conf::mysql_user, $conf::mysql_passwd);
}

END { 
  $dbh->disconnect;
};

1;
