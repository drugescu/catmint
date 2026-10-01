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

int sample_printf(const char *fmt, ...);        /* variadic */
SamplePoint sample_origin(void);                /* a struct by value */
static inline int sample_inline(int x) { return x; }
