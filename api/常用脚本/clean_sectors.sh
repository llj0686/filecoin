#!/bin/bash

#c_unseal () 
#{
#  for n in `cat /tmp/twq`
#  do
#  lotus-miner sectors status $n | egrep 'SectorID|Status' | grep -B 1 'Removed' | grep 'ID' | awk '{print $2}'
#  done
#  return $n
#}
#根据各机器任务数量修改下面awk的if判断,默认为24
lotus-miner sealing  jobs|awk 'NR>1{host[$4":"$5]+=1}END{for(i in host)print i,host[i]}'|sort -nk2 |column -t | grep 'PC1' | awk '{if ($2 < 24)print $1}' | awk -F 'p1-' '{print $2}' | awk -F ':' '{print $1}' | sed 's/\-/\./g' > /tmp/ip_list
for i in `cat /tmp/ip_list`
do

ssh -nq $i "ls /opt/raid0/workercache/unsealed/ | awk -F '-' '{print $3}'" | awk -F '-' '{print $3}' > /tmp/twq_p1.sectors

echo > /tmp/twq_p1.fail

for n in `cat /tmp/twq_p1.sectors`
do
lotus-miner sectors status $n | egrep 'SectorID|Status' | grep -B 1 'Removed' | grep 'ID' | awk '{print $2}' >> /tmp/twq_p1.fail
done

for m in `cat /tmp/twq_p1.fail`
do	
miner_id=`ssh -nq $i "hostname" | awk -F '-p1' '{print $1}' | awk -F 'f' '{print "s-t"$2}'`
echo $miner_id
ssh -nq $i "find /opt/raid0/workercache/ -name "$miner_id-$m" | xargs rm -rf"
done
done


fin_num=`ssh -nq $i "ps aux | grep 'cp -r' | grep -v grep | wc -l"`
apx_pid=`ssh -nq $i "ps -ef | grep apx | grep -v grep " | awk '{print $2}'`

#if [ `cat /tmp/twq_p1.fail | wc -l` -ne 0 ];then
     if [ $fin_num -eq 0 ];then
	     ssh -nq $i "kill -9 $apx_pid"
             apx_pid=`ssh -nq $i "ps -ef | grep apx | grep -v grep " | awk '{print $2}'`
	     if [ ! $apx_pid ];then
		    ssh -nq $i "bash /opt/lotusworker/start_apx.sh"
		    apx_pid=`ssh -nq $i "ps -ef | grep apx | grep -v grep" | awk '{print $2}'`
		    if [ ! $apx_pid ];then
			    echo 'APX fail!'
			    exit 1
		    fi
	     fi
     fi
#fi
	     
ssh -nq $i "ls /opt/raid0/workercache/sealed/ | awk -F '-' '{print $3}'" | awk -F '-' '{print $3}' > /tmp/twq_p1.sectors

echo > /tmp/twq_p1.fail

for n in `cat /tmp/twq_p1.sectors`
do
lotus-miner sectors status $n | egrep 'SectorID|Status' | grep -B 1 'Removed' | grep 'ID' | awk '{print $2}' >> /tmp/twq_p1.fail
done

for m in `cat /tmp/twq_p1.fail`
do
miner_id=`ssh -nq $i "hostname" | awk -F '-p1' '{print $1}' | awk -F 'f' '{print "s-t"$2}'`
ssh -nq $i "find /opt/raid0/workercache/ -name "$miner_id-$m" | xargs rm -rf"

fin_num=`ssh -nq $i "ps aux | grep 'cp -r' | grep -v grep | wc -l"`
apx_pid=`ssh -nq $i "ps -ef | grep apx | grep -v grep"| awk '{print $2}'`
#if [ `cat /tmp/twq_p1.fail | wc -l` -ne 0 ];then
     if [ $fin_num -eq 0 ];then
             ssh -nq $i "kill -9 $apx_pid"
             apx_pid=`ssh -nq $i "ps -ef | grep apx | grep -v grep"| awk '{print $2}'`
             if [ ! $apx_pid ];then
                    ssh -nq $i "bash /opt/lotusworker/start_apx.sh"
                    apx_pid=`ssh -nq $i "ps -ef | grep apx | grep -v grep"| awk '{print $2}'`
                    if [ ! $apx_pid ];then
                            echo 'APX fail!'
                            exit 1
                    fi
             fi
     fi
#fi
done

