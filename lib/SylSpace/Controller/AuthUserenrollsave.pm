#!/usr/bin/env perl
package SylSpace::Controller::AuthUserenrollsave;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(userenroll coursesecret tweet);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

post '/auth/userenrollsave' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  my $coursename= $c->req->body_params->param('course');
  my $secret= $c->req->body_params->param('secret');

  (defined($coursename)) or die "wtf";
  my $isecret= coursesecret($coursename);

  $isecret =~ s{.*secret\=}{};

  (lc($isecret) eq lc($secret)) or
    return $c->flash( message => "$secret is so not the right secret for course $coursename" )->redirect_to('/auth/userenrollform?c='.$coursename);

  userenroll($coursename, $c->session->{uemail});

  tweet($c->tx->remote_address, $coursename, $c->session->{uemail}, " now enrolled in course $coursename\n" );

  return $c->flash( message => "you are now enrolled in course '$coursename'" )->redirect_to('/auth/goclass');
};

1;
