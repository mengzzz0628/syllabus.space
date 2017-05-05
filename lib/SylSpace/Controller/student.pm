#!/usr/bin/env perl
package SylSpace::Controller::student;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo cbuttons msgreadnotread ismorphed userisenrolled bioiscomplete lasttweet);
use SylSpace::Model::Controller qw(global_redirect  standard msghash2string domain);

################################################################

my $shm= sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  (bioiscomplete($c->session->{uemail})) or $c->flash( message => 'You first need to complete your bio!' )->redirect_to('http://auth.'.domain($c).'/usettings');

  (userisenrolled($subdomain, $c->session->{uemail})) or $c->flash( message => "first enroll in $subdomain please" )->redirect_to('/auth/goclass');

  $c->stash(
	    msgstring => msghash2string(msgreadnotread( $subdomain, $c->session->{uemail} ), "/msgmarkread"),
	    btnptr => cbuttons( $subdomain )||undef,
	    ismorphed => ismorphed( $subdomain,$c->session->{uemail} ),
	    lasttweet => lasttweet( $subdomain )||"",
	    template => 'student',
	   );

};

get '/student' => $shm;
get '/student/index' => $shm;

1;

################################################################

__DATA__

@@ student.html.ep

%title 'student';
%layout 'student';


<%
  use SylSpace::Model::Controller qw(btnblock);
%>

<main>
  <style> span.epoch { display:none; } </style>

  <%== $msgstring %>

  <nav>

   <div class="row top-buffer text-center">
     <%== btnblock("/student/msgcenter", '<i class="fa fa-paper-plane"></i> Messages', 'From Instructor') %>
     <%== btnblock("/student/equizcenter", '<i class="fa fa-pencil"></i> Equizzes', 'Test Yourself') %>
     <%== btnblock("/student/hwcenter", '<i class="fa fa-folder-open"></i> HWork', 'Assignments') %>

     <%== btnblock("/student/filecenter", '<i class="fa fa-files-o"></i> Files', 'Old Exams, etc') %>

     <%== btnblock("/student/gradecenter", '<i class="fa fa-star"></i> Grades', 'Saved Scores') %>
     <%== btnblock("/auth/usettings", '<i class="fa fa-cog"></i> Bio', 'Set My Profile') %>

     <%== btnblock("/seclog", '<i class="fa fa-bars"></i> Sec Log', 'Security Records') %>
     <%== btnblock("/rss", '<i class="fa fa-rss"></i> Class', 'Activity Monitor') %>
     <%== btnblock("/student/faq", '<i class="fa fa-question-circle"></i> Help', 'FAQ and More') %>

     <%== btnblock("/student/quickinfo", '<i class="fa fa-info-circle"></i> Quick', 'Location, Instructor') %>

    </div>


  <%
  my $btnstring="";
  if (defined($btnptr)) {
    $btnstring= '<div class="row top-buffer text-center">';
    my $numbuttons= scalar @{$btnptr};
    foreach (@$btnptr) { $btnstring .= btnblock($_->[0], $_->[1], $_->[2]); }
    $btnstring .= "</div>\n";
  }
  %> <%== $btnstring %>

  <%== $ismorphed ? '<div class="row top-buffer text-center">
    <div class="col-md-10 col-md-offset-1">
          <a class="btn btn-primary btn-block" href="/student/unmorph">
		<h2> <i class="fa fa-graduation-cap"></i> Unmorph Back To Instructor</h2></a>
      </div>
    </div>' : ""
  %>

  </nav>

  <%== $lasttweet %>

</main>
