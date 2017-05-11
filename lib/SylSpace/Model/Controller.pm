#!/usr/bin/env perl
package SylSpace::Model::Controller;

use base 'Exporter';
@ISA = qw(Exporter);

our @EXPORT_OK =qw(  standard global_redirect global_redirectmsg domain
		     timedelta epochof epochtwo timezones
		     btn btnsubmit btnblock btnxs
		     msghash2string ifilehash2table
		     drawform drawmore fileuploadform displaylog mkdatatable);

use strict;
use warnings;
use common::sense;
use utf8;
use warnings FATAL => qw{ uninitialized };
use autodie;

use feature ':5.20';
use feature 'signatures';
no warnings qw(experimental::signatures);

use Data::Dumper;

################################################################

=pod

=head1 Title

  Controller.pm --- routines used repeatedly in the controller.

=head1 Description

  this code must *not* be dependent on any backend model code.

  it contains common utility routines, and some longer routines
  that are used in multiple url's.

=head1 Versions

  0.0: Sat Apr  1 10:55:38 2017

=cut

################################################################
## basic routines used by most webpages
################################################################

my $global_redirecturl;
my $global_message;


## standard() should start every webpage.  it makes sure that we have
## a session uemail and expiration, and redirects nonsensible
## subdomains (course names) to /auth

sub standard {
  my $c= shift;

  if (!($c->session->{uemail})) {
    $global_redirecturl= '/auth'; $global_message= 'you have no (session) email yet.  please identify yourself';
    return;
  }

  if (time() > $c->session->{expiration}) {
    $global_redirecturl= '/auth'; $global_message= 'sorry, '.($c->{session}->{uemail}).', but your session has expired.  you have to reauthenticate';
    return;
  }

  my $subdomain= _subdomain($c);

  if (!($subdomain)) {
    $global_redirecturl= '/auth'; $global_message= "no subdomain for '".$c->req->url->to_abs->host."' in /index --- redirected to '/auth'"; return;
  }

  return $subdomain;
}


## we use global variables because M cannot redirect deep in
## the code.  so we set these global variables and return undef

sub global_redirectmsg {
  my $c= shift;
  return $global_message;
}

sub global_redirect {
  my $c= shift;
  $c->flash(message => $global_message);

  return $c->redirect_to($global_redirecturl);
}


################################################################

