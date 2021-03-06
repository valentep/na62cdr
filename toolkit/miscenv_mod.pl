#!/usr/bin/perl -w
# 
# Subroutines to get misc environment variables
#

require 5.004;

use strict;
use diagnostics;

use Env qw(PATH LD_LIBRARY_PATH);

#
#=== New version; Massimo Lamanna 26-JUL-2000 ====
#
sub getUser_mod() {
    my(@params) = @_;
    my($usersfile) = $params[0];
    my ($user) = $ENV{LOGNAME};
    my ($host) = getHost();
#    print "+++ ",$host,"\n";
    # List of authorised users (format cluster:user)  
    my @auth_user = `cat $usersfile`;
    my $uthn = 0;
    # Check this user against and authorisation list
    foreach my $line (@auth_user) {
#	print '--- ',$line,$user,"\n";
	next if ($line !~ /:\s{0,}$user/);
	next if ($line !~ /^\s{0,}$host:/);
	$uthn=1;
    }  
    die "$0: $user is not authorised to run on $host\n" unless $uthn==1;
    return ($user);
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

