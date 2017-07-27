#!/usr/bin/perl
package SylSpace::Controller::PaypalHandler;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use LWP::UserAgent 6;
use Email::Sender::Simple 'sendmail';
use Email::Sender::Transport::SMTP::TLS;
use Email::Simple::Creator;


post  '/paypalreturndata' => sub {
        my $c = shift;

	# read post from PayPal system and add 'cmd'
	my $query = $c->req->params;	
	my $qs = "cmd=_notify-validate&".$query;
	$c->rendered(200);

	# post back to PayPal system to validate
	my $ua = new LWP::UserAgent;
	# Produciton URL
	my $req = HTTP::Request->new('POST', 'https://ipnpb.paypal.com/cgi-bin/webscr');
	# Sandbox URL
	#my $req = HTTP::Request->new('POST', 'https://ipnpb.sandbox.paypal.com/cgi-bin/webscr');
	$req->content_type('application/x-www-form-urlencoded');
	$req->header(Host => 'www.paypal.com');
	$req->content($qs);	
	my $res = $ua->request($req);

	if ($res->is_error) {
		# HTTP error
		_log_paypal_error($res);
	}
	elsif ($res->content eq 'VERIFIED') {
	 # check the $payment_status=Completed
	 # check that $txn_id has not been previously processed
	 # check that $receiver_email is your Primary PayPal email
	 # check that $payment_amount/$payment_currency are correct
	 # process payment
        my $status = $c->param('payment_status');
		if($status eq 'Completed') {
			_log_paypal_info($query);		
			_send_email($c);
		}		
	}
	elsif ($res->content eq 'INVALID') {
	 # log for manual investigation
		_log_paypal_error($res);
	}
	else {
	 # error
		_log_paypal_error($res);
	}
	print "content-type: text/plain\n\n";
};

1;

sub _log_paypal_error {
	my ($res) = @_;
	open(my $fd, ">>/var/paypal/paypal_error.txt")
              or die( "Can't find paypal_error.txt : $!");
	 my $timestamp = localtime();
         print($fd "[$timestamp] - INVALID: ".$res->message);
         close($fd);
	
	return;
}

sub _log_paypal_info {
	my ($query) = @_;
	my $paypalData;
        my $pair;
        my @pairs = split(/&/, $query);
        foreach $pair (@pairs) {
               my ($key, $value) = split("=", $pair);
               $value =~ tr/+/ /;
               $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
               $paypalData .= $value."\t";
         }

         open(my $fd, ">>/var/paypal/paypal_info.txt")
              or die( "Can't find paypal_info.txt : $!");
          print($fd $paypalData."\n");
          close($fd);

	return;
}

sub _send_email {
  my ($c) = @_;
  my $config = $c->app->plugin('Config');

  my $message = Email::Simple->create(
    header => [
      From    => $config->{paypal}{notify_email},
      To      => $config->{paypal}{notify_email},
      Subject => 'Paypal Transaction - Completed',
    ],
    body => "Payment has been verified, validated, and captured.",
  );

  sendmail($message, { transport => _getTransport($c) });
  return;
}

sub _getTransport {
  my $c = shift;

  return $c->{_transport} ||= Email::Sender::Transport::SMTP::TLS->new(
    %{ $c->app->plugin('Config')->{email}{transport} }
  );
}

1;
