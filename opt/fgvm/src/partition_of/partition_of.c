#include <stdio.h>
#include <sys/param.h>
#include <sys/pstat.h>
#include <string.h>

char rcsid[] = "$Id";

int main (argc,argv)
	int argc;
	char *argv[];
{
 struct pst_status target_pst;
 int target;
 int i;

 for(i=1;i< (argc == 1? 2: argc);i++) {
  if (argc != 1) {
   target = atoi(argv[i]);
  } else { 
   target = (int)getpid();
  }

  if (pstat_getproc(&target_pst, sizeof(target_pst), (size_t)0, target) == -1) {
	perror("pstat_getproc");
  }
  printf("%x:%x,%x:%x\n", 
        target_pst.pst_rdir.psf_fsid.psfs_id >> 32,
        target_pst.pst_rdir.psf_fsid.psfs_id & 0xffffffff,
        target_pst.pst_rdir.psf_fileid >> 32,
        target_pst.pst_rdir.psf_fileid & 0xffffffff
  );
 }
}
