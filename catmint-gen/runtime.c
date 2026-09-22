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
 *   - every object begins with a pointer to its run-time type information;
 *   - a virtual table is an array of function pointers at the end of the RTTI
 *     record, with the parent's slots first;
 *   - the built-in slot order is Object {abort, typeName, copy}, then IO
 *     {in, out} or String {length, toInt, substring, concat, equal};
 *   - a method is named M<length of class name>_<class>_<method> and takes the
 *     receiver as its first argument.
 *
 * Build:  clang -O0 -emit-llvm -S runtime.c -o runtime.host.ll
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct TString;

struct __catmint_rtti {
  struct TString *name;         /* the class name, as a catmint String */
  int size;                     /* bytes to allocate for an instance    */
  struct __catmint_rtti *parent;/* null for Object                      */
  void *vtable[];               /* parent's slots first, then new ones  */
};

struct TObject {
  struct __catmint_rtti *rtti;
};

struct TString {
  struct __catmint_rtti *rtti;
  int length;
  char *string;
};

struct TIO {
  struct __catmint_rtti *rtti;
};

/* A growable array of object references. This is the one container the
 * runtime provides; richer ones (a dictionary, say) are written in catmint on
 * top of it, because everything they need beyond raw memory is expressible in
 * the language. */
struct TList {
  struct __catmint_rtti *rtti;
  int length;
  int capacity;
  void **items;
};

/* A boxed Int, so that an Int can be stored in a List. The generated code
 * boxes and unboxes automatically where a conversion is needed. */
