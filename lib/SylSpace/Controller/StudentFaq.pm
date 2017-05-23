#!/usr/bin/env perl
package SylSpace::Controller::StudentFaq;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(fileread);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/student/faq' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  my $isfaq= fileread( $subdomain, $c->session->{uemail}, 'faq' ) || "<p>the instructor has not added her own faq</p>\n" ;



  use Perl6::Slurp;
  my $body= slurp("public/html/faq.html");
  my $code= (length($body)<=1) ? 404 : 200;

#  my $allfaq = $c->ua->get("/html/faq.html");
#  my $code= $allfaq->res->{code};
#  my $body= $allfaq->res->{content}->{asset}->{content};
#
#  if ($code == 404) {
#    $allfaq= "<p>There is no sitewide public /html/faq.html.</p>\n";
#  } else {
#    $body =~ s{.*(<body.*)}{$1}ms;
#    $body =~ s{(.*)</body>.*}{$1}ms;
#  }

## use Mojolicious::Plugin::ContentManagement::Type::Markdown;
## ($allfaq) or $allfaq = $markdown->translate(slurp("/faq.md"));

  $c->stash( allfaq => $body, isfaq => $isfaq, template => 'faq' );
};

1;

################################################################

__DATA__

@@ faq.html.ep

%title 'Student FAQ';
%layout 'student';

<main>

<dl class="dl faq">

  <dt>What is <i>not</i> intuitive using syllabus.space?  Have an idea to make it easier and better?  Found a dead link?</dt>

  <dd>Please <a href="mailto:ivo.welch@gmail.com?subject=unclear-syllabus-space">let me know</a>.  I cannot guarantee that I will follow your recommendation(s), but I will consider it.</dd>

  <dt>Why won't my file upload?</dt>

  <dd>The maximum uupload limit is 16MB/file.</dd>

</dl>

<hr />

<h3> Site FAQ </h3>

  <%== $allfaq %>

<hr />

<h3> Instructor-added Student FAQ </h3>

  <%== $isfaq %>

</main>

