#ifndef IR_GENERATOR_H
#define IR_GENERATOR_H

#include "ASTNodes.h"
#include "SymbolTable.h"
#include "TypeTable.h"

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"

#include <map>
#include <string>
#include <vector>

namespace catmint {

/// \brief The types, globals and functions provided by runtime.ll.
///
/// The object model is fixed by the runtime and must be matched exactly:
///   __catmint_rtti = { TString *name; int size; __catmint_rtti *parent;
///                      void *vtable[]; }
///   TObject        = { __catmint_rtti *rtti; }
///   TString        = { __catmint_rtti *rtti; int length; char *chars; }
///   TIO            = { __catmint_rtti *rtti; }
/// Every object starts with its RTTI pointer, and __catmint_new allocates
/// rtti->size bytes, so a generated class must publish an accurate size.
class RuntimeInterface {
public:
  explicit RuntimeInterface(llvm::Module &M);

  llvm::StructType *rttiType() const { return RTTIType; }
  llvm::StructType *stringType() const { return StringType; }
  llvm::StructType *objectType() const { return ObjectType; }
  llvm::StructType *ioType() const { return IOType; }

  llvm::GlobalVariable *objectRTTI() const { return RObject; }
  llvm::GlobalVariable *stringRTTI() const { return RString; }
  llvm::GlobalVariable *ioRTTI() const { return RIO; }

  llvm::FunctionCallee catmintNew() const { return CatmintNew; }
  llvm::FunctionCallee intToString() const { return IntToString; }
  llvm::FunctionCallee checkNull() const { return CheckNull; }
  llvm::FunctionCallee dynamicCast() const { return DynamicCast; }
  llvm::FunctionCallee stringSubstring() const { return StringSubstring; }
  llvm::FunctionCallee stringConcat() const { return StringConcat; }
  llvm::FunctionCallee stringEqual() const { return StringEqual; }

private:
  llvm::StructType *RTTIType;
  llvm::StructType *StringType;
  llvm::StructType *ObjectType;
  llvm::StructType *IOType;

  llvm::GlobalVariable *RObject;
  llvm::GlobalVariable *RString;
  llvm::GlobalVariable *RIO;

  llvm::FunctionCallee CatmintNew;
  llvm::FunctionCallee IntToString;
  llvm::FunctionCallee CheckNull;
  llvm::FunctionCallee DynamicCast;
  llvm::FunctionCallee StringSubstring;
  llvm::FunctionCallee StringConcat;
  llvm::FunctionCallee StringEqual;
};

/// \brief Everything code generation needs to know about one catmint class.
struct ClassInfo {
  Class *AST = nullptr;
  ClassInfo *Parent = nullptr;
  bool Builtin = false;

  /// The LLVM struct for instances: { rtti, inherited fields..., own fields... }
  llvm::StructType *Ty = nullptr;
  std::vector<llvm::Type *> Elements;

  /// Attribute name -> index into Elements (0 is always the RTTI pointer).
  std::map<std::string, unsigned> FieldIndex;
  std::map<std::string, std::string> FieldType;

  /// Virtual table: parent's slots first, then this class's new methods in
  /// declaration order. An override reuses the parent's slot.
  std::vector<std::string> VTableOrder;
  std::map<std::string, unsigned> VTableIndex;
  /// method name -> (class that provides the implementation, its Method node)
  std::map<std::string, std::pair<ClassInfo *, Method *>> VTableImpl;

  llvm::GlobalVariable *RTTI = nullptr;
  llvm::GlobalVariable *NameGlobal = nullptr;
  llvm::Function *Init = nullptr;
};

/// \brief Lowers a semantically analysed catmint program to an LLVM module.
class IRGenerator {
public:
  IRGenerator(llvm::StringRef ModuleName, Program *P, const TypeTable &ASTTypes,
              SymbolMap DefinitionsMap);

