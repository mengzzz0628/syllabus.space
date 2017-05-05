#!/usr/bin/env perl
package SylSpace::Controller::rss;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Controller qw(global_redirect standard);
use SylSpace::Model::Model qw(tweeted);

################################################################

get '/rss' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  ## enrollment not required
  $c->stash( tweets => tweeted($subdomain) );
};

1;

################################################################

__DATA__

@@ rss.html.ep

%title 'course activity';
%layout 'auth';

<main>

<h1>Tweeted Messages</h1>

  <%
    use SylSpace::Model::Controller qw(displaylog);
  %>  <%== displaylog($tweets) %>

</main>

