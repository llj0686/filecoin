cpumodel="7542" # 7371|7532|7t83
apipath="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJBbGxvdyI6WyJyZWFkIiwid3JpdGUiLCJzaWduIiwiYWRtaW4iXX0.XjevynIo4R6eLj6vI1_Nq7OJ1db63sR0t6gbl6LjuBI:/ip4/192.168.143.56/tcp/2345/http"
numanum=8

################################## lotus-worker ######################################
# DOWNLOADURL=http://download.zhianidc.com/application/filecoin
# AUTH=''
# VERSION='mainnet+git.f49144640'

# curl -u "$AUTH" ${DOWNLOADURL}/lotus-worker-${VERSION}.tar.gz  -o /tmp/lotus-worker-${VERSION}.tar.gz 
# mkdir /opt/lotusworker/
# tar xf /tmp/lotus-worker+${VERSION}.tar.gz -C /opt/lotusworker/

######################################环境#####################################
swapoff -a && sed -i  '/swap/d'  /etc/fstab
# 内存大页配置
echo 'GRUB_CMDLINE_LINUX_DEFAULT="default_hugepagesz=1G hugepagesz=1G"' >>/etc/default/grub
update-grub
echo 'none /opt/hugepages/layer_labels hugetlbfs pagesize=1G,size=1936G 0 0' >>/etc/fstab
mkdir -p /opt/hugepages/layer_labels

