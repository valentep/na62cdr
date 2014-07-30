#!/usr/bin/perl -w
# 

require 5.004;
use strict;
use diagnostics;
use Time::Local;
use Sys::Hostname;   # Uli
#####
use File::Basename;
use DBI;


my($CCF_ROOT) = `grep CCF_ROOT $ENV{HOME}/.ccfrc | sed 's/CCF_ROOT//' | sed 's/ //g'`;
defined $CCF_ROOT || die "Home directory CCF_ROOT not found in configuration file $ENV{HOME}/.ccfrc";
chomp($CCF_ROOT);
print "===============================================================\n";
print "===============================================================\n";
print "CCF_ROOT      ",$CCF_ROOT,"\n";

require "$CCF_ROOT/toolkit/decode_fdb_mod.pl";
require "$CCF_ROOT/toolkit/miscenv_mod.pl";
require "$CCF_ROOT/toolkit/ls_stat_full.pl";
require "$CCF_ROOT/toolkit/bkm_dir.pl";

require "dbutils.pl";
sub insert_file_entry;

my($setupdbfile) = "$CCF_ROOT/setup/setupdb.dat";
my($setupfile) = "$CCF_ROOT/setup/setup.dat";
my($usersfile) = "$CCF_ROOT/setup/users.dat";
#######################################################
my($user) = getUser_mod($usersfile);
my $thishost=getHost();
print "Host:         $thishost\n";
print "User:         $user\n";

print "Parsing setup file: $setupfile\n";
my($datayear) = getDataYear("-quiet",$setupfile);
my($datadir) = getDataDir("-quiet",$setupfile);
print "Processing year:    $datayear\n";
print "datadir:            $datadir\n";

my($bkm_dir);
my(@bkm_entry) = ();
my(%bkm_entry) = ();
%bkm_entry = bkm_dir("-quiet",$setupfile);

foreach  (sort keys %bkm_entry) {
  if ( $thishost = $_) { $bkm_dir = $bkm_entry{$_}; }
}

die "$0: No bkm_dir on this host ($thishost). Check the setup.dat file..." unless defined($bkm_dir);



print "Parsing setup DB file: $setupdbfile\n";
my $myhost=getDBhost("-quiet",$setupdbfile);
my $myport=getDBport("-quiet",$setupdbfile);
my $dbuser = getDBuser("-quiet",$setupdbfile);
my $pw = getDBpw("-quiet",$setupdbfile);

my $host = $myhost.":".$myport;
my $db = "na62_bk";
my $datab = "DBI:mysql:".$db;
my $thedb = $datab."\;host=".$host;

print "Connecting to $thedb... \n";
my $connect = DBI->connect($thedb, $dbuser, $pw) or die "Connection Error: $DBI::errstr\n";
my $sql_code;
my $sth;

###
my @rows=get_tables($connect);
#for (@rows){
#    print $_,"\n";
#}  
###

my $thisfilename="/merger/cdr/cdr00000000-0001.dat";
print "\nProcessing file: $thisfilename\n"; 
insert_file_entry($connect,$thisfilename);
print "I am here, now\n";






sub insert_file_entry(){
    my $conn=$_[0];
    my $currentfilename=$_[1];
    (my $fileonly,my $filedir,my $fileext) = fileparse($currentfilename, qr/\.[^.]*/);
    print "Path: $filedir, Name: $fileonly\n";
    
    my $filetp=get_filetype($conn,$fileext);
    my $filetypeid=$$filetp{'id'};
    my $filetypename=$$filetp{'filetypeshort'};
    print "Extension: $fileext -> Type: $filetypename\n";
    
    (my $merger_n, my $run_n, my $burst_n)=get_fileinfo($fileonly);
    print "Merger: $merger_n, Run: $run_n, Burst: $burst_n\n\n"; 
    
    if ($filedir eq ($datadir."/")){
	
    }else{
	print "ERROR: current data dir: $datadir NOT MATCHING with $filedir for file $fileonly$fileext\n\n";
    }
    
    my @disk_stat = ls_stat_full($currentfilename);
    my $filecrea=$disk_stat[2];
    my $filesize=$disk_stat[1];
    my $fileuri="file://".$thishost.$currentfilename;
    
    (my $sec,my $min,my $hour,my $mday,my $mon,my $year,my $wday, my $yday, my $isdst) = localtime($filecrea);
    my $yyear=1900+$year;
    my $filecreatime="$yyear-$mon-$mday $hour:$min:$sec\n";
    
    eval { 
	insert_file($conn,$fileonly,"1",$filecreatime,$filetypeid,$run_n,$burst_n);
    }; warn "Error in inserting new UNIQUE record in FILE table" if $@;    
} 

