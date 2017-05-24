#!/usr/bin/env perl
package SylSpace::Controller::StudentEquizcenter;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use feature ':5.20';
use feature 'signatures';
no warnings qw(experimental::signatures);

use SylSpace::Model::Model qw(sfilelistall isenrolled);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/student/equizcenter' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  (isenrolled($subdomain, $c->session->{uemail})) or $c->flash( message => "first enroll in $subdomain please" )->redirect_to('/auth/goclass');

  $c->stash( filelist => sfilelistall($subdomain, $c->session->{uemail}, "*equiz") );
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
    <%== equizfilehash2string( $filelist ) %>
   </div>
 </nav>

</main>


<%
sub equizfilehash2string {
  my $filehashptr= shift;
  (defined($filehashptr)) or return "";
  my $filestring= '';

  my $counter=0;
  foreach (@$filehashptr) {
    ($_->[1]<time()) and next;
    ++$counter;

    (my $shortname = $_->[0]) =~ s/\.equiz$//;
    my $duein= timedelta($_->[1] , time());
    $filestring .= btnblock("/renderequiz?f=".($_->[0]),
			    '<h4><i class="fa fa-pencil"></i> '.$shortname.'</h4>',
			    $duein."<br />".localtime($_->[1])."<br /><span style=\"font-size:x-small\">add last taken and score if available</span>");
  }
  ($counter) or return "<p>no publicly posted equizzes at the moment</p>";

  return $filestring;
}
%>

