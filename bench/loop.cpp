#include <cstdio>
int main() {
  long long total = 0;
  for (long long i = 0; i < 100000000LL; i++) total += i % 7;
  std::printf("%lld\n", total);
  return 0;
}
