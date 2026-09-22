/*
 * The catmint runtime: the object model, the built-in classes and the helpers
 * the generated code calls into.
 *
 * This file is the source of catmint-gen/runtime.ll. It was reconstructed from
 * that IR, which had been committed without its source, and is verified
 * against it by test_suite/runtime_parity: the two are behaviourally
 * interchangeable across the whole code generation suite.
 *
 * Everything here is fixed by agreement with IRGenerator.cpp and must not be
 * changed on one side only:
 *   - every object begins with a pointer to its run-time type information,
 *     followed by a reference count: zero means the object is static (a
 *     string literal, a class name) and must never be freed;
 *   - a virtual table is an array of function pointers at the end of the RTTI
 *     record, with the parent's slots first;
 *   - the built-in slot order is Object {abort, typeName, copy}, then IO
 *     {in, out} or String {length, toInt, substring, concat, equal};
 *   - a method is named M<length of class name>_<class>_<method> and takes the
 *     receiver as its first argument.
 *
 * Build:  clang -O0 -emit-llvm -S runtime.c -o runtime.host.ll
 */

#include <ctype.h>
#include <math.h>
#include <setjmp.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

struct TString;

struct __catmint_rtti {
  struct TString *name;         /* the class name, as a catmint String */
  int size;                     /* bytes to allocate for an instance    */
  struct __catmint_rtti *parent;/* null for Object                      */
  void *vtable[];               /* parent's slots first, then new ones  */
};

/* Every object starts this way. `refs` is 1 when __catmint_new made it and 0
 * when it is a static object the compiler emitted -- a string literal or a
 * class name. Zero is therefore "do not free", which is what makes free() on
 * a literal a no-op instead of heap corruption. */
struct TObject {
  struct __catmint_rtti *rtti;
  int refs;
};

struct TString {
  struct __catmint_rtti *rtti;
  int refs;
  int length;
  char *string;
};

struct TIO {
  struct __catmint_rtti *rtti;
  int refs;
};

/* A growable array of object references. This is the one container the
 * runtime provides; richer ones (a dictionary, say) are written in catmint on
 * top of it, because everything they need beyond raw memory is expressible in
 * the language. */
struct TList {
  struct __catmint_rtti *rtti;
  int refs;
  int length;
  int capacity;
  void **items;
};

/* A boxed integer, so that one can be stored in a List. The generated code
 * boxes and unboxes automatically where a conversion is needed. The field is
 * 64 bits wide so that every integer type -- Int8 through Int64 -- survives a
 * trip through a container without losing anything. */
struct TInteger {
  struct __catmint_rtti *rtti;
  int refs;
  long long value;
};

/* An open file. The handle is the only state; everything else about files is
 * expressible in catmint on top of these methods. */
struct TFile {
  struct __catmint_rtti *rtti;
  int refs;
  FILE *handle;
};

/* Math has no state at all: it exists so that the libm functions have
 * somewhere to live, since the language has no free functions. */
struct TMath {
  struct __catmint_rtti *rtti;
  int refs;
};

/* A flexible array member cannot be initialised, so each class's RTTI gets a
 * named struct with its vtable sized exactly, and is cast where it is used.
 * The layout up to the vtable is identical in all of them, which is what makes
 * the cast to struct __catmint_rtti * valid. */
#define CATMINT_RTTI_TYPE(name, slots)                                         \
  typedef struct {                                                             \
    struct TString *name_;                                                     \
    int size;                                                                  \
    struct __catmint_rtti *parent;                                             \
    void *vtable[slots];                                                       \
  } name

/* Object holds six slots, so every subclass's own methods start at six.
 * These sizes are the totals, Object's included. */
CATMINT_RTTI_TYPE(catmint_rtti6_object, 6);
CATMINT_RTTI_TYPE(catmint_rtti20_io, 20);
CATMINT_RTTI_TYPE(catmint_rtti11_list, 11);
CATMINT_RTTI_TYPE(catmint_rtti9_integer, 9);
CATMINT_RTTI_TYPE(catmint_rtti13_file, 13);
CATMINT_RTTI_TYPE(catmint_rtti19_string, 19);


#define RTTI(x) ((struct __catmint_rtti *)&(x))

void  M6_Object_abort(struct TObject *self);
struct TString *M6_Object_typeName(struct TObject *self);
struct TObject *M6_Object_copy(struct TObject *self);
struct TObject *M6_Object_retain(struct TObject *self);
void M6_Object_release(struct TObject *self);
int M6_Object_refs(struct TObject *self);

int M6_String_length(struct TString *self);
int M6_String_toInt(struct TString *self);
struct TString *M6_String_substring(struct TString *self, int start, int end);
struct TString *M6_String_concat(struct TString *self, struct TString *other);
int M6_String_equal(struct TString *self, struct TString *other);
int M6_String_at(struct TString *self, int index);
int M6_String_indexOf(struct TString *self, struct TString *needle);
struct TString *M6_String_trim(struct TString *self);
struct TString *M6_String_upper(struct TString *self);
struct TString *M6_String_lower(struct TString *self);
struct TList *M6_String_split(struct TString *self, struct TString *separator);
struct TString *M6_String_chr(int code);
struct TString *M6_String_replace(struct TString *self, struct TString *from,
                                  struct TString *to);
double M6_String_toFloat(struct TString *self);

struct TString *M2_IO_in(struct TIO *self);
struct TIO *M2_IO_out(struct TIO *self, struct TString *message);
struct TString *M2_IO_readLine(struct TIO *self);
int M2_IO_eof(struct TIO *self);
int M2_IO_entropy(struct TIO *self);
int M2_IO_ticks(struct TIO *self);
long long M2_IO_epoch(struct TIO *self);
int M2_IO_localOffset(struct TIO *self);
struct TIO *M2_IO_sleep(struct TIO *self, int milliseconds);
int M2_IO_args(struct TIO *self);
struct TString *M2_IO_arg(struct TIO *self, int index);
struct TIO *M2_IO_err(struct TIO *self, struct TString *message);
void M2_IO_exit(struct TIO *self, int code);
int M2_IO_allocated(struct TIO *self);

