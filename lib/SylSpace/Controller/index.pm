#!/usr/bin/env perl
package SylSpace::Controller::Index;
use Mojolicious::Lite;  ## implied strict, warnings, utf8, 5.10
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(isenrolled isinstructor _suundo);
use SylSpace::Model::Controller qw(global_redirect standard domain);

################################################################
## a redirector
################################################################

my $torealhome = sub {
  my $c = shift;

  (my $subdomain = standard( $c )) or return global_redirect($c);

  ($subdomain eq "auth") and return $c->redirect_to('/auth/index');

  (isenrolled( $subdomain, $c->session->{uemail} ))
    or return $c->flash(message => 'we do not know who you are, so you need to authenticate')->redirect_to('http://auth'.domain($c).'/index');

  _suundo();  ## sometimes after a direct redirect, this is oddly still set.  grrr

  my $desturl= isinstructor( $subdomain, $c->session->{uemail} ) ? '/instructor' : '/student';

  return $c->flash(message => $c->session->{uemail}." logs into $subdomain")->redirect_to($desturl)
};


get '/index' => $torealhome;
get '/' => $torealhome;

1;
