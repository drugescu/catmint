/* The same work with malloc and snprintf, freed by hand. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int main(void) {
  long total = 0;
  for (int i = 0; i < 2000000; i++) {
    char *line = malloc(64);
    snprintf(line, 64, "row %d of the table", i);
    total += (long)strlen(line);
    free(line);
  }
  printf("%ld\n", total);
  return 0;
}