int M4_File_open(struct TFile *self, struct TString *path, struct TString *mode);
struct TString *M4_File_readLine(struct TFile *self);
struct TString *M4_File_readAll(struct TFile *self);
struct TFile *M4_File_write(struct TFile *self, struct TString *text);
int M4_File_eof(struct TFile *self);
struct TFile *M4_File_close(struct TFile *self);
int M4_File_isOpen(struct TFile *self);
int M4_File_exists(struct TString *path);
int M4_File_remove(struct TString *path);

double M4_Math_sqrt(double x);
double M4_Math_pow(double x, double y);
double M4_Math_exp(double x);
double M4_Math_log(double x);
double M4_Math_log10(double x);
double M4_Math_sin(double x);
double M4_Math_cos(double x);
double M4_Math_tan(double x);
double M4_Math_atan2(double y, double x);
double M4_Math_floor(double x);
double M4_Math_ceil(double x);
double M4_Math_round(double x);
double M4_Math_absf(double x);
int M4_Math_abs(int x);
int M4_Math_min(int a, int b);
int M4_Math_max(int a, int b);
double M4_Math_pi(void);
double M4_Math_e(void);

int M4_List_len(struct TList *self);
void *M4_List_get(struct TList *self, int index);
void *M4_List_set(struct TList *self, int index, void *value);
struct TList *M4_List_append(struct TList *self, void *value);
struct TList *M4_List_slice(struct TList *self, int start, int end);

int M7_Integer_get(struct TInteger *self);
struct TInteger *M7_Integer_set(struct TInteger *self, int value);
long long M7_Integer_getLong(struct TInteger *self);

void *__catmint_new(struct __catmint_rtti *rtti);
void String_init(struct TString *self);
void __cm_runtimeError(const char *message);
void __cm_throw(void *object);
void __cm_retain(void *object);
void __cm_release(void *object);
void __cm_poolAdd(void *object);
int __cm_poolDepth(void);
void __cm_poolUnwind(int depth);
void __cm_poolPop(void);

extern catmint_rtti19_string RString;

/* Class names. Each is itself a String, so its rtti is RString, and each has
 * a reference count of zero: they are static and must never be freed. */
struct TString NObject = { RTTI(RString), 0, 6, "Object" };
struct TString NString = { RTTI(RString), 0, 6, "String" };
struct TString NIO      = { RTTI(RString), 0, 2, "IO" };
struct TString NList    = { RTTI(RString), 0, 4, "List" };
struct TString NInteger = { RTTI(RString), 0, 7, "Integer" };
struct TString NFile    = { RTTI(RString), 0, 4, "File" };
struct TString NMath    = { RTTI(RString), 0, 4, "Math" };

#define CATMINT_OBJECT_SLOTS                                                   \
  (void *)M6_Object_abort, (void *)M6_Object_typeName,                         \
      (void *)M6_Object_copy, (void *)M6_Object_retain,                        \
      (void *)M6_Object_release, (void *)M6_Object_refs

catmint_rtti6_object RObject = {
  &NObject, sizeof(struct TObject), NULL,
  { CATMINT_OBJECT_SLOTS }
};

catmint_rtti19_string RString = {
  &NString, sizeof(struct TString), RTTI(RObject),
  { CATMINT_OBJECT_SLOTS,
    (void *)M6_String_length, (void *)M6_String_toInt,
    (void *)M6_String_substring, (void *)M6_String_concat,
    (void *)M6_String_equal, (void *)M6_String_at,
    (void *)M6_String_indexOf, (void *)M6_String_trim,
    (void *)M6_String_upper, (void *)M6_String_lower,
    (void *)M6_String_split,
    (void *)M6_String_replace, (void *)M6_String_toFloat }
};

/* The two new slots go on the end. Inserting anywhere else would renumber
 * `in` and `out` and silently break every already-compiled caller. */
catmint_rtti20_io RIO = {
  &NIO, sizeof(struct TIO), RTTI(RObject),
  { CATMINT_OBJECT_SLOTS,
    (void *)M2_IO_in, (void *)M2_IO_out,
    (void *)M2_IO_readLine, (void *)M2_IO_eof, (void *)M2_IO_entropy,
    (void *)M2_IO_ticks, (void *)M2_IO_epoch, (void *)M2_IO_localOffset,
    (void *)M2_IO_sleep,
    (void *)M2_IO_args, (void *)M2_IO_arg, (void *)M2_IO_err,
    (void *)M2_IO_exit, (void *)M2_IO_allocated }
};

catmint_rtti13_file RFile = {
  &NFile, sizeof(struct TFile), RTTI(RObject),
  { CATMINT_OBJECT_SLOTS,
    (void *)M4_File_open, (void *)M4_File_readLine, (void *)M4_File_readAll,
    (void *)M4_File_write, (void *)M4_File_eof, (void *)M4_File_close,
    (void *)M4_File_isOpen }
};

/* Every Math method is static, so the class contributes no slots of its own
 * and its table is Object's. The class exists only to name the functions. */
catmint_rtti6_object RMath = {
  &NMath, sizeof(struct TMath), RTTI(RObject),
  { CATMINT_OBJECT_SLOTS }
};

catmint_rtti11_list RList = {
  &NList, sizeof(struct TList), RTTI(RObject),
  { CATMINT_OBJECT_SLOTS,
    (void *)M4_List_len, (void *)M4_List_get, (void *)M4_List_set,
    (void *)M4_List_append, (void *)M4_List_slice }
};

catmint_rtti9_integer RInteger = {
  &NInteger, sizeof(struct TInteger), RTTI(RObject),
  { CATMINT_OBJECT_SLOTS,
    (void *)M7_Integer_get, (void *)M7_Integer_set,
    (void *)M7_Integer_getLong }
};

/* -------------------------------------------------------------------------
 * Allocation and initialisers
 * ------------------------------------------------------------------------- */

/* How many objects __catmint_new has handed out and not taken back. A
 * program can read it through IO.allocated(), which is what makes "did that
 * loop leak?" a question with an answer. */
static int gLiveObjects = 0;

/* Allocate an instance of the class described by rtti, zero it, install the
 * rtti pointer and start the reference count at one. Generated code calls
 * this for `new` and for every declaration of a variable of class type.
 *
 * The new object also joins the current pool, so that if nothing goes on to
 * keep it -- the String that `a + b` makes and nobody names -- it is released
 * when the pool closes. Anything that does keep it retains it, and the
 * pool's release then only undoes the one this allocation put there. */
