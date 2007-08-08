$FGVM_ROOTS="/partition";
$FGVM_BIN_DIR="/opt/fgvm";
$FGVM_ISL_DIR="/opt/fgvm/isl";
$FGVM_FSU_DIR="/opt/fgvm/fsu";
$FGVM_PARTITION_LIST="/etc/opt/fgvm/partition.list";
$FGVM_SKELETON_ETC="/opt/fgvm/skel/etc-skel";
$FGVM_SKELETON_SBIN="/opt/fgvm/skel/sbin-skel";
$FGVM_SKELETON_MAN="/opt/fgvm/skel/man-skel";

sub FGVM_PARTITIONS {
  open(FGVM_PARTITION_LIST_FILEHANDLE,$FGVM_PARTITION_LIST)
   || die "Can't open $FGVM_PARTITION_LIST,$!, stopped";
  local(@answer) = ();
  while (<FGVM_PARTITION_LIST_FILEHANDLE>) {
   chop;
   @answer = (@answer,$_);
  }
  close(FGVM_PARTITION_LIST_FILEHANDLE);
  return @answer;
}

sub FGVM_PARTITION_EXISTS {
  local($potential_partition,@junked) = @_;
  local($partition_exists)= 0;
  foreach $partition (&FGVM_PARTITIONS()) {
    if ($potential_partition eq $partition) { 
   $partition_exists = 1;
   }
  }
  return $partition_exists;
}
