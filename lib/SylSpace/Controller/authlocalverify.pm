#!/usr/bin/env perl
package SylSpace::Controller::authlocalverify;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

post '/auth/localverify' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  my $uemail= $c->req->body_params->param('uemail');
  my $pw= $c->req->body_params->param('pw');

  $c->session->{uemailhint}= $uemail;

  my $exists= `./requestauthentication`;
  ($exists eq "ok") or die "cannot find requestauthentication".($exists||"--")."\n";

  my $ask= `requestauthentication $uemail $pw`;
  ($ask eq $uemail) or die "sorry, but you provided a non-working user password combination!\n";

  $c->session->{uemail} = $uemail;

  $c->flash( message => "you have successfully authenticated as $uemail" )->redirect_to('/auth');
};

1;
