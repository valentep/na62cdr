#!/bin/csh

set CCF_ROOT="/home/na62cdr/cdr"

foreach MY_HOST (01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20)
echo pccoeb${MY_HOST}
#touch ${CCF_ROOT}/lockfiles/cleanup_online.pccoeb${MY_HOST}.lock
#touch ${CCF_ROOT}/lockfiles/complete_online.pccoeb${MY_HOST}.lock
#touch ${CCF_ROOT}/lockfiles/interface_online.pccoeb${MY_HOST}.lock
touch ${CCF_ROOT}/lockfiles/submitStage0_castor2.pccoeb${MY_HOST}.lock
end