void *__catmint_new(struct __catmint_rtti *rtti) {
  void *object = malloc(rtti->size);
  memset(object, 0, rtti->size);
  ((struct TObject *)object)->rtti = rtti;
  ((struct TObject *)object)->refs = 1;
  gLiveObjects += 1;
  __cm_poolAdd(object);
  return object;
}

void Object_init(struct TObject *self) {
  (void)self;
}

void IO_init(struct TIO *self) {
  (void)self;
}

/* One shared, static empty buffer, rather than a literal: free() has to be
 * able to tell "this String owns its characters" from "this String is
 * pointing at something malloc never returned". */
static char gEmptyChars[1] = "";

void String_init(struct TString *self) {
  self->string = gEmptyChars;
  self->length = 0;
}

void List_init(struct TList *self) {
  self->length = 0;
  self->capacity = 0;
  self->items = NULL;
}

void Integer_init(struct TInteger *self) {
  self->value = 0;
}

void File_init(struct TFile *self) {
  self->handle = NULL;
}

void Math_init(struct TMath *self) {
  (void)self;
}

/* Build a catmint String from a NUL-terminated buffer. */
static struct TString *make_string(const char *text) {
  struct TString *result = (struct TString *)__catmint_new(RTTI(RString));
  String_init(result);
  result->length = (int)strlen(text);
  result->string = calloc((size_t)result->length + 1, 1);
  strcpy(result->string, text);
  return result;
}

/* -------------------------------------------------------------------------
 * Object
 * ------------------------------------------------------------------------- */

void M6_Object_abort(struct TObject *self) {
  (void)self;
  exit(1);
}

struct TString *M6_Object_typeName(struct TObject *self) {
  return self->rtti->name;
}

/* A shallow copy: the size in the RTTI covers the whole instance. The copy
 * is a fresh allocation with its own count of one, whatever the original's
 * count was -- copying a literal gives something you can free. */
struct TObject *M6_Object_copy(struct TObject *self) {
  struct TObject *copy = (struct TObject *)__catmint_new(self->rtti);

  memcpy(copy, self, (size_t)self->rtti->size);
  copy->refs = 1;

  /* Shallow would leave the two sharing one malloc'd buffer, and freeing
   * both would be a double free. The buffer a built-in owns is therefore
   * duplicated; the objects a List holds are not, since those are
   * references and sharing them is what a shallow copy means. */
  if (copy->rtti == RTTI(RString)) {
    struct TString *text = (struct TString *)copy;
    if (text->string == gEmptyChars) {
      /* nothing owned */
    } else {
      char *chars = calloc((size_t)text->length + 1, 1);
      memcpy(chars, ((struct TString *)self)->string, (size_t)text->length);
      text->string = chars;
    }
  } else if (copy->rtti == RTTI(RList)) {
    struct TList *list = (struct TList *)copy;
    if (list->capacity > 0 && list->items) {
      void **items = malloc((size_t)list->capacity * sizeof(void *));
      int i;
      memcpy(items, ((struct TList *)self)->items,
             (size_t)list->length * sizeof(void *));
      list->items = items;
      /* Two lists now point at the same items, so each item gains a holder. */
      for (i = 0; i < list->length; ++i) {
        __cm_retain(items[i]);
      }
    }
  } else if (copy->rtti == RTTI(RFile)) {
    /* Two objects must not hold one FILE *: the copy starts closed. */
    ((struct TFile *)copy)->handle = NULL;
  }
  return copy;
}

/* -------------------------------------------------------------------------
 * Memory
 *
 * Reference counting the programmer drives: the compiler inserts no retain
 * and no release. What the runtime guarantees is that the counting is
 * correct when you do call them, that a static object is never freed, and
 * that a built-in's own buffers go back with it.
 * ------------------------------------------------------------------------- */

/* The buffers a built-in owns beyond its own struct. A user class owns
 * nothing extra: its object fields are references, and freeing one object
 * does not reach through them. */
static void release_owned_buffers(struct TObject *self) {
  if (self->rtti == RTTI(RString)) {
    struct TString *text = (struct TString *)self;
    /* A String built by the runtime owns its characters. A freshly
     * initialised one points at the shared empty buffer and owns nothing. */
    if (text->string && text->string != gEmptyChars) {
      free(text->string);
    }
    text->string = gEmptyChars;
    text->length = 0;
  } else if (self->rtti == RTTI(RList)) {
    struct TList *list = (struct TList *)self;
    int i;
    /* A list holds a reference to each of its items, so it gives them back
     * when it goes. This is the one container the runtime provides, and the
     * only place ownership is nested. */
    for (i = 0; i < list->length; ++i) {
      __cm_release(list->items[i]);
    }
    free(list->items);
    list->items = NULL;
    list->length = 0;
    list->capacity = 0;
  } else if (self->rtti == RTTI(RFile)) {
    struct TFile *file = (struct TFile *)self;
    if (file->handle) {
      fclose(file->handle);
      file->handle = NULL;
    }
  }
}

/* Give the object back. Only release calls this, and only when the last
 * holder has let go: an unconditional "free it now" cannot be offered once
 * the compiler is counting references, because it would leave the counted
 * references pointing at freed memory. A count of zero means a static object
 * -- a string literal, a class name -- which is never freed. */
static void object_free(struct TObject *self) {
  if (self == NULL || self->refs == 0) {
    return;
  }
  release_owned_buffers(self);
  self->refs = 0;
  gLiveObjects -= 1;
  free(self);
}

struct TObject *M6_Object_retain(struct TObject *self) {
  __cm_retain(self);
  return self;
}

/* The same two operations as plain functions, because the generated code
 * calls them directly rather than through a virtual table: they are the same
 * for every class, and a dispatch per assignment would be absurd. */
void __cm_retain(void *object) {
  struct TObject *self = (struct TObject *)object;
  if (self != NULL && self->refs > 0) {
    self->refs += 1;
  }
}

void __cm_release(void *object) {
  M6_Object_release((struct TObject *)object);
}

