#!/usr/bin/env perl
use strict;
use common::sense;
use utf8;
use feature ':5.20';
use warnings;
use warnings FATAL => qw{ uninitialized };
use autodie;

foreach my $url (@ARGV) {

  ($url =~ m{/}) or die "you almost surely want a / in your url";
  $url =~ s/\.p[ml]$//;

  (my $fname= $url) =~ s{\/}{}g;
  my $fnamepm = "$fname.pm";
  my $layout= ($fname =~ /instructor/) ? 'instructor' : ($fname =~ /instructor/) ? 'student' : 'guest';

  open(my $FOUT, ">", $fnamepm);

  print $FOUT <<EOM;
#!/usr/bin/env perl
package SylSpace::Controller::$fname;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo);
use SylSpace::Model::Utils qw(global_redirect standard);

################################################################

get '$url' => sub {
  my \$c = shift;
  (my \$subdomain = standard( \$c )) or return global_redirect(\$c);

  ## sudo( \$subdomain, \$c->session->{uemail} );

  \$c->stash( );
};

1;

################################################################

__DATA__

@@ $fname.html.ep

%title '$url';
%layout '$layout';

<main>

<h1>Not Yet</h1>

</main>

EOM
  print "written $fnamepm\n";
}
