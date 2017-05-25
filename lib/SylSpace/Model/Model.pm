#!/usr/bin/env perl
package SylSpace::Model::Model;

use base 'Exporter';
## @ISA = qw(Exporter);

our @EXPORT_OK=qw(
 sudo tzi tokenmagic

 isinstructor ismorphed
 instructorlist instructoradd instructordel

 sitebackup isvalidsitebackupfile courselistenrolled courselistnotenrolled
 usernew userenroll isenrolled instructor2student student2instructor userexists getcoursesecret throttle 

 readschema bioread biosave bioiscomplete cioread ciosave cioiscomplete

 ciobuttonsave ciobuttons hassyllabus
 studentlist studentdetailedlist

 msgsave msgdelete msgread msgmarkasread msglistread msgshownotread

 ifilelistall ifilelist1
 sfilelistall sfileread sownfilelist sownfileread
 filelistsfiles filesetdue collectstudentanswers filewrite fileread fullfilename filedelete
 cptemplate rmtemplates

 gradetaskadd gradesave gradesashash gradesasraw gradesfortask2table

 tweet showtweets showlasttweet seclog showseclog superseclog

 renderequiz equizgrade equizanswerrender
);

our @EXPORT_DEBUG= qw(_msglistnotread _suundo _websitemake _websiteshow _webcourseremove _storegradeequiz _listallusers _checkvalidagainstschema);

@EXPORT_OK = ( @EXPORT_OK, @EXPORT_DEBUG );

################
use strict;
use common::sense;
use utf8;
use warnings;
use warnings FATAL => qw{ uninitialized };
use autodie;

use feature ':5.20';
use feature 'signatures';
no warnings qw(experimental::signatures);

################

my $var="/var/sylspace";  ## this should be hardcoded and unchanging
(-e "$var") or die "$0: please create the $var directory for the site first.  then run mksite.pl, Model.t, or Test.t\n";

################

=pod

=head1 Title

  Model.pm --- the model driving SylSpace

=head1 Description

  although some output is provided in html format, the code is controller independent.

  all data is saved in the filesystem and only in ASCII format.  this makes it easy to debug actions.

  a site is organized as follow

	/var/sylspace/
		secrets.txt  <- a set of random strings, generated at site initiation
		templates/  <- equiz templates containing collections of (algorithmic) questions
		users/  <- this is shared across all sites. 
			email/ <- primarily contains a bio.yml file, plus a user tzi (timezone)
		sites/  <- individual courses
			<nameofcourse>/
				buttons.yml  <- user interface extra buttons
				cinfo.yml <- course info
				tasklist <- for what grades can be assigned
				grades <- log of grades assigned
				instructor/ <- file storage for the instructor that can be made public
				public/ <- (empty) files posting with expiration dates
				msgs/ <- messages for the class from the instructor
				secret= <- whether the course requires an entry secret
				security.log <- obvious
				...enrolled user emails...

  instructors are identified by having a file in their subdomain user directory that says instructor=1

=head1 Versions

  0.0: Sat Apr  1 10:55:38 2017

=cut

################################################################

use File::Temp;
use File::Path;
use File::Touch;
use File::Copy;
use Email::Valid;
use Perl6::Slurp;
use Data::Dumper;
use YAML::Tiny;
use File::Glob qw(bsd_glob);
use Archive::Zip;


################################################################

=pod

=head2 website-related, course, and user-related functionality

=cut

################################################################

sub _websitemake($course, $instructoremail) {
  (-e "$var") or die "[wbm:1a] please create the $var directory for the site first\n";
  (-w "$var") or die "[wbm:1b] please make $var writable\n";
  (-e "$var/users") or die "[wbm:2a] please create the $var/users directory for everyone first\n";
  (-w "$var/users") or die "[wbm:2b] please make $var/users writable\n";
  (-e "$var/templates") or die "[wbm:3a]please create the $var/templates directory\n";
  (-e "$var/templates/starters") or die "[wbm:3b]please create the $var/templates/starters directory (templates are copied by hand)\n\tusually, ln -s .../templates/equiz/* $var/templates/";

  ($course =~ /^[\w][\w\.\-]*[\w]$/) or die "bad website name '$course'!\n"; ## need to check without triggering existence check
  (-e "$var/courses/$course") and die "website $course already exists\n";
  _checkemail($instructoremail);
  (-e "$var/users/$instructoremail") or usernew($instructoremail);

  mkdir("$var/courses/$course") or die "cannot make $course course website: $!\n";
  $course= _checkcname($course); ## we are not yet the instructor, so checking makes no sense

  mkdir("$var/courses/$course/msgs") or die "cannot make website messages: $!\n";
  mkdir("$var/courses/$course/public") or die "cannot make website published: $!\n";  ## will contain links
  mkdir("$var/courses/$course/instructor") or die "cannot make website instructor: $!\n";  ## will contain links
  mkdir("$var/courses/$course/instructor/files") or die "cannot make website instructor files: $!\n";  ## will contain links

  userenroll($course, $instructoremail, 1);
  touch("$var/courses/$course/$instructoremail/instructor=1");
  ##$instructoremail= _checkemail($instructoremail, $course);
}


## used for debugging in .t files
sub _websiteshow($course) {
  (-e "$var") or die "please create the $var directory for the site first\n";
  (-e "$var/users") or die "please create the $var/users directory for everyone first\n";
  (-e "$var/courses/$course") or die "please create the $var/courses/$course directory for everyone first\n";

  _confirmnotdangerous($course, "subdomain in wss");
  return `find $var/users $var/courses/$course`;
}


## for drastic debugging, this removes all websites!  it should never be called from the web.
sub _webcourseremove($course) {
  ## can we add a test whether we are running under Mojolicious and abort if we are?
  ($course =~ m{/}) and die "ok, wcremove is not safe, but '$course' is ridiculous";
  (($course eq "*") || ($course =~ m{\w[\w\.\-]*/})) or die "ok, wcrm is not safe, but '$course' is ridiculous";
  my $nremoved=0;
  foreach (bsd_glob("$var/courses/$course")) {
    $_= lc($_);
    (-e $_) or next;
    system("rm -rf $_");
    (-e $_) and die "wth?  $_ could not be removed!\n";
    ++$nremoved;
  }
  return $nremoved;
}

## user email information should not leak, either, so please use it only during debugging.
sub _listallusers() {
  my @users;
  foreach (glob("$var/users/*")) {
    chomp;
    s{.*/}{};
    push(@users, $_);
  }
  return \@users;
}


## create a zip file of the site, place it in the user directory, and return the filename
sub sitebackup( $course ) {
  $course= _confirmsudoset( $course );

  (-d "$var/courses/$course") or die "bad course";
  (-r "$var/courses/$course") or die "unreadable course";
  ((-d "$var/tmp") && (-w "$var/tmp")) or die "tmp was not created";

  ($course =~ /test/) and die "sorry, no websitebackup for testsite allowed";

  my $zip= Archive::Zip->new();
  _confirmnotdangerous($course, "subdomain in wss");
  my $ls=`ls -Rlt $var/courses/$course/`;
  $zip->addString($ls , '_MANIFEST_' );
  $zip->addTreeMatching( "$var/courses/$course", "backup", '(?<!\.zip)$' );

  my $ofname="$var/tmp/$course-".time().".zip";
  $zip->writeToFileNamed($ofname);

  return $ofname;
}

