#!/bin/bash

export MY_HOST=`hostname -s`
echo $MY_HOST
export CCF_ROOT=`grep CCF_ROOT $HOME/.ccfrc | sed 's/CCF_ROOT//' | sed 's/ //g'`

/usr/bin/k5start -U -f ~/na62cdr.keytab -b -K 60 -l 61m -- $CCF_ROOT/onl_cdr/submitStage0.pl