/* One fewer holder; the last one out frees it. */
void M6_Object_release(struct TObject *self) {
  if (self == NULL || self->refs == 0) {
    return;
  }
  self->refs -= 1;
  if (self->refs == 0) {
    self->refs = 1; /* so the free does not mistake it for a static object */
    object_free(self);
  }
}

int M6_Object_refs(struct TObject *self) {
  return self == NULL ? 0 : self->refs;
}

/* -------------------------------------------------------------------------
 * String
 * ------------------------------------------------------------------------- */

int M6_String_length(struct TString *self) {
  return self->length;
}

/* Zero when the text is not entirely a number, which is why strtol's end
 * pointer is checked rather than just its result. */
int M6_String_toInt(struct TString *self) {
  char *end;
  int value = (int)strtol(self->string, &end, 10);
  if (*end != '\0') {
    return 0;
  }
  return value;
}

/* A half-open range: [start, end). One character at i is substring(i, i + 1). */
struct TString *M6_String_substring(struct TString *self, int start, int end) {
  struct TString *result;

  if (start < 0 || start > end || end > self->length) {
    __cm_runtimeError("Substring indices out of bounds.");
  }

  result = (struct TString *)__catmint_new(RTTI(RString));
  String_init(result);
  result->length = end - start;
  result->string = calloc(end - start + 1, 1);
  memcpy(result->string, self->string + start, end - start);
  return result;
}

struct TString *M6_String_concat(struct TString *self, struct TString *other) {
  int length = self->length + other->length;
  struct TString *result = (struct TString *)__catmint_new(RTTI(RString));

  String_init(result);
  result->length = length;
  result->string = calloc(length + 1, 1);
  strncpy(result->string, self->string, self->length);
  strncat(result->string, other->string, other->length);
  return result;
}

/* 1 when equal, 0 otherwise. Two nulls are equal; one null never is. */
int M6_String_equal(struct TString *self, struct TString *other) {
  if (self == NULL) {
    return other == NULL;
  }
  if (other == NULL) {
    return 0;
  }
  if (self->length != other->length) {
    return 0;
  }
  return strncmp(self->string, other->string, self->length) == 0;
}

/* The character code at an index. Catmint has no character type, so this
 * gives the byte as an Int, which is what a hash function needs. */
int M6_String_at(struct TString *self, int index) {
  if (index < 0 || index >= self->length) {
    __cm_runtimeError("String index out of bounds.");
  }
  return (int)(unsigned char)self->string[index];
}

/* -------------------------------------------------------------------------
 * IO
 * ------------------------------------------------------------------------- */

/* Reads one whitespace-delimited word, at most 255 characters. */
struct TString *M2_IO_in(struct TIO *self) {
  char buffer[256];

  (void)self;
  buffer[0] = '\0';
  if (scanf("%255s", buffer) != 1) {
    buffer[0] = '\0';
  }

  return make_string(buffer);
}

/* The rest of the current line, without its newline. At end of input this
 * gives an empty String, so pair it with eof() to drive a loop. */
struct TString *M2_IO_readLine(struct TIO *self) {
  char buffer[1024];
  size_t length;

  (void)self;
  if (!fgets(buffer, (int)sizeof(buffer), stdin)) {
    return make_string("");
  }

  length = strlen(buffer);
  if (length > 0 && buffer[length - 1] == '\n') {
    buffer[length - 1] = '\0';
  }
  return make_string(buffer);
}

/* 1 once input is exhausted. It peeks rather than relying on a previous read
 * having failed, which is what makes `while !io.eof():` stop at the right
 * place instead of one iteration late. */
int M2_IO_eof(struct TIO *self) {
  int c;

  (void)self;
  c = fgetc(stdin);
  if (c == EOF) {
    return 1;
  }
  ungetc(c, stdin);
  return 0;
}

/* A seed for a random number generator. This is the whole of the runtime's
 * involvement in randomness: the generator itself is written in catmint, in
 * lib/random.cmm, where it can be read and tested. Only the unpredictable
 * part has to come from outside the language.
 *
 * /dev/urandom when it is there, which it is on every system this compiler
 * targets. The fallback mixes the wall clock with the CPU clock so that two
 * runs started in the same second still differ. */
int M2_IO_entropy(struct TIO *self) {
  unsigned int value = 0;
  FILE *source;

  (void)self;

  source = fopen("/dev/urandom", "rb");
  if (source) {
    size_t got = fread(&value, sizeof(value), 1, source);
    fclose(source);
    if (got == 1) {
      return (int)(value & 0x7fffffffu);
    }
  }

  value = (unsigned int)time(NULL) * 2654435761u;
  value ^= (unsigned int)clock() * 40503u;
  return (int)(value & 0x7fffffffu);
}

/* -------------------------------------------------------------------------
 * Time
 *
 * Three primitives, deliberately few. Breaking a timestamp into a date is
 * plain integer arithmetic, so it lives in lib/time.cmm rather than here.
 * ------------------------------------------------------------------------- */

/* Milliseconds since the first call, which is close enough to program start.
 * Monotonic, so it is the one to use for measuring how long something took;
 * epoch() can jump when the clock is set. */
int M2_IO_ticks(struct TIO *self) {
  static int started = 0;
  static struct timespec origin;
  struct timespec now;
  long seconds;
  long millis;

  (void)self;

  if (clock_gettime(CLOCK_MONOTONIC, &now) != 0) {
    return 0;
  }
  if (!started) {
    origin = now;
    started = 1;
  }

  seconds = (long)(now.tv_sec - origin.tv_sec);
  millis = (now.tv_nsec - origin.tv_nsec) / 1000000L;
  return (int)(seconds * 1000L + millis);
}

/* Seconds since 1970-01-01 UTC, as an Int64, so it does not stop working in
 * 2038. */
long long M2_IO_epoch(struct TIO *self) {
  (void)self;
  return (long long)time(NULL);
}

/* Seconds to add to UTC to get local time, daylight saving included. Keeping
 * this separate is what lets the date arithmetic stay in catmint. */
