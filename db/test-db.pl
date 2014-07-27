#!/usr/bin/perl -w
# 

require 5.004;
use strict;
use diagnostics;
use Time::Local;
use Sys::Hostname;   # Uli

use DBI;

my $host = "dbod-na62cdr.cern.ch:5501";
my $user = "cdr";
my $pw = "na62cdr-cdr-user";

my $db = "na62_bk";
my $datab = "DBI:mysql:".$db;
my $thedb = $datab."\;host=".$host;


print "Connecting to $thedb...\n";
my $connect = DBI->connect($thedb, $user, $pw) or die "Connection Error: $DBI::errstr\n";
my $sql_code;
my $sth;

print "====================================\n";
$sql_code = "SHOW TABLES";
$sth = $connect->prepare($sql_code);
$sth->execute or die "SQL Error: $DBI::errstr\n";
while (my @row = $sth->fetchrow_array){
    for (@row){
	print $_," ";
    }  
    print "\n";
} 
print "====================================\n";
my $tablename = "filecopy"; 
$sql_code = "SELECT * FROM $tablename";
$sth = $connect->prepare($sql_code);
$sth->execute or die "SQL Error: $DBI::errstr\n";
while (my $line = $sth->fetchrow_hashref){
    foreach (keys %$line){
	print $_,"->"; 
	if (defined($$line{$_})){
	    print $$line{$_};
	}else{
	    print "NULL";
	} 
	print "\n";      
    } 
    print "\n";
} 
