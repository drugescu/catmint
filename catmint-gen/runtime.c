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

void *__catmint_new(struct __catmint_rtti *rtti);
void String_init(struct TString *self);

extern catmint_rtti8 RString;

/* Class names. Each is itself a String, so its rtti is RString. */
struct TString NObject = { RTTI(RString), 6, "Object" };
struct TString NString = { RTTI(RString), 6, "String" };
struct TString NIO     = { RTTI(RString), 2, "IO" };

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

catmint_rtti5 RIO = {
  &NIO, sizeof(struct TIO), RTTI(RObject),
  { (void *)M6_Object_abort, (void *)M6_Object_typeName, (void *)M6_Object_copy,
    (void *)M2_IO_in, (void *)M2_IO_out }
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
  struct TString *result;

  (void)self;
  buffer[0] = '\0';
  if (scanf("%255s", buffer) != 1) {
    buffer[0] = '\0';
  }

  result = (struct TString *)__catmint_new(RTTI(RString));
  String_init(result);
  result->length = (int)strlen(buffer);
  result->string = calloc(result->length + 1, 1);
  strcpy(result->string, buffer);
  return result;
}

struct TIO *M2_IO_out(struct TIO *self, struct TString *message) {
  printf("%s", message->string);
  return self;
}

/* -------------------------------------------------------------------------
 * Helpers the generated code calls directly
 * ------------------------------------------------------------------------- */

/* Called before every dispatch. */
void __lcpl_checkNull(void *object) {
  if (object == NULL) {
    printf("Runtime error : Calling a method of a void object.\n");
    exit(1);
  }
}

/* A checked downcast: walk the object's ancestry looking for the target. */
void *__lcpl_cast(void *object, struct __catmint_rtti *target) {
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

/* What makes out(someInt) work: the generated code inserts this call. */
struct TString *__lcpl_intToString(int value) {
  char buffer[32];
  struct TString *result;

  memset(buffer, 0, sizeof(buffer));
  snprintf(buffer, sizeof(buffer), "%d", value);

  result = (struct TString *)__catmint_new(RTTI(RString));
  String_init(result);
  result->length = (int)strlen(buffer);
  result->string = calloc(result->length + 1, 1);
  strcpy(result->string, buffer);
  return result;
}
