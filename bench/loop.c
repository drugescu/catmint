#include <stdio.h>
int main(void) {
  long long total = 0;
  for (long long i = 0; i < 100000000LL; i++) total += i % 7;
  printf("%lld\n", total);
  return 0;
}
