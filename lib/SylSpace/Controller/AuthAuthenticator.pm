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
  ## we could also pick off first and last name, but it ain't worth it
  my @emaillist = grep {$_->{type} eq 'account'} @{ $userinfo->{emails} };
  my $email= $emaillist[0]->{value};
  ## my $email = $userinfo->{emails}->[0]->{value};
  return logandreturn( $self, $email, $name, 'google' );
}

sub github {
  my ( $self, $access_token, $userinfo ) = @_;

  (defined($userinfo->{email})) or die "sadly, you have not confirmed your email with github, so you cannot use it to confirm it.\n";
  ($userinfo->{email} =~ /gmail.com$/) and die "sorry, but gmail accounts must be validated by google, not github";

  return logandreturn( $self, $userinfo->{email}, $userinfo->{name}, 'github' );
}

sub facebook {
  my ( $self, $access_token, $userinfo ) = @_;

  my $ua  = Mojo::UserAgent->new;
  my $res = $ua->get("https://graph.facebook.com/me?fields=name,email&access_token=$access_token")->result->json;

  if (!$res->{email}) {
    return $self->render(text => "Can't get your email from facebook, please try another auth method.");
  }
  ($res->{email} =~ /gmail.com$/) and die "sorry, but gmail accounts must be validated by google, not facebook";

  return logandreturn( $self, $res->{email}, $res->{name}, "facebook");
}

################################################################

get '/auth/authenticator' => sub {
  my $c = shift;

  (my $course = standard( $c )) or return global_redirect($c);

  $c->render(template => 'AuthAuthenticator' );
};


1;

################################################################

__DATA__

@@ AuthAuthenticator.html.ep

%title 'authenticate email';
%layout 'auth';

<% use SylSpace::Model::Controller qw(btnblock msghash2string); %>

<main>


<p style="margin:1em"> To learn more about this site, please visit the <a href="/aboutus">about us</a> page.</p>

  <%== msghash2string( [{ msgid => 0, priority => 5, time => 1495672668, subject => 'Test Play Site',
			body => '<p>This is our syllabus.space (SylSpace) test site, with code on github. It is safe to authenticate and register yourself.  The site is run by Ivo Welch, UCLA.  For more information, please click on <b>About Us</b> below, and then read the linked FAQ.   <p>Registration allows you to try out the student perspective for our sample course&mdash;innovatively named <span style="color:blue;font-family:mono;">corpfin:intro</span>.  A typical quiz looks like <a href="/html/eqsample02a.html">this rendering</a>.  These equizzes are a great self-test resource for all introductory corporate finance students in their own right, regardless of where they are learning corporate finance. <p>If you are an instructor, you can also obtain access for your own tailored course site.  This allows you to post and change equizzes (<a href="/html/eqsample02a.html">sample source</a>), see what your students are answering, distribute homeworks and collect student answers, etc.  The web interface is far simpler and more pleasing than anything else out there.  Syllabus.space has practically zero learning curve.  If interested, please <a href="mailto:ivo.welch@gmail.com">email</a> to ask me for your own instructor site.  Include a preferred name (such as \'fin101a-2017.johndoe.syllabus.space\') and a gmail address (such as johndoe@gmail.com).<p>In summer 2017, the site and VM will be regularly destroyed and rebuilt, so please do not store anything valuable here.  If you stumble upon little or not-so-little bugs, please let me know. '}] ) %>

<hr />

<nav>

  <p style="font-size:small;"><b>Direct Authentication</b> is the fastest and most reliable method to authenticate.  It works with your google or facebook id.</p>

   <div class="row text-center">
     <%== btnblock('/auth/google/authenticate', '<i class="fa fa-google"></i> Google', 'Your Gmail ID') %>
    <!-- <%== btnblock('/auth/github/authenticate', '<i class="fa fa-github"></i> Github', 'Your Github ID<br />Disabled Until Approved', 'btn-disabled') %> -->
    <%== btnblock('/auth/facebook/authenticate', '<i class="fa fa-facebook"></i> Facebook', 'Your Facebook ID') %>
     <%== btnblock('/auth/ucla/authenticate', '<i class="fa fa-university"></i> UCLA', 'Your University ID<br />Disabled Until Approved', 'btn-disabled') %>
   </div>

  <p>For gmail accounts, you must use Google to authenticate.  We will not accept Facebook or other authenticators.</p>

  <hr />

  <p style="font-size:small;padding-top:1em;">Alternatively, use sendmail.  It is slow, throttled per server (to avoid bot DDOS attacks on other servers), may take up to 10 minutes to arrive, and is only valid for 15 minutes&mdash;if you are lucky and no spam filter blocks it, in which case you will have to debug where your IT department or you have blocked the email.  If possible, avoid direct sendmail authentication.  Nevertheless, here it is: </p>

  <form name="registration" method="post" action="/auth/sendmail/authenticate">
       <input style="display:none" class="form-control" value="no name" name="name" />

    <div class="row text-center">

       <div class="col-md-5">
         <div class="input-group">
            <span class="input-group-addon">Email: <i class="fa fa-email"></i></span>
            <input class="form-control" placeholder="joe.schmoe@ucla.edu" name="outgemaildest" type="email" required />
         </div>
       </div>

       <div class="col-md-2">
          <div class="input-group">
             <button class="btn btn-default" type="submit" value="submit">Send Authorization Email</button>
          </div>
      </div>


     <% if ($ENV{'SYLSPACE_onlocalhost'}) { %>
        <hr />
        <hr />
        <div class="row top-buffer text-center; border-style:solid;"> <!-- completely ignored afaik -->
           <%== btnblock('/auth/testsetuser', '<i class="fa fa-users"></i> Hello, syllabus.test Sudo:<br />Choose Local Users', 'Listed Users -- Only on Localhost', 'btn-warning btn-md', 'w') %>
        </div>
      <% } %>

    </div> <!-- row -->

  </form>

<p style="font-size:x-small;padding-top:1ex"><a href="/auth/magic">magic</a> is only useful to the cli site admin</p>

</nav>

</main>
