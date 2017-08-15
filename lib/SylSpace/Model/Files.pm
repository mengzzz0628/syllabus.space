#!/usr/bin/env perl
package SylSpace::Model::Files;

use base 'Exporter';
@ISA = qw(Exporter);

our @EXPORT_OK=qw(
  eqsetdue hwsetdue
  collectstudentanswers

  eqsetdue eqlisti eqlists eqwrite eqreads eqreadi
  filesetdue filelisti filelists filereadi filereads filewrite filedelete fileexistsi fileexistss
  hwsetdue hwlisti hwlists hwreadi hwreads hwwrite hwdelete
  answerlists answerread answerwrite answerlisti answercollect answerhashs

  longfilename

  cptemplate rmtemplates listtemplates
);

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

use Data::Dumper;
use Perl6::Slurp;
use File::Copy;
use File::Glob qw(bsd_glob);
use File::Touch;
use Email::Valid;

use Scalar::Util::Numeric qw(isint);


use lib '../..';
use SylSpace::Model::Utils qw( _getvar _confirmsudoset _checksfilenamevalid _checkemailvalid _burpnew);

my $var= _getvar();

################################################################################################################################

=pod

=head2 File interface. 

instructors can store and read all files.  students can only read
published instructor files, plus own files that they have uploaded.

=cut

################################################################

sub longfilename( $course, $sfilename ) {
  $course= _checksfilenamevalid( $course );
  $sfilename= _checksfilenamevalid( $sfilename );
  return "$var/courses/$course/instructor/files/$sfilename";
}

## note: returns not a list, but a listptr
sub filelisti( $course, $mask="*") {
  $course= _checksfilenamevalid( $course );
  my $ilist= _deeplisti("$var/courses/$course/instructor/files/$mask");
  (rlc($ilist)>0) or return $ilist;
  my @slist; foreach (@$ilist) { push(@slist, $_); }  ## always open!
  return \@slist;
}

## note: returns not a list, but a listptr
sub filelists( $course, $mask="*") {
  $course= _checksfilenamevalid( $course );
  my $ilist= _deeplisti("$var/courses/$course/instructor/files/$mask");

  (rlc($ilist)>0) or return $ilist;

  my @slist; foreach (@$ilist) {
    if ($mask ne '*.equiz') { ($_->{sfilename} =~ /.equiz$/) and next; } ## unless specifically requested, we do not display equizzes in the file list
    if ($mask ne 'hw*') { ($_->{sfilename} =~ /^hw$/) and next; } ## or homeworks
    (time() <= ($_->{duetime})) and push(@slist, $_);
  }
  return \@slist;
}

sub filereadi( $course, $filename) {
  $course= _confirmsudoset( $course );  ## lc()
  _checksfilenamevalid($filename);
  my $lfnm="$var/courses/$course/instructor/files/$filename";

  (-l $lfnm) and $lfnm= readlink($lfnm);
  return slurp $lfnm;  ## does not like symlinked files
}


sub filereads( $course, $filename, $equizspecial=0) {
  $course= _checksfilenamevalid($course);
  _checksfilenamevalid($filename);
  my $lfnm="$var/courses/$course/instructor/files/$filename";
  (time() >= _finddue( $lfnm )) and die "sorry, but there is no (longer) $lfnm";
  if (!$equizspecial) { ($filename =~ /\.equiz/) and die "sorry, but we never show off equiz source to students"; }
  (-l $lfnm) and $lfnm= readlink($lfnm);
  return slurp $lfnm;
}


sub filewrite( $course, $filename, $filecontents ) {
  $course= _confirmsudoset( $course );  ## lc()
  _checksfilenamevalid($filename);
  return _maybeoverwrite( "$var/courses/$course/instructor/files/$filename", $filecontents );
}


sub filedelete( $course, $sfilename ) {
  $course= _confirmsudoset( $course );  ## lc()
  $sfilename =~ s{$var/courses/$course/instructor/files/}{};
  _checksfilenamevalid($sfilename);
  my $lfilename = "$var/courses/$course/instructor/files/$sfilename";
  (-e $lfilename) or die "cannot delete non-existing $lfilename";
  unlink($lfilename)
}


################################################################
sub hwsetdue( $course, $hwname, $epoch ) { return filesetdue( $course, $hwname, $epoch ); }
sub hwlisti( $course ) { return filelisti( $course, "hw*" ); }
sub hwlists( $course ) { return filelists( $course, "hw*" ); }
sub hwreadi( $course, $hwname ) { ($hwname =~ /^hw/) or die "hwreadi: '$hwname' must start with hw\n"; return filereadi( $course, $hwname ); }
sub hwreads( $course, $hwname ) { ($hwname =~ /^hw/) or die "hwreads: '$hwname' must start with hw\n"; return filereads( $course, $hwname ); }
sub hwwrite( $course, $hwname, $hwcontents ) { ($hwname =~ /^hw/) or die "hwwrite: '$hwname' must start with hw\n"; return filewrite( $course, $hwname, $hwcontents ); }
sub hwdelete( $course, $hwname ) { ($hwname =~ /^hw/) or die "hwdelete: '$hwname' must start with hw\n"; return filedelete( $course, $hwname ); }
#sub hwrate( $course, $hwname, $rating ) { ($hwname =~ /^hw/) or die "hwrate: '$hwname' must start with hw\n"; return filerate( $course, $hwname, $rating ); }

