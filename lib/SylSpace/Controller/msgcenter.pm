#!/usr/bin/env perl
package SylSpace::Controller::msgcenter;
use Mojolicious::Lite;  ## implied strict, warnings, utf8, 5.10
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(utype);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################
## a redirector
################################################################

get '/msgcenter' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  my $whoami= utype($subdomain, $c->session->{uemail});

  (defined($whoami)) or die "what are you??";
  ($whoami eq 'i') and return $c->flash( message => 'as instructor')->redirect_to('/instructor/msgcenter');
  ($whoami eq 's') and return $c->redirect_to('/student/msgcenter');
  die "confused with '$whoami'!";
};
