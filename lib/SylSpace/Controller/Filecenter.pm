#!/usr/bin/env perl
package SylSpace::Controller::Filecenter;
use Mojolicious::Lite;  ## implied strict, warnings, utf8, 5.10
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(isinstructor);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################
## a redirector
################################################################

get '/filecenter' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  (isinstructor($course, $c->session->{uemail})) and return $c->redirect_to('/instructor/filecenter');
  return $c->redirect_to('/student/filecenter');
};

1;
