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
	$mountpoint = "$FGVM_ROOTS/$PARTITION_NAME" . $mountpoint;
	$cmd = "umount $mountpoint";
	print "Running $cmd\n";
	system("$cmd");
   }
}
