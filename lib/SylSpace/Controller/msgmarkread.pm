#!/usr/bin/env perl
package SylSpace::Controller::msgmarkread;
use Mojolicious::Lite;  ## implied strict, warnings, utf8, 5.10
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo msgmarkread);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get '/msgmarkread' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  my $msgid= $c->req->query_params->param('msgid');
  my $uemail= $c->session->{uemail};

  msgmarkread($subdomain, $uemail, $msgid);
  my $subject= $c->req->body_params->param('subject');
  my $priority= $c->req->body_params->param('priority');
  my $msg= "marked message $msgid as read: '$subject', priority $priority";

  $c->flash(message => $msg)->redirect_to($c->req->headers->referrer);
};

1;
