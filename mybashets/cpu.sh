#!/bin/bash
id=$1
id=${id:=[0-9]*}
for i in /sys/devices/system/cpu/cpu$id/cpufreq ; do
   max=`sudo cat $i/cpuinfo_max_freq`
   cur=`sudo cat $i/cpuinfo_cur_freq`
   per=$(($cur*100/$max))
   echo $max $cur $per
done
