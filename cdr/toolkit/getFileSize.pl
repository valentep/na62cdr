#!/usr/bin/perl -w
# Author: Ulrich Fuchs (Ulrich.Fuchs@cern.ch) 2000
# Modified: Massimo Lamanna (Massimo.Lamanna@cern.ch) June 2000
#
# The input parameter is a @dir containing the full path
# of the directories. The output is a %run with key the
# filename (without the directory) and value a string
# containing the mask (0 missing, 1 present)
#
# In the comments there is a small example program
#
# Main change is that the hash has a single value, which 
# can be seen as a bit map of found/missing files. 
# This makes easier printout and handling of trigger conditions (?)
#
# $Id: getFileSize.pl,v 1.1 2003/09/23 09:28:00 objsrvvy Exp $

require 5.004;

use strict;
use diagnostics;

# Small test program
#
# my($bkmdir)="/shift/ccf018d/data01/objsrvvy/bkm";
# my(%run) = 
#     getFileSize("$bkmdir/OnlineDataStart",
#	         "$bkmdir/OnlineTransferStop",
#	         "$bkmdir/DumpTransfersStart",
#	         "$bkmdir/DumpTransferStop");
# foreach (keys %run) {
#     print "$_ $run{$_}[0]\n";
# }

sub getFileSize(){

  my(@dir) = @_; # Input: list of full specified directories
  
  my(%run)=();   # Output: hash of file names (stripped) and mask
  
  for (my($i)=0;$i<=$#dir;$i++)
  {   
    if (opendir(DIR,$dir[$i])) 
    {
      my($entry);
      while ( defined( $entry = readdir(DIR)) )
      {
	my $fileName = $entry;
	my $ttt = $entry;
#  	if( $ttt =~ /^cdr\d{2,2}\-\d{5,5}_\d{3,3}\.raw/ )
	if( $ttt =~ /^cdrpcco[er]b\d{2,2}-\d{3,6}.\d{3,3}.raw/ )
	{
	  $_ = $entry;
#	  /(\w{3,3})(\d{2,2})\-(\d{5,5})\_(\d{3,3})\.raw/ ;
#	  my $newname = "$1$2$4-$3.dat";
	  /cdrpcco[er]b(\d{2,2})\-(\d{3,6})\.(\d{3,3})\.raw/ ;
	  my $newname = "cdr$1$3-$2.dat";
#		    print("getFileSize: old name: $entry\nnew file name: ", $newname,"\n");
	  $entry = $newname;
	}
	if( $ttt =~ /^cdrpcco[er]b\d{2,2}-\d{3,6}.raw/ )
	{
	  $_ = $entry;
#	  /(\w{3,3})(\d{2,2})\-(\d{5,5})\_(\d{3,3})\.raw/ ;
#	  my $newname = "$1$2$4-$3.dat";
	  /cdrpcco[er]b(\d{2,2})\-(\d{3,6})\.raw/ ;
	  my $newname = "cdr$1-$2.dat";
#		    print("getFileSize: old name: $entry\nnew file name: ", $newname,"\n");
	  $entry = $newname;
	}
#match to be improved: 
	if (
	    $entry=~/^cdr([\d-]*)(\.dat)$/   # 5-5.dat format
	    ||
	    $entry=~/^cdr\d{5,6}$/           # 6-digit run number
	    ||
	    $entry=~/^cdr([\d\-_]*)(\.raw)$/   # lars.raw format
	    )
	{
	  my($key) = $&;
	  if (! (defined $run{$key}[0])){  # found new run !
	    $run{$key}[0] = (-s "$dir[$i]/$fileName");
	  }
	  else {
	    $run{$key}[0] += (-s "$dir[$i]/$fileName");
	  }
	}
      }
      closedir(DIR);
    }
    else {
      print "$0: cannot open $dir[$i]: $!\n";
    }

  }  
  return %run;

}

sub getDirSize()
{
  
  my($dir) = $_[0]; # Input: directory's name
  my($dirSize) = 0;
  if (opendir(DIR,$dir))
  {
    my($entry);
    while ( defined( $entry = readdir(DIR)) )
    {
      if( $entry =~ /^\./ ){ next; }
      $dirSize += (-s "$dir/$entry");
    }
  }
  return $dirSize;
}

sub getDataFileName(){

  my(@dir) = @_; # Input: list of full specified directories
  
  my(%run)=();   # Output: hash of file names (stripped) and mask
  
  for (my($i)=0;$i<=$#dir;$i++)
  {   
    if (opendir(DIR,$dir[$i])) 
    {
      my($entry);
      while ( defined( $entry = readdir(DIR)) )
      {
	my $fileName = $entry;
	my $ttt = $entry;
#	if( $ttt =~ /^cdr\d{2,2}\-\d{5,5}_\d{3,3}\.raw/ )
	if( $ttt =~ /^cdrpcco[er]b\d{2,2}-\d{3,6}.\d{3,3}.raw/ )
	{
	  $_ = $entry;
#	  /(\w{3,3})(\d{2,2})\-(\d{5,5})\_(\d{3,3})\.raw/ ;
#	  my $newname = "$1$2$4-$3.dat";
	  /cdrpcco[er]b(\d{2,2})\-(\d{3,6})\.(\d{3,3})\.raw/ ;
	  my $newname = "cdr$1$3-$2.dat";
#		print("getDirSize: old name: $entry\nnew file name: ", $newname,"\n");
	  $entry = $newname;
	}
	if( $ttt =~ /^cdrpcco[er]b\d{2,2}-\d{3,6}.raw/ )
	{
	  $_ = $entry;
#	  /(\w{3,3})(\d{2,2})\-(\d{5,6})\_(\d{3,3})\.raw/ ;
#	  my $newname = "$1$2$4-$3.dat";
	  /cdrpcco[er]b(\d{2,2})\-(\d{3,6})\.raw/ ;
	  my $newname = "cdr$1-$2.dat";
#		print("getDirSize: old name: $entry\nnew file name: ", $newname,"\n");
	  $entry = $newname;
	}
#match to be improved: 
	if (
	    $entry=~/^cdr([\d-]*)(\.dat)$/   # 5-5.dat format
	    ||
	    $entry=~/^cdr\d{3,6}$/           # 6-digit run number
	    ||
	    $entry=~/^cdr([\d\-_]*)(\.raw)$/   # lars.raw format
	    )
	{
	  my($key) = $&;
	  if (! (defined $run{$key}[0])){  # found new file !
	    $run{$key}[0] = $fileName;
	  }
	  else {
	    print("getDataFileName: $entry ERROR\n");
	  }
	}
      }
      closedir(DIR);
    }
    else {
      print "$0: cannot open $dir[$i]: $!\n";
    }

  }  
  return %run;

}
