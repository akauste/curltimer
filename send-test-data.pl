#!perl

use strict;
use v5.24;

use DBI;
use HTTP::Tiny;

my ($src_db, $interval) = @ARGV;

die "Usage: send-test-data.pl SOURCE_SQLITE_DB [INTERVAL_SECONDS]"
  unless $src_db && -e $src_db;

my $dbh = DBI->connect("dbi:SQLite:dbname=$src_db") or die DBI->errstr;

my $http = HTTP::Tiny->new;

# We use old database to feed new data. All the real data from real datasource is saved as json
# in the data field, so we can just pass that to the API and not care about any of the other fields
my $sth = $dbh->prepare('SELECT data FROM measurement');

$interval ||= 20;

$sth->execute;
while(my $href = $sth->fetchrow_hashref) {
  say STDERR 'Sending data: '. $href->{data};
  my $res = $http->post_form('http://localhost:8888/timer/', { JSON => $href->{data} });
  if($res->{success}) {
    say STDERR "OK";
  }
  else {
    say STDERR "ERROR: ". substr($res->{content}, 600, 1500);
  }
  # It would make more sense to just have the request body JSON, now it's form-data with a single json-attribute
  # my $response = $http->post('localhost:8889/timer', { content => $href->{data} });
  sleep $interval;
};