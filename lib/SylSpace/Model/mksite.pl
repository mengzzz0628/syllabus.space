#!/usr/bin/env perl
use strict;
use common::sense;
use utf8;
use warnings FATAL => qw{ uninitialized };
use autodie;

use feature ':5.20';
use feature 'signatures';
no warnings qw(experimental::signatures);

################################################################
## not used, but we want to make sure that these modules are installed.
use common::sense;
use File::Copy;
use Perl6::Slurp;
use Archive::Zip;
use FindBin;
use Mojolicious::Plugin::RenderFile;
use Data::Dumper;

################################################################

use lib '../..';

use SylSpace::Model::Webcourse qw(_webcoursemake _webcourseremove _webcourseshow );
use SylSpace::Model::Model qw(:DEFAULT instructornewenroll);

my $usage= "usage: $0 sitename instructoremail\n";

(@ARGV) or die $usage;
($#ARGV==1) or die $usage;
my ($subdomain, $iemail) = @ARGV;

_webcoursemake( $subdomain );
instructornewenroll($subdomain, $iemail);

print "successfully created website $subdomain with instructor $iemail\n";

