#!/bin/bash

curdir=$(cd `dirname $0`;pwd)
res_dir=${curdir}/result

run_test()
{
  #para: [ProcessNum] [ThreadNum] [size]
  ./teststress.sh $1 $2 $3 > $res_dir/$4
}

cal_result()
{
   # para: [file] [callTime] [threadNum] [process] [size]
   ./cal_ret.sh $1 $2 $3 $4 $5
}

if [[ $# -lt 3 ]];then
  echo "Usage: $0 [ProcessNum] [ThreadNum] [size]"
  exit 1
fi

pn=$1
tn=$2
size=$3
ct=150000
file="${pn}_${tn}_${ct}_${size}.txt"

# run client
run_test ${pn} ${tn} {$size} ${file}

# calculate tps and time, write to result file
cal_result ${file} ${ct} ${tn} ${pn} ${size}
