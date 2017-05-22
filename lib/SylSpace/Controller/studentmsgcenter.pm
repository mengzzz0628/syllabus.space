#!/usr/bin/env perl
package SylSpace::Controller::StudentMsgcenter;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(msglistread isenrolled msgread);
use SylSpace::Model::Controller qw(global_redirect standard  msghash2string);

################################################################

get '/student/msgcenter' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  (isenrolled($subdomain, $c->session->{uemail})) or $c->flash( message => "first enroll in $subdomain please" )->redirect_to('/auth/goclass');

  my @msglistread= msglistread($subdomain, $c->session->{uemail});
  $c->stash( msgstring => msghash2string(msgread( $subdomain ), "/msgmarkread", \@msglistread ) );
};

1;

################################################################

__DATA__

@@ studentmsgcenter.html.ep

%title 'message center';
%layout 'student';

<main>

<h2> All Previously Posted Messages </h2>

<%== $msgstring %>

</main>

