#!/usr/bin/env perl
package SylSpace::Controller::InstructorCptemplate;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(cptemplate sudo);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/instructor/cptemplate' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my $templatename= $c->req->query_params->param('templatename');

  ## && ($course !~ /fin/)
  ## (($templatename eq /corpfinintro/)) and die "only fin classes are allowed to use the corpfinintro template";

  my $nc= cptemplate( $course, $templatename );

  return $c->flash( message => "copied $nc equiz files from template $templatename")->redirect_to( 'equizcenter' );
};
