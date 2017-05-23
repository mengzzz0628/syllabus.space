#!/usr/bin/perl -w

use strict;
use common::sense;
use utf8;
use warnings FATAL => qw{ uninitialized };
use autodie;

use feature ':5.20';
use feature 'signatures';
no warnings qw(experimental::signatures);

################################################################
## not used, but we want to make sure that these modules are installed.
use common::sense;
use File::Path;
use File::Touch;
use File::Copy;
use Email::Valid;
use Perl6::Slurp;
use Archive::Zip;
use FindBin;
use Mojolicious::Plugin::RenderFile;
use Data::Dumper;
sub arrlen { (ref ($_[0]) eq 'ARRAY') and return scalar @{$_[0]}; return scalar @_; }

use lib '../..';
use SylSpace::Model::Model qw(:DEFAULT _websitemake _webcourseremove biosave usernew userenroll courselistenrolled ciosave msgsave filewrite filesetdue gradetaskadd gradesave ciobuttonsave cptemplate sudo);

use Test2::Bundle::Extended;
use Test2::Plugin::DieOnFail;

my $v= _webcourseremove("*");  ## but not users and templates


my %bioinstructor = ( uniname => 'ucla anderson', regid => 'na', firstname => 'ivo', lastname => 'welch', birthyear => 1971,
		      email => 'ivo.welch@gmail.com', zip => 90095, country => 'US', cellphone => '(310) 555-1212',
		      email2 => 'ivo.welch@anderson.ucla.edu', tzi => tziserver(), optional => '' );

my %biokingsfield = ( uniname => 'harvard law', regid => 'na', firstname => 'charles', lastname => 'kingsfield', birthyear => 1971,
		      email2 => 'charles.kingsfield@anderson.ucla.edu', zip => 90095, country => 'US', cellphone => '(310) 555-1212',
		      email => 'instructor@gmail.com', tzi => tziserver(), optional => '' );

my $iemail= $bioinstructor{email};

note '
################ website creation, user registration, and user enrollment

';

my @courselist=qw(corpfin.test);

foreach (@courselist) {  ok( _websitemake($_, $iemail), "created $_ site" ); }

ok( scalar @{courselistenrolled($iemail)} == scalar @courselist, "need enrollment info on $#courselist+1 existing courses: ".scalar @{courselistenrolled($iemail)}. " vs ".scalar @courselist);

note '
################ auth: user bios
';

ok( biosave( $iemail, \%bioinstructor), 'written biodata for instructor '.$iemail );

ok( usernew('student@gmail.com'), 'new student' );

my %biostudent = ( uniname => 'harvard law', regid => 'na', firstname => 'james', lastname => 'hart', birthyear => 1971,
		   email2 => 'james.hart@gmail.com', zip => 90049, country => 'US', cellphone => '(312) 555-1212',
		   email => 'student@gmail.com', tzi => tziserver(), optional => '' );

ok( biosave('student@gmail.com', \%biostudent), 'written biodata for student' );

ok( userenroll($courselist[0], 'student@gmail.com'), 'enrolled student' );

note '
################ course validity testing and modification
';

my %ciosample = ( uniname => 'harvard law', unicode => 'law101', coursesecret => '', cemail => 'the.paper.chase@gmail.com',
		  anothersite => 'http://ivo-welch.info',
		  department => 'law', subject => 'contract law', meetroom => 'Austin-Hall', meettime => 'TR 9:00-5:00',
		  domainlimit => '', hellomsg => 'watch the movie' );

sudo($courselist[0], $iemail);  ## become the instructor
ok( ciosave($courselist[0], \%ciosample), 'instructor writes sample cio sample' );

## buttons

my @buttonlist;
push(@buttonlist, ['http://ivo-welch.info', 'welch', 'go back to root']);
push(@buttonlist, ['http://book.ivo-welch.info', 'book', 'read book']);
push(@buttonlist, ['http://gmail.com', 'gmail', 'send email']);

ciobuttonsave( $courselist[0], \@buttonlist );

note '
################ messaging system
';

ok( msgsave($courselist[0], { subject => 'Test Welcome', body => 'Welcome to the testing site.  Note that everything is public and nothing stays permanent here.  I often replace the testsite with a similar new one.', priority => 5 }, 1233), 'posting 1233' );

note '
################ file storage and retrieval system
';

ok( filewrite($courselist[0], $iemail, 'hw1.txt', "please do this first homework\n"), 'writing hw1.txt');
ok( filewrite($courselist[0], $iemail, 'syllabus.txt', "<h2>please read this syllabus</h2>\n"), 'writing syllabus.txt' );
my $e2n= "02a-welch-tvm.equiz"; ok( -e $e2n, "have test for 2medium.equiz for use in Model subdir" );
ok( filewrite($courselist[0], $iemail, $e2n, scalar slurp($e2n)), "writing $e2n" );

ok( cptemplate($courselist[0], 'starters'), "cannot copy starters template" );
ok( cptemplate($courselist[0], 'tutorials'), "cannot copy tutorials template" );
## ok( cptemplate($courselist[0], 'corpfin'), "cannot copy corpfin template" );

####
ok( filesetdue($courselist[0], 'hw1.txt', time()+60*60*24*14), "set hw1.txt open for 2 weeks");
ok( filesetdue($courselist[0], $e2n, time()+60*60*24*14), "set e2n open for 4 weeks");

note '
################ grade center
';

ok( gradetaskadd($courselist[0], qw(hw1 hw2 midterm)), "hw1, hw2 midterm all allowed now" );

ok( gradesave($courselist[0], 'student@gmail.com', 'midterm', 'badfail' ), "grade midterm for student");

note '
################ backup
';

done_testing();

sub tziserver {
  my $off_h=1;
  my @local=(localtime(time+$off_h*60*60));
  my @gmt=(gmtime(time+$off_h*60*60));
  return (-1)*($gmt[2]-$local[2] + ($gmt[5] <=> $local[5]
			      ||
			      $gmt[7] <=> $local[7])*24);
}
