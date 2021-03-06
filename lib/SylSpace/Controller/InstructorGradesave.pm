#!/usr/bin/env perl
package SylSpace::Controller::InstructorGradesave;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo seclog);
use SylSpace::Model::Grades qw(gradesave);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get '/instructor/gradesave' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

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
  gradesave($course, \@semail, \@taskname, \@newgrade);

  seclog($c->tx->remote_address, $course, 'instructor', "changed many grades [to enhance please]" );

  $c->flash( message=> "submitted many grades" )->redirect_to("gradecenter");
};

1;
