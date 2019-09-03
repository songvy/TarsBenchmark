#!/bin/bash
NIC="enp10s0f0"

irq_list=`cat /proc/interrupts | grep ${NIC} | cut -d: -f1`

get_stat() 
{
  for irq in $irq_list
  do
    cpu=`cat /proc/irq/${irq}/smp_affinity_list`
    #echo "--$irq : $cpu--"
    # tr -s 替换重复的字符，保留一个
    val=`cat /proc/interrupts | grep "$irq:" | tr -s ' ' |cut -d" " -f$((cpu+2))`
    #echo "===$val"
    echo "$cpu $irq $val" >> irq$1.txt
  done
}

cal_stat() 
{
  while read cpu irq_num irq_s ii jj irq_e
  do
     #echo "---$irq_num: $irq_s - $irq_e"
     #st=`expr $irq_e - $irq_s`
     ((st=$irq_e-$irq_s))
     echo "$cpu $irq_num: $st"
  done < irq3.txt 
}

rm -f irq1.txt irq2.txt
get_stat 1
sleep 20
get_stat 2
paste irq1.txt irq2.txt > irq3.txt

cal_stat
