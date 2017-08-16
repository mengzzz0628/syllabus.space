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
use FindBin;

################################################################

use lib '../..';
use SylSpace::Model::Model qw(:DEFAULT instructornewenroll);

instructornewenroll(@ARGV);

