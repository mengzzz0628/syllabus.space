#!/usr/bin/env perl
package SylSpace::Controller::authsettingssave;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(biowrite);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

post '/auth/settingssave' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  biowrite( $c->session->{uemail}, $c->req->body_params->to_hash ) or die "evil submission\n";

  $c->flash(message => "Updated Biographical Settings")->redirect_to("/auth/goclass");
};

1;
