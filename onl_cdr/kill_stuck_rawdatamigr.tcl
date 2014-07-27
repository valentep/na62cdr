#!/usr/bin/tclsh

# kill processes started more than 6 hours ago
set maxsec 21600

# kill rawdatamigr and rfcp processes
set lpid [ exec pgrep "rawdatamigr|rfcp" ]


foreach ipid $lpid {

  set day 0; set hour 0; set min 0; set sec 0; set dummy "";

  set etime [ exec ps -p $ipid -o etime h ]

  regexp -all {(?:(\d*)-)?(?:0*(\d*):)?0*(\d*):0*(\d*)} $etime dummy day hour min sec
  if { $day == "" } { set day 0 }

  set totsec [ expr $sec + 60*($min + 60*($hour + 24*$day)) ]
  if { $totsec >  $maxsec } { exec kill $ipid }
#  if { $totsec >  $maxsec } { puts "id $ipid" }

#puts "ipid $ipid etime $etime dummy $dummy day $day hour $hour min $min sec $sec totsec $totsec"

}


