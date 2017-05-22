#!/usr/bin/env perl
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
use SylSpace::Model::Model qw(:DEFAULT _websitemake _websiteshow _webcourseremove _checkvalidagainstschema biosave usernew bioread userenroll courselistenrolled ciosave cioread ciobuttons msgsave msgmarkasread _msglistnotread msgdelete msgread msgshownotread filewrite filesetdue _suundo sitebackup gradetaskadd gradesave gradesashash isenrolled ifilelistall sfilelistall collectstudentanswers sfileread sownfileread sownfilelist ciobuttonsave isinstructor sudo);

use Test2::Bundle::Extended;
use Test2::Plugin::DieOnFail;

my $v= _webcourseremove("*");  ## but not users and templates

note '
################ website creation, user registration, and user enrollment
';
my @c=qw (mfe.welch mba.welch mba.daniel 2017.mba430.schwartz.ucla);

like(dies { _websitemake($c[0], 'alice.welch-not-possible-gmail.com') }, qr/email /, 'good fail on bad i email' );

foreach (@c) {  ok( _websitemake($_, 'alice.welch@gmail.com'), "created $_ site" ); }
ok( !eval { _websitemake($c[0], 'alice.welch@gmail.com') }, 'cannot create mfe a second time' );

ok( scalar @{courselistenrolled('alice.welch@gmail.com')} == scalar @c, "need enrollment info on $#c+1 existing courses");
ok( isenrolled($c[0], 'alice.welch@gmail.com'), "alice.welch\@gmail.com is nicely enrolled in $c[0]");
ok( !isenrolled($c[0], 'alice@gmail.com'), "alice is not enrolled in $c[0]");

note '
################ auth: user bios
';

my %bioalice = ( uniname => 'ucla', regid => 'na', firstname => 'alice', lastname => 'welch', birthyear => 1963,
	       email2 => 'alice.welch@anderson.ucla.edu', zip => 90095, country => 'US', cellphone => '(312) 212-3100',
	       email => 'alice.welch@gmail.com', tzi => tziserver(), optional => '' );
ok( biosave('alice.welch@gmail.com', \%bioalice), 'written biodata for alice' );

ok( usernew('bob@gmail.com'), 'new bob' );
my %biobob = ( uniname => 'na', regid => 'na', firstname => 'bob', lastname => 'qiu', birthyear => 1975,
		email2 => 'bob@gmail.com', zip => 90049, country => 'US', cellphone => '(312) 212-3200',
		email => 'bob@gmail.com', tzi => tziserver(), optional => '' );
ok( biosave('bob@gmail.com', \%biobob), 'written biodata for bob' );


ok( usernew('charlie@gmail.com'), 'new charlie' );
my %biocharlie = ( uniname => 'ucla', regid => 'na', firstname => 'charlie', lastname => 'welch', birthyear => 2005,
		  email => 'charlie@gmail.com', zip => 90049, country => 'US', cellphone => '(312) 212-3300',
		  email2 => 'gdtwentyseven@gmail.com', tzi => tziserver(), optional => '' );

ok( usernew('noone@gmail.com'), 'new noone user' );


#my $s= Dumper testmodhash(\%biocharlie, 'uniname', '');

sub testmodhash { my ( $h, $k, $v )=@_; my %nh= %$h; $nh{$k}=$v; return \%nh; }

like(dies { biosave('charlie@gmail.com', testmodhash(\%biocharlie, 'uniname', '')) }, qr/required/, 'fail on bad field content for uniname' );
like(dies { biosave('charlie@gmail.com', testmodhash(\%biocharlie, 'uniname', '&^SD')) }, qr/regex/, 'fail on regex for uniname' );
like(dies { biosave('charlie@gmail.com', testmodhash(\%biocharlie, 'uniname', 'ucla' x 50)) }, qr/long/, 'fail on length' );

like(dies { biosave('charlie@gmail.com', testmodhash(\%biocharlie, 'notvalid', 'any')) }, qr/allowed/, 'fail on field that should not be here' );
#delete $biosampledata{'notvalid'};

