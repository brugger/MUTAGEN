#!/usr/bin/perl -w
#
# A "Genefinder" (ORF-finder) for the annotation project
#
#Code by K Brugger Apr 2002 (bugger@diku.dk)

use strict;

my $UPSTREAM = 0;


my %contigs = parse_contigs(shift);
my $min_length = 40;
my $upstream   = 16;

my $name = "";
foreach my $key (keys %contigs) {
#  print "$key == ".$contigs{$key}{name}."\n";
  $name = $key;
  trans_all ($contigs{$key}{seq});
}

#
# Translate in all 6 reading frames
#
sub trans_all {
  my($sequence, $limit, $translated) = @_;

  if (1) {
    for (my $i = 0; $i < 3; $i++) {
      $translated = raw_trans(substr($sequence, $i));
      extract_ORFs($translated, length($sequence), $i, 0, $min_length, $sequence);
    }
  }

  if (1) {
    my $rev_seq = reverseDNA($sequence);
    for (my $i = 0; $i < 3; $i++) {
      $translated = raw_trans(substr($rev_seq, $i));
#      print "$translated\n";
      extract_ORFs($translated, length($sequence), $i, 1, $min_length, $sequence);
    }
  }
}


#
# Split up the translated sequence and prints it
#
sub extract_ORFs {
  my($sequence, $seq_len, $offset, $compliment, $limit, $DNA) = @_;
  my $pos = $offset;
  my $endpos;
  $limit = 0 if (not $limit);

#  print $sequence ."\n";

  foreach my $ss (split /\./, $sequence) {
    $endpos = $pos + length ($ss) * 3;

    # trim the sequence to the first M
    if ($ss !~ /^M/) {
      $ss =~ /^(.*?)(M.*)/;
      $ss = $2;
      $ss = "" if (!$ss);
      $pos += length($1) *3 if ($1); #Adjust the start position.
    }

    if (length ($ss) >= $limit) {

      if ($compliment) {
	$pos +=  -3;
	my ($cpos, $cendpos) = ($seq_len - $pos+1, $seq_len - $endpos -2);
	$cpos    += -4;

#	$cendpos += -1;

	if (! $UPSTREAM) {
	  # just a simple score, will be changed.
	  my $score = abs(100/($cendpos-$cpos));
	  $score =~ s/(\d+\.\d{3}).*/$1/;
	  print "$name\tORFinder\tORF\t$cpos\t$cendpos\t$score\t-\t0\n";
#	  print ">$name\_$cpos\-$cendpos\t$cpos\t$cendpos\tcomplement\n";
#	  print "".raw_trans(reverseDNA(substr($DNA, $cendpos -1, 
#					       $cpos - $cendpos +1)),1) . "\n";;
	}
	else {
	  $_ = raw_trans(reverseDNA(substr($DNA, $cendpos -1, $cpos - $cendpos +1)));
	  # how many start codons are there in this ORF ...
	  my $Ms = tr/M/M/;
	  
	  # the position of the first M is ofcause at position 0
	  my $mpos = 0;
	  for (my $i=0;$i<$Ms;$i++) {
	    
	    my ($lcpos, $lcendpos) = ($seq_len - ($pos+$mpos)+1, $seq_len - $endpos -2);
	    $lcpos    += -4;
#	  my ($lcpos, $lcendpos) = ($cpos, $cendpos);
	    
	    my $upstream = reverseDNA(substr ($DNA, $lcpos-3, $upstream));
	    print ">$name\_$cpos\-$cendpos\[$mpos]\n$upstream\n";
	    
	    $_ = raw_trans(reverseDNA(substr($DNA, $lcendpos -1, $lcpos - $lcendpos +1)));
	    /^(..*?)(M.*)$/;
	    $mpos += length($1) *3 if ($1); #Adjust the start position.
#	  print "MM[$mpos] ==== $1 == $2 ($_)\n";
	    last if ($2 && length($2) < $min_length);
	  }
	}
      }
      else {
	$pos    += 1;
	$endpos += 3;
	if (!$UPSTREAM) {

	  my $score = abs(100/($endpos-$pos));
	  $score =~ s/(\d+\.\d{3}).*/$1/;
	  print "$name\tORFinder\tORF\t$pos\t$endpos\t$score\t+\t0\n";

#	  print ">$name\_$pos\-$endpos\t$pos\t$endpos\tdirect\n";
	  
#	  print "".raw_trans(substr($DNA, $pos-1, 
#			      $endpos -$pos +1),1) . "\n";
	}
	else {
	  $_ = raw_trans(substr($DNA, $pos-1, $endpos -$pos +1));
	  # how many start codons are there in this ORF ...
	  my $Ms = tr/M/M/;
	  
	  # the position of the first M is ofcause at position 0
	  my $mpos = 0;
	  for (my $i=0;$i<$Ms;$i++) {
	    
	    my $upstream = substr ($DNA, $pos+2+$mpos - $upstream, $upstream);
	    print ">$name\_$pos\-$endpos\[$mpos]\n$upstream\n";
	    $_ = raw_trans(substr($DNA, $pos-1+($mpos), $endpos -($pos+$mpos) +1),0);
	    
	    /^(..*?)(M.*)$/;
	    $mpos += length($1) *3 if ($1); #Adjust the start position.
#	  print "MM[$mpos] ==== $1 == $2 ($_)\n";
	    last if ($2 && length($2) < $min_length);
	  }
	}
	$endpos -= 3;
      }
    }

    $endpos +=3; #for the stop codon
    $pos = $endpos;
  }
}

#
# Make the complementary DNA strand
#
sub reverseDNA {
  my ($seq) = @_;
  $seq =~ tr /[aAtTgGcC]/[TTAACCGG]/;
  $seq = scalar reverse $seq;
  return $seq;
}

