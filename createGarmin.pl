#!/usr/bin/perl
#
use strict;
use warnings;

use Data::Dumper;
use File::Path 'rmtree';

my $java = '/opt/jre1.6.0_13/bin/java';
my $osmcut = '/home/thsz/osm/garmin/osmcut.0.5.jar';
my $splitter = '/home/thsz/osm/garmin/splitter.jar';
my $tile_size = '1';
#my $mkgmap = '/home/thsz/osm/garmin/mkgmap-r973/mkgmap.jar'; 
#my $mkgmap = '/home/thsz/osm/garmin/mkgmap-r1188/mkgmap.jar'; 
my $mkgmap = '/home/thsz/osm/garmin/mkgmap-r1642/mkgmap.jar'; 
my $map_features = '/home/thsz/osm/garmin/teddys_map-features.csv';
my $garmin_dir = '/home/thsz/pub-html/osm/garmin/countries/';
my $osm_dir = '/home/thsz/pub-html/osm/countries/';
my $memory = 2048;

my %countries = getCountries($osm_dir);

foreach my $country (sort (keys %countries)) {
	my $main_dir = `mktemp -d`;			# creating main -> /
	chomp $main_dir;
	my $temp_dir = `mktemp -d -p $main_dir`;	# creating tmp in main -> /tmp
	my $work_dir = $main_dir . '/' . $country;
	mkdir $work_dir;				# creating work in main -> /country
	chdir $work_dir;
	chomp($temp_dir);
	# Lets cut it in pieces
	print "unzipping $country\n";
	system("bunzip2 -k $countries{$country}{'osm'}");
	my $tmp_file = $countries{$country}{'osm'};
	$tmp_file =~ s/\.bz2$//;
	my $mapname = sprintf("%08d",int(rand(99999000)));
	if (-r $tmp_file) {
		#/opt/jre1.6.0_02/bin/java -Xmx1024M -jar ../splitter.jar /home/thsz/pub-html/osm/countries/germany.osm
		#my $command = "$java -Xmx$memory" . "M -jar $osmcut $tile_size $tmp_file $temp_dir";
		chdir $temp_dir;
		my $command = "$java -Xmx$memory" . "M -jar $splitter --max-nodes=1000000 $tmp_file";
		#my $command = "$java -Xmx$memory" . "M -jar $splitter --max-nodes=1500000 $tmp_file";

		print $command . "\n";
		system $command;
		my $files = readTiles($temp_dir);
#		$command = "$java -Xmx512M -jar $mkgmap -n \"OSM ". ucfirst($country) . "\" --gmapsupp --map-features $map_features $files";
		#/opt/jre1.6.0_02/bin/java -Xmx1024M -enableassertions -jar ../mkgmap-r971/mkgmap.jar --net --route --gmapsupp ../new/*.osm.gz
		#$command = "$java -Xmx$memory" . "M -jar $mkgmap --mapname=00000001 --description=osm-default-map --gmapsupp $files";
		chdir $work_dir;
		$command = "$java -enableassertions -Xmx$memory" . "M -jar $mkgmap --net --route --mapname=$mapname --description=\"OSM " . ucfirst($country) . "\" --gmapsupp $temp_dir/*.osm.gz";
		#$command = "$java -enableassertions -Xmx$memory" . "M -jar $mkgmap --net --route --gmapsupp $temp_dir/*.osm.gz";
		print $command . "\n";
		system $command;
		my $gmap_file = $country . '/gmapsupp.img';
		if (-r "$main_dir/$gmap_file") {
			chdir $main_dir;
			my $tar_command;
			my $final_gmap_file = $garmin_dir . $country . '.gmap.tar.bz2';
			$tar_command = "tar --remove-files -cjvvf $final_gmap_file $gmap_file";
			print $tar_command . "\n";
			system $tar_command;
			my $archive_file = $garmin_dir . $country . '.img.tar.bz2';
			$tar_command = "tar --remove-files -cjvvf $archive_file $country";
			print $tar_command . "\n";
			system $tar_command;
		}
		unlink $tmp_file;
	}
	rmtree($main_dir);
}

sub readTiles {
	my $dir = shift();
	opendir(DIR, $dir) || die "can't opendir $dir: $!";
	my @files = grep { /^\d+$/ && -f "$dir/$_" } readdir(DIR);
	closedir DIR;

	my $file_string;
	foreach my $file (@files) {
		$file_string .= $dir . '/' . $file . ' ';
	}

	return $file_string;
}

sub getCountries {
	my $dir = shift();
	my %countries;
	opendir(DIR, $dir) || die "can't opendir $dir: $!";
#	 $countries{$1}{'osm'}{$_}++  if grep { /^(.+?)\.osm\.bz2$/ && -f "$dir/$_" }
	my @file_list = readdir(DIR);
	closedir DIR;

	foreach my $file (@file_list) {
		if ($file =~ m{^(.+?)\.osm\.bz2$}) {
			my $country = $1;
			$countries{$country}{'osm'} = "$dir$file";
		}
	}
	return %countries;
}
