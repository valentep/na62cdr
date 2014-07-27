#!/bin/bash

export MY_HOST=`hostname -s`
echo $MY_HOST
export CCF_ROOT="/home/na62cdr/cdr"

rm ${CCF_ROOT}/lockfiles/cleanup_online.${MY_HOST}.lock
rm ${CCF_ROOT}/lockfiles/interface_online.${MY_HOST}.lock
rm ${CCF_ROOT}/lockfiles/submitStage0.${MY_HOST}.lock
rm ${CCF_ROOT}/lockfiles/complete_online.${MY_HOST}.lock
${CCF_ROOT}/onl_cdr/mymaster.pl -quiet&
