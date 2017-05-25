#!/usr/bin/env perl
package SylSpace::Controller::StudentGradecenter;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use lib '../..';

use SylSpace::Model::Model qw(gradesashash isenrolled);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/student/gradecenter' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  (isenrolled($course, $c->session->{uemail})) or $c->flash( message => "first enroll in $course please" )->redirect_to('/auth/goclass');

  my $all= gradesashash( $course, $c->session->{uemail} );  ## just my own grades!

  $c->stash( all => $all );
};

1;

################################################################

__DATA__

@@ studentgradecenter.html.ep

<% use SylSpace::Model::Controller qw(mkdatatable); %>

%title 'grade center';
%layout 'student';

<main>

  <%== mkdatatable('gradebrowser') %>

  <% if (defined($all)) { %>
  <table class="table" style="width: auto !important; margin:2em;" id="gradebrowser">
     <%== showmygrades($all) %>
  </table>
  <% } else { %>
      <p> No grade data posted just yet </p>
  <% } %>

</main>

  <%
  sub showmygrades {
    my $all= shift;
    my $rs= "";
    $rs.= "<caption> Student ".$all->{uemail}->[0]." </caption>
           <thead> <tr> <th>Task</th> <th>Grade</th> </tr> </thead>\n";

    $rs .= "<tbody>\n";
    foreach my $hw (@{$all->{hw}}) {
      foreach my $st (@{$all->{uemail}}) {
	$rs.= "<tr> <th> $hw </th> \n";
	$rs.= "<td style=\"text-align:center\">".($all->{grade}->{$st}->{$hw}||"-")."</td>";
      }
      $rs.= "</tr>\n";
    }
    $rs .= "</tbody>\n";

    #my $rr="<select name=\"task\" class=\"form-control\">";
    #foreach (@{$all->{hw}}) { $rr .= qq(<option value="$_">$_</option>); }
    ##$$rr .= "</select>\n";
    return $rs;
  }
  %>

