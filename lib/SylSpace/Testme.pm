#!/usr/bin/env perl
package SylSpace::Controller::Testme;
use base 'Exporter';

our @EXPORT =qw( testme );

use strict;
use common::sense;
use utf8;
use warnings;
use warnings FATAL => qw{ uninitialized };
use autodie;

use feature ':5.20';
use feature 'signatures';

################################################################

sub testme( ) {
  return "testme works!\n";
}

1;
