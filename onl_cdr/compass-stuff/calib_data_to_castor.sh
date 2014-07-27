#!/bin/csh

set datadir="/data/cdr"
set castordir="/castor/cern.ch/compass/data/2012/raw/calib_data"
# 4 days delay would be enough
# set mintime=345600
# let say 3 days finally
# set mintime=259200
# let say 1 days finally
# set mintime=86400
# delete these fucking files as soon as possible !
# set mintime=10000
# let say 12 hours finally
#set mintime=43200
# let say 4 hours finally :)
set mintime=14400
#set mintime=0

# and do not store them in castor
# set storefiles=0
# finally Claude wants them....
set storefiles=1

echo ""
echo "Copy of calibration data to Castor directory $castordir"
echo ""
date
echo ""

setenv STAGE_HOST "castorpublic"
setenv STAGE_SVCCLASS "compasscdr"
setenv STAGE_POOL "compasscdr"
setenv RFIO_USE_CASTOR_V2 "YES"

cd $datadir

set curtime=`date +"%s"`

foreach ii (cdrpccoeb??-*-t*.*.raw)

  set mtime=`stat -c "%Y" $ii`
  set fsize=`stat -c "%s" $ii`
  @ difftime = $curtime - $mtime

  if ($difftime < $mintime) then
    continue
  endif

  set storefile=$storefiles

#  stat $ii

  # do not copy files that are meant to be processed by
  # the quality assurance system to CASTOR, only delete them
  if ($ii =~ cdrpccoeb??-*-t00000fff.*.raw) then
    set storefile=0
  endif

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
#    rfcp $ii $castordir
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


