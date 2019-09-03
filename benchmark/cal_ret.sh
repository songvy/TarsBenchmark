#!/bin/bash

curdir=$(cd `dirname $0`;pwd)
res_dir=${curdir}/result

if [[ $# -lt 4 ]];then
  echo "Usage: $0 [file] [callTime] [threadNum] [process] [size]"
  exit 1
fi

file=$1
ct=$2
thread=$3
process=$4
size=$5
cat ${res_dir}/${file} | grep 'this process time:' | awk '{print $4}' > tmp

sum=0

while read val
do
  t_s=$(($val/1000))
  total=$(($ct*$thread))
  tps=$(($total/$t_s))
  sum=$(($tps+$sum))
done < tmp
N=$(($thread*$process*1000))
#avg_t=`echo "scale=2; $N/$sum" | bc`
avg_t=`echo $N $sum | awk '{ printf "%0.3f\n" ,$1/$2}'`

echo "calculate tps for $file -- callTime: $ct threads: $thread size:$size tps = $sum time=$avg_t ms"
if [ ! -f $res_dir/result ]; then
   echo -e "Data\t\t\t Process\t Thread\t callTime\t size\t TPS\t\t Avg_time(ms)" > $res_dir/result
fi
dt=`date +"%Y-%m-%d %H:%M:%S"`
echo -e "${dt}\t ${process}\t\t ${thread}\t ${ct}\t\t ${size}\t ${sum}\t\t ${avg_t}" >> $res_dir/result

rm -r tmp
