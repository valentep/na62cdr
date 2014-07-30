require 5.004;
use strict;
use diagnostics;
use Time::Local;
use Sys::Hostname;   # Uli
#####
use File::Basename;
use DBI;


sub get_tables(){
    my $conn=$_[0];
    my @linee = ();
    my $myq = "show tables";    
#    print $myq,"\n";
    my $strh = $conn->prepare($myq);
    $strh->execute or die "SQL Error: $DBI::errstr\n";
    while (my @resu=$strh->fetchrow_array){
	push (@linee,$resu[0]); 
    } 
    return @linee;
} 

sub get_fileinfo(){
    my $filenam=$_[0];
    $filenam =~ m/(\d{2})(\d{6})\-(\d{4})/;   
    my @valu =($1,$2,$3);
    return @valu;
} 

sub get_filetype(){
    my $conn=$_[0];
    my $fext=$_[1];
    my $myq = "select * from filetype where extension='$fext';";    
#    print $myq,"\n";
    my $strh = $conn->prepare($myq);
    $strh->execute or die "SQL Error: $DBI::errstr\n";
    my $linea = $strh->fetchrow_hashref;
    return $linea;
} 

sub update_run(){
    my $conn=$_[0];
    my $run_n=$_[1];
    my $timestamp=$_[2];
    my $runtype_id=$_[3];
    my $myq = "select id,number,timestart from run where number='$run_n'";
    my $strh = $conn->prepare($myq);
    $strh->execute or die "SQL Error: $DBI::errstr\n";
    my $linea = $strh->fetchrow_hashref;
    my $tstart=$$linea{'timestart'};
    my $r_id=$$linea{'id'};
    my $myqq;
    if (!defined($r_id)){
	$myqq = "insert into run (number,timestart,runtype_id) values ('$run_n','$timestamp','$runtype_id')";
    }else{
	my $told=dbtime_to_timegm($tstart);
	my $tnew=dbtime_to_timegm($timestamp);
	if ($tnew<$told){
	    $myqq = "update run set timestart='$timestamp' where id='$r_id'";
	}else{

	}
    }
    if(defined($myqq)){
#	print $myqq,"\n";
	my $str = $conn->prepare($myqq);
	$str->execute or die "SQL Error: $DBI::errstr\n";
    } 	
    sub dbtime_to_timegm(){
	my $dbtime=$_[0];    
	$dbtime =~ /([\d]+)\-([\d]+)\-([\d]+)+\s+([\d]+):([\d]+)\:([\d]+)/;
	my $tgm=timegm($6,$5,$4,$3,$2-1,$1);
	return $tgm;
    } 
}

sub get_run(){
    my $conn=$_[0];
    my $run_n=$_[1];
    my $myq = "select * from run where number='$run_n'";
    my $strh = $conn->prepare($myq);
    $strh->execute or die "SQL Error: $DBI::errstr\n";
    my $linea = $strh->fetchrow_hashref;
    return $linea;
}

sub update_burst(){
    my $conn=$_[0];
    my $number=$_[1];
    my $isdebug=$_[2];
    my $timestamp=$_[3];
    my $run_id=$_[4];
    my $run_n=$_[5];
    my $global=$run_n*10000+$number;
    my $myq = "select id,timestamp,globalnumber from burst where globalnumber='$global'";
    my $strh = $conn->prepare($myq);
    $strh->execute or die "SQL Error: $DBI::errstr\n";
    my $linea = $strh->fetchrow_hashref;
    my $tburst=$$linea{'timestamp'};
    my $b_id=$$linea{'id'};
    my $myqq;
    if (!defined($b_id)){
    $myqq = "insert into burst (number,isdebug,timestamp,run_id,run_number,globalnumber) values ('$number','$isdebug','$timestamp','$run_id','$run_n','$global');"; 
    }else{
	my $told=dbtime_to_timegm2($tburst);
	my $tnew=dbtime_to_timegm2($timestamp);
	if ($tnew<$told){
	    $myqq = "update burst set timestamp='$timestamp' where id='$b_id'";
	}else{

	}
    }
    if(defined($myqq)){
#	print $myqq,"\n";
	my $str = $conn->prepare($myqq);
	$str->execute or die "SQL Error: $DBI::errstr\n";
    } 	
    sub dbtime_to_timegm2(){
	my $dbtime=$_[0];    
	$dbtime =~ /([\d]+)\-([\d]+)\-([\d]+)+\s+([\d]+):([\d]+)\:([\d]+)/;
	my $tgm=timegm($6,$5,$4,$3,$2-1,$1);
	return $tgm;
    } 
} 

 
sub insert_file(){
    my $conn=$_[0];
    my $filename=$_[1];
    my $custodial=$_[2];
    my $created=$_[3];
    my $typeid=$_[4];
    my $run_n=$_[5];
    my $burst_n=$_[6];
    my $myq = "insert into file (filename,custodiallevel,createtime,filetype_id,run_number,burst_number)";
    $myq.="values ('$filename','$custodial','$created','$typeid','$run_n','$burst_n');"; 
#    print $myq,"\n";
    my $strh = $conn->prepare($myq);
    $strh->execute or die "SQL Error: $DBI::errstr\n";
} 

sub insert_filecopy(){
    my $conn=$_[0];
    my $filename=$_[1];
    my $fileuri=$_[2];
    my $created=$_[3];
    my $filesize=$_[4];
    my $myq = "insert into filecopy (uri,createtime,file_id,size)";
    $myq.="select '$fileuri','$created',id,'$filesize' from file where filename='$filename' limit 1;"; 
#    print $myq,"\n";
    my $strh = $conn->prepare($myq);
    $strh->execute or die "SQL Error: $DBI::errstr\n";
} 

sub timelocal_to_dbtime(){
    (my $sec,my $min,my $hour,my $mday,my $mon,my $year,my $wday, my $yday, my $isdst) = localtime($_[0]);
    my $yyear=1900+$year;
    my $mmon=$mon+1;
    $yyear = sprintf("%04d", $yyear); 
    $mmon = sprintf("%02d", $mmon); 
    $mday = sprintf("%02d", $mday); 
    $hour = sprintf("%02d", $hour); 
    $min = sprintf("%02d", $min); 
    $sec = sprintf("%02d", $sec); 
    my $dbtime="$yyear-$mmon-$mday $hour:$min:$sec\n";
    return $dbtime;
} 


