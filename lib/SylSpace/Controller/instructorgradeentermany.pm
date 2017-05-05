#!/usr/bin/env perl
package SylSpace::Controller::instructorgradeentermany;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo studentlist gradesashash);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get '/instructor/gradeentermany' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  sudo( $subdomain, $c->session->{uemail} );

  my $sgl;

  my $taskname= $c->req->query_params->param('taskn');
  my $studentlist= studentlist($subdomain);
  foreach (@$studentlist) { $sgl->{$_}=""; }
  my $gah= gradesashash( $subdomain );
  foreach (@{$gah->{uemail}}) {
    $sgl->{$_}= ($gah->{grade}->{$_}->{$taskname}) || "";
  }

  $c->stash( formname => $taskname, sgl => $sgl );
};

1;

################################################################

__DATA__

@@ instructorgradeentermany.html.ep

%title 'enter grades';
%layout 'instructor';

<% use SylSpace::Model::Controller qw(mkdatatable) %> <%== mkdatatable('gradebrowser') %>

<main>

<h1>Grades For Task <%= $formname %></h1>

<form action="gradeentermanysubmit">
  <input type="hidden" name="task" value="<%= $formname %>" />

  <table class="table" id="gradebrowser">
     <thead> <th class="col-md-1"> # </th> <th class="col-md-3"> Student </th> <th class="col-md-1"> Grade </th> </tr> </thead>
     <tbody>
	<% sub tcontent {
	    my $sgl= shift;
	    my $rv="";
	    my $i=0;
	    foreach (keys %{$sgl}) {
	      ++$i;
	      $rv .= qq(\t<tr> <td>$i</td> <td> $_ </td> <td> <input type="text" name="$_" value="$sgl->{$_}" /> </tr>\n);
	    }
	    return $rv;
	  }
	%>
        <%== tcontent($sgl) %>
     </tbody>
  </table>

  <div class="col-xs-1">
      <button class="btn" type="submit" value="submit">Update All Grades</button>
   </div>

</form>

</main>

