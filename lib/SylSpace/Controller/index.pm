#!/usr/bin/env perl
package SylSpace::Controller::index;
use Mojolicious::Lite;  ## implied strict, warnings, utf8, 5.10
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(userisenrolled isinstructor);
use SylSpace::Model::Controller qw(global_redirect standard domain);

################################################################
## a redirector
################################################################

my $torealhome = sub {
  my $c = shift;

  (my $subdomain = standard( $c )) or return global_redirect($c);

  ($subdomain eq "auth") and return $c->redirect_to('/auth/index');

  userisenrolled( $subdomain, $c->session->{uemail} )
    or return $c->flash(message => 'we do not know who you are, so you need to authenticate')->redirect_to('http://auth'.domain($c).'/index');

  (isinstructor( $subdomain, $c->session->{uemail} )) and return $c->redirect_to('/instructor/');
  return $c->redirect_to('/student/');
};


get '/' => $torealhome;
get '/ignored' => $torealhome;
get '/index' => $torealhome;

1;
