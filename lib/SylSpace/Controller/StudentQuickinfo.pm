#!/usr/bin/env perl
package SylSpace::Controller::StudentQuickinfo;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(isenrolled cioread hassyllabus);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/student/quickinfo' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  (isenrolled($subdomain, $c->session->{uemail})) or $c->flash( message => "first enroll in $subdomain please" )->redirect_to('/auth/goclass');

  $c->stash( cioread => cioread($subdomain), requestsyllabus => hassyllabus($subdomain)  );
};

1;

################################################################

__DATA__

@@ studentquickinfo.html.ep

%title 'quick info';
%layout 'student';

<main>

<h1>Quick Course Facts</h1>

  <table class="table" style="width: auto !important; margin: 2em;">
    <tr> <th> Subject Matter </th> <td> <%= $cioread->{subject} %> </td> </tr>
    <tr> <th> Course Code </th> <td> <%= $cioread->{unicode} %> </td> </tr>
    <tr> <th> Department </th> <td> <%= $cioread->{department} %> </td> </tr>
    <tr> <th> University </th> <td> <%= $cioread->{uniname} %> </td> </tr>
    <tr> <th> Meets </th> <td> <%= $cioread->{meetroom}." : ".$cioread->{meettime} %> </td> </tr>
    <tr> <th> Course Email </th> <td> <a href="<%= $cioread->{cemail} %>"><%= $cioread->{cemail} %></a> </td> </tr>
    <tr> <th> Syllabus </th> <td> <% my $s=$requestsyllabus; %> <%== (defined($s)) ? qq(<a href="/student/fileview?f=$s">syllabus</a>): 'n/a' %> </td> </tr>
  </table>

</main>

