#!/usr/bin/env perl
package SylSpace::Controller::instructorgradecenter;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use lib '../..';

use SylSpace::Model::Model qw(sudo gradesashash);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get '/instructor/gradecenter' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  sudo( $subdomain, $c->session->{uemail} );

  my $all= gradesashash( $subdomain );

  $c->stash( all => $all );
};

1;

################################################################

__DATA__

@@ instructorgradecenter.html.ep

%title 'grade center';
%layout 'instructor';

<main>

  <%
    use SylSpace::Model::Controller qw(btn mkdatatable);
  %> <%== mkdatatable('gradebrowser') %>

<%
  my $rs= "";
  $rs.= "<thead> <tr> <th>Student</th>";
  foreach (@{$all->{hw}}) { $rs.= "<th> <a href=\"gradeentermany?taskn=$_\">$_</a> </th>"; }
  $rs.= "</tr> </thead>\n<tbody>\n";

  foreach my $st (@{$all->{uemail}}) {
    $rs.= "<tr> <th> $st </th> \n";
    foreach my $hw (@{$all->{hw}}) {
      $rs.= "<td style=\"text-align:center\">".($all->{grade}->{$st}->{$hw}||"-")."</td>";
    }
    $rs.= "</tr>\n";
  }
  $rs .= "</tbody>\n";

  my $studentselector="<select name=\"uemail\" class=\"form-control\">";
  $studentselector .= qq("<option value=""></option>");
  foreach (@{$all->{uemail}}) { $studentselector .= qq(<option value="$_">$_</option>); }
  $studentselector .= "</select>\n";

  my $hwselector="<select name=\"task\" class=\"form-control\">";
  $hwselector .= qq("<option value=""></option>");
  foreach (@{$all->{hw}}) { $hwselector .= qq(<option value="$_">$_</option>); }
  $hwselector .= "</select>\n";
%>


  <table class="table" id="gradebrowser">
     <%== $rs %>
  </table>

  <p style="font-size:x-small">Click on the column name to enter many student grades for this one task.  If it is a new task, you must first add it.  To enter just one grade for one student, use the following form.</p>

<hr />

<form method="GET" action="/instructor/gradeenter1">
  <div class="row">

    <div class="col-xs-4">
      <div class="input-group">
        <span class="input-group-addon"><i class="fa fa-user"></i></span>
        <!-- input type="text" class="form-control" placeholder="student email" name="uemail" -->
        <%== $studentselector %>
      </div>
    </div>

    <div class="col-xs-2">
      <div class="input-group">
        <span class="input-group-addon"><i class="fa fa-file"></i></span>
            <%== $hwselector %>
      </div>
    </div>

    <div class="col-xs-2">
      <div class="input-group">
        <span class="input-group-addon"><i class="fa fa-thermometer-half"></i></span>
        <input type="text" class="form-control" placeholder="grade" name="grade" />
      </div>
    </div>

    <div class="col-xs-1">
      <div class="input-group">
         <button class="btn btn-default" type="submit" value="submit">Submit 1 New Grade</button>
      </div>
    </div>

  </div>
  <span style="font-size:x-small">For entering many student grades, please click on the column header name instead.</span></form>

<hr />

<form action="/instructor/gradetaskadd">
  <div class="row">

    <div class="col-xs-2">
      <div class="input-group">
        <span class="input-group-addon"><i class="fa fa-file"></i></span>
         <input type="text" class="form-control" placeholder="task name" name="taskn" />
      </div>
    </div>

    <div class="col-xs-1">
       <div class="input-group">
          <button class="btn" type="submit" value="submit">Add 1 New Task Category</button>
       </div>
    </div>
  </div>
          <span style="font-size:x-small">Warning: Categories, once entered, cannot be undone.  Just ignore empty column then.</span>
</form>


<hr />

    <form action="studentlist"><button class="btn" value="add students"> add student </button></form>

  <hr />


   <div class="row top-buffer text-center">
     <%== btn('/instructor/gradedownload?f=csv&sf=l', 'Download Long CSV') %>
     <%== btn('/instructor/gradedownload?f=csv&sf=w', 'Download Wide CSV') %>
  </div>

  <p style="font-size:x-small">The long view also contains repeated entries, changes, time stamps, etc.</p>

</main>

