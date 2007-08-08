#!/usr/bin/ksh

. /etc/opt/fgvm/environ.sh

ALL_PARTITIONS=$(cat $FGVM_PARTITION_LIST)

if [ $# -eq 0 ]
then
   echo "Starting all partitions"
   for p in $ALL_PARTITIONS
   do
      echo "Starting $p"
      $0 $p
   done
else
   while [ "$*" != "" ]
   do
    PARTITION_NAME=$1
    echo "Checking root filesystem"
    fsck /dev/vg${PARTITION_NAME}partition/rroot
    echo "Mounting root filesystem of $PARTITION_NAME"
    mount /dev/vg${PARTITION_NAME}partition/root ${FGVM_ROOTS}/${PARTITION_NAME}
    echo "Mounting filesystems of $PARTITION_NAME"
    $FGVM_ISL_DIR/mountall.pl $PARTITION_NAME
    if [ "$DONT_FIX_PARTITIONED_PRINTERS" != ""  ]
    then
      echo "Fixing printers into $PARTITION_NAME"
      $FGVM_BIN_DIR/plpsetup $PARTITION_NAME
    fi
    if [ "$DONT_FIX_PARTITION_DEVICES" != "" ]
    then
      echo "Thinking about updating device files in $PARTITION_NAME"
      $FGVM_BIN_DIR/pdevupdate $PARTITION_NAME
    fi
    echo "Running /sbin/init.partition of $PARTITION_NAME"
    chroot $FGVM_ROOTS/${PARTITION_NAME} /sbin/init.partition
    shift
  done
fi
