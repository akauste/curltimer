#!/usr/bin/env perl
use strict;
use v5.24;
use utf8;

use Mojolicious::Lite -signatures;

use JSON::XS;
my $json = JSON::XS->new;

use DateTime;
use Excel::Writer::XLSX;
use Excel::Writer::XLSX::Utility;

use DBI;

my $clients = {};

my $dbh = DBI->connect("dbi:SQLite:dbname=curltimer.sqlite","","") or die DBI->errstr;
$dbh->{sqlite_unicode} = 1;
$dbh->do(<<"END_SQL");
	CREATE TABLE IF NOT EXISTS measurement (
	global_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	local_id  INTEGER DEFAULT NULL,
	timestamp DATETIME,
	speed FLOAT NOT NULL,
	stone_number INTEGER,
	stone_color VARCHAR(15),
	data LONG TEXT)
END_SQL

sub get_latest($rows) {
  my $sth = $dbh->prepare(qq/
		SELECT * FROM measurement ORDER BY global_id DESC LIMIT $rows
	/);
	$sth->execute;
	
  my @list;
	my $maxgid;
	while(my $href = $sth->fetchrow_hashref) {
		$href->{data} = JSON::XS->new->decode($href->{data});
		$maxgid = $href->{global_id} if $maxgid < $href->{global_id};
		($href->{date}, $href->{time}) = split /T/, $href->{timestamp};
		push @list, $href;
	}
  return \@list;
}

get '/' => sub ($self) {
  $self->redirect_to('index.html');
};

post 'timer' => sub($self) {
	my $json = $self->param('JSON');
	my $data = JSON::XS->new->decode( $json );

	$dbh->do(qq/
		INSERT INTO measurement
		(global_id, local_id, boot_id, timestamp, speed, stone_number, stone_color, data)
		VALUES (NULL, ?, ?, ?, ?, ?, ?, ?)
	/, undef,
		$data->{local_id},
    $data->{boot_id},
		DateTime->now,
		$data->{corrected_speed}, $data->{stone_number}, $data->{stone_color}, $json) or die $dbh->errstr;
	my $gid = $dbh->last_insert_id(undef, undef, 'measurement', 'global_id');
	my $lid = $data->{local_id} || 0;
	
    
  #Send message to all clients
  # my $message =  JSON::XS->new->encode({
  #   global_id => $gid,
  #   boot_id => $data->{boot_id},
  #   speed => $data->{corrected_speed}, 
  #   data => $data, 
	# 	#DateTime->now,
	# 	#$data->{corrected_speed}, $data->{stone_number}, $data->{stone_color}, $json
  # });
  my $list = get_latest(1);
  my $json_out = JSON::XS->new->encode($list->[0]);
  foreach my $cid (keys %$clients) {
    $clients->{$cid}{controller}->send($json_out);
  }

  $self->res->headers->header('Access-Control-Allow-Origin' => '*');
	return $self->render(json => {local_id => $lid, global_id => $gid});
};

get 'timer_after/:gid' => sub ($self) {
	my $gid = $self->captures->{gid};
	my $sth = $dbh->prepare('SELECT * FROM measurement WHERE global_id > ? ORDER BY global_id DESC LIMIT 20');
	$sth->execute($gid);
	my @list;
	while(my $href = $sth->fetchrow_hashref) {
		$href->{data} = JSON::XS->new->decode($href->{data});
		unshift @list, $href; # Reverse the order here..
	}
  $self->res->headers->header('Access-Control-Allow-Origin' => '*');
  return $self->render(json => \@list);
};

websocket '/update' => sub ($self) {
  #Client id
  my $cid = "$self";
  
  #Resistance controller
  $clients->{$cid} {controller} = $self;

  my $list = get_latest(1);
  $clients->{$cid} {controller}->send(JSON::XS->new->encode($list->[0]));
  
  # Finish
  $self->on('finish' => sub {
    # Remove client
    delete $clients->{$cid};
  });
};

