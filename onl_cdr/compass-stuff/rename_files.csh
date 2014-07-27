#!/bin/tcsh

foreach ii (/merger/tmp/*)

  echo $ii
  set jj=`echo $ii | awk '{t1=gsub("tmp","cdr");  t2=gsub("rpd","cdr",$t1); print $t2}' -`
  echo "mv $ii $jj"
  mv  $ii $jj

end