################################################################################################################################

sub eqsetdue( $course, $eqsymname, $epoch ) { ($eqsymname=~ /\.equiz[\~]*/) or die "eqsymsetdue: $eqsymname must end with .equiz"; return filesetdue( $course, $eqsymname, $epoch ); }
sub eqlisti( $course ) { return filelisti( $course, "*.equiz" ); }
sub eqlists( $course ) { return filelists( $course, "*.equiz" ); }
sub eqreadi( $course, $eqsymname ) { ($eqsymname=~ /\.equiz[\~]*/) or die "eqsymreadi: $eqsymname must end with .equiz"; return filereadi( $course, $eqsymname );  }
sub eqreads( $course, $eqsymname ) { ($eqsymname=~ /\.equiz[\~]*/) or die "eqsymreads: $eqsymname must end with .equiz"; return filereads( $course, $eqsymname, 1 ); }
sub eqwrite( $course, $eqsymname, $eqsymcontents ) { ($eqsymname=~ /\.equiz[\~]*/) or die "eqsymreads: $eqsymname must end with .equiz"; return filewrite( $course, $eqsymname, $eqsymcontents ); }
sub eqdelete( $course, $eqsymname ) { ($eqsymname =~ /^eqsym/) or die "eqsymdelete: $eqsymname must end with .equiz\n"; return filedelete( $course, $eqsymname ); }

################################################################################################################################

sub answerhashs( $course, $uemail ) {
  my @list= bsd_glob("$var/courses/$course/$uemail/files/*\~answer\=*");
  my %rh;
  foreach (@list) {
    m{$var/courses/$course/$uemail/files/(.*)\~answer\=(.*)};
    (defined($2)) or next;  # or error
    $rh{$2}=$1;
  }
  return \%rh;
}

sub answerlists( $course, $uemail, $mask="*" ) {
  $course= _checksfilenamevalid( $course );
  $uemail= _checkemailvalid($uemail);
  (-e "$var/courses/$course/$uemail/") or die "answerlists: $uemail is not enrolled in $course";
  my $ilist= _deeplisti("$var/courses/$course/$uemail/files/$mask");
}

sub answerread( $course, $uemail, $ansname ) {
  $course= _checksfilenamevalid( $course );
  $uemail= _checkemailvalid($uemail);
  (-e "$var/courses/$course/$uemail/") or die "answerread: $uemail is not enrolled in $course";
  _checksfilenamevalid($ansname);
  return slurp( (bsd_glob("$var/courses/$course/$uemail/files/*$ansname*"))[0] );
}

sub answerwrite( $course, $uemail, $hwname, $ansname, $anscontents ) {
  $course= _checksfilenamevalid( $course );
  $uemail= _checkemailvalid($uemail);
  (-e "$var/courses/$course/$uemail/") or die "answerwrite: $uemail is not enrolled in $course";

  _checksfilenamevalid($ansname);
  _checksfilenamevalid($hwname);
  (-e bsd_glob("$var/courses/$course/instructor/files/$hwname"))
    or die "instructor has not posted a homework starting with $hwname";
  my $rv= _maybeoverwrite( "$var/courses/$course/$uemail/files/$ansname", $anscontents );
  touch( "$var/courses/$course/$uemail/files/$ansname~answer=$hwname" );

  return $rv;
}

sub answerlisti( $course, $hwname ) {
  $course= _checksfilenamevalid( $course );
  _checksfilenamevalid($hwname);

  my $retrievepattern="$var/courses/$course/*@*/files/*answer=$hwname";
  my @filelist= bsd_glob($retrievepattern);
  (@filelist) or return "";  ## no files yet;
  return \@filelist;
}

sub answercollect( $course, $hwname ) {
  $course= _checksfilenamevalid( $course );
  _checksfilenamevalid($hwname);

  my $retrievepattern="$var/courses/$course/*@*/files/*answer=$hwname";
  my @filelist= bsd_glob($retrievepattern);
  (@filelist) or return "";  ## no files yet;

  my $zip= Archive::Zip->new();
  my $ls=`ls -lt $retrievepattern`;
  $zip->addString( $ls, '_MANIFEST_' ); ## contains date info

  my $archivednames="";
  foreach (@filelist) {
    my $fname= $_; $fname=~ s{$var/courses/$course/}{};  $fname=~ s{/files/}{-};
    $zip->addFile( $_, $fname );  $archivednames.= " $fname ";
  }

  my $ofname="$var/courses/$course/instructor/files/$hwname-answers-".time().".zip";
  $zip->writeToFileNamed( $ofname );
  return $ofname;
}


################################################################
## TEMPLATES
################################################################

sub listtemplates( ) {
  my @list= bsd_glob("$var/templates/*");
  foreach (@list) { s{$var/templates/}{}; }
  return \@list;
}


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
  return $count+1; ## not to give an error!
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

