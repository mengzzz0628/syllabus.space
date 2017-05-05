#!/usr/bin/env perl
package SylSpace::Controller::aboutus;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/aboutus' => sub {
  my $c = shift;
  (my $subdomain = standard( $c )) or return global_redirect($c);

  ## sudo( $subdomain, $c->session->{uemail} );

  $c->stash( );
};

1;

################################################################

__DATA__

@@ aboutus.html.ep

%title 'about us';
%layout 'both';

<main>

<h2>Basics</h2>

  <p>syllabus.space is free course administration and equizzing software, written in <a href="http://mojolicious.org/">Mojolicious</a> (perl) and <a href="http://getbootstrap.com">Bootstrap</a> (with <a href="http://fontawesome.io/">fontawesome icons</a>) in early 2017 by Ivo Welch (<a href="ivo.welch@gmail.com">ivo.welch@gmail.com</a>).</p>

  <p>For basic help, please visit the <a href="/faq">FAQ</a>.</p>

<h2>License</h2>

  <p>The syllabus.space software is free under the <a href="https://choosealicense.com/licenses/agpl-3.0/">GNU AGPLv3</a> license.</p>

<h2>Legal</h2>

  <p>NO REPRESENTATIONS OR WARRANTIES, EITHER EXPRESS OR IMPLIED, OF MERCHANTABILITY, FITNESS FOR A SPECIFIC PURPOSE, THE PRODUCTS TO WHICH THE INFORMATION MENTIONS MAY BE USED WITHOUT INFRINGING THE INTELLECTUAL PROPERTY RIGHTS OF OTHERS, OR OF ANY OTHER NATURE ARE MADE WITH RESPECT TO INFORMATION OR THE PRODUCT TO WHICH INFORMATION MENTIONS. IN NO CASE SHALL THE INFORMATION BE CONSIDERED A PART OF OUR TERMS AND CONDITIONS OF SALE.</p>


</main>

