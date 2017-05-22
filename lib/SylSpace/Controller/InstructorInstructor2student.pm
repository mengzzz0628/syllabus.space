#!/usr/bin/env perl
package SylSpace::Controller::InstructorInstructor2student;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo instructor2student ismorphed);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/instructor/instructor2student' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  ismorphed($subdomain, $c->session->{uemail}) and return $c->flash( message => "you were already a morphed instructor" )->redirect_to('/student');

  sudo( $subdomain, $c->session->{uemail} );

  instructor2student($subdomain, $c->session->{uemail});

  return $c->flash( message => "instructor morphed into student" )->redirect_to('/student');
};

1;

