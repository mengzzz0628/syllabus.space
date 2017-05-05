#!/usr/bin/env perl
package SylSpace::Controller::instructorgradeentermanysubmit;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo gradeenter seclog);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get '/instructor/gradeentermanysubmit' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  sudo( $subdomain, $c->session->{uemail} );

  my $params=$c->req->query_params;
  my $phash= $params->to_hash();

  use Data::Dumper;

  my $task= $phash->{task};

  my (@semail, @taskname, @newgrade);
  foreach (keys %{$phash}) {
    (/^task$/) and next;
    push(@semail, $_); push(@taskname, $task); push(@newgrade, $phash->{$_});
  }

  ## may not work, because filenames are now args and not given.  please check
  gradeenter($subdomain, \@semail, \@taskname, \@newgrade);

  seclog( $subdomain, 'instructor', "changed many grades [to enhance please]" );

  $c->flash( message=> "submitted many grades" )->redirect_to("gradecenter");
};

1;