sub fileexistsi( $course, $fname ) {
  return (-e "$var/courses/$course/instructor/files/$fname");
}

sub fileexistss( $course, $fname ) {
  return (-e "$var/courses/$course/instructor/files/$fname");  ## bug
}

sub filesetdue( $course, $filename, $when ) {
  $course= _confirmsudoset( $course );
  _checksfilenamevalid($filename);
  return _deepsetdue( $when, "$var/courses/$course/instructor/files/$filename");
}

#
# sub _ispublic( $course, $sfilename ) {
#   _cleandeadlines( $course, $sfilename );
#   my @gf= bsd_glob("$var/courses/$course/public/$sfilename.DEADLINE.*");
#   (@gf) or return 0;
#   ($#gf<=0) or die "ispublic is written for one file only";
#   (-e $gf[0]) or die "internal error: $gf[0] does not exist!";
#   $gf[0] =~ s{.*DEADLINE\.([0-9]+)}{$1};
#   return $gf[0];
# }
# 
# 
# sub publicfiles( $course, $uemail, $mask ) {
#   _cleandeadlines($course);
# 
#   my @files= _glob2last( "$var/courses/$course/public/".(($mask eq "X") ? "*" : "$mask").".DEADLINE.*" );
#   if ($mask eq "X") {  ## special!!!
#     @files = grep { $_ !~ /^hw/i } @files;
#     @files = grep { $_ !~ /\.equiz\.DEADLINE/i } @files;
#   }
#   foreach (@files) { s{\.DEADLINE\.[0-9]+$}{}; }
#   return \@files;
# }
# 
# ## remove expired files
# sub _cleandeadlines( $course, $basename="*" ) {
#   foreach ( bsd_glob("$var/courses/$course/public/$basename.DEADLINE.*") ) {
#     (-e $_) or next;  ## weird race condition; the link had already disappeared
#     (my $deadtime=$_) =~ s{.*DEADLINE\.([0-9]+)}{$1};  # wipe everything before the deadline
#     ($deadtime+0 == $deadtime) or die "internal error: deadline is not a number\n";
#     if ($deadtime <= time()) { unlink($_); next; }  ## we had just expired
#   }
# }
#



################################################################################################################################
## files utility subroutines
################################################################
sub _deeplisti( $globfilename ) {
  ## does not check whether you are an su.  so don't return carelessly
  my @filelist;
  foreach (bsd_glob("$globfilename")) {
    my %parms;
    ($_ =~ /\~/) and next;  ## these are meta files!
    ($parms{sfilename}= $_) =~ s{.*/}{};
    $parms{lfilename}= $_;
    $parms{filelength}= -s $_;
    $parms{mtime}= ((stat($_))[9]);
    $parms{duetime}= _finddue($_);
    (_findanswer($_)) and $parms{answer}= _findanswer($_);
    push(@filelist, \%parms);
  }
  return \@filelist;
}


sub _deepsetdue( $epoch, $lfilename ) {
  isint($epoch) or die "cannot set due date to non-int epoch $epoch";
  (($epoch==0)||($epoch>=time()-10)) or die "useless to set expiration to the past ($epoch) now=".time().".  use 0 for notpublic.";
  ((-l $lfilename) || (-e $lfilename)) or die "cannot set due date for non existing file $lfilename";
  foreach (bsd_glob("$lfilename\~due=*")) { unlink($_); }
  touch("$lfilename\~due=$epoch");
  return $epoch||1;  ## to signal non-failure if epoch is 0!
}


sub _finddue( $lfilename ) {
  ((-l $lfilename) || (-e $lfilename)) or die "cannot read due date for non-existing file $lfilename";

  my @duelist= bsd_glob("$lfilename\~due=*");
  (@duelist) or return 0;
  (my $f= $duelist[0]) =~ s{.*\~due=}{};
  (isint($f)) or die "invalid due date $f for $lfilename";
  return $f;
}

sub _findanswer( $lfilename ) {
  ((-l $lfilename) || (-e $lfilename)) or die "cannot read due date for non-existing file $lfilename";

  my @duelist= bsd_glob("$lfilename\~answer=*");
  (@duelist) or return 0;
  (my $f= $duelist[0]) =~ s{.*\~answer=}{};
  return $f;
}


## this is a safe backup-and-replace function
sub _maybeoverwrite( $lfilename, $contents ) {
  (-e $lfilename) or return _burpnew( $lfilename, $contents );

  _burpnew( "$lfilename.new", $contents );

  use File::Compare;
  if (compare($lfilename, "$lfilename.new") == 0) {
    unlink("$lfilename.new");
    return 0;  ## signal that no replacement was necessary
  }

  copy($lfilename, "$lfilename\~") or die "cannot rename existing file $lfilename to $lfilename~: $!";
  rename("$lfilename.new", "$lfilename") or die "cannot rename new file $lfilename.new to become $lfilename: $!";
  return length($contents);
}



sub rlc { return scalar @{$_[0]}; }

