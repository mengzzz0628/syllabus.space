#!/usr/bin/env perl
package SylSpace::Controller::InstructorCiobuttonsave;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo ciobuttonsave);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/instructor/ciobuttonsave' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  sudo( $subdomain, $c->session->{uemail} );

  my @buttonlist;
  foreach my $i (0..9) {
    my $url= $c->req->query_params->param("url$i");
    my $titlein= $c->req->query_params->param("titlein$i");
    my $textin= $c->req->query_params->param("textin$i");

    ($url =~ /^http/i) or next;
    ($titlein) or next;
    push(@buttonlist, [ $url, $titlein, $textin ])
  }

  ciobuttonsave( $subdomain, \@buttonlist ) or return global_redirect($c);
  $c->flash( message => 'updated buttons' )->redirect_to('/instructor');
};

1;
