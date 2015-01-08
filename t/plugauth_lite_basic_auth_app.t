use strict;
use warnings;
use Test::More tests => 11;
use Test::Mojo;

use PlugAuth::Lite;

my $app = PlugAuth::Lite->new({
  auth => sub {
    my($user, $pass) = @_;
    return 1 if $user eq 'foo' && $pass eq 'bar';
    return;
  },
  authz => sub {
    my($user, $action, $resource) = @_;
    return 1;
  },
});

my $t = Test::Mojo->new($app);

$t->get_ok('/')
  ->status_is(404);

my $port = eval { $t->ua->server->url->port } // $t->ua->app_url->port;

$t->get_ok("http://localhost:$port/auth")
  ->status_is(401)
  ->content_like(qr[authenticate], 'got authenticate header');

$t->get_ok("http://foo:bar\@localhost:$port/auth")
  ->status_is(200)
  ->content_is('ok', 'auth succeeded');

$t->get_ok("http://foo:foo\@localhost:$port/auth")
  ->status_is(403)
  ->content_is('not ok', 'auth failed');
