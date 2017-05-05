#!/usr/bin/env perl
package SylSpace::Controller::instructorhwcenter;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use feature ':5.20';
use feature 'signatures';
no warnings qw(experimental::signatures);

use SylSpace::Model::Model qw(sudo ifilelistall tzi);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################
get '/instructor/hwcenter' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  sudo( $subdomain, $c->session->{uemail} );

  $c->stash( filetable => ifilelistall($subdomain, [ 'view', 'download', 'edit' ], $c->session->{uemail}, "hw*"),
	   tzi => tzi( $c->session->{uemail} )  );
};




1;

################################################################

__DATA__

@@ instructorhwcenter.html.ep

%title 'homework center';
%layout 'instructor';

<main>

  <style> span.epoch { display:none; } </style>

  <% use SylSpace::Model::Controller qw( ifilehash2table fileuploadform); %>

  <%== ifilehash2table($filetable, 'hw', $tzi) %>

  <%== fileuploadform() %>

</main>
