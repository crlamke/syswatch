#!/bin/bash 
#Description : This script prints basic system stats until
#              the user stops it. It will keep an ssh session
#              alive like top but with lower overhead.
#Project Home: https://github.com/crlamke/syswatch
#Copyright   : 2021 Christopher R Lamke
#License     : MIT - See https://opensource.org/licenses/MIT

# Set up header and data display formats
divider="-------------------------------------------------------------------------------"
headerFormat="%-12s %-15s %-16s %-24s %-8s"
dataFormat="%-12s %-15s %-16s %-24s %-8s"

#timeHeader="Sys Time   Uptime   Watch Runtime"
#memHeader="RAM Avail   RAM Total   RAM %Free"
#loadHeader="Sys Load  1 Min   5 Min   15 Min"


# The updateInterval determines how many seconds this script will sleep
# between system info updates.
updateInterval=5

#When $exitScript becomes non-zero, exit the script.
exitScript=0

procCount=$(getconf _NPROCESSORS_ONLN)


# Name: getElapsedTimeString
# Parameters: elapsedSeconds
# Description: This function accepts an integer number of seconds
#              and returns an elapsed time string.
function getElapsedTimeString()
{
  elapsedDays=$(($1 / 86400))
  remainderSecs=$(($1 % 86400))
  elapsedHours=$(($remainderSecs / 3600)) 
  remainderSecs=$(($remainderSecs % 3600))
  elapsedMinutes=$(($remainderSecs / 60)) 
  elapsedSeconds=$(($remainderSecs % 60))
  echo "${elapsedDays}d:${elapsedHours}h:${elapsedMinutes}m:${elapsedSeconds}s"
}


# Name: getMemStatsString
# Parameters: None
# Description: This function returns a string containing current mem stats.
function getMemStatsString()
{
  memAvailable=$(grep 'MemAvailable:' /proc/meminfo | \
               awk '{print int($2 / 1024)}')
  memTotal=$(grep 'MemTotal:' /proc/meminfo | \
               awk '{print int($2 / 1024)}')
  memPercentFree=$((${memAvailable} * 100 / ${memTotal}))

  echo "${memAvailable}MB/${memTotal}MB/${memPercentFree}%"
}


# Name: getLoadStatsString
# Parameters: None
# Description: This function returns a string containing current system load stats.
function getLoadStatsString()
{
  sysLoad=$(cat /proc/loadavg)
  oneMinLoad=$(echo $sysLoad | awk '{print $1;}')
  fiveMinLoad=$(echo $sysLoad | awk '{print $2;}')
  fifteenMinLoad=$(echo $sysLoad | awk '{print $3;}')
  echo "${oneMinLoad}/${fiveMinLoad}/${fifteenMinLoad}"
}


# Name: updateSystemInfo
# Parameters: none
# Description: This function updates the system information display.
function updateSystemInfo()
{
  duration=$SECONDS
  elapsed=$(getElapsedTimeString $duration);
  memPrint=$(getMemStatsString); 
  sysLoad=$(getLoadStatsString);
  uptime=$(cat /proc/uptime | awk '{print int($1)}')
  uptimePrint=$(getElapsedTimeString $uptime);
  serverTime=$(date +"%T")

  printf "$dataFormat \r" $serverTime $elapsed $uptimePrint $memPrint $sysLoad

}


# Trap ctrl + c 
trap ctrl_c INT
function ctrl_c() 
{
  printf "\n\nctrl-c received. Exiting\n"
  exit
}

function getCommandLine()
{
echo "params: $@";
  currentPosition=1;
  maxPosition=$#;
echo $currentPosition $maxPosition;
  while [[ $currentPosition -le $maxPosition ]];
  do
    case "$1" in
      -u)
        shift 1;
        currentPosition=$currentPosition+1;
        updateInterval=$1;;
      -t) 
        shift 1;
        currentPosition=$currentPosition+1;
        totalTime=$1;;
      -l)
        shift 1;
        currentPosition=$currentPosition+1;
        logging=$1;;
      -h)
         showUsage;
         exitScript=1;
         break;;
      *) echo Invalid option: $1;
         showUsage;
         exitScript=1;
         break;;
    esac
    shift 1;
    currentPosition=$currentPosition+1;
  done
echo "update interval=$updateInterval" "logging=$logging" "totalTime=$totalTime"
}

function showUsage()
{
  echo "$0 is a system monitor script that displays and tracks system resources."
  echo
  echo "Usage: $0 [-u updateSeconds] [-t monitorMinutes] [-l logfile]"
  echo "Options:"
  echo "-u  Change the update interval in seconds. Default is 5"
  echo "-t  Run monitor script for monitorMinutes minutes and then exit."
  echo "-l  Enable logging to logfile."
  echo
}

function setup()
{
  # Print headers and data such as hostname and IP
  # that won't change over script run.
  hostName=$(hostname)
  hostIP=$(hostname -I)

  printf "\nHostname: %s\tIPs: %s\n" "$hostName" "$hostIP"
  printf "%s\n" "$divider"
  printf "%s\n\n" "$timeHeader"
  printf "%s\n" "$divider"
  printf "%s\n\n" "$memHeader"
  printf "%s\n" "$divider"
  printf "%s\n\n" "$loadHeader"
}

function shutdown()
{
  exit 0
}

function mainLoop()
{


  # Enter loop, updating transient system info every $updateInterval seconds
  while true; do
    updateSystemInfo
    read -t $updateInterval -n1
    if [ $? == 0 ]; then
      exit 0
    fi
  done
}


###
# Start script execution
###

#getCommandLine $@

#if [ $exitScript -ne 0 ]; then
#  shutdown
#fi

#setup

#mainLoop

# Print headers and data such as hostname and IP
# that (probably) won't change over script run.
hostName=$(hostname)
printf "\nHostname: %s\n\n" $hostName

ipInfo="Interface State IP\n"
IFS=" "
while read -r interface state ip
do
  ipInfo+="$interface $state $ip\n"
done <<< $(ip -4 -br a | grep -v "127.0.0.1")
echo -e $ipInfo | column -t -s " "

printf "%s\n" $divider
printf "$headerFormat \n" "Sys Time" "Idle Period" "Sys Uptime" "RAM Avail/Total/Free%" "Sys Load 1m/5m/15m"

# Enter loop, updating transient system info every updateInterval interval
while true; do 
  updateSystemInfo
  read -t $updateInterval -n1
  if [ $? == 0 ]; then
    exit 0
  fi
done
