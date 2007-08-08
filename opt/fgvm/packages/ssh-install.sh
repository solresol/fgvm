#!/usr/bin/ksh

. /etc/opt/fgvm/environ.sh

PARTITION_NAMES=$*

for PARTITION in $PARTITION_NAMES
do
  PARTITION_ROOT=${FGVM_ROOTS}/${PARTITION}
  if [ -f ${PARTITION_ROOT}/etc/partition/netconf ]
  then
   .  ${PARTITION_ROOT}/etc/partition/netconf 
    
   if [ "$INTERFACE_NAME" != "" -a "$IP_ADDRESS" != "" -a "$NETMASK" != "" ]
   then 
    SSHD_CONFIG=${PARTITION_ROOT}/etc/sshd_config
    cp -p $SSHD_CONFIG /tmp/sshd_config.${PARTITION}
    sed 's/^ListenAddress.*$/ListenAddress '"$IP_ADDRESS"/ ${SSHD_CONFIG} > /tmp/sshd_config.${PARTITION}
    mv /tmp/sshd_config.${PARTITION} ${PARTITION_ROOT}/etc/sshd_config
   else
    echo "INTERFACE_NAME, IP_ADDRESS and NETMASK are not all defined."
    echo "Will not configure ssh on this partition ($PARTITION)"
   fi

  else
   echo "Partition $PARTITION does not have /etc/partition/netconf"
 fi
done