sub isvalidsitebackupfile( $fnm ) {
  ($fnm =~ m{^$var/tmp/[\w\-\.]+\.zip}) or die "internal error: '$fnm' is not a good site backup file\n";
}

################################################################

sub courselistenrolled( $uemail ) { return _courselist( $uemail, 1 ); }
sub courselistnotenrolled( $uemail ) { return _courselist( $uemail, 0 ); }

## inefficient, but unimportantly inefficient
sub _courselist( $uemail, $enrolltype ) {
  my $fnames;  my %coursenames;
  foreach (bsd_glob("$var/courses/*")) {
    (-d $_) or next;
    if (defined($uemail)) {
      my $isenrolled= (-d "$_/$uemail");
      if (defined($enrolltype)) {
	(($enrolltype) && (!$isenrolled)) and next;
	((!$enrolltype) && ($isenrolled)) and next;
      }
    }
    (my $snm=$_) =~ s{.*/}{};
    $coursenames{$snm}= defined(getcoursesecret( $snm ))?1:0; ## the hash tells us whether the course has a required secret or not
  }
  return \%coursenames;
}

################################################################

sub getcoursesecret( $course ) { 
  (defined($course)) or die "you need a secret for a course, not for nothing";
  $course =~ s{^.*/}{};
  my $sf=bsd_glob("$var/courses/$course/secret=*");
  (defined($sf)) or return undef;
  $sf =~ s{.*secret\=}{};
  return $sf;
}

sub setcoursesecret( $course, $secret ) {
  if ((!defined($secret)) || ($secret =~ /^\s*$/)) {
    unlink(bsd_glob("$var/courses/$course/secret=*"));  ## or ignore
    return;
  }
  _confirmnotdangerous( $secret, "bad secret" );
  touch("$var/courses/$course/secret=$secret");
}


sub throttle( $seconds=5 ) {
  my @timestamps;
  ## each unique second throttle shares the same semaphore
  foreach ( bsd_glob("$var/tmp/throttle$seconds=*") ) {
    (defined($_)) or next;
    push(@timestamps, $_);
    (my $timestamp= $_) =~ s{.*throttle$seconds=}{};
    ($timestamp > 1000000) or die "non-sensible timestamp $timestamp in file system";
    ($timestamp + $seconds <= time()) or sleep($seconds);  ## conservative
  }
  touch("$var/tmp/throttle$seconds=".time());
  foreach (@timestamps) { unlink($_); }  ## files may have disappeared already, but noone cares
}

################
## creates a new user.  users can register themselves

sub usernew( $uemail ) {
  $uemail= _checkemail($uemail);
  (-e "$var/users/$uemail") and return (-1);  ## this is a forgivable mistake, but signaled
  mkdir("$var/users/$uemail") or die "cannot create user name $uemail";

  my $randomcode= join'', map +(0..9,'a'..'z','A'..'Z')[rand(10+26*2)], 1..32;
  touch("$var/users/$uemail/code.$randomcode") or die "cannot create a unique randomcode for $uemail";
  return 1;
}

sub userexists( $uemail ) { return (-e "$var/users/$uemail"); }

################
## users cannot enroll themselves unless they know the course secret
sub userenroll( $course, $uemail, $iswebsitecreator=0 ) {
  (-e "$var/courses/$course") or die "no such course $course.\n";
  (-e "$var/users/$uemail") or die "no such user $uemail yet.  please register bio info first\n";
  if (!$iswebsitecreator) {
    (-e "$var/users/$uemail/bio.yml") or die "cannot enroll user who has no bio info (except for instructor)";
    (-e "$var/courses/$course/instructor") or die "why is there no instructor for $course yet?";
    (-e "$var/courses/$course/instructor/files") or die "why does instructor for $course not have any files?";
  }

  (-e "$var/courses/$course/$uemail") and return _checkemail($uemail, $course);  ## mild error-- we already exist

  mkdir("$var/courses/$course/$uemail") or die "could not make $course/$uemail: $!\n";
  mkdir("$var/courses/$course/$uemail/msgs") or die "could not make $course/$uemail/msgs: $!\n";
  mkdir("$var/courses/$course/$uemail/files") or die "could not make $course/$uemail/files: $!\n";
  ## we want to keep user information when we do websitebackup, so don't symlink:
  symlink("$var/users/$uemail/bio.yml", "$var/courses/$course/$uemail/bio.yml")
    or die "cannot store bio info for $uemail in class $course";
  copy("$var/users/$uemail/bio.yml", "$var/courses/$course/$uemail/static-bio.yml");  ## one time copy from auth.  will not be updated.
  return _checkemail($uemail, $course);
}

sub isenrolled( $course, $uemail ) {
  ($course =~ /^[\w][\w\-\.]*[\w]/) or die "bad subdomain name $course";
  ($course eq "auth") and return 0;
  (-e "$var/courses/$course") or die "no such course $course.\n";
  return (-e "$var/courses/$course/$uemail");
}


################################################################

sub bioread( $uemail ) {
  $uemail=_checkemail($uemail);
  return _saferead("$var/users/$uemail/bio.yml");
}

sub biosave( $uemail, $biodataptr ) {
  $uemail=_checkemail($uemail);
  _checkvalidagainstschema( $biodataptr, 'u' );
  ($biodataptr->{email} eq $uemail) or die "you better have the same primary email in biowrite, not $uemail and $biodataptr->{email}";

  my $udir="$var/users/$uemail";
  (defined($biodataptr->{tzi})) or die "need a timezone";
  unlink(bsd_glob("$udir/tzi=*"));  ## remove any old timezones
  touch("$udir/tzi=".$biodataptr->{tzi}) or die "cannot set user timezone to ".$biodataptr->{tzi};
  ## print STDERR "[update biowrite: on save percolate into existing user directories, too --- or do it backup time and keep link]"
  return _safewrite( $biodataptr, "$udir/bio.yml" );
}

sub tzi( $uemail ) {
  my $f=bsd_glob("$var/users/$uemail/tzi=*");
  (defined($f)) or die "user $uemail has no timezone info";
  (-e $f) or die "user $uemail has no timezone info";
  $f =~ s{.*tzi\=(.*)}{$1};
  return $f;
}

sub bioiscomplete( $uemail ) {
  $uemail=_checkemail($uemail);
  (-e "$var/users/$uemail/bio.yml") or return 0;
  return ((-s "$var/users/$uemail/bio.yml")>10);  ## ok, not a full check, I admit.
}

################################################################

sub cioread( $course ) {
  $course= _checkcname($course);
  return _saferead("$var/courses/$course/cinfo.yml");
}

sub ciosave( $course, $ciodataptr ) {
  $course= _confirmsudoset( $course );
  _checkvalidagainstschema( $ciodataptr, 'c' );

  setcoursesecret($course, $ciodataptr->{coursesecret});
  return _safewrite( $ciodataptr, "$var/courses/$course/cinfo.yml" )
}

sub cioiscomplete( $course ) {
  $course= _confirmsudoset( $course );
  (-e "$var/courses/$course/cinfo.yml") or return 0;
  return ((-s "$var/courses/$course/cinfo.yml")>10);  ## ok, not a full check, I admit.
}

sub ciobuttonsave( $course, $list ) {
  $course= _confirmsudoset( $course );
  return _safewrite($list, "$var/courses/$course/buttons.yml" );
}

