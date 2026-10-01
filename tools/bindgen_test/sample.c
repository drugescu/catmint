#include "sample.h"
#include <stdlib.h>
#include <string.h>

struct SampleThing { int32_t id; };

int32_t sample_sum(const SampleRecord *r) {
  return r->tag + r->at.x + r->at.y + (int32_t)r->weight + r->id +
         r->name[0] + (int32_t)(r->ratio * 4) + (int32_t)r->color;
}

void sample_fill(SampleRecord *r) {
  r->tag = 200;
  r->at.x = -7;
  r->at.y = 11;
  r->weight = 2.5;
  r->id = 60000;
  memcpy(r->name, "hello", 6);
  r->label = "label";
  r->ratio = 0.75f;
  r->color = SAMPLE_BLUE;
}

SampleThing *sample_make(int32_t id) {
  SampleThing *t = malloc(sizeof *t);
  t->id = id;
  return t;
}

int32_t sample_id(const SampleThing *t) { return t ? t->id : -1; }
void sample_free(SampleThing *t) { free(t); }
uint32_t sample_word(const SampleBits *b) { return b->word; }
size_t sample_length(const char *s) { return strlen(s); }
int32_t sample_holder_last(const SampleHolder *h) { return h->last; }
void sample_count(int32_t *out) { *out = 42; }
int sample_printf(const char *fmt, ...) { (void)fmt; return 0; }
int sample_log(const char *fmt, ...) { (void)fmt; return 0; }

long sample_wide_sum(const SampleWide *w) {
  return w->a + (long)w->b + (long)w->c + (long)w->d;
}

const char *sample_name(int32_t id) {
  static const char *names[] = {"zero", "one", "two"};
  return (id >= 0 && id < 3) ? names[id] : NULL;
}

char *sample_dup(const char *s) {
  size_t n = strlen(s);
  char *p = malloc(n + 1);
  memcpy(p, s, n + 1);
  return p;
}

void sample_release(char *p) { free(p); }
SamplePoint sample_origin(void) { SamplePoint p = {0, 0}; return p; }
