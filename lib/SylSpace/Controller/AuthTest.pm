#!/usr/bin/env perl
package SylSpace::Controller::AuthTest;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Controller qw(domain);

use SylSpace::Model::Model qw(_listallusers);  ## for testsites



################################################################

get '/auth/test' => sub {
  my $c = shift;

  ($c->req->url->to_abs->host() =~ m{auth\.\w}) or $c->redirect_to('http://auth.'.domain($c).'/auth');  ## wipe off anything beyond on url

  $c->render( template => 'authtest', email => $c->session->{uemail}, allusers => _listallusers() );
};

1;

################################################################

__DATA__

@@ authtest.html.ep

<% use SylSpace::Model::Controller qw(domain btnblock btn); %>


%title 'short-circuit identity';
%layout 'auth';

<main>

  <p>This is only useful under localhost, where it is shared by all, public to anyone, and ephemeral (regularly destroyed).  Do not enter anything confidential here.</p>

<ul>
  <%== makelist($allusers) %>
  <li> <a href="/logout">Log out</a> </li>
</ul>

<hr />

<p>right now, you are <tt><%= $email||"no session email" %></tt>.</p>

<hr />

<p> <%== btn("/auth/goclass", "Choose Class") %>

<p> <%== btn('/auth/authenticator', "Real Authenticator</h2>") %>

<hr />

</main>


<% sub makelist {
  my $l= shift;
  my $rs;
  my @ulist= ($ENV{'ONLOCALHOST'}) ? @$l : qw( ivo.welch@gmail.com instructor@gmail.com student@gmail.com );
  foreach (@ulist) { $rs .="<li> <a href=\"/login?email=$_\">Make yourself $_</a> </li>\n"; }
  return $rs;
} %>
