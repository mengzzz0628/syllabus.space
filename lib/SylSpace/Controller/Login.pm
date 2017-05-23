#!/usr/bin/env perl
package SylSpace::Controller::Login;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Controller qw(domain);

get '/login' => sub {
  my $c = shift;

  (time()>=1502385651) and die "sorry, by now you should be in real use.  this is a controlled function, after all";
  # (domain($c) =~ /localhost/) or die "this is a controlled function";

  $c->session->{uemail}= $c->req->query_params->param('email');
  $c->session->{expiration}= time()+3600*24*365;

  my $redir='http://auth.'.domain($c).'/auth/goclass';

  $c->flash(message => "we have made you ".$c->session->{uemail}." and redirected to '$redir")->redirect_to($redir);
};
