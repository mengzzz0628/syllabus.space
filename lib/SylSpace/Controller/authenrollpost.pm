#!/usr/bin/env perl
package SylSpace::Controller::authenrollpost;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(userenroll coursesecret tweet);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

post '/auth/enrollpost' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  my $coursename= $c->req->body_params->param('course');
  my $secret= $c->req->body_params->param('secret');

  my $isecret= coursesecret($coursename);

  (lc($isecret) eq lc($secret)) or $c->flash( message => "$secret is so not the right secret for course $coursename" )->redirect_to('/auth/enroll');

  userenroll($coursename, $c->session->{uemail});

  tweet( $coursename, $c->session->{uemail}, " now enrolled in course $coursename\n" );

  return $c->flash( message => "you are now enrolled in course '$coursename'" )->redirect_to('/auth/goclass');
};

1;
