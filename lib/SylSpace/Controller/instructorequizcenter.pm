#!/usr/bin/env perl
package SylSpace::Controller::instructorequizcenter;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use feature ':5.20';
use feature 'signatures';
no warnings qw(experimental::signatures);

use SylSpace::Model::Model qw(ifilelistall sudo tzi);
use SylSpace::Model::Controller qw(global_redirect  standard);


################################################################


get '/instructor/equizcenter' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  sudo( $subdomain, $c->session->{uemail} );

  $c->stash(
	    filelist => ifilelistall($subdomain, $c->session->{uemail}, "*equiz"),
	    subdomain => $subdomain,
	    tzi => tzi( $c->session->{uemail} ) );
};

1;


################################################################

__DATA__

@@ instructorequizcenter.html.ep

%title 'equiz center';
%layout 'instructor';

<main>

  <% use SylSpace::Model::Controller qw( ifilehash2table fileuploadform); %>

  <%== ifilehash2table($filelist, [ 'equizrun', 'view', 'download', 'edit' ], 'equiz', $tzi) %>

  <%== fileuploadform() %>

<hr />

  <h3 style="margin-top:2em"> Equiz Basics </h3>

   <h4>Load Existing Templates</h4>

<div class="form-group" id="narrow">
<div class="row" style="text-align:center;color:black">
  <div class="col-xs-2"> <a href="/instructor/cptemplate?templatename=starters" class="btn btn-default btn-block">starters</a></div>
  <div class="col-xs-2 col-md-offset-0"> <a href="/instructor/cptemplate?templatename=tutorials" class="btn btn-default btn-block">tutorials</a></div>
  <div class="col-xs-2 col-md-offset-0">
  <%== ($subdomain !~ /fin/) ? '' :
    ($subdomain =~ /test/) ? '<a href="" class="btn btn-disabled btn-block">corpfinintro disabled</a>' :
                             '<a href="/instructor/cptemplate?templatename=corpfinintro" class="btn btn-default btn-block">corpfinintro</a>' %>
</div>
</div> <!--row-->
</div> <!--formgroup-->

<div class="form-group" id="narrow">
<div class="row" style="text-align:center;color:black">
<div class="col-xs-6"><a href="/instructor/rmtemplates" class="btn btn-default btn-block">remove all unchanged unpublished template files</a></div></div> <!--row-->
</div> <!--formgroup-->



  <h4> Designing Your Own </h4>

<div class="form-group" id="narrow">
  <div class="row" style="color:black">
    <div class="col-xs-offset-1 col-xs-4"> <a href="/testquestion" class="btn btn-default">quick test any question</a></div>
  </div> <!--row-->
</div> <!--formgroup-->

  <p> To learn more about equizzes, please read the <a href="/staticintro.html"> intro </a>, and copy the set of sample templates into your directory for experimentation and examples.  </p>


</main>

