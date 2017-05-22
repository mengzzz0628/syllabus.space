#!/usr/bin/perl -w
use strict;
use warnings FATAL => qw{ uninitialized };
use autodie;

use CGI qw(:standard);
use CGI::Carp qw ( fatalsToBrowser );

my $query = CGI->new( );

print $query->header ( );

$query->param("_timestamp", scalar localtime);  ## add more local information here
$query->param("REMOTE_HOST", $ENV{REMOTE_HOST});  ## save our entire environment, too;
$query->param("REMOTE_ADDRESS", $ENV{REMOTE_ADDR});  ## save our entire environment, too;

print start_html("Echo All Page");

print h1("Method 1: Iterate over the ENV");

foreach my $key (sort(keys(%ENV))) {
    print "$key = $ENV{$key}<br />\n";
}


print h1("Method 2: Handle query");

my $allinfo = "";
foreach my $k ($query->param()) {
  $allinfo .= " ($k = '".$query->param($k)."')<br />\n";
}

print <<END_HTML;

<hr />

<h2>All Info</h2>

$allinfo

</body>

</html>
END_HTML