int M2_IO_localOffset(struct TIO *self) {
  time_t now;
  struct tm local;
  struct tm utc;
  int localSeconds;
  int utcSeconds;
  int dayDifference;

  (void)self;

  now = time(NULL);
  if (!localtime_r(&now, &local) || !gmtime_r(&now, &utc)) {
    return 0;
  }

  localSeconds = local.tm_hour * 3600 + local.tm_min * 60 + local.tm_sec;
  utcSeconds = utc.tm_hour * 3600 + utc.tm_min * 60 + utc.tm_sec;

  /* The two may fall on different days, in which case the difference is out
   * by a day in one direction or the other. */
  dayDifference = local.tm_yday - utc.tm_yday;
  if (dayDifference > 1) {
    dayDifference = -1; /* local is in the next year */
  } else if (dayDifference < -1) {
    dayDifference = 1; /* utc is in the next year */
  }

  return localSeconds - utcSeconds + dayDifference * 86400;
}

struct TIO *M2_IO_sleep(struct TIO *self, int milliseconds) {
  struct timespec request;

  if (milliseconds <= 0) {
    return self;
  }
  request.tv_sec = milliseconds / 1000;
  request.tv_nsec = (long)(milliseconds % 1000) * 1000000L;
  nanosleep(&request, NULL);
  return self;
}

struct TIO *M2_IO_out(struct TIO *self, struct TString *message) {
  printf("%s", message->string);
  return self;
}

/* -------------------------------------------------------------------------
 * List
 * ------------------------------------------------------------------------- */

static void list_bounds(struct TList *self, int index) {
  if (index < 0 || index >= self->length) {
    __cm_runtimeError("List index out of bounds.");
  }
}

int M4_List_len(struct TList *self) {
  return self->length;
}

void *M4_List_get(struct TList *self, int index) {
  list_bounds(self, index);
  return self->items[index];
}

void *M4_List_set(struct TList *self, int index, void *value) {
  void *previous;

  list_bounds(self, index);
  previous = self->items[index];
  /* Retain before releasing: setting a slot to what it already holds must
   * not free it in between. */
  __cm_retain(value);
  self->items[index] = value;
  __cm_release(previous);
  return value;
}

/* Doubling growth, so appending n items costs O(n) in total. */
struct TList *M4_List_append(struct TList *self, void *value) {
  if (self->length == self->capacity) {
    int capacity = self->capacity == 0 ? 4 : self->capacity * 2;
    void **items = realloc(self->items, (size_t)capacity * sizeof(void *));
    if (!items) {
      __cm_runtimeError("Out of memory growing a List.");
    }
    self->items = items;
    self->capacity = capacity;
  }
  /* The list keeps what it is given, so it holds a reference of its own. */
  __cm_retain(value);
  self->items[self->length] = value;
  self->length += 1;
  return self;
}

/* A half-open range [start, end), matching String.substring. */
struct TList *M4_List_slice(struct TList *self, int start, int end) {
  struct TList *result;
  int i;

  if (start < 0 || start > end || end > self->length) {
    __cm_runtimeError("List slice indices out of bounds.");
  }

  result = (struct TList *)__catmint_new(RTTI(RList));
  List_init(result);
  for (i = start; i < end; ++i) {
    M4_List_append(result, self->items[i]);
  }
  return result;
}

/* -------------------------------------------------------------------------
 * Integer, the box that lets an Int live in a List
 * ------------------------------------------------------------------------- */

/* Truncating, because catmint's Int is 32 bits. getLong gives the whole
 * thing back. */
int M7_Integer_get(struct TInteger *self) {
  return (int)self->value;
}

struct TInteger *M7_Integer_set(struct TInteger *self, int value) {
  self->value = value;
  return self;
}

long long M7_Integer_getLong(struct TInteger *self) {
  return self->value;
}

/* -------------------------------------------------------------------------
 * Helpers the generated code calls directly
 * ------------------------------------------------------------------------- */

/* Called before every dispatch. */
void __cm_checkNull(void *object) {
  if (object == NULL) {
    __cm_runtimeError("Calling a method of a void object.");
  }
}

/* 'expr is Type': 1 when the object's class is the target or inherits from
 * it, 0 otherwise, including for null. Unlike a cast this never aborts, which
 * is the point of having it. */
int __cm_isType(void *object, struct __catmint_rtti *target) {
  struct __catmint_rtti *current;

  if (object == NULL) {
    return 0;
  }
  for (current = ((struct TObject *)object)->rtti; current;
       current = current->parent) {
    if (current == target) {
      return 1;
    }
  }
  return 0;
}

/* A checked downcast: walk the object's ancestry looking for the target. */
void *__cm_cast(void *object, struct __catmint_rtti *target) {
  struct __catmint_rtti *actual;
  struct __catmint_rtti *current;

  if (object == NULL) {
    return NULL;
  }

  actual = ((struct TObject *)object)->rtti;
  for (current = actual; current != NULL; current = current->parent) {
    if (current == target) {
      return object;
    }
  }

  {
    char message[256];
    snprintf(message, sizeof(message), "Unable to convert %s into %s.",
             actual->name->string, target->name->string);
    __cm_runtimeError(message);
  }
  return NULL;
}

/* Boxing and unboxing, inserted by the generator where an integer meets a
 * place that holds object references, and on the way back out. The box is 64
 * bits wide, so the generator widens before boxing and narrows after
 * unboxing; no integer type loses anything in a container. */
void *__cm_boxLong(long long value) {
  struct TInteger *box = (struct TInteger *)__catmint_new(RTTI(RInteger));
  Integer_init(box);
  box->value = value;
  return box;
}

long long __cm_unboxLong(void *object) {
  __cm_checkNull(object);
  if (((struct TObject *)object)->rtti != RTTI(RInteger)) {
    char message[256];
    snprintf(message, sizeof(message), "Expected an Integer, found %s.",
             ((struct TObject *)object)->rtti->name->string);
    __cm_runtimeError(message);
  }
  return ((struct TInteger *)object)->value;
}

/* Equality for two object references, used when the static types are not
 * specific enough to know better. Strings compare by content and boxed Ints
 * by value, because comparing either by identity would surprise everyone;
 * anything else compares by identity. */
