#!/usr/bin/env perl

=pod

=head1 Using the script for create backup of Check Point Gaia Embedded configs  
#===============================================================================
#
#         FILE: backup_cp_gaia_cfgs.pl
#
#        USAGE: cpanm install Net::OpenSSH
#
#        	   ./backup_cp_gaia_cfgs.pl  
#
#  DESCRIPTION: Create Check Point Gaia Embedded configs backup
#
#      OPTIONS: ---
# REQUIREMENTS: Perl v5.14+
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Vladislav Sapunov 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 09.04.2024 22:48:36
#     REVISION: ---
#===============================================================================
=cut

use strict;
use warnings;
use v5.14;
use utf8;
use Net::OpenSSH;
use POSIX 'strftime';

my $timestamp=strftime('%Y-%m-%dT%H-%M-%S', localtime());
#say "$timestamp";
my $backupLogin="admin";
my $backupPassword="vpn123";

# Log file
my $errorLog = "error.log";

# Source File
my $inFile = 'cp_list.txt';

# open source file for reading
open(FHR, '<', $inFile) or die "Couldn't Open file $inFile"."$!\n";
my @cpAppliances=<FHR>;

#my @cpAppliances=('127.0.0.1', '127.0.0.2', '10.210.8.49');
foreach my $cpHost (@cpAppliances) {
	chomp($cpHost);
	eval {
		my $ssh=Net::OpenSSH->new("$backupLogin\@$cpHost", password=>$backupPassword, timeout=>30);
	#my $ssh=Net::OpenSSH->new($cpHost, user=>$backupLogin, password=>$backupPassword, timeout=>30);
		$ssh->error and die "Unable to connect: ". $ssh->error;
		#say "Connected to $cpHost";

		##my $fh=$ssh->pipe_out("clish -c \"show configuration\"") or die "Unable to run command\n $!";
		my $hostname=$ssh->capture('hostname');
		chomp($hostname);
		my $shConfig=$ssh->capture('clish -c "show configuration"');
		my $dynamicObjects=$ssh->capture('dynamic_objects -l');
		my $version=$ssh->capture('ver');
		my $interfaces=$ssh->capture('ifconfig');
		my $routes=$ssh->capture('ip route'); # hostname; ip route | awk '{print $3" "$1}' | grep -v "default\|10.0.0.0" | grep -i "bond\|eth\|Sync\|Lan\|WAN\|Mgmt\|Internal"
		my $users=$ssh->capture('clish -c "show users"');
		my $confMasters=$ssh->capture('cat $FWDIR/conf/masters');
		my $confLocalArp=$ssh->capture('cat $FWDIR/conf/local.arp');
		my $cfgFile="$hostname" . "_" . "$timestamp" . ".cfg";
		my $addCfgFile="$hostname" . "_" . "$timestamp" . "_add.cfg";		

		# open log file for writing
		open(FHW, '>', $cfgFile) or die "Couldn't Open file $cfgFile"."$!\n";
		open(FHWADD, '>', $addCfgFile) or die "Couldn't Open file $addCfgFile"."$!\n";
		
		say FHW "$shConfig";		
		say FHW "#"x30;
		say FHW "$dynamicObjects";
		say FHW "#"x30;	

        say FHWADD "#"x30;
		say FHWADD "$hostname";
		say FHWADD "#"x30;
		say FHWADD "$version";
		say FHWADD "#"x30;
		say FHWADD "$interfaces";
		say FHWADD "#"x30;
		say FHWADD "$routes";
		say FHWADD "#"x30;
		say FHWADD "$users";
		say FHWADD "#"x30;
		say FHWADD "$confMasters"; # if defined || say "\$FWDIR/conf/masters does not exist";
		say FHWADD "#"x30;
		say FHWADD "$confLocalArp"; # if defined || say "\$FWDIR/conf/local.arp does not exist";
		say FHWADD "#"x30;
		
	undef $ssh;
	# Close the filehandles
	close(FHW) or die "$!\n";
	close(FHWADD) or die "$!\n";
};

if($@) {
	# open log file for write
	open(ERRORS, '>>', $errorLog) or die "Couldn't open error log file $errorLog"."$!\n"; 
	
	say ERRORS "Date: $timestamp Host: $cpHost Error: $@";
	# Close the filehandle
	close(ERRORS) or die "$!\n";
}
}


