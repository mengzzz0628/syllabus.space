#!/usr/bin/env perl
use strict;
use warnings;
use common::sense;
use utf8;
use feature ':5.20';
use warnings FATAL => qw{ uninitialized };
use autodie;

(-d "new") or die "please make new\n";

foreach (glob("*.pm")) {
  my $nfnm= process($_);
}

sub process {
  print "$_[0]\t";
  (my $sfnm= $_[0]) =~ s/\.pm$//;
  $sfnm= lc($sfnm);

  open(my $FIN, "<", $_[0]);
  open(my $FOUT, ">", "new/".camelcase($_[0]));
  my $pname;
  while (<$FIN>) {
    if (/package SylSpace::Controller::([\w]+);/) {
      print "\t$1\t";
      (lc($sfnm) eq lc($1)) or die "filename '$sfnm' and packagename '$1' do not match\n\n";
      print $FOUT 'package SylSpace::Controller::'.camelcase($1).";\n";
      $pname=$1;
      next;
    }
    if (/^(get|post) \'([^\']+)\'/) {
      my $url= $2;
      print "\t$url\t";
      $url =~ s{/}{}g;
      if (!(lc($pname) eq $url)) {
	(/\=\>\s*\$/) and next; ## ignore sub reference
	warn "$_: sorry, package name '$pname' is not 'url' for $url\n\n";
	next;
      }
    }
    print $FOUT $_;
  }
    print "\n";
  close($FIN);
  close($FOUT);
}

sub camelcase {
  $_= lc($_[0]);
  (s/^auth(\w)(\w+)/"Auth".uc($1).$2/e) and return $_;
  (s/^instructor(\w)(\w+)/"Instructor".uc($1).$2/e) and return $_;
  (s/^student(\w)(\w+)/"Student".uc($1).$2/e) and return $_;
  s/^(\w)(\w+)/uc($1).$2/e; return $_;
}

