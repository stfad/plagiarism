#!/usr/bin/perl

use strict;
use warnings;
no warnings 'utf8';
use Data::Dumper;
use Digest::MD5 qw(md5_hex);
use LCS;

sub main()
{
  my $arg1 = $ARGV[0];
  my $arg2 = $ARGV[1];
  my @hash1 = split(//, $arg1);
  my @hash2 = split(//, $arg2);
  my $llcs = LCS->LLCS(\@hash1, \@hash2);
  print "args: $arg1, $arg2\n";
  print "llcs: $llcs\n";
  my $l1 = length($arg1);
  print "l(arg1)=$l1, llcs=$llcs\n";
  my $percentage = ($llcs/length($arg1))*100;
  print "plagiarism: $percentage %\n";
  exit 0;
}

main();
