#!/usr/bin/env perl
package SylSpace::Controller::AuthEmailer;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(superseclog);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

use Mojo::JWT;

use Email::Sender::Simple 'try_to_sendmail';
use Email::Sender::Transport::SMTP::TLS;
use Email::Simple::Creator;

post '/auth/sendmail/authenticate' => sub {
  my $c = shift;

  my $name = $c->param('name');
  my $email = $c->param('email');

  if (!$name or !$email) {
    return $c->stash(error => 'Missing required parameter' )->render(template => 'AuthEmailer');
  }

  if (_send_email($c, $email, $name)) {
    return $c->stash(error => '')->render(template => 'AuthEmailer');
  }

  $c->stash(error => 'Failed to send email')->render(template => 'AuthEmailer');
};

get '/auth/sendmail/callback' => sub {
  my $c = shift;

  my $jwt = $c->param('jwt');
  my $params = _jwt($c)->decode($jwt);

  my $name = $params->{name};
  my $email = $params->{email};

  superseclog( $c->tx->remote_address, $email, "got email callback for $name and $email" );

  if ($name and $email) {
    $c->session(uemail => $email, name => $name)->redirect_to('/index');
  } else {
    $c->stash(error => 'Missing required parameter')->render(template => 'AuthEmailer');;
  }
};

sub _getTransport {
  my $c = shift;

  return $c->{_transport} ||= Email::Sender::Transport::SMTP::TLS->new(
    %{ $c->app->plugin('Config')->{email}{transport} }
  );
}

sub _jwt {
  return Mojo::JWT->new(secret => shift->app->secrets->[0]);
}

sub _send_email {
  my ($c, $email, $name) = @_;
  my $config = $c->app->plugin('Config');

  my $jwt = _jwt($c)->claims({name => $name, email => $email})->encode;
  my $url = $c->url_for('/auth/sendmail/callback')->to_abs->query(jwt => $jwt);

  my $message = Email::Simple->create(
    header => [
      From    => $config->{email}{message}{from},
      To      => $c->param('email'),
      Subject => 'Confirm your email',
    ],
    body => "Follow this link: $url",
  );

  say $c->param('email');

  return try_to_sendmail($message, { transport => _getTransport($c) });
}

1;

################################################################

__DATA__

@@ AuthEmailer.html.ep

%title 'Sent Email For Identity Confirmation';
%layout 'auth';

<% use SylSpace::Model::Controller qw(domain); %>

<main>

% if ($error) {
  <h2>ERROR: Email was NOT sent</h2>
  <p>
    <%= $error %>
  </p>
% } else {
  <h2>Email was sent</h2>
    % }

  <p>
  Please check your mailbox for a confirmation email with link.  If you do not receive an email from us within 5-10 minutes, check for any spam filters along the way.  Whitelist 'syllabus.space@gmail.com'.

  <p><b>Warning:</b> Some email spam filters may be blocking us.  Make sure to whitelist us.  Here is more information on <a href="http://onlinegroups.net/blog/2014/02/25/how-to-whitelist-an-email-address/">whitelisting</a> us (e.g., <a href="http://smallbusiness.chron.com/whitelist-domain-office-365-74321.html">office365</a> and <a href="https://support.microsoft.com/en-us/kb/2545137">office365</a>)?  If you never receive an email&mdash;even after having whitelisted us&mdash;then please try a gmail account.  We know that gmail can receive our emails.</p>

  <hr />

  <p>Note that when you click on the link in your email, it should invoke the same internet browser that you are using now.   Your authentication is browser-specific, not computer-specific!</p>

</main>


