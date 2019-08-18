#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

int main(int argc, char *argv[])
{
  char *s, *inpnam=NULL, *rawnam=NULL, notestr[16384], numstr[16];
  unsigned char *buf, *dat, *data;
  int fdinp, fdraw, highlight=0, note=0, offset=14;
  unsigned hbeg, hblen, hend, helen, nbeg, nblen, nend, nelen, flen;
  struct stat sbuf;
  FILE *fhraw=NULL;

  s = *argv++;
  while ((s = *argv++)) {
    if (*s == '-') switch(*++s) {
      case 'i': inpnam = *argv++; break;
      case 'h': highlight = 1; break;
      case 'n': note = 1; break;
      case 'o': offset = atoi(*argv++); break;
      case 'r': rawnam = *argv++; break;
    }
  }
  if (rawnam) fhraw = fopen(rawnam, "r");
  if (!(highlight || note)) note = 1;
  if (stat(inpnam, &sbuf)) {
    fprintf(stderr, "Can't stat input file: '%s'!\n", inpnam);
    exit(1);
  }
  if ((fdinp = open(inpnam, O_RDONLY)) < 0) {
    fprintf(stderr, "Can't open input file: '%s'!\n", inpnam);
    exit(1);
  }
  dat = buf = mmap(0, sbuf.st_size, PROT_READ, MAP_SHARED, fdinp, 0);
  while(dat - buf < sbuf.st_size) {
    if (highlight) if (!strncmp(dat, "annotation.personal.highlight", 29)) {
      if (dat[29] == 3) {
        dat += 30;
        hblen = (dat[0]*256 + dat[1])*256 + dat[2]; dat += 3;
        strncpy(numstr, dat, hblen); numstr[hblen] = 0;
        sscanf(numstr, "%u", &hbeg); dat += hblen;
      } else {
        fprintf(stderr, "File synchronization lost.\n");
        goto NEXTbyte;
      }
      if (dat[0] == 3) {
        dat++;
        helen = (dat[0]*256 + dat[1])*256 + dat[2]; dat += 3;
        strncpy(numstr, dat, helen); numstr[helen] = 0;
        sscanf(numstr, "%u", &hend); dat += helen;
      } else {
        fprintf(stderr, "File synchronization lost.\n");
        goto NEXTbyte;
      }
      if (fhraw) { int n;
        fseek(fhraw, hbeg + offset, SEEK_SET);
        n = fread(notestr, 1, hend - hbeg + 1, fhraw);
        notestr[n] = 0;
      }
      printf("%u\t%u\tHighlight:", hbeg, hend);
      if (fhraw) { printf("\t'%s'\n", notestr); } else printf("\n");
    }
    if (note) if (!strncmp(dat, "annotation.personal.note", 24)) {
      if (dat[24] == 3) {
        dat += 25;
        nblen = (dat[0]*256 + dat[1])*256 + dat[2]; dat += 3;
        strncpy(numstr, dat, nblen); numstr[nblen] = 0;
        sscanf(numstr, "%u", &nbeg); dat += nblen;
      } else {
        fprintf(stderr, "File syncnronization lost.\n");
        goto NEXTbyte;
      }
      if (dat[0] == 3) {
        dat++;
        nelen = (dat[0]*256 + dat[1])*256 + dat[2]; dat += 3;
        strncpy(numstr, dat, nelen); numstr[nelen] = 0;
        sscanf(numstr, "%u", &nend); dat += nelen;
      } else {
        fprintf(stderr, "File syncnronization lost.\n");
        goto NEXTbyte;
      }
      if (dat[0] == 2) {
        dat++;
        flen = (dat[0]*256 + dat[1])*256 + dat[2]; dat += 3; dat += flen;
        BadB2: while (dat[0] != 2) dat++;
        dat++;
        if (dat[0]) goto BadB2;
        flen = (dat[0]*256 + dat[1])*256 + dat[2]; dat += 3; dat += flen;
        while (dat[0] != 3) dat++;
        dat++;
        flen = (dat[0]*256 + dat[1])*256 + dat[2]; dat += 3; dat += flen;
        while (dat[0] != 3) dat++;
        dat++;
        flen = (dat[0]*256 + dat[1])*256 + dat[2]; dat += 3;
        if (flen > 16383) flen = 16383;
        strncpy(notestr, dat, flen); notestr[flen] = 0;
      } else {
        fprintf(stderr, "File syncnronization lost.\n");
        goto NEXTbyte;
      }
      printf("%u\t%u\tNote:\t'%s'\n", nbeg, nend, notestr);
    }
    NEXTbyte: dat++;
  }
}
