/* A C library that calls back, for tools/callback_test: the cases libc's qsort
 * cannot show. Built by clang, like the library the binding generator's test
 * uses; nothing here ships. */
#include <pthread.h>
#include <stdint.h>

typedef int32_t (*cb_each_fn)(void *userdata, int32_t index);
typedef void (*cb_once_fn)(void *userdata);
typedef uint32_t (*cb_wide_fn)(uint8_t small, uint16_t medium, uint32_t large,
                               int64_t big, double d, float f);
typedef struct { int32_t a; int32_t b; } cb_pair;
typedef int32_t (*cb_pair_fn)(cb_pair *pair, void *userdata);

/* The sum of fn(userdata, 0), fn(userdata, 1), ... fn(userdata, n - 1). */
int64_t cb_sum(int32_t n, cb_each_fn fn, void *userdata) {
  int64_t total = 0;
  for (int32_t i = 0; i < n; i++) total += fn(userdata, i);
  return total;
}

void cb_once(cb_once_fn fn, void *userdata) { fn(userdata); }

/* Every width at once; what the callback returns comes back. */
uint32_t cb_wide(cb_wide_fn fn) {
  return fn(200, 60000, 4000000000u, -5000000000LL, 2.5, 0.5f);
}

int32_t cb_pair_call(cb_pair_fn fn, void *userdata) {
  cb_pair pair = {3, 4};
  return fn(&pair, userdata);
}

/* From a thread of C's own, which the program must refuse to run on. */
static void *thread_body(void *arg) {
  void **both = arg;
  ((cb_once_fn)both[0])(both[1]);
  return 0;
}

void cb_from_thread(cb_once_fn fn, void *userdata) {
  void *both[2] = {(void *)fn, userdata};
  pthread_t thread;
  pthread_create(&thread, 0, thread_body, both);
  pthread_join(thread, 0);
}

/* Arguments narrower than an int. Compiled by clang this takes each one from
 * its register as it finds it, because the ABI (Apple's arm64, and clang's own
 * callers everywhere) has the caller extend it to 32 bits first. A caller that
 * only truncates leaves the rest of the register as it was, and the sum is
 * wrong by whatever was there. */
__attribute__((noinline)) uint32_t cb_narrow(uint8_t a, uint16_t b, uint8_t c) {
  return (uint32_t)a + (uint32_t)b + (uint32_t)c;
}
