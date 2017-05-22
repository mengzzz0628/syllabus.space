#!/usr/bin/env perl

package SylSpace::Controller::Logout;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Controller qw(domain);

my $logout = sub {
  my $c = shift;
  my $logoutemail= $c->session->{uemail} || "no email yet";
  $c->session->{uemail}=undef;
  $c->session->{uexpiration}= undef;

  $c->flash(message => "$logoutemail logged out")->redirect_to('http://auth.'.domain($c).'/auth/index');
};

get '/logout' => $logout;

1;
