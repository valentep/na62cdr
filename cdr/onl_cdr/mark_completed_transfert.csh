#!/bin/csh

# used to mark as transfer completed a file where the OnlineTransferStart is
# missing and where we know that the transfert to castor has been succeeded

# set host=`uname -n`

set bkmdir="/data/bkm"

set bkfile=$1

cp "$bkmdir/OnlineTransferStop/$bkfile" "$bkmdir/OnlineTransferStart"
cp "$bkmdir/OnlineTransferStop/$bkfile" "$bkmdir/OnlineTransferComplete"


