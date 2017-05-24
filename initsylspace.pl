#!/usr/bin/env perl
use strict;
use common::sense;
use utf8;
use feature ':5.20';
no warnings qw(experimental::signatures);
use feature 'signatures';
no warnings qw(experimental::signatures);

use warnings;
use warnings FATAL => qw{ uninitialized };
use autodie;

use Archive::Zip;
use Crypt::CBC;
use Crypt::DES;
use Crypt::Blowfish;
use Data::Dumper;
use Digest::MD5;
use Email::Valid;
use Encode;
use File::Copy;
use File::Glob;
use File::Path;
use File::Touch;
use FindBin;
use HTML::Entities;
use MIME::Base64;
use Math::Round;
use Perl6::Slurp;
use Safe;
use Scalar::Util;
use Test2::Bundle::Extended;
use Test2::Plugin::DieOnFail;
use YAML::Tiny;

use Mojolicious::Lite;
use Mojolicious::Plugin::RenderFile;
use Mojolicious::Plugin::Mojolyst;
use Mojolicious::Plugin::BrowserDetect;

## these are used in the authentication module
use Mojo::JWT;
use Mojolicious::Plugin::Web::Auth;
use Email::Sender::Simple;
use Email::Simple::Creator;
use Email::Sender::Transport::SMTP::TLS;

use Mojolicious::Plugin::Web::Auth;

=pod

=head1 Title

  initsylspace.pl --- set up sylspace on a new computer

=head1 Description

  the above 'use' statements exist to make sure we have everything installed.

=head1 Versions

  0.0: Wed May  3 08:53:04 2017

=cut

(-e "templates/equiz/starters") or die "internal error: you don't seem to have any starter templates";
(-e "Model/Model.pm") or die "internal error: you don't seem to have the Model";
(-e "Model/eqbackend/eqbackend.pl") or die "internal error: you don't seem to have the eqbackend";
(-e "Controller/InstructorIndex.pm") or die "internal error: you don't seem to have the frontend (Controller/instructorindex.pm";

my $var="/var/sylspace";

if (-w $var) {
  die "[good -- $var exists and is writeable, aborting for safety]\n";
} else {
  (-e "/var") or die "internal error: your computer has no /var directory";
  (-r "/var") or die "internal error: I cannot read the /var directory";

  (-w "/var") or die "internal error: I cannot write to the /var directory.  please run this script as sudo";
  mkdir("$var") or die "internal error: I could not mkdir $var: $!";
  chmod(0777, $var) or die "chmod: failed on opening $var to the public: $!\n";
  print STDERR "created $var\n";
}

my $varu="$var/users";
if (!(-e $varu)) {
  mkdir($varu) or die "cannot make $varu\n";
  chmod(0777, $varu) or die "chmod: failed on opening $varu to the public: $!\n";
  say STDERR "made $var";
}

if (!(-e "$var/sites")) {
  mkdir("$var/sites") or die "cannot make $var/sites\n";
  chmod(0777, "$var/sites") or die "chmod: failed on opening $varu/sites to the public: $!\n";
  say STDERR "made $var/sites";
}

if (!(-e "$var/tmp")) {
  mkdir("$var/tmp") or die "cannot make $var/tmp\n";
  chmod(0777, "$var/tmp") or die "chmod: failed on opening $varu/tmp to the public: $!\n";
  say STDERR "made $var/tmp";
}

if (!(-e "$var/templates")) {
  mkdir("$var/templates") or die "cannot make $var/templates\n";
  system("cp -a templates/equiz/* $var/templates/");
  say STDERR "copied templates";
}

if (!(-e "$var/secrets.txt")) {
  open(my $FO, ">", "$var/secrets.txt"); for (my $i=0; $i<30; ++$i) { print $FO mkrandomstring(32)."\n"; } close($FO);
}


say STDERR "now create a samplewebsite, e.g., (1) mksite.pl mfe.ucla instructor\@gmail.com or (2) run Model/Model.t or (3) run Model/MkTestSite.t";


sub mkrandomword {
  my $len= $_[0] || 32;
  my @conson = (split( '', "bcdfghjklmnprstvwxz"."rsn"), "sh", "th");
  my @vowel = split( '', "aeeiou" );
  my $rstring="";
  for (my $i=0; $i<$len; ++$i) {
    $rstring.=  (( $i % 2 ) == 0 ) ? ($conson[rand @conson]) : ($vowel[rand @vowel]);
  }
  return $rstring;
}

sub mkrandomstring {
  my @chars = ("A".."Z", "a".."z", "0".."9");
  my $string;
  $string .= $chars[rand @chars] for 1..($_[0]||32);
  return $string;
}
