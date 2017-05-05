#!/usr/bin/env perl
package SylSpace::Controller::equizgrade;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo userisenrolled equizgrade equizanswerrender);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

post '/equizgrade' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  (userisenrolled($subdomain, $c->session->{uemail})) or $c->flash( message => "first enroll in $subdomain please" )->redirect_to('/auth/goclass');

  my $result= equizgrade($subdomain, $c->session->{uemail}, $c->req->body_params->to_hash);

  $c->stash( a => equizanswerrender($result) );
};

1;

################################################################

__DATA__

@@ equizgrade.html.ep

%title 'show equiz results';
%layout 'both';

<main>

<h1>Equiz Results</h1>

<%== $a %>

</main>

