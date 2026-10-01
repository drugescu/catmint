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
#include <fcntl.h>
#include <math.h>
#include <setjmp.h>
/* Spelled through a macro so the file still compiles as plain C89 anywhere
 * that does not know the attribute. */
#if defined(__GNUC__) || defined(__clang__)
#define CATMINT_NORETURN __attribute__((noreturn))
#else
#define CATMINT_NORETURN
#endif

#include <pthread.h>
#include <sys/wait.h>
#include <unistd.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

struct TString;

struct __catmint_rtti {
  struct TString *name;         /* the class name, as a catmint String */
  int size;                     /* bytes to allocate for an instance    */
  struct __catmint_rtti *parent;/* null for Object                      */
  void *interfaces;             /* __cm_iface[], ending in a null entry */
  void *finalize;               /* run before the memory goes back, or  */
                                /* null; see M6_Object_release          */
  int *fields;                  /* byte offsets of this class's         */
                                /* reference fields, ending in -1, or   */
                                /* null; see object_free                */
  void *vtable[];               /* parent's slots first, then new ones  */
};

/* Where in a class's virtual table the run of slots implementing one
 * interface begins. A class carries one of these per interface it
 * implements, and the array ends with a null entry. */
struct __cm_iface {
  struct __catmint_rtti *iface;
  int base;
};

/* The ABI stamp. Object layouts and the virtual table slot order are fixed
 * by agreement between this file and IRGenerator.cpp, and a disagreement is
 * a silent miscompile. Every generated program refers to this symbol by name,
 * so a runtime and a compiler that disagree fail to link instead. Change
 * CATMINT_ABI here and in IRGenerator.h whenever that agreement changes -- a
 * slot moved, a field added to the type information, an object reshaped. */
#define CATMINT_ABI 1
#define CATMINT_ABI_NAME_(n) __catmint_abi_##n
#define CATMINT_ABI_NAME(n) CATMINT_ABI_NAME_(n)
const int CATMINT_ABI_NAME(CATMINT_ABI) = CATMINT_ABI;

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

/* Another program, running beside this one. The pipe is set when the process
 * was started to be read from or written to; the pid when it was started to
 * be waited for. This is the whole of catmint's concurrency: separate
 * processes with no shared memory, which is the only kind that costs the
 * object model nothing. */
struct TProcess {
  struct __catmint_rtti *rtti;
  int refs;
  FILE *pipe;
  int pid;
};

/* A fixed-length run of numbers, stored as numbers rather than as object
 * references. This is the one thing List cannot be: a List holds pointers to
 * boxed values, so a million flags is a million allocations and a pointer
 * chase per element.
 *
 * Three of them rather than one generic one, because catmint has no generics
 * and is not getting any. Each is the same eight lines three times over,
 * which is a smaller price than a type system that could express `Array of
 * Int`. */
struct TBytes {
  struct __catmint_rtti *rtti;
  int refs;
  int length;
  unsigned char *data;
};

struct TInts {
  struct __catmint_rtti *rtti;
  int refs;
  int length;
  long long *data;
};

struct TFloats {
  struct __catmint_rtti *rtti;
  int refs;
  int length;
  double *data;
};

/* Worker has no state: it exists to name the two static methods that wait
 * for a thread and report how many cores there are. */
/* Handles has no state of its own: the table is below, and the class exists
 * to give the functions a home. */
struct THandles {
  struct __catmint_rtti *rtti;
  int refs;
};

struct TWorker {
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
    void *interfaces;                                                          \
    void *finalize;                                                            \
    int *fields;                                                               \
    void *vtable[slots];                                                       \
  } name

/* Object holds six slots, so every subclass's own methods start at six.
 * These sizes are the totals, Object's included. */
CATMINT_RTTI_TYPE(catmint_rtti6_object, 6);
CATMINT_RTTI_TYPE(catmint_rtti20_io, 20);
CATMINT_RTTI_TYPE(catmint_rtti11_list, 11);
CATMINT_RTTI_TYPE(catmint_rtti8_integer, 8);
CATMINT_RTTI_TYPE(catmint_rtti15_file, 15);
CATMINT_RTTI_TYPE(catmint_rtti12_process, 12);
CATMINT_RTTI_TYPE(catmint_rtti10_array, 10);
/* Bytes carries two more than Ints and Floats do: it is the one of the three
 * that bridges to String and File, because it is the one whose element is a
 * byte. */
CATMINT_RTTI_TYPE(catmint_rtti12_bytes, 12);
CATMINT_RTTI_TYPE(catmint_rtti20_string, 20);


#define RTTI(x) ((struct __catmint_rtti *)&(x))

void  M6_Object_abort(struct TObject *self) CATMINT_NORETURN;
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
struct TString *M6_String_fromC(const char *source, int max);
struct TString *M6_String_fromBytes(struct TBytes *source, int max);
struct TString *M6_String_replace(struct TString *self, struct TString *from,
                                  struct TString *to);
double M6_String_toFloat(struct TString *self);
struct TBytes *M6_String_toBytes(struct TString *self);

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
int M4_File_readBytes(struct TFile *self, struct TBytes *buffer);
int M4_File_writeBytes(struct TFile *self, struct TBytes *buffer, int count);
int M4_File_exists(struct TString *path);
int M4_File_remove(struct TString *path);

int M7_Process_open(struct TProcess *self, struct TString *command,
                     struct TString *mode);
struct TString *M7_Process_readLine(struct TProcess *self);
struct TProcess *M7_Process_write(struct TProcess *self, struct TString *text);
int M7_Process_eof(struct TProcess *self);
int M7_Process_finish(struct TProcess *self);
int M7_Process_openArgs(struct TProcess *self, struct TList *args);
static int process_close(struct TProcess *self);
int M7_Process_run(struct TString *command);
int M7_Process_start(struct TString *command);
int M7_Process_runArgs(struct TList *args);
int M7_Process_startArgs(struct TList *args);
int M7_Process_wait(int pid);
int M7_Process_pid(void);

long long M6_Worker_wait(int handle);
int M6_Worker_count(void);

void M5_Bytes_init(struct TBytes *self, int count);
int M5_Bytes_len(struct TBytes *self);
int M5_Bytes_get(struct TBytes *self, int index);
int M5_Bytes_set(struct TBytes *self, int index, int value);
struct TBytes *M5_Bytes_fill(struct TBytes *self, int value);
struct TString *M5_Bytes_toString(struct TBytes *self);
struct TBytes *M5_Bytes_slice(struct TBytes *self, int start, int end);

void M4_Ints_init(struct TInts *self, int count);
int M4_Ints_len(struct TInts *self);
long long M4_Ints_get(struct TInts *self, int index);
long long M4_Ints_set(struct TInts *self, int index, long long value);
struct TInts *M4_Ints_fill(struct TInts *self, long long value);

void M6_Floats_init(struct TFloats *self, int count);
int M6_Floats_len(struct TFloats *self);
double M6_Floats_get(struct TFloats *self, int index);
double M6_Floats_set(struct TFloats *self, int index, double value);
struct TFloats *M6_Floats_fill(struct TFloats *self, double value);

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
long long M7_Integer_getLong(struct TInteger *self);

void *__catmint_new(struct __catmint_rtti *rtti);
void String_init(struct TString *self);
struct TString *__cm_concatAll(void **parts, int count);
/* Neither of these comes back: one jumps to a handler or exits, the other
 * always jumps. Saying so is not decoration -- it is what lets the optimiser
 * treat a bounds check as a predictable branch and inline the accessor
 * around it. Without it, every array element access stayed a function call. */
void __cm_runtimeError(const char *message) CATMINT_NORETURN;
extern int __cm_line;
void __cm_throw(void *object) CATMINT_NORETURN;
void __cm_retain(void *object);
void __cm_release(void *object);
void __cm_poolAdd(void *object);
int __cm_poolDepth(void);
void __cm_poolUnwind(int depth);
void __cm_poolPop(void);
void __cm_poolAddSlot(void **slot);

