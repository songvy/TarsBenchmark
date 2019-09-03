#!/bin/bash
# chkconfig: 2345 90 60
### BEGIN INIT INFO
# Provides:          rps
# Required-Start:    $local_fs $remote_fs $network $syslog
# Required-Stop:     $local_fs $remote_fs $network $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: enable rps config for ubuntu
# Description:       enabele rps which is a kernel tweak for network performance
### END INIT INFO

NAME=rps
DESC=rps

# cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
# cpupower frequency-set -g performance
# activate rps/rfs by script: https://gist.github.com/wsgzao/18828f69147635f3e38a14690a633daf
# double ring buffer size: ethtool -G p1p1 [rx|tx] 4096, ethtool -g p1p1
# double NAPI poll budget: sysctl -w net.core.netdev_budget=600

#grep -v 可以实现 NOT 操作。 -v 选项用来实现反选匹配的（ invert match）

rps_start() {
  #net_interface=`ip link show | grep "state UP" | awk '{print $2}' | egrep -v '^docker|^veth' | tr ":\n" " "`

  net_interface="enp9s0f1"
  for em in ${net_interface[@]}
  do
      rq_count=`ls /sys/class/net/$em/queues/rx-* -d | wc -l`
      rps_flow_cnt_value=`expr 32768 / $rq_count`

      for ((i=0; i< $rq_count; i++))
      do
          echo $rps_flow_cnt_value > /sys/class/net/$em/queues/rx-$i/rps_flow_cnt
      done

      flag=0
      while [ -f /sys/class/net/$em/queues/rx-$flag/rps_cpus ]
      do
          echo `cat  /sys/class/net/$em/queues/rx-$flag/rps_cpus | sed 's/0/f/g' ` >  /sys/class/net/$em/queues/rx-$flag/rps_cpus
          flag=$(($flag+1))
      done
  done
  echo 32768 > /proc/sys/net/core/rps_sock_flow_entries
  sysctl -p
}

rps_stop() {
  #net_interface=`ip link show | grep "state UP" | awk '{print $2}' | egrep -v '^docker|^veth' | tr ":\n" " "`
  net_interface="enp9s0f1"

  for em in ${net_interface[@]}
  do
      rq_count=`ls /sys/class/net/$em/queues/rx-* -d | wc -l`
      rps_flow_cnt_value=0

      for ((i=0; i< $rq_count; i++))
      do
          echo $rps_flow_cnt_value > /sys/class/net/$em/queues/rx-$i/rps_flow_cnt
      done

      flag=0
      while [ -f /sys/class/net/$em/queues/rx-$flag/rps_cpus ]
      do
          echo `cat  /sys/class/net/$em/queues/rx-$flag/rps_cpus | sed 's/f/0/g' ` >  /sys/class/net/$em/queues/rx-$flag/rps_cpus
          flag=$(($flag+1))
      done
  done
  echo 0 > /proc/sys/net/core/rps_sock_flow_entries
  sysctl -p
}


check_rps() {
  #ni_list=`ip link show | grep "state UP" | awk '{print $2}' | egrep -v "^docker|^veth" | tr ":\n" " "`
  ni_list="enp9s0f1"

  for n in $ni_list
  do
      rx_queues=`ls /sys/class/net/$n/queues/ | grep "rx-[0-9]"`
      for q in $rx_queues
      do
          rps_cpus=`cat /sys/class/net/$n/queues/$q/rps_cpus`
          rps_flow_cnt=`cat /sys/class/net/$n/queues/$q/rps_flow_cnt`

          echo "[$n]" $q "--> rps_cpus =" $rps_cpus ", rps_flow_cnt =" $rps_flow_cnt
      done
  done
  rps_sock_flow_entries=`cat /proc/sys/net/core/rps_sock_flow_entries`
  echo "rps_sock_flow_entries =" $rps_sock_flow_entries
}

case "$1" in
  start)
        echo -n "Starting $DESC: "
        rps_start
        check_rps
        ;;
  stop)
        echo -n "Stopping $DESC: "
	rps_stop
	check_rps
        ;;
  restart|reload|force-reload)
        echo -n "Restart is not supported. "
        ;;
  status)
        check_rps
        ;;
  *)
        echo "Usage: $0 [start|status|stop]"
        ;;
esac

exit 0
