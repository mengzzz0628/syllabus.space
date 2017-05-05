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
use SylSpace::Model::Model qw(:DEFAULT _websitemake _websiteshow _websiteremove _checkvalidagainstschema biowrite usernew bioread userenroll courselist ciowrite cioread cbuttons msgpost msgmarkread _msglistnotread msgdelete msgread msgreadnotread filewrite filesetdue _suundo websitebackup gradetaskadd gradeenter _storegradeequiz gradesashash userisenrolled ifilelistall sfilelistall filestudentcollect sfileread sownfileread sownfilelist csetbuttons isinstructor);

use Test2::Bundle::Extended;
use Test2::Plugin::DieOnFail;

_websiteremove("mfe"); ## if exists, we start over
_websiteremove("mba");
_websiteremove("undgrad");

note '
################ website creation, user registration, and user enrollment
';

like(dies { _websitemake("mfe", 'ivo.welch-not-possible-gmail.com') }, qr/email /, 'fail on need better i email' );
ok( _websitemake("mfe", 'ivo.welch@gmail.com'), 'create mfe site' );
ok( !eval { _websitemake("mfe", 'ivo.welch@gmail.com') }, 'cannot create mfe a second time' );

ok( _websitemake("mba", 'ivo.welch@gmail.com'), 'create mba site' );
ok( _websitemake("undgrad", 'x.lily.qiu@gmail.com'), 'create undergrad site' );

ok( (keys %{courselist('ivo.welch@gmail.com')} ) == 3, "need enrollment info on 3 existing courses\n");
ok( userisenrolled('mfe', 'ivo.welch@gmail.com'), "ivo is nicely enrolled");
ok( !userisenrolled('mfe', 'arthur.welch@gmail.com'), "arthur is nicely not enrolled");

note '
################ auth: user bios
';

my %bioivo = ( uniname => 'ucla', regid => 'na', firstname => 'ivo', lastname => 'welch', birthyear => 1963,
	       email2 => 'ivo.welch@anderson.ucla.edu', zip => 90095, country => 'US', cellphone => '(312) 212-3100',
	       email => 'ivo.welch@gmail.com', tzi => tziserver(), optional => '' );
ok( biowrite('ivo.welch@gmail.com', \%bioivo), 'written biodata for ivo' );

ok( usernew('x.lily.qiu@gmail.com'), 'new lily' );
my %biolily = ( uniname => 'na', regid => 'na', firstname => 'lily', lastname => 'qiu', birthyear => 1975,
		email2 => 'x.lily.qiu@gmail.com', zip => 90049, country => 'US', cellphone => '(312) 212-3200',
		email => 'x.lily.qiu@gmail.com', tzi => tziserver(), optional => '' );
ok( biowrite('x.lily.qiu@gmail.com', \%biolily), 'written biodata for lily' );


ok( usernew('arthur.welch@gmail.com'), 'new arthur' );
my %bioarthur = ( uniname => 'portola', regid => 'na', firstname => 'arthur', lastname => 'welch', birthyear => 2005,
		  email => 'arthur.welch@gmail.com', zip => 90049, country => 'US', cellphone => '(312) 212-3300',
		  email2 => 'gdtwentyseven@gmail.com', tzi => tziserver(), optional => '' );

#my $s= Dumper testmodhash(\%bioarthur, 'uniname', '');

sub testmodhash { my ( $h, $k, $v )=@_; my %nh= %$h; $nh{$k}=$v; return \%nh; }

like(dies { biowrite('arthur.welch@gmail.com', testmodhash(\%bioarthur, 'uniname', '')) }, qr/required/, 'fail on bad field content for uniname' );
like(dies { biowrite('arthur.welch@gmail.com', testmodhash(\%bioarthur, 'uniname', '&^SD')) }, qr/regex/, 'fail on regex for uniname' );
like(dies { biowrite('arthur.welch@gmail.com', testmodhash(\%bioarthur, 'uniname', 'ucla' x 50)) }, qr/long/, 'fail on length' );

like(dies { biowrite('arthur.welch@gmail.com', testmodhash(\%bioarthur, 'notvalid', 'any')) }, qr/allowed/, 'fail on field that should not be here' );
#delete $biosampledata{'notvalid'};

