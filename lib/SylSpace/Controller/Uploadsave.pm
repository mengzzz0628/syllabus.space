#!/usr/bin/env perl
package SylSpace::Controller::Uploadsave;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(filewrite isinstructor tweet seclog);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################
  # $app    = $app->max_request_size(16777216);

post '/uploadsave' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  return $c->render(text => 'File is too big for M', status => 200) if $c->req->is_limit_exceeded;

  my $uploadfile = $c->param('uploadfile');
  (defined($uploadfile)) or die "confusing not to see an upload file.";
  my $hwmatch = $c->param('hwtask');

  my $filesize = $uploadfile->size;
  my $filename = $uploadfile->filename;
  #  my $filecontents = $uploadfile->asset->{content};  ## could be done more efficiently by working with the diskfile
  my $filecontents = $uploadfile->asset->slurp();  ## could be done more efficiently by working with the diskfile

  # Check file size by instructor type
  ## (isinstructor($course, $c-session->{uemail}) or return $c->render(text => 'File is too big for s', status => 200) if ($filesize>1024*1024*16);

  my $infiletype= ($filename =~ m{^hw}i) ? 'hw' : ($filename =~ m{\.equiz$}i) ? 'equiz' : 'file';  # to
  my $referto;
  if (isinstructor( $course, $c->session->{uemail})) {
    ## an instructor can upload anything
    filewrite($course, $c->session->{uemail}, $filename, $filecontents);
    seclog( $c->tx->remote_address, $course, 'instructor ', $c->session->{uemail}." uploaded ". $filename );  ## student uploads are public
    $referto= "/instructor/${infiletype}center";

    ($filename =~ /^syllabus\./i) and filesetdue( $course, $filename, time()+60*60*24*365 );  ## special rule: make syllabus available for 1 year
    ($filename =~ /^faq\./i) and filesetdue( $course, $filename, time()+60*60*24*365 );  ## special rule: make syllabus available for 1 year

  } else {
    (eval { filewrite($course, $c->session->{uemail}, $filename, $filecontents, $hwmatch) }) or die "Problem : $@";
    tweet($c->tx->remote_address, $course, $c->session->{uemail}, " uploaded ".$filename." in response to $hwmatch" );  ## student uploads are public
    $referto= "/student/hwcenter";
  }

  my $extra= ($c->req->headers->referrer !~ /$infiletype/) ? " and had to switch center" : "";

  $c->flash( message => "squirreled away $infiletype '$filename' ($filesize bytes) $extra" )->redirect_to($referto);
};

1;