#!/usr/bin/env perl
package SylSpace::Controller::authindex;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Controller qw(domain);



################################################################

my $authroot= sub {
  my $c = shift;

  ($c->req->url->to_abs->host() =~ m{auth\.\w}) or $c->redirect_to('http://auth.'.domain($c).'/auth');  ## wipe off anything beyond on url

  $c->stash( email => $c->session->{uemail} );

  $c->render( template => 'authindex');
};

get '/auth/index' =>  $authroot;
get '/auth' =>  $authroot;
get '/auth/' =>  $authroot;
get '/auth/' =>  $authroot;

1;

################################################################

__DATA__

@@ authindex.html.ep

%title 'authenticate email identity';
%layout 'auth';

<main>

<p>

<%  use SylSpace::Model::Controller qw(domain btnblock btn); %>

  <%
  use SylSpace::Model::Model qw(_listallusers);
  my $s;
  my $l= _listallusers();
  foreach (@$l) {
    $s .="<li> <a href=\"/login?email=$_\">Make yourself $_</a> </li>\n";
  }
  %>

  <h2>Test Site</h2>

  <p>This is a simple testsite, shared by all, public to anyone, and ephemeral (regularly destroyed).  Do not enter anything confidential here.</p>

<ul>
<%== $s %>
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

<!--
<p>Here will go more sophisticated code, requesting login.  At the end, this code should go back to the referrer (if local) or to <a href="/goclass">/auth/goclass</a>.

<p> <%== btn('/auth/dani', "Go To Dani</h2>") %>

-->

<p> <%== btn("/auth/goclass", "choose class") %>


</main>

