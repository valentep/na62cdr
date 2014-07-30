#!/bin/bash

export MY_HOST=`hostname -s`
echo $MY_HOST
export CCF_ROOT=`grep CCF_ROOT $HOME/.ccfrc | sed 's/CCF_ROOT//' | sed 's/ //g'`
echo $CCF_ROOT
touch ${CCF_ROOT}/lockfiles/complete_online.${MY_HOST}.lock
