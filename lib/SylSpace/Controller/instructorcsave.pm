#!/usr/bin/env perl
package SylSpace::Controller::instructorcsave;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(ciowrite sudo tweet);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

post '/instructor/csave' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  sudo( $subdomain, $c->session->{uemail} );

  ciowrite( $subdomain, $c->req->body_params->to_hash ) or die "evil submission\n";

  tweet( $subdomain, $c->session->{uemail}, " updated course settings\n" );
  $c->flash(message => "Updated Course Settings")->redirect_to("/instructor");
};

1;
