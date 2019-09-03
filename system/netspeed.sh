#!/bin/bash
 
ethn=enp9s0f1
 
while true
do
 RX_pre=$(cat /proc/net/dev | grep $ethn | sed 's/:/ /g' | awk '{print $2}')
 TX_pre=$(cat /proc/net/dev | grep $ethn | sed 's/:/ /g' | awk '{print $10}')
 sleep 1
 RX_next=$(cat /proc/net/dev | grep $ethn | sed 's/:/ /g' | awk '{print $2}')
 TX_next=$(cat /proc/net/dev | grep $ethn | sed 's/:/ /g' | awk '{print $10}')
 
# clear
 echo -e "\t\t RX `date +%k:%M:%S` TX"
 
 RX=$(((${RX_next}-${RX_pre})*8))
 TX=$(((${TX_next}-${TX_pre})*8))
 
 if [[ $RX -lt 1024 ]];then
 RX="${RX}b/s"
 elif [[ $RX -gt 1048576 ]];then
 RX=$(echo $RX | awk '{print $1/1048576 "Mb/s"}')
 else
 RX=$(echo $RX | awk '{print $1/1024 "Kb/s"}')
 fi
 
 if [[ $TX -lt 1024 ]];then
 TX="${TX}b/s"
 elif [[ $TX -gt 1048576 ]];then
 TX=$(echo $TX | awk '{print $1/1048576 "Mb/s"}')
 else
 TX=$(echo $TX | awk '{print $1/1024 "Kb/s"}')
 fi
 
 echo -e "$ethn \t $RX   $TX "
 
done
