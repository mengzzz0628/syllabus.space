#!/usr/bin/env perl
package SylSpace::Controller::instructormorph;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo usermorph);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/instructor/morph' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  sudo( $subdomain, $c->session->{uemail} );

  usermorph($subdomain, $c->session->{uemail});

  return $c->flash( message => "instructor morphed into student" )->redirect_to('/student');
};

1;

