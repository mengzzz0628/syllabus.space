#!/usr/bin/env perl
use strict;
use common::sense;
use utf8;
use warnings;
use warnings FATAL => qw{ uninitialized };
use autodie;

use lib 'Model';

use Model qw(_websitemake _websiteremove);

my $usage= "usage: $0 sitename instructoremail\n";

(@ARGV) or die $usage;
($#ARGV==1) or die $usage;
my ($subdomain, $uemail) = @ARGV;

SylSpace::Model::Model::_websitemake( $subdomain, $uemail );  ## will check proper characters, etc.

print "successfully created website $subdomain with instructor $uemail\n";

