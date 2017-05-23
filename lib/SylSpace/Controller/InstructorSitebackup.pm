#!/usr/bin/env perl
package SylSpace::Controller::InstructorSitebackup;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sitebackup sudo isvalidsitebackupfile);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/instructor/sitebackup' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  sudo( $subdomain, $c->session->{uemail} );

  my $filename= sitebackup( $subdomain );
  (-e $filename) or die "internal error: zip file $filename vanished";

  (isvalidsitebackupfile($filename)) or die "internal error: '$filename' is not a good site backup file\n";

  $c->render( filename => $filename, template => 'InstructorSitebackup' );
};

1;

################################################################

__DATA__

@@ InstructorSitebackup.html.ep

%title 'Site Backup';
%layout 'instructor';

<main>

<meta http-equiv="refresh" content="1;url=silentdownload?f=<%=$filename%>">

  <p>Your zipped backup file has been created and will download in a moment.</p>

  <p>Naturally, if the syllabus.space webserver dies or is compromised, only your local backup will survive.  So please make sure to keep it in a safe place!</p>

</main>