sub ciobuttons( $course ) {
  $course= _checkcname($course);
  return _saferead( "$var/courses/$course/buttons.yml" )|| ();
}


sub hassyllabus( $course ) {
  my $s= (bsd_glob("$var/courses/$course/instructor/files/syllabus.*"));
  (defined($s)) or $s= (bsd_glob("$var/courses/$course/instructor/files/syllabus*.*"));
  (defined($s)) or return undef;
  $s =~ s{.*/}{};
  return (_ispublic( $course, $s )) ? $s : undef;
}



################################################################

sub studentdetailedlist( $course ) {
  $course= _confirmsudoset( $course );
  my @list;
  foreach (_glob2last("$var/courses/$course/*@*")) {
    (my $ename=$_) =~ s{$var/courses/$course}{};
    my $thisuser= _saferead( "$var/users/$ename/bio.yml" );
    ($thisuser->{email}) or $thisuser->{email}= $ename;  ## instructor added may lack
    push(@list, $thisuser);
  }
  return \@list;
}

sub studentlist( $course ) {
  $course= _confirmsudoset( $course );
  my @list= _glob2last("$var/courses/$course/*@*");
  return \@list;
}



################################################################

=pod

=head2 SODO (Instructor)-related functionality

=cut

################################################################

sub tokenmagic( $uemail ) {
  (-e "$var/tmp/magictoken") or return undef;
  my @lines= slurp("$var/tmp/magictoken");
  $lines[0] =~ s{^now\:\s*}{}; chomp($lines[0]); # =~ s{\s*[\r\n]*}{}ms;
  $lines[1] =~ s{^then\:\s*}{}; chomp($lines[1]); # =~ s{\s*[\r\n]*}{}ms;
  (lc($lines[0]) eq lc($uemail)) or die "bad token magic file email.  you are '$uemail', not '$lines[0]'";
  (_checkemail($lines[1])) or die "you cannot possibly turn yourself into an invalid email of $lines[1]";
  unlink("$var/tmp/magictoken");
  return $lines[1];
}


sub instructor2student( $course, $uemail) {
  $course= _confirmsudoset( $course );  ## ok, we are the instructor!
  $uemail= _checkemail($uemail, $course);
  return touch("$var/courses/$course/$uemail/morphed=1");
}

sub student2instructor( $course, $uemail) {
  $uemail= _checkemail($uemail, $course);
  # (ismorphed($course,$uemail)) or die "you cannot unmorph $uemail in $course";
  (-e "$var/courses/$course/$uemail/morphed=1") and unlink("$var/courses/$course/$uemail/morphed=1");
}

sub ismorphed($course, $uemail) {
  ## ahhh, here we need to just check for morphing, not for instructor
  ((-e "$var/courses/$course/$uemail/morphed=1")&&(-e "$var/courses/$course/$uemail/instructor=1")) and return 1;
  return 0;
}


my $amsudo=0;  ## after setting it to 1, you no longer have to give the email to check capabilities

sub sudo( $course, $uemail ) {
  ##  ($amsudo) and return 1;  ## it was already set (by me!)  this is probably no longer necessary
  (defined($course)) or die "Model sudo: need a class name";
  (defined($uemail)) or die "Model sudo: need some uemail --- who are you?";
  (-e "$var/users/$uemail") or die "Model sudo: '$uemail' is not even enrolled in $course";

  (isinstructor($course, $uemail)) or die "Model sudo: you $uemail are not among valid instructors for $course\n";
  $amsudo=1; ## ok, we are set for confirmsudoset and isinstructor
  return $course;
}

# sub utype( $course, $uemail ) { return (isinstructor($course, $uemail)) ? 'i' : 's'; }

## a local helper,  works only after an sudo() has been called, because email has been checked; also does _checkcname
sub _confirmsudoset( $course ) {
  $course= _checkcname($course);
  ($amsudo) or die "insufficient privileges: you are not a confirmed instructor for $course!\n";
  return $course;
}

sub _suundo { $amsudo=0; }  ## needed for debug and testing only

sub isinstructor( $course, $uemail, $ignoremorph=0 ) {
   $course= _checkcname($course);
   ($course eq "auth") and return 0;  ## there are no instructors in auth
   ## ($amsudo) and return 1;  ## already checked
   (defined($uemail)) or die "isinstructor without uemail!\n";

   (-e "$var/courses/$course/$uemail/instructor=1") or return 0;  ## for sure we are not
   (-e "$var/courses/$course/$uemail/morphed=1") and return 0;
   return 1;
}

sub instructorlist( $course ) {
  $course= _checkcname($course);
  ## students and instructors can find out who is in charge
  my @l= bsd_glob("$var/courses/$course/*@*/instructor=1");
  foreach (@l) { s{$var/courses/$course/([^\/]+)/instructor\=1}{$1}; }
  return \@l;
}

sub instructoradd( $course, $newiemail ) {
  $course= _checkcname($course);
  _confirmsudoset( $course );

  (defined($newiemail)) or die "setinstructors without uemail!\n";
  (-e "$var/courses/$course/$newiemail") or die "you can only make users enrolled in $course your new instructors";
  return touch("$var/courses/$course/$newiemail/instructor=1");
}

sub instructordel( $course, $uemail, $newiemail ) {
  $course= _checkcname($course);
  _confirmsudoset( $course );
  ($uemail eq $newiemail) and die "you cannot delete yourself as an instructor";
  unlink("$var/courses/$course/$newiemail/instructor=1");
}


################################################################

=pod

=head2 Bio and Course Info : Input and Validation

=cut

################################################################

#### the main routine to make sure that our inputs validate
sub readschema( $metaschemafletter ) {
  use FindBin;
  use lib "$FindBin::Bin/../lib";

  my $fname= $metaschemafletter."settings-schema.yml";
  (!(-e $fname)) and $fname="Model/$fname";
  (!(-e $fname)) and $fname="SylSpace/$fname";
  my $metaptr= _saferead($fname);  ## needs to be external, so that form controller and viewer know it, too
  (defined($metaptr)) or die "schema '$metaschemafletter' ($fname) is not readable from ".`pwd`."!\n";
  return $metaptr;
}


