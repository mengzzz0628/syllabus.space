#!/usr/bin/env perl
package SylSpace::Controller::instructorfilecenter;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use feature ':5.20';
use feature 'signatures';
no warnings qw(experimental::signatures);

use SylSpace::Model::Model qw(ifilelistall sudo tzi);
use SylSpace::Model::Controller qw(global_redirect  standard);


get '/instructor/filecenter' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  sudo( $subdomain, $c->session->{uemail} );

  $c->stash( filelist => ifilelistall($subdomain, $c->session->{uemail}, "X" ),
	   tzi => tzi( $c->session->{uemail} )  ); ## X means not hw and not equiz
};


1;

################################################################

__DATA__

@@ instructorfilecenter.html.ep

%title 'file center';
%layout 'instructor';

<script src="/js/dropzone.js"></script>

<main>

  <% use SylSpace::Model::Controller qw( ifilehash2table fileuploadform);

  <%== ifilehash2table($filelist, [ 'view', 'download', 'edit' ], 'file', $tzi) %>

  <%== fileuploadform() %>

  <h2> Big Drop Zone </h2>

  <form action="uploadfile" method="POST" class="dropzone"  id="my-awesome-dropzone" enctype="multipart/form-data">

  <img src="/images/mickey.png" />

  </form>

</main>
