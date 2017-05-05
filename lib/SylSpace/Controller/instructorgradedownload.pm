#!/usr/bin/env perl
package SylSpace::Controller::instructorgradedownload;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo gradesashash gradesasraw);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get '/instructor/gradedownload' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  sudo( $subdomain, $c->session->{uemail} );

  sub wide {
    my $all= gradesashash( $_[0] );
    my $rs= "";
    $rs.= "Student";
    foreach (@{$all->{hw}}) { $rs.= ",$_"; }
    $rs.= "\n";

    foreach my $st (@{$all->{uemail}}) {
      $rs.= "$st";
      foreach my $hw (@{$all->{hw}}) {
	$rs.= ",".($all->{grade}->{$st}->{$hw}||"");
      }
      $rs.= "\n";
    }
    return $rs;
  }

  sub flong {
    my $s="student,hw,grade,epoch,date\n".gradesasraw( $_[0] );
    $s =~ s/\t/\,/gm;
    $s =~ s/(.*\,)(1\d+)/"$1$2,".localtime($2)/ge;
    return $s;
  }

  my $sf= $c->req->query_params->param('sf');
  ($sf eq "w") and return $c->render(text => wide( $subdomain ), format => 'csv');
  return $c->render(text => flong( $subdomain ), format => 'csv');
  die "sorry, what format is $sf supposed to be?";
};

1;