extern catmint_rtti20_string RString;

/* Class names. Each is itself a String, so its rtti is RString, and each has
 * a reference count of zero: they are static and must never be freed. */
struct TString NObject = { RTTI(RString), 0, 6, "Object" };
struct TString NString = { RTTI(RString), 0, 6, "String" };
struct TString NIO      = { RTTI(RString), 0, 2, "IO" };
struct TString NList    = { RTTI(RString), 0, 4, "List" };
struct TString NInteger = { RTTI(RString), 0, 7, "Integer" };
struct TString NFile    = { RTTI(RString), 0, 4, "File" };
struct TString NMath    = { RTTI(RString), 0, 4, "Math" };
struct TString NProcess = { RTTI(RString), 0, 7, "Process" };
struct TString NWorker  = { RTTI(RString), 0, 6, "Worker" };
struct TString NHandles = { RTTI(RString), 0, 7, "Handles" };
struct TString NBytes   = { RTTI(RString), 0, 5, "Bytes" };
struct TString NInts    = { RTTI(RString), 0, 4, "Ints" };
struct TString NFloats  = { RTTI(RString), 0, 6, "Floats" };

#define CATMINT_OBJECT_SLOTS                                                   \
  (void *)M6_Object_abort, (void *)M6_Object_typeName,                         \
      (void *)M6_Object_copy, (void *)M6_Object_retain,                        \
      (void *)M6_Object_release, (void *)M6_Object_refs

catmint_rtti6_object RObject = {
  &NObject, sizeof(struct TObject), NULL, NULL, NULL, NULL,
  { CATMINT_OBJECT_SLOTS }
};

catmint_rtti20_string RString = {
  &NString, sizeof(struct TString), RTTI(RObject), NULL, NULL, NULL,
  { CATMINT_OBJECT_SLOTS,
    (void *)M6_String_length, (void *)M6_String_toInt,
    (void *)M6_String_substring, (void *)M6_String_concat,
    (void *)M6_String_equal, (void *)M6_String_at,
    (void *)M6_String_indexOf, (void *)M6_String_trim,
    (void *)M6_String_upper, (void *)M6_String_lower,
    (void *)M6_String_split,
    (void *)M6_String_replace, (void *)M6_String_toFloat,
    (void *)M6_String_toBytes }
};

/* The two new slots go on the end. Inserting anywhere else would renumber
 * `in` and `out` and silently break every already-compiled caller. */
catmint_rtti20_io RIO = {
  &NIO, sizeof(struct TIO), RTTI(RObject), NULL, NULL, NULL,
  { CATMINT_OBJECT_SLOTS,
    (void *)M2_IO_in, (void *)M2_IO_out,
    (void *)M2_IO_readLine, (void *)M2_IO_eof, (void *)M2_IO_entropy,
    (void *)M2_IO_ticks, (void *)M2_IO_epoch, (void *)M2_IO_localOffset,
    (void *)M2_IO_sleep,
    (void *)M2_IO_args, (void *)M2_IO_arg, (void *)M2_IO_err,
    (void *)M2_IO_exit, (void *)M2_IO_allocated }
};

catmint_rtti15_file RFile = {
  &NFile, sizeof(struct TFile), RTTI(RObject), NULL, NULL, NULL,
  { CATMINT_OBJECT_SLOTS,
    (void *)M4_File_open, (void *)M4_File_readLine, (void *)M4_File_readAll,
    (void *)M4_File_write, (void *)M4_File_eof, (void *)M4_File_close,
    (void *)M4_File_isOpen,
    (void *)M4_File_readBytes, (void *)M4_File_writeBytes }
};

/* Every Math method is static, so the class contributes no slots of its own
 * and its table is Object's. The class exists only to name the functions. */
catmint_rtti6_object RMath = {
  &NMath, sizeof(struct TMath), RTTI(RObject), NULL, NULL, NULL,
  { CATMINT_OBJECT_SLOTS }
};

catmint_rtti6_object RHandles = {
  &NHandles, sizeof(struct THandles), RTTI(RObject), NULL, NULL, NULL,
  { CATMINT_OBJECT_SLOTS }
};

catmint_rtti6_object RWorker = {
  &NWorker, sizeof(struct TWorker), RTTI(RObject), NULL, NULL, NULL,
  { CATMINT_OBJECT_SLOTS }
};

catmint_rtti12_bytes RBytes = {
  &NBytes, sizeof(struct TBytes), RTTI(RObject), NULL, NULL, NULL,
  { CATMINT_OBJECT_SLOTS,
    (void *)M5_Bytes_len, (void *)M5_Bytes_get, (void *)M5_Bytes_set,
    (void *)M5_Bytes_fill,
    (void *)M5_Bytes_toString, (void *)M5_Bytes_slice }
};

catmint_rtti10_array RInts = {
  &NInts, sizeof(struct TInts), RTTI(RObject), NULL, NULL, NULL,
  { CATMINT_OBJECT_SLOTS,
    (void *)M4_Ints_len, (void *)M4_Ints_get, (void *)M4_Ints_set,
    (void *)M4_Ints_fill }
};

catmint_rtti10_array RFloats = {
  &NFloats, sizeof(struct TFloats), RTTI(RObject), NULL, NULL, NULL,
  { CATMINT_OBJECT_SLOTS,
    (void *)M6_Floats_len, (void *)M6_Floats_get, (void *)M6_Floats_set,
    (void *)M6_Floats_fill }
};

catmint_rtti12_process RProcess = {
  &NProcess, sizeof(struct TProcess), RTTI(RObject), NULL, NULL, NULL,
  { CATMINT_OBJECT_SLOTS,
    (void *)M7_Process_open, (void *)M7_Process_readLine,
    (void *)M7_Process_write, (void *)M7_Process_eof,
    (void *)M7_Process_finish, (void *)M7_Process_openArgs }
};

catmint_rtti11_list RList = {
  &NList, sizeof(struct TList), RTTI(RObject), NULL, NULL, NULL,
  { CATMINT_OBJECT_SLOTS,
    (void *)M4_List_len, (void *)M4_List_get, (void *)M4_List_set,
    (void *)M4_List_append, (void *)M4_List_slice }
};

