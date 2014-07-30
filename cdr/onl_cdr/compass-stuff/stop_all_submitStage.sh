#!/bin/csh

set CCF_ROOT="/home/na62cdr/cdr"

foreach MY_HOST (01)
echo na62merger${MY_HOST}
#touch ${CCF_ROOT}/lockfiles/cleanup_online.pccoeb${MY_HOST}.lock
#touch ${CCF_ROOT}/lockfiles/complete_online.pccoeb${MY_HOST}.lock
#touch ${CCF_ROOT}/lockfiles/interface_online.pccoeb${MY_HOST}.lock
touch ${CCF_ROOT}/lockfiles/submitStage0.na62merger${MY_HOST}.lock
end