sub _checkvalidagainstschema( $dataptr, $metaschemafletter, $verbose =0 ) {
  sub _ishashptr( $x ) { (ref($x) eq ref({})) or die "bad internal input\n" };
  _ishashptr($dataptr);

  my $metaptr= readschema($metaschemafletter); ## needs to be external, so that form controller and viewer know it, too
  (defined($metaptr)) or die "schema for '$metaschemafletter' is not readable by _checkvalidagainstschema\n";

  my @validmetas = qw( required regex maxsize htmltype placeholder public value readonly );
  my %validmetas; foreach( @validmetas ) { $validmetas{$_} = 1; }

  my %metas;
  foreach (@{$metaptr}) {
    my $field= $_;
    ($verbose) and print STDERR Dumper($field)."\n";
    my $fieldname= (keys %$field)[0];
    my $d= $dataptr->{$fieldname};
    ($fieldname eq 'defaults') and next;  ## this one is special and not checked
    (defined($d)) or die "sorry, but I really wanted a field named $fieldname\nyou only gave ".Dumper($dataptr)."\n";

    my $constraints= $field->{$fieldname};
    foreach (keys %{$constraints}) { ($validmetas{$_}) or die "in meta-scheme file, Field $fieldname contains invalid fieldinfo '$_'"; }

    if ($constraints->{required}) {
      ($verbose) and print STDERR "REQUIRED: $fieldname ";
      (defined($d)) or die "required field '$fieldname' has no data in\n".Dumper($dataptr)."\n";
      ($d =~ /[a-zA-Z0-9\-]/) or die "required field '$fieldname' has no data in\n".Dumper($dataptr)."\n";
      ($verbose) and print STDERR " w/ content = '$dataptr->{$fieldname}'\n";
    }
    if (my $regex=$constraints->{regex}) {
      ($verbose) and print STDERR "testing $fieldname data $d against regex $regex ";
      ## empty only validates against regex if not empty
      if (defined($d) && ($d ne "")) {
	($d =~ m{$regex}) or die "field $fieldname: '$d' does not satisfy regex $regex\n";
      }
      ($verbose) and print STDERR "passed.\n";
    }
    if (my $maxsize=$constraints->{maxsize}) {
      ($verbose) and print STDERR "testing $fieldname data $d against maxsize $maxsize\n\n";
      (length($d)<=$maxsize) or die "$d is longer than $maxsize characters\n";
    }
    if (my $htmltype=$constraints->{htmltype}) {
      ($verbose) and print STDERR "testing $fieldname data $d against htmltype $htmltype  ";
      if (($d)&&($d ne '')) {
	if ($htmltype eq "number") { ($d+0 == $d) or die "Sorry, but $htmltype is not a number\n"; }
	if ($htmltype eq "email") { _checkemail($d) or die "Sorry, but $htmltype is not an email\n"; }
	if ($htmltype eq "url") { ($d=~/^http/) or die "Sorry, but $htmltype is not a url\n"; }
      }
    }

    $metas{$fieldname}=1;
  }
  foreach (keys %{$dataptr}) {
    ($metas{$_}) or die "Sorry, but data point '$_' was not in list of allowed metas: ".Dumper(\%metas)."\n";
  }

  return 1;
}



################################################################

=pod

=head2 Messaging System (from instructors to notify students)

=cut

################################################################

sub msgsave( $course, $msgin, $optmsgid =undef ) {
  $course= _confirmsudoset( $course );
  (defined($msgin)) or die "no message was provided";
  $msgin->{time}= time();
  $msgin->{msgid}= $optmsgid||($msgin->{time});
  (-e "$var/courses/$course/msgs/$msgin->{msgid}") and die "message with id $msgin->{msgid} already exists";
  (defined($msgin->{priority})) or $msgin->{priority}=0;
  my $msg;
  foreach (qw(priority subject body msgid time)) {
    (exists($msgin->{$_})) or die "message lacks required field $_ (".Dumper($msgin).")\n";
    $msg->{$_} = $msgin->{$_};
  }
  foreach (qw(priority msgid time)) { (($msg->{$_}+0)==($msg->{$_})) or die "message $_ must be an int, not $_\n"; }
  (length($msg->{body})<= 16384) or die "message is ".(length($msg->{body})-16384)." characters too long\n";
  (length($msg->{subject})<= 512) or die "subject header is ".(length($msg->{subject})-512)." characters too long\n";

  _safewrite( $msg, "$var/courses/$course/msgs/".$msg->{msgid}.".yml" ) or return 0;
  return $msgin->{msgid};
}

sub msgdelete( $course, $msgid ) {
  $course= _confirmsudoset( $course );
  $msgid =~ s/^msgid=//;
  ($msgid =~ /^[0-9]+$/) or die "need reasonable message id to delete, not '$msgid'!\n";

  (-e "$var/courses/$course") or die "no such course";
  (-e "$var/courses/$course/msgs") or die "no course messages";
  (-e "$var/courses/$course/msgs/$msgid.yml") or die "message $msgid.yml does not exist in $var/courses/$course/msgs";

  foreach (bsd_glob("$var/courses/$course/*@*/msgs/$msgid.yml")) { unlink($_); }  ## any user who thinks he has seen this now no longer has
  unlink("$var/courses/$course/msgs/$msgid.yml");  ## and the original message, too, of course
  return 1;
}

## msg read can work with an array of or a single msgid, or a pointer to an array of msgid
sub msgread( $course, @msgid ) {
  $course= _checkcname($course);
  (@msgid) or @msgid= _glob2last("$var/courses/$course/msgs/*");
  (ref $msgid[0] eq 'ARRAY') and @msgid= @{$msgid[0]};

  my @allmsgs;
  foreach my $msgid (@msgid) {
    $msgid =~ s/\.yml$//;
    ($msgid =~ /^[0-9]+$/) or die "need reasonable message id to read, not '$msgid'!\n";
    push( @allmsgs, _saferead( "$var/courses/$course/msgs/$msgid.yml" ));
  }
  return \@allmsgs;
}

## iterate messages
sub msgmarkasread( $course, $uemail, $msgid ) {
  $course= _checkcname( $course );
  $uemail= _checkemail($uemail,$course);
  $msgid =~ s/^msgid=//;
  ($msgid =~ /^[0-9]+$/) or die "need reasonable message id to mark read, not '$msgid'!\n";
  touch("$var/courses/$course/$uemail/msgs/$msgid.yml");
}


## the following three return lists of msgid.yml
sub _msglist( $course ) {
  $course= _checkcname($course);
  return _glob2lastnoyaml("$var/courses/$course/msgs/*.yml");
}

sub msglistread( $course, $uemail ) {
  $uemail= _checkemail($uemail,$course);
  return _glob2lastnoyaml("$var/courses/$course/$uemail/msgs/*.yml");
}

## iterate messages; returns a pointer to an array of msgids
sub _msglistnotread( $course, $uemail ) {
  my @r= msglistread( $course, $uemail );  ## will check cname and uemail
  my @a= _msglist( $course );
  my %r; foreach (@r) { $r{$_}=1; }
  my @m= grep { !$r{$_} } @a;
  return \@m;
}

## iterate all unread messages and put it into a full structure
sub msgshownotread( $course, $uemail ) {
  return msgread( $course, _msglistnotread( $course, $uemail ) ); } ## ->[0] dereferences




################################################################

=pod

=head2 Grading interface, allowing setting and reading grades

=cut

################################################################

## can be done repeatedly without harm
sub gradetaskadd( $course, @hwname ) {
  my $tasklistfile="$var/courses/$course/tasklist";
  _confirmsudoset($course);

  my %existing;
  if (-e $tasklistfile) { foreach (slurp($tasklistfile)) { $existing{$_}= 1; } }

  my @addhw;
  foreach ( @hwname ) {
    chomp;
    ($existing{$_}) and next;  ## just ignore the task if it already is in file
    push(@addhw, $_);
  }

  if (@addhw) {
    open(my $FOUT, ">>", $tasklistfile) or die "cannot open file $tasklistfile to store new hw category: $!";
    foreach (@addhw) { print $FOUT $_."\n"; }
    close($FOUT);
  }

  return $#addhw+1;
}

sub gradesasraw( $course ) {
  (-e "$var/courses/$course/grades") or return "no grades yet";
  return slurp("$var/courses/$course/grades");
}


