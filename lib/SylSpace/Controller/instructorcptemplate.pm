#!/usr/bin/env perl
package SylSpace::Controller::instructorcptemplate;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(cptemplate sudo);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/instructor/cptemplate' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  sudo( $subdomain, $c->session->{uemail} );

  my $templatename= $c->req->query_params->param('templatename');

  my $nc= cptemplate( $subdomain, $templatename );

  return $c->flash( message => "copied $nc equiz files from template $templatename")->redirect_to( 'equizcenter' );
};
