#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Parallel::ForkManager;

my $MAX_PROCESSES = 2;

my $target_path = $ARGV[0];

die "No valid path provided" unless -d $target_path;

my %countries = ( 
#	'europe' => [ 
#		'germany', 
#		'norway',
#		'sweden',
#		'switzerland',
#		'italy',
#		'france',
#		'spain',
#		'austria'
#		'netherlands',
#		'great_britain'
#	]
);

my @geofabrik = (
#	'europe/germany/baden-wuerttemberg',
#	'europe/germany/hessen',
	'europe/germany',
	'europe/france',
	'europe/italy',
	'europe/switzerland'
#	'europe/norway',
#	'europe/sweden',
#	'europe/finland',
#	'africa'
);

my %bboxes = (
#	'southafrica' => '17,-35,30,-30',
#	'sanfrancisco' => '-123.05,37.20,-121.70,38.20'
);

#print Dumper \%bboxes;
#die();

my $pm = new Parallel::ForkManager($MAX_PROCESSES);

foreach my $country (keys %bboxes) {
	my $pid = $pm->start and next; 
	my $bbox = $bboxes{$country};
	my $command = 'wget http://www.informationfreeway.org/api/0.5/*[bbox=' . $bbox . '] -o /tmp/' . "$country.log -O $target_path/$country.osm";
	print $command . "\n";
	system $command;
	$command = "bzip2 -f $target_path/$country.osm";
	print $command . "\n";
	system $command;
	$pm->finish; # Terminates the child process
}

#foreach my $continent (keys %countries) {
#	my $pid = $pm->start and next; 
#	my $command = "wget http://download.geofabrik.de/osm/$continent.osm.bz2 -o /tmp/$continent.log -O $target_path/$continent.osm.bz2";
#	print $command . "\n";
#	system $command;
#	$pm->finish; # Terminates the child process
#}
foreach my $continent (keys %countries) {
	foreach my $country (@{$countries{$continent}}) {
		my $pid = $pm->start and next; 
		my $command = "wget http://download.geofabrik.de/osm/$continent/$country.osm.bz2 -o /tmp/$country.log -O $target_path/$country.osm.bz2";
#		print $command . "\n";
		system $command;
		$pm->finish; # Terminates the child process
	}
}

foreach my $location (@geofabrik) {
	my $pid = $pm->start and next; 
	my @array = split /\//, $location;
	my $country = pop(@array); 
#	print Dumper \$country;
	my $command = "wget http://download.geofabrik.de/osm/$location.osm.bz2 -o /tmp/$country.log -O $target_path/$country.osm.bz2.tmp";
#	print $command . "\n";
	system $command;
	$command = "mv $target_path/$country.osm.bz2.tmp $target_path/$country.osm.bz2";
	system $command;
	$pm->finish; # Terminates the child process
}

$pm->wait_all_children;