ok( biowrite('arthur.welch@gmail.com', \%bioarthur), 'written biodata for arthur' );

ok(dies { usernew('../..@gmail.com') }, 'bad email new user' );

ok( my $ibio=bioread('ivo.welch@gmail.com'), 'reread biodata for ivo' );
ok( biowrite('ivo.welch@gmail.com', $ibio), 'rewrote it' );

note '
################ enroll users in course
';

ok( isinstructor('mfe','ivo.welch@gmail.com'), 'ivo.welch\@ is an instructor for mfe' );
ok( userenroll('mfe', 'x.lily.qiu@gmail.com'), 'enrolled lily' );
ok( userenroll('mfe', 'arthur.welch@gmail.com'), 'enrolled arthur' );
ok( !eval { userenroll('mfe', 'noone@gmail.com') }, 'cannot enroll non-existing user' );


note '
################ course validity testing and modification
';

my %ciosample = ( uniname => 'ucla', unicode => 'mfe237', coursesecret => 'judy', cemail => 'mfe@gmail.com', anothersite => 'http://ivo-welch.info',
		  department => 'fin', subject => 'advanced corpfin', meetroom => 'B301', meettime => 'TR 2:00-3:30pm',
		  domainlimit => 'ucla.edu', hellomsg => 'hi friends' );

like(dies { ciowrite('mfe', \%ciosample) }, qr/insufficient privileges/, 'student cannot write class info' );

sudo('mfe', 'ivo.welch@gmail.com');  ## become the instructor

my $w= testmodhash(\%ciosample, 'coursesecret', '&^SD');

like(dies { ciowrite('mfe', testmodhash(\%ciosample, 'coursesecret', '&^SD')) }, qr/regex/, 'fail on regex for coursesecret' );

ok( ciowrite('mfe', \%ciosample), 'instructor writes sample cio sample' );
ok( my $icio=cioread('mfe'), 'reread cio' );
ok( _checkvalidagainstschema( $icio, 'c' ), 'is the reread ciodata still valid?' );

## buttons

my @buttonlist;
push(@buttonlist, ['http://ivo-welch.info', 'iaw-web', 'go back to root']);
push(@buttonlist, ['http://gmail.com', 'gmail', 'send email']);
push(@buttonlist, ['http://book.ivo-welch.info', 'book', 'read book']);

csetbuttons( 'mfe', \@buttonlist );

ok( cbuttons('mfe')->[2]->[1] eq 'book', 'ok, book stored right!' );
ok( cbuttons('mfe')->[1]->[1] eq 'gmail', 'ok, gmail stored right!' );

note '
################ messaging system
';

ok( msgpost('mfe', { subject => 'first msg', body => 'the first message contains nothing', priority => 5 }, 1233), 'posting 1233' );
ok( msgpost('mfe', { subject => 'second msg', body => 'die zweite auch nichts', priority => 3 }, 1234), 'posting 1234' );
ok( msgpost('mfe', { subject => 'third msg', body => 'tres nada nada nada', priority => 3 }, 1235), 'posting 1235');
ok( msgpost('mfe', { subject => 'fourth msg', body => 'ze meiyou meiyou meiyou', priority => 3 }, 1236), 'posting 1236');
ok( msgpost('mfe', { subject => 'to be killed', body => 'please die', priority => 3 }, 999), 'posting 999');

ok( msgmarkread('mfe','ivo.welch@gmail.com', 1235), 'marking 1235 as read by ivo');

my $msglistnotread= _msglistnotread('mfe','ivo.welch@gmail.com');
ok( scalar @{$msglistnotread} == 4, 'correct n=4 messages unread');
ok( msgdelete('mfe', 999), 'destroying 999');
$msglistnotread= _msglistnotread('mfe','ivo.welch@gmail.com');
ok( scalar @{$msglistnotread} == 3, 'correct n=3 messages unread');
ok( join(" ",@$msglistnotread) eq join(" ", (1233, 1234, 1236)), 'returned correct list of unread' );
like( (msgread( 'mfe', 1235 ))->[0]->{body}, qr/nada nada nada/, 'read 1235 again' );

