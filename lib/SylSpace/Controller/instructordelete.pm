#!/usr/bin/env perl
package SylSpace::Controller::instructordelete;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo filedelete);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get '/instructor/delete' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  sudo( $subdomain, $c->session->{uemail} );

  my $fname= $c->req->query_params->param('f');

  filedelete( $subdomain, $c->session->{uemail}, $fname);

  ## we cannot go back, because the page no longer exists! return $c->redirect_to($c->req->headers->referrer);
  return $c->flash( message=> "completely deleted file $fname" )->redirect_to( ''.(($fname =~ /^hw/) ? 'hwcenter' : ($fname =~ /\.equiz$/) ? 'equizcenter' : 'filecenter'));
};

1;
