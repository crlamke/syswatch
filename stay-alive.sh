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

# Name: showAnimation
# Parameters: none
# Description: This function prints the line animation.
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


startTime=`date +%s`


# Trap ctrl + c 
trap ctrl_c INT
function ctrl_c() 
{
  echo "ctrl-c received. Exiting"
  exit
}


# The outer loop will print the time the script has been running and
# then start the single line output. 
while true; do 
  showAnimation
  newTime=`date +%s`
  timeDiff=$newTime-$startTime
#  echo -n "$0 has been running for $timeDiff seconds"
  sleep 2
done

