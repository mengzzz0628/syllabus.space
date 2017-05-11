#!/usr/bin/env perl
package SylSpace::Controller::authenroll;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(coursesecret);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/auth/enroll' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  my $coursename= $c->req->query_params->param('c');
  my $secret= coursesecret($coursename);

  (defined($secret)) or $secret="";

  $c->stash( asecret => $secret, coursename => $coursename );
};

1;

################################################################

__DATA__

@@ authenroll.html.ep

%title 'enroll in a course';
%layout 'auth';

<main>

<h1> Enrolling in Course '<%= $coursename %>' </h1>

  <p>
  <%
  sub enrollform {
    my ($secret,$coursename)= @_;

    my $q= '<input class="form-control foo" id="secret" name="secret"'
      .(($secret ne "") ?
	'placeholder="usually instructor provided"' :
	'placeholder="not required - instructor requests none" readonly').' />';

    return qq(
	<form  class="form-horizontal" method="POST"  action="/auth/enrollpost">
	<input type="hidden" name="course" value="$coursename" />
	  <div class="form-group">
	    <label class="col-sm-2 control-label col-sm-2" for="secret">secret*</label>
	    <div class="col-sm-6">
		$q
	    </div>
          </div>

          <div class="form-group">
             <label class="col-sm-2 control-label col-sm-2" for="submit"></label>
	     <button class="btn btn-lg" type="submit" value="submit">Enroll Now</button>
	  </div>
	</form>
       );
  }
   %>

  <%== enrollform( $asecret, $coursename ) %>

</main>

