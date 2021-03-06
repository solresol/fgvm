#!/usr/contrib/bin/perl


VG:
foreach $volume_group (@ARGV) {
   if ((system("vgdisplay $volume_group 2> /dev/null > /dev/null") >> 8) == 0) {
	next VG;
   }
   print "Do you want me to create $volume_group for you? ";
   $answer = <STDIN>;
   if ($answer !~ /^[yY]/) {
      exit(1);
   }
   $group_minor_nums = `/usr/bin/ls -l /dev/vg*/group | cut -c42-49`;
   foreach $n (split(/\s+/,$group_minor_nums)) {
      $t = hex($n);
      $used_minor{$t} = 1;
   #   print "$t found\n";
   }
   for ($minor_num=0;
        $used_minor{$minor_num}==1;
        $minor_num+=hex("0x010000")
   ) {}
   printf ( "I will create it with minor number 0x0%x\n",$minor_num);
   print "I will ask for some pvcreated disks and some uncreated disks\n";
   print "\nYou do not need to give the part after /dev/dsk. \n";
   print "i.e.  c0t6d0 is ok.\n";
   print "Enter the device names of some pvcreate'd disks: ";
   $already_pvcreated = <STDIN>; chop($already_pvcreated);
   print "Enter the device names of some unused disks: ";
   $need_pvcreating = <STDIN>; chop($need_pvcreating);
   foreach $disk (split(/\s+/,$need_pvcreating)) {
	$disk =~ s:^/dev/dsk/::;
	system("pvcreate /dev/rdsk/$disk");
   }
   @disknames = ();
   foreach $disk ((split(/\s+/,$need_pvcreating)) , (split(/\s+/,$already_pvcreated))) {	
	$disk =~ s:^/dev/dsk/::;
	@disknames = (@disknames,"/dev/dsk/".$disk);
   }
   print "mkdir $volume_group\n";
   mkdir("$volume_group", 0755);
   print "mknod $volume_group/group c 64 $minor_num\n";
   system("mknod $volume_group/group c 64 $minor_num");
   print "vgcreate $volume_group @disknames\n";
   system("vgcreate","$volume_group",@disknames);
}

