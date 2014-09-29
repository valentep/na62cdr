require 5.004;
use strict;
use diagnostics;
use Time::Local;
use Sys::Hostname;   # Uli
#####
use File::Basename;
use DBI;



sub get_tables;
sub get_fileinfo;
sub get_filetype;
sub insert_file;
sub insert_filecopy;


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
    my $dbtime="$yyear-$mon-$mday $hour:$min:$sec\n";
    return $dbtime;
} 
