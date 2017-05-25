#!/usr/bin/env perl
package SylSpace::Controller::InstructorHwmore;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo ifilelist1 filelistsfiles tzi);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get '/instructor/hwmore' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my $fname=  $c->req->query_params->param('f');
  (defined($fname)) or die "need a filename for hwmore.\n";

  $c->stash( detail => ifilelist1($course, $c->session->{uemail}, $fname),
	     studentuploaded => filelistsfiles($course, $fname),
	     fname => $fname,
	     tzi => tzi( $c->session->{uemail} ) );
};

1;

################################################################

__DATA__

@@ instructorhwmore.html.ep

<% use SylSpace::Model::Controller qw(drawmore btn browser); %>

%title 'more homework information';
%layout 'instructor';

<main>

  <%== drawmore('hw', [ 'view', 'download', 'edit' ], $detail, $tzi, browser($self) ); %>

  <hr />

  <%== upl($studentuploaded) %>


<%== btn('/instructor/collectanswers?f='.$fname, "collect all student answers", 'btn-lg') %>

</main>

<%
  sub upl {
    my $rs=""; my $c=0;
    my @fl= @{$_[0]};
    foreach (@fl) {
      m{.*/([0-9a-z\_\.\-]+@[0-9a-z\_\.\-]+)/files/(.*)};
      (/\.old$/) and next;
      $rs .= "<li> $1 </li>"; ++$c;
    }
    return "<h2> $c Student Responses </h2>\n\n<ol> $rs </ol>\n";
  }
%>
