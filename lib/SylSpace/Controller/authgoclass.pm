#!/usr/bin/env perl
package SylSpace::Controller::AuthGoclass;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(courselistenrolled courselistnotenrolled bioiscomplete);
use SylSpace::Model::Controller qw(standard global_redirect timedelta domain);

################################################################

get '/auth/goclass' => sub {
  my $c = shift;

  (my $subdomain = standard( $c )) or return global_redirect($c);

  (bioiscomplete($c->session->{uemail})) or $c->flash( message => 'You first need to complete your bio!' )->redirect_to('/auth/bioform');

  ($c->session->{expiration}) or die "you have no expiration date, ".$c->session->{uemail}."?!";

  $c->stash( timedelta => timedelta( $c->session->{expiration} ),
	     courselistenrolled => courselistenrolled($c->session->{uemail}),
	     courselistnotenrolled => courselistnotenrolled($c->session->{uemail}),
	     email => $c->session->{uemail}, domain => domain($c) );
};

1;

################################################################

__DATA__

@@ authgoclass.html.ep

<% use SylSpace::Model::Controller qw(domain btnblock); %>

%title 'choose your class';
%layout 'auth';

<main>

<hr />

<h2> <%= $self->session->{uemail} %> </h2>


<h3> Enrolled Courses </h3>

    <%== coursebuttonsenter($self, $courselistenrolled, $email, 1) %>

<hr />

<h3> Other Available Courses </h3>

      <%== coursebuttonsenroll($self, $courselistnotenrolled, $email, 0) %>

  <hr />

<h3> Change Auto-Logout Time </h3>

   <div class="row top-buffer text-center">
     <%== btnblock("settimeout?tm=1", '1 day', 'reasonably safe') %>
     <%== btnblock("settimeout?tm=7", '1 week', 'quite unsafe') %>
     <%== btnblock("settimeout?tm=90", '3 mos', 'better be your own computer') %>
     <%== btnblock("/logout", 'Logout', 'from authentication', "btn-danger") %>
  </div>

  <p>Currently, you are set to be logged out in <span><%= ((($self->session->{expiration})||0)-time())." seconds" %>, which is <%= $timedelta %>.</span></p>

<hr />

</main>


  <%

  use SylSpace::Model::Controller qw(obscure);

sub coursebuttonsenter {
  my ($self, $courselist, $email)= @_;

  ## users want a sort by subdomain name first, then subsubdomain, then ...
  ## websites names are in reverse order

  (@{$courselist}) or return "<p>No courses enrolled yet.</p>";

  my %displaylist;
  foreach (@{$courselist}) {
    $displaylist{ $_ } = join(" : ", reverse(split(/\./, $_)));
  }

  ## add a number of how many courses qualify from this list for possible combination
  my %subdomcount;
  foreach (@$courselist) {
    my @f=split(/\./, $_); my $le=pop( @f );
    ++$subdomcount{ $le };
  }
  my %freq; my %group;
  foreach (@$courselist) {
    my @f=split(/\./, $_); my $le=pop( @f );
    $freq{$_} = $subdomcount{ $le };
    $group{$le} .= $_;
  }

  my $rs='<div class="row top-buffer text-center">'."\n";
  foreach (@$courselist) {
    $rs .= btnblock( 'http://'.$_.'.'.domain($self).'/enter?e='.obscure( time().':'.$email.':'.$self->session->{expiration} ),
		     $displaylist{$_},
		     '', # $group{$_}." ".$freq{$_}||"N",
		     'btn-default',
		     'w' )."\n";
  }
  return $rs.'</div>';
}


sub coursebuttonsenroll {
  my ($self, $courselist, $email)= @_;

  (@{$courselist}) or return "<p>No courses available.</p>";

  ## users want a sort by subdomain name first, then subsubdomain, then ...
  ## websites names are in reverse order

  my %displaylist;
  foreach (@{$courselist}) {
    $displaylist{ $_ } = join(" : ", reverse(split(/\./, $_)));
  }

  ## add a number of how many courses qualify from this list for possible combination
  my %subdomcount;
  foreach (@$courselist) {
    my @f=split(/\./, $_); my $le=pop( @f );
    ++$subdomcount{ $le };
  }
  my %group;
  foreach (@$courselist) {
    my @f=split(/\./, $_); my $le=pop( @f );
    push(@{$group{$le}}, $_);
  }

  my $rs="";
  foreach my $g (sort keys %group) {
    my @displaylist= @{$group{$g}};

    sub imbtn {
      my ( $url, $maintext, $subtext, $displaylist )= @_;
      return btnblock($url, $displaylist->{$maintext}, $subtext, 'btn-default', 'w');
    }

    if (scalar(@displaylist) == 1) {
      my $course= $displaylist[0];
      $rs .= imbtn( '/auth/userenrollform?c='.$course, $course, "singleton", \%displaylist );
    } else {
      ## nah $rs .= qq(</div>\n<div class="row">);
      $rs .= qq(<button type="button" class="btn btn-block btn" data-toggle="collapse" data-target="#$g">\n<h3>$g</h3></button>
          <div id="$g" class="collapse">);
      foreach my $x (@displaylist) {
	$rs .= imbtn( "/auth/userenrollform?c=$x", $x, "multiple $_", \%displaylist )."\n";
      }
      $rs .= "</div>\n</div>\n";
    }
  }

  return $rs."</div>";
}

%>
