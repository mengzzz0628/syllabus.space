#!/usr/bin/env perl
package SylSpace::Controller::instructormsgsave;
use Mojolicious::Lite;  ## implied strict, warnings, utf8, 5.10
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo msgpost tweet);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

post '/instructor/msgsave' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  sudo( $subdomain, $c->session->{uemail} );

  my $msgid= msgpost($subdomain, $c->req->body_params->to_hash);
  my $subject= $c->req->body_params->param('subject');
  my $priority= $c->req->body_params->param('priority');
  my $msg= "posted new message $msgid: '$subject', priority $priority";

  tweet($subdomain, 'instructor', $msg );
  $c->flash( message => $msg )->redirect_to('/instructor');  ## usually one posts only one message
};

1;
