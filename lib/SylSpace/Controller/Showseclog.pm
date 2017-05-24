#!/usr/bin/env perl
package SylSpace::Controller::Showseclog;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(isenrolled showseclog isinstructor);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get '/showseclog' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  (isenrolled($subdomain, $c->session->{uemail})) or $c->flash( message => "first enroll in $subdomain please" )->redirect_to('/goclass');
  my $seclog= showseclog($subdomain);

  $c->stash(toprightexit => '<li><a href="/auth/goclass"> <i class="fa fa-sign-out"></i> Exit Course </a></li>');

  if (!isinstructor($subdomain, $c->session->{uemail})) {
    my @seclog=split(/\n/, $seclog);
    @seclog = grep { $_ =~ $c->session->{uemail} } @seclog;
    $seclog= join("\n", @seclog);
    $c->stash( color => $ENV{sitescolor}, homeurl => '/student' );
  } else {
    $c->stash( color => $ENV{siteicolor}, homeurl => '/instructor' );
  }

  $c->stash( seclog => $seclog );
};

1;

################################################################

__DATA__

@@ showseclog.html.ep

<% use SylSpace::Model::Controller qw(displaylog); %>


%title 'security log';
%layout 'sylspace';

<main>

  <%== displaylog( $seclog ); %>

</main>

