use strict;
use warnings;
eval q{ use Test::Clustericious::Log };
use Test::Clustericious::Cluster;
use Test::More;
BEGIN {
  plan skip_all => 'test requires Clustericious 0.9941'
    unless eval q{ use Clustericious 0.9941; 1};
}

plan tests => 6;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok('MyApp');

create_config_ok MyApp => {
  url => $cluster->url,
};

use_ok 'MyApp::Client';

my $client = eval { MyApp::Client->new };
diag $@ if $@;
isa_ok $client, 'MyApp::Client';
$client->client($cluster->t->ua);

is $client->welcome, 'welcome', 'welcome returns welcome';
is $client->version->[0], '1.00', 'version = 1.00';

__DATA__

@@ lib/MyApp.pm
package MyApp;

use Mojo::JSON qw( encode_json );
use Mojo::Base qw( Mojolicious );

sub startup
{
  my($self, $config) = @_;
  $self->routes->get('/' => sub { shift->render(text => 'welcome') });
  $self->routes->get('/version' => sub {
    my $c = shift;
    $c->tx->res->headers->content_type('application/json');
    $c->render(text => encode_json([ '1.00' ]));
  });
}

1;

@@ lib/MyApp/Client.pm
package MyApp::Client;
use Clustericious::Client;
route welcome => 'GET', '/';
1;