int __cm_equals(void *a, void *b) {
  struct __catmint_rtti *ra;
  struct __catmint_rtti *rb;

  if (a == b) {
    return 1;
  }
  if (a == NULL || b == NULL) {
    return 0;
  }

  ra = ((struct TObject *)a)->rtti;
  rb = ((struct TObject *)b)->rtti;
  if (ra != rb) {
    return 0;
  }
  if (ra == RTTI(RString)) {
    return M6_String_equal((struct TString *)a, (struct TString *)b);
  }
  if (ra == RTTI(RInteger)) {
    return ((struct TInteger *)a)->value == ((struct TInteger *)b)->value;
  }
  return 0;
}

/* The float counterpart of __cm_intToString. %g keeps short values short
 * instead of printing a tail of zeroes. */
struct TString *__cm_floatToString(double value) {
  char buffer[64];

  memset(buffer, 0, sizeof(buffer));
  snprintf(buffer, sizeof(buffer), "%g", value);
  return make_string(buffer);
}

/* What makes out(someInt) work: the generated code inserts this call. */
struct TString *__cm_intToString(int value) {
  char buffer[32];

  memset(buffer, 0, sizeof(buffer));
  snprintf(buffer, sizeof(buffer), "%d", value);

  return make_string(buffer);
}

/* The same for Int64. The narrower widths are sign-extended to Int first, so
 * only these two conversions exist. */
struct TString *__cm_longToString(long long value) {
  char buffer[32];

  memset(buffer, 0, sizeof(buffer));
  snprintf(buffer, sizeof(buffer), "%lld", value);

  return make_string(buffer);
}

/* -------------------------------------------------------------------------
 * String, part two
 *
 * Everything here could in principle be written in catmint on top of at() and
 * substring(), but these are the operations every text-handling program needs
 * on its first page, and chr() cannot be written in the language at all.
 * ------------------------------------------------------------------------- */

/* The index of the first occurrence, or -1. An empty needle is found at 0,
 * which is what every other language's indexOf does. */
int M6_String_indexOf(struct TString *self, struct TString *needle) {
  int i;
  int limit;

  if (needle == NULL || needle->length == 0) {
    return 0;
  }
  limit = self->length - needle->length;
  for (i = 0; i <= limit; ++i) {
    if (memcmp(self->string + i, needle->string, (size_t)needle->length) == 0) {
      return i;
    }
  }
  return -1;
}

struct TString *M6_String_trim(struct TString *self) {
  int start = 0;
  int end = self->length;

  while (start < end && isspace((unsigned char)self->string[start])) {
    ++start;
  }
  while (end > start && isspace((unsigned char)self->string[end - 1])) {
    --end;
  }
  return M6_String_substring(self, start, end);
}

static struct TString *string_mapped(struct TString *self, int upper) {
  struct TString *result = M6_String_substring(self, 0, self->length);
  int i;

  for (i = 0; i < result->length; ++i) {
    unsigned char c = (unsigned char)result->string[i];
    result->string[i] = (char)(upper ? toupper(c) : tolower(c));
  }
  return result;
}

struct TString *M6_String_upper(struct TString *self) {
  return string_mapped(self, 1);
}

struct TString *M6_String_lower(struct TString *self) {
  return string_mapped(self, 0);
}

/* Split on a literal separator. A separator that never occurs gives a list of
 * one, the whole string; an empty separator does the same, because splitting
 * on nothing has no useful answer. */
struct TList *M6_String_split(struct TString *self, struct TString *separator) {
  struct TList *result = (struct TList *)__catmint_new(RTTI(RList));
  int start = 0;
  int i;

  List_init(result);

  if (separator == NULL || separator->length == 0) {
    M4_List_append(result, M6_String_substring(self, 0, self->length));
    return result;
  }

  for (i = 0; i + separator->length <= self->length;) {
    if (memcmp(self->string + i, separator->string,
               (size_t)separator->length) == 0) {
      M4_List_append(result, M6_String_substring(self, start, i));
      i += separator->length;
      start = i;
    } else {
      ++i;
    }
  }
  M4_List_append(result, M6_String_substring(self, start, self->length));
  return result;
}

/* A character code as a one-character String: the inverse of at(), and the
 * one string operation that cannot be written in catmint, because there is no
 * way to build a character out of a number. It is static: String.chr(65). */
struct TString *M6_String_chr(int code) {
  char buffer[2];

  buffer[0] = (char)(code & 0xff);
  buffer[1] = '\0';
  return make_string(buffer);
}

/* Every occurrence, left to right. Replacing an empty string would never
 * terminate, so that gives the original back. */
struct TString *M6_String_replace(struct TString *self, struct TString *from,
                                  struct TString *to) {
  struct TString *result;
  char *out;
  int written = 0;
  int i = 0;
  int occurrences = 0;
  int growth;

  if (from == NULL || from->length == 0 || to == NULL) {
    return M6_String_substring(self, 0, self->length);
  }

  for (i = 0; i + from->length <= self->length;) {
    if (memcmp(self->string + i, from->string, (size_t)from->length) == 0) {
      ++occurrences;
      i += from->length;
    } else {
      ++i;
    }
  }

  growth = occurrences * (to->length - from->length);
  result = (struct TString *)__catmint_new(RTTI(RString));
  String_init(result);
  result->length = self->length + growth;
  out = calloc((size_t)result->length + 1, 1);
  result->string = out;

  for (i = 0; i < self->length;) {
    if (i + from->length <= self->length &&
        memcmp(self->string + i, from->string, (size_t)from->length) == 0) {
      memcpy(out + written, to->string, (size_t)to->length);
      written += to->length;
      i += from->length;
    } else {
      out[written++] = self->string[i++];
    }
  }
  return result;
}

/* Zero when the text is not entirely a number, matching toInt. */
double M6_String_toFloat(struct TString *self) {
  char *end;
  double value = strtod(self->string, &end);

  if (*end != '\0') {
    return 0.0;
  }
  return value;
}

/* -------------------------------------------------------------------------
 * IO, part two: the command line, standard error and the exit status
 * ------------------------------------------------------------------------- */

/* Stashed by the generated main() before anything else runs. */
static int gArgCount = 0;
static char **gArgValues = NULL;

void __cm_setArgs(int argc, char **argv) {
  gArgCount = argc;
  gArgValues = argv;
}

