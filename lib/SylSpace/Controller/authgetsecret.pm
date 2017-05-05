#!/usr/bin/env perl
package SylSpace::Controller::authgetsecret;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/auth/getsecret' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  ## sudo( $subdomain, $c->session->{uemail} );

  $c->stash( );
};

1;

################################################################

__DATA__

@@ authgetsecret.html.ep

%title '/auth/getsecret';
%layout 'auth';

<main>

<h1>Not Yet</h1>

</main>

