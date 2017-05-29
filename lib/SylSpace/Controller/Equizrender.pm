#!/usr/bin/env perl
package SylSpace::Controller::Equizrender;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(equizrender isenrolled);
use SylSpace::Model::Controller qw(standard global_redirect);

################################################################

my $equizrender= sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  (isenrolled($course, $c->session->{uemail})) or $c->flash( message => "first enroll in $course please" )->redirect_to('/auth/goclass');

  # students can run this, too.  sudo( $course, $c->session->{uemail} );

  ## we allow students to run expired equizzes (if they know the names);  feature or bug

  my $quizname=$c->req->query_params->param('f');
  my $cururl=$c->req->url->to_abs;
  my $returnurl= 'http://'.$cururl->subdomain.'.'.$cururl->domainport.'/equizgrade';

  $c->stash( content => equizrender( $course, $c->session->{uemail}, $quizname, $returnurl ),
	     quizname => $quizname,
	     template => 'equizrender' );
};

get '/equizrender' => $equizrender;

1;

################################################################

__DATA__

@@ equizrender.html.ep

%title 'take an equiz';
%layout 'both';

  <script type="text/javascript" async src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-MML-AM_CHTML"> </script>
  <script type="text/javascript"       src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS_HTML-full"></script>
  <script type="text/javascript" src="/js/eqbackend.js"></script>
  <link href="/css/eqbackend.css" media="screen" rel="stylesheet" type="text/css" />
  <link href="/css/input.css" media="screen" rel="stylesheet" type="text/css" />

<main>

 Quiz: <%= $quizname %>

<%== $content %>

</main>

