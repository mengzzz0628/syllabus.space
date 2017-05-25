#!/usr/bin/env perl
package SylSpace::Controller::Enter;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(seclog student2instructor);
use SylSpace::Model::Controller qw(global_redirect standard global_redirectmsg unobscure);

################################################################

## this is a bit tricky.  on localhost, all sorts of browser cookie
## transfers fail.  thus, iff we are on localhost, we accept the query
## passed parameter.
##
## 

get '/enter' => sub {
  my $c = shift;

  my ($posttime,$postemail,$postexpiration)= split(/:/, unobscure($c->req->query_params->param("e")));
  my $timesincepostrequest= (time() - $posttime);
  #($timesincepostrequest<30) or die "Sorry, goclass entry requests always expire after 30 seconds (not $timesincepostrequest).\n";

  if ($ENV{'ONLOCALHOST'}) {
    ## do not yet check our site or email yet.  first transfer in our email.
    (defined($c->req->query_params->param("e"))) or die "need an e argument with secret info!\n";
    use Email::Valid;
    (Email::Valid->address($postemail)) or die "email address '$postemail' could not possibly be valid\n";
    $c->session->{expiration}= $postexpiration;
    $c->session->{uemail}= $postemail;
    $c->session->{ishuman}= time().":".$c->ession->{uemail};
  } else {
    (Email::Valid->address($c->session->{uemail})) or die "email address '".$c->session->{uemail}."' could not possibly be valid\n";
  }

  (($postexpiration - time()) > 60 ) or die "Sorry, but your expiration is almost here.  Please reauthorize or extend!\n";

  ## now we are ready for the rest of our work on this subdomain
  (my $subdomain = standard( $c )) or return global_redirect($c);

  ($subdomain eq "auth") and die "you cannot enter the /auth course --- it does not exist!\n";
  ## return $c->flash(message => 'auth likes only index')->redirect_to('/auth/index');  ## we cannot enter the auth course site

  ## unmorph if needed
  student2instructor( $subdomain, $c->session->{uemail} );  ## just make sure that we morph back if we were a morphed instructor
  seclog($c->tx->remote_address, $subdomain, $c->session->{uemail}||"no one", "entering course site $subdomain" );

  return $c->flash( message => "hello $postemail" )->redirect_to('/index');
};

1;
