#!/usr/bin/env perl
package SylSpace::Controller::instructorbackup;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(websitebackup sudo);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/instructor/backup' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  sudo( $subdomain, $c->session->{uemail} );

  my $filename= websitebackup( $subdomain );
  $filename =~ s{.*/}{};
  $c->stash( filename => $filename );
};

1;

################################################################

__DATA__

@@ instructorbackup.html.ep

%title 'backup website';
%layout 'instructor';

<main>

<meta http-equiv="refresh" content="1;url=silentdownload?f=<%=$filename%>">

  <p>Your zipped backup file has been created and saved into your <a href="/instructor/filecenter">file center</a>.  Please delete it when you no longer need it.  Space is scarce.</p>

  <p>This file should download by itself in a moment.  If not, please click <a href="silentdownload?f=<%=$filename%>">silentdownload?f=<%=$filename%></a>.</p>

  <p>Naturally, if the webserver dies, only your local backup will survive.  So please make sure to keep it in a safe place!</p>

</main>