/* The count includes the program itself at index 0, as C's argc does. */
int M2_IO_args(struct TIO *self) {
  (void)self;
  return gArgCount;
}

/* An index outside the range gives an empty String rather than aborting, so a
 * missing argument is handled with a test rather than a guard. */
struct TString *M2_IO_arg(struct TIO *self, int index) {
  (void)self;
  if (index < 0 || index >= gArgCount || gArgValues == NULL) {
    return make_string("");
  }
  return make_string(gArgValues[index]);
}

struct TIO *M2_IO_err(struct TIO *self, struct TString *message) {
  fputs(message->string, stderr);
  return self;
}

void M2_IO_exit(struct TIO *self, int code) {
  (void)self;
  exit(code);
}

/* Objects allocated and not yet given back. Compare two readings around a
 * piece of work to see whether it leaks. */
int M2_IO_allocated(struct TIO *self) {
  (void)self;
  return gLiveObjects;
}

/* -------------------------------------------------------------------------
 * File
 *
 * The handle is the whole of the state. open() reports failure by returning 0
 * instead of aborting, because a missing file is an ordinary thing for a
 * program to have an opinion about.
 * ------------------------------------------------------------------------- */

int M4_File_open(struct TFile *self, struct TString *path,
                 struct TString *mode) {
  if (self->handle) {
    fclose(self->handle);
    self->handle = NULL;
  }
  self->handle = fopen(path->string, mode->string);
  return self->handle != NULL;
}

struct TString *M4_File_readLine(struct TFile *self) {
  char buffer[4096];
  size_t length;

  if (!self->handle || !fgets(buffer, (int)sizeof(buffer), self->handle)) {
    return make_string("");
  }

  length = strlen(buffer);
  if (length > 0 && buffer[length - 1] == '\n') {
    buffer[length - 1] = '\0';
  }
  return make_string(buffer);
}

/* The rest of the file, from wherever it is now. */
struct TString *M4_File_readAll(struct TFile *self) {
  struct TString *result;
  char *text = NULL;
  size_t size = 0;
  size_t capacity = 0;

  if (!self->handle) {
    return make_string("");
  }

  for (;;) {
    size_t got;
    if (size + 4096 + 1 > capacity) {
      capacity = capacity == 0 ? 8192 : capacity * 2;
      text = realloc(text, capacity);
      if (!text) {
        __cm_runtimeError("Out of memory reading a file.");
      }
    }
    got = fread(text + size, 1, 4096, self->handle);
    size += got;
    if (got < 4096) {
      break;
    }
  }

  if (!text) {
    return make_string("");
  }
  text[size] = '\0';

  result = (struct TString *)__catmint_new(RTTI(RString));
  String_init(result);
  result->length = (int)size;
  result->string = text;
  return result;
}

struct TFile *M4_File_write(struct TFile *self, struct TString *text) {
  if (self->handle) {
    fwrite(text->string, 1, (size_t)text->length, self->handle);
  }
  return self;
}

/* 1 once the file is exhausted, peeking rather than waiting for a read to
 * fail, so a read loop stops in the right place. A file that is not open is
 * at its end. */
int M4_File_eof(struct TFile *self) {
  int c;

  if (!self->handle) {
    return 1;
  }
  c = fgetc(self->handle);
  if (c == EOF) {
    return 1;
  }
  ungetc(c, self->handle);
  return 0;
}

struct TFile *M4_File_close(struct TFile *self) {
  if (self->handle) {
    fclose(self->handle);
    self->handle = NULL;
  }
  return self;
}

int M4_File_isOpen(struct TFile *self) {
  return self->handle != NULL;
}

/* These two are about a path, not about a particular file, so they are
 * static: File.exists(path), not someFile.exists(path). */
int M4_File_exists(struct TString *path) {
  FILE *probe;

  probe = fopen(path->string, "rb");
  if (!probe) {
    return 0;
  }
  fclose(probe);
  return 1;
}

int M4_File_remove(struct TString *path) {
  return remove(path->string) == 0;
}

/* -------------------------------------------------------------------------
 * Math
 *
 * A thin shell over libm. It is a class with no state because the language
 * has no free functions; `Math m` costs one allocation and then nothing.
 * ------------------------------------------------------------------------- */

double M4_Math_sqrt(double x)  { return sqrt(x); }
double M4_Math_pow(double x, double y) { return pow(x, y); }
double M4_Math_exp(double x)   { return exp(x); }
double M4_Math_log(double x)   { return log(x); }
double M4_Math_log10(double x) { return log10(x); }
double M4_Math_sin(double x)   { return sin(x); }
double M4_Math_cos(double x)   { return cos(x); }
double M4_Math_tan(double x)   { return tan(x); }
double M4_Math_atan2(double y, double x) { return atan2(y, x); }
double M4_Math_floor(double x) { return floor(x); }
double M4_Math_ceil(double x)  { return ceil(x); }
double M4_Math_round(double x) { return round(x); }
double M4_Math_absf(double x)  { return fabs(x); }

int M4_Math_abs(int x) { return x < 0 ? -x : x; }
int M4_Math_min(int a, int b) { return a < b ? a : b; }
int M4_Math_max(int a, int b) { return a > b ? a : b; }

double M4_Math_pi(void) { return 3.14159265358979323846; }
double M4_Math_e(void)  { return 2.71828182845904523536; }

/* -------------------------------------------------------------------------
 * Errors
 *
 * try/catch/throw, on setjmp and longjmp. This is the scheme Lua uses, and
 * it fits here for the same reason: there is nothing to unwind. Catmint has
 * no destructors, so jumping over a frame skips no work that had to happen,
 * and the cost on the path where nothing is thrown is one setjmp per try
 * rather than the frame descriptors a table-driven scheme needs.
 *
 * The generated code allocates the jump buffer itself, because setjmp has to
 * be called from the frame that will be returned to; the runtime only keeps
 * the stack of them.
 * ------------------------------------------------------------------------- */

/* The generated code allocates this many bytes for a jump buffer. It cannot
 * ask sizeof(jmp_buf) at compile time, so the size is fixed here and checked
 * once, loudly, rather than being silently too small on some platform. */
#define CATMINT_JMPBUF_BYTES 512

