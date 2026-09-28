#include <cstdio>
struct Fib { virtual int fib(int n) { return n < 2 ? n : fib(n - 1) + fib(n - 2); } };
int main() { Fib f; std::printf("%d\n", f.fib(35)); return 0; }
