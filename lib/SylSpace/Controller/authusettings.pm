#!/usr/bin/env perl
package SylSpace::Controller::authusettings;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(readschema bioread);
use SylSpace::Model::Controller qw(global_redirect standard drawform);

################################################################

get '/auth/usettings' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  $c->stash( udrawform=> drawform( readschema('u'), bioread($c->session->{uemail}) ) );
};


1;

################################################################

__DATA__

@@ authusettings.html.ep

  %title 'user settings';
%layout 'auth';

<main>

  <form class="form-horizontal" method="POST" action="/auth/settingssave">

  <div class="form-group">
	  <label class="col-sm-2 control-label col-sm-2" for="email">email*</label>
	  <div class="col-sm-6">[public unchangeable]
		<input class="form-control foo" id="email" name="email" value="<%= $self->session->{uemail} %>" readonly />
	  </div>
        </div>

  <%== $udrawform %>

  <div class="form-group" style="padding-top:2em">
    <label class="col-sm-2 control-label col-sm-2" for="directlogincode">[c] directlogincode</label>
    <div class="col-sm-6">[Super-Confidential, Not Changeable, Ever]<br />  <a href="auth/showdirectlogincode">click here to play with knives</a><br /> </div>
  </div>

  <div class="form-group">
     <button class="btn btn-lg" type="submit" value="submit">Submit These Settings</button>
  </div>

  </form>

  <p> <b>*</b> means required (red if not yet provided).</p>



</main>

