#!/usr/bin/env perl
package SylSpace::Controller::InstructorFilemore;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(ifilelist1 sudo tzi);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/instructor/filemore' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  sudo( $subdomain, $c->session->{uemail} );

  my $fname=  $c->req->query_params->param('f');
  (defined($fname)) or die "need a filename for filemore.\n";

  $c->stash( detail => ifilelist1($subdomain, $c->session->{uemail}, $fname),
	     tzi => tzi( $c->session->{uemail} ) );
};

1;

################################################################

__DATA__

@@ instructorfilemore.html.ep

<% use SylSpace::Model::Controller qw(drawmore browser); %>

%title 'more file information';
%layout 'instructor';

<main>

  <%== drawmore('file', [ 'view', 'download', 'edit' ], $detail, $tzi, browser($self)); %>

</main>