cat >/etc/hugepages.sh<<EOF
#!/bin/bash
echo 252| tee /sys/devices/system/node/node{{0..1},{3..6}}/hugepages/hugepages-1048576kB/nr_hugepages
echo 220| tee /sys/devices/system/node/node2/hugepages/hugepages-1048576kB/nr_hugepages
echo 230| tee /sys/devices/system/node/node7/hugepages/hugepages-1048576kB/nr_hugepages
EOF
chmod +x /etc/hugepages.sh
cat >/etc/systemd/system/hugepages.service<<EOF
[Unit]
Description=hugepages
After=network-online.target 
[Service]
Type=simple
User=root
ExecStart=/etc/hugepages.sh
[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now hugepages


# 内核参数优化
cat >/etc/security/limits.d/20-nproc.conf<<EOF
*          soft    nproc     102400
root       soft    nproc     unlimited
EOF
cat >/etc/security/limits.conf<<EOF
*               soft    nofile          10000000
*               hard    nofile          10000000
root            soft    nofile          10000000
root            hard    nofile          10000000
*               soft    noproc          65000
*               hard    noproc          65000
EOF

cat >/etc/sysctl.conf<<EOF
fs.file-max=10000000
fs.nr_open=10000000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 204800
net.ipv4.tcp_max_tw_buckets = 204800
net.ipv4.tcp_max_orphans = 204800
net.core.netdev_max_backlog = 204800
net.core.somaxconn = 131070
vm.swappiness = 0
net.unix.max_dgram_qlen = 128
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.neigh.default.gc_thresh1 = 512
net.ipv4.neigh.default.gc_thresh2 = 28672
net.ipv4.neigh.default.gc_thresh3 = 32768
vm.dirty_background_ratio = 15
vm.dirty_ratio = 20
vm.dirty_expire_centisecs = 6000
EOF
sysctl -p

sed -i "/DefaultLimitNOFILE/c DefaultLimitNOFILE=10000000" /etc/systemd/system.conf
sed -i "/DefaultLimitNPROC/c DefaultLimitNPROC=10000000" /etc/systemd/system.conf
systemctl daemon-reexec


# 安装依赖
apt update -y
apt install -y tcpdump bash-completion bc net-tools mtr traceroute psmisc tcptrack nload ntpdate lsof tree lrzsz wget glances rsync zip unzip tcptraceroute hwloc ipmitool nvidia-driver-460 tmux nfs-common -y

# 时间同步
timedatectl set-timezone Asia/Shanghai
(crontab -l;echo "*/1 *  *  *  *  /usr/sbin/ntpdate cn.pool.ntp.org &>/dev/null") |crontab

# ceph软件包
curl -fsSL http://mirrors.aliyun.com/ceph/keys/release.asc | apt-key add -
echo deb https://mirrors.aliyun.com/ceph/debian-nautilus/ $(lsb_release -sc) main > /etc/apt/sources.list.d/ceph.list
apt update
apt install ceph-common=14.* ceph-fuse=14.* -y






###################

case $cpumodel in 
    7542)
        p1config="""
worker-1p1=0,1=0
worker-2p1=2,3=0
worker-3p1=4,5=0
worker-4p1=6,7=0,1
worker-5p1=8,9=1
worker-6p1=10,11=1
worker-7p1=12=1
worker-8p1=13=1,2
worker-9p1=26=3
worker-10p1=27=3
worker-11p1=28,29=3
worker-12p1=30,31=3,4
worker-13p1=32,33=4
worker-14p1=34,35=4
worker-15p1=36,37=4
worker-16p1=38,39=4,5
worker-17p1=40,41=5
worker-18p1=42,43=5
worker-19p1=44,45=5
worker-20p1=46,47=5,6
worker-21p1=48=6
worker-22p1=49=6
worker-23p1=52=7
worker-24p1=53=6,7
"""
    P2C2CPU1="14,15,16,17,18,19,20,21,22,23,24,25"
    P2C2CPU2="50,51,54,55,56,57,58,59,60,61,62,63"
    ARGS="""
# P1
export FIL_PROOFS_SDR_PARENTS_CACHE=524288
"""
    ;;
    7371)
        p1config="""
worker-1p1=0=0
worker-2p1=2=0
worker-3p1=4=1
worker-4p1=6=1
worker-5p1=8=2
worker-6p1=10=2
worker-7p1=12=3
worker-8p1=14=3
worker-9p1=16=4
worker-10p1=18=4
worker-11p1=20=5
worker-12p1=22=5
worker-13p1=28=7
worker-14p1=30=7
"""
    P2CPU="24,26,25,27"
	ARGS="""
# P1
export FIL_PROOFS_SDR_PARENTS_CACHE=524288
"""
    ;;

    7352)
        p1config="""
worker-1p1=0=0
worker-2p1=2=0
worker-3p1=3=0
worker-4p1=6=1
worker-5p1=8=1
worker-6p1=9=1
worker-7p1=18=3
worker-8p1=20=3
worker-9p1=21=3
worker-10p1=24=4
worker-11p1=26=4
worker-12p1=27=4
worker-13p1=30=5
worker-14p1=32=5
worker-15p1=33=5
worker-16p1=36=6
worker-17p1=38=6
worker-18p1=39=6
"""
    P2C2CPU1="1,2,3,5,6,7,23"
    P2C2CPU2="9,10,11,13,14,15,31"
    ARGS="""
# P1
export FIL_PROOFS_SDR_PARENTS_CACHE=524288
"""
    ;;
    7532)
        p1config="""
worker-1p1=0=0
worker-2p1=2=0
worker-3p1=4=0 
worker-4p1=8=1 
worker-5p1=10=1
worker-6p1=12=1
worker-7p1=16=2
worker-8p1=18=2
worker-9p1=20=2
worker-10p1=24=3
worker-11p1=26=3
worker-12p1=28=3
worker-13p1=32=4 
worker-14p1=34=4 
worker-15p1=36=4 
worker-16p1=40=5 
worker-17p1=42=5
worker-18p1=44=5
worker-19p1=48=6
worker-20p1=50=6
worker-21p1=52=6

"""
    P2CPU="56,57,58,59,60,61,62,63"
	ARGS="""
# P1 slo
export FIL_PROOFS_SDR_PARENTS_CACHE=524288
"""
    ;;
    7t83)
        p1config="""
worker-1p1=0,1=0
worker-2p1=8,9=0,1
worker-3p1=16,17=1 
worker-4p1=24,25=1,2 
worker-5p1=32,33=2 
worker-6p1=40,41=2,3 
worker-7p1=48,49=3
worker-8p1=56,57=3,4
worker-9p1=64,65=4 
worker-10p1=72,73=4,5
worker-11p1=80,81=5
worker-12p1=88,89=5,6 
worker-13p1=96,97=6
worker-14p1=104,105=6,7
"""
    P2CPU="112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,106,107,108,109,110,111"
	ARGS="""
# P1 multi-thread
export FIL_PROOFS_SDR_PARENTS_CACHE_SIZE=1048576
export FIL_PROOFS_USE_MULTICORE_SDR=true
export FIL_PROOFS_MULTICORE_SDR_PRODUCERS=1
export FIL_PROOFS_MULTICORE_SDR_LOOKAHEAD=4096
export FIL_PROOFS_MULTICORE_SDR_PRODUCER_STRIDE=128
"""
    ;;
esac

################################## 大页######################################


################################## APx 工作环境生成 ######################################
rootpath=/opt
workpath=$rootpath/lotusworker
cachepath=$rootpath/raid0

mkdir -p $workpath
cat >$workpath/profile<<EOF
export MINER_API_INFO="$apipath"
export SECTOR_TYPE=32GB
EOF

