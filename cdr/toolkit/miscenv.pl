#!/usr/bin/perl -w
# 
# Subroutines to get misc environment variables
#

require 5.004;

use strict;
use diagnostics;

use Env qw(PATH LD_LIBRARY_PATH);

my($CCF_ROOT) = "/home/na62cdr/cdr";
if(-e "$ENV{HOME}/.ccfrc") {
#    $CCF_ROOT = `cat "$ENV{HOME}/.ccfrc" 2>&1`;
    $CCF_ROOT = `grep "CCF_ROOT" "$ENV{HOME}/.ccfrc" 2>&1`;
    chomp($CCF_ROOT);
    $CCF_ROOT =~ s/CCF_ROOT//;
    $CCF_ROOT =~ s/ //g;
}
if(!-d $CCF_ROOT) {
    $CCF_ROOT = "/home/na62cdr/cdr";
}
defined $CCF_ROOT || die "Define CCF_ROOT enviroment variable";

#
#=== New version; Massimo Lamanna 26-JUL-2000 ====
#
sub getUser {

  my ($user) = $ENV{LOGNAME};
  my ($host) = getHost();

  my $cluster;
  $cluster = 'na62merger';
#  $host =~ /^([a-z,A-Z,\-]){1,}[a-z]/;
#  $cluster = $&;
  defined ($cluster) || die "$0: illegal cluster name \n";

  print '+++cl ',$cluster;
  print '+++ho ',$host;

  # List of authorised users (format cluster:user)  
  my @auth_user = `cat $CCF_ROOT/setup/users.dat`;

  my $uthn = 0;

  # Check this user against and authorisation list
  foreach my $line (@auth_user) {
      print '--- ',$line,$user,$cluster;
   next if ($line !~ /:\s{0,}$user/);
   next if ($line !~ /^\s{0,}$cluster:/);
   $uthn=1;
  }  

  die "$0: $user is not authorised to run this software \n" unless $uthn==1;
  return ($user);

}
#=============================================  
sub getCastorVers {
    my $setup_file = "$CCF_ROOT/setup/setup.dat";
    defined $_[0] && ($setup_file=$_[0]);
    open (IN,$setup_file) || die "$0: cannot open $setup_file for reading: $!";

    my $castor_vers;

    while (<IN>) {$castor_vers  = $1 if /^CASTOR_VERS\s+(\S*)/;} close IN;
    defined $castor_vers || die "$0: CASTOR_VERS not defined in $setup_file \n";	
    return $castor_vers;
}
#=============================================
sub getSys {

    my $sys_info = `uname -a`;
    my @sys_var = split(/ /, $sys_info);
    my $os;

  switch: {
#      if ($sys_var[0] eq "Linux")   {$os = "lnx"; last switch;}
      if ($sys_var[0] eq "Linux") {
	  $os = "redhat61,rh61_gcc2952"; 
	  last switch;
      }
      if ($sys_var[0] eq "Solaris") {$os = "sun"; last switch;}
      if ($sys_var[0] eq "SunOS") {$os = "sun"; last switch;}
  }
    defined $os || die "$0: $sys_var[0] is an unsupported architecture \n";
    return $os;
}
#=============================================   
sub getOS {

    my $sys_info = `uname -a`;
    my @sys_var = split(/ /, $sys_info);
    my $os = $sys_var[0];
    return $os;

}
#=== added by Massimo Lamanna 16-DEC-1999 ====
sub getHost {
    my($host) = `/bin/hostname`;
    chomp($host);
    $host =~ s/\..*//;
    return $host; 
}
#=============================================  
1;