## no uemail means that 
sub gradesashash( $course, $uemail=undef ) {
  ## as instructor, just leave uemail blank and you get all grades;
  ## otherwise, with an email, you only get your own grades

  $course= _checkcname( $course );

  (-e "$var/courses/$course/grades") or return;
  my @gradelist= slurp("$var/courses/$course/grades");
  if (defined($uemail)) {
    @gradelist= grep(/$uemail/, @gradelist);  ## faster...we just do it for 1 student
  } else {
    $course= _confirmsudoset($course);  ## make sure
  }
  ## hw stays in order!
  my (%hw,@hw);  foreach (slurp("$var/courses/$course/tasklist")) { chomp; $hw{$_}=1; push(@hw, $_); }

  my (%col, %row, $gradecell, $timestamp);
  foreach (@gradelist) {
    s/[\r\n]//;
    my ($uem, $tskn, $grd, $tma)=split(/\t/, $_);
    ($tma >= 1493749426) or die "corrupted homework file!\n";

    $col{$uem}= $uem; ## unregistered students can have homeworks, so no check against registered list
    $row{$tskn}= $tskn;
    $hw{$tskn} or die "unknown homework '$tskn'\n".slurp("$var/courses/$course/tasklist")."\n";
    $gradecell->{$uem}->{$tskn}= $grd;  ## use the last time we got a grade for this task;  ignore earlier grades
    $timestamp->{$uem}->{$tskn}= $tma;
  }
  my @col= sort keys %col;
  # my @row= sort keys %row;
  ($#col == (-1)) and return;

  return { hw => \@hw,
	   uemail => (defined($uemail) ? [ $uemail ] : studentlist( $course )),
	   grade => $gradecell, epoch => $timestamp };
}


## entering is easy: just append to a file.  the only complex aspect is that we do not want
## to repeat ourselves; if the grade has not changed, keep the old entry.  note that we may
## have multiple grades on the same homework in the file.  the reader has to be smart enough
## to know that it is the last one that counts;
sub gradesave( $course, $semail, $hwname, $newgrade ) {
  $course= _confirmsudoset( $course );

  my (@semail, @hwname, @newgrade);

  if (ref $semail eq 'ARRAY') {
    (ref $hwname eq 'ARRAY') or die 'gradeadd: either all or none are arrays!';
    (ref $newgrade eq 'ARRAY') or die 'gradeadd: either all or none are arrays!';
    ((scalar @{ $semail }) == (scalar @{ $hwname })) or die "gradeadd: must be the same number of obs";
    ((scalar @{ $semail }) == (scalar @{ $newgrade })) or die "gradeadd: must be the same number of obs";
    @semail= @$semail;
    @hwname= @$hwname;
    @newgrade= @$newgrade;
  } else {
    push(@semail, $semail ); push(@hwname, $hwname); push(@newgrade, $newgrade);
  }

  my %recorded;
  if (-e "$var/courses/$course/grades") {
    foreach (slurp("$var/courses/$course/grades")) {
      my @k= split(/\t/, $_); pop(@k);
      $recorded{join("\t", @k)}=1;
    }
  }

  my %hw;
  if (-e "$var/courses/$course/tasklist") {
    foreach (slurp("$var/courses/$course/tasklist")) { chomp; $hw{$_}=1; }
  }

  my @todo;
  while ($#semail >= 0) {
    my $e= pop(@semail); $e=_checkemail($e,$course);  ## we could permit recording non-registered students
    my $h= pop(@hwname); ($hw{$h}) or die "cannot add grade for non-existing homework '$h', course $course.";
    my $g= pop(@newgrade); ## grades can be anything
    my $ehg= "$e\t$h\t$g";
    ($recorded{$ehg}) and next;
    $recorded{$ehg}= 1;
    push(@todo, $ehg."\t".time()."\n");
  }
  if (@todo) {
    open(my $FOUT, ">>", "$var/courses/$course/grades") or die "cannot open gradefile for course $course for w: $!";
    foreach (@todo) { print $FOUT $_; }
    close($FOUT);
  }

  return $#todo+1;
}

##
sub gradesfortask2table($course, $task) {
  my @r;
  open(my $FIN, "<", "$var/courses/$course/grades") or return;
  while (<$FIN>) {
    my @c= split(/\t/, $_);
    ($c[1] eq $task) or next;
    push(@r, [ $c[0], $c[2], $c[3] ]);
  }
  return \@r;
}

################################################################

=pod

=head2 File interface. 

instructors can store and read all files.  students can only read
published instructor files, plus own files that they have uploaded.

=cut

################################################################

### could be split into instructor and studentwrites
sub filewrite( $course, $uemail, $filename, $filecontents, $inresponseto=undef ) {
  $uemail= _checkemail($uemail,$course);
  $filename= _checkfilename($filename);

  if (isinstructor($course, $uemail)) {
    $course= _checkcname( $course );
    $uemail= 'instructor';
    return _safewrite( $filecontents, "$var/courses/$course/$uemail/files/$filename" );
  }

  ## we are a student
  (defined($inresponseto)) or die "students can only answer, but not post, so '$filename' cannot be accepted\n";
  (_ispublic($course, $inresponseto))
    or die "sorry, we are not collecting for $inresponseto.  did you use the correct hw filename in your own response filename $filename?";
  $filename="$inresponseto.response.$filename";
  (_safewrite( $filecontents, "$var/courses/$course/$uemail/files/$filename" )) or return 0;  ## fail
  foreach (bsd_glob("$var/courses/$course/$uemail/files/inresponseto.response.*")) {
    ($_ eq $filename) and next;
    unlink($_);  # delete any earlier files that answered the same homework (should be only 1)
  }
  return 1;
}

sub fileread( $course, $uemail, $filename ) {
  return _saferead( fullfilename( $course, $uemail, $filename) );
}

## a full path to a file
sub fullfilename( $course, $uemail, $filename ) {
  ($uemail eq 'instructor') or $uemail= _checkemail($uemail,$course);
  $filename= _checkfilename($filename);
  (isinstructor($course,$uemail)) and $uemail='instructor';
  return "$var/courses/$course/$uemail/files/$filename";
}


## a student reading files from the instructor
sub sfileread( $course, $filename ) {
  ## check enrollment?
  $filename =~ s{.*/}{};
  my $t= _ispublic( $course, $filename );
  ($t < time()) and die "no public file $filename!  choices=".join(" ", bsd_glob( "$var/courses/$course/public/*" ));  ## expired!
  return _saferead( fullfilename( $course, 'instructor', $filename) )
}

## a student reading an own submitted homework answer
sub sownfileread( $course, $uemail, $filename ) {
  my $pattern= "$var/courses/$course/$uemail/files/$filename*";  # any that meets the pattern
  $_= ((_glob2last($pattern))[0]);
  (defined($_)) or die "no file '$filename' was earlier uploaded by you (a student, $uemail)";

  my $rv= _saferead( fullfilename( $course, $uemail, $_) );
  return _saferead( fullfilename( $course, $uemail, $_) );
}


## could be instructor only if we do not allow students to remove their own files
sub filedelete( $course, $uemail, $filename ) {
  $uemail= _checkemail($uemail,$course);
  $filename= _checkfilename($filename);
  (isinstructor($course, $uemail)) and $uemail='instructor';
  (-e "$var/courses/$course/$uemail/files/$filename") or die "cannot delete non-existing file $filename";
  unlink( "$var/courses/$course/$uemail/files/$filename" ) or die "failed to delete $filename: $!\n";
  _cleandeadlines($course);
  ## keep the student responseto submissions
  return 1;
}


## build a detailed file structure for extended display
sub ifilelist1( $course, $uemail, $basename ) {
  $course= _confirmsudoset( $course );
  $uemail= _checkemail($uemail,$course);
  $basename= _checkfilename($basename);

  $course= _confirmsudoset( $course );

  my $fullfnm="$var/courses/$course/instructor/files/$basename";
  (-e $fullfnm) or die "internal error: $fullfnm does not exist.";

  return { filename => $basename, fullfilename => $fullfnm, filelength => (-s $fullfnm),
	   duetime => _ispublic($course, $basename), mtime => ((stat($fullfnm))[9]) };
}


## instructor can list all files
sub ifilelistall( $course, $uemail, $mask="*" ) {
  $course= _confirmsudoset( $course );
  $uemail= _checkemail($uemail, $course);

  my @ufl;
  if ($mask eq "X") {  ## special!!!  this means files that are not homeworks or equizzes
    my @l= _glob2last( "$var/courses/$course/instructor/files/*" );
    @l = grep { $_ !~ /^hw/i } @l;
    @l = grep { $_ !~ /\.equiz$/i } @l;
    @ufl= @l;
  } else {
    @ufl= _glob2last( "$var/courses/$course/instructor/files/$mask" );
  }

  my $xlist;
  foreach (@ufl) { push( @$xlist, ifilelist1($course, $uemail, $_ ) ); }
  return $xlist;
}

## student can list only instructor's published files
sub sfilelistall( $course, $uemail, $mask="*" ) {
  my $files= publicfiles($course, $uemail, $mask);

  my @sfiles;
  foreach (@$files) {
    my $tt= _ispublic($course, $_);
    push( @sfiles, [ $_, _ispublic($course, $_) ] );
  }
  return \@sfiles;
}

## student can list all own files
sub sownfilelist( $course, $uemail, $mask="*" ) {
  my @list= bsd_glob( "$var/courses/$course/$uemail/files/$mask" );
  (@list) or return ;
  foreach (@list) { s{$var/courses/$course/$uemail/files/}{}g; }
  return \@list;
}

## instructor can list all student files
sub filelistsfiles( $course, $inresponseto="*" ) {
  $course= _checkcname( $course );
  my @a= bsd_glob( "$var/courses/$course/*/files/$inresponseto.response.*" );
  return \@a; ## needs student id, so not _glob2last
}


## instructor can collect all student homework submissions
sub collectstudentanswers( $course, $filename ) {
  $course= _confirmsudoset( $course );
  $filename= _checkfilename($filename);

  my $retrievepattern= "$var/courses/$course/*\@*/files/$filename.response.*";
  my @filelist= bsd_glob( $retrievepattern );

  (@filelist) or return "";  ## no files yet;

  my $zip= Archive::Zip->new();

  _confirmnotdangerous($retrievepattern, "retrievepattern in fstudentcollect");
  my $ls=`ls -lt $retrievepattern`;
  $zip->addString( $ls, '_MANIFEST_' ); ## contains date info

  my $archivednames="";
  foreach (@filelist) {
    my $fname= $_; $fname=~ s{$var/courses/$course/}{};  $fname=~ s{/files/}{-};
    $zip->addFile( $_, $fname );  $archivednames.= " $fname ";
  }

  my $ofname="$var/courses/$course/instructor/files/$filename-".time().".zip";
  $zip->writeToFileNamed( $ofname );

  return $ofname;
}

################################################################


sub cptemplate( $course, $templatename ) {
  $course= _confirmsudoset( $course );

  (-e "$var/templates/") or die "templates not yet installed.";
  (-e "$var/templates/$templatename") or die "no template $templatename";

  my $count=0;
  foreach (bsd_glob("$var/templates/$templatename/*")) {
    (my $sname= $_) =~ s{.*/}{};
    (-e "$var/courses/$course/instructor/files/$sname") and next;  ## skip if already existing
    symlink($_, "$var/courses/$course/instructor/files/$sname") or die "cannot symlink $_ to $var/courses/$course/instructor/files/$sname: $!\n";
    ++$count;
  }
  return $count;
}

sub rmtemplates( $course ) {
  $course= _confirmsudoset( $course );

  my $count=0;
  foreach (bsd_glob("$var/courses/$course/instructor/files/*")) {
    (-l $_) or next;
    my $pointsto = readlink($_);
    if ($pointsto =~ m{$var/templates/}) { unlink($_) or die "cannot remove template link: $!\n"; ++$count; }
  }
  _cleandeadlines($course);
  return $count;
}



################################################################

=pod

=head2 Deadline interface.

deadlines are (empty) filenames in the filesystem

=cut

################################################################

sub filesetdue( $course, $filename, $when ) {
  $course= _confirmsudoset( $course );
  $filename= _checkfilename($filename);  # lowercase the filename and check against mischief

  my $srcfile= "$var/courses/$course/instructor/files/$filename";
  (-e $srcfile) or die "$srcfile does not exist";

  my $olddeadline= _ispublic($course, $filename);  ## can expire and remove dead deadlines, if any
  ($olddeadline) and unlink("$var/courses/$course/public/$filename.DEADLINE.$olddeadline");  ## we are updating, so wipe earlier prevailing (not necessarily expired) deadlines
  (bsd_glob("$var/courses/$course/public/$filename.DEADLINE.*")) and die "internal error---there was yet another deadline!\n";

  ($when =~ /^[0-9]+$/) or die "need reasonable deadline, not '$when'!\n";  ## expired could be 0 or earlier
  touch( "$var/courses/$course/public/$filename.DEADLINE.$when" );
  return $when;
}

sub _ispublic( $course, $filename ) {
  _cleandeadlines( $course, $filename );
  my @gf= bsd_glob("$var/courses/$course/public/$filename.DEADLINE.*");
  (@gf) or return 0;
  ($#gf<=0) or die "ispublic is written for one file only";
  (-e $gf[0]) or die "internal error: $gf[0] does not exist!";
  $gf[0] =~ s{.*DEADLINE\.([0-9]+)}{$1};
  return $gf[0];
}

sub publicfiles( $course, $uemail, $mask ) {
  _cleandeadlines($course);

  my @files= _glob2last( "$var/courses/$course/public/".(($mask eq "X") ? "*" : "$mask").".DEADLINE.*" );
  if ($mask eq "X") {  ## special!!!
    @files = grep { $_ !~ /^hw/i } @files;
    @files = grep { $_ !~ /\.equiz\.DEADLINE/i } @files;
  }
  foreach (@files) { s{\.DEADLINE\.[0-9]+$}{}; }
  return \@files;
}

## remove expired files
sub _cleandeadlines( $course, $basename="*" ) {
  foreach ( bsd_glob("$var/courses/$course/public/$basename.DEADLINE.*") ) {
    (-e $_) or next;  ## weird race condition; the link had already disappeared
    (my $deadtime=$_) =~ s{.*DEADLINE\.([0-9]+)}{$1};  # wipe everything before the deadline
    ($deadtime+0 == $deadtime) or die "internal error: deadline is not a number\n";
    if ($deadtime <= time()) { unlink($_); next; }  ## we had just expired
  }
}




################################################################

=pod

=head2 Logging and Tweeting interface.

=cut

################################################################

sub _logany( $ip, $course, $who, $msg, $file, $destdir=undef ) {
  (defined($who)) or die "please give a user name.  you gave undef at ".((caller(1))[3]);
  (($who =~ /instructor/)||($who =~ /\@/)) or die "who needs to identify user?  not ".($who||"nowho");
  # let's keep the full email address  $who =~ s/\@.*\b//;
  $msg =~ s{\t}{ }g;  $msg=~ s/[\n\r]//g;
  (defined($destdir)) or $destdir="$var/courses/$course";
  open(my $FLOG, ">>", "$destdir/$file"); print $FLOG $ip."\t".time()."\t".gmtime()."\t".$who."\t$msg\n"; close($FLOG);
}

sub superseclog( $ip, $who, $msg ) {
  _logany( $ip, 'auth', $who, $msg, 'auth.log', "$var/" );
}

sub seclog( $ip, $course, $who, $msg ) {
  _logany($ip, $course, $who, $msg, 'security.log');
}

sub tweet( $ip, $course, $who, $msg ) {
  sub randstring {
    my @chars = ("a".."z", "0".."9");
    $_=""; foreach my $i (1..8) { $_ .= $chars[rand @chars]; } return $_;
  }

  my $tweetfile= bsd_glob("$var/courses/$course/tweet.*")||("$var/courses/$course/tweet.log");
  (-e $tweetfile) or touch($tweetfile);
  $tweetfile =~ s{.*/}{};
  _logany($ip, $course, $who, $msg, $tweetfile);
  open(my $FLT, ">", "$var/courses/$course/lasttweet"); print $FLT "GMT ".gmtime()." $who $msg"; close($FLT);
}

sub showlasttweet( $course ) {
  (-e "$var/courses/$course/lasttweet") or return "";
  return "<div class=\"ltweet\">Last Tweet: ".slurp("$var/courses/$course/lasttweet")."</div>";
}


sub showtweets( $course ) {
  (my $tweetfile=bsd_glob("$var/courses/$course/tweet.*")) or return undef;
  return scalar slurp($tweetfile);
}

sub showseclog( $course ) {
  my $seclogfile= "$var/courses/$course/security.log";
  (-e $seclogfile) or return time()."\t".gmtime()."\tsystem\tno security log just yet\n";
  return scalar slurp($seclogfile);
}


################################################################

=pod

=head2 Equiz Backend Interface

=cut

################################################################

sub renderequiz( $course, $email, $equizname, $callbackurl ) {
  (defined($equizname)) or die "need a filename for equizmore.\n";
  my $equizcontent= fileread( $course, 'instructor', $equizname );  ## quizzes always belong to the instructor
  my $fullequizname= fullfilename( $course, 'instructor', $equizname );
  my $equizlength= length($equizcontent);

  my $executable= sub {
    my $loc=`pwd`; chomp($loc); $loc.= "/Model/eqbackend/eqbackend.pl";
    return $loc;
  } ->();

  my $secret= md5_base64( (-e "/usr/local/var/lib/dbus/machine-id") ? "/usr/local/var/lib/dbus/machine-id" : "/etc/machine-id" );
  ## must be same secret as in equizgrade()
  ## instead of this secret, we could use a line from /var/sylgrade/secrets.txt

  my $fullcommandline= "$executable $fullequizname ask $secret $callbackurl $email";
  _confirmnotdangerous($fullcommandline, "executable to render equiz");

  my $r= `$fullcommandline`;
  return $r;
}


################
## grading an equiz entails unencrypting it, counting up the score, saving the score, and presenting the correct solutions

sub equizgrade( $course, $uemail, $posttextashash ) {
  sub decryptdecode {
    use Crypt::CBC ;
    use MIME::Base64;
    use HTML::Entities;

    use Digest::MD5 qw(md5_base64);
    my $secret= md5_base64( (-e "/usr/local/var/lib/dbus/machine-id") ? "/usr/local/var/lib/dbus/machine-id" : "/etc/machine-id" );
    ## must be same secret as in renderequiz()
    ## instead of this secret, we could use a line from /var/sylgrade/secrets.txt

    my $cipherhandle = Crypt::CBC->new( -key => $secret, -cipher => 'Blowfish', -salt => '14151617' );

    my $step1 = decode_entities($_[0]);
    my $step2 = decode_base64($step1);
    my $step3= $cipherhandle->decrypt($step2);
    return $step3;
  }

  sub decodeall( $posttextashash ) {
    ## A S P are encrypted
    foreach ( keys %$posttextashash ) {
      (/^confidential$/) and $posttextashash->{$_} = decryptdecode($posttextashash->{$_});
      (/^[ASPQN]\-[0-9]+/) and $posttextashash->{$_} = decryptdecode($posttextashash->{$_});
    }
    return $posttextashash;
  }

  $posttextashash= decodeall($posttextashash);
  my ($conf, $fname, undef, undef, $referrer, $qemail, $time, $browser, $ignoredgradename, $eqlongname)= split(/\|/, $posttextashash->{confidential});
  ($conf eq 'confidential') or die "oh well, you don't know what confidential means";

  (my $gradename = $fname) =~ s{.*/}{};
  #  $gradename =~ s{\.equiz$}{};  ## an equiz is always named by its filename

  (lc($qemail) eq lc($uemail)) or die "Sorry, but $uemail cannot look at answers from $qemail";

  my $i=0; my $score=0; my @qlist;
  while (++$i) {
    sub isanum { return ($_[0] =~ /^\s*[0-9\.]+\s*/); }
    my $ia= $posttextashash->{"S-$i"};
    (defined($ia)) or last;
    (isanum($ia)) or
      die "sorry, but instructor answer S-$i is not numeric, but '$ia'";
    my $sa= $posttextashash->{"q-stdnt-$i"};
    (defined($sa)) or die "there is no student answer field for $i";
    (isanum($sa)) or die "sorry, but student answer q-stdnt-$i is not numeric, but '$ia'";
    my $answerdelta= abs($sa - $ia);
    my $precision= ($posttextashash->{"P-$i"})||0.01;

    ## the actual grading:
    $posttextashash->{'iscorrect'}= ($answerdelta < $precision);
    $score += $posttextashash->{'iscorrect'};
    push( @qlist, [ $posttextashash->{"N-$i"}, $posttextashash->{"Q-$i"}, $posttextashash->{"A-$i"}, $ia, $sa, $precision, $posttextashash->{'iscorrect'}?"Correct":"Incorrect" ])
  }
  --$i;

  ## instructor quiz results are never stored
  ## [1] we store the answered full hash to "$var/courses/$course/$uemail/files/$fname.$time.eanswer.yml"
  ## [2a] we store plain info to the student, $var/subdomain/$semail/equizgrades
  ##   [2b] we store grades via gradetaskadd, too.

  if (!(isinstructor($course, $uemail))) {
    my $ofname= "$var/courses/$course/$uemail/files/$gradename.$time.eanswer.yml";
#    (-e $ofname) and die "please do not answer the same equiz twice.  instead go back, refresh the browser to receive fresh questions, and submit then\n";
    _safewrite( $posttextashash, $ofname );  ## the content
    _storegradeequiz( $course, $uemail, $gradename, $eqlongname, $time, "$score / $i" );
  }

  ## to be read by equizanswerrender()
  return [ $i, $score, $uemail, $time, $gradename, $eqlongname, $fname, $posttextashash->{confidential}, \@qlist ];
}


##
sub _storegradeequiz( $course, $semail, $gradename, $eqlongname, $time, $grade, $optcontentptr=undef ) {
  ## $course= _confirmsudoset( $course );  ## sudo must have been called!

  $course= _checkcname( $course );  ## sudo must have been called!
  $semail= _checkemail($semail,$course);
  ($time > 0) or die "wtf is your quiz time?";
  ($time <= time()) or die "back to the future?!";

  (-d "$var/courses/$course/$semail/files") or die "bad directory:\n";
  (-w "$var/courses/$course/$semail/files") or die "non-writeable directory:\n";

  ## temporarily allow su privileges to add to grades, too
  my $psudo= $amsudo;
  $amsudo=1;
  gradetaskadd( $course, $gradename );
  my $rv=gradesave( $course, $semail, $gradename, $grade );
  $amsudo=$psudo;
  return $rv;
}

##
sub equizanswerrender( $decodedarray ) {
  ## from equizgrade()
  my ($numq, $ans, $uemail, $time, $gradename, $eqlongname, $fname, $confidential, $detail) = @$decodedarray;

  my $rv= "<p>Quiz <b>$eqlongname</b> results for $uemail.
           <p><b>Overall Result:</b> $ans correct responses for $numq questions</p>";
  $rv .= '

  <script type="text/javascript" async src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-MML-AM_CHTML"> </script>
    <script type="text/javascript"       src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS_HTML-full"></script>
    <script type="text/javascript" src="/js/eqbackend.js"></script>
    <link href="/css/eqbackend.css" media="screen" rel="stylesheet" type="text/css" />
    <link href="/css/input.css" media="screen" rel="stylesheet" type="text/css" />

    <style>
      p.qstntext::before {  content: "Question: "; font-weight: bold;  }
      p.qstntext::before {  content: "Question: "; font-weight: bold;  }
      p.qstnlong::before {  content: "Detailed: "; font-weight: bold;  }
      p.qstnshort::before {  content: "Correct Answer: "; font-weight: bold;  }
      p.qstnstudentsays::before {  content: "Your Answer: "; font-weight: bold;  }
      p.qstnscore::before {  content: "Counted As: "; font-weight: bold;  }
    </style>
    ';


  foreach (@{$detail}) {
    my $precision= $_[5] || "0.01";
    $rv .= qq(
       <div class="subpage">
          <div class="qname">$_->[0]</div>
          <div class="qstn">
           <p class="qstntext"> $_->[1] </p>
           <p class="qstnlong"> $_->[2] </p>
           <p class="qstnshort"> $_->[3] (+/- $precision)</p>
           <p class="qstnstudentsays"> $_->[4] </p>
           <p class="qstnscore"> $_->[6] </p>
       </div>
     </div>
);
  }
  return $rv;
}


################################################################

=pod

=head2 Utility Routines: 

* safe writing into the filesystem (with backup and yaml understanding)

* globbing

* checking filenames and filepaths

* checking email / enrollment

=cut

################################################################

## safewrite will first write a temporary file with the new content,
## then rename any old file to a backup first (including useless
## symlinks), and finally rename the two files appropriately.  if the
## file ends with yml, the content is written and read through
## yaml::tiny.  otherwise, it is just a plain file

sub _safewrite( $contentinfo, $filename ) {
  $filename= _checkfilepath($filename);

  (defined($contentinfo)) or die "need contentinfo to write!\n";

  if ($filename =~ /\.yml$/) {
    my $yamlofinfo= YAML::Tiny->new($contentinfo);
    $yamlofinfo->write($filename.".new") or die "cannot write replacement: $! --- aborted update/write\n";
  } else {
    open(my $FOUT, ">", $filename.".new") or die "cannot write replacement: $! --- aborted update/date\n"; print $FOUT $contentinfo; close($FOUT);
  }
  if (-e $filename) {
    if ($filename =~ /\.equiz$/) {
      (my $newfilename= $filename) =~ s{(.*)/(.*)}{$1/old-$2};
      rename($filename, $newfilename) or die "cannot rename existing file $filename to $newfilename: $!";
    } else {
      rename($filename, $filename.".old") or die "cannot rename existing file $filename to $filename.old: $!";
    }
  }
  return rename($filename.".new", $filename); ## this better work
}

sub _saferead( $filename ) {
  ## problem: the below will change Model/filename to model/filename, which
  ## works under osx, but not under linux;

  $filename= ($filename =~ m{^Model/[ubc]settings-schema\.yml}) ? $filename : _checkfilepath($filename);  ## do not uppercase

  ## the .yml extension is hardcoded
  if ($filename =~ /\.ya?ml$/) {
    (-e $filename) or return;
    return (YAML::Tiny->read($filename))->[0];
  }

  ## we will try to see if any of the following work, in order
  foreach my $ext ("", ".html", ".htm", ".pdf", ".txt", ".text", ".csv", ".doc") {
    (-e "$filename$ext") and return slurp("$filename$ext");
  }

  return (-e $filename);  ## not found
}


sub _glob2last( $globstring ) {
  return map { (my $foo = $_) =~ s{.*/}{}; $foo; } bsd_glob($globstring);
}

sub _glob2lastnoyaml( $globstring ) {
  return map { (my $foo = $_) =~ s{.*/}{}; $foo =~ s{\.ya?ml$}{}; $foo; } bsd_glob($globstring);
}

sub _checkfilename( $filename ) {
  defined($filename) or die "please provide a filename";
  ($filename eq "") and die "please provide a filename";
  ($filename =~ /^[\w\-\ ][\@\w\.\-\ ]*$/) or die "filename $filename contains bad characters; use only words, dashes, dots";
  return lc($filename);
}

sub _checkfilepath( $filepath ) {
  $filepath =~ s{/+}{/};
  ($filepath =~ m{[^\w]\.\.}) and die "filepath $filepath can have double dots only after a word character\n";
  return lc($filepath);
}


##
## validation of names and sites
##

sub _checkemail( $uemail, $course=undef ) {
  (defined($uemail)) or die "I have no idea who you are!\n";
  (length($uemail)<128) or die "email $uemail too long\n";
  (Email::Valid->address($uemail)) or die "email address '$uemail' could not possibly be valid\n";
  ($uemail =~ m{/}) and die "email $uemail cannot have slash in it!\n";
  ($uemail =~ m{\.\.}) and die "email $uemail cannot have consecutive dots!\n";
  $uemail= lc($uemail);

  if ((defined($course))&&($course ne "auth")) {
    $course= _checkcname($course);
    (-e "$var/courses/$course/$uemail") or die "user $uemail is not enrolled in course $course\n";
  }
  return $uemail;
}

sub _checkcname( $course ) {
  ($course =~ /^[\w][\w\.\-]*[\w]$/) or die "bad website name '$course'!\n";
  (-e "$var/courses/$course") or ($course eq "auth") or die "subdomain $course is unknown.\n";
  return lc($course);
}


## stuff we may pass into a system or backquote call
sub _confirmnotdangerous( $string, $warning ) {
  ($string =~ /\;\&\|\>\<\?\`\$\(\)\{\}\[\]\!\#\'/) and die "too dangerous: $warning fails!";  ## we allow '*'
  return $string;
}

1;
