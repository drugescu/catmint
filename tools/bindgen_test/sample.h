/* A header written to exercise tools/bindgen.py: every kind of thing it
 * binds, and every kind it must refuse with a reason. */
#include <stddef.h>
#include <stdint.h>

#define SAMPLE_FLAG 0x20u
#define SAMPLE_BIG 0xFFFFFFFFu
#define SAMPLE_NEG (-5)
#define SAMPLE_POS(x) (0x2FFF0000u | (x))
#define SAMPLE_CENTERED SAMPLE_POS(0)
#define SAMPLE_NAME "not a number"
#define OTHER_VALUE 99          /* a second prefix, bound by a second pattern */

typedef enum { SAMPLE_RED = 1, SAMPLE_GREEN, SAMPLE_BLUE = 10 } SampleColor;

typedef struct { int32_t x, y; } SamplePoint;

typedef struct SampleThing SampleThing;   /* opaque: only ever a pointer */

typedef struct SampleRecord {
  uint8_t tag;
  SamplePoint at;
  double weight;
  uint16_t id;
  char name[6];
  const char *label;
  float ratio;
  SampleColor color;
} SampleRecord;

typedef union {
  uint32_t word;
  uint8_t bytes[4];
  SamplePoint pt;
} SampleBits;

typedef struct {          /* bitfields: sized, not described */
  unsigned a : 3;
  unsigned b : 5;
  int c;
} SamplePacked;

typedef struct {          /* holds the packed one: must still lay out */
  char first;
  SamplePacked packed;
  int32_t last;
} SampleHolder;

int32_t sample_sum(const SampleRecord *r);
void sample_fill(SampleRecord *r);
SampleThing *sample_make(int32_t id);
int32_t sample_id(const SampleThing *t);
void sample_free(SampleThing *t);
uint32_t sample_word(const SampleBits *b);
size_t sample_length(const char *s);
int32_t sample_holder_last(const SampleHolder *h);
void sample_count(int32_t *out);

/* What `long` is depends on the target: 8 bytes here, 4 on Windows. */
typedef struct {
  long a;
  unsigned long b;
  long long c;
  unsigned long long d;
  char e;
} SampleWide;

long sample_wide_sum(const SampleWide *w);
const char *sample_name(int32_t id);            /* static text, or NULL */
char *sample_dup(const char *s);                /* malloc'd: stays a Ptr */
void sample_release(char *p);

/* Callbacks. A typedef; a function pointer written out in a parameter; one
 * that cannot be bound because it takes a struct by value; and atexit, which
 * installs a handler C runs when the process exits and is never bound. */
typedef int32_t (*SampleVisit)(void *userdata, int32_t index);
typedef void (*SampleSpoiled)(SamplePoint point);
void sample_each(int32_t n, SampleVisit fn, void *userdata);
int32_t sample_largest(const int64_t *values, int32_t count,
                       int32_t (*better)(int64_t candidate, int64_t current));
void sample_spoiled(SampleSpoiled handler);
typedef void (*SampleTick)(void *userdata);     /* called from a thread of the library's */
void sample_every(SampleTick fn, void *userdata);
int atexit(void (*function)(void));

int sample_printf(const char *fmt, ...);        /* variadic */
int sample_log(const char *fmt, ...) __attribute__((format(printf, 1, 2)));
SamplePoint sample_origin(void);                /* a struct by value */
static inline int sample_inline(int x) { return x; }
