#!/bin/csh

set CCF_ROOT="/online/detector/cdr"

set logfile="/tmp/ccf/onl_cdr/inspect.log"
set dirreports="/online/detector/cdr/reports/"
set hostn=`hostname -s`

/bin/cp $logfile "$dirreports/inspect_$hostn.log"