get 'timer_latest' => sub ($self) {
	my $list = get_latest(200);
  $self->res->headers->header('Access-Control-Allow-Origin' => '*');
  return $self->render(json => $list);
};

get 'timer_set/(:bootid).json' => sub ($self) {
	my $boot = $self->captures->{'bootid.html'};
	my $sth = $dbh->prepare(qq/
		SELECT * FROM measurement
		WHERE boot_id=?
		ORDER BY global_id ASC
	/);
	die "Boot id missing!" unless $boot && $boot =~ /^\d+$/;
	$sth->execute($boot);

	my @list;
	#my @json;
	#my $maxgid;
	while(my $href = $sth->fetchrow_hashref) {
		$href->{data} = JSON::XS->new->decode($href->{data});
		#$maxgid = $href->{global_id} if $maxgid < $href->{global_id};
		($href->{date}, $href->{time}) = split /T/, $href->{timestamp};
		push @list => $href;
		#push @json => JSON::XS->new->encode($href);
	}
  return $self->render(json => \@list);
};

get 'timer_set/:bootid.xlsx' => sub ($self) {
  my $boot = $self->stash('bootid.xlsx');

  die "Boot id missing!" if !$boot || $boot !~ /^\d+$/;

	my $sth = $dbh->prepare(qq/
		SELECT * FROM measurement
		WHERE boot_id=?
		ORDER BY global_id ASC
	/);
	$sth->execute($boot);
	
	open my $fh, '>', \my $str or die "Failed to open filehandle: $!";
	binmode $fh;
	my $excel = Excel::Writer::XLSX->new( $fh );
	my $ws    = $excel->add_worksheet( 'Curltimer_boot_' + $boot );       # Actual export
	my %fmt;
	$fmt{data}   = $excel->add_format( bold => 0, locked => 0, );
	$fmt{header} = $excel->add_format( bold => 1, locked => 1, bg_color => 'silver', bottom => 1 );
	$fmt{extras} = $excel->add_format( bold => 0, locked => 1, bg_color => 'gray', bottom => 1 );
	
	my $row = 1;
	
	$ws->write_string(0, 0, 'Kivi', $fmt{header});
	$ws->write_string(0, 1, 'Kierros', $fmt{header});
	$ws->write_string(0, 2, 'Laidasta', $fmt{header});
	$ws->write_string(0, 3, 'Pituus', $fmt{header});
	$ws->write_string(0, 4, 'Nopeus', $fmt{header});
	$ws->write_string(0, 6, 'Debug dataa', $fmt{extras});
	$ws->write_string(0, 7, 'boot_id', $fmt{extras});
	$ws->write_string(0, 8, 'global_id', $fmt{extras});
	$ws->write_string(0, 9, 'raw_speed', $fmt{extras});
	$ws->write_string(0, 10, 'ldr_min', $fmt{extras});
	$ws->write_string(0, 11, 'ldr_max', $fmt{extras});
	
	while(my $href = $sth->fetchrow_hashref) {
		$href->{data} = JSON::XS->new->decode($href->{data});
		$ws->write_formula($row, 0, "=MOD(ROW()-2, 8)+1", $fmt{data}, (($row-1) % 8)+1);
		$ws->write_formula($row, 1, '=QUOTIENT(ROW()-2,8)+1', $fmt{data}, int(($row-1)/8)+1);
		
		$ws->write($row, 4, $href->{speed});
		# Print other fields...
		$ws->write($row, 7, $href->{data}{boot_id});
		$ws->write($row, 8, $href->{global_id});
		$ws->write($row, 9, $href->{data}{raw_speed});
		$ws->write($row, 10, $href->{data}{ldr_min});
		$ws->write($row, 11, $href->{data}{ldr_max});
		$row++;
	}

	$excel->close();
	$fh->seek(0,0);

	return $self->render(data => $str, format => 'xlsx');
};

app->start;

__END__

