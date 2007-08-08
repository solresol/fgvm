#!/usr/bin/ksh

# Updates files within a partition.
# 
# The following things happen.
#
# All BAD_PROGRAMS (things that affect the whole system)
# are removed.
#
# A bunch of things from /partition/sbin-skel get copied in
#
# /etc/profile gets replaced and has an alias added, and PS1 modified
# /etc/issue.netpartition  gets overwritten
# /etc/partition/netconf gets overwritten if it does not exist

BAD_PROGRAMS="/usr/bin/kill /usr/sbin/shutdown /usr/sbin/reboot /sbin/reboot /sbin/init /sbin/umountall /usr/sbin/inetd"

. /etc/opt/fgvm/environ.sh

PARTITION_NAMES_LIST=$*

if [ "$PARTITION_NAMES_LIST" = "" ]
then
   PARTITION_NAMES_LIST=$(cat $FGVM_PARTITION_LIST)
fi

for PARTITION_NAME in $PARTITION_NAMES_LIST
do 
    echo "   [ $PARTITION_NAME ] "
    PARTITION_ROOT="$FGVM_ROOTS/${PARTITION_NAME}"
    # Unfortunately,  the copying of the toplevel introduces this...
    # I should actually not copy it in the first place.  (And also
    # think about the implications of a partition stored within vg00). 
    rm -rf ${PARTITION_ROOT}/partition ${PARTITION_ROOT}/opt/fgvm ${PARTITION_ROOT}/etc/opt/fgvm ${PARTITION_ROOT}/var/opt/fgvm 
    for program in $BAD_PROGRAMS
    do
      rm -f ${PARTITION_ROOT}/$program
    done

    # We need this for the hacked around ps
    cp /usr/contrib/bin/perl ${PARTITION_ROOT}/sbin
    chmod a+rx ${PARTITION_ROOT}/sbin/perl
    
    # Speaking of hacking around ps...
    if [ -h ${PARTITION_ROOT}/usr/bin/ps ]
    then
      # it's already a symlink.  No problem
      rm ${PARTITION_ROOT}/usr/bin/ps
    elif [ -f ${PARTITION_ROOT}/usr/bin/ps ]
    then
      # must be the original.  Let's move it
      mv ${PARTITION_ROOT}/usr/bin/ps ${PARTITION_ROOT}/usr/lbin/global-ps
    fi
    # whatever,  make the link.
    ln -s /sbin/ps ${PARTITION_ROOT}/usr/bin/ps
    

    rm -f /tmp/netconf.${PARTITION_NAME}
    if [ -f ${PARTITION_ROOT}/etc/partition/netconf ]
    then
        cp ${PARTITION_ROOT}/etc/partition/netconf /tmp/netconf.${PARTITION_NAME}
    fi
    cp -Rp $FGVM_SKELETON_ETC/* ${PARTITION_ROOT}/etc/
    cp -Rp $FGVM_SKELETON_SBIN/* ${PARTITION_ROOT}/sbin/
    cp -Rp $FGVM_SKELETON_MAN/* ${PARTITION_ROOT}/usr/share/man/

    if [ -f /tmp/netconf.${PARTITION_NAME} ]
    then
        cp /tmp/netconf.${PARTITION_NAME} ${PARTITION_ROOT}/etc/partition/netconf 
    fi

    # fun and games with our modified kill
    rm -f ${PARTITION_ROOT}/usr/bin/kill
    ln -s /sbin/kill ${PARTITION_ROOT}/usr/bin/kill
    
    # Make a nice(r) message for incoming telnet.
    cp -p /etc/issue ${PARTITION_ROOT}/etc/issue.netpartition
    # 
    echo "Partition '${PARTITION_NAME}' of "$(hostname)"\n\n\n" >> \
              ${PARTITION_ROOT}/etc/issue.netpartition
    cp -p /etc/profile ${PARTITION_ROOT}/etc
    echo 'PS1="\['${PARTITION_NAME}'\] \$PWD"' >>  \
              ${PARTITION_ROOT}/etc/profile
    echo alias kill=/sbin/kill >> ${PARTITION_ROOT}/etc/profile
    echo export partition=${PARTITION_NAME} >> ${PARTITION_ROOT}/etc/profile
    echo "${PARTITION_NAME}" > ${PARTITION_ROOT}/etc/partitionname
    chmod a+r ${PARTITION_ROOT}/etc/partitionname
done


#${FGVM_BIN_DIR}/plpsetup $PARTITION_NAMES_LIST


