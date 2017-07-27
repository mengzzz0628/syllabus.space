#!/usr/bin/env perl
package SylSpace::Controller::Paypal;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(superseclog throttle);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

use Email::Valid;

get '/paypalreturn' => sub {
  my $c = shift;

  return $c->render( );




  my $name = $c->param('name');
  ($name eq 'no name') or die "we are already overloaded!\n";

  if (!$name) {
    return $c->stash(error => 'Missing required parameter name' )->render(template => 'AuthPaypal');
  }

  my $email = $c->param('outgemaildest');
  ($email) or die "Missing email\n";
  (Email::Valid->address($email)) or die "email address '$email' could not possibly be valid\n";

  if (!$email) {
    return $c->stash(error => 'Missing required parameter email' )->render(template => 'AuthPaypal');
  }

  $c->stash(email => $email);

  if (_send_email($c, $email, $name)) {
    return $c->stash(error => '')->render(template => 'AuthPaypal');
  }

  die "Failed to send email to '$email' with name '$name', for some unknown reason without a useful error message";
  $c->stash(error => 'Failed to send email')->render(template => 'AuthPaypal');
};

################
get '/auth/sendmail/callback' => sub {
  my $c = shift;

  my $jwt = $c->param('jwt');
  my $params = _jwt($c)->decode($jwt);

  my $name = $params->{name};
  my $email = $params->{email};

  superseclog( $c->tx->remote_address, $email, "got email callback for $name and $email" );

  ($email) or die "sorry, but our callback to authenticate you failed because we had no or an invalid email";

  if ($name and $email) {
    $c->session(uemail => $email, name => $name, expiration => time()+60*60, ishuman => time())->redirect_to('/index');
  } else {
    $c->stash(error => 'Missing required parameter')->render(template => 'AuthPaypal', $email => $params->{email} );;
  }
};

################
sub _getTransport {
  my $c = shift;

  return $c->{_transport} ||= Email::Sender::Transport::SMTP::TLS->new(
    %{ $c->app->plugin('Config')->{email}{transport} }
  );
}

################
sub _jwt {
  return Mojo::JWT->new(secret => shift->app->secrets->[0], expires => time()+15*60);  ## 15 minutes
#  return Mojo::JWT->new(secret => shift->app->secrets->[0]);
}

################
sub _send_email {
  my ($c, $email, $name) = @_;
  my $config = $c->app->plugin('Config');

  my $jwt = _jwt($c)->claims({name => $name, email => $email})->encode;
  my $url = $c->url_for('/auth/sendmail/callback')->to_abs->query(jwt => $jwt);

  defined($email) or die "internal error---what is your email??";

  my $message = Email::Simple->create(
    header => [
      From    => $config->{email}{message}{from},
      To      => $email,
      Subject => 'Confirm your email',
    ],
    body => "Follow this link: $url",
  );

  superseclog( $c->tx->remote_address, $email, "requesting sending email to ".$email );

  throttle();  ## to prevent nasty DDOSs on other sites

  return sendmail($message, { transport => _getTransport($c) });
}

1;

################################################################

__DATA__

@@ Paypal.html.ep

%title 'paypal testing';
%layout 'both';

<main>

  <p>Thank you for your payment. Your transaction has been completed, and a receipt for your purchase has been emailed to you from paypal. You may log into your paypal account at www.paypal.com to view details of this transaction.</p>

<hr />

working from 
  <a href="https://developer.paypal.com/docs/integration/direct/express-checkout/integration-jsv4/add-paypal-button/">
 https://developer.paypal.com/docs/integration/direct/express-checkout/integration-jsv4/add-paypal-button/</a>.


<hr />

  <script src="https://www.paypalobjects.com/api/checkout.js"></script>
  </head>

  <div id="paypal-button"></div>

  <script>
  paypal.Button.render({

		      env: 'sandbox', // Or 'production',
		      commit: true, // Show a 'Pay Now' button
		      payment: function() {
			  // Set up the payment here
			},

		      onAuthorize: function(data, actions) {
			  // Execute the payment here
			},

		      style: {
			size: 'small',
			  color: 'gold',
			  shape: 'pill',
			  label: 'checkout'
			  }

		       }, '#paypal-button');
</script>



<h2> Braintree </h2>

  <!-- Load the required components. -->
  <script src="https://js.braintreegateway.com/web/3.16.0/js/client.min.js"></script>
  <script src="https://js.braintreegateway.com/web/3.16.0/js/paypal-checkout.min.js"></script>

  <!-- Use the components. We'll see usage instructions next. -->
<script>
braintree.client.create(/* ... */);
</script>

< hr />

// Create a client.
braintree.client.create({
  authorization: 'CLIENT_TOKEN_FROM_SERVER'
}, function (clientErr, clientInstance) {

  // Stop if there was a problem creating the client.
  // This could happen if there is a network error or if the authorization
  // is invalid.
  if (clientErr) {
    console.error('Error creating client:', clientErr);
    return;
  }

  // Create a PayPal Checkout component.
  braintree.paypalCheckout.create({
    client: clientInstance
  }, function (paypalCheckoutErr, paypalCheckoutInstance) {

    // Stop if there was a problem creating PayPal Checkout.
    // This could happen if there was a network error or if it's incorrectly
    // configured.
    if (paypalCheckoutErr) {
      console.error('Error creating PayPal Checkout:', paypalCheckoutErr);
      return;
    }

// Set up PayPal with the checkout.js library
  paypal.Button.render({
		      env: 'production', // or 'sandbox'

		      payment: function () {
			  return paypalCheckoutInstance.createPayment({
								     flow: 'checkout', // Required
								     amount: 10.00, // Required
								     currency: 'USD', // Required
								     locale: 'en_US',
								     enableShippingAddress: true,
								     shippingAddressEditable: false,
								     shippingAddressOverride: {
								       recipientName: 'Scruff McGruff',
									 line1: '1234 Main St.',
									 line2: 'Unit 1',
									 city: 'Chicago',
									 countryCode: 'US',
									 postalCode: '60652',
									 state: 'IL',
									 phone: '123.456.7890'
									 }
								      });
			},

		      onAuthorize: function (data, actions) {
			  return paypalCheckoutInstance.tokenizePayment(data)
			    .then(function (payload) {
			      // Submit `payload.nonce` to your server
			    });
			},

		      onCancel: function (data) {
			  console.log('checkout.js payment cancelled', JSON.stringify(data, 0, 2));
			},

		      onError: function (err) {
			  console.error('checkout.js error', err);
			}
		       }, '#paypal-button').then(function () {
			 // The PayPal button will be rendered in an html element with the id
			   // `paypal-button`. This function will be called when the PayPal button
			   // is set up and ready to be used.
			 });

});

});


</main>


