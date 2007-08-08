#!/usr/contrib/bin/perl

require '/etc/opt/fgvm/environ.pl';

foreach $PARTITION_NAME (@ARGV) {
  $fstab = "$FGVM_ROOTS/$PARTITION_NAME/etc/fstab";
  open(FSTAB,$fstab) || die "Can't open $fstab.  Stopped ";
fs:
  while  (<FSTAB>) {
 	next fs if /^#/;
	next fs if /^\s*$/;
	($device,$mountpoint,$fstype,$options,$backupnum,$fsck_num) = split;
	next if $mountpoint =~ m:^/$:;
        @splitdevice = split('/',$device);
        $splitdevice[$#splitdevice] = 'r' . $splitdevice[$#splitdevice];
        $rawdevice = join('/',@splitdevice);
        print "fsk $rawdevice\n";
        system("fsck $rawdevice");
	$mountpoint = "$FGVM_ROOTS/$PARTITION_NAME" . $mountpoint;
	$cmd = "mount -F $fstype -o $options $device $mountpoint";
	print "Running $cmd\n";
	system("$cmd");
   }
}
