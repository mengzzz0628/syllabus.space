#!/usr/bin/env perl
use strict;
use warnings;
use common::sense;
use utf8;
use feature ':5.20';
use warnings FATAL => qw{ uninitialized };
use autodie;

my $hostname= `hostname`;
chomp($hostname);

sub dirgive { (-d $_[0]) ? $_[0] : undef; }

my $superhome= (-d "/Users/ivo") ? "/Users" : "/home";

if ($hostname eq 'syllabus-space') {
  ($superhome eq '/home') or die "$0: please do not run real version on osx!\n";
  ($> == 0) or die "$0: you can run production only when you are root.\n";
  ## should not run off syllabus.test!
  my $workdir="$superhome/ivo/bitsyllabus/syllabus.space/";
  (-e $workdir) or die "$0: no $workdir!\n";
  chdir($workdir) or die "failed to change directory: $!\n";
  print STDERR "$0: Running Full Production Server.
	kill -QUIT `cat hypnotoad.pid` gracefully (or -TERM), or
	/usr/local/bin/hypnotoad -s ./SylSpace)\n";
  system("/usr/local/bin/hypnotoad -f ./SylSpace");  ## do not '&', or it fails in systemd SylSpace.service !
} else {
  print STDERR "$0: Running Development Test Server\n";

  ## here we can run off syllabus.test, and both on osx or on linux
  my $workdir="$superhome/ivo/bitsyllabus/syllabus.test/";
  if (-e $workdir) {
    print STDERR "running off the **TEST** subdir\n";
  } else {
    $workdir="$superhome/ivo/bitsyllabus/syllabus.space/";
    (-e $workdir) or die "we have neither syllabus.test nor syllabus.space!\n";
  }

  ## best: use DNSMASQ, add address=/test/127.0.0.1 into /usr/local/etc/dnsmasq.conf; and launchctl stop homebrew.mxcl.dnsmasq
  (`grep syllabus.test /etc/hosts` =~ /\.syllabus\.test/) or die "please add *.syllabus.test to your /etc/hosts\n";

  my $mode= "development";
  if (@ARGV) { ($ARGV[0] =~ /^p/i) and $mode="production"; }
  system("/usr/local/bin/morbo -v -m $mode ./SylSpace -l http://syllabus.test:80");
}
