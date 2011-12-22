#!/usr/bin/perl -wT
# 
# 
# 
# 
# Kim Brugger (Dec 2003), contact: brugger@mermaid.molbio.ku.dk

use strict;

package page::admin;
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

  my $html = "<CENTER><h1>Administrative pages</h1></CENTER>\n";
  $html .= &html::style::hr("70%");
  $html .= &html::style::break();
  
  if ($html::parameters{'subpage'}) {
    if ($html::parameters{'subpage'} eq "user_group") {
      require page::admin::user_group;
      
      $html = &page::admin::user_group::run();
    }
    elsif ($html::parameters{'subpage'} eq "sequences") {
      require page::admin::sequences;

      $html = &page::admin::sequences::run();
    }
    elsif ($html::parameters{'subpage'} eq "backup") {
      require page::admin::backup;

      $html = &page::admin::backup::run();
    }
    elsif ($html::parameters{'subpage'} eq "external") {
      require page::admin::external;

      $html = &page::admin::external::run();
    }
  }

  return $html
}


BEGIN {

}

END {

}

1;