ok( biosave('charlie@gmail.com', \%biocharlie), 'written biodata for charlie' );

ok(dies { usernew('../..@gmail.com') }, 'bad email new user' );

ok( my $ibio=bioread('alice.welch@gmail.com'), 'reread biodata for alice' );
ok( biosave('alice.welch@gmail.com', $ibio), 'rewrote it' );

note '
################ enroll users in course
';

ok( isinstructor($c[0],'alice.welch@gmail.com'), 'alice.welch\@ is an instructor for mfe' );
ok( userenroll($c[0], 'bob@gmail.com'), 'enrolled bob' );
ok( userenroll($c[0], 'charlie@gmail.com'), 'enrolled charlie' );
like(dies { userenroll($c[0], 'noone22@gmail.com') }, qr/no such user/, 'cannot enroll non-existing user nooone' );


note '
################ course validity testing and modification
';

my %ciosample = ( uniname => 'ucla', unicode => 'mfe237', coursesecret => 'judy', cemail => 'mfe@gmail.com', anothersite => 'http://ivo-welch.info',
		  department => 'fin', subject => 'advanced corpfin', meetroom => 'B301', meettime => 'TR 2:00-3:30pm',
		  domainlimit => 'ucla.edu', hellomsg => 'hi friends' );

like(dies { ciosave($c[0], \%ciosample) }, qr/insufficient privileges/, 'student cannot write class info' );

sudo($c[0], 'alice.welch@gmail.com');  ## become the instructor

my $w= testmodhash(\%ciosample, 'coursesecret', '&^SD');

like(dies { ciosave($c[0], testmodhash(\%ciosample, 'coursesecret', '&^SD')) }, qr/regex/, 'fail on regex for coursesecret' );

ok( ciosave($c[0], \%ciosample), 'instructor writes sample cio sample' );
ok( my $icio=cioread($c[0]), 'reread cio' );
ok( _checkvalidagainstschema( $icio, 'c' ), 'is the reread ciodata still valid?' );

## buttons

my @buttonlist;
push(@buttonlist, ['http://ivo-welch.info', 'iaw-web', 'go back to root']);
push(@buttonlist, ['http://gmail.com', 'gmail', 'send email']);
push(@buttonlist, ['http://book.ivo-welch.info', 'book', 'read book']);

ciobuttonsave( $c[0], \@buttonlist );

ok( ciobuttons($c[0])->[2]->[1] eq 'book', 'ok, book stored right!' );
ok( ciobuttons($c[0])->[1]->[1] eq 'gmail', 'ok, gmail stored right!' );

note '
################ messaging system
';

ok( msgsave($c[0], { subject => 'first msg', body => 'the first message contains nothing', priority => 5 }, 1233), 'posting 1233' );
ok( msgsave($c[0], { subject => 'second msg', body => 'die zweite auch nichts', priority => 3 }, 1234), 'posting 1234' );
ok( msgsave($c[0], { subject => 'third msg', body => 'tres nada nada nada', priority => 3 }, 1235), 'posting 1235');
ok( msgsave($c[0], { subject => 'fourth msg', body => 'ze meiyou meiyou meiyou', priority => 3 }, 1236), 'posting 1236');
ok( msgsave($c[0], { subject => 'to be killed', body => 'please die', priority => 3 }, 999), 'posting 999');

ok( msgmarkasread($c[0],'alice.welch@gmail.com', 1235), 'marking 1235 as read by alice');

my $msglistnotread= _msglistnotread($c[0],'alice.welch@gmail.com');
ok( scalar @{$msglistnotread} == 4, 'correct n=4 messages unread');
ok( msgdelete($c[0], 999), 'destroying 999');
$msglistnotread= _msglistnotread($c[0],'alice.welch@gmail.com');
ok( scalar @{$msglistnotread} == 3, 'correct n=3 messages unread');
ok( join(" ",@$msglistnotread) eq join(" ", (1233, 1234, 1236)), 'returned correct list of unread' );
like( (msgread( $c[0], 1235 ))->[0]->{body}, qr/nada nada nada/, 'read 1235 again' );

