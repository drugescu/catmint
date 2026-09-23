// The same work with std::string, freed by its destructor.
#include <cstdio>
#include <string>
int main() {
  long total = 0;
  for (int i = 0; i < 2000000; i++) {
    std::string line = "row " + std::to_string(i) + " of the table";
    total += (long)line.size();
  }
  std::printf("%ld\n", total);
  return 0;
}