like( (msgreadnotread( 'mfe', 'ivo.welch@gmail.com' ))->[0]->{body}, qr/the first message contains nothing/, 'reading message ok' );

note '
################ file storage and retrieval system
';

ok( filewrite('mfe', 'ivo.welch@gmail.com', 'hw1.txt', "please do the first homework\n"), 'writing hw1.txt');
ok( filewrite('mfe', 'ivo.welch@gmail.com', 'hw2.txt', "please do the second homework.  it is longer.\n"), 'writing hw2.txt');
my $e2n= "2medium.equiz"; ok( -e $e2n, "have test for 2medium.equiz for use in Model subdir" );
ok( filewrite('mfe', 'ivo.welch@gmail.com', '2medium.equiz', scalar slurp($e2n)), 'writing fun.equiz' );
ok( filewrite('mfe', 'ivo.welch@gmail.com', 'syllabus.txt', "<h2>please read this syllabus</h2>\n"), 'writing syllabus.txt' );
ok( filewrite('mfe', 'ivo.welch@gmail.com', 'other.txt', "please do this syllabus\n"), 'writing other.txt' );

####
like( dies { filesetdue('mfe', 'hw0.txt', time()+100); }, qr/ does not exist/, 'cannot publish non-existing file' );

ok( filesetdue('mfe', 'hw1.txt', time()+10000), 'published hw1.txt');
ok( filesetdue('mfe', 'other.txt', time()+10000), 'published other.txt' );
ok( filesetdue('mfe', 'syllabus.txt', time()+10000), 'published syllabus.txt' );
ok( filesetdue('mfe', 'other.txt', time()-10000), 'unpublished other.txt' );
ok( filesetdue('mfe', 'other.txt', time()-10000), 'harmless unpublished again' );
ok( filesetdue('mfe', 'hw2.txt', time()-100), "unpublished hw2 by setting expiry to be behind us" );

my $npub= arrlen(ifilelistall('mfe', 'ivo.welch@gmail.com'));
ok( $npub == 5, "instructor has 5 files" );

my $publicstruct=sfilelistall('mfe', 'ivo.welch@gmail.com');
$npub= arrlen($publicstruct);
ok( $npub == 2, "student should see 2 published files (hw1, syllabus) not $npub" );

(my $publicstring= Dumper( $publicstruct )) =~ s/\n/ /g;

ok( $publicstring =~ m{hw1\.txt}, "published contains hw1.txt 1" );
ok( $publicstring !~ m{other.txt}, "published still contains other.txt 1" );
ok( $publicstring =~ m{syllabus\.txt}, "we had not published hw2.txt! 1" );

ok( sfileread( 'mfe', 'hw1.txt'), "student can read hw1.txt 2" );
ok( sfileread( 'mfe', 'syllabus.txt'), "student can read syllabus.txt 2" );
like( dies { sfileread( 'mfe', 'other.txt') }, qr/no public file/, "student cannnot read unpublished other.txt" );
like( dies { sfileread( 'mfe', 'blahother.txt') }, qr/no public file/, "student cannot read unexisting file" );

ok( !defined(sownfilelist( 'mfe', 'arthur.welch@gmail.com' )), "you have not yet uploaded hw1" );

ok( filesetdue('mfe', 'other.txt', time()-100), "unpublish 'other.txt' by setdue ");

_suundo();
## a student submission kind of thing
ok( filewrite('mfe', 'arthur.welch@gmail.com', 'hw1answer.txt', "I have done hw1 text\n", 'hw1.txt'), 'arthur answered hw1.txt');
like(dies { filewrite('mfe', 'arthur.welch@gmail.com', 'hwneanswer.txt', "I have done hwne text\n", 'hwne.txt') },
     qr/not collecting/, 'fail on arthur cannot answer hwne.txt');
sudo('mfe', 'ivo.welch@gmail.com');  ## become the instructor

my $ownfiles= join(" ", @{sownfilelist( 'mfe', 'arthur.welch@gmail.com' )});
ok( $ownfiles =~ /hw1/, "you have now uploaded hw1" );
ok( $ownfiles !~ /hw3/, "you had not uploaded hw3" );

