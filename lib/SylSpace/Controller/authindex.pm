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

  $c->render( template => 'authindex' );
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

<p>Here goes dani's code, requesting login.  at the end, it goes back to the referrer (if local) or to <a href="/goclass">/auth/goclass</a>.

<p>In the meantime:

<ul>
<li> <a href="/login?email=ivo.welch@gmail.com">Make yourself ivo.welch@gmail.com (who happens to be the su for the mfe class).</a> </li>
<li> <a href="/login?email=arthur.welch@gmail.com">Make yourself arthur.welch@gmail.com (who happens to be a student in the mfe class).</a> </li>
<li> <a href="/login?email=x.lily.qiu@gmail.com">Make yourself x.lily.qiu.</a> </li>
<li> <a href="/login?email=noone@gmail.com">Try making yourself noone@gmail.com, who does not exist</a> </li>
<li> <a href="/logout">Log out</a> </li>
</ul>

<p>right now, you are <tt><%= $email||"no session email" %></tt>.</p>


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
</form>

<p> PS: The password could be RSA-encrypted before it is passed to the server. </p>

</main>