like( (msgshownotread( $c[0], 'alice.welch@gmail.com' ))->[0]->{body}, qr/the first message contains nothing/, 'reading message ok' );

note '
################ file storage and retrieval system
';

ok( filewrite($c[0], 'alice.welch@gmail.com', 'hw1.txt', "please do the first homework\n"), 'writing hw1.txt');
ok( filewrite($c[0], 'alice.welch@gmail.com', 'hw2.txt', "please do the second homework.  it is longer.\n"), 'writing hw2.txt');
my $e2n= "2medium.equiz"; ok( -e $e2n, "have test for 2medium.equiz for use in Model subdir" );
ok( filewrite($c[0], 'alice.welch@gmail.com', $e2n, scalar slurp($e2n)), 'writing $e2n' );
ok( filewrite($c[0], 'alice.welch@gmail.com', 'syllabus.txt', "<h2>please read this syllabus</h2>\n"), 'writing syllabus.txt' );
ok( filewrite($c[0], 'alice.welch@gmail.com', 'other.txt', "please do this syllabus\n"), 'writing other.txt' );

####
like( dies { filesetdue($c[0], 'hw0.txt', time()+100); }, qr/ does not exist/, 'cannot publish non-existing file' );

ok( filesetdue($c[0], 'hw1.txt', time()+10000), 'published hw1.txt');
ok( filesetdue($c[0], 'other.txt', time()+10000), 'published other.txt' );
ok( filesetdue($c[0], 'syllabus.txt', time()+10000), 'published syllabus.txt' );
ok( filesetdue($c[0], 'other.txt', time()-10000), 'unpublished other.txt' );
ok( filesetdue($c[0], 'other.txt', time()-10000), 'harmless unpublished again' );
ok( filesetdue($c[0], 'hw2.txt', time()-100), "unpublished hw2 by setting expiry to be behind us" );

my $npub= arrlen(ifilelistall($c[0], 'alice.welch@gmail.com'));
ok( $npub == 5, "instructor has 5 files" );

my $publicstruct=sfilelistall($c[0], 'alice.welch@gmail.com');
$npub= arrlen($publicstruct);
ok( $npub == 2, "student should see 2 published files (hw1, syllabus) not $npub" );

(my $publicstring= Dumper( $publicstruct )) =~ s/\n/ /g;

ok( $publicstring =~ m{hw1\.txt}, "published contains hw1.txt 1" );
ok( $publicstring !~ m{other.txt}, "published still contains other.txt 1" );
ok( $publicstring =~ m{syllabus\.txt}, "we had not published hw2.txt! 1" );

ok( sfileread( $c[0], 'hw1.txt'), "student can read hw1.txt 2" );
ok( sfileread( $c[0], 'syllabus.txt'), "student can read syllabus.txt 2" );
like( dies { sfileread( $c[0], 'other.txt') }, qr/no public file/, "student cannnot read unpublished other.txt" );
like( dies { sfileread( $c[0], 'blahother.txt') }, qr/no public file/, "student cannot read unexisting file" );

ok( filesetdue($c[0], 'other.txt', time()-100), "unpublish 'other.txt' by setdue ");
ok( filesetdue($c[0], 'hw1.txt', time()+1000), "publish 'hw1.txt' by setdue ");

## now we do student responses to homeworks

_suundo();

ok( !defined(sownfilelist( $c[0], 'charlie@gmail.com' )), "you have not yet uploaded hw1" );
like(dies { sownfileread( $c[0], 'charlie@gmail.com', 'hw1.txt' ) }, qr/uploaded/, "charlie cannot read a student submission he has not yet uploaded" );
like(dies { filewrite($c[0], 'charlie@gmail.com', 'hwneanswer.txt', "I have done hwne text\n", 'hwne.txt') },
     qr/not collecting/, 'charlie cannot answer nonexisting hw hwne.txt');

ok( filewrite($c[0], 'charlie@gmail.com', 'hw1answer.txt', "I have done hw1 text\n", 'hw1.txt'), 'charlie answered hw1.txt');
my $ownfiles= join(" ", @{sownfilelist( $c[0], 'charlie@gmail.com' )});
ok( $ownfiles =~ /hw1/, "you have now uploaded hw1" );
ok( $ownfiles !~ /hw3/, "you had not uploaded hw3" );

