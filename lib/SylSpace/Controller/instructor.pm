#!/usr/bin/env perl
package SylSpace::Controller::instructor;
use Mojolicious::Lite;  ## implied strict, warnings, utf8, 5.10
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo cbuttons msgreadnotread bioiscomplete cioiscomplete lasttweet);
use SylSpace::Model::Controller qw(global_redirect standard msghash2string global_redirect);

################################################################

my $ihm= sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  sudo( $subdomain, $c->session->{uemail} );

  (bioiscomplete($c->session->{uemail})) or $c->flash( message => 'You first need to complete your bio!' )->redirect_to('http://auth.'.domain($c).'/usettings');

  (cioiscomplete($subdomain)) or $c->flash( message => 'You first need to complete the course settings!' )->redirect_to('/instructor/csettings');

  my $lasttweet=lasttweet( $subdomain );

  $c->stash(
	    msgstring => msghash2string(msgreadnotread( $subdomain, $c->session->{uemail} ), "/msgmarkread"),
	    btnptr => cbuttons( $subdomain ),
	    lasttweet => $lasttweet,
	    template => 'instructor',
	   );
};

get '/instructor' => $ihm;
get '/instructor/index' => $ihm;


1;


################################################################


__DATA__

@@ instructor.html.ep

%title 'instructor';
%layout 'instructor';

<%
  use SylSpace::Model::Controller qw(btnblock);
%>

<main>

  <style> span.epoch { display:none; } </style>

  <%== $msgstring %>

  <nav>

   <div class="row top-buffer text-center">
     <%== btnblock("/instructor/msgcenter", '<i class="fa fa-paper-plane"></i> Messages', 'Msgs to Students') %>
     <%== btnblock("/instructor/equizcenter", '<i class="fa fa-pencil"></i> Equizzes', 'Algorithmic Testing') %>
     <%== btnblock("/instructor/hwcenter", '<i class="fa fa-folder-open"></i> HWorks', 'Assignments') %>
     <%== btnblock("/instructor/filecenter", '<i class="fa fa-files-o"></i> Files', 'Old Exams, etc') %>

     <%== btnblock("/instructor/studentlist", '<i class="fa fa-users"></i> Students', 'Enrolled List') %>
     <%== btnblock("/instructor/gradecenter", '<i class="fa fa-star"></i> Grades', 'Saved Scores') %>
     <%== btnblock("/instructor/csettings", '<i class="fa fa-wrench"></i> Course', 'Set Class Parameters') %>
     <%== btnblock("/auth/usettings", '<i class="fa fa-cog"></i> Bio', 'Set Bio Parameters') %>

     <%== btnblock("/rss", '<i class="fa fa-rss"></i> Class', 'Activity Monitor (<a href="/rss?rss=1">pure rss</a>)') %>
     <%== btnblock("/seclog", '<i class="fa fa-bars"></i> Sec Log', 'Security Records') %>
     <%== btnblock("/instructor/faq", '<i class="fa fa-question-circle"></i> Help', 'FAQ and More') %>
     <%== btnblock("/instructor/backup", '<i class="fa fa-cloud-download"></i> Backup', 'Backup My Account') %>

     <%== btnblock("/instructor/instructorlist", '<i class="fa fa-magic"></i> TAs', 'Set Assistants') %>
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

  <div class="row top-buffer text-center">
    <div class="col-md-10 col-md-offset-1">
         <a class="btn btn-primary btn-block" href="/instructor/morph">
		<h2> <i class="fa fa-graduation-cap"></i> Morph Into Student</h2></a>
    </div>
  </div>

  </nav>

  <%== $lasttweet %>

</main>
