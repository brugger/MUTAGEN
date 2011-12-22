#!/usr/bin/perl -w
# 
# This script sets up all the important stuff for MUTAGEN v4.+
#
# This program should be run as root, since we have to alter some file permissions
# 
# Kim Brugger (May 2004), contact: brugger@mermaid.molbio.ku.dk

use strict;
use Getopt::Std;
use Data::Dumper;

my $pwd = $ENV{'PWD'};
unless ($pwd) {
  $pwd = `pwd`; 
  chomp $pwd;
}


my %opts = ();

# [-s(id) -p(refix)| -O(ginal)
getopts('v', \%opts);

# Should be used to reset everything before cvs checkin!
my $virgin = 0;
$virgin = 1 if ($opts{'v'});

my %setups = ('path' =>1,
	      'programs'=>0,
	      'perl' => 0,
	      'db' => 1,

	      );

my $grep = `which egrep`; chomp $grep;

print "\nWelcome to the setup script for MUTAGEN\n";
print "-------------------------------------\n";
print "Paths and available programs needs to be setup for the system.\n";
print "If you are happy with the suggestion in [] just press <entr>\n";

## verifying the path to the installation
my $input = '';

if ($setups{'path'}) {
  my $Tip = "MUTAGEN needs to setup the path to the installation";
  print "Tip: $Tip\n" if ($Tip);
  $input = "." if ($virgin);
  until ($input) {
    print "Enter the full path to the MUTAGEN installation [",$pwd,"]? : ";
    $input = <>; chomp $input;
    $input = $pwd unless ($input);
    unless (-d $input) {
      print "the input is not valid (it is not a directory), try again.\n";
      $input = '';
    }
  }
  $pwd = $input;

  patch_files_recursive('./cbin','mutagen.pl','^use lib', "s|^use lib.*|use lib '$pwd/modules/';|");
  patch_files_recursive('./bin', '.*.pl',      '^use lib', "s|^use lib.*|use lib '$pwd/modules/';|");
  patch_files_recursive('./sbin','.*.pl',      '^use lib', "s|^use lib.*|use lib '$pwd/modules/';|");
  patch_files_recursive('./tools','.*.pl',     '^use lib', "s|^use lib.*|use lib '$pwd/modules/';|");
  patch_files_recursive('./modules','.conf.pm','basedir  =', "s|basedir  = .*|basedir  = \"$pwd/\";|");
}

if ($setups{'perl'}) {
## Set up the correct perl to use in the perl scripts ...
  my $Tip = "MUTAGEN requires Perl5 (available from http://www.cpan.org).";
  my $perl = "";
  if ($virgin) {
    $perl = "/usr/bin/perl";
  }
  else {
    $perl = which_binaries('Perl5', 'perl', '-v', 'v(ersion *)?(5|6)', $Tip);
  }
  patch_files_recursive('./bin/',  '.*\.pl', '^#!.*', "s|^#!.*|#!$perl -wT/");
  patch_files_recursive('./cbin/', '.*\.pl', '^#!.*', "s|^#!.*|#!$perl -wT/");
  patch_files_recursive('./sbin/', '.*\.pl', '^#!.*', "s|^#!.*|#!$perl -w/");
  patch_files_recursive('./tools/','.*\.pl', '^#!.*', "s|^#!.*|#!$perl -w/");
}

if ($setups{'db'}) {
  undef $input;
  my ($dbname, $user, $passwd);
  my $Tip = "MUTAGEN needs to setup the db information";
  print "Tip: $Tip\n" if ($Tip);
  $input = "mutagen" if ($virgin);
  until ($input) {
    print "Enter the database identifier (the same word) [mutagen]? : ";
    $input = <>; chomp $input;
    $input = 'mutagen' unless ($input);
  }
  $dbname = $input;

  undef $input;
  $input = "mutagen" if ($virgin);
  until ($input) {
    print "Enter the user identifier (the same word) [$dbname]? : ";
    $input = <>; chomp $input;
    $input = $dbname unless ($input);
  }
  $user = $input;

  undef $input;
  $input = "mutagen" if ($virgin);
  until ($input) {
    print "Enter the password identifier (the same word) [$dbname]? : ";
    $input = <>; chomp $input;
    $input = $dbname unless ($input);
  }
  $passwd = $input;


  patch_files_recursive('modules/','conf.pm','mysql_dbase', 
			"s|^( *\\\$mysql_dbase *= *).*|\$1\"$dbname\";|");

  patch_files_recursive('modules/','conf.pm','mysql_user',  
			"s|^( *\\\$mysql_user *= *).*|\$1\"$user\";|");

  patch_files_recursive('modules/','conf.pm','mysql_passwd', 
			"s|^( *\\\$mysql_passwd *= *).*|\$1\"$passwd\";|");

}

