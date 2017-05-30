#!/usr/bin/env perl
use Test::Mojo;

use Test2::Bundle::Extended;
use Test2::Plugin::DieOnFail;

use Data::Dumper;

use feature ':5.20';
use feature 'signatures';
no warnings qw(experimental::signatures);


my $t = Test::Mojo->new;
$t->ua->max_redirects(100);

my $identity= 'no email yet';
my $course= 'auth';

x2('/auth/test', 'short-circuit identity');

x3('corpfin.test', '/enter', 'ivo.welch@gmail.com', 500);  ## fails here, we are not yet known

$identity='ivo.welch@gmail.com';
x2('/login?email=ivo.welch@gmail.com', 'choose course');

$course='corpfin.test';
x2('/enter', 'instructor');

done_testing();






################################################################################################################################
sub x3($course, $url, $resulthead, $statuswanted=200) {
  note '---';
  $url="http://$course.syllabus.test/$url";
  $url =~ s{//}{/}g; $url =~ s{http:/}{http://};
  if ($statuswanted == 200) {
    my $x=$t->get_ok($url)->status_is($statuswanted)->text_like('html head title' => qr{$resulthead}, "$course $url $resulthead");
    if (defined($identity)) {
      return $x->content_like(qr{syllabus.test: $identity}, "user $identity confirmed");
    }
  } else {
    return $t->get_ok($url)->status_is($statuswanted);
  }
}

sub x2($url, $resulthead, $statuswanted=200) {
  (defined($course)) or die "please define your course first";
  return x3($course, $url, $resulthead, $statuswanted);
}

