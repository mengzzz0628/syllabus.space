#!/usr/bin/env perl
package SylSpace::Controller::instructorgradetaskadd;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo gradetaskadd);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get '/instructor/gradetaskadd' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  sudo( $subdomain, $c->session->{uemail} );

  my $taskn= $c->req->query_params->param('taskn');

  gradetaskadd($subdomain, $taskn);

  $c->flash( message=> "added new task category '$taskn'" )->redirect_to("gradecenter");

};

1;