if ($setups{'programs'}) {
  
  my $Tip = "MUTAGEN uses NCBI blast for making multiple alignments, and the web blast. Depending on the setup of blast, you might have to check that this is not a link to the blast executables";
  my $blastall = "";
  if ($virgin) {
    $blastall = "/use/local/blast/bin/blastall";
  }
  else {
    $blastall = which_binaries('blastall', 'blastall', '', '', $Tip);
  }
  $blastall =~ s/\//\\\//g;
  $blastall =~ s/\w*$//;
  patch_files_recursive('/modules',"conf.pm",'^my \$blastdir', 
			's/^(my \$blastdir=).*$/$1"'.$blastall.'";/');


  my $formatdb = "";
  if ($virgin) {
    $formatdb = "/use/local/blast/bin/formatdb";
  }
  else {
    $formatdb =   which_binaries('formatdb', 'formatdb', '', '', "------");
  }

  $formatdb =~ s/\//\\\//g;
  print "FORMATDB $formatdb\n";

  patch_files_recursive('.',"Makefile",'formatdb', 
			's/^(.*?)((\/.*)*?)formatdb (.*)$/$1'.$formatdb.' $4/');
    
}

system "chmod 777 tmp/";
system "chmod 777 blastdb/";
system "chmod -R 777 reports/";
system "chmod  777 runs/";
system "chmod  777 backup/";
system "chmod  777 log/";

sub patch_files_recursive {
  my ($start, $file_filter, $content_regex, $mod_code) = (@_);

  my @dirs;
  
#  print "($mod_code)\n";
#  exit;
  use File::Find;
  
  find sub  {
    if (defined $File::Find::name && $File::Find::name, -d) {
      push @dirs, $File::Find::name;
    }
  }, "$start";

  foreach my $dir (@dirs) {
    my @files = split('\n',`egrep -Hc '$content_regex' $dir/* 2> /dev/null`);
    foreach my $f (@files) {
      my ($fname, $found) = ($f =~ /(.*):(\d+)$/);

#      print STDERR "--->>> '$f' '$fname' '$found' '$file_filter'\n";
      
      next if ($f !~ /$file_filter/);
      next if (!defined $found || $found == 0);
      next if ($dir =~ /\~/);
   
      next if ($fname =~ /~$/);
      
      print STDERR "processing: $fname\n";
      # Delete old work-file
      system "rm -f $fname~" if (-e "$fname~");
      system "cp -f $fname $fname~";
      open(FF, "<$fname") || die "can't open $fname\n";
      open(NN, ">$fname~") || die "can't open $fname~\n";
      while (<FF>) { 
	print '*' if (eval($mod_code)); #changes to the $_
	print NN;
      }
      close(NN);
      close(FF);
      `mv $fname~ $fname`;
      print STDERR "\n";
    }
  }
  return 1;
}


sub which_binaries {
  my ($print_name, $file_name, $version_opt, $required_version, $Tip) = (@_);
  my ($prompt, $input);
  my $exec = `which $file_name`; chomp $exec;

  print "Tip: $Tip\n" if ($Tip);
  if ($exec =~ /no $file_name in/ or $exec =~ /$file_name not found/) {
    $prompt = "Enter the full path of your $print_name installation";
  } else {
    $prompt = "Use $print_name installation [$exec]? ";
  }
  until ($input) {
    print "$prompt: ";
    $input = <>; chomp $input;
    $input = $exec unless ($input);
    unless (-x $input) {
      print "the input is not an executable, try again.\n";
      $input = '';
      next;
    }
    unless (`$input $version_opt 2>&1 1| $grep -cE "$required_version"` > 0) {
      print "the version is incorrect (doesn't match /$required_version/), try again.\n";
      $input = '';
      next;
    }
  }
  return $input;
}

