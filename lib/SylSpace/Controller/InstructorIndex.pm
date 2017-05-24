#!/usr/bin/env perl
package SylSpace::Controller::InstructorIndex;
use Mojolicious::Lite;  ## implied strict, warnings, utf8, 5.10
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo ciobuttons msgshownotread bioiscomplete cioiscomplete showlasttweet _suundo);
use SylSpace::Model::Controller qw(global_redirect standard msghash2string global_redirect);

################################################################

my $ihm= sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  _suundo();  ## sometimes after a direct redirect, this is oddly still set.  grrr

  sudo( $subdomain, $c->session->{uemail} );

  (bioiscomplete($c->session->{uemail})) or $c->flash( message => 'You first need to complete your bio!' )->redirect_to('http://auth.'.domain($c).'/usettings');

  (cioiscomplete($subdomain)) or $c->flash( message => 'You first need to complete the course settings!' )->redirect_to('/instructor/csettings');

  $c->stash(
	    msgstring => msghash2string(msgshownotread( $subdomain, $c->session->{uemail} ), "/msgmarkasread"),
	    btnptr => ciobuttons( $subdomain ),
	    lasttweet => showlasttweet( $subdomain ),
	    template => 'instructor',
	   );
};

get '/instructor/index.html' => $ihm;
get '/instructor/index' => $ihm;
get '/instructor' => $ihm;


1;


################################################################


__DATA__

@@ instructor.html.ep

<% use SylSpace::Model::Controller qw(btnblock); %>

%title 'instructor';
%layout 'instructor';

<main>


  <%== $msgstring %>

  <nav>

   <div class="row top-buffer text-center">
     <%== btnblock("/instructor/msgcenter", '<i class="fa fa-paper-plane"></i> Messages', 'Msgs to Students') %>
     <%== btnblock("/instructor/equizcenter", '<i class="fa fa-pencil"></i> Equizzes', 'Algorithmic Testing') %>
     <%== btnblock("/instructor/hwcenter", '<i class="fa fa-folder-open"></i> HWorks', 'Assignments') %>
     <%== btnblock("/instructor/filecenter", '<i class="fa fa-files-o"></i> Files', 'Old Exams, etc') %>

     <%== btnblock("/instructor/studentdetailedlist", '<i class="fa fa-users"></i> Students', 'Enrolled List') %>
     <%== btnblock("/instructor/gradecenter", '<i class="fa fa-star"></i> Grades', 'Saved Scores') %>
     <%== btnblock("/instructor/cioform", '<i class="fa fa-wrench"></i> Course', 'Set Class Parameters') %>
     <%== btnblock("/auth/bioform", '<i class="fa fa-cog"></i> Bio', 'Set My Profile') %>

     <%== btnblock("/showtweets", '<i class="fa fa-rss"></i> Class', 'Activity Monitor (<a href="/rss?rss=1">pure rss</a>)') %>
     <%== btnblock("/showseclog", '<i class="fa fa-lock"></i> Sec Log', 'Security Records') %>
     <%== btnblock("/instructor/faq", '<i class="fa fa-question-circle"></i> Help', 'FAQ and More') %>
     <%== btnblock("/instructor/sitebackup", '<i class="fa fa-cloud-download"></i> Backup', 'Backup My Account') %>

     <%== btnblock("/instructor/instructorlist", '<i class="fa fa-magic"></i> TAs', 'Set Assistants') %>
   </div>

  <%== btnstring($btnptr) %>

  <div class="row top-buffer text-center">
    <div class="col-md-10 col-md-offset-1">
         <a class="btn btn-primary btn-block" href="/instructor/instructor2student">
		<h2> <i class="fa fa-graduation-cap"></i> Morph Into Student</h2></a>
    </div>
  </div>

  </nav>

  <%== $lasttweet %>

</main>

<% sub btnstring {
  my $btnptr= shift;
  my $btnstring="";
  if (defined($btnptr)) {
    $btnstring= '<div class="row top-buffer text-center">';
    my $numbuttons= scalar @{$btnptr};
    foreach (@$btnptr) { $btnstring .= btnblock($_->[0], $_->[1], $_->[2]); }
    $btnstring .= "</div>\n";
  }
  return $btnstring;
} %>
