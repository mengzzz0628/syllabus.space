#!/usr/bin/env perl
package SylSpace::Controller::StudentStudent2instructor;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(unmorphstudent2instructor isenrolled ismorphed);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/student/student2instructor' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  (isenrolled($course, $c->session->{uemail})) or $c->flash( message => "first enroll in $course please" )->redirect_to('/auth/goclass');

  ismorphed($course, $c->session->{uemail}) or die "you are not a morphed instructor for $course?!";

  unmorphstudent2instructor($course, $c->session->{uemail});

  return $c->flash( message => "student unmorphed back to instructor" )->redirect_to('/instructor');
};

