#!/usr/bin/perl

use strict;
use warnings;
no warnings 'utf8';
use Data::Dumper;
use Digest::MD5 qw(md5_hex);
use LCS;
use Text::CSV;
use Text::CSV_XS;
use Time::Piece;
use Pod::Usage;

my $filename = shift @ARGV;

my @solutions = ();

my @tasks_to_skip = ();

my $tasks_to_skip_filename = "trivialtasks.cfg";

# calculates a pair of fingerprints (sentence_fingerprint, formula_fingerprint)
# by the given string (field 'comment' from the CSV)
# usage: create_fingerprint($comment)
sub create_fingerprint($) {
  my $comment = shift;
  my @sentences = ();
  my @formulas = ();
  my $sentence_buf, my $formula_buf;
  my $flag = 0;

  $comment =~ s/\$\$/\$/g; # $$ -> $
  $comment =~ s/\!\[ImageFile\]\(.*?\)/IMG/g; # non-greedy search for image names
  $comment =~ s/\\n//g; # remove \n
  $comment =~ s/\n//g; # remove \n
  $comment =~ s/\\r//g; # remove \r
  $comment =~ s/\r//g; # remove \r
  $comment =~ s/\'//g; # remove '
  $comment =~ s/\\\\/\\/g; # \\ -> \

  foreach my $char (split //, $comment) {
    if ($char eq "\$") { # border of the formula of the form $...$
      $formula_buf=$formula_buf.$char;
      if (!$flag and defined($sentence_buf)) { # was a sentence and got a formula
        push(@sentences, $sentence_buf);
        undef($sentence_buf);
      }
      if ($flag and defined($formula_buf)) { # formula ended
        push(@formulas, $formula_buf);
        undef($formula_buf);
      }
      $flag=!$flag; 
    } elsif ($flag) {
      $formula_buf=$formula_buf.$char;
    } else {
      $sentence_buf=$sentence_buf.$char;
    }
  }
  if (defined($sentence_buf)) {
    push(@sentences, $sentence_buf);
    undef($sentence_buf);
  }
  filter_arrays(\@sentences,\@formulas);
  return merge_arrays(\@sentences,\@formulas);
}

