#!/usr/bin/env perl
package SylSpace::Controller::seclog;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(userisenrolled seclogged isinstructor);
use SylSpace::Model::Controller qw(global_redirect  standard domain);

################################################################

get '/seclog' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  (userisenrolled($subdomain, $c->session->{uemail})) or $c->flash( message => "first enroll in $subdomain please" )->redirect_to('/goclass');
  my $seclog= seclogged($subdomain);

  $c->stash(toprightexit => '<li><a href="/auth/goclass"> <i class="fa fa-sign-out"></i> Exit Course </a></li>');

  if (!isinstructor($subdomain, $c->session->{uemail})) {
    my @seclog=split(/\n/, $seclog);
    @seclog = grep { $_ =~ $c->session->{uemail} } @seclog;
    $seclog= join("\n", @seclog);
    $c->stash( color => 'white', homeurl => '/student' );
  } else {
    $c->stash( color => 'beige', homeurl => '/instructor' );
  }

  $c->stash( seclog => $seclog );
};

1;

################################################################

__DATA__

@@ seclog.html.ep

%title 'security log';
%layout 'sylspace';

<main>

<%
    use SylSpace::Model::Controller qw(displaylog);
%> <%== displaylog( $seclog ); %>



</main>

