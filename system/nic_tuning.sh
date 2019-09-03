#!/bin/bash

NIC_INTERFACE="enp9s0f1"

#Disable IRQ Balance
sudo systemctl stop irqbalance

#find interrupts related to PCI bus
irq_list=`cat /proc/interrupts | grep ${NIC_INTERFACE} | cut -d: -f1`

function set_affinity() 
{
  #bind irq from cpu 0-(riq numbers -1)
  cpu=0
  for irq_num in ${irq_list}
  do
    #((affinity=(1<<${cpu})))
    echo "set $irq_num smp_affinity as cpu $cpu"
    echo ${cpu} | sudo tee /proc/irq/${irq_num}/smp_affinity_list
    let cpu+=1
  done
}

function check_affinity()
{
  for irq_num in $irq_list
  do
    echo "-----------${irq_num}----------------"
    cat /proc/irq/${irq_num}/smp_affinity
    cat /proc/irq/${irq_num}/smp_affinity_list
  done
}

case "$1" in
  config)
        echo "configure smp_affinity: "
        set_affinity
        check_affinity
        ;;
  stop)
        echo "Stopping is not supported. "
        ;;
  status)
        check_affinity
        ;;
  *)
        echo "Usage: $0 [config|status]"
        ;;
esac

exit 0


