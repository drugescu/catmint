#include <cstdio>
#include <vector>
int main() {
  int limit = 5000000;
  std::vector<char> flags(limit, 1);
  for (int p = 2; p * p < limit; p++)
    if (flags[p])
      for (int m = p * p; m < limit; m += p) flags[m] = 0;
  int count = 0;
  for (int n = 2; n < limit; n++) count += flags[n];
  std::printf("%d\n", count);
  return 0;
}
