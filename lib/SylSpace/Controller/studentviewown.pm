#!/usr/bin/env perl
package SylSpace::Controller::studentviewown;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(userisenrolled sownfileread);
use SylSpace::Model::Controller qw(global_redirect standard domain);

################################################################

get '/student/viewown' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  (userisenrolled($subdomain, $c->session->{uemail})) or $c->flash( message => "first enroll in $subdomain please" )->redirect_to('/auth/goclass');

  my $fname= $c->req->query_params->param('f');
  my $filecontent= sownfileread( $subdomain, $c->session->{uemail}, $fname );

  (defined($filecontent)) or return $c->flash(message => "file $fname cannot be found")->redirect_to($c->req->headers->referrer);
  (length($filecontent)>0) or return $c->flash(message => "file $fname was empty")->redirect_to($c->req->headers->referrer);

  (my $extension= $fname) =~ s{.*\.}{};

  return ($fname =~ /\.(txt|text|html|htm|csv)$/i) ? $c->render(text => $filecontent, format => 'txt') :
    $c->render(data => $filecontent, format => $extension);
};

1;

################################################################

__DATA__

@@ studentviewown.html.ep

%title 'view own files';
%layout 'student';

<main>

<h1>Not Yet</h1>

</main>

