#!/usr/bin/env perl
package SylSpace::Controller::Testquestion;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/testquestion' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  my $starter = '
:N: Starter Question

:I: $x= rseq(1,10); $y= pr(10,20,30);  $underroot= ($x^2+$y^2); $ANS=sqrt($underroot)

:Q: Please calculate
  \[ \sqrt{$x^2+$y^2} \]
      Illegal Hint: it will turn out to be $ANS.

:A: The question requested
  \[ \sqrt{$x^2+$y^2} \]
  The expression under the root was $underroot.

:T: 2

:P: 2

:E:
';

  my $ecode= ($c->req->query_params->param('ecode')) || $starter;

  foreach (qw(I N Q A E)) {
    if ($ecode !~ /^:$_:/m) {
      $ecode =~ s/\n/\n\|/g;
      die "(you may have to remove all spaces before :T: tags); your question lacks a :$_: as the first character on a line:\n\n$ecode";
    }
  }

  ## sudo( $subdomain, $c->session->{uemail} );

  my $executable= sub {
    my $loc=`pwd`; chomp($loc); $loc.= "/Model/eqbackend/eqbackend.pl";
    return $loc;
  } ->();

  ## my $quizretcode= system($executable); # `perl $executable < $filecontent`;
  use File::Temp qw/ tempfile /;
  my ($FOUT, $FNAME) = tempfile(); print $FOUT $ecode; close($FOUT);

  _confirmnotdangerous( $FNAME, "quizname FNAME" );

  my $eresult= `$executable solo < $FNAME`;

  $c->stash( template => 'testquestion', ecode => $ecode, eresult => $eresult);
};

sub _confirmnotdangerous {
  my ( $string, $warning )= @_;
  ($string =~ /\;\&\|\>\<\?\`\$\(\)\{\}\[\]\!\#\'/) and die "too dangerous: $warning fails!";  ## we allow '*'
  return $string;
}

1;

################################################################

__DATA__

@@ testquestion.html.ep

%title 'test your equiz question';
%layout 'instructor';

  <script type="text/javascript" async src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-MML-AM_CHTML"> </script>
  <script type="text/javascript"       src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS_HTML-full"></script>
  <script type="text/javascript" src="/js/eqbackend.js"></script>
  <link href="/css/eqbackend.css" media="screen" rel="stylesheet" type="text/css" />
  <link href="/css/input.css" media="screen" rel="stylesheet" type="text/css" />

  <style>
    div.unhide { color: blue;  border: 1px solid red; }
    span.unhidename { color: black; padding-bottom:1em; }
    span.unhidevalue { padding-top:1em; }
  </style>

<main>

<form method="GET" action="/testquestion" />
  <button class="btn btn-default" type="submit" value="submit">Completely Start Over</button>
</form>


<h1>Test Question</h1>

<form method="GET" action="/testquestion" />

  <b>bug: why is the textarea not auto-growth, as tried in eqbackend.css</b><br />

  <!-- script $('#ecode').css('overflow', 'hidden').autogrow() /script -->

  <script>
    $("textarea").keyup(function(e) {
       while($(this).outerHeight() < this.scrollHeight + parseFloat($(this).css("borderTopWidth")) + parseFloat($(this).css("borderBottomWidth"))) {
          $(this).height($(this).height()+1);
       };
   });
 </script>

  <textarea name="ecode" rows="15" id="ecode" cols="60"><%= $ecode %></textarea>

<br />
  <button class="btn btn-default" type="submit" value="submit">Test Now</button>
</form>

<h1>Evaluated</h1>

<%== $eresult %>

<p> You can bookmark this page to save your question and the answer.</p>

</main>