sudo($c[0], 'alice.welch@gmail.com');  ## become the instructor

ok( collectstudentanswers($c[0], 'hw1.txt') =~ /zip/, "collected properly submitted hw1 answer for charlie" );

note '
################ grade center
';

ok( dies { gradeadd($c[0], 'charlie@gmail.com', 'hw1', 'fail' ) }, "no hw1 yet registered for new grades");
ok( gradetaskadd($c[0], qw(hw1 hw2 hw3 midterm)), "hw1, hw2 hw3 midterm all allowed now" );

ok( gradesave($c[0], 'charlie@gmail.com', 'hw2', 'c-' ), "grade hw2 for charlie");
ok( gradesave($c[0], 'charlie@gmail.com', 'hw3', 'pass' ), "grade hw1 for charlie");
ok( gradesave($c[0], 'charlie@gmail.com', 'hw1', 'pass' ), "grade hw1 for charlie changed");

ok( gradesave($c[0], 'bob@gmail.com', 'hw1', 'pass' ), "grade hw1 for bob fail");
ok( gradesave($c[0], 'bob@gmail.com', 'hw2', 'a-' ), "grade hw2 for bob a-");
ok( gradesave($c[0], 'bob@gmail.com', 'midterm', 'pass' ), "grade midterm for bob");

ok( dies { gradesave($c[0], 'noone12312@gmail.com', 'midterm', 'pass' ) }, "grade midterm for none12312");
ok( dies { gradesave('mfe2', 'charlie@gmail.com', 'test5', 'midterm' ) }, "grade midterm for wrong course");

ok( gradetaskadd($c[0], qw(hw5)), "hw5 is now allowed now" );
ok( gradesave($c[0], 'alice.welch@gmail.com', "hw5", " 1/3 "), "added grade alice for hw5");
ok( gradesave($c[0], 'charlie@gmail.com', "hw5", " 2/3 "), "added grade charlie for hw5");

my $gah;
my @students;

$gah=gradesashash( $c[0] );  ## instructor call
@students= @{$gah->{uemail}};
ok( $#students==2, "you have three students, $#students: ".join("|", @students) );

ok( $gah->{grade}->{'bob@gmail.com'}->{midterm} eq 'pass', "Sorry, but bob should have passed the midterm, not ".$gah->{grade}->{'bob@gmail.com'}->{midterm});
ok( !defined($gah->{grade}->{'bob@gmail.com'}->{eq1}), "Good. bob has no eq1 grade" );

$gah=gradesashash( $c[0], 'charlie@gmail.com' );
@students= $gah->{uemail};
ok( $#students==0, "Sorry, but charlie should have been only one student.  you have ".join("|", @students) );
ok( $gah->{grade}->{'charlie@gmail.com'}->{hw2} eq 'c-', "good.  charlie got a c-" );
ok( !defined($gah->{grade}->{'charlie@gmail.com'}->{eqz22}), "good.  charlie has no grade" );

ok( !defined($gah->{grade}->{'bob@gmail.com'}->{midterm}), "Good.  we did not leak bob's grade info to charlie" );

note '
################ backup
';

ok( (sitebackup( $c[0] ) =~ /mfe.*zip/), "sitebackup worked" );
#ok( (sitebackup( $c[0] ) =~ /mfe.*zip/), "second long backup worked" );  should be the same and not contain a zip file

done_testing();

print "\n################ website structure now\n"._websiteshow($c[0])."\n";

# my $g= gradesashash( $c[0], 'alice.welch@gmail.com' ); print "glist for instructor: ".(Dumper $g);

sub tziserver {
  my $off_h=1;
  my @local=(localtime(time+$off_h*60*60));
  my @gmt=(gmtime(time+$off_h*60*60));
  return (-1)*($gmt[2]-$local[2] + ($gmt[5] <=> $local[5]
			      ||
			      $gmt[7] <=> $local[7])*24);
}
