#!/usr/bin/env perl
package SylSpace::Controller::StudentEquizcenter;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use feature ':5.20';
use feature 'signatures';
no warnings qw(experimental::signatures);

use SylSpace::Model::Model qw(sfilelistall isenrolled gradesashash);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/student/equizcenter' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  (isenrolled($course, $c->session->{uemail})) or $c->flash( message => "first enroll in $course please" )->redirect_to('/auth/goclass');

  my $allgrades= gradesashash( $course, $c->session->{uemail} );  ## just my own grades!

  $c->stash( filelist => sfilelistall($course, $c->session->{uemail}, "*equiz"), allgrades => $allgrades );
};

1;

################################################################

__DATA__

@@ studentequizcenter.html.ep

<% use SylSpace::Model::Controller qw(timedelta btnblock); %>

%title 'equiz center';
%layout 'student';

<main>

 <nav>
   <div class="row top-buffer text-center">
    <%== equizfilehash2string( $self, $filelist, $allgrades ) %>
   </div>
 </nav>

</main>


<%
  use strict;

sub equizfilehash2string {
  my $self= shift;
  my $filehashptr= shift;
  (defined($filehashptr)) or return "";
  my $allgrades= shift;

  my $filestring= '';

  my $counter=0;
  foreach (@$filehashptr) {
    ($_->[1]<time()) and next;
    ++$counter;

    (my $shortname = $_->[0]) =~ s/\.equiz$//;
    my $duein= timedelta($_->[1] , time());

    my $uemail=$self->session->{uemail};

    my $lastgrade= $allgrades->{ grade }->{ $uemail } ->{ $_->[0] } || "no grade yet";
    my $lastdate= $allgrades->{ epoch }->{ $uemail }->{ $_->[0] } || "no date";

    $filestring .= btnblock("/equizrender?f=".($_->[0]),
			    '<h4><i class="fa fa-pencil"></i> '.$shortname.'</h4>',
			    'due '.$duein."<br />".localtime($_->[1])."<br /><span style=\"font-size:x-small\">Last Taken: ".timedelta($lastdate).": Score $lastgrade</span>");
  }
  ($counter) or return "<p>no publicly posted equizzes at the moment</p>";

  return $filestring;
}
%>