#
# Reads in a fasta formated file and places it in a hashtable
#
sub parse_contigs {
  my ($filename) = @_;
  my %contigs = ();
  my ($name, $id, $seq);
  my $FIL;# = "$filename";
  open ($FIL, $filename)  or die "could not open file $filename : $!";
  
  while (<$FIL>) {
    chomp;
    if (/^\>/) {
      if ($name) { # we have a name and a seq
	($id = $name) =~ s/>\ *//;
	$id =~ s/\ .*//;
	$name =~ s/^\>//;
	$contigs{$id} = {'name' => $name,
			'seq'  => $seq};
	$name = ""; 
	$seq = "";
      }
      $name = $_;
    }
    else {
      $_ =~ tr/atcg/ATCG/;
      $seq .= $_;
    }
  }

  if ($name) { # we have a name and a seq
    ($id = $name) =~ s/>\ *//;
    $id =~ s/\ .*//;
    $name =~ s/^\>//;
    $contigs{$id} = {'name' => $name,
		    'seq'  => $seq};
  }

  return %contigs;
}


#
# Translate the N sequence into a AA sequence
#

sub raw_trans {
  my($sequence) = (@_);

  my %code = ("ATG" => "M", "GTG" => "M", "TTG" => "M",
	      "GCT" => "A", "GCC" => "A", "GCA" => "A", "GCG" => "A",
	      "CGT" => "R", "CGC" => "R", "CGA" => "R",
	      "CGG" => "R", "AGA" => "R", "AGG" => "R",
	      "AAT" => "N", "AAC" => "N",
	      "GAT" => "D", "GAC" => "D", "TGT" => "C",
	      "TGC" => "C",
	      "CAA" => "Q", "CAG" => "Q",
	      "GAA" => "E", "GAG" => "E",
	      "GGT" => "G", "GGC" => "G", "GGA" => "G", "GGG" => "G",
	      "CAT" => "H", "CAC" => "H",
	      "ATT" => "I", "ATC" => "I", "ATA" => "I",
	      "TTA" => "L", "CTT" => "L",
	      "CTC" => "L", "CTA" => "L", "CTG" => "L",
	      "AAG" => "K", "AAA" => "K",
	      "TTT" => "F", "TTC" => "F",
	      "CCT" => "P", "CCC" => "P", "CCA" => "P", "CCG" => "P", 
	      "AGT" => "S", "AGC" => "S", "TCT" => "S", 
	      "TCC" => "S", "TCA" => "S", "TCG" => "S", 
	      "ACT" => "T", "ACC" => "T", "ACA" => "T", "ACG" => "T", 
	      "TGG" => "W",
	      "TAT" => "Y", "TAC" => "Y",
	      "GTT" => "V", "GTC" => "V", "GTA" => "V", 
	      "TAG" => ".", "TAA" => ".", "TGA" => ".");
  
  my $translated = "";
  my $first_M = 1;
  for (my $i = 0; $i < length $sequence; $i+=3) {
    my $codon = substr($sequence,$i,3);
    if ($code{$codon}) {
      $translated .= $code{$codon} ;
    }
    # If the codon contains an X this means that 2 contigs have been joined here.
    # This will be translated into a stopcodon since we have no idea about the sequence here.
    elsif ($codon =~ /X/) {
      $translated .= ".";
    }
    # We do not know how to translate this so insert an X
    else {
      $translated .= "X";
    }
  }
  return $translated;
}


sub trans {
  my($sequence, $onlu_one_M) = (@_);

  my %alt_start_codon = ("ATG" => "M", "GTG" => "M", "TTG" => "M");

  my %code = ("ATG" => "M", 
	      "GCT" => "A", "GCC" => "A", "GCA" => "A", "GCG" => "A",
	      "CGT" => "R", "CGC" => "R", "CGA" => "R", 
	      "CGG" => "R", "AGA" => "R", "AGG" => "R",
	      "AAT" => "N", "AAC" => "N", 
	      "GAT" => "D", "GAC" => "D", "TGT" => "C",
	      "TGC" => "C",
	      "CAA" => "Q", "CAG" => "Q",
	      "GAA" => "E", "GAG" => "E",
	      "GGT" => "G", "GGC" => "G", "GGA" => "G", "GGG" => "G", 
	      "CAT" => "H", "CAC" => "H",
	      "ATT" => "I", "ATC" => "I", "ATA" => "I",
	      "TTA" => "L", "CTT" => "L", "TTG" => "L",
	      "CTC" => "L", "CTA" => "L", "CTG" => "L", 
	      "AAG" => "K", "AAA" => "K", 
	      "TTT" => "F", "TTC" => "F",
	      "CCT" => "P", "CCC" => "P", "CCA" => "P", "CCG" => "P", 
	      "AGT" => "S", "AGC" => "S", "TCT" => "S", 
	      "TCC" => "S", "TCA" => "S", "TCG" => "S", 
	      "ACT" => "T", "ACC" => "T", "ACA" => "T", "ACG" => "T", 
	      "TGG" => "W",
	      "TAT" => "Y", "TAC" => "Y",
	      "GTT" => "V", "GTC" => "V", "GTA" => "V", "GTG" => "V", 
	      "TAG" => ".", "TAA" => ".", "TGA" => ".");
  
  my $translated = "";
  my $first_M = 1;
  for (my $i = 0; $i < length $sequence; $i+=3) {
    my $codon = substr($sequence,$i,3);
    if ($onlu_one_M && $first_M && $alt_start_codon{$codon}) {
	$translated .= $alt_start_codon{$codon};
	$first_M = 0;
      
    }
    elsif ($code{$codon}) {
      $translated .= $code{$codon} ;
    }
    else {
      $translated .= "X" ;
    }
  }
  return $translated;
}

