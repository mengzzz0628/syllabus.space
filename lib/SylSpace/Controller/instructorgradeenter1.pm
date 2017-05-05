#!/usr/bin/env perl
package SylSpace::Controller::instructorgradeenter1;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo gradeenter seclog);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################
## enter one and only one new grade for a student
################################################################

get '/instructor/gradeenter1' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  sudo( $subdomain, $c->session->{uemail} );

  my $uemail= $c->req->query_params->param('uemail');
  my $task= $c->req->query_params->param('task');
  my $grade= $c->req->query_params->param('grade');

  gradeenter($subdomain, $uemail, $task, $grade);

  seclog( $subdomain, 'instructor', "changed grade for $uemail $task $grade" );

  $c->flash( message=> "added grade for '$uemail', task '$task': $grade" )->redirect_to("gradecenter");

};

1;
