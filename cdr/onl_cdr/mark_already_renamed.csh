#!/bin/csh


# used to add bookmark for data files which have been already renamed to
# the cdr1200x-32109.dat format

#set host=`uname -n`

#set bkmdir="/shift/$host/data01/objsrvvy/bkm"
set bkmdir="/data/bkm"

set bkfile=$1

cp $bkmdir/OnlineDataStop/$bkfile $bkmdir/OnlineDataComplete/$bkfile