catmint_rtti8_integer RInteger = {
  &NInteger, sizeof(struct TInteger), RTTI(RObject), NULL, NULL, NULL,
  { CATMINT_OBJECT_SLOTS,
    (void *)M7_Integer_get, (void *)M7_Integer_getLong }
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

void Process_init(struct TProcess *self) {
  self->pipe = NULL;
  self->pid = 0;
}

void Handles_init(struct THandles *self) {
  (void)self;
}

void Worker_init(struct TWorker *self) {
  (void)self;
}

/* Declaring one without a length gives an empty array; `new Bytes(n)` then
 * runs the constructor below. */
void Bytes_init(struct TBytes *self)   { self->length = 0; self->data = NULL; }
void Ints_init(struct TInts *self)     { self->length = 0; self->data = NULL; }
void Floats_init(struct TFloats *self) { self->length = 0; self->data = NULL; }

/* A String of a given length, with room for its characters in the same
 * allocation. Two allocations per string -- the object and its buffer --
 * was half the cost of building one, and a program that builds strings
 * spends most of its time here.
 *
 * The characters live immediately after the struct, which is how free()
 * recognises them: an inline buffer is not freed separately. */
static struct TString *new_string(int length) {
  struct TString *result =
      malloc(sizeof(struct TString) + (size_t)length + 1);

  if (!result) {
    printf("Runtime error : out of memory making a String.\n");
    exit(1);
  }

  result->rtti = RTTI(RString);
  result->refs = 1;
  result->length = length;
  result->string = (char *)(result + 1);
  result->string[length] = '\0';

  gLiveObjects += 1;
  __cm_poolAdd(result);
  return result;
}

/* Whether a String's characters are in the same block as the String. */
static int owns_inline_chars(struct TString *text) {
  return text->string == (char *)(text + 1);
}

/* Build a catmint String from a NUL-terminated buffer. */
static struct TString *make_string(const char *text) {
  size_t length = strlen(text);
  struct TString *result = new_string((int)length);

  memcpy(result->string, text, length);
  return result;
}

/* -------------------------------------------------------------------------
 * Object
 * ------------------------------------------------------------------------- */

CATMINT_NORETURN void M6_Object_abort(struct TObject *self) {
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
    /* The copy is exactly as long as the RTTI says, so an inline buffer did
     * not come with it: whatever the original owned, the copy gets its own. */
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
  } else if (copy->rtti == RTTI(RProcess)) {
    ((struct TProcess *)copy)->pipe = NULL;
  } else if (copy->rtti == RTTI(RBytes) || copy->rtti == RTTI(RInts) ||
             copy->rtti == RTTI(RFloats)) {
    /* Two arrays must not share one buffer, or freeing both would free it
     * twice. The element width comes from which class it is. */
    struct TBytes *array = (struct TBytes *)copy;
    size_t width = copy->rtti == RTTI(RBytes)  ? sizeof(unsigned char)
                   : copy->rtti == RTTI(RInts) ? sizeof(long long)
                                               : sizeof(double);
    if (array->data && array->length > 0) {
      size_t bytes = (size_t)array->length * width;
      unsigned char *fresh = malloc(bytes);
      memcpy(fresh, ((struct TBytes *)self)->data, bytes);
      array->data = fresh;
    }
  }

  /* A user class's reference fields are shared by the two objects now, so each
   * one gains a holder -- exactly as a List's items do above. Without this the
   * copy and the original each release the field when they are freed, and the
   * second of them releases something already gone. It only became wrong when
   * freeing started following these fields: before that nobody released them
   * at all, so a shallow copy was harmless. */
  if (self->rtti->fields != NULL) {
    const int *offset;
    for (offset = self->rtti->fields; *offset >= 0; ++offset) {
      void **slot = (void **)((char *)copy + *offset);
      __cm_retain(*slot);
    }
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
    if (text->string && text->string != gEmptyChars &&
        !owns_inline_chars(text)) {
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
  } else if (self->rtti == RTTI(RProcess)) {
    process_close((struct TProcess *)self);
  } else if (self->rtti == RTTI(RBytes) || self->rtti == RTTI(RInts) ||
             self->rtti == RTTI(RFloats)) {
    /* All three have their length and their buffer in the same two fields,
     * which is what makes one branch enough. */
    struct TBytes *array = (struct TBytes *)self;
    free(array->data);
    array->data = NULL;
    array->length = 0;
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
  /* The class's own last word, before anything is taken apart. A field in the
   * type information rather than a virtual table slot: a slot would have had
   * to go into Object, which shifts every other built-in's numbering, and
   * this renumbers nothing.
   *
   * The count is set to 1 for the duration so that a retain and release
   * inside the finalizer -- an interpolated string, a method call -- cannot
   * re-enter this function and free the object twice. */
  if (self->rtti != NULL && self->rtti->finalize != NULL) {
    void (*finalize)(void *) = (void (*)(void *))self->rtti->finalize;
    self->refs = 1;
    finalize(self);
  }
  /* Let go of what this object's fields were holding. Until this existed a
   * class with a String field leaked that String every time an instance went
   * away -- not a few bytes at exit but a leak that grows, since a loop
   * making and dropping a hundred objects left a hundred Strings behind and
   * `IO.allocated()` said so.
   *
   * The offsets come from the generator, which knows the layout; the runtime
   * only walks them. The count is held at 1 for the walk so that a field
   * pointing back at this object cannot re-enter and free it twice. */
  self->refs = 1;
  if (self->rtti != NULL && self->rtti->fields != NULL) {
    const int *offset;
    for (offset = self->rtti->fields; *offset >= 0; ++offset) {
      void **slot = (void **)((char *)self + *offset);
      if (*slot != NULL) {
        void *held = *slot;
        *slot = NULL;
        __cm_release(held);
      }
    }
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

  result = new_string(end - start);
  memcpy(result->string, self->string + start, (size_t)(end - start));
  return result;
}

struct TString *M6_String_concat(struct TString *self, struct TString *other) {
  struct TString *result = new_string(self->length + other->length);

  memcpy(result->string, self->string, (size_t)self->length);
  memcpy(result->string + self->length, other->string, (size_t)other->length);
  return result;
}

/* Several at once, which is what a chain of '+' and every interpolated
 * string really is. Joining them in one pass allocates the answer once
 * instead of once per '+', and the intermediate strings nobody asked for
 * are never made at all. */
struct TString *__cm_concatAll(void **parts, int count) {
  struct TString *result;
  int length = 0;
  int at = 0;
  int i;

  for (i = 0; i < count; ++i) {
    if (parts[i]) {
      length += ((struct TString *)parts[i])->length;
    }
  }

  result = new_string(length);
  for (i = 0; i < count; ++i) {
    struct TString *part = (struct TString *)parts[i];
    if (!part) {
      continue;
    }
    memcpy(result->string + at, part->string, (size_t)part->length);
    at += part->length;
  }
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
  /* memcmp, not strncmp: a catmint String carries its length rather than
   * ending at a NUL, so it may contain one -- Bytes.toString() and a binary
   * file read both produce such strings. strncmp stopped at the first NUL,
   * which made {0,1} and {0,2} compare equal. The lengths are known equal by
   * the check above, so comparing the whole range is safe. */
  return memcmp(self->string, other->string, (size_t)self->length) == 0;
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

/* Whether this class, or any it inherits from, promised this interface. */
static int implements(struct __catmint_rtti *rtti,
                      struct __catmint_rtti *target) {
  for (; rtti; rtti = rtti->parent) {
    struct __cm_iface *entry = (struct __cm_iface *)rtti->interfaces;
    if (!entry) {
      continue;
    }
    for (; entry->iface; ++entry) {
      if (entry->iface == target) {
        return 1;
      }
    }
  }
  return 0;
}

/* Where an object's implementation of an interface begins in its virtual
 * table. The generated code adds the method's position within the interface
 * to this and loads that slot, so an interface call is one short search and
 * then an ordinary indexed load. The search is over the interfaces a class
 * promised, which is a handful at most. */
int __cm_ifaceBase(void *object, struct __catmint_rtti *target) {
  struct __catmint_rtti *rtti;

  __cm_checkNull(object);
  for (rtti = ((struct TObject *)object)->rtti; rtti; rtti = rtti->parent) {
    struct __cm_iface *entry = (struct __cm_iface *)rtti->interfaces;
    if (!entry) {
      continue;
    }
    for (; entry->iface; ++entry) {
      if (entry->iface == target) {
        return entry->base;
      }
    }
  }

  {
    char message[256];
    snprintf(message, sizeof(message), "%s does not do %s.",
             ((struct TObject *)object)->rtti->name->string,
             target->name->string);
    __cm_runtimeError(message);
  }
  return 0;
}

/* 'expr is Type': 1 when the object's class is the target, inherits from it,
 * or promised it as an interface, 0 otherwise, including for null. Unlike a
 * cast this never aborts, which is the point of having it. */
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
  return implements(((struct TObject *)object)->rtti, target);
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
  if (implements(actual, target)) {
    return object;
  }

  {
    char message[256];
    snprintf(message, sizeof(message), "Unable to convert %s into %s.",
             actual->name->string, target->name->string);
    __cm_runtimeError(message);
  }
  return NULL;
}

/* Small values are shared rather than allocated. A List of flags, of counts,
 * of character codes -- the common case -- then costs no allocation at all:
 * the sieve benchmark made two hundred thousand boxes and now makes none.
 *
 * A shared box has a reference count of zero, which already means "static,
 * never free", so retain and release ignore it and it never joins a pool.
 * It is also why Integer has no setter: mutating one of these would change
 * it for everyone holding that number. */
#define CATMINT_SMALL_MIN (-128)
#define CATMINT_SMALL_MAX 1024

static struct TInteger gSmallIntegers[CATMINT_SMALL_MAX - CATMINT_SMALL_MIN + 1];
static int gSmallIntegersReady = 0;

static void prepare_small_integers(void) {
  long long value;
  for (value = CATMINT_SMALL_MIN; value <= CATMINT_SMALL_MAX; ++value) {
    struct TInteger *box = &gSmallIntegers[value - CATMINT_SMALL_MIN];
    box->rtti = RTTI(RInteger);
    box->refs = 0;
    box->value = value;
  }
  gSmallIntegersReady = 1;
}

/* Boxing and unboxing, inserted by the generator where an integer meets a
 * place that holds object references, and on the way back out. The box is 64
 * bits wide, so the generator widens before boxing and narrows after
 * unboxing; no integer type loses anything in a container. */
void *__cm_boxLong(long long value) {
  struct TInteger *box;

  if (value >= CATMINT_SMALL_MIN && value <= CATMINT_SMALL_MAX) {
    if (!gSmallIntegersReady) {
      prepare_small_integers();
    }
    return &gSmallIntegers[value - CATMINT_SMALL_MIN];
  }

  box = (struct TInteger *)__catmint_new(RTTI(RInteger));
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
  /* Built by length, not as a C string: chr(0) is one character, a NUL, and
   * a C string would have been empty. */
  struct TString *result = new_string(1);

  result->string[0] = (char)(code & 0xff);
  return result;
}

/* Text that C owns, copied: the bytes at `source` up to the first NUL or
 * `max` of them, whichever comes first. A copy and never an alias, so C still
 * cannot write into a String. NULL gives null. The compiler makes this call
 * only inside `unsafe`, because reading through a pointer is the promise that
 * it is valid; the bound is what turns an unterminated buffer into a short
 * read where strlen would run on. */
struct TString *M6_String_fromC(const char *source, int max) {
  struct TString *result;
  const char *end;
  size_t length;

  if (max < 0) {
    __cm_runtimeError("String.fromC needs a length of zero or more");
  }
  if (!source) {
    return NULL;
  }
  end = (const char *)memchr(source, '\0', (size_t)max);
  length = end ? (size_t)(end - source) : (size_t)max;
  result = new_string((int)length);
  memcpy(result->string, source, length);
  return result;
}

/* The same out of a Bytes, which knows how large it is: `max` can never reach
 * past the end of the buffer. */
struct TString *M6_String_fromBytes(struct TBytes *source, int max) {
  if (!source) {
    __cm_runtimeError("String.fromC was given a null Bytes.");
  }
  if (max > source->length) {
    max = source->length;
  }
  return M6_String_fromC((const char *)source->data, max);
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
  result = new_string(self->length + growth);
  out = result->string;

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

static int pool_held_objects(void);

/* Objects allocated and not yet given back, and held by something other than
 * a temporary. Compare two readings around a piece of work to see whether it
 * leaks.
 *
 * "Not yet given back" alone made the number useless inside the method that
 * did the work: an object made there stays on that method's pool until it
 * returns, so letting go of it did not lower the count, and every string
 * out() built stayed counted too. What is left out is exactly what closing the
 * pools would free -- see pool_held_objects. A cycle is not among it, which is
 * the point: counting never frees one, and this keeps saying so. */
int M2_IO_allocated(struct TIO *self) {
  int held;

  (void)self;
  held = gLiveObjects - pool_held_objects();
  return held < 0 ? 0 : held;
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
CATMINT_NORETURN void __cm_throw(void *object) {
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

  /* Keep the thrown object alive across the unwind. Its only reference is
   * often the pool of the very work being abandoned -- `throw "a" + b`
   * builds a String there, and so does __cm_runtimeError building its
   * message -- so closing those pools frees it and the handler reads memory
   * that has gone. Retain first, unwind, then hand it to the pool the
   * handler is running in, which balances the retain and releases it when
   * that statement is done.
   *
   * It survived by luck natively and showed up under lli as a crash inside
   * malloc, which is the same way `Object.free` announced itself. */
  __cm_retain(object);

  /* The jump skips every poolPop between here and the handler, so close
   * those pools now; their contents are temporaries of the abandoned work,
   * and their slots hold what the abandoned frames had stored. */
  __cm_poolUnwind(handler->poolDepth);
  /* The retain above is given back by the handler, which opens a pool and
   * puts the caught object in it. Doing it here instead would hand the
   * object to the *catching method's* pool, which does not close until that
   * method returns -- so a loop that threw would pile them up. */
  free(handler);
  longjmp(*buffer, 1);
}

/* What the runtime's own checks call. With a handler installed the message
 * becomes an ordinary thrown String, so a program can catch a null dispatch
 * or an index out of bounds; with none it prints and stops, as before. */
/* The line the program is on, kept up to date only under -g. Zero means the
 * program was built without it, and then a runtime error says what happened
 * without saying where -- which is what every build did before, and what a
 * build that did not ask for debug information still costs nothing for. */
int __cm_line = 0;

CATMINT_NORETURN void __cm_runtimeError(const char *message) {
  char located[512];

  if (__cm_line > 0) {
    snprintf(located, sizeof(located), "line %d : %s", __cm_line, message);
    message = located;
  }

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

/* A pool holds two kinds of entry, told apart by the low bit of the pointer,
 * which is always zero in a real one because every allocation here is at
 * least pointer-aligned.
 *
 *   an object  -- a temporary nothing named. Released when the pool closes.
 *   a slot     -- the address of a variable holding a reference. Released
 *                 only when the pool is *unwound* by a throw.
 *
 * The second kind exists because a throw skips the scope-exit releases of
 * every frame between it and the handler, so whatever those frames had
 * *stored* was orphaned -- their temporaries went back, but the reference a
 * local was holding did not. Registering the slot costs one array entry; on
 * the ordinary path it is simply dropped, so nothing about normal execution
 * changes. */
#define POOL_SLOT_TAG ((uintptr_t)1)

static int pool_is_slot(void *entry) {
  return ((uintptr_t)entry & POOL_SLOT_TAG) != 0;
}

static void pool_close(int unwinding) {
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
    void *entry = gPoolItems[gPoolCount - 1];
    gPoolCount -= 1;

    if (pool_is_slot(entry)) {
      void **slot;
      void *held;

      if (!unwinding) {
        continue; /* its scope will release it, as it always has */
      }
      slot = (void **)((uintptr_t)entry & ~POOL_SLOT_TAG);
      held = *slot;
      /* Nulled first: the same slot can be registered more than once -- a
       * declaration inside a loop body runs every iteration -- and the
       * second release must find nothing left to give back. */
      *slot = NULL;
      __cm_release(held);
      continue;
    }

    __cm_release(entry);
  }
}

void __cm_poolPop(void) { pool_close(/*unwinding=*/0); }

/* The address of a variable that holds a reference, so that a throw passing
 * through this frame can give back what the variable was holding. */
void __cm_poolAddSlot(void **slot) {
  if (gPoolDepth == 0 || slot == NULL) {
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
  gPoolItems[gPoolCount] = (void *)((uintptr_t)slot | POOL_SLOT_TAG);
  gPoolCount += 1;
}

int __cm_poolDepth(void) {
  return gPoolDepth;
}

/* ---- what the pools alone are keeping alive ------------------------------
 *
 * A trial deletion, as a cycle collector does, and with nothing freed. Every
 * object an open pool holds is owed one release per entry. If that is all its
 * count has left -- nothing else holds it -- closing the pools would free it,
 * and freeing it would release what it holds in turn, which may free those. So:
 * count each object down by its pool entries, and where that reaches zero
 * follow its references (the offsets the generator wrote into the type
 * information, and a List's items, exactly as object_free does), counting each
 * down by one, and so on. Everything that reaches zero is what closing the
 * pools would free. Anything a variable, a field or a container still holds
 * does not reach zero, and neither does a cycle.
 *
 * This reads the pool and the counts and writes nothing of the program's.
 * It is a diagnostic, run when asked, and costs what the pools and the
 * freeable part hold. */
struct trial_entry {
  struct TObject *object;
  long left;
  int freeable;
};

struct trial {
  struct trial_entry *slots;
  size_t capacity;
  size_t used;
};

static size_t trial_slot(const struct TObject *object, size_t mask) {
  uint64_t v = (uint64_t)(uintptr_t)object >> 4;

  v *= 0x9E3779B97F4A7C15ull;
  v ^= v >> 32;
  return (size_t)v & mask;
}

static void trial_grow(struct trial *t) {
  size_t capacity = t->capacity ? t->capacity * 2 : 256;
  struct trial_entry *slots = (struct trial_entry *)calloc(capacity, sizeof(*slots));
  size_t i;

  if (!slots) {
    printf("Runtime error : out of memory counting allocations.\n");
    exit(1);
  }
  for (i = 0; i < t->capacity; i++) {
    if (t->slots[i].object) {
      size_t at = trial_slot(t->slots[i].object, capacity - 1);

      while (slots[at].object) {
        at = (at + 1) & (capacity - 1);
      }
      slots[at] = t->slots[i];
    }
  }
  free(t->slots);
  t->slots = slots;
  t->capacity = capacity;
}

/* The entry for an object, made on first sight with all of its count still
 * to account for. The address is good only until the next call. */
static struct trial_entry *trial_for(struct trial *t, struct TObject *object) {
  size_t at;

  if (t->used * 2 >= t->capacity) {
    trial_grow(t);
  }
  at = trial_slot(object, t->capacity - 1);
  while (t->slots[at].object && t->slots[at].object != object) {
    at = (at + 1) & (t->capacity - 1);
  }
  if (!t->slots[at].object) {
    t->slots[at].object = object;
    t->slots[at].left = object->refs;
    t->slots[at].freeable = 0;
    t->used += 1;
  }
  return &t->slots[at];
}

struct trial_work {
  struct TObject **items;
  size_t length;
  size_t capacity;
};

static void trial_push(struct trial_work *w, struct TObject *object) {
  if (w->length == w->capacity) {
    size_t capacity = w->capacity ? w->capacity * 2 : 64;
    struct TObject **items =
        (struct TObject **)realloc(w->items, capacity * sizeof(*items));

    if (!items) {
      printf("Runtime error : out of memory counting allocations.\n");
      exit(1);
    }
    w->items = items;
    w->capacity = capacity;
  }
  w->items[w->length++] = object;
}

/* One reference from an object that would be freed, given back. */
static void trial_release(struct trial *t, struct trial_work *w,
                          struct TObject *object) {
  struct trial_entry *entry;

  if (object == NULL || object->refs <= 0) {
    return; /* nothing there, or static: never freed, never counted */
  }
  entry = trial_for(t, object);
  if (entry->freeable) {
    return;
  }
  entry->left -= 1;
  if (entry->left == 0) {
    entry->freeable = 1;
    trial_push(w, object);
  }
}

static int pool_held_objects(void) {
  struct trial t = {NULL, 0, 0};
  struct trial_work work = {NULL, 0, 0};
  int freeable = 0;
  int i;
  size_t s;

  for (i = 0; i < gPoolCount; i++) {
    struct TObject *object;

    if (pool_is_slot(gPoolItems[i])) {
      continue; /* a variable's address, not an object: it holds a count */
    }
    object = (struct TObject *)gPoolItems[i];
    if (object == NULL || object->refs <= 0) {
      continue;
    }
    trial_for(&t, object)->left -= 1;
  }
  for (s = 0; s < t.capacity; s++) {
    if (t.slots[s].object && t.slots[s].left == 0) {
      t.slots[s].freeable = 1;
      trial_push(&work, t.slots[s].object);
    }
  }
  while (work.length > 0) {
    struct TObject *object = work.items[--work.length];

    freeable += 1;
    if (object->rtti != NULL && object->rtti->fields != NULL) {
      const int *offset;

      for (offset = object->rtti->fields; *offset >= 0; ++offset) {
        trial_release(&t, &work,
                      *(struct TObject **)((char *)object + *offset));
      }
    }
    if (object->rtti == RTTI(RList)) {
      struct TList *list = (struct TList *)object;
      int item;

      for (item = 0; item < list->length; ++item) {
        trial_release(&t, &work, (struct TObject *)list->items[item]);
      }
    }
  }
  free(t.slots);
  free(work.items);
  return freeable;
}

/* A throw jumps over every pool the try body opened, so the handler asks for
 * them to be closed rather than leaving them open forever. The objects in
 * them are temporaries; anything the body stored somewhere has a reference of
 * its own and survives. */
void __cm_poolUnwind(int depth) {
  while (gPoolDepth > depth) {
    pool_close(/*unwinding=*/1);
  }
}

/* -------------------------------------------------------------------------
 * Process
 *
 * Catmint's answer to concurrency is another process, not another thread.
 * Threads would make every reference count atomic, tax every store in every
 * program including the single-threaded ones, and need the temporary pool and
 * the handler stack to be per-thread -- all so that a language with no
 * ownership model could offer shared mutable memory with nothing to reason
 * about a race with. Processes share nothing, so none of that applies, and
 * the whole feature is the hundred lines below.
 *
 * run() is one command, waited for. start() and wait() are the pair that
 * gives real parallelism: begin several, then collect them. open() opens a
 * pipe, for when the answer has to come back.
 * ------------------------------------------------------------------------- */

/* A wait status carries more than the exit code; this is the code itself,
 * or 128 + the signal when the child was killed, as a shell reports it. */
static int exit_status(int status) {
  if (WIFEXITED(status)) {
    return WEXITSTATUS(status);
  }
  if (WIFSIGNALED(status)) {
    return 128 + WTERMSIG(status);
  }
  return -1;
}

/* Let go of a Process's pipe and give back the exit status of what was on the
 * other end, or -1. A pipe from popen is closed with pclose, which also waits;
 * one from openArgs was made by hand, with a child of our own to wait for, and
 * pclose on it would be undefined. */
static int process_close(struct TProcess *self) {
  int status = -1;
  int wait_status;

  if (!self->pipe) {
    return -1;
  }
  if (self->pid > 0) {
    fclose(self->pipe);
    if (waitpid((pid_t)self->pid, &wait_status, 0) >= 0) {
      status = exit_status(wait_status);
    }
  } else {
    wait_status = pclose(self->pipe);
    if (wait_status != -1) {
      status = exit_status(wait_status);
    }
  }
  self->pipe = NULL;
  self->pid = 0;
  return status;
}

/* Run a command and wait for it. The exit status, or -1 when it could not
 * be started -- never an abort, because a command failing is an ordinary
 * thing for a program to have an opinion about. */
int M7_Process_run(struct TString *command) {
  int status = system(command->string);
  if (status == -1) {
    return -1;
  }
  return exit_status(status);
}

/* Start a command without waiting, and give back its process id, or 0 when
 * it could not be started. Collect it with wait(). Static: it is about
 * starting a program, not about a pipe that is already open. */
int M7_Process_start(struct TString *command) {
  pid_t child = fork();

  if (child < 0) {
    return 0;
  }
  if (child == 0) {
    execl("/bin/sh", "sh", "-c", command->string, (char *)NULL);
    _exit(127); /* exec failed: the shell's "command not found" status */
  }
  return (int)child;
}

/* Wait for one started by spawn() and give back its exit status. */
int M7_Process_wait(int pid) {
  int status = 0;

  if (pid <= 0) {
    return -1;
  }
  if (waitpid((pid_t)pid, &status, 0) < 0) {
    return -1;
  }
  return exit_status(status);
}

int M7_Process_pid(void) {
  return (int)getpid();
}

/* Open a command as a pipe, as File.open opens a file: mode "r" to read what
 * it prints, "w" to write to what it reads. 1 when it started, 0 when it did
 * not. */
int M7_Process_open(struct TProcess *self, struct TString *command,
                     struct TString *mode) {
  process_close(self);
  self->pipe = popen(command->string, mode->string);
  return self->pipe != NULL;
}

struct TString *M7_Process_readLine(struct TProcess *self) {
  char buffer[4096];
  size_t length;

  if (!self->pipe || !fgets(buffer, (int)sizeof(buffer), self->pipe)) {
    return make_string("");
  }

  length = strlen(buffer);
  if (length > 0 && buffer[length - 1] == '\n') {
    buffer[length - 1] = '\0';
  }
  return make_string(buffer);
}

struct TProcess *M7_Process_write(struct TProcess *self, struct TString *text) {
  if (self->pipe) {
    fwrite(text->string, 1, (size_t)text->length, self->pipe);
  }
  return self;
}

int M7_Process_eof(struct TProcess *self) {
  int c;

  if (!self->pipe) {
    return 1;
  }
  c = fgetc(self->pipe);
  if (c == EOF) {
    return 1;
  }
  ungetc(c, self->pipe);
  return 0;
}

/* Close the pipe and wait, giving back the command's exit status. */
int M7_Process_finish(struct TProcess *self) {
  return process_close(self);
}

/* The argument vector for execvp, from a List of Strings. This is where the
 * no-shell forms earn the name: each argument is checked and then handed over
 * whole, so nothing in it is ever parsed. Checked before anything starts, and
 * catchably: an empty list, a null, something that is not a String, and a
 * String holding a NUL (which C would read as the end of the argument, so
 * `a\0b` would run as `a`) are all errors rather than guesses. */
static char **argv_from_list(struct TList *args) {
  char **argv;
  int i;

  if (!args) {
    __cm_runtimeError("Process: the argument list is null");
  }
  if (args->length < 1) {
    __cm_runtimeError("Process: the argument list is empty");
  }
  if (args->length > 4096) {
    __cm_runtimeError("Process: too many arguments");
  }
  argv = malloc(sizeof(char *) * ((size_t)args->length + 1));
  if (!argv) {
    printf("Runtime error : out of memory starting a process.\n");
    exit(1);
  }
  for (i = 0; i < args->length; i++) {
    struct TObject *item = (struct TObject *)args->items[i];
    struct TString *text = (struct TString *)item;

    if (!item || item->rtti != RTTI(RString)) {
      free(argv);
      __cm_runtimeError("Process: every argument must be a String");
    }
    if (memchr(text->string, '\0', (size_t)text->length)) {
      free(argv);
      __cm_runtimeError("Process: an argument contains a NUL");
    }
    argv[i] = text->string;
  }
  argv[args->length] = NULL;
  return argv;
}

/* A program started from here must not be lent what this one has open: a
 * file, a socket, a document would stay open in the child for as long as it
 * ran, and it could read it. So the child closes every descriptor above the
 * three standard ones before it execs.
 *
 * The list is taken here, in the parent, because between fork and exec a
 * child may call only async-signal-safe functions -- and another thread (SDL
 * starts several) may have held the malloc lock at the moment of the fork and
 * never release it in the child. The child only calls close.
 *
 * It is found by asking each descriptor in turn, not by reading /dev/fd. The
 * obvious way, opendir and readdir, is two different symbols on Intel and on
 * Apple-silicon Macs (readdir$INODE64 against readdir: the old and the new
 * struct dirent), and this file is one for both architectures; portability.sh
 * caught exactly that. fcntl is the same symbol on both. The scan stops at the
 * descriptor table's size, at most 65536, and `cap` descriptors are returned;
 * a process with more than that open at once keeps the rest open in the
 * child, which is the one limit of this. */
static int open_descriptors(int *fds, int cap) {
  int count = 0;
  int limit = getdtablesize();
  int fd;

  if (limit > 65536) {
    limit = 65536;
  }
  for (fd = 3; fd < limit && count < cap; fd++) {
    if (fcntl(fd, F_GETFD) != -1) {
      fds[count++] = fd;
    }
  }
  return count;
}

static void close_descriptors(const int *fds, int count) {
  int i;

  for (i = 0; i < count; i++) {
    close(fds[i]);
  }
}

/* Start a program without a shell and give back its process id, or 0 when
 * it could not be started. A program that does not exist starts and exits
 * with 127, as it does under a shell. */
int M7_Process_startArgs(struct TList *args) {
  char **argv = argv_from_list(args);
  int held[1024];
  int holding = open_descriptors(held, 1024);
  pid_t child;

  fflush(stdout);
  child = fork();
  if (child < 0) {
    free(argv);
    return 0;
  }
  if (child == 0) {
    close_descriptors(held, holding);
    execvp(argv[0], argv);
    _exit(127);
  }
  free(argv);
  return (int)child;
}

/* Run a program to completion: its exit status, or -1 when it could not be
 * started. */
int M7_Process_runArgs(struct TList *args) {
  int pid = M7_Process_startArgs(args);

  if (pid <= 0) {
    return -1;
  }
  return M7_Process_wait(pid);
}

/* Start a program and read what it prints, standard output and standard
 * error together, in order. It is given no input at all (/dev/null), so a
 * program that reads its terminal sees the end of the file at once instead of
 * waiting for someone who is not there. 1 when it started, 0 when it did
 * not. */
int M7_Process_openArgs(struct TProcess *self, struct TList *args) {
  char **argv;
  int ends[2];
  int held[1024];
  int holding;
  pid_t child;

  process_close(self);
  argv = argv_from_list(args);
  if (pipe(ends) < 0) {
    free(argv);
    return 0;
  }
  fcntl(ends[0], F_SETFD, FD_CLOEXEC);
  holding = open_descriptors(held, 1024);
  fflush(stdout);
  child = fork();
  if (child < 0) {
    close(ends[0]);
    close(ends[1]);
    free(argv);
    return 0;
  }
  if (child == 0) {
    int none = open("/dev/null", O_RDONLY);

    if (none >= 0) {
      dup2(none, 0);
      if (none > 2) {
        close(none);
      }
    }
    dup2(ends[1], 1);
    dup2(ends[1], 2);
    /* Including both ends of the pipe, which were taken with the rest. */
    close_descriptors(held, holding);
    execvp(argv[0], argv);
    _exit(127);
  }
  close(ends[1]);
  free(argv);
  self->pipe = fdopen(ends[0], "r");
  if (!self->pipe) {
    int status;
    close(ends[0]);
    waitpid(child, &status, 0);
    return 0;
  }
  self->pid = (int)child;
  return 1;
}

/* -------------------------------------------------------------------------
 * Handles
 *
 * How C holds a catmint object. C cannot be given an object's address: the
 * first words are type information and a reference count, which C would read
 * as data and could write through, and a pointer C keeps is a reference nobody
 * counts. So C is given a handle, a number carried in a Ptr, that names a slot
 * in this table; the table holds a reference to the object until the handle is
 * dropped.
 *
 * A handle is  magic | generation | index+1.  Three things follow:
 *   - the magic (the top sixteen bits, which no real pointer has) means a Ptr
 *     that never was a handle fails at once, whatever its other bits;
 *   - a slot's generation moves on when it is dropped, so a stale handle can
 *     never match a slot that has since been reused for something else;
 *   - the index is range-checked, so no number can name a slot that is not
 *     there. Nothing here dereferences a handle's own bits.
 *
 * The table is as non-atomic as the reference counts it holds, so it may be
 * used from the program's main thread only, and says so, aborting, otherwise.
 * ------------------------------------------------------------------------- */

#define CATMINT_HANDLE_MAGIC ((uint64_t)0x4348 << 48)
#define CATMINT_HANDLE_INDEX_BITS 24
#define CATMINT_HANDLE_INDEX_MASK (((uint64_t)1 << CATMINT_HANDLE_INDEX_BITS) - 1)
#define CATMINT_HANDLE_NO_SLOT 0xFFFFFFFFu

struct __cm_handle_slot {
  void *object;          /* NULL while the slot is free */
  uint32_t generation;   /* 1 .. 2^24 - 1, never 0 */
  uint32_t next_free;    /* the free list, while the slot is free */
};

static struct __cm_handle_slot *gHandleSlots = NULL;
static uint32_t gHandleCount = 0;
static uint32_t gHandleCapacity = 0;
static uint32_t gHandleFree = CATMINT_HANDLE_NO_SLOT;

/* The thread the program started on, recorded before main runs. */
static pthread_t gMainThread;
static int gMainThreadKnown = 0;

__attribute__((constructor)) static void record_main_thread(void) {
  gMainThread = pthread_self();
  gMainThreadKnown = 1;
}

static int on_main_thread(void) {
  return gMainThreadKnown && pthread_equal(pthread_self(), gMainThread);
}

/* Stop the program, having written what it had printed. abort() does not
 * flush stdio on glibc (it stopped in 2.27; macOS's does), so a program whose
 * output goes to a file or a pipe -- fully buffered -- lost everything it had
 * printed when a guard stopped it. exit() flushes; abort() is used here
 * because the guards run where nothing may be run after them. */
static CATMINT_NORETURN void abort_flushed(void) {
  fflush(stdout);
  fflush(stderr);
  abort();
}

static void require_main_thread(const char *what) {
  if (!on_main_thread()) {
    /* Not __cm_runtimeError: that would throw into the main thread's handler
     * stack from another thread, which is the very race this refuses. */
    fprintf(stderr,
            "Runtime error : %s may only be used on the program's main thread.\n",
            what);
    abort_flushed();
  }
}

/* The slot a handle names, or NULL when it names none that is in use. */
static struct __cm_handle_slot *handle_slot(void *handle) {
  uint64_t value = (uint64_t)(uintptr_t)handle;
  uint64_t index;
  uint32_t generation;

  if ((value & ~(((uint64_t)1 << 48) - 1)) != CATMINT_HANDLE_MAGIC) {
    return NULL;
  }
  index = value & CATMINT_HANDLE_INDEX_MASK;
  generation = (uint32_t)((value >> CATMINT_HANDLE_INDEX_BITS) &
                          CATMINT_HANDLE_INDEX_MASK);
  if (index == 0 || index > gHandleCount) {
    return NULL;
  }
  if (!gHandleSlots[index - 1].object ||
      gHandleSlots[index - 1].generation != generation) {
    return NULL;
  }
  return &gHandleSlots[index - 1];
}

/* Put an object in the table and give back the handle for it. The table holds
 * a reference of its own, given back by drop. */
void *M7_Handles_make(void *object) {
  uint32_t index;
  struct __cm_handle_slot *slot;

  require_main_thread("Handles.make");
  if (!object) {
    __cm_runtimeError("Handles.make needs an object, not null");
  }
  if (gHandleFree != CATMINT_HANDLE_NO_SLOT) {
    index = gHandleFree;
    gHandleFree = gHandleSlots[index].next_free;
  } else {
    if (gHandleCount >= CATMINT_HANDLE_INDEX_MASK) {
      __cm_runtimeError("Handles: too many handles are held at once");
    }
    if (gHandleCount == gHandleCapacity) {
      uint32_t capacity = gHandleCapacity ? gHandleCapacity * 2 : 64;
      struct __cm_handle_slot *grown = (struct __cm_handle_slot *)realloc(
          gHandleSlots, sizeof(struct __cm_handle_slot) * capacity);

      if (!grown) {
        printf("Runtime error : out of memory making a handle.\n");
        exit(1);
      }
      gHandleSlots = grown;
      gHandleCapacity = capacity;
    }
    index = gHandleCount++;
    gHandleSlots[index].generation = 1;
  }
  slot = &gHandleSlots[index];
  slot->object = object;
  slot->next_free = CATMINT_HANDLE_NO_SLOT;
  __cm_retain(object);
  return (void *)(uintptr_t)(CATMINT_HANDLE_MAGIC |
                             ((uint64_t)slot->generation
                              << CATMINT_HANDLE_INDEX_BITS) |
                             ((uint64_t)index + 1));
}

/* The object a handle names, or null if it names none: dropped, from a slot
 * since reused, a null, or not a handle at all. */
void *M7_Handles_get(void *handle) {
  struct __cm_handle_slot *slot;

  require_main_thread("Handles.get");
  slot = handle_slot(handle);
  return slot ? slot->object : NULL;
}

/* Let go of the table's reference. The slot is retired first and the object
 * released last, so that anything the release runs (a finalize) sees a table
 * that is already consistent. Dropping a handle that names nothing is
 * harmless, which includes dropping one twice. */
void M7_Handles_drop(void *handle) {
  struct __cm_handle_slot *slot;
  void *object;

  require_main_thread("Handles.drop");
  slot = handle_slot(handle);
  if (!slot) {
    return;
  }
  object = slot->object;
  slot->object = NULL;
  slot->generation = (slot->generation + 1) & (uint32_t)CATMINT_HANDLE_INDEX_MASK;
  if (slot->generation == 0) {
    slot->generation = 1;
  }
  slot->next_free = gHandleFree;
  gHandleFree = (uint32_t)(slot - gHandleSlots);
  __cm_release(object);
}

/* -------------------------------------------------------------------------
 * Callbacks
 *
 * The function the compiler writes for C to call (callbackTrampoline) uses
 * these three. The counts, pools and handler stack are not atomic, so it
 * refuses to run anywhere but the program's own thread. An error the method
 * throws is not allowed to leave through C's frames -- longjmp over a qsort
 * skips whatever qsort still had to do -- so it is caught, kept here, and
 * thrown by the extern call that was running once C has returned.
 * ------------------------------------------------------------------------- */

static void *gPendingError = NULL;

/* On entry. 1 means an error is already pending, so do nothing and answer
 * zero; anything else runs the method. Off the main thread it aborts, before
 * touching anything shared: a callback that C calls from a thread of its own
 * is exactly the race the rest of the runtime is built not to have. */
int __cm_callbackEnter(void) {
  if (!on_main_thread()) {
    fputs("Runtime error : a callback was called on a thread other than the "
          "program's main thread.\n"
          "  C called catmint from a thread of its own; the reference counts "
          "are not atomic, so it was stopped.\n",
          stderr);
    abort_flushed();
  }
  return gPendingError != NULL;
}

/* In the handler path: the method threw. __cm_throw retained the error for the
 * unwind, and that reference is the one kept. */
void __cm_callbackFail(void) {
  gPendingError = gThrown;
}

static CATMINT_NORETURN void callback_rethrow(void) {
  void *error = gPendingError;

  gPendingError = NULL;
  /* The kept reference becomes the pool's, which is how a thrown object is
   * always owned until its handler is done with it. */
  __cm_poolAdd(error);
  __cm_throw(error);
}

/* After every call to C. The first test is the whole cost of a call that had
 * no callback, and it is small enough to be inlined into the caller. */
void __cm_callbackRethrow(void) {
  if (__builtin_expect(gPendingError != NULL, 0)) {
    callback_rethrow();
  }
}

/* -------------------------------------------------------------------------
 * Worker
 *
 * A thread, through a door narrow enough that none of the rest of the
 * runtime has to become thread-safe. A worker runs a *static* method taking
 * one integer and returning one, and the compiler refuses to spawn anything
 * that could allocate, throw, or touch an object. So a worker never reaches
 * the reference counts, the temporary pool or the handler stack, and those
 * stay exactly as cheap as they are for a single-threaded program.
 *
 * That is the whole bargain. Widening it -- letting a worker build a String,
 * say -- would mean atomic reference counts on every assignment in every
 * program, a per-thread pool and a per-thread handler stack. This way costs
 * nothing and still parallelises the thing worth parallelising, which is a
 * long arithmetic computation split into chunks.
 * ------------------------------------------------------------------------- */

#define CATMINT_MAX_WORKERS 256

struct __cm_worker {
  pthread_t thread;
  long long (*entry)(long long);
  long long argument;
  long long result;
  int running;
};

static struct __cm_worker gWorkers[CATMINT_MAX_WORKERS];
static int gWorkerCount = 0;
static int gWorkersCollected = 0;

static void *worker_body(void *raw) {
  struct __cm_worker *worker = (struct __cm_worker *)raw;
  worker->result = worker->entry(worker->argument);
  return NULL;
}

/* Start one and give back a handle, or 0 when it could not be started. */
int __cm_workerStart(void *entry, long long argument) {
  struct __cm_worker *worker;

  if (gWorkerCount >= CATMINT_MAX_WORKERS) {
    __cm_runtimeError("too many workers; wait for some before starting more.");
  }

  worker = &gWorkers[gWorkerCount];
  worker->entry = (long long (*)(long long))entry;
  worker->argument = argument;
  worker->result = 0;
  worker->running = 1;

  if (pthread_create(&worker->thread, NULL, worker_body, worker) != 0) {
    worker->running = 0;
    return 0;
  }
  gWorkerCount += 1;
  return gWorkerCount; /* handles are 1-based, so 0 can mean failure */
}

/* Wait for one and give back what its method returned. Each handle is
 * waited for exactly once; asking twice, or for one that was never started,
 * is a mistake and says so rather than quietly answering zero. */
long long M6_Worker_wait(int handle) {
  struct __cm_worker *worker;
  long long result;

  if (handle == 0) {
    return 0; /* the spawn itself failed, and said so by giving back 0 */
  }
  if (handle < 1 || handle > gWorkerCount) {
    __cm_runtimeError("no such worker; wait for each handle exactly once.");
  }

  worker = &gWorkers[handle - 1];
  if (!worker->running) {
    __cm_runtimeError("that worker has already been waited for.");
  }

  pthread_join(worker->thread, NULL);
  worker->running = 0;
  gWorkersCollected += 1;
  result = worker->result;

  /* Once every worker in the table has been collected the table is free
   * again, so a program that spawns in a loop does not run out of handles. */
  if (gWorkersCollected == gWorkerCount) {
    gWorkerCount = 0;
    gWorkersCollected = 0;
  }
  return result;
}

/* How many can usefully run at once. */
int M6_Worker_count(void) {
  long cores = sysconf(_SC_NPROCESSORS_ONLN);
  return cores > 0 ? (int)cores : 1;
}

/* -------------------------------------------------------------------------
 * Bytes, Ints, Floats
 *
 * The one thing a List cannot be: numbers stored as numbers. A List holds
 * object references, so a million flags is a million allocations and a
 * pointer chase per element; these are one allocation and an indexed load.
 *
 * Fixed length on purpose. Growing is what List and Vector are for, and both
 * are expressible on top of what is already here, which is the test for
 * whether something belongs in the runtime at all.
 * ------------------------------------------------------------------------- */

/* One message for all three, because the mistake is the same one. */
static void array_bounds(int index, int length, const char *what) {
  if (index < 0 || index >= length) {
    char message[128];
    snprintf(message, sizeof(message),
             "%s index %d is outside 0 to %d.", what, index, length - 1);
    __cm_runtimeError(message);
  }
}

static void *array_allocate(int count, size_t width, const char *what) {
  void *data;

  if (count < 0) {
    char message[128];
    snprintf(message, sizeof(message), "%s cannot have %d elements.", what,
             count);
    __cm_runtimeError(message);
  }
  if (count == 0) {
    return NULL;
  }

  data = calloc((size_t)count, width);
  if (!data) {
    __cm_runtimeError("Out of memory making an array.");
  }
  return data;
}

void M5_Bytes_init(struct TBytes *self, int count) {
  free(self->data);
  self->data = array_allocate(count, sizeof(unsigned char), "Bytes");
  self->length = count;
}

int M5_Bytes_len(struct TBytes *self) { return self->length; }

int M5_Bytes_get(struct TBytes *self, int index) {
  array_bounds(index, self->length, "Bytes");
  return (int)self->data[index];
}

int M5_Bytes_set(struct TBytes *self, int index, int value) {
  array_bounds(index, self->length, "Bytes");
  self->data[index] = (unsigned char)(value & 0xff);
  return value;
}

/* The bridge between Bytes and the rest of the world. Only Bytes has it, of
 * the three arrays, because a byte is what a file and a string are made of.
 *
 * A catmint String carries an explicit length rather than ending at a NUL, so
 * these round-trip binary data -- a zero byte in the middle included -- which
 * is what makes them usable for anything but text. */
struct TString *M5_Bytes_toString(struct TBytes *self) {
  struct TString *result = new_string(self->length);

  if (self->data && self->length > 0) {
    memcpy(result->string, self->data, (size_t)self->length);
  }
  return result;
}

/* Half-open [start, end), the same convention as String.substring, and the
 * copy owns its own buffer. */
struct TBytes *M5_Bytes_slice(struct TBytes *self, int start, int end) {
  struct TBytes *result;

  if (start < 0 || start > end || end > self->length) {
    __cm_runtimeError("Bytes slice indices out of bounds.");
  }
  result = (struct TBytes *)__catmint_new(RTTI(RBytes));
  M5_Bytes_init(result, end - start);
  if (end > start) {
    memcpy(result->data, self->data + start, (size_t)(end - start));
  }
  return result;
}

struct TBytes *M6_String_toBytes(struct TString *self) {
  struct TBytes *result = (struct TBytes *)__catmint_new(RTTI(RBytes));

  M5_Bytes_init(result, self->length);
  if (self->length > 0) {
    memcpy(result->data, self->string, (size_t)self->length);
  }
  return result;
}

/* Fills the buffer and answers how many bytes arrived, which is less than the
 * buffer holds at the end of the file. Nothing is appended and nothing is
 * interpreted: this is read(2) with bounds. */
int M4_File_readBytes(struct TFile *self, struct TBytes *buffer) {
  size_t got;

  if (!self->handle || !buffer->data || buffer->length <= 0) {
    return 0;
  }
  got = fread(buffer->data, 1, (size_t)buffer->length, self->handle);
  return (int)got;
}

int M4_File_writeBytes(struct TFile *self, struct TBytes *buffer, int count) {
  size_t put;

  if (!self->handle || !buffer->data || count <= 0) {
    return 0;
  }
  if (count > buffer->length) {
    count = buffer->length;
  }
  put = fwrite(buffer->data, 1, (size_t)count, self->handle);
  return (int)put;
}

struct TBytes *M5_Bytes_fill(struct TBytes *self, int value) {
  if (self->data) {
    memset(self->data, value & 0xff, (size_t)self->length);
  }
  return self;
}

void M4_Ints_init(struct TInts *self, int count) {
  free(self->data);
  self->data = array_allocate(count, sizeof(long long), "Ints");
  self->length = count;
}

int M4_Ints_len(struct TInts *self) { return self->length; }

long long M4_Ints_get(struct TInts *self, int index) {
  array_bounds(index, self->length, "Ints");
  return self->data[index];
}

long long M4_Ints_set(struct TInts *self, int index, long long value) {
  array_bounds(index, self->length, "Ints");
  self->data[index] = value;
  return value;
}

struct TInts *M4_Ints_fill(struct TInts *self, long long value) {
  int i;
  for (i = 0; i < self->length; ++i) {
    self->data[i] = value;
  }
  return self;
}

void M6_Floats_init(struct TFloats *self, int count) {
  free(self->data);
  self->data = array_allocate(count, sizeof(double), "Floats");
  self->length = count;
}

int M6_Floats_len(struct TFloats *self) { return self->length; }

double M6_Floats_get(struct TFloats *self, int index) {
  array_bounds(index, self->length, "Floats");
  return self->data[index];
}

double M6_Floats_set(struct TFloats *self, int index, double value) {
  array_bounds(index, self->length, "Floats");
  self->data[index] = value;
  return value;
}

struct TFloats *M6_Floats_fill(struct TFloats *self, double value) {
  int i;
  for (i = 0; i < self->length; ++i) {
    self->data[i] = value;
  }
  return self;
}
