#!/usr/bin/env perl
package SylSpace::Controller::rss;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(tweeted isinstructor);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/rss' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  $c->stash(toprightexit => '<li><a href="/auth/goclass"> <i class="fa fa-sign-out"></i> Exit Course </a></li>');

  if (isinstructor($subdomain, $c->session->{uemail})) {
    $c->stash( color => 'beige', homeurl => '/student' );
  } else {
    $c->stash( color => 'white', homeurl => '/student' );
  }

  ## enrollment not required
  $c->stash( tweets => tweeted($subdomain) );
};

1;

################################################################

__DATA__

@@ rss.html.ep

%title 'course activity';
%layout 'sylspace';

<main>

  <%
    use SylSpace::Model::Controller qw(displaylog);
  %>  <%== displaylog($tweets) %>

</main>