struct __cm_handler {
  jmp_buf *buffer;
  int poolDepth;
  struct __cm_handler *previous;
};

static struct __cm_handler *gHandlers = NULL;
/* What the innermost throw was carrying, read by the catch block. */
static void *gThrown = NULL;

void __cm_pushHandler(void *buffer) {
  struct __cm_handler *handler;

  if (sizeof(jmp_buf) > CATMINT_JMPBUF_BYTES) {
    printf("Runtime error : this platform needs a larger CATMINT_JMPBUF_BYTES.\n");
    exit(1);
  }

  handler = (struct __cm_handler *)malloc(sizeof(struct __cm_handler));
  if (!handler) {
    printf("Runtime error : out of memory entering a try.\n");
    exit(1);
  }
  handler->buffer = (jmp_buf *)buffer;
  handler->poolDepth = __cm_poolDepth();
  handler->previous = gHandlers;
  gHandlers = handler;
}

/* Leaving a try normally, and also on the way out of a return that jumped
 * over the end of one. */
void __cm_popHandler(void) {
  struct __cm_handler *handler = gHandlers;

  if (!handler) {
    return;
  }
  gHandlers = handler->previous;
  free(handler);
}

void *__cm_caught(void) {
  return gThrown;
}

/* Hand the object to the innermost handler and jump to it. The handler is
 * popped first, so a throw from inside a catch block reaches the next one
 * out rather than looping back into itself. */
void __cm_throw(void *object) {
  struct __cm_handler *handler = gHandlers;
  jmp_buf *buffer;

  gThrown = object;

  if (!handler) {
    /* Nothing is watching, so this is the end of the program. A String says
     * what happened; anything else can at least say what it was. */
    if (object && ((struct TObject *)object)->rtti == RTTI(RString)) {
      printf("Uncaught: %s\n", ((struct TString *)object)->string);
    } else if (object) {
      printf("Uncaught: an object of type %s\n",
             ((struct TObject *)object)->rtti->name->string);
    } else {
      printf("Uncaught: null\n");
    }
    exit(1);
  }

  buffer = handler->buffer;
  gHandlers = handler->previous;
  /* The jump skips every poolPop between here and the handler, so close
   * those pools now; their contents are temporaries of the abandoned work. */
  __cm_poolUnwind(handler->poolDepth);
  free(handler);
  longjmp(*buffer, 1);
}

/* What the runtime's own checks call. With a handler installed the message
 * becomes an ordinary thrown String, so a program can catch a null dispatch
 * or an index out of bounds; with none it prints and stops, as before. */
void __cm_runtimeError(const char *message) {
  if (gHandlers) {
    __cm_throw(make_string(message));
  }
  printf("Runtime error : %s\n", message);
  exit(1);
}

/* -------------------------------------------------------------------------
 * Temporaries
 *
 * An expression makes objects nothing names: the String that `a + b`
 * produces, the Integer that boxing an Int produces. Nothing can free those
 * by hand, because nothing can refer to them. So every allocation joins the
 * open pool, and closing the pool releases everything in it once.
 *
 * What keeps an object alive is a reference of its own: the generated code
 * retains whatever it stores into a variable, a field or a container, and
 * releases it again when that variable goes out of scope. An object that was
 * stored therefore has two -- the allocation's and the store's -- and
 * closing the pool takes back only the first.
 *
 * This is the pool and retain/release pair that Objective-C used before ARC,
 * for the same reason: it needs no reachability analysis and nothing in the
 * language has to change.
 * ------------------------------------------------------------------------- */

/* One array of entries for the whole program, and a stack of marks into it.
 * Opening a pool is pushing a mark, closing it is releasing everything above
 * that mark -- so a pool that catches nothing costs a compare and a store,
 * and no allocation at all. That matters: a loop body opens one per
 * iteration. */
static void **gPoolItems = NULL;
static int gPoolCount = 0;
static int gPoolCapacity = 0;

static int *gPoolMarks = NULL;
static int gPoolDepth = 0;
static int gPoolMarkCapacity = 0;

void __cm_poolPush(void) {
  if (gPoolDepth == gPoolMarkCapacity) {
    int capacity = gPoolMarkCapacity == 0 ? 32 : gPoolMarkCapacity * 2;
    int *marks = realloc(gPoolMarks, (size_t)capacity * sizeof(int));
    if (!marks) {
      printf("Runtime error : out of memory opening a pool.\n");
      exit(1);
    }
    gPoolMarks = marks;
    gPoolMarkCapacity = capacity;
  }
  gPoolMarks[gPoolDepth] = gPoolCount;
  gPoolDepth += 1;
}

/* An allocation with no pool open -- there is none before main starts -- is
 * simply not tracked, which is the behaviour there used to be everywhere. */
void __cm_poolAdd(void *object) {
  if (gPoolDepth == 0 || object == NULL) {
    return;
  }
  if (gPoolCount == gPoolCapacity) {
    int capacity = gPoolCapacity == 0 ? 64 : gPoolCapacity * 2;
    void **items = realloc(gPoolItems, (size_t)capacity * sizeof(void *));
    if (!items) {
      printf("Runtime error : out of memory recording a temporary.\n");
      exit(1);
    }
    gPoolItems = items;
    gPoolCapacity = capacity;
  }
  gPoolItems[gPoolCount] = object;
  gPoolCount += 1;
}

void __cm_poolPop(void) {
  int mark;

  if (gPoolDepth == 0) {
    return;
  }
  gPoolDepth -= 1;
  mark = gPoolMarks[gPoolDepth];

  /* The count comes down as each entry is released, so anything allocated by
   * a release -- freeing a List releases its items -- lands in the pool
   * below rather than in the one being emptied. */
  while (gPoolCount > mark) {
    void *object = gPoolItems[gPoolCount - 1];
    gPoolCount -= 1;
    __cm_release(object);
  }
}

int __cm_poolDepth(void) {
  return gPoolDepth;
}

/* A throw jumps over every pool the try body opened, so the handler asks for
 * them to be closed rather than leaving them open forever. The objects in
 * them are temporaries; anything the body stored somewhere has a reference of
 * its own and survives. */
void __cm_poolUnwind(int depth) {
  while (gPoolDepth > depth) {
    __cm_poolPop();
  }
}
