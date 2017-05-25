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
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  plugin 'RenderFile';  ## ask viktor why $c->render_file is not seen

  my $fname = $c->req->query_params->param('f');
  my $fullfilename;
  if (($fname =~ /.zip$/) && ($fname =~ m{/tmp/})) {
    $fullfilename = $fname;
  } else {
    $fname =~ s{.*/}{};
    $fullfilename= fullfilename( $course, $c->session->{uemail}, $fname);
    (-e $fullfilename) or die "file $fullfilename is not retrievable: $!\n";
  }

  return $c->render_file('filepath' => $fullfilename);
};
