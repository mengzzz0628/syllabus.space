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

  (my $course = standard( $c )) or return global_redirect($c);

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

%title 'choose course';
%layout 'auth';

<main>

<hr />

<h3> Enrolled Courses </h3>

  <div class="row top-buffer text-center">
    <%== coursebuttonsentry($self, $courselistenrolled, $email, 1) %>
  </div>

<hr />

<h3> Other Available Courses </h3>

  <div class="row top-buffer text-center">
    <%== coursebuttonsenroll($self, $courselistnotenrolled, $email, 0) %>
  </div>

  <hr />

<h3> Change Auto-Logout Time </h3>

  <p>Currently, you are set to be logged out in <span><%= ((($self->session->{expiration})||0)-time())." seconds" %>, which is <%= $timedelta %>.</span></p>

   <div class="row top-buffer text-center">
     <%== btnblock("settimeout?tm=1", '<i class="fa fa-clock-o"></i> 1 day', 'reasonably safe', 'btn-default', 'w') %>
     <%== btnblock("settimeout?tm=7", '<i class="fa fa-clock-o"></i> 1 week', 'quite unsafe', 'btn-default', 'w') %>
  </div>

   <div class="row top-buffer text-center">
     <%== btnblock("settimeout?tm=90", '<i class="fa fa-clock-o"></i> 3 mos', 'better be your own computer', 'btn-default', 'w') %>
     <%== btnblock("/logout", '<i class="fa fa-sign-out"></i> Logout', 'from authentication', "btn-danger", 'w') %>
  </div>

  <hr />

<h3> Change Biographical Information and Settings </h3>

   <div class="row top-buffer text-center">
     <%== btnblock('/auth/bioform', '<i class="fa fa-user"></i> '.$self->session->{uemail}, 'Change My Biographical Information', 'btn-default btn-xs', 'w') %>
   </div>

</main>


  <%

  use SylSpace::Model::Controller qw(obscure);

sub coursebuttonsentry {
  my ($self, $courselist, $email)= @_;

  ## users want a sort by subdomain name first, then subsubdomain, then ...
  ## websites names are in reverse order

  my @courselist= keys %{$courselist};

  (@courselist) or return "<p>No courses enrolled yet.</p>";

  my %displaylist;
  foreach (@courselist) {
    $displaylist{ $_ } = join(" : ", reverse(split(/\./, $_)));
  }

  ## add a number of how many courses qualify from this list for possible combination
  my %subdomcount;
  foreach (@courselist) {
    my @f=split(/\./, $_); my $le=pop( @f );
    ++$subdomcount{ $le };
  }
  my %freq; my %group;
  foreach (@courselist) {
    my @f=split(/\./, $_); my $le=pop( @f );
    $freq{$_} = $subdomcount{ $le };
    $group{$le} .= $_."\n";
  }

  my $rs='';
  foreach (@courselist) {
    $rs .= btnblock( 'http://'.$_.'.'.domain($self).'/enter?e='.obscure( time().':'.$email.':'.$self->session->{expiration} ),
		     '<i class="fa fa-circle"></i> '.$displaylist{$_},
		     '', # $group{$_}." ".$freq{$_}||"N",
		     'btn-default',
		     'w' )."\n";
  }
  return $rs;
}



sub coursebuttonsenroll {
  my ($self, $courselist, $email)= @_;

  my @courselist= keys %{$courselist};

  (@courselist) or return "<p>No courses available.</p>";

  ## users want a sort by subdomain name first, then subsubdomain, then ...
  ## websites names are in reverse order

  my %displaylist;
  foreach (@courselist) {
    $displaylist{ $_ } = join(" : ", reverse(split(/\./, $_)));
  }

  ## add a number of how many courses qualify from this list for possible combination
  my %subdomcount;
  foreach (@courselist) {
    my @f=split(/\./, $_); my $le=pop( @f );
    ++$subdomcount{ $le };
  }
  my %group;
  foreach (@courselist) {
    my @f=split(/\./, $_); my $le=pop( @f );
    push(@{$group{$le}}, $_);
  }

  my $rs="";
  foreach my $g (sort keys %group) {
    my @displaylist= @{$group{$g}};

    sub imbtn {
      my ( $maintext, $subtext, $displaylist, $coursehassecret )= @_;
      my $url= ($coursehassecret) ? '/auth/userenrollform?c='.$maintext : '/auth/userenrollsavenopw?course='.$maintext ;
      my $icon=  ($coursehassecret) ? '<i class="fa fa-lock"></i> ': '<i class="fa fa-circle-o"></i> ';
      return btnblock($url, $icon.$displaylist->{$maintext}, $subtext." ".($coursehassecret||"no secret"), 'btn-default', 'w');
    }

    if (scalar(@displaylist) == 1) {
      my $course= $displaylist[0];
      $rs .= imbtn( $course, "singleton", \%displaylist, $courselist->{$course} )."\n";
    } else {
      $rs .= qq(<button type="button" class="btn btn-primary btn-block" data-toggle="collapse" data-target="#$g">\n<h3>$g</h3></button>);

      $rs .= qq(<div id="$g" class="collapse">);
      foreach my $x (@displaylist) {
	$rs .= imbtn( $x, "multiple", \%displaylist, $courselist->{$x}  )."\n";
      }
      $rs .= qq(</div>\n);
    }
  }

  return $rs;
}

%>
