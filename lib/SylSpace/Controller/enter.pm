#!/usr/bin/env perl
package SylSpace::Controller::enter;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo seclog userunmorph);
use SylSpace::Model::Controller qw(global_redirect standard global_redirectmsg);

################################################################

get '/enter' => sub {
  my $c = shift;

  my $warner="";
  if ($c->req->url->to_abs->host =~ /localhost$/) {
    ## shit we are debugging and on localhost the cookies do not cross the
    ## subdomain; so we trust the e=... request
    if (defined($c->req->query_params->param("e"))) {
      $c->session->{uemail}= $c->req->query_params->param("e");
      $c->session->{expiration}= time()+3600*24*32;
      $warner= "you are localhost, so we need to trust your email ".$c->session->{uemail}." in the get request";
    }
  }

  (my $subdomain = standard( $c )) or return global_redirect($c);

  ($subdomain eq "auth") and return $c->flash(message => 'auth likes only index')->redirect_to('/auth/index');  ## we cannot enter the auth course site

  userunmorph( $subdomain, $c->session->{uemail} );
  seclog( $subdomain, $c->session->{uemail}||"no one", "entering website $subdomain" );
  return $c->flash( message => $warner )->redirect_to('/index');
};

1;
