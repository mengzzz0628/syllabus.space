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


%title 'authenticate email identity';
%layout 'auth';

<main>

  <h2>TESTING Auth Site</h2>

  <p>This is a simple testsite, shared by all, public to anyone, and ephemeral (regularly destroyed).  Do not enter anything confidential here.</p>

<ul>
  <%== makelist($allusers) %>
  <li> <a href="/logout">Log out</a> </li>
</ul>

<hr />

<p>right now, you are <tt><%= $email||"no session email" %></tt>.</p>

<!--
<form method="POST" action="/auth/localverify">
  <div class="row">

    <div class="col-xs-12 col-sm-4 col-md-4">
      <div class="input-group">
        <span class="input-group-addon"><i class="fa fa-user"></i></span>
         <input  <%== ($self->session->{uemailhint}) ? 'value="'.$self->session->{uemailhint}.'"' : "" %>
		type="text" class="form-control" placeholder="email@syllabus.space" name="uemail" />
      </div>
    </div>

    <div class="col-xs-12 col-sm-4 col-md-4">
      <div class="input-group">
        <span class="input-group-addon"><i class="fa fa-key"></i></span>
         <input type="password" class="form-control" placeholder="only you should know" name="pw" />
      </div>
    </div>

    <div class="col-xs-12 col-sm-4 col-md-2">
      <div class="input-group">
         <button class="btn btn-default" type="submit" value="submit">Request Local Authentication</button>
      </div>
    </div>

  </div>
  <p> PS: The password could be RSA-encrypted before it is passed to the server. </p>

</form>
-->

<hr />

<p> <%== btn("/auth/goclass", "choose class") %>

<p> <%== btn('/auth/authenticator', "Go To Dani's Authenticator</h2>") %>

<hr />

  <p>Email authentication and google authentication work great.

  <style> li { margin-top:1em; } </style>

  <ol style="background-color:yellow">
  <li> We need a logfile that tells us where the authorization came from, IP site, time; etc.  you can either just write to <tt>/var/sylspace/auth.log</tt>, or you can call <pre> use SylSpace::Model::Model qw(seclog)
 seclog( 'auth', $newemail, "IP,source-of-auth,any other useful info from authentication system" )</pre></li>
  <li> when I go through github auth, the <tt>session->{uemail}</tt> is not set.  if this is a bug, it needs to be fixed.  if there was an error, then it needs to be displayed.</li>
  <li> we always need descriptive error messages when the authentication fails </li>
  <li> I need step by step documentation and instructions as to set this up on a completely different site.  This must include getting credentials (from google and facebook), setting up the mail sender/receiver setup, and anything else we need.</li>
  <li> Q: is "name" necessary for email authenticator?  A: good practice instead of a challenge, anyway!!!  Let's keep it.
  </ol>


</main>


<% sub makelist {
  my $l= shift;
  my $rs;
  foreach (@$l) {
    $rs .="<li> <a href=\"/login?email=$_\">Make yourself $_</a> </li>\n";
  }
  return $rs;
} %>
