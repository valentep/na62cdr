#!/bin/bash
export MY_HOST=`hostname -s`
echo $MY_HOST
export NA62CASTOR=/castor/cern.ch/na62/
export CCF_ROOT=`grep CCF_ROOT /merger/etc/.ccfrc | sed 's/CCF_ROOT//' | sed 's/ //g'`
export AKLOG="aklog -c cern.ch -k CERN.CH"
k5start -b -t -K 30 -f /merger/etc/na62cdr.keytab na62cdr@CERN.CH -- sh -c '$CCF_ROOT/onl_cdr/submitStage0.pl >> /merger/logs/onl_cdr/submitStage0.log 2>&1'