# this function filters arrays of sentences and formulas:
# Sentences:
## * remove "a", "the"
## * remove signs, spaces
## * remove TeX colors
# Formulas:
## * remove $
## * remove TeX spaces: \! \; \ \quad \qquad
## * remove TeX displaystyle command
## * remove TeX colors
## * all the greek symbols turned into G
## * all the variables (Z,X,Y,W,U,V,A,B) turned into V
## * all the indeces (J,K,N) turned into I
## * remove spaces
# All the letters turned into upper case
# usage: filter_arrays($sentences_ref,$formulas_ref);
sub filter_arrays($;$) {
  my $s_ref = shift;
  my $f_ref = shift;
  for my $str (@$s_ref) {
    $str =~ s/ a //g; # remove articles
    $str =~ s/ the //g;
    $str =~ s/[.,!?:;#_]//g; # remove signs
    $str =~ s/\s+//g; # remove spaces
    $str = uc($str); # UPPER CASE
    $str =~ s/TEXTCOLOR//g; # remove \textcolor
    $str =~ s/RED//g; # remove color:
    $str =~ s/GREEN//g;
    $str =~ s/BLUE//g;
    $str =~ s/CYAN//g;
    $str =~ s/MAGENTA//g;
    $str =~ s/YELLOW//g;
    $str =~ s/BLACK//g;
    $str =~ s/GRAY//g;
    $str =~ s/WHITE//g;
    $str =~ s/DARKGRAY//g;
    $str =~ s/LIGHTGRAY//g;
    $str =~ s/BROWN//g;
    $str =~ s/LIME//g;
    $str =~ s/OLIVE//g;
    $str =~ s/ORANGE//g;
    $str =~ s/PINK//g;
    $str =~ s/PURPLE//g;
    $str =~ s/TEAL//g;
    $str =~ s/VIOLET//g;
  }
  for my $str (@$f_ref) {
    $str =~ s/\$//g;
    $str = uc($str); # UPPER CASE
    $str =~ s/\\DISPLAYSTYLE//g; # remove displaystyle
    $str =~ s/\\\!//g; # remove \!
    $str =~ s/\\\;//g; # remove \;
    $str =~ s/\\ //g; # remove \ 
    $str =~ s/\\QUAD//g; # remove \quad 
    $str =~ s/\\QQUAD//g; # remove \qquad 
    $str =~ s/TEXTCOLOR//g; # remove \textcolor
    $str =~ s/RED//g; # remove color:
    $str =~ s/GREEN//g;
    $str =~ s/BLUE//g;
    $str =~ s/CYAN//g;
    $str =~ s/MAGENTA//g;
    $str =~ s/YELLOW//g;
    $str =~ s/BLACK//g;
    $str =~ s/GRAY//g;
    $str =~ s/WHITE//g;
    $str =~ s/DARKGRAY//g;
    $str =~ s/LIGHTGRAY//g;
    $str =~ s/BROWN//g;
    $str =~ s/LIME//g;
    $str =~ s/OLIVE//g;
    $str =~ s/ORANGE//g;
    $str =~ s/PINK//g;
    $str =~ s/PURPLE//g;
    $str =~ s/TEAL//g;
    $str =~ s/VIOLET//g;
    $str =~ s/\\ALPHA/G/g; # greek
    $str =~ s/\\BETA/G/g;
    $str =~ s/\\GAMMA/G/g;
    $str =~ s/\\DELTA/G/g;
    $str =~ s/\\EPSILON/G/g;
    $str =~ s/\\VAREPSILON/G/g;
    $str =~ s/\\ZETA/G/g;
    $str =~ s/\\ETA/G/g;
    $str =~ s/\\THETA/G/g;
    $str =~ s/\\IOTA/G/g;
    $str =~ s/\\KAPPA/G/g;
    $str =~ s/\\LAMBDA/G/g;
    $str =~ s/\\MU/G/g;
    $str =~ s/\\NU/G/g;
    $str =~ s/\\XI/G/g;
    $str =~ s/\\OMICRON/G/g;
    $str =~ s/\\PI/G/g;
    $str =~ s/\\RHO/G/g;
    $str =~ s/\\SIGMA/G/g;
    $str =~ s/\\TAU/G/g;
    $str =~ s/\\UPSILON/G/g;
    $str =~ s/\\PHI/G/g;
    $str =~ s/\\CHI/G/g;
    $str =~ s/\\PSI/G/g;
    $str =~ s/\\OMEGA/G/g;
    $str =~ s/X/V/g; # main functional variables
    $str =~ s/Y/V/g;
    $str =~ s/Z/V/g;
    $str =~ s/U/V/g;
    $str =~ s/A/V/g;
    $str =~ s/B/V/g;
    $str =~ s/W/V/g;
    $str =~ s/T/V/g;
    $str =~ s/P/V/g;
    $str =~ s/J/I/g; # indices
    $str =~ s/K/I/g;
    $str =~ s/N/I/g;
    $str =~ s/\s+//g; # remove spaces
  }
}

# merges arrays to be fingerprinted into two fingerprints
# returns statement string and formula string
# usage: merge_arrays($sentences_ref, $formulas_ref)
sub merge_arrays($;$) {
  my $s_ref = shift;
  my $f_ref = shift;
  my $s_result, my $f_result;
  for my $buf (@$s_ref) {
    $s_result=$s_result.$buf;
  }
  for my $buf (@$f_ref) {
    $f_result=$f_result.$buf;
  }
  return $s_result, $f_result;
}

# reads *.csv file, writes *_new.csv file with the additional fingerprint columns,
# inserts solutions into array for comparing
# usage: parse_csv($filename);
sub parse_csv($) {
  my $file = shift;
  if (index($file, ".csv") == -1) {
    die "This program can work only with .csv, but received '$file' $!";
  }
  my $csv = Text::CSV->new({ sep_char => ',', eol => $/ });
  my $new_csv = $file;
  $new_csv =~ s/\.csv/_new\.csv/;

  open(my $in, '<:encoding(UTF-8)', $file) or die "Could not open file '$file' $!";
  open(my $out, '>:encoding(UTF-8)', $new_csv) or die "Could not open file '$new_csv' $!";
  while (my $fields = $csv->getline($in)) {
    my $tasknum = $fields->[0];
    my $author = $fields->[1];
    my $date = $fields->[2];
    $date =~ s/\.[0-9]{6}\+[0-9]{2}:[0-9]{2}//g; # remove microseconds and timezone
    my $comment = $fields->[3];
    (my $s_fingerprint, my $f_fingerprint) = create_fingerprint($comment);
    push @$fields, $s_fingerprint, $f_fingerprint; # let's add a fingerprint columns to the new csv
    $csv->print($out, $fields);
    my @arr = ($tasknum, $author, $date, $comment, $s_fingerprint, $f_fingerprint);
    push(@solutions, \@arr);
  }
  close($in) || die "Could't close file properly";
  close($out) || die "Could't close file properly";
}


sub min($;$) {
  my $a = shift, my $b = shift;
  if ($a <= $b) {
    return $a;
  }
  return $b;
}

# calculates percentage for two nullable arguments
# usage: percentage($l1, $l2, $llcs)
# $llcs - length of the longest common subsequence
sub percentage($;$;$) {
  my $arg1 = shift;
  my $arg2 = shift;
  my $llcs = shift;
  if (not defined($llcs)) {
    $llcs = 0;
  }

  if ((defined $arg1) and ($arg1 != 0)) {
    if ((defined $arg2) and ($arg2 != 0)) {
      return min(($llcs/$arg1)*100, ($llcs/$arg2)*100); 
    }
    return ($llcs/$arg1)*100;
  } elsif ($arg2 != 0) {
    return ($llcs/$arg2)*100;
  }
  return 0; 
}

# calculates llcs for two nullable strings
sub calculate_llcs($;$) {
  my $str1 = shift;
  my $str2 = shift;

  if (((not defined($str1)) or (not defined($str2)))  or (length($str1) == 0 or length($str2) == 0)) {
    return 0;
  }
  my @hash1 = split(//, $str1); # string to array
  my @hash2 = split(//, $str2);

  return LCS->LLCS(\@hash1, \@hash2);
}

# calculates length of the nullable string
sub calculate_length($) {
  my $arg = shift;
  if (defined($arg)) {
    return length($arg);
  }
  return 0;
}

# Runs through all pair of solutions, reports plagiarism to the .report-file
sub compare_fingerprints() {
  my $size = scalar @solutions;
  my $report_file = $filename;
  $report_file =~ s/\.csv/\.report/;
  open(my $out, '>:encoding(UTF-8)', $report_file) or die "Could not open file '$report_file' $!";

  for (my $i = 0; $i < $size; $i = $i + 1) {
    print STDERR (($i/$size)*100)."%\n"; # current progress
    my $s1ref = $solutions[$i];
    my @sol1 = @{$s1ref};
    for (my $j = $i + 1; $j < $size; $j = $j + 1) {
      my $s2ref = $solutions[$j];
      my @sol2 = @{$s2ref};

      my $task1 = $sol1[0];
      my $task2 = $sol2[0];
      next if ((grep( /^$task1$/, @tasks_to_skip)) or (grep( /^$task2$/, @tasks_to_skip)));
      my $author1 = $sol1[1];
      my $author2 = $sol2[1];
 
      if (($task1 eq $task2) and ($author1 ne $author2)) {
        my $statement1 = $sol1[4];
        my $statement2 = $sol2[4];
        my $formula1 = $sol1[5];
        my $formula2 = $sol2[5];
        my $time1 = Time::Piece->strptime($sol1[2],"%Y-%m-%d %H:%M:%S");
        my $time2 = Time::Piece->strptime($sol2[2],"%Y-%m-%d %H:%M:%S");
        my $l1 = calculate_length($statement1);
        my $l2 = calculate_length($statement2);
        my $l3 = calculate_length($formula1);
        my $l4 = calculate_length($formula2);

        my $sentence_llcs = calculate_llcs($statement1, $statement2);
        my $formula_llcs = calculate_llcs($formula1, $formula2);
        my $sentence_percentage = percentage($l1, $l2, $sentence_llcs);
        my $formula_percentage = percentage($l3, $l4, $formula_llcs);
        my $general_percentage = percentage($l1+$l3, $l2+$l4, $sentence_llcs+$formula_llcs);

        if (($general_percentage >= 75) and (($l1 + $l3 > 30) or ($l2 + $l4 > 30))) {
          if ($time1 < $time2) {
            print $out "Coincidence: $task1 $author1 -> $author2 $general_percentage %\n";
          } else {
            print $out "Coincidence: $task1 $author2 -> $author1 $general_percentage %\n";
          }
        }
      }
    }
  }
  close($out) || die "Could't close file properly";
}

# reads configation file
# usage: read_tasks_to_skip()
sub read_tasks_to_skip() {
  my $file = $tasks_to_skip_filename;
  open(my $in, '<:encoding(UTF-8)', $file) or return;

  while (my $row = <$in>) {
    chomp $row;
    next if ($row =~ /\#/);
    foreach my $buf (split(' ', $row)) {
      push(@tasks_to_skip, $buf);
    }
  }
  close($in) || die "Could't close file properly";
}

sub main()
{
  if (not defined $filename) {
    pod2usage(1);
    die "Filename is not specified\n";
  }
  print "Working with the file $filename\n";
  read_tasks_to_skip();
  parse_csv($filename);
  compare_fingerprints();
  exit 0;
}

main();

__END__
=head1 NAME

CheckCSVForPlagiarism.pl - utility to calculate the percentage of plagiarism in solutions from nsuhw.ru

=head1 SYNOPSIS

CheckCSVForPlagiarism.pl filename

this script can work only with the CSV of this structure:

task_number, author, create_date, comment

As a result, you will get new csv with additional fingerprint columns and .report - file with plagiarism found
=cut
