#!/bin/bash

#disable password for sudo
sed -i '/Defaults[[:space:]]\+!*requiretty/s/^/#/' /etc/sudoers
echo "$ADMINUSER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

ls -la /
# Create Impala scratch directory
numDataDirs=$(ls -la / | grep data | wc -l)
echo "numDataDirs:" $numDataDirs
let endLoopIter=(numDataDirs - 1)
for x in $(seq 0 $endLoopIter)
do 
  echo mkdir -p /data${x}/impala/scratch 
  mkdir -p /data${x}/impala/scratch
  chmod 777 /data${x}/impala/scratch
done

  sed -i.bak "s/^SELINUX=.*$/SELINUX=disabled/" /etc/selinux/config
  setenforce 0
    # stop firewall and disable
  systemctl stop iptables
  systemctl iptables off
  # RHEL 7.x uses firewalld
  systemctl stop firewalld
  systemctl disable firewalld
  # Disable tuned so it does not overwrite sysctl.conf
  service tuned stop
  systemctl disable tuned
  # Disable chrony so it does not conflict with ntpd installed by Director
  systemctl stop chronyd
  systemctl disable chronyd
    # update config to disable IPv6 and disable
  echo "# Disable IPv6" >> /etc/sysctl.conf
  echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
  echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf

 yum install -y ntp
 systemctl start ntpd
 systemctl status ntpd
 yum install -y nscd
 systemctl start nscd
 systemctl status nscd

# echo never | tee -a /sys/kernel/mm/transparent_hugepage/enabled
# echo "echo never | tee -a /sys/kernel/mm/transparent_hugepage/enabled" | tee -a /etc/rc.local
 echo vm.swappiness=1 | tee -a /etc/sysctl.conf
 echo 1 | tee /proc/sys/vm/swappiness
 ifconfig -a >> initialIfconfig.out; who -b >> initialRestart.out

 echo net.ipv4.tcp_timestamps=0 >> /etc/sysctl.conf
 echo net.ipv4.tcp_sack=1 >> /etc/sysctl.conf
 echo net.core.rmem_max=16777216 >> /etc/sysctl.conf
 echo net.core.wmem_max=16777216 >> /etc/sysctl.conf
 echo net.core.rmem_default=8388608 >> /etc/sysctl.conf
 echo net.core.wmem_default=8388608 >> /etc/sysctl.conf
 echo net.core.optmem_max=8388608 >> /etc/sysctl.conf
 echo net.ipv4.tcp_rmem="4096 87380 16777216" >> /etc/sysctl.conf
 echo net.ipv4.tcp_wmem="4096 65536 16777216" >> /etc/sysctl.conf
 echo net.ipv4.tcp_low_latency=1 >> /etc/sysctl.conf
 echo fs.file-max=100000 >> /etc/sysctl.conf

 sed -i "s/defaults        1 1/defaults,noatime        0 0/" /etc/fstab

 echo "* soft nproc 65535" >> /etc/security/limits.conf
 echo "* hard nproc 65535" >> /etc/security/limits.conf
 echo "* soft nofile 65535" >> /etc/security/limits.conf
 echo "* hard nofile 65535" >> /etc/security/limits.conf
 echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
 sysctl -p

 systemctl restart sshd

 ifconfig eth0 txqueuelen 5000
 ethtool -K eth0 tso off 
 ethtool -K eth0 gso off

 echo never > /sys/kernel/mm/transparent_hugepage/defrag
 echo never > /sys/kernel/mm/transparent_hugepage/enabled

wget http://archive.cloudera.com/cm5/redhat/7/x86_64/cm/cloudera-manager.repo -O /etc/yum.repos.d/cloudera-manager.repo
yum-config-manager --disable openlogic
yum install -y java
yum install -y cloudera-manager-agent cloudera-manager-daemons
sed -i 's/^\(server_host=\).*/\1'10.2.18.100'/' /etc/cloudera-scm-agent/config.ini
service cloudera-scm-agent restart
