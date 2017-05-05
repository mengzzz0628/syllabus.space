#!/usr/bin/env perl
package SylSpace::Controller::studenthwcenter;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sfilelistall userisenrolled sownfilelist);
use SylSpace::Model::Controller qw(global_redirect  standard domain);

################################################################

get '/student/hwcenter' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  (userisenrolled($subdomain, $c->session->{uemail})) or $c->flash( message => "first enroll in $subdomain please" )->redirect_to('/auth/goclass');

  $c->stash( filelist => sfilelistall($subdomain, $c->session->{uemail}, "hw*"),
	     sownfilelist => sownfilelist( $subdomain, $c->session->{uemail} )
	   );
};

1;


################################################################

__DATA__

@@ studenthwcenter.html.ep

%title 'homework center';
%layout 'student';

<main>

<%
  use SylSpace::Model::Controller qw(timedelta btn);

sub filehash2string {
  my $filehashptr= shift;
  defined($filehashptr) or return "";
  my $sownfilelist= shift;

  my %sownfilelist;
  foreach (@$sownfilelist) {
    /^(.*)\.response\.(.*)$/ or next;
    (/\.old$/) and next;
    $sownfilelist{ $1 } = "<a href=\"/student/viewown?f=$_\">$2</a>";
  }

  my $counter=0;
  my $filestring= '';
  foreach (@$filehashptr) {
    my $duetime= $_->[1];  my $fname= $_->[0];
    ($duetime<time()) and next;
    ++$counter;
    my $duein= timedelta($duetime , time());
    my $pencil= '<i class="fa fa-pencil"></i>';

    my $uploadform=
      qq(<form action="/upload" id="uploadform" method="post" enctype="multipart/form-data" style="display:block">
          <label for="idupload">Upload: </label>
          <input type="file" name="uploadfile" id="idupload" style="display:inline"  >
          <input type="hidden" name="hwtask" value="$_->[0]"  ><br />
          <button class="btn btn-default btn-block" type="submit" value="submit">Go</button>
      </form>);

    $filestring .= "<tr>"
      . "<td> ". btn("/student/view?f=$fname", "$pencil $fname") . "</td>"
      . "<td style=\"text-align:left\"> due $duein (<span class=\"epoch\">$duetime</span>)<br />due GMT ". localtime($_->[1])."<br />now GMT ".localtime()."</td>"
      . "<td> $uploadform </td>"
      . '<td> '.$sownfilelist{$fname}.' </td>' ."</tr>";
  }
  ($counter) or return "<tr colspan=\"3\"><td>$counter publicly posted homeworks at the moment</td> </tr>";

  return $filestring;
}
%>

  <h2> Upload Your Answers </h2>

   <div class="row top-buffer text-center">
    <table class="table" style="width: auto !important">
      <thead>  <tr> <th> Assignment </th> <th>Due</th> <th> Upload </th> <th> Uploaded </th> </tr> </thead>

      <tbody>
          <%== filehash2string( $filelist, $sownfilelist ) %>
      </tbody>

     </table>
  </div>

  <p>Any answer that you want to upload must begin with the homework file name, too.  For example, if the homework is named 'hwa1.txt', name your answer file something like 'hwa1-answer.pdf' (no spaces or weird characters, please).  The filename congruance is a security check for your own sake.</p>
</main>
