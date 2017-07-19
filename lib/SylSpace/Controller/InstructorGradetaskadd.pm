#!/usr/bin/env perl
package SylSpace::Controller::InstructorGradetaskadd;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo);
use SylSpace::Model::Grades qw(gradetaskadd);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get '/instructor/gradetaskadd' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my $taskn= $c->req->query_params->param('taskn');

  gradetaskadd($course, $taskn);

  $c->flash( message=> "added new task category '$taskn'" )->redirect_to("gradecenter");

};

1;
