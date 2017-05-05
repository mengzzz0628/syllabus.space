#!/usr/bin/env perl
package SylSpace::Controller::instructorinstructorlist;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo instructorlist);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/instructor/instructorlist' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  sudo( $subdomain, $c->session->{uemail} );

  $c->stash( instructors => instructorlist( $subdomain ) );
};

1;

################################################################

__DATA__

@@ instructorinstructorlist.html.ep

%title 'Current Course Instructors';
%layout 'instructor';

<main>

  <div class="alert alert-danger"><i class="fa fa-exclamation-triangle" aria-hidden="true"></i>  Warning: This page allows you to give full control to anyone to administer the website.</div>

  <table class="table" style="width: auto !important; margin:2em; font-size:large;" id="insbrowser">
  <thead> <tr> <th> Instructors </th> </tr> </thead>
  <tbody>
  <%
  my $rs="";
  foreach (@{$instructors}) {
    $rs .= "<tr> <td> $_ </td> <td> <a href=\"instructordel?deliemail=$_\"><i class=\"fa fa-trash\" aria-hidden=\"true\"></i></a> </td> </tr>\n";
  }
%> <%== $rs %>

  </tbody>
  </table>

<form action="/instructor/instructoradd" method="POST">
  <div class="row">

    <div class="col-xs-4">
      <div class="input-group">
        <span class="input-group-addon"><i class="fa fa-user"></i></span>
         <input type="text" class="form-control" placeholder="enrolled user email" name="newiemail" />
      </div>
    </div>

    <div class="col-xs-1">
       <div class="input-group">
          <button class="btn btn-danger" type="submit" value="submit">Add New Instructor</button>
       </div>
    </div>
  </div>
</form>


</main>

