#!/usr/bin/env perl
package SylSpace::Controller::studentfilecenter;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use feature ':5.20';
use feature 'signatures';
no warnings qw(experimental::signatures);

use SylSpace::Model::Model qw(sfilelistall userisenrolled);
use SylSpace::Model::Controller qw(global_redirect  standard domain);

################################################################

get '/student/filecenter' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  (userisenrolled($subdomain, $c->session->{uemail})) or $c->flash( message => "first enroll in $subdomain please" )->redirect_to('/auth/goclass');

  $c->stash( filelist => sfilelistall($subdomain, $c->session->{uemail}, "X") );
};

1;

################################################################

__DATA__

@@ studentfilecenter.html.ep

%title 'file center';
%layout 'student';

<main>

<%
    use SylSpace::Model::Controller qw(timedelta btnblock);

     sub filehash2string {
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
         $filestring .= btnblock("view?f=".($_->[0]), '<i class="fa fa-pencil"></i> '.($_->[0]), "");
       }
       ($counter) or return "<p>no publicly posted files at the moment</p>";

       return $filestring;
     }
%>


 <nav>
   <div class="row top-buffer text-center">
    <%== filehash2string( $filelist ) %>
   </div>
 </nav>

</main>
