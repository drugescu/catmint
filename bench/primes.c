#include <stdio.h>
static int isPrime(int n) {
  if (n < 2) return 0;
  for (int d = 2; d * d <= n; d++) if (n % d == 0) return 0;
  return 1;
}
int main(void) {
  int count = 0;
  for (int n = 0; n < 2000000; n++) count += isPrime(n);
  printf("%d\n", count);
  return 0;
}