struct TInteger {
  struct __catmint_rtti *rtti;
  int value;
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

CATMINT_RTTI_TYPE(catmint_rtti3, 3);
CATMINT_RTTI_TYPE(catmint_rtti7, 7);
CATMINT_RTTI_TYPE(catmint_rtti8_list, 8);
CATMINT_RTTI_TYPE(catmint_rtti5, 5);
CATMINT_RTTI_TYPE(catmint_rtti8, 8);

#define RTTI(x) ((struct __catmint_rtti *)&(x))

void  M6_Object_abort(struct TObject *self);
struct TString *M6_Object_typeName(struct TObject *self);
struct TObject *M6_Object_copy(struct TObject *self);

int M6_String_length(struct TString *self);
int M6_String_toInt(struct TString *self);
struct TString *M6_String_substring(struct TString *self, int start, int end);
struct TString *M6_String_concat(struct TString *self, struct TString *other);
int M6_String_equal(struct TString *self, struct TString *other);

struct TString *M2_IO_in(struct TIO *self);
struct TIO *M2_IO_out(struct TIO *self, struct TString *message);
struct TString *M2_IO_readLine(struct TIO *self);
int M2_IO_eof(struct TIO *self);

int M4_List_len(struct TList *self);
void *M4_List_get(struct TList *self, int index);
void *M4_List_set(struct TList *self, int index, void *value);
struct TList *M4_List_append(struct TList *self, void *value);
struct TList *M4_List_slice(struct TList *self, int start, int end);

int M7_Integer_get(struct TInteger *self);
struct TInteger *M7_Integer_set(struct TInteger *self, int value);

void *__catmint_new(struct __catmint_rtti *rtti);
void String_init(struct TString *self);

extern catmint_rtti8 RString;

/* Class names. Each is itself a String, so its rtti is RString. */
struct TString NObject = { RTTI(RString), 6, "Object" };
struct TString NString = { RTTI(RString), 6, "String" };
struct TString NIO      = { RTTI(RString), 2, "IO" };
struct TString NList    = { RTTI(RString), 4, "List" };
struct TString NInteger = { RTTI(RString), 7, "Integer" };

catmint_rtti3 RObject = {
  &NObject, sizeof(struct TObject), NULL,
  { (void *)M6_Object_abort, (void *)M6_Object_typeName, (void *)M6_Object_copy }
};

catmint_rtti8 RString = {
  &NString, sizeof(struct TString), RTTI(RObject),
  { (void *)M6_Object_abort, (void *)M6_Object_typeName, (void *)M6_Object_copy,
    (void *)M6_String_length, (void *)M6_String_toInt,
    (void *)M6_String_substring, (void *)M6_String_concat,
    (void *)M6_String_equal }
};

/* The two new slots go on the end. Inserting anywhere else would renumber
 * `in` and `out` and silently break every already-compiled caller. */
catmint_rtti7 RIO = {
  &NIO, sizeof(struct TIO), RTTI(RObject),
  { (void *)M6_Object_abort, (void *)M6_Object_typeName, (void *)M6_Object_copy,
    (void *)M2_IO_in, (void *)M2_IO_out,
    (void *)M2_IO_readLine, (void *)M2_IO_eof }
};

catmint_rtti8_list RList = {
  &NList, sizeof(struct TList), RTTI(RObject),
  { (void *)M6_Object_abort, (void *)M6_Object_typeName, (void *)M6_Object_copy,
    (void *)M4_List_len, (void *)M4_List_get, (void *)M4_List_set,
    (void *)M4_List_append, (void *)M4_List_slice }
};

catmint_rtti5 RInteger = {
  &NInteger, sizeof(struct TInteger), RTTI(RObject),
  { (void *)M6_Object_abort, (void *)M6_Object_typeName, (void *)M6_Object_copy,
    (void *)M7_Integer_get, (void *)M7_Integer_set }
};

/* -------------------------------------------------------------------------
 * Allocation and initialisers
 * ------------------------------------------------------------------------- */

/* Allocate an instance of the class described by rtti, zero it, and install
 * the rtti pointer. Generated code calls this for `new` and for every
 * declaration of a variable of class type. */
void *__catmint_new(struct __catmint_rtti *rtti) {
  void *object = malloc(rtti->size);
  memset(object, 0, rtti->size);
  ((struct TObject *)object)->rtti = rtti;
  return object;
}

void Object_init(struct TObject *self) {
  (void)self;
}

void IO_init(struct TIO *self) {
  (void)self;
}

void String_init(struct TString *self) {
  self->string = "";
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

/* A shallow copy: the size in the RTTI covers the whole instance. */
struct TObject *M6_Object_copy(struct TObject *self) {
  struct TObject *copy = malloc(self->rtti->size);
  memcpy(copy, self, self->rtti->size);
  return copy;
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
    printf("Runtime error : Substring indices out of bounds.\n");
    exit(1);
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

struct TIO *M2_IO_out(struct TIO *self, struct TString *message) {
  printf("%s", message->string);
  return self;
}

/* -------------------------------------------------------------------------
 * List
 * ------------------------------------------------------------------------- */

static void list_bounds(struct TList *self, int index) {
  if (index < 0 || index >= self->length) {
    printf("Runtime error : List index out of bounds.\n");
    exit(1);
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
  list_bounds(self, index);
  self->items[index] = value;
  return value;
}

/* Doubling growth, so appending n items costs O(n) in total. */
struct TList *M4_List_append(struct TList *self, void *value) {
  if (self->length == self->capacity) {
    int capacity = self->capacity == 0 ? 4 : self->capacity * 2;
    void **items = realloc(self->items, (size_t)capacity * sizeof(void *));
    if (!items) {
      printf("Runtime error : Out of memory growing a List.\n");
      exit(1);
    }
    self->items = items;
    self->capacity = capacity;
  }
  self->items[self->length] = value;
  self->length += 1;
  return self;
}

/* A half-open range [start, end), matching String.substring. */
struct TList *M4_List_slice(struct TList *self, int start, int end) {
  struct TList *result;
  int i;

  if (start < 0 || start > end || end > self->length) {
    printf("Runtime error : List slice indices out of bounds.\n");
    exit(1);
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

int M7_Integer_get(struct TInteger *self) {
  return self->value;
}

struct TInteger *M7_Integer_set(struct TInteger *self, int value) {
  self->value = value;
  return self;
}

/* -------------------------------------------------------------------------
 * Helpers the generated code calls directly
 * ------------------------------------------------------------------------- */

/* Called before every dispatch. */
void __cm_checkNull(void *object) {
  if (object == NULL) {
    printf("Runtime error : Calling a method of a void object.\n");
    exit(1);
  }
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

  printf("Runtime error : Unable to convert %s into %s.\n",
         actual->name->string, target->name->string);
  exit(1);
}

/* Boxing and unboxing, inserted by the generator where an Int meets a place
 * that holds object references, and on the way back out. */
void *__cm_boxInt(int value) {
  struct TInteger *box = (struct TInteger *)__catmint_new(RTTI(RInteger));
  Integer_init(box);
  box->value = value;
  return box;
}

int __cm_unboxInt(void *object) {
  __cm_checkNull(object);
  if (((struct TObject *)object)->rtti != RTTI(RInteger)) {
    printf("Runtime error : Expected an Integer, found %s.\n",
           ((struct TObject *)object)->rtti->name->string);
    exit(1);
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
