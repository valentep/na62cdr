#!/usr/bin/perl -w
####################################################################
#
# Module ErrorReport
# Leanne Guy    December 1999
#
# Module to formulate errors and mail them to CDR/CCF support 
# 
####################################################################



# Get current environment
use Env qw(OBJY_DIR OBJY_VERS PATH LD_LIBRARY_PATH OO_FD_BOOT OS);
my($CCF_ROOT) = "/home/na62/cdr";


#==================================================================== 
# Return the from address for the mailer
sub FromAddress {
    $host = getHost();
    $from_address = "$host.cern.ch";
}
#==================================================================== 
# Return the to address for the mailer
sub ToAddress {
$urgent = 0;
$to_address = "felice.pantaleo\@cern.ch";

return ($to_address);
}
#==================================================================== 
# Return addresses to be cc'd 
sub  ccAddress {
   @cc_addresses = qw (
			felice.pantaleo@cern.ch
      		);
   return (@cc_addresses);
}
#==================================================================== 
# Return subject message to be cc'd 
sub Subject {
    $host = getHost();
    $subject = " NA62 CDR operating on $host has a problem ";
    return($subject);
}
#==================================================================== 
# Return the body of a message
sub Body {
    ($file,$level) = @_;
    $host = getHost(); $date = getDate();
    $body = "$date \n\n File $file on $host has status $level\n Human intervention required\n";
}
#====================================================================
# Return the date in the format to be included in the log files
sub getDate {
    $hr = localtime(time())->hour;
    $mn = localtime(time())->min;
    $sc = localtime(time())->sec;
    $date =  localtime(time())->mday;
    $tday = (Sun,Mon,Tue,Wed,Thu,Fri,Sat)[(localtime(time())->wday)];
    $this_mon = (Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec)[(localtime(time())->mon)];
    $year = localtime(time())->year + 1900;
  
    my($tme)  = sprintf "%02d:%02d:%02d_%3s_%02d_%3s_%4d",$hr,$mn,$sc,$tday,$date,$this_mon,$year;
    return $tme;
}
#====================================================================
1;
