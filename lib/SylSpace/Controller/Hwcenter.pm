#!/usr/bin/env perl
package SylSpace::Controller::Hwcenter;
use Mojolicious::Lite;  ## implied strict, warnings, utf8, 5.10
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(isinstructor);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################
## a redirector
################################################################

get '/hwcenter' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  (isinstructor($subdomain, $c->session->{uemail})) and return $c->redirect_to('/instructor/hwcenter');
  return $c->redirect_to('/student/hwcenter');
};

1;
