#!/usr/bin/env perl
package SylSpace::Controller::instructorstudentadd;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo userenroll usernew);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/instructor/studentadd' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  sudo( $subdomain, $c->session->{uemail} );

  my $newstudent= $c->req->query_params->param('newuemail');
  (defined($newstudent)) or die "silly you.  I need a student!\n";

  usernew( $newstudent );
  userenroll( $subdomain, $newstudent, 1 );

  $c->flash(message => "Added new student '$newstudent'" )->redirect_to( $c->req->headers->referrer );
};

1;

################################################################

__DATA__

@@ instructorstudentadd.html.ep

%title 'add a student';
%layout 'instructor';

<main>

<h1>Not Yet</h1>

</main>

