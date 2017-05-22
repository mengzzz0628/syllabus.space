#!/usr/bin/env perl
package SylSpace::Controller::InstructorSilentdownload;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo fullfilename);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get 'instructor/silentdownload' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  sudo( $subdomain, $c->session->{uemail} );

  plugin 'RenderFile';  ## ask viktor why $c->render_file is not seen

  my $fname = $c->req->query_params->param('f');
  $fname =~ s{.*/}{};

  my $fullfilename= fullfilename( $subdomain, $c->session->{uemail}, $fname);
  (-e $fullfilename) or die "file $fullfilename is not retrievable: $!\n";

  return $c->render_file('filepath' => $fullfilename);
};
