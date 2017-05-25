#!/usr/bin/env perl
package SylSpace::Controller::AuthUserenrollsave;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(userenroll getcoursesecret tweet);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

post '/auth/userenrollsave' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  my $coursename= $c->req->body_params->param('course');
  my $secret= $c->req->body_params->param('secret');

  (defined($coursename)) or die "wtf";
  my $isecret= getcoursesecret($coursename);

  (lc($isecret) eq lc($secret)) or
    return $c->flash( message => "$secret is so not the right secret for course $coursename" )->redirect_to('/auth/userenrollform?c='.$coursename);

  userenroll($coursename, $c->session->{uemail});

  tweet($c->tx->remote_address, $coursename, $c->session->{uemail}, " now enrolled in course $coursename\n" );

  return $c->flash( message => "you are now enrolled in course '$coursename'" )->redirect_to('/auth/goclass');
};

################

get '/auth/userenrollsavenopw' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  my $coursename= $c->req->query_params->param('course');

  (defined($coursename)) or die "wtf";
  (defined(getcoursesecret($coursename))) and die "sorry, but course $coursename requires a secret";

  userenroll($coursename, $c->session->{uemail});

  tweet($c->tx->remote_address, $coursename, $c->session->{uemail}, " now enrolled in no-secret course $coursename\n" );

  return $c->flash( message => "you are now enrolled in course '$coursename'" )->redirect_to('/auth/goclass');
};


1;