mkdir -p $workpath/worker-apx/
cat >$workpath/worker-apx/start_apx.sh <<EOF
#!/bin/bash
source $workpath/profile
ip=\`hostname -I|awk '{print \$1}'\`
#groupid=\${ip##*.}
dir=\`dirname \$(readlink -f "\$0")\`
currdir=\${dir##*/}
bindir=\${dir%/*}
taskp1n=\`echo \${dir##*/}|sed -nr 's#.*-([0-9]+)p1#\1#p'\`
port=\$((\$taskp1n+11000))

export RUST_LOG=info
export TMPDIR=/opt/raid0/
export PIECE_TEMPLATE_DIR=/opt/raid0/piecetemplate/

nohup \${bindir}/lotus-worker --worker-repo \${bindir}/\$currdir run --no-local-storage --role APx --group \${ip} --listen \${ip}:\${port} > \${bindir}/\$currdir/log.txt 2>&1 &
EOF

##### APx初始化脚本 #####
cat >$workpath/worker-apx/init_apx.sh<<EOF
ip=\`hostname -I|awk '{print \$1}'\`
#groupid=\${ip##*.}
source $workpath/profile
export  LOTUS_WORKER_PATH=${workpath}/worker-apx
bash $workpath/worker-apx/start_apx.sh
sleep 5
mkdir -p ${cachepath}/workercache
${workpath}/lotus-worker storage attach --init --seal --maxsealing 50 --group \${ip} ${cachepath}/workercache
#ps aux|awk '/[w]orker-apx/{print "kill "\$2}'|bash 
EOF

##### APx启动脚本 #####
cat >$workpath/start_apx.sh<<EOF
bash $workpath/worker-apx/start_apx.sh
EOF


################################## P1 工作环境生成 ######################################

for i in $p1config
do 
    dir=`echo $i|awk -F'=' '{print $1}'`
    cpulist=`echo $i|awk -F'=' '{print $2}'`
    scrname=`echo ${dir##*-}`
    numaid=`echo $i|awk -F'=' '{print $3}'`
    #echo $workpath/$dir $cpu $role $port $scrname
    mkdir -p $workpath/$dir    
    
cat >$workpath/$dir/start_${scrname}.sh<<EOF
#!/bin/bash
source $workpath/profile
ip=\`hostname -I|awk '{print \$1}'\`
#groupid=\${ip##*.}
dir=\`dirname \$(readlink -f "\$0")\`
currdir=\${dir##*/}
bindir=\${dir%/*}
taskp1n=\`echo \${dir##*/}|sed -nr 's#.*-([0-9]+)p1#\1#p'\`
port=\$((\$taskp1n+10000))
# cpu limits
export CPU_LIST=$cpulist
export FIL_PROOFS_CC_CPU_SET_STR=\$CPU_LIST
$ARGS
export FIL_PROOFS_MAX_NUMA_NODE=$numanum
export FIL_PROOFS_NUMA_NODE=$numaid
export FIL_PROOFS_HUGEPAGES_MOUNT_PATH=/opt/hugepages/layer_labels/\${taskp1n}p1
export FIL_PROOFS_PARENT_CACHE=/opt/raid0/filecoin-parents
export TMPDIR=/opt/raid0/
export MERKLE_TREE_CACHE=/opt/raid0/merklecache/mcache.dat
# skip proof parameters fetch and check
export no_fetch_params=true
export RUST_LOG=info

mkdir -p \$FIL_PROOFS_HUGEPAGES_MOUNT_PATH
nohup \${bindir}/lotus-worker --worker-repo \${bindir}/\$currdir run --no-local-storage --role P1 --group \${ip} --listen \${ip}:\${port} > \${bindir}/\$currdir/log.txt 2>&1 &
EOF
done

##### P1启动脚本 #####
cat >$workpath/start_p1.sh<<EOF
pgrep lotus -a|awk '/P1/{print "kill "\$1}'|bash 
rm -rf /opt/hugepages/layer_labels/*
sleep 1
for i in {1..24}
do
   bash $workpath/worker-\${i}p1/start_\${i}p1.sh
  sleep 30
done
EOF

################################## P2C2 工作环境生成 ######################################
mkdir -p $workpath/worker-1p2c2/
mkdir -p $workpath/worker-2p2c2/
cat >$workpath/worker-1p2c2/start_1p2c2.sh <<EOF
#!/bin/bash
source /opt/lotusworker/profile
ip=\`hostname -I|awk '{print \$1}'\`
#groupid=$(echo $ip|awk -F '.' 'BEGIN{OFS="#"}{print $3,$4}')
dir=\`dirname \$(readlink -f "\$0")\`
currdir=\${dir##*/}
bindir=\${dir%/*}
taskp1n=\`echo \${dir##*/}|sed -nr 's#.*-([0-9]+)p1#\1#p'\`
port=\$((\$taskp1n+21000))

# cpu limits
export CPU_LIST=$P2C2CPU1
export FIL_PROOFS_CC_CPU_SET_STR=$P2C2CPU1


export FIL_PROOFS_MAX_NUMA_NODE=$numanum
export FIL_PROOFS_NUMA_NODE=2
export FIL_PROOFS_PARAMETER_CACHE=/opt/raid0/filecoin-proof-parameters
export TMPDIR=/opt/raid0/


# skip proof parameters fetch and check
export no_fetch_params=true
export RUST_LOG=info

# P2
export mimalloc_reserve_huge_os_pages=200
export mimalloc_reserve_os_memory=10737418240
export mimalloc_verbose=1
export mimalloc_use_numa_offset=2
export mimalloc_use_numa_nodes=$numanum


export FIL_PROOFS_POOL_LIMIT=30
export FIL_PROOFS_USE_GPU_COLUMN_BUILDER=true
export FIL_PROOFS_MAX_GPU_COLUMN_BATCH_SIZE=500000
export FIL_PROOFS_COLUMN_WRITE_BATCH_SIZE=8388608
export FIL_PROOFS_USE_GPU_TREE_BUILDER=true
export FIL_PROOFS_MAX_GPU_TREE_BATCH_SIZE=7000000
export FIL_PROOFS_COLUMN_PARALLEL=4
export FIL_PROOFS_TREE_R_PARALLEL=2

export NEPTUNE_DEFAULT_GPU=33


# C2
export BELLMAN_CPU_SET=16,17,18,19,20,21,22,23
export BELLMAN_GPU_SET=33
export BELLMAN_GPU_BUS_ID=33

export BELLMAN_SYNTHESIZE_BATCH=4
export BELLMAN_FFT_BATCH=4
export BELLMAN_EXP_BATCH=4


nohup taskset --cpu \$CPU_LIST \${bindir}/lotus-worker --worker-repo \${bindir}/\$currdir run --no-local-storage --role P2C2 --group \${ip} --listen \${ip}:\${port} > \${bindir}/\$currdir/log.txt 2>&1 &
EOF


cat >$workpath/worker-2p2c2/start_2p2c2.sh <<EOF
#!/bin/bash
source /opt/lotusworker/profile
ip=\`hostname -I|awk '{print \$1}'\`
#groupid=$(echo $ip|awk -F '.' 'BEGIN{OFS="#"}{print $3,$4}')
dir=\`dirname \$(readlink -f "\$0")\`
currdir=\${dir##*/}
bindir=\${dir%/*}
taskp1n=\`echo \${dir##*/}|sed -nr 's#.*-([0-9]+)p1#\1#p'\`
port=\$((\$taskp1n+22000))

# cpu limits
export CPU_LIST=$P2C2CPU2
export FIL_PROOFS_CC_CPU_SET_STR=$P2C2CPU2


export FIL_PROOFS_MAX_NUMA_NODE=$numanum
export FIL_PROOFS_NUMA_NODE=7
export FIL_PROOFS_PARAMETER_CACHE=/opt/raid0/filecoin-proof-parameters
export TMPDIR=/opt/raid0/


# skip proof parameters fetch and check
export no_fetch_params=true
export RUST_LOG=info

# P2
export mimalloc_reserve_huge_os_pages=200
export mimalloc_reserve_os_memory=10737418240
export mimalloc_verbose=1
export mimalloc_use_numa_offset=7
export mimalloc_use_numa_nodes=$numanum


export FIL_PROOFS_POOL_LIMIT=30
export FIL_PROOFS_USE_GPU_COLUMN_BUILDER=true
export FIL_PROOFS_MAX_GPU_COLUMN_BATCH_SIZE=500000
export FIL_PROOFS_COLUMN_WRITE_BATCH_SIZE=8388608
export FIL_PROOFS_USE_GPU_TREE_BUILDER=true
export FIL_PROOFS_MAX_GPU_TREE_BATCH_SIZE=7000000
export FIL_PROOFS_COLUMN_PARALLEL=4
export FIL_PROOFS_TREE_R_PARALLEL=2

export NEPTUNE_DEFAULT_GPU=129


# C2
export BELLMAN_CPU_SET=56,57,58,59,60,61,62,63
export BELLMAN_GPU_SET=129
export BELLMAN_GPU_BUS_ID=129

export BELLMAN_SYNTHESIZE_BATCH=4
export BELLMAN_FFT_BATCH=4
export BELLMAN_EXP_BATCH=4



nohup taskset --cpu \$CPU_LIST \${bindir}/lotus-worker --worker-repo \${bindir}/\$currdir run --no-local-storage --role P2C2 --group \${ip} --listen \${ip}:\${port} > \${bindir}/\$currdir/log.txt 2>&1 &
EOF



cat >$workpath/start_p2c2.sh<<EOF
bash $workpath/worker-1p2c2/start_1p2c2.sh
bash $workpath/worker-2p2c2/start_2p2c2.sh
EOF



#reboot



