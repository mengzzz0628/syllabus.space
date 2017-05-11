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
use SylSpace::Model::Model qw(:DEFAULT _websitemake _websiteshow _webcourseremove _checkvalidagainstschema biowrite usernew bioread userenroll courselistenrolled courselistnotenrolled ciowrite cioread cbuttons msgpost msgmarkread _msglistnotread msgdelete msgread msgreadnotread filewrite filesetdue _suundo websitebackup gradetaskadd gradeenter _storegradeequiz gradesashash userisenrolled ifilelistall sfilelistall filestudentcollect sfileread sownfileread sownfilelist csetbuttons isinstructor cptemplate);

use Test2::Bundle::Extended;
use Test2::Plugin::DieOnFail;

my $v= _webcourseremove("*");  ## but not users and templates

note '
################ website creation, user registration, and user enrollment
';
my @c=qw (corpfin.test);

like(dies { _websitemake($c[0], 'ivo.welch-not-possible-gmail.com') }, qr/email /, 'good fail on bad i email' );

foreach (@c) {  ok( _websitemake($_, 'instructor@gmail.com'), "created $_ site" ); }

ok( scalar @{courselistenrolled('instructor@gmail.com')} == scalar @c, "need enrollment info on $#c+1 existing courses: ".scalar @{courselistenrolled('instructor@gmail.com')}. " vs ".scalar @c);

note '
################ auth: user bios
';

my %bioinstructor = ( uniname => 'harvard law', regid => 'na', firstname => 'charles', lastname => 'kingsfield', birthyear => 1971,
		      email2 => 'charles.kingsfield@anderson.ucla.edu', zip => 90095, country => 'US', cellphone => '(310) 555-1212',
		      email => 'instructor@gmail.com', tzi => tziserver(), optional => '' );

ok( biowrite('instructor@gmail.com', \%bioinstructor), 'written biodata for instructor' );

ok( usernew('student@gmail.com'), 'new student' );

my %biostudent = ( uniname => 'harvard law', regid => 'na', firstname => 'james', lastname => 'hart', birthyear => 1971,
		   email2 => 'james.hart@gmail.com', zip => 90049, country => 'US', cellphone => '(312) 555-1212',
		   email => 'student@gmail.com', tzi => tziserver(), optional => '' );
ok( biowrite('student@gmail.com', \%biostudent), 'written biodata for student' );

ok( userenroll($c[0], 'student@gmail.com'), 'enrolled student' );

note '
################ course validity testing and modification
';

my %ciosample = ( uniname => 'harvard law', unicode => 'law101', coursesecret => '', cemail => 'the.paper.chase@gmail.com',
		  anothersite => 'http://ivo-welch.info',
		  department => 'law', subject => 'contract law', meetroom => 'Austin-Hall', meettime => 'TR 9:00-5:00',
		  domainlimit => '', hellomsg => 'watch the movie' );

sudo($c[0], 'instructor@gmail.com');  ## become the instructor
ok( ciowrite($c[0], \%ciosample), 'instructor writes sample cio sample' );

## buttons

my @buttonlist;
push(@buttonlist, ['http://ivo-welch.info', 'welch', 'go back to root']);
push(@buttonlist, ['http://book.ivo-welch.info', 'book', 'read book']);
push(@buttonlist, ['http://gmail.com', 'gmail', 'send email']);

csetbuttons( $c[0], \@buttonlist );

note '
################ messaging system
';

ok( msgpost($c[0], { subject => 'Test Welcome', body => 'Welcome to the testing site.  Note that everything is public and nothing stays permanent here.  I often replace the testsite with a similar new one.', priority => 5 }, 1233), 'posting 1233' );

note '
################ file storage and retrieval system
';

ok( filewrite($c[0], 'instructor@gmail.com', 'hw1.txt', "please do this first homework\n"), 'writing hw1.txt');
ok( filewrite($c[0], 'instructor@gmail.com', 'syllabus.txt', "<h2>please read this syllabus</h2>\n"), 'writing syllabus.txt' );
my $e2n= "02a-welch-tvm.equiz"; ok( -e $e2n, "have test for 2medium.equiz for use in Model subdir" );
ok( filewrite($c[0], 'instructor@gmail.com', $e2n, scalar slurp($e2n)), "writing $e2n" );

ok( cptemplate($c[0], 'starters'), "cannot copy starters template" );
ok( cptemplate($c[0], 'tutorials'), "cannot copy tutorials template" );

####
ok( filesetdue($c[0], 'hw1.txt', time()+60*60*24*14), "set hw1.txt open for 2 weeks");
ok( filesetdue($c[0], $e2n, time()+60*60*24*14), "set e2n open for 4 weeks");

note '
################ grade center
';

ok( gradetaskadd($c[0], qw(hw1 hw2 midterm)), "hw1, hw2 midterm all allowed now" );

ok( gradeenter($c[0], 'student@gmail.com', 'midterm', 'badfail' ), "grade midterm for student");

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
