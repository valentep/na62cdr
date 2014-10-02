#!/bin/bash

export MY_HOST=`hostname -s`
echo $MY_HOST
export CCF_ROOT=`grep CCF_ROOT /merger/etc/.ccfrc | sed 's/CCF_ROOT//' | sed 's/ //g'`

$CCF_ROOT/onl_cdr/submitStage0.pl >> /merger/logs/onl_cdr/submitStage0.log 2>&1 &