  llvm::Module *runGenerator();

private:
  llvm::LLVMContext Context;
  llvm::Module Module;
  llvm::IRBuilder<> Builder;
  /// Used only to size objects for __catmint_new. A generic 64-bit layout is
  /// correct for every target this compiler is used on, and leaving the module
  /// itself without a datalayout lets lli/clang supply the host's.
  llvm::DataLayout SizingLayout;
  RuntimeInterface Runtime;

  Program *AST;
  TypeTable ASTTypes;
  SymbolMap DefinitionsMap;

  std::map<std::string, ClassInfo> Classes;
  std::vector<ClassInfo *> ClassOrder; // parents before children

  /// A local variable: its stack slot plus the catmint type it was declared with.
  struct Local {
    llvm::Value *Addr;
    std::string TypeName;
  };
  std::vector<std::map<std::string, Local>> Scopes;

  ClassInfo *CurrentClass = nullptr;
  llvm::Function *CurrentFunction = nullptr;
  std::string CurrentReturnType;

  // ---- setup -------------------------------------------------------------
  bool collectClasses();
  bool layoutClass(ClassInfo *CI);
  void buildVTable(ClassInfo *CI);
  void emitClassMetadata(ClassInfo *CI);
  void declareMethods(ClassInfo *CI);
  bool emitInitFunction(ClassInfo *CI);
  bool emitMethod(ClassInfo *CI, Method *M);
  void emitProgramMain();

  // ---- helpers -----------------------------------------------------------
  ClassInfo *lookupClass(const std::string &Name);
  llvm::Type *lowerType(const std::string &TypeName);
  llvm::FunctionType *methodType(ClassInfo *CI, Method *M);
  std::string mangle(const std::string &ClassName, const std::string &Method);
  std::string runtimeSymbol(ClassInfo *CI, const std::string &Method);
  /// The catmint type of an expression, worked out structurally so that code
  /// generation does not depend on the semantic pass having annotated a node.
  std::string staticTypeOf(Expression *E);
  bool isSubclassOf(const std::string &Derived, const std::string &Base);
  llvm::Value *coerce(llvm::Value *V, const std::string &From,
                      const std::string &To, int Line);

  Local *findLocal(const std::string &Name);
  llvm::Value *selfValue();
  llvm::Value *attributeAddress(const std::string &Name, std::string &TypeOut);
  llvm::AllocaInst *createEntryAlloca(llvm::Type *Ty, const std::string &Name);
  bool blockTerminated() const;

  // ---- expressions -------------------------------------------------------
  llvm::Value *emit(Expression *E);
  llvm::Value *emitBlock(Block *B);
  llvm::Value *emitIntConstant(IntConstant *IC);
  llvm::Value *emitFloatConstant(FloatConstant *FC);
  llvm::Value *emitStringConstant(StringConstant *SC);
  llvm::Value *emitNullConstant(NullConstant *NC);
  llvm::Value *emitSymbol(Symbol *S);
  llvm::Value *emitLocalDefinition(LocalDefinition *LD);
  llvm::Value *emitAssignment(Assignment *A);
  llvm::Value *emitBinaryOperator(BinaryOperator *BO);
  llvm::Value *emitUnaryOperator(UnaryOperator *UO);
  llvm::Value *emitIf(IfStatement *If);
  llvm::Value *emitWhile(WhileStatement *W);
  llvm::Value *emitFor(ForStatement *F);
  llvm::Value *emitReturn(ReturnExpression *R);
  llvm::Value *emitDispatch(Dispatch *D);
  llvm::Value *emitStaticDispatch(StaticDispatch *SD);
  llvm::Value *emitNewObject(NewObject *NO);
  llvm::Value *emitCast(Cast *C);
  llvm::Value *emitSubstring(Substring *S);

  llvm::Value *emitCall(ClassInfo *RecvClass, const std::string &MethodName,
                        llvm::Value *Receiver,
                        const std::vector<Expression *> &Args, int Line,
                        bool Virtual, const std::string &StaticClass);

  llvm::Value *makeStringLiteral(const std::string &Value);
  [[noreturn]] void fail(int Line, const std::string &Message);
};

} // namespace catmint

#endif
