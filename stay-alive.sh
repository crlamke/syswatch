#!/bin/bash 
#
#Script Name : stay-alive.sh
#Description : This script will keep an ssh session alive by running
#              until the user stops it, printing its status on the 
#              command line.
#Author      : Chris Lamke
#Copyright   : 2019 Christopher R Lamke
#License     : MIT - See https://opensource.org/licenses/MIT
#Last Update : 2019 Mar 09
#Version     : 0.1  
#Usage       : stay-alive.sh
#Notes       : 
#

# Set up header and data display formats
divider="------------------------------------------------------------------"
headerFormat="%-10s %-10s %-10s %-16s %-8s"
dataFormat="%-10s %-10s %-10s %-16s %-8s"

# The updateInterval determines how many seconds this script will sleep
# between system info updates.
updateInterval=5


# Name: showAnimation
# Parameters: none
# Description: This function prints a line animation.
function showAnimation()
{
  for i in {1..10} ; do
    echo -n '['
    for ((j=0; j<i; j++)) ; do echo -n ' '; done
    echo -n '=>'
    for ((j=i; j<10; j++)) ; do echo -n ' '; done
    echo -n "] $i"0% $'\r'
    sleep 2
  done
#  echo -n $'\r'
}

# Name: updateSystemInfo
# Parameters: none
# Description: This function updates the system information display.
function updateSystemInfo()
{
  duration=$SECONDS
  hours=$(($duration / 3600)) 
  minutes=$(($duration / 60)) 
  seconds=$(($duration % 60)) 
  elapsed="$(($duration / 3600))h:$(($duration / 60))m:$(($duration % 60))s"
  cpuLoad=$(grep 'cpu ' /proc/stat | \
          awk '{usage=(($2+$3+$4)*100/($2+$3+$4+$5))} \
          END {print usage "%"}')
#  topProcesses=$(ps -Ao comm,pid,pcpu --sort=-pcpu | head -n 3)
  memAvailable=$(grep 'MemAvailable:' /proc/meminfo | \
               awk '{print int($2 / 1024)}')
  memTotal=$(grep 'MemTotal:' /proc/meminfo | awk '{print int($2 / 1024)}')
  memPrint="${memAvailable}MB/${memTotal}MB"
  uptime=$(cat /proc/uptime | awk '{print int($1)}')
  uptimeH=$(($uptime / 3600))
  uptimeM=$(($uptime % 3600 / 60))
  uptimePrint="${uptimeH}h:${uptimeM}m"
  serverTime=$(date +"%T")

  printf "$dataFormat \r" $serverTime $elapsed $uptimePrint $memPrint $cpuLoad

#  printf "\n%s" $topProcesses 
#  $(tput cuul)
  
}


# Trap ctrl + c 
trap ctrl_c INT
function ctrl_c() 
{
  echo "ctrl-c received. Exiting"
  exit
}


# Print headers and data such as hostname and IP
# that won't change over script run.
hostName=$(hostname)
hostIP=$(hostname -i)

printf "\n%s\t%s\n" $hostName $hostIP
printf "%s\n" $divider
printf "$headerFormat \n" "Time" "Idle" "Uptime" "RAM Avail/Total" "CPU Load/Time"

# Enter loop, updating transient system info every updateInterval interval
while true; do 
  updateSystemInfo
  sleep $updateInterval
done

