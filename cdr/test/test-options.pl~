#!/usr/bin/perl -w
# 
#
# Paolo Valente, July 2014
#
# Some important options and parameters were hard-coded: moved them to setup file
#
# This is a small program for testing modifications.
#



require 5.004;
use strict;
use diagnostics;
use Time::Local;
use Sys::Hostname;   # Uli

use lib '../toolkit';

print "Running command: $0\n";

my($CCF_ROOT) = "/home/na62cdr/cdr";
chomp($CCF_ROOT);


require "$CCF_ROOT/toolkit/getDirMask.pl";
require "$CCF_ROOT/toolkit/ErrorReport.pl";
require "$CCF_ROOT/toolkit/bkm_dir.pl";
#require "$CCF_ROOT/toolkit/miscenv.pl";
#require "./miscenv.pl";
require "./miscenv_mod.pl";
#require "$CCF_ROOT/toolkit/decode_fdb.pl";
#require "./decode_fdb.pl";
require "./decode_fdb_mod.pl";

my($hostcdr) = getHost();

# Check that this user is authorised to run CCF software 
my($user) = getUser_mod();

my($bkm_dir);
my(@bkm_entry) = ();
my(%bkm_entry) = ();
%bkm_entry = bkm_dir("-quiet","$CCF_ROOT/setup/setup.dat");

foreach  (sort keys %bkm_entry) {
  if ( $hostcdr = $_) { $bkm_dir = $bkm_entry{$_}; }
}

die "$0: No bkm_dir on this host ($hostcdr). Check the setup.dat file..." unless defined($bkm_dir);

my(@cmdarg);

my($bkmrootdir) = $bkm_dir;

my($bkmstartdir)    = "$bkmrootdir/OnlineTransferStart";
my($bkmstopdir)     = "$bkmrootdir/OnlineTransferStop";
my($bkmcompletedir) = "$bkmrootdir/OnlineTransferComplete";
my($castordir)      = getRAWrepository2("-quiet","$CCF_ROOT/setup/setup.dat.2014");
my($castorhost)     = getCASTORstagehost("-quiet","$CCF_ROOT/setup/setup.dat.2014");
my($castorsvcclass) = getCASTORsvcclass("-quiet","$CCF_ROOT/setup/setup.dat.2014");
my($castorpool)     = getCASTORstagepool("-quiet","$CCF_ROOT/setup/setup.dat.2014");
my($castorusev2)    = getCASTORusev2("-quiet","$CCF_ROOT/setup/setup.dat.2014");
my($datadir)        = "/merger/cdr";


$hostcdr = getHost();

$ENV{STAGE_HOST}  = $castorhost;
$ENV{STAGE_SVCCLASS}  = $castorsvcclass;
$ENV{STAGE_POOL}  = $castorpool;
$ENV{RFIO_USE_CASTOR_V2}  = $castorusev2;


print "$0: Program is starting... ".`date`;
print `uname -a`;
print "host:                 $hostcdr\n";
print "user:                 $user\n";
print "bkmstartdir:          $bkmstartdir\n";
print "bkmstopdir:           $bkmstopdir\n";
print "bkmcompletedir:       $bkmcompletedir\n";
print "castordir:            $castordir\n";
print "datadir:              $datadir\n";
print "CASTOR options:\n";
print "STAGE_HOST ",$ENV{STAGE_HOST},"\n";
print "STAGE_SVCCLASS ",$ENV{STAGE_SVCCLASS},"\n";
print "STAGE_POOL ",$ENV{STAGE_POOL},"\n";
print "RFIO_USE_CASTOR_V2 ",$ENV{RFIO_USE_CASTOR_V2},"\n";

