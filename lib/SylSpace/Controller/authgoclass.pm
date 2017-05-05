#!/usr/bin/env perl
package SylSpace::Controller::authgoclass;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(courselist bioiscomplete);
use SylSpace::Model::Controller qw(global_redirect standard timedelta domain);

################################################################

get '/auth/goclass' => sub {
  my $c = shift;

  ($c->req->url->to_abs->host() =~ m{^auth\.})
    or $c->flash(message => 'not from auth, so back to root')->redirect_to('http://auth.'.domain($c).'/auth');

  (my $subdomain = standard( $c )) or return global_redirect($c);

  (bioiscomplete($c->session->{uemail})) or $c->flash( message => 'You first need to complete your bio!' )->redirect_to('/auth/usettings');

  $c->stash( timedelta => timedelta( $c->session->{expiration} ),
	     courselist => courselist($c->session->{uemail}),
	     email => $c->session->{uemail}, domain => domain($c) );
};

1;

################################################################

__DATA__

@@ authgoclass.html.ep

%title 'choose your class';
%layout 'auth';

<main>

<hr />

<h2> <%= $self->session->{uemail} %> </h2>

<h3> Enrolled Courses </h3>

  <%
  use SylSpace::Model::Controller qw(domain btnblock);
  use Data::Dumper;

  sub coursebuttons {
      my $self= shift; my $courselist= shift; my $email=shift;
      ## draws sets of buttons, either enrolled or available
      my $rs='<div class="row top-buffer text-center">';
      my $domain=domain($self);
      foreach (sort keys %{$courselist}) {
	my $fulldirname= $_;
	(defined($courselist->{$fulldirname}->{enrolled})) or die "sorry, but $fulldirname has no enrolled field?!".Dumper $courselist;
	my $isenrolled= $courselist->{$fulldirname}->{enrolled};
	($isenrolled == $_[0]) or next;
	s{.*/}{};  # keep only the final part
	$rs .= btnblock( (($isenrolled) ? "http://$_.$domain/enter?e=" : "/auth/enroll?c=$_&amp;e=").($email),  $_);
      }
      return $rs.'</div>';
    }
  %> <%== coursebuttons($self, $courselist, $email, 1) %>

<hr />

<h3> Other Available Courses </h3>

      <%== coursebuttons($self, $courselist, $email, 0) %>

  <hr />

<h3> Change Auto-Logout Time </h3>

   <div class="row top-buffer text-center">
     <%== btnblock("settimeout?tm=1", '1 day', 'reasonably safe',1) %>
     <%== btnblock("settimeout?tm=7", '1 week', 'quite unsafe',1) %>
     <%== btnblock("settimeout?tm=90", '3 mos', 'better be your own computer',1) %>
     <%== btnblock("/logout", 'Logout', 'from authentication', "btn-danger",1) %>
  </div>

  <p>Currently, you are set to be logged out in <span><%= ((($self->session->{expiration})||0)-time())." seconds" %>, which is <%= $timedelta %>.</span></p>

<hr />

</main>

