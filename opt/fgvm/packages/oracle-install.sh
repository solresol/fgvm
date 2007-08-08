#!/usr/bin/ksh

. /etc/opt/fgvm/environ.sh

NECESSARY="/etc/listener.ora /etc/sqlnet.ora /usr/local/bin/oraenv /usr/local/bin/dbhome /etc/oratab /sbin/init.d/oracle /etc/rc.config.d/oracle"

for PARTITION in $*
do
  for file in $NECESSARY
  do
    if [ ! -f ${FGVM_ROOTS}/${PARTITION}${file} ]
    then
        echo "The necessary file $file is missing from $PARTITION"
        exit 1
    fi
  done
  if [ ! -d ${FGVM_ROOTS}/${PARTITION}/u01/app ]
  then
     echo "The /u01/app directory of $PARTITION is missing."
     exit 1
  fi
  if grep -q oracle ${FGVM_ROOTS}/${PARTITION}/etc/passwd
  then
     if [ ! -d ${FGVM_ROOTS}/${PARTITION}$(grep oracle ${FGVM_ROOTS}/${PARTITION}/etc/passwd | cut -d: -f6) ]
     then
        echo "The oracle user's home directory is missing"
        exit 1
     fi
     if $FGVM_BIN_DIR/pu ${PARTITION} ls -ld $(grep oracle ${FGVM_ROOTS}/${PARTITION}/etc/passwd | cut -d: -f6) | grep -q oracle
     then
       :   # good
     else
         echo "The user oracle doesn't seem to own their home directory."
         exit 1
     fi

  else
     echo "There is no user called 'oracle' defined in /etc/passwd"
     exit 1
  fi

  default_name="$PARTITION"
  echo "What is the hostname associated with $PARTITION? [$default_name] \c"
  read desired_name
  if [ "$desired_name" = "" ] 
  then
     desired_name="$default_name"
  fi
  LISTENER_CONF="$FGVM_ROOTS/${PARTITION}/etc/listener.ora"
  cp -p $LISTENER_CONF /tmp/listerner.ora.$PARTITION
  sed 's/(Host = [^)]*)/'"(Host = $desired_name"'\)/' ${FGVM_ROOTS}/${PARTITION}/etc/listener.ora > /tmp/listener.ora.$PARTITION
  mv /tmp/listener.ora.$PARTITION ${FGVM_ROOTS}/${PARTITION}/etc/listener.ora
done


