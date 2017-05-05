#!/usr/bin/env perl
use Mojolicious::Lite;

#my $cookiedomain;
#my $cookiedomain= "localhost";

my $cookiedomain= "syllabus.space";
my $bigdomain= $cookiedomain;

get '/' => sub {
  my $c= shift;
  ## ($cookiedomain) and $c->app->sessions->cookie_domain($cookiedomain);
  my $fulldomain= $c->req->url->to_abs->host;

  my $incookie=$c->session->{nicecookie} || "NO INCOOKIE DEFINED";
  $c->session->{nicecookie}= time()." at ".$fulldomain;
  my $outcookie= $c->session->{nicecookie};

  my $texts= qq(
        <h1> cookie tester, myappreal </h1>
	<p>our incookie was '$incookie'</p>
	<p>our outcookie is '$outcookie'</p>
        <hr />
	<p>you are currently in domain '$fulldomain'</p>
        <hr />
	<p>main domain <a href='http://$bigdomain:3000/'>go to /</a></p>
	<p>subdomain <a href='http://s1.$bigdomain:3000/'>go to /s1</a></p>
	<p>subdomain <a href='http://s2.$bigdomain:3000/'>go to /s2</a></p>
	<hr />
	<p>the cookiedomain is $cookiedomain.</p>
 );

  $c->render(text => $texts);
};

($cookiedomain) and app->sessions->cookie_domain($cookiedomain);

app->start;
