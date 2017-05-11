#!/usr/bin/env perl
package SylSpace::Controller::authdani;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/auth/dani' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  ## sudo( $subdomain, $c->session->{uemail} );

  $c->stash( );
};

1;

################################################################

__DATA__

@@ authdani.html.ep

%title '/auth/dani';
%layout 'auth';

<% use SylSpace::Model::Controller qw(domain); %>

<main>

<h1>Do Magic</h1>

  <p>My own web code will redirect to this url.  You can change the text and code here.  Ultimately, all your code needs to do is
  <ol>
  <li> set $self->session->{uemail} to whatever is authenticated.</li>
  <li> write more complete authentication information to a logfile, <tt>/var/sylspace/auth.log</tt>.</li>
  <li> redirect_to http://auth.<%= domain($self) %>://index .</li>
  </ol>

  <hr />

  <p>To keep with the look of this website, please create new pages via the shell script <pre> $ perl mkurl.pl /auth/dani</pre>

  <hr />

  <p>Finally, I need step by step instructions as to set up.  This must include getting credentials (from google and facebook), setting up the mail sender/receiver setup, and this one.</p>

</main>

