#!/usr/bin/env perl
package SylSpace::Controller::InstructorGradesave1;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo gradesave seclog);
use SylSpace::Model::Controller qw(standard global_redirect);

################################################################
## enter one and only one new grade for a student
################################################################

get '/instructor/gradesave1' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  sudo( $subdomain, $c->session->{uemail} );

  my $uemail= $c->req->query_params->param('uemail');
  my $task= $c->req->query_params->param('task');
  my $grade= $c->req->query_params->param('grade');

  gradesave($subdomain, $uemail, $task, $grade);

  seclog($c->tx->remote_address, $subdomain, 'instructor', "changed grade for $uemail $task $grade" );

  $c->flash( message=> "added grade for '$uemail', task '$task': $grade" )->redirect_to("gradecenter");

};

1;
