#!perl

use strict;
use v5.24;

use DBI;
use JSON::XS;

my ($src, $tgt) = @ARGV;

unless($src && $tgt && -e $src && !-e $tgt) {
  say 'Usage: convertdb.pl SOURCE_DB_FILE TARGET_DB_FILE';
  say 'TARGET_DB_FILE should not exist';
};

my $dbh_s = DBI->connect("dbi:SQLite:dbname=$src") or die "Could not open $src";
my $dbh_t = DBI->connect("dbi:SQLite:dbname=$tgt") or die "Could not open $tgt";

my $sth_read = $dbh_s->prepare('SELECT global_id, local_id, timestamp, speed, stone_number, stone_color, data FROM measurement') or die $dbh_s->errstr;
$sth_read->execute or die $dbh_s->errstr;

$dbh_t->do(q/
  CREATE TABLE IF NOT EXISTS measurement (
	global_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	local_id  INTEGER DEFAULT NULL,
  boot_id INTEGER DEFAULT NULL,
	timestamp DATETIME,
	speed FLOAT NOT NULL,
	stone_number INTEGER,
	stone_color VARCHAR(15),
	data LONG TEXT)
/) or die "Could not create target db";

my $sth_write = $dbh_t->prepare('INSERT INTO measurement (global_id, local_id, boot_id, timestamp, speed, stone_number, stone_color, data) VALUES (?,?,?,?,?,?,?,?)')
  or die "Could not prepare SQL ". $dbh_t->errstr;

while (my $href = $sth_read->fetchrow_hashref) {
  my $json = JSON::XS->new->decode( $href->{data} );
  $sth_write->execute(
    @$href{qw/
      global_id
      local_id
      boot_id
      timestamp
      speed
      stone_number
      stone_color
      data
    /}
  ) or die "Failed to execute SQL ". $dbh_t->errstr;
}