ok( sownfileread( 'mfe', 'arthur.welch@gmail.com', 'hw1.txt' ) =~ /I have done/, "can read student submission hw1.txt" );

ok( filestudentcollect('mfe', 'hw1.txt') =~ /zip/, "collected properly submitted hw1 answer for arthur" );

note '
################ grade center
';

ok( dies { gradeadd('mfe', 'arthur.welch@gmail.com', 'hw1', 'fail' ) }, "no hw1 yet registered for new grades");
ok( gradetaskadd('mfe', qw(hw1 hw2 hw3 midterm)), "hw1, hw2 hw3 midterm all allowed now" );

ok( gradeenter('mfe', 'arthur.welch@gmail.com', 'hw2', 'c-' ), "grade hw2 for arthur");
ok( gradeenter('mfe', 'arthur.welch@gmail.com', 'hw3', 'pass' ), "grade hw1 for arthur");
ok( gradeenter('mfe', 'arthur.welch@gmail.com', 'hw1', 'pass' ), "grade hw1 for arthur changed");

ok( gradeenter('mfe', 'x.lily.qiu@gmail.com', 'hw1', 'pass' ), "grade hw1 for lily fail");
ok( gradeenter('mfe', 'x.lily.qiu@gmail.com', 'hw2', 'a-' ), "grade hw2 for lily a-");
ok( gradeenter('mfe', 'x.lily.qiu@gmail.com', 'midterm', 'pass' ), "grade midterm for lily");

ok( dies { gradeenter('mfe', 'noone@gmail.com', 'midterm', 'pass' ) }, "grade midterm for none");
ok( dies { gradeenter('mfe2', 'arthur.welch@gmail.com', 'test5', 'midterm' ) }, "grade midterm for wrong course");

ok( gradetaskadd('mfe', qw(hw5)), "hw5 is now allowed now" );
ok( gradeenter('mfe', 'ivo.welch@gmail.com', "hw5", " 1/3 "), "added grade ivo for hw5");
ok( gradeenter('mfe', 'arthur.welch@gmail.com', "hw5", " 2/3 "), "added grade arthur for hw5");

my $gah;
my @students;

$gah=gradesashash( 'mfe' );  ## instructor call
@students= @{$gah->{uemail}};
ok( $#students==2, "you have three students, $#students: ".join("|", @students) );

ok( $gah->{grade}->{'x.lily.qiu@gmail.com'}->{midterm} eq 'pass', "Sorry, but lily should have passed the midterm, not ".$gah->{grade}->{'x.lily.qiu@gmail.com'}->{midterm});
ok( !defined($gah->{grade}->{'x.lily.qiu@gmail.com'}->{eq1}), "Good. lily has no eq1 grade" );

$gah=gradesashash( 'mfe', 'arthur.welch@gmail.com' );
@students= $gah->{uemail};
ok( $#students==0, "Sorry, but arthur should have been only one student.  you have ".join("|", @students) );
ok( $gah->{grade}->{'arthur.welch@gmail.com'}->{hw2} eq 'c-', "good.  arthur got a c-" );
ok( !defined($gah->{grade}->{'arthur.welch@gmail.com'}->{eqz22}), "good.  arthur has no grade" );

ok( !defined($gah->{grade}->{'x.lily.qiu@gmail.com'}->{midterm}), "Good.  we did not leak lily's grade info to arthur" );

note '
################ backup
';

ok( (websitebackup( 'mfe' ) =~ /mfe.*zip/), "websitebackup worked" );
#ok( (websitebackup( 'mfe' ) =~ /mfe.*zip/), "second long backup worked" );  should be the same and not contain a zip file

done_testing();

print "\n################ website structure now\n"._websiteshow('mfe')."\n";

# my $g= gradesashash( 'mfe', 'ivo.welch@gmail.com' ); print "glist for instructor: ".(Dumper $g);

sub tziserver {
  my $off_h=1;
  my @local=(localtime(time+$off_h*60*60));
  my @gmt=(gmtime(time+$off_h*60*60));
  return $gmt[2]-$local[2] + ($gmt[5] <=> $local[5]
			      ||
			      $gmt[7] <=> $local[7])*24;
}
