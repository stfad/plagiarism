#!/usr/bin/perl

use strict;
use warnings;
no warnings 'utf8';
use Data::Dumper;
use Digest::MD5 qw(md5_hex);
use LCS;
use Text::CSV;

my $filename = shift @ARGV;

sub create_fingerprint($) {
  my $comment = shift;
  my @sentences = ();
  my @formulas = ();
  my $sentence_buf, my $formula_buf;
  my $flag = 0;

  $comment =~ s/\$\$/\$/g; # $$ -> $
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
  print "Sentences:\n";
  print Dumper(@sentences);
  print "Formulas:\n";
  print Dumper(@formulas);
  filter_arrays(\@sentences,\@formulas);
  my $hash = convert_arrays_to_hash(\@sentences,\@formulas);
  return $hash;
}

sub parse_file($) {
  my $file = shift;
  my @sentences = ();
  my @formulas = ();
  my $multiline = 0;

  open(my $fh, '<:encoding(UTF-8)', $file) or die "Could not open file '$file' $!";
  my $formula_buf, my $sentence_buf;
  my $flag = 0; # are we reading a formula?

  while (my $row = <$fh>) {
    chomp $row;
    $row =~ s/\$\$/\$/g; # $$ -> $
    $row =~ s/\n//g; # remove \n

    if (($row =~/\$/) or $flag == 1) { # row contains formula
      foreach my $char (split //, $row) {
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
    }
  }
  close($fh) || die "Could't close file properly";
  return (\@sentences, \@formulas);
}

sub filter_arrays($;$) {
  my $s_ref = shift;
  my $f_ref = shift;
  for my $str (@$s_ref) {
    $str =~ s/ a //g; # remove articles
    $str =~ s/ the //g;
    $str =~ s/[.,!?:;#_]//g; # remove signs
    $str =~ s/\s+//g; # remove spaces
    $str = uc($str); # UPPER CASE
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

sub convert_arrays_to_hash($;$) {
  my $s_ref = shift;
  my $f_ref = shift;
  my $result;
  for my $buf (@$s_ref) {
    $result=$result.$buf;
  }
  for my $buf (@$f_ref) {
    $result=$result.$buf;
  }
#  print "res = $result \n";
#  $result=md5_hex($result);
  return $result;
}

sub parse_csv($) {
  my $file = shift;
  my $csv = Text::CSV->new({ sep_char => ',' });

  open(my $fh, '<:encoding(UTF-8)', $file) or die "Could not open file '$file' $!";
  while (my $fields = $csv->getline($fh)) {
    my $tasknum = $fields->[0];
    my $author = $fields->[1];
    my $date = $fields->[2];
    my $comment = $fields->[3];
    print "tasknum: $tasknum\n";
    print "author: $author\n";
    print "date: $date\n";
    print "comment: $comment\n";
    my $fingerprint = create_fingerprint($comment);
    print "fingerprint: $fingerprint\n";
  }
  close($fh) || die "Could't close file properly";
}


sub main()
{
  if (not defined $filename) {
    die "Filename is not specified\n";
  }
  print "Working with the file $filename\n";
  parse_csv($filename);
#  my ($s_ref, $f_ref) = parse_file($filename);
#  filter_arrays($s_ref, $f_ref);
#  my $hash = convert_arrays_to_hash($s_ref, $f_ref);
#  print "$hash\n";
  exit 0;
}

main();
