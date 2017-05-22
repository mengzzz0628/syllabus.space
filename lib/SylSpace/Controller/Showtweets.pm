#!/usr/bin/env perl
package SylSpace::Controller::Showtweets;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(showtweets isinstructor);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/showtweets' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  $c->stash(toprightexit => '<li><a href="/auth/goclass"> <i class="fa fa-sign-out"></i> Exit Course </a></li>');

  if (isinstructor($subdomain, $c->session->{uemail})) {
    $c->stash( color => 'beige', homeurl => '/student' );
  } else {
    $c->stash( color => 'white', homeurl => '/student' );
  }

  ## enrollment not required
  $c->stash( tweets => showtweets($subdomain) );
};

1;

################################################################

__DATA__

@@ showtweets.html.ep

<% use SylSpace::Model::Controller qw(displaylog); %>

%title 'course activity';
%layout 'sylspace';

<main>

  <%== displaylog($tweets) %>

</main>

