#!/bin/bash
#

RES=$(amixer get Master | grep "Front Left:" | awk '{ if ($6 == "[off]") {print "[0%]"} else {print $5}}')
#echo -e $RES
#RES="[30%]"
RES=${RES##"["}
RES=${RES%%"%]"}
echo -n $RES #> /tmp/vollevel.out
