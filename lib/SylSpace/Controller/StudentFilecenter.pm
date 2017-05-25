#!/usr/bin/env perl
package SylSpace::Controller::StudentFilecenter;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use feature ':5.20';
use feature 'signatures';
no warnings qw(experimental::signatures);

use SylSpace::Model::Model qw(sfilelistall isenrolled);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/student/filecenter' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  (isenrolled($course, $c->session->{uemail})) or $c->flash( message => "first enroll in $course please" )->redirect_to('/auth/goclass');

  $c->stash( filelist => sfilelistall($course, $c->session->{uemail}, "X") );
};

1;

################################################################

__DATA__

@@ studentfilecenter.html.ep

<% use SylSpace::Model::Controller qw(timedelta btnblock); %>

%title 'file center';
%layout 'student';

<main>

 <nav>
   <div class="row top-buffer text-center">
    <%== filefilehash2string( $filelist ) %>
   </div>
 </nav>

</main>

<%
     sub filefilehash2string {
       my $filehashptr= shift;
       defined($filehashptr) or return "";
       my $filestring= '';

       my $counter=0;
       use Data::Dumper;

       foreach (@$filehashptr) {
         ($_->[1]<time()) and next;
         ++$counter;

         (my $shortname = $_->[0]) =~ s/\.file$//;
         my $duein= timedelta($_->[1] , time());
         $filestring .= btnblock("/student/fileview?f=".($_->[0]), '<i class="fa fa-pencil"></i> '.($_->[0]), "", "btn-default", "w");
       }
       ($counter) or return "<p>no publicly posted files at the moment</p>";

       return $filestring;
     }
%>
