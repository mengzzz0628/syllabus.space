#!/usr/bin/env perl
package SylSpace::Controller::instructorsetdue;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo filesetdue tweet tzi);
use SylSpace::Model::Controller qw(global_redirect  standard epochof);

################################################################

use Mojo::Date;

get '/instructor/setdue' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  sudo( $subdomain, $c->session->{uemail} );

  my $params= $c->req->query_params;

  my $whendue= epochof( $params->param('duedate'), $params->param('duetime'), tzi($c->session->{uemail}) );
  my $r= filesetdue( $subdomain, $params->param('f'), $whendue );

  tweet( $subdomain, $c->session->{uemail}, " published ". $params->param('f'). ", due $whendue (GMT ".gmtime($whendue).")" );

  my $msg= "set due date to ".($params->param('duedate'))." ".($params->param('duetime'))." -> ".$whendue;
  $c->flash(message => $msg)->redirect_to($c->req->headers->referrer);
};


1;

################################################################

__DATA__

@@ instructorsetdue.html.ep

%title 'instructor -- setdue date';
%layout 'instructor';

<main>

<h1>Not Yet</h1>

<%== $result %>

<pre> <%= dumper $params %>

</main>

