#!/usr/bin/perl -w
# 
# Makes sure that all the paths, permissions etc are right.
# 
# 
# Kim Brugger (Apr 2004), contact: brugger@mermaid.molbio.ku.dk

use strict;
use Getopt::Std;
use Data::Dumper;


# find the current working directory.
my $pwd = $ENV{'PWD'};
unless ($pwd) {
  $pwd = `pwd`; 
  chomp $pwd;
}

my $grep = `which egrep`; chomp $grep;

# -v(irgin): for restoring the program defaults
# -c(lean): Removes files that are not part of the standart distribution
my %opts = ();
getopts('vc', \%opts);

my $virgin = 0;
$virgin = 1 if ($opts{'v'});

my %setups = ('path' =>1,
	      'db'=>1,
	      'perl'=>1
	      );

# Let the program begin.
print "\n      Welcome to the setup script for MUTAGEN 4.+\n";
print "--------------------------------------------------------------\n";
print "It is recommended that the program is run as root to alter the \n";
print "ownerships of directories, otherwise the permissions have to be\n";
print "altered, and this is not the best way to do this.\n\n";

print "Paths and available programs needs to be setup for the system.\n";
print "If you are happy with the suggestion in [] just press <entr>\n\n";

## verifying the path to the installation
my $input = '';


if ($setups{'path'}) {
  my $Tip = "MUTAGEN needs to setup the path to the installation";
  print "Tip: $Tip\n" if ($Tip);
  $input = "." if ($virgin);
  until ($input) {
    print "Enter the full path to the MUTAGEN installation [$pwd]? : ";
    $input = <>; chomp $input;
    $input = $pwd unless ($input);
    unless (-d $input) {
      print "the input is not valid (it is not a directory), try again.\n";
      $input = '';
    }
  }
  $pwd = $input;
  
  $pwd =~ s/\//\\\//g;

  patch_files('./cbin/',   '\.pl', '^use lib', "s|^use lib.*\$|use lib '$pwd\/modules/';|");
  patch_files('./modules', '',     '^use lib', "s|^use lib.*\$|use lib '$pwd\/modules/';|");
  patch_files('./bin',     '\.pl', '^use lib', "s|^use lib.*\$|use lib '$pwd\/modules/';|");
  patch_files('./sbin',    '\.pl', '^use lib', "s|^use lib.*\$|use lib '$pwd\/modules/';|");
  patch_files('./tools',   '\.pl', '^use lib', "s|^use lib.*\$|use lib '$pwd\/modules/';|");

  patch_files('modules','conf.pm','\$basedir *?=', 
			"s|^( +\\\$basedir + = \").*?(\";)|\$1$pwd/\$2|");

}


#
# Set up the correct perl to use in the perl scripts ...
#
if ($setups{'perl'}) {
  my $Tip = "\nMUTAGEN requires Perl5 (available from http://www.cpan.org).";
  my $perl = "";
  if ($virgin) {
    $perl = "/usr/bin/perl";
  }
  else {
    $perl = which_binaries('Perl5', 'perl', '-v', 'v(ersion *)?(5|6)', $Tip);
  }
  $perl =~ s/\//\\\//g;

  patch_files('./cbin/',   '\.pl', '^use lib', "s|^#!.*|#!$perl -wT|");
  patch_files('./bin',     '\.pl', '^use lib', "s|^#!.*|#!$perl -wT|");
  patch_files('./sbin',    '\.pl', '^use lib', "s|^#!.*|#!$perl -wT|");
  patch_files('./tools',   '\.pl', '^use lib', "s|^#!.*|#!$perl -wT|");
}


if ($setups{'db'}) {
  undef $input;
  my ($dbname, $user, $passwd);
  my $Tip = "MUTAGEN needs to setup the db information";
  print "\n$Tip\n" if ($Tip);
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

  patch_files('modules','conf.pm','\$mysql_dbase *?=', 
			"s|^( +\\\$mysql_dbase + = \").*?(\";)|\$1$dbname\$2|");

  patch_files('modules','conf.pm','\$mysql_user *?=', 
			"s|^( +\\\$mysql_user += \").*?(\".*)|\$1$user\$2|");

  patch_files('modules','conf.pm','\$mysql_passwd *?=', 
			"s|^( +\\\$mysql_passwd += \").*?(\".*)|\$1$passwd\$2|");


}


# finally we changes the permissions of the various sub folders.

undef $input;
my $Tip = "To enable storage of pictures, reports etc change ownership of some folders";
print "\n$Tip\n" if ($Tip);
$input = "nobody" if ($virgin);
until ($input) {
  print "Enter the user that runs the http server [nobody] : ";
  $input = <>; chomp $input;
  $input = 'nobody' unless ($input);
}

# Changing the folders
`chown -f $input tmp/`        || `chmod -f 777 tmp/`;
`chown -f $input blastdb/`    || `chmod -f 777 blastdb/`;
`chown -f $input runs/`       || `chmod -f 777 runs/`;
`chown -f $input log/`        || `chmod -f 777 log/`;
`chown -f $input backup/`     || `chmod -f 777 backup/`;
`chown -fR $input reports/`   || `chmod -fR 777 reports/`;
#`chown $input /` || `chmod 777 /`;


print "\n\nThe rest of the setup in done in the file : 'modules/conf.pm'.\n";
print "Here you can show paths to external programs, databases etc.\n";
print "\n\nPlease enjoy the system, and please report bugs and ideas for new features\n";


#
# Identifies the position of binary files.
#
sub which_binaries {
  my ($print_name, $file_name, $version_opt, $required_version, $Tip) = (@_);
  my ($prompt, $input);
  my $exec = `which $file_name`; chomp $exec;

  print "$Tip\n" if ($Tip);
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


#
# Patches files: alters different values in the programs/modules.
#
sub patch_files {
  my ($startdir, $file_filter, $content_regex, $mod_regex) = (@_);

  my @dirs;
  
  use File::Find;
  
  find sub  {
    if (defined $File::Find::name && $File::Find::name, -d) {
      push @dirs, $File::Find::name;
    }
  }, $startdir;

  foreach my $dir (@dirs) {
    my @files = split('\n',`egrep -l '$content_regex' $dir/*$file_filter 2> /dev/null`);
    foreach my $file (@files) {
#      print STDERR "F::: $file || egrep -c '$content_regex' $dir/*$file_filter\n";
      
      # check and see if a backup file exists and remove it.
      system "rm -f $file~" if (-e "$file~");
   
      print STDERR "processing '$file': ";      
      if (1) {
	system "cp -f $file $file~";
	open(FF, "<$file") || die "can't open $file\n";
	open(NN, ">$file~") || die "can't open $file~\n";
	while (<FF>) { 
	  print '*' if (eval($mod_regex)); #changes to the $_
	  print NN;
	}
	close(NN);
	close(FF);
	`mv $file~ $file`;
      }
      print  "\n";
    }
  }
  return 1;
}

