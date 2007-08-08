/* Must be compiled +D64 if possible unless HP fixes the bug in 
   pstat_getproc for 32-bit binaries within 64-bit HP-UX */

/* Released under GPL.
   Code developed by Greg Baker (greg.baker@aptec.net.au,
                                 gbaker@postgrad.mq.edu.au)
   Development funded by Franklins. (www.franklins.com.au)
   Copyright (c) 1999.
*/

/* 
 The idea behind this program is that we want to preserve all the
 nice options of HP-UX's /usr/bin/ps,  but only show processes
 which have the same root as we do.  In this way,  processes within
 one "partition" don't see each other,  and don't see top level
 processes either.
 
 We don't want to rewrite ps from scratch,  nor could I snaffle any
 appropriate code that uses pstat_getproc (the only way to get process
 information on HP-UX 11, it seems).
 
 In each chroot'ed environment,  ps is going to get replaced by this
 program.  However,  the original ps is copied over into REAL_PS_LOCATION.
 So we fork off a copy of REAL_PS_LOCATION with the arguments we were
 given,  and change our own argv to something more descriptive.
 
 Then we read the output from REAL_PS_LOCATION,  and guess which column
 range is the printout of the PID.  We check that PID's root, and if it's 
 the same as ours,  we print out that line.  Otherwise,  we suppress it.
 
 Simple, eh? 

 This was a 38-line Perl program,  but because of issues when it
 was run from a setuid script,  it had to be converted.  
*/


#include <stdio.h>
#include <stdlib.h>
#include <sys/param.h>
#include <sys/pstat.h>
#include <string.h>
#include <sys/errno.h>

#define             REAL_PS_LOCATION            "/usr/lbin/global-ps"
#define             MAXIMUM_LINE_LENGTH		1000
struct psfileid     file_id_of_my_root;
int                 column_where_pid_is_given;
char                rcsid[]                      = "$Id$";


/*********************************************************************/

int file_ids_are_the_same(fileid1,fileid2) 
  struct psfileid *fileid1;
  struct psfileid *fileid2;
{
  return (fileid1->psf_fsid.psfs_id == fileid2->psf_fsid.psfs_id) &&
         (fileid1->psf_fileid == fileid2->psf_fileid);
}
 
 
/*********************************************************************/ 

void die (message) 
  char *message; 
{ 
 fprintf(stderr,"ps died; ");
 perror(message);
 exit(1);
}	 
 
/*********************************************************************/ 

int file_id_of_root_directory_of_process(process_id,fileid) 
  int process_id;
  struct psfileid * fileid;
{ 
 struct pst_status details;  /* for fields,  look at sys/pstat.h  */

 if (pstat_getproc(&details, sizeof(details), (size_t)0, process_id) == -1) 
 {
    if (ESRCH == errno) { return -1; }
    die("pstat_getproc(...)");
 }
 *fileid = details.pst_rdir; /* the root directory of */
 return 0;
}

/********************************************************************/

void reconnect_input_to_a_ps_output (argv)
 char* argv[];
{
 int pipe_fd[2];
 int pid;
 
 if (pipe(pipe_fd) == -1) { die ("pipe()"); }
 pid = fork();
 if (pid == -1) { die ("fork()"); }
 if (pid == 0) {
    if (close(1)==-1) { die ("close(1) -- stdout "); }
    if (dup(pipe_fd[1])==-1) { die ("dup(pipe_fd[1])"); }
    if (close(pipe_fd[0])==-1) { die ("close(pipe_fd[0])"); }
    if (execv(REAL_PS_LOCATION,argv)==-1) 
     { die ("execv(REAL_PS_LOCATION,argv)"); }
 }  
 if (close(0)==-1) { die ("close(0) -- stdin "); }
 if (dup(pipe_fd[0])==-1) { die ("dup(pipe_fd[0])"); }
 if (close(pipe_fd[1])==-1) { die ("close(pipe_fd[1])"); }
 return;
}

/**********************************************************************/

/*
$line1 = <PS>;
$pid_start_column = index($line1,'PID')-2;
$pid_column_width =6;
*/

void guess_PID_column () {
 char line[MAXIMUM_LINE_LENGTH];
 char *position;
 
 if (fgets(line,MAXIMUM_LINE_LENGTH,stdin)==NULL) {
  if (feof(stdin)) {
      fprintf(stderr,"Unexpected end of file read from child by ps-filter\n");
      exit(1);
  }
  die("fgets(line,MAXIMUM_LINE_LENGTH,stdin) ");
 }
 position=strstr(line,"PID");
 if (position==NULL) {
   fprintf(stderr,"ps-filter could not find the string PID anywhere in the\n");
   fprintf(stderr,"first line of the output of %s. Died.\n",REAL_PS_LOCATION);
   exit(1);
 };
 column_where_pid_is_given = (position-line) - 2;
}


void read_pid_lines() {
 char line[MAXIMUM_LINE_LENGTH];
 char pidstr[MAXIMUM_LINE_LENGTH];
 int pid;
 struct psfileid target_root;
 
 while (1) {
   if (fgets(line,MAXIMUM_LINE_LENGTH,stdin)==NULL) {
       if (feof(stdin))  break;
       die("fgets(line,MAXIMUM_LINE_LENGTH,stdin)");
   }
   if (strlen(line)<column_where_pid_is_given) {
     fprintf(stderr,"The following line was probably corrupt:\n %s\n",line);
   }
   pid = atoi(line+column_where_pid_is_given);
   /* pid = 0 could either mean the swapper,  or a bad line.
      Gulp.  We silently ignore either case. */
   if ((pid) &&
       (file_id_of_root_directory_of_process(pid,&target_root) == 0) &&
       (file_ids_are_the_same(&target_root,&file_id_of_my_root))
       ) {
         fputs(line,stdout);
      } 
  }
}


/**********************************************************************/

int main (argc,argv) 
   int argc;
   char *argv[];
{
 /* special messages */
 if ((argc == 2) && (strcmp(argv[1],"--version")==0)) {
   printf("fgvm.ps: %s\n",rcsid);
   exit(0);
 }
  
 /* get our root filesystem's file id,  so that we can compare others' */
 if (file_id_of_root_directory_of_process(getpid(),&file_id_of_my_root) == -1)
 {
   die ("Kind of surreal, can't pstat_getproc myself. Maybe I don'texist.\n");
 }
 
 /* create a "real" ps,  because we don't have
 access to the source code of ps,  so therefore we have to 
 just process its output */
 reconnect_input_to_a_ps_output(argv);
 
 /* everything's ready now.  We can read through our standard
 input,  and find the first line (which should have the PID column
 in it somewhere),  work out its position,  and start processing
 the remaining input lines. */
 
 /* for fun,  and just to make things a little more transparent
 for the poor sysadmin suffering under this,  we cover ourselves.
 This is likely to occur before REAL_PS_LOCATION has even parsed
 its command line options. */

 argv[2] = NULL; 
 argv[1] = "filtering out processes not in the same chroot";

 /* this chops out the first line of the output */
 guess_PID_column();

 /* this reads the remainder */
 read_pid_lines();
}

