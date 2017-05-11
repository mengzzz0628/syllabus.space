#!/usr/bin/env perl
package SylSpace::Controller::instructorcsettings;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(readschema sudo cioread cbuttons);
use SylSpace::Model::Controller qw(global_redirect  standard drawform);

################################################################

get '/instructor/csettings' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  sudo( $subdomain, $c->session->{uemail} );

  $c->stash( udrawform=> drawform( readschema('c'), cioread($subdomain) ), udrawbuttons => cbuttons($subdomain) );
};


1;

################################################################

__DATA__

@@ instructorcsettings.html.ep

%title 'course settings';
%layout 'instructor';

<main>

  <h1>Course Settings</h1>

  <form class="form-horizontal" method="POST" action="/instructor/csave">

    <%== $udrawform %>

    <div class="form-group">
         <button class="btn btn-default btn-lg" type="submit" value="submit">Submit These Course Settings</button>
    </div>

  </form>

  <p> <b>*</b> means required (red if not yet provided).</p>


  <hr />


  <h1>Additional GUI Buttons for Student Shortcuts</h1>

  <form class="form-horizontal" method="GET" action="/instructor/csavebuttons">


  <%
  sub makebuttontable {
    my $rs="";
    my $count=0;
    if (defined($_[0])) {
      foreach(@{$_[0]}) {
	$rs.= "<tr> ".
	  "<td> <input class=\"urlin\" id=\"url$count\" name=\"url$count\" value=\"$_->[0]\" readonly size=\"64\" maxsize=\"128\" /> </td>".
	  "<td> <input class=\"titlein\" id=\"titlein$count\" name=\"titlein$count\" value=\"$_->[1]\" size=\"12\" maxsize=\"12\" /></td>".
	  "<td> <input class=\"textin\" id=\"textin$count\" name=\"textin$count\" value=\"$_->[2]\" size=\"48\" maxsize=\"48\" /></td>".
	  "</tr>";
	++$count;
      }
    }

    $rs.= "<tr> ".
      "<td> <input class=\"urlin\" id=\"url$count\" name=\"url$count\" placeholder=\"e.g., http://google.com\" size=\"64\" maxsize=\"128\" /> </td>".
      "<td> <input class=\"titlein\" id=\"titlein$count\" name=\"titlein$count\" placeholder=\"e.g., google\" size=\"12\" maxsize=\"12\" /></td>".
      "<td> <input class=\"textin\" id=\"textin$count\" name=\"textin$count\" placeholder=\"e.g., learn more\" size=\"48\" maxsize=\"48\" /></td>".
      "</tr>";
    return $rs;
  }
  %>


    <table class="table">
      <tr> <th> URL </th> <th> Title </th> <th> More Explanation </th> </tr>
      <%== makebuttontable( $udrawbuttons ) %>
    </table>

     <div class="form-group">
        <button class="btn btn-default btn-lg" type="submit" value="submit">Submit Buttons</button>
     </div>

  </form>


</main>
