#include <cstdio>
static bool isPrime(int n) {
  if (n < 2) return false;
  for (int d = 2; d * d <= n; d++) if (n % d == 0) return false;
  return true;
}
int main() {
  int count = 0;
  for (int n = 0; n < 400000; n++) count += isPrime(n) ? 1 : 0;
  std::printf("%d\n", count);
  return 0;
}