sub _subdomain( $c ) {
  my @f= split(/\./, $c->req->url->to_abs->host);
  (@f) or return;  ## never
  (pop(@f) ne "localhost") and pop(@f);  ## hehe --- pop again
  ($#f>=0) or return;
  return join('.', @f);
}

sub domain( $c ) {
  return domainfromurl($c->req->url->to_abs->host);
}

sub domainfromurl( $url ) {
  ($url =~ /localhost/) and return "localhost:3000";  ## this catches too many

  my @f= split(/\./, $url);
  (@f) or return;  ## should never happen, so this is an error return
  return $f[$#f-1].'.'.$f[$#f];
}


################################################################
## routines related to time
################################################################

## a nice English version of how much time is left
sub timedelta {
  my $x= ($_[1]||time()) - ($_[0]);
  sub tdt {
    my $ax= abs($_[0]);
    sub mm { return $_[0]." $_[1]".(($_[0]>1)?"s":""); }
    ($ax<60) and return mm($ax, "sec");
      ($ax<60*60) and return mm(int($ax/60), "min");
    ($ax<60*60*24) and return mm(int($ax/60/60*1.01), "hour");
    ($ax<60*60*24*7) and return mm(int($ax/60/60/24*1.01), "day");
    ($ax<60*60*24*31) and return mm(int($ax/60/60/24/7*1.01), "week");
    ($ax<60*60*24*365) and return mm(int($ax/60/60/24/30*1.01), "month");
    return mm(int($ax/60/60/24/365), "year");
  }
  ($x<0) and return "in ".tdt($x);
  return tdt($x)." ago";
}


################
## calculate the time difference between server GM and local time

sub _tziofserver {
  my $off_h=1;
  my @local=(localtime(time+$off_h*60*60));
  my @gmt=(gmtime(time+$off_h*60*60));
  return $gmt[2]-$local[2] + ($gmt[5] <=> $local[5]
			      ||
			      $gmt[7] <=> $local[7])*24;
}



################
## html date picker returns a date and time, but we want to store
## everything in epoch

sub epochof {
  my ($d1,$d2,$tzi)=@_;
  (defined($tzi)) or die "please set timezone";
  $d2 =~ s/%3A/:/g; ## if any
  ($d1 =~ /[12]\d\d\d\-[01]\d-\d\d/) or die "bad yyyy-mm-dd $d1\n";
  ($d2 =~ /[012]\d:[0-5]\d/) or die "bad hh:mm $d2\n";

  # ($tzi == (-7)) or die "wtf.  you should be in the -7 timezone, not $tzi";
  # $tzi*= (-1);  ## quoted as the opposite. gmt - local

  $tzi= sprintf("%s%02d:00", ($tzi>0)?"+":"-", abs($tzi));
  ($tzi =~ /[+-][01]\d:\d0/) or die "bad time zone int offset $tzi";
  my $p="${d1}T${d2}:00$tzi";

  my $e=Mojo::Date->new($p)->epoch;
  (defined($e)) or die "internal epochof conversion error from $d1, $d2, $tzi";
  return $e;
}


################
## returns an html table with four different versions of epoch time

sub _epochfour( $epoch, $tzi ) {
  ($epoch == 0) and return "no date yet";
  ($epoch >= 140000000) or die "nonsensible $epoch\n";

  my $duegmt=gmtime($epoch);
  my $dueserver=localtime($epoch);  ## GMT-07:00 DST
  my $dueuser= defined($tzi) ? gmtime($epoch+$tzi*60*60) : "n/a";
  my $gmtadd= (defined($tzi)) ? " GMT $tzi:00" : "";

  my $serveruser= ($dueuser eq $dueserver) ? 
    "<tr> <td>Server/User:&nbsp;</td> <td> $dueserver $gmtadd</td></tr>\n" :
    "<tr> <td>Server:&nbsp;</td> <td> $dueserver</td></tr>\n".
    "<tr> <td>User: </td> <td> $dueuser  $gmtadd</td> </tr>";

  return
    "<table style=\"font-family:monospace\">".
    "<tr> <td>Epoch: </td> <td><span class=\"epoch14\">$epoch</span></td> </tr>\n".
    "<tr> <td>GMT: </td> <td> $duegmt</td></tr>\n".
    $serveruser.
    "<tr> <td>Relative:&nbsp; </td> <td> ".timedelta( $epoch )."</td> </tr>".
    "</table>";
}


sub epochtwo( $epoch ) { qq(<span class="epoch0">$epoch</span> ).timedelta($epoch); }



################################################################
## button related drawing
################################################################

sub btn( $url, $text, $btntypes="btn-default", $extra="" ) {
  return qq(<a href="$url" class="btn $btntypes" $extra>$text</a>); }

sub btnsubmit {
  $_[3].= qq( type="submit" value="submit" ); return btn(@_); }

sub btnblock($url, $text, $belowtext="", $btntypes="btn-default", $textlength=undef) {
  if ($btntypes =~ 1) { $btntypes="btn-default", $textlength='n'; }
  my @w= ( 1, 2, 4, 4 );
  my $h= 'h2';
  if (defined($textlength)) {
    if ($textlength eq 'w') { @w = ( 1, 1, 2, 2 ); $h='h3'; }
    elsif ($textlength eq 'sw') { @w = ( 1, 1, 2, 2 ); $h='h4'; }
    elsif ($textlength eq 'n') { @w = ( 2, 2, 4, 4 ); }
    else { die "textlength argument should not be $textlength, but n or w\n"; }
  }
  foreach (@w) { $_ = 12/$_; }
  $belowtext= "<p>$belowtext</p>";


  ## Since grid classes apply to devices with screen widths greater than or equal to the breakpoint sizes (unless overridden by grid classes targeting larger screens), `class="col-xs-12 col-sm-12 col-md-6 col-lg-6"` is redundant and can be simplified to `class="col-xs-12 col-md-6"`
  return qq(<div class="col-xs-$w[0] col-md-$w[2]">).
    btn($url, "<$h>$text</$h>", "btn btn-block $btntypes")
    .$belowtext
    .'</div>';


  ## for short button text, we can do 2 for xs, 4 for sm 
  ## for normal button text, we want 1 for xs, 2 for sm, 4 for md and lg

  return qq(<div class="col-xs-$w[0] col-sm-$w[1] col-md-$w[2] col-lg-$w[3]">).
    btn($url, "<$h>$text</$h>", "btn btn-block $btntypes")
    .$belowtext
    .'</div>';
}




################################################################
## others, mostly used a few times in similar fashion
################################################################


## use this if you want to make a table sortable
sub mkdatatable {
  return '<script type="text/javascript" class="init">
    $(document).ready(function() {
       $(\'#'.$_[0].'\').DataTable( { "paging":false, "info":false  } );
    } );
  </script>'; }



################
## used by both student and instructor, this draws all messages at the
## top of their home page

sub msghash2string( $msgptr, $msgurlback, $listofread=undef, $tzformat=undef ) {
  (defined($msgptr)) or die "internal error";

  my %listofread;
  if ($listofread) {
    (ref($listofread) eq 'ARRAY') or die "bad input---we have a ".ref($listofread)."\n".Dumper($listofread);
    foreach (@$listofread) { $listofread{$_}=1; }
  }

  my $msgstring= '<div class="msgarea">';

  foreach (@$msgptr) {
    my $donotshowmarkreadagain="";
    if ($listofread) {
      $donotshowmarkreadagain= qq(
          <a href="$msgurlback?msgid=$_->{msgid}" class="btn btn-default btn-xs" style="font-size:x-small;color:black" > X do not show again</a>
);
    } else {
      $donotshowmarkreadagain = defined($listofread{$_->{msgid}}) ? "" : <<EOS;
          <a href="$msgurlback?msgid=$_->{msgid}" class="btn btn-default btn-xs" style="font-size:x-small;color:black" > X do not show again</a>
EOS
    }

    my $epoch= (defined($tzformat)) ? _epochfour($_->{time}, $tzformat) : epochtwo($_->{time});
    $msgstring .= <<EOM;
  <dl class="dl-horizontal" id="$_->{msgid}">
    <dt>msgid</dt> <dd class="msgid-msgid ">$_->{msgid} $donotshowmarkreadagain</dd>
    <dt>date</dt> <dd class="msgid-date">$epoch</dd>
    <dt>subject</dt> <dd class="msgid-subject" > $_->{subject}</dd>
    <dt></dt> <dd class="msgid-msg"> $_->{body}</dd>
  </dl>
EOM
  }
  return $msgstring .= "\n</div>\n";
}



################
## used by course and bio settings, this draws the html form

sub drawform {
  my ($readschema, $ciobio)= @_;

  my $rs= "";
  foreach (@{$_[0]}) {
    my @name=keys(%{$_}); my $name= $name[0];
    my %f= %{$_->{$name}};
    ($name eq 'defaults') and next;
    ($name eq 'email') and next;
    my $hstarrequired= ($f{required}) ? '*' : ' ';
    my $hpublic=($f{public}) ? '[public]' : '[undisclosed]';
    my $hreadonly= ($f{readonly}) ? 'readonly' : '';
    my $hrequired= ($f{required}) ? 'required' : '';
    my $hhtmltype= ($f{htmltype}) ? "type=\"$f{htmltype}\"" : '';
    my $hpattern= ($f{regex}) ? "pattern=\"$f{regex}\"" : "";
    my $hmaxsize= ($f{maxsize}) ? "maxsize=\"$f{maxsize}\"" : "";
    my $hvalue= ($f{value}) ? "value=\"$f{value}\"" : "";
    my $hplaceholder= ($f{placeholder}) ? "placeholder=\"$f{placeholder}\"" : "";

    ((defined($ciobio)) && (defined($ciobio->{$name}))) and $hvalue="value=\"$ciobio->{$name}\"";  ## override default with the preexisting value

    $rs.= qq(
	<div class="form-group">
	  <label class="col-sm-2 control-label col-sm-2" for="$name">${name}$hstarrequired</label>
	  <div class="col-sm-6">$hpublic
		<input class="form-control foo" id="$name" name="$name" $hhtmltype $hmaxsize $hvalue $hplaceholder $hrequired $hreadonly $hpattern />
	  </div>
        </div>
       );
  }
  return $rs;
}


################

sub drawmore($centertype, $actionchoices, $detail, $tzi) {
  my $fname= $detail->{filename};

  my $achoices= actionchoices( $actionchoices, $fname );

  my $changedtime= _epochfour( $detail->{mtime}||0, $tzi );
  my $delbutton= btn("delete?f=$fname", 'delete', 'btn-xs btn-danger');
  my $backbutton= btn($centertype."center", "back to ${centertype}center", 'btn-xs btn-default');

  my $dueyyyymmdd="";  my $duehhmm="23:59";
  if ($detail->{duetime}) {
    use POSIX qw(strftime);
    $dueyyyymmdd=  strftime('%Y-%m-%d', localtime($detail->{duetime}));
    $duehhmm=  strftime('%H:%M', localtime($detail->{duetime}));
  }
  my $duetimefour= _epochfour( $detail->{duetime}||0, $tzi );

  my $v= <<EOT;
  <table class="table">
    <thead> <tr> <th> variable </th> <th> value </th> </tr> </thead>
    <tbody>
	<tr> <th> file name </th> <td> $fname </td> </tr>
	<tr> <th> file size</th> <td> $detail->{filelength} bytes </td> </tr>
	<tr> <th> changed </th> <td> $changedtime </td> </tr>
	<tr> <th> action </th> <td> $achoices </td> </tr>
	<tr> <th> visible until </th> <td> $duetimefour
			<p>
			<form method="get" action="setdue?f=$fname" class="form-inline">
			<input type="hidden" name="f" value="$fname" />
			User Time: <input type="date" id="duedate" name="duedate" value="$dueyyyymmdd" onblur="submit();" />
			<input type="time" id="duetime" name="duetime" value="$duehhmm" />
			<input type="submit" id="submit" value="change or tab out to set" class="btn btn-xs btn-default" />
			</form>
	   </td> </tr>
	<tr> <th> delete </th> <td> $delbutton </td> </tr>
	<tr> <td colspan="2"> $backbutton </td> </tr>
    </tbody>
  </table>
EOT
}

################
## used by "*more" for inspection of files

sub ifilehash2table( $filehashptr, $actionchoices, $type, $tzi ) {
  defined($filehashptr) or return "";
  my $filestring= '';
  my $counter=0;
  foreach (@$filehashptr) {
    ++$counter;
    my $fq= "f=$_->{filename}";

    my $thisduedate= epochtwo($_->{duetime});
    my $thismdfddate= epochtwo($_->{mtime});

    my $publish=($_->{duetime}) ? qq(<a href="${type}more?$fq"> $thisduedate </a>) :
      qq(<a href="${type}more?$fq"  class="btn btn-primary btn-xs">Publish</a>);

    my $achoices= actionchoices( $actionchoices, $_->{filename} );

    $filestring .= qq(
    <tr class="published">
	<td class="c">$counter</td>
	<td class="c"> $publish </td>
	<td> <a href="${type}more?$fq">$_->{filename}</a> </td>
	<td class="int" style="text-align:right"> $_->{filelength} </td>
	<td class="c"> $thismdfddate </td>
        <td class="c"> $achoices </td>
	<td class="c"> <a href="${type}more?$fq" class="btn btn-default btn-xs">more</a> </td>
     </tr>)
  }

  return mkdatatable('taskbrowser').<<EOT;

  <table id="taskbrowser" class="table">
    <thead>
      <tr>
        <th class="c">#</th><th class="c">public until</th><th class="c">$type name</th><th class="c">bytes</th><th class="c">modfd</th><th class="c">actions</th> <th class="c">more</th>
     </tr>
    </thead>

    <tbody>
       $filestring
    </tbody>
  </table>
EOT
}


sub actionchoices( $actionchoices, $fname ) {
  my $selector= {
		 equizrun => btn("equizrun?f=$fname", 'run', 'btn-xs btn-default'),
		 view => btn("view?f=$fname", 'view', 'btn-xs btn-default'),
		 download => btn("download?f=$fname", 'download', 'btn-xs btn-default'),
		 edit => btn("edit?f=$fname", 'edit', 'btn-xs btn-default') };

  my $achoices=""; foreach (@$actionchoices) { $achoices.= " ".$selector->{$_}; }
  return $achoices;
}


################
## used by all file-related centers (hw, equiz, file)

sub fileuploadform {
return '
   <form action="/upload" id="uploadform" method="post" enctype="multipart/form-data" style="display:block">
     <label for="idupload">Upload A New File: </label>
     <input type="file" name="uploadfile" id="idupload" style="display:inline"  >
   </form>
  <ul style="margin-left:5em;font-size:smaller">
  <li> any file starting with <tt>hw</tt> is considered to be a <a href="/instructor/hwcenter">homework</a>,</li>
  <li> any file ending with <tt>.equiz</tt> is considered to be an <a href="/instructor/equizcenter">equiz</a>,</li>
  <li> and any other file (e.g., <tt>syllabus.html</tt>) is considered just a <a href="/instructor/filecenter">file</a>.</li>
  </ul>

   <script>
      document.getElementById("idupload").onchange = function() {
         document.getElementById("uploadform").submit();
      }
   </script>
 ';
}

################
## used for both tweeting and security logs, displays a nice
## html version of a log file.

sub displaylog( $logptr ) {

  my $s="";
  foreach (split(/\n/, $logptr)) {
    my ($epoch, $gmt, $who, $what)=split(/\t/,$_);
    $s.= "<tr> <td>".epochtwo($epoch)."</td> <td> $gmt </td> <td>$who</td> <td>$what</td> </tr>";
  };

  return mkdatatable('seclogbrowser').<<LOGT;
   <table class="table" id="seclogbrowser">
      <thead> <tr> <th> Epoch </th> <th> GMT </th> <th> Who </th> <th> What </th> </tr> </thead>
      <tbody>
       $s
     </tbody>
   </table>
LOGT
}

################################################################

1;
