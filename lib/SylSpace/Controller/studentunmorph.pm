#!/usr/bin/env perl
package SylSpace::Controller::studentunmorph;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(userunmorph userisenrolled ismorphed);
use SylSpace::Model::Controller qw(global_redirect standard domain);

################################################################

get '/student/unmorph' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  (userisenrolled($subdomain, $c->session->{uemail})) or $c->flash( message => "first enroll in $subdomain please" )->redirect_to('/auth/goclass');

  ismorphed($subdomain, $c->session->{uemail}) or die "you are not morphed for $subdomain?!";

  userunmorph($subdomain, $c->session->{uemail});

  return $c->flash( message => "instructor unmorphed" )->redirect_to('/instructor');
};

