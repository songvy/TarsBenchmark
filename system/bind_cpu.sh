#!/bin/bash
pid=`pgrep TarsStressServe`
pref=${pid:0:3}
tids=`pidstat -t -p $pid | grep $pref | awk '{print $5}'`

#echo $tids
cpu=3

# server thread:
#   total: tars servcie + handle thread + net thread
#   tars service:  9 [fixed]
num_ts=9
#   handle thread: 5 [configured]
num_handle=5
#   net thread:    8 [configured]
num_net=8

n=1
# reverse tid list, bind net thread first.
tids_list=$(echo $tids | sed -s 's/-//g' | tac -s " ")
#echo $tids_list

function bind_cpu_seq()
{
for tid in $tids
do
  if [[ $tid != "-" ]]; then
    echo "tid=$tid , cpu=$cpu"
    taskset -cp $cpu $tid
    let cpu+=1
  fi
done
}

function bind_cpu_same()
{
   i=0
   j=0
   for tid in $tids
   do
      if [[ $tid != "-" && $j < $num_ts ]]; then
	 echo "bind $tid to $cpu"
	 taskset -cp $cpu $tid
         let cpu+=1
	 let j+=1
      fi
   done

   num=$(($num_net+$num_handle))
   cpu_end=$(($cpu+$num_net-1))
   hand_cpu_s=$(($cpu+28))
   hand_cpu_e=$(($cpu_end+28))

   for tid in $tids_list
   do
       if [ $i -lt $num_net ]; then
          # bind net thread
	  echo "bind tid $tid on cpu $cpu-$cpu_end"
          taskset -cp $cpu-$cpu_end $tid
       elif [ $i -lt $num ]; then
	  # bind handle thread
	  echo "bind tid $tid on cpu $hand_cpu_s-$hand_cpu_e"
	  taskset -cp $hand_cpu_s-$hand_cpu_e $tid
       fi
       let i+=1

   done
}

function check_bind ()
{
  pidstat -t -p $pid
}

case "$1" in
  sequence)
        echo -n "Bind thread to sequence and different cpu: "
        bind_cpu_seq
	sleep 5
        check_bind
        ;;
  same)
        echo -n "Bind net and handle thread both on $num_net cpus"
	bind_cpu_same
	sleep 5
	check_bind
        ;;
  restart|reload|force-reload)
        echo -n "Restart is not supported. "
        ;;
  status)
        check_bind
        ;;
  *)
        echo "Usage: $0 [sequence|same|status]"
        ;;
esac

exit 0
