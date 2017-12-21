#!/bin/bash
###################################################################################
#
#
####################################################################################
#
#  Created by: samuel.januario01@gmail.com
#  Last changed by: $Author: Samuel Januario$:
#  Revision: $Rev: 0 $:
#
####################################################################################

# we need to sed LD_LIBRARY_PATH first so perl will
# know about DB2 libraries
# two possibilities:
# 1. load profile of db2inst1 user
# 2. set LD_LIBRARY_PATH manually to directories where libdb2.so.1 is

#. /opt/IBM/ITM_HMS/TEPS_DB/sqllib/db2profile
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/opt/IBM/ITM_HMS/TEPS_DB/sqllib/lib64:/opt/IBM/ITM_HMS/TEPS_DB/sqllib/lib32"

# exec this script but now by perl
# -x will search for #!/usr/bin/perl in this script and starts from there
exec perl -wx "$0" "$@"



#!/usr/bin/perl -w
use DBI;
use strict;
use Time::Local;
use XML::Simple;
use Data::Dumper;
use Sys::Hostname;

if ($#ARGV != 0) {
        print "Usage: $0 <agent>\n";
        exit;
}

chomp $ARGV[0];

my $agent = $ARGV[0];

# define config file
my $configFile = "/opt/IBM/ITM_HMS/tools/scripts/check_reporting.conf";

# find agent type
my @tmp = split(/:/, $agent);
my $agentType = $tmp[$#tmp];

# define output format
my $format = "%-30s %-25s %-10s %-13s %-20s\n";

# FIXME should be in config file
# allowed only defined agents
my %definedAgents = ();
$definedAgents{'NT'}{'NT_Memory_64'} = 3600;
$definedAgents{'NT'}{'NT_Processor'} = 3600;
$definedAgents{'NT'}{'NT_System'} = 3600;
$definedAgents{'NT'}{'NT_Logical_Disk'} = 3600;
$definedAgents{'NT'}{'NT_Network_Interface'} = 3600;

$definedAgents{'LZ'}{'KLZ_CPU'} = 3600;
$definedAgents{'LZ'}{'KLZ_Disk_IO'} = 3600;
$definedAgents{'LZ'}{'KLZ_IO_Ext'} = 3600;
$definedAgents{'LZ'}{'KLZ_Network'} = 3600;
$definedAgents{'LZ'}{'KLZ_System_Statistics'} = 3600;
$definedAgents{'LZ'}{'KLZ_VM_Stats'} = 3600;

$definedAgents{'KUX'}{'Disk_Performance'} = 3600;
$definedAgents{'KUX'}{'Unix_Memory'} = 3600;
$definedAgents{'KUX'}{'Network'} = 3600;
$definedAgents{'KUX'}{'Disk'} = 3600;
$definedAgents{'KUX'}{'SMP_CPU'} = 3600;
$definedAgents{'KUX'}{'System'} = 3600;

$definedAgents{'1T'}{'K1T_SYSINFO'} = 86400;
$definedAgents{'1T'}{'K1T_STORAGE'} = 86400;
$definedAgents{'1T'}{'K1T_VERSIONS'} = 86400;
$definedAgents{'1T'}{'K1T_RAW'} = 86400;
$definedAgents{'1T'}{'K1T_ISCSI_INFO'} = 86400;
$definedAgents{'1T'}{'K1T_SL_REP_BAT'} = 3600;

# declare database variables
my $database;
my $db_hostname;
my $db_port;
my $db_user;
my $db_pass;

my $dbh; # database handler

# IBM has "strange" timestamps in database like 1120302090026000
# see definition at http://blog.gulfsoft.com/2008/03/converting-tdw-timestamps-to-db2.html
# convert to unixtime
sub ibm2unixtime {
        #       1120302090026000
        my ($ibmtime, $unixtime, $century, $year, $month, $day, $hour, $minute, $second);
        $ibmtime = $_[0];
        ($century, $year, $month, $day, $hour, $minute, $second) = $ibmtime =~ /(\d{1})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/;
        $unixtime = timelocal($second, $minute, $hour, $day, $month-1, $year);
        return $unixtime;
}

# get hostname, IP, login, password for TDW
sub setTDW {
	my $hostname = $_[0];
	my $config = XMLin($configFile);
	my $tdw = $config->{hubs}->{hub}->{$hostname}->{tdw};

	if ( ! $tdw ) {
		print STDERR "ERROR: Environment not found, check config file.\n";
		exit 1;
	}
	
	$database = $config->{datawarehouses}->{tdw}->{$tdw}->{database};
	$db_hostname = $config->{datawarehouses}->{tdw}->{$tdw}->{ip};
	$db_port = $config->{datawarehouses}->{tdw}->{$tdw}->{port};
	$db_user = $config->{hubs}->{hub}->{$hostname}->{tdwlogin};
	$db_pass = $config->{hubs}->{hub}->{$hostname}->{tdwpass};
}

# run query to DATABASE
sub do_check {

        my $object = $_[0];
        my $sth;

        my $stmt = "
                SELECT
                        startqueue,
                        wpsysname
                FROM warehouselog
                WHERE
                        ORIGINNODE = ? and
                        OBJECT = '" . $object  . "'
                ORDER BY startqueue DESC FETCH FIRST 1 ROWS ONLY WITH UR
        ";

        $sth = $dbh->prepare($stmt);
        $sth->execute($agent);

        my ($wtimestamp,$whpa);

        $sth->bind_col(1,\$wtimestamp);
        $sth->bind_col(2,\$whpa);
        $sth->fetch;
        $sth->finish();

        # if agent not found, set timestamp to 1.1.1970
        if ( ! $wtimestamp) {
                $wtimestamp = "1700101000000000";
        }
	if ( ! $whpa) {
		$whpa = "NOTSET";
	}
       
        my $readableTimestamp = substr($wtimestamp, 1, 12);    
        my $unixDB = ibm2unixtime($wtimestamp);
        my $unixNOW = time();
        my $sub = ($unixNOW - $unixDB);


        # FIXME $maxTime, *1 is defined it means that we are strict that last timestamp must be available
        # add to config/definition as variable/parameter what is the last timestamp still as OK
        my $maxTime = ($definedAgents{$agentType}{$object} * 2);
        if ( $sub < $maxTime) {
                printf($format, $agent, $object, $readableTimestamp, "OK", $whpa);
        }
        else {
                printf($format, $agent, $object, $readableTimestamp, "ERROR $sub > $maxTime", $whpa);
        }
}


######################### main ########################
setTDW(hostname());

# open database connection
my $tmp_string = "dbi:DB2:DATABASE=$database; HOSTNAME=$db_hostname; PORT=$db_port; PROTOCOL=TCPIP; UID=$db_user; PWD=$db_pass;";
$dbh = DBI->connect($tmp_string, $db_user, $db_pass, {RaiseError => 1});
$dbh->do("SET CURRENT SCHEMA $db_user");

# loop for objects for given agentType and perform query
for my $key (keys %{$definedAgents{$agentType} } ) {
        do_check($key);
}

# close database connection
$dbh->disconnect();
