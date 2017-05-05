#!/usr/bin/env perl
package SylSpace::Controller::instructorequizmore;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(ifilelist1 sudo filelistsfiles gradesfortask2table tzi);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get '/instructor/equizmore' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  sudo( $subdomain, $c->session->{uemail} );

  my $fname=  $c->req->query_params->param('f');
  (defined($fname)) or die "need a filename for equizmore.\n";

  $c->stash( detail => ifilelist1($subdomain, $c->session->{uemail}, $fname),
	     studentuploaded => filelistsfiles($subdomain, $fname),
	     fname => $fname,
	     grds4tsk =>  gradesfortask2table($subdomain, $fname),
	     tzi => tzi( $c->session->{uemail} ) );
};

1;

################################################################

__DATA__

@@ instructorequizmore.html.ep

%title 'more equiz information';
%layout 'instructor';

<%
  use SylSpace::Model::Controller qw(drawmore epochtwo mkdatatable);
%>  <%== mkdatatable('eqabrowser') %>

<main>

  <%== drawmore('equiz', [ 'equizrun', 'view', 'download', 'edit' ], $detail, $tzi); %>

  <hr />

<%
  sub upl {
    my $rs=""; my $c=0;
    my @fl= @{$_[0]};
    foreach (@fl) {
      m{.*/([0-9a-z\_\.\-]+@[0-9a-z\_\.\-]+)/files/(eq.*)};
      (/\.old$/) and next;
      $rs .= "<li> $1 </li>"; ++$c;
    }
    return "<h2> Student Responses </h2>\n\n<ol> $rs </ol>\n";
  }
%> <%== upl($studentuploaded) %>

  <style> span.epoch { display:none; } </style>

<table class="table" id="eqabrowser">
<thead> <tr> <th> # </th> <th> Student </th> <th> Score </th> <th> Date </th> </tr> </thead>
<tbody>
    <%
    sub mktbl {
      my $rs=""; my $i=0;
      foreach (@{$_[0]}) {
	$rs .= "<tr> <td>".++$i."</td> <td>$_->[0]</td> <td>$_->[1]</td> <td>".epochtwo($_->[2])."</td> </tr>\n";
      }
      return $rs;
    }
    %> <%== mktbl($grds4tsk) %>
</tbody>
</table>

</main>

