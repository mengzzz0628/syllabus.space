#!/usr/bin/env perl
package SylSpace::Controller::InstructorCollectstudentanswers;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo collectstudentanswers);
use SylSpace::Model::Controller qw(standard global_redirect);

################################################################

get '/instructor/collectstudentanswers' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my $filename= collectstudentanswer( $course, $c->req->query_params->param('f') );
  $filename =~ s{.*/}{};
  $c->stash( filename => $filename );
};

1;

################################################################

__DATA__

@@ instructorcollectstudentanswers.html.ep

%title 'collect student answers';
%layout 'instructor';

<main>

<meta http-equiv="refresh" content="1;url=silentdownload?f=<%=$filename%>">

  <p>Your zipped file of studentanswers has been created and saved into your <a href="/instructor/filecenter">file center</a>.  Please delete it when you no longer need it.  Space is scarce.</p>

  <p>This file should download by itself in a moment.  If not, please click <a href="silentdownload?f=<%=$filename%>">silentdownload?f=<%=$filename%></a>.</p>

</main>

