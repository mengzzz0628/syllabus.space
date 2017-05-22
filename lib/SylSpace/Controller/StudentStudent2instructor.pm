#!/usr/bin/env perl
package SylSpace::Controller::StudentStudent2instructor;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(student2instructor isenrolled ismorphed);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/student/student2instructor' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  (isenrolled($subdomain, $c->session->{uemail})) or $c->flash( message => "first enroll in $subdomain please" )->redirect_to('/auth/goclass');

  ismorphed($subdomain, $c->session->{uemail}) or die "you are not a morphed instructor for $subdomain?!";

  student2instructor($subdomain, $c->session->{uemail});

  return $c->flash( message => "student unmorphed back to instructor" )->redirect_to('/instructor');
};

