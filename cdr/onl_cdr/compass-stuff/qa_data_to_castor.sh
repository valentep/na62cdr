#!/bin/csh

set datadir="/data/castor"
set castordir="/castor/cern.ch/compass/data/2012/qa"
#set mintime=14400
set mintime=0

set storefiles=1

echo ""
echo "Copy of QA DST files to Castor directory $castordir"
echo ""
date
echo ""

setenv STAGE_HOST "castorpublic"
setenv STAGE_SVCCLASS "compasscdr"
setenv STAGE_POOL "compasscdr"
setenv RFIO_USE_CASTOR_V2 "YES"

cd $datadir

set curtime=`date +"%s"`

foreach ii (*.root *.root.*)

  set mtime=`stat -c "%Y" $ii`
  set fsize=`stat -c "%s" $ii`
  @ difftime = $curtime - $mtime

  if ($difftime < $mintime) then
    continue
  endif

  set storefile=$storefiles

  if ($fsize == 0) then
    echo "deleting empty file $ii"
    /bin/rm -f $ii
    continue
  endif
  set ret_val=0
  if ($storefile == 1) then
    echo -n "copy of $ii to castor..."
    rfcp $ii $castordir
    set ret_val=$status
  else
    echo -n "do not copy $ii to castor..."
  endif
  if ($ret_val == 0) then
    echo " ...and removing local file"
    /bin/rm -f $ii
  else
    echo "  Error: can't copy $ii to castor !"
    rfrm "$castordir/$ii"
  endif

# avoid to overload EBs and network...
  sleep 10

end


