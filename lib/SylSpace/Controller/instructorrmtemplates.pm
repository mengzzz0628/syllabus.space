#!/usr/bin/env perl
package SylSpace::Controller::InstructorRmtemplates;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo rmtemplates);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get '/instructor/rmtemplates' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  sudo( $subdomain, $c->session->{uemail} );

  my $numremoved= rmtemplates($subdomain);

  return $c->flash( message=> "deleted $numremoved unchanged template files" )->redirect_to( 'equizcenter' );
};
