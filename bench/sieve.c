#include <stdio.h>
#include <stdlib.h>
int main(void) {
  int limit = 200000;
  char *flags = malloc((size_t)limit);
  for (int i = 0; i < limit; i++) flags[i] = 1;
  for (int p = 2; p * p < limit; p++)
    if (flags[p])
      for (int m = p * p; m < limit; m += p) flags[m] = 0;
  int count = 0;
  for (int n = 2; n < limit; n++) count += flags[n];
  printf("%d\n", count);
  free(flags);
  return 0;
}
