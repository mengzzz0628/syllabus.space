#!/usr/bin/env perl
package SylSpace::Controller::AuthAuthenticator;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(superseclog);
use SylSpace::Model::Controller qw(global_redirect standard);


sub logandreturn {
  my ( $self, $email, $name, $authenticator ) = @_;
  superseclog($self->tx->remote_address, $email, "logging in $email ($name) via $authenticator" );
  $self->session(uemail => $email, name => $name, expiration => time()+60*60); ## one hour default
  return $self->redirect_to('/index');
}

sub google {
  my ( $self, $access_token, $userinfo ) = @_;
  my $name = $userinfo->{displayName};
  ## dani did this: my $emailptr = grep {$_->{type} eq 'account'} @{ $userinfo->{emails} };
  my $email = $userinfo->{emails}->[0]->{value};
  return logandreturn( $self, $email, $name, 'google' );
}

sub github {
  my ( $self, $access_token, $userinfo ) = @_;

  (defined($userinfo->{email})) or die "sadly, you have not confirmed your email with github, so you cannot use it to confirm it.\n";

  return logandreturn( $self, $userinfo->{email}, $userinfo->{name}, 'github' );
}

sub facebook {
  my ( $self, $access_token, $userinfo ) = @_;

  my $ua  = Mojo::UserAgent->new;
  my $res = $ua->get("https://graph.facebook.com/me?fields=name,email&access_token=$access_token")->result->json;

  if (!$res->{email}) {
    return $self->render(text => "Can't get your email from facebook, please try another auth method.");
  }

  return logandreturn( $self, $res->{email}, $res->{name}, "facebook");
}

################################################################

get '/auth/authenticator' => sub {
  my $c = shift;

  (my $subdomain = standard( $c )) or return global_redirect($c);

  ## sudo( $subdomain, $c->session->{uemail} );

  $c->render(template => 'AuthAuthenticator' );
};


1;

################################################################

__DATA__

@@ AuthAuthenticator.html.ep

%title 'Authenticate Your Email Identity';
%layout 'auth';

<% use SylSpace::Model::Controller qw(domain); %>
<% use SylSpace::Model::Controller qw(btnblock); %>

<main>

<hr />

<nav>

   <div class="row top-buffer text-center">
     <%== btnblock('/auth/google/authenticate', '<i class="fa fa-google"></i> Google', 'Your Gmail ID') %>
     <%== btnblock('/auth/github/authenticate', '<i class="fa fa-github"></i> Github', 'Your Github ID<br />Disabled Until Approved', 'btn-disabled') %>
     <%== btnblock('/auth/facebook/authenticate', '<i class="fa fa-facebook"></i> Facebook', 'Your Facebook ID<br />Disabled Until Approved', 'btn-disabled') %>
     <%== btnblock('/auth/ucla/authenticate', '<i class="fa fa-university"></i> UCLA', 'Your UCLA ID<br />Disabled Until Approved', 'btn-disabled') %>

  </div>

  <hr />

  <div class="row">
    <form name="registration" method="post" action="/auth/sendmail/authenticate">

   <div class="col-md-3">
         <div class="input-group">
            <span class="input-group-addon">Name: <i class="fa fa-user"></i></span>
           <input type="text" class="form-control" placeholder="joe schmoe" name="name" required />
         </div>
   </div>

   <div class="col-md-3">
         <div class="input-group">
            <span class="input-group-addon">Email: <i class="fa fa-email"></i></span>
            <input class="form-control" placeholder="joe.schmoe@ucla.edu" name="email" type="email" required />
         </div>
    </div>

     <div class="col-md-1">
          <div class="input-group">
             <button class="btn btn-default" type="submit" value="submit">Send Authorization Email</button>
          </div>
      </div>

      </form>
    </div> <!-- row -->

</nav>

  <hr />

<p>Advice: Sendmail only wakes up every minute or so.  It may take 0-5 minutes for an email to arrive in your mailbox, provided some spam filter did not catch it along the way.  Our recommendation is to use the direct authentication buttons whenever you can.</p>

<hr />

</main>
