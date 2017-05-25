#!/usr/bin/env perl
package SylSpace::Controller::Equizgrade;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(isenrolled equizgrade equizanswerrender);
use SylSpace::Model::Controller qw(standard global_redirect);

################################################################

post '/equizgrade' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  (isenrolled($course, $c->session->{uemail})) or $c->flash( message => "first enroll in $course please" )->redirect_to('/auth/goclass');

  my $result= equizgrade($course, $c->session->{uemail}, $c->req->body_params->to_hash);

  $c->stash( eqanswer => equizanswerrender($result) );
};

1;

################################################################

__DATA__

@@ equizgrade.html.ep

%title 'show equiz results';
%layout 'both';

<main>

<h1>Equiz Results</h1>

<%== $eqanswer %>

</main>

