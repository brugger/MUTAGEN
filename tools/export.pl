#!/usr/bin/perl -w
# 
# Small program that exports the code (and the code only), making
# it possible to move mutagen and continue development. 
# 
# Basic you properly dont need to use this program.
#
# Kim Brugger (Apr 2004), contact: brugger@mermaid.molbio.ku.dk

use strict;
use Data::Dumper;

my $todir = shift || die "Please provide a directory to copy the source to ...\n";

$todir .= "/" if ($todir !~ /\/$/);

#check that the directory exists and that we can write to it....
die "Not a valid directory: '$todir'\n" if (! -f $todir && ! -d $todir);
die "Cannot write to : '$todir'\n" if (!-w $todir);


my @files = `find ./ `;

foreach my $file (@files) {
  chomp $file;
  $file =~ s/^\.\///;
  next if ($file =~ /gz$/);
  next if ($file =~ /\~$/);
  next if ($file =~ /tmp\//);
  next if ($file =~ /runs\//);
  next if ($file =~ /backup\//);
  next if ($file =~ /^\.$/);
  next if ($file =~ /^\.\.$/);
  next if ($file =~ /^$/);

  # do we have a directory...
  if (-d $file) {
    print "Makeing dir :: $todir$file\n";
    system "mkdir $todir$file";
#    sleep (10);
    next;
  }
  
  print "$file\n";
  
  system "cp -R $file $todir$file \n";
}



