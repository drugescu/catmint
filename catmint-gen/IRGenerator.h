#ifndef IR_GENERATOR_H
#define IR_GENERATOR_H

#include "ASTNodes.h"
#include "SymbolTable.h"
#include "TypeTable.h"

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/DIBuilder.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/DebugInfoMetadata.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"

#include <map>
#include <set>
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
  llvm::FunctionCallee longToString() const { return LongToString; }
  llvm::FunctionCallee floatToString() const { return FloatToString; }
  llvm::FunctionCallee boxLong() const { return BoxLong; }
  llvm::FunctionCallee unboxLong() const { return UnboxLong; }
  llvm::FunctionCallee objectEquals() const { return ObjectEquals; }
  llvm::FunctionCallee isType() const { return IsType; }
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
  llvm::FunctionCallee LongToString;
  llvm::FunctionCallee FloatToString;
  llvm::FunctionCallee BoxLong;
  llvm::FunctionCallee UnboxLong;
  llvm::FunctionCallee ObjectEquals;
  llvm::FunctionCallee IsType;
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
  /// Static methods, which take no receiver and get no slot. Inherited like
  /// the virtual table, so a subclass can call its parent's by name.
  std::map<std::string, std::pair<ClassInfo *, Method *>> StaticImpl;

  /// Declared with `interface`: signatures only, and never instantiated.
  bool IsInterface = false;
  /// True while any `abstract def` in this class or its ancestors has no
  /// body. Such a class is a type to hold a subclass in, not something to
  /// make -- the same as an interface, and treated the same way.
  bool IsAbstract = false;
  /// True for `extern class`: its methods are C functions living in some
  /// library, so nothing is emitted for it at all -- no metadata, no
  /// initialiser, no bodies -- and its calls use the unmangled name.
  bool IsExtern = false;
  /// Every interface this class promises, its own and its ancestors'.
  std::vector<std::string> AllInterfaces;
  /// For each of those, where its run of slots begins in this class's
  /// virtual table. An interface's methods are appended there in the
  /// interface's own declaration order, so a call through an interface is
  /// one lookup for the base and then an ordinary indexed load.
  std::vector<std::pair<std::string, unsigned>> InterfaceBases;

  llvm::GlobalVariable *RTTI = nullptr;
  llvm::GlobalVariable *NameGlobal = nullptr;
  llvm::GlobalVariable *IfaceTable = nullptr;
  llvm::Function *Init = nullptr;
};

/// \brief Lowers a semantically analysed catmint program to an LLVM module.
class IRGenerator {
public:
  IRGenerator(llvm::StringRef ModuleName, Program *P, const TypeTable &ASTTypes,
              SymbolMap DefinitionsMap,
              std::set<std::string> ExternalClasses = {},
              bool LibraryOnly = false, bool EmitDebugInfo = false);

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

  /// Classes that belong to a separately compiled module. Their layout and
  /// virtual table are still computed here -- a subclass or a call site needs
  /// them -- but nothing is defined: the metadata is declared external and the
  /// method bodies live in the other object.
  std::set<std::string> ExternalClasses;
  /// True when compiling a .cmm: no Main is required and no entry point is
  /// emitted.
  bool LibraryOnly = false;

  // ---- debug information -------------------------------------------------
  /// Line numbers only: enough for a debugger to say where it is and for a
  /// crash to name a line, without describing types or variables.
  bool EmitDebugInfo = false;
  std::unique_ptr<llvm::DIBuilder> DI;
  llvm::DICompileUnit *DICU = nullptr;
  llvm::DIFile *DIMainFile = nullptr;
  std::map<std::string, llvm::DIFile *> DIFiles;
  llvm::DISubprogram *CurrentSubprogram = nullptr;

  void startDebugInfo();
  llvm::DIFile *debugFileFor(ClassInfo *CI);
  /// Attach a subprogram to \p F and make it the scope for what follows.
  void beginDebugScope(llvm::Function *F, ClassInfo *CI,
                       const std::string &Name, int Line);
  void endDebugScope();
  /// Point the builder at \p Line inside the current subprogram.
  void setDebugLine(int Line);

  bool isExternal(const ClassInfo *CI) const;

  /// A local variable: its stack slot plus the catmint type it was declared with.
  struct Local {
    llvm::Value *Addr;
    std::string TypeName;
    /// False for a reference this scope does not own: an unassigned parameter,
    /// which the caller holds for the whole call, and `self`. Such a slot is
    /// not released when the scope ends and is not registered with the pool,
    /// because there is no reference of its own to give back.
    bool Counted = true;
  };
  /// One scope: the names it declares, and the expressions a `defer` in it
  /// asked to run where it ends.
  struct Scope {
    std::map<std::string, Local> Locals;
    std::vector<Expression *> Deferred;
  };
  std::vector<Scope> Scopes;

  ClassInfo *CurrentClass = nullptr;
  llvm::Function *CurrentFunction = nullptr;
  std::string CurrentReturnType;
  /// How many try handlers are open around the point being emitted. A return
  /// from inside a try has to pop them, or the next throw jumps into a frame
  /// that has gone.
  unsigned OpenHandlers = 0;

  /// Where `break` and `continue` branch to in the innermost enclosing loop,
  /// and how much of the frame has to be given back before they can. A
  /// `break` leaves blocks exactly the way a `return` leaves the function,
  /// and has to undo the same four things on the way out -- which is what the
  /// three depths here record the starting point of.
  struct LoopContext {
    llvm::BasicBlock *BreakTarget;
    llvm::BasicBlock *ContinueTarget;
    size_t ScopeDepth;    ///< Scopes.size() on entry; deeper ones are released
    size_t PoolDepth;     ///< Pools.size() on entry; deeper ones are closed
    unsigned HandlerDepth; ///< OpenHandlers on entry; the rest are popped
  };
  std::vector<LoopContext> Loops;
  /// True while emitting a function that contains a try.
  bool FunctionHasTry = false;
  /// A pool opened around the code being emitted. It is opened
  /// speculatively and taken away again if nothing in it turned out to
  /// allocate, so a loop over integers pays nothing for a mechanism it does
  /// not use.
  struct PoolScope {
    llvm::CallInst *Push;
    unsigned AllocationsBefore;
    /// The closes emitted for this pool by returns inside it, so that they
    /// can be taken away with the open if the pool turns out to be unused.
    std::vector<llvm::CallInst *> Pops;
  };
  std::vector<PoolScope> Pools;
  /// Counts the points at which the generator has emitted something that can
  /// put an object in the open pool.
  unsigned AllocationCount = 0;

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
  /// The truth value of \p V as an i1: any integer width compares against a
  /// zero of its own type, and a reference against null.
  llvm::Value *toCondition(llvm::Value *V, const std::string &Name);
  llvm::Value *coerce(llvm::Value *V, const std::string &From,
                      const std::string &To, int Line);

  Local *findLocal(const std::string &Name);

  // ---- ownership ---------------------------------------------------------
  /// True for a type held as an object reference rather than as a value.
  bool isReferenceTypeName(const std::string &TypeName);
  /// True when the value \p E produces is a Ptr. A Ptr is an LLVM `ptr` like
  /// any object reference, so the LLVM type cannot tell them apart; the
  /// catmint type is what says this one must never be counted.
  bool yieldsPtr(Expression *E);
  void emitRetain(llvm::Value *V);
  void emitRelease(llvm::Value *V);
  /// Store a reference into a slot, keeping the counts right: the new value
  /// gains a holder and the one being replaced loses one. Retaining first
  /// matters, because storing what is already there must not free it.
  void storeReference(llvm::Value *V, llvm::Value *Slot, bool SlotIsLive);
  /// Release every reference local in the innermost \p Count scopes, newest
  /// first. `self` is left alone: the caller holds it for the whole call.
  void releaseScopes(unsigned Count);
  void emitPoolPushCall();
  llvm::CallInst *emitPoolPopCall();
  /// Open a pool here, provisionally.
  void beginPool();
  /// Close it, or erase it when nothing inside it allocated.
  void endPool(bool Reachable);
  /// Note that something allocating has been emitted into the open pool.
  void noteAllocation();
  void emitPoolAdd(llvm::Value *V);
  /// Leave the current function: keep the result alive, release every local,
  /// close every handler and pool this frame opened, and hand the result to
  /// the caller's pool. \p RV may be null for a void return.
  void emitCleanupAndReturn(llvm::Value *RV);
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
  /// The pieces of a chain of string concatenations, left to right. `"a" + b
  /// + "c"` is three pieces rather than two nested additions.
  void collectConcatenation(Expression *E, std::vector<Expression *> &Parts);
  /// Emit a whole chain as one call, or null when this is not one.
  llvm::Value *emitConcatenation(BinaryOperator *BO);
  llvm::Value *emitUnaryOperator(UnaryOperator *UO);
  llvm::Value *emitIf(IfStatement *If);
  llvm::Value *emitWhile(WhileStatement *W);
  llvm::Value *emitFor(ForStatement *F);
  llvm::Value *emitReturn(ReturnExpression *R);
  llvm::Value *emitDispatch(Dispatch *D);
  llvm::Value *emitStaticDispatch(StaticDispatch *SD);
  llvm::Value *emitNewObject(NewObject *NO);
  /// Allocate an instance, run its attribute initialisers and then its
  /// constructor. Shared by `new`, by a declaration of a variable of class
  /// type, and by an attribute of class type.
  llvm::Value *constructObject(ClassInfo *CI,
                               const std::vector<Expression *> &Args, int Line,
                               const std::string &Name);
  llvm::Value *emitFieldAccess(FieldAccess *FA);
  llvm::Value *emitTry(TryStatement *T);
  llvm::Value *emitThrow(ThrowStatement *T);
  llvm::Value *emitDefer(DeferStatement *D);
  llvm::Value *emitSpawn(SpawnStatement *S);
  llvm::Value *emitLoopControl(LoopControl *LC);
  /// The address a C function is given for a String or an array: the
  /// contents, not the catmint object in front of them.
  llvm::Value *marshalToC(llvm::Value *V, const std::string &TypeName,
                          int Line);

  /// Tell the open pool where a reference-holding variable lives, so that a
  /// throw passing through this frame can give back what it holds. The
  /// scope-exit release is unchanged; this is only for the path that skips it.
  void registerReferenceSlot(llvm::Value *Slot, const std::string &TypeName);
  /// Emit the deferred expressions of the innermost \p Count scopes, newest
  /// scope first and, within a scope, last registered first. Run before the
  /// scope's locals are released, because a deferred call almost always uses
  /// one of them.
  void runDeferred(unsigned Count);
  /// Every alloca in \p F is accessed volatilely from here on. A function
  /// containing a try needs this: longjmp returns to the middle of the
  /// frame, and a value the optimiser had promoted to a register would be
  /// whatever it was when setjmp ran, not what the try body left it. It is
  /// the C rule about volatile locals, applied by the compiler instead of by
  /// the programmer.
  void makeLocalsVolatile(llvm::Function *F);
  /// Emit one __cm_popHandler for each try open around this point.
  void popOpenHandlers(unsigned Count);
  llvm::Value *emitCast(Cast *C);
  llvm::Value *emitSubstring(Substring *S);

  /// A call with no receiver: the implementation is called directly and the
  /// arguments start at parameter zero.
  llvm::Value *emitStaticCall(ClassInfo *Owner, Method *M,
                              const std::vector<Expression *> &Args, int Line);
  /// The class a dispatch's receiver names when it is a class rather than a
  /// variable, which is what makes `Math.sqrt(2.0)` a static call.
  ClassInfo *staticReceiver(Dispatch *D);
  /// Whether a call on \p RecvClass can skip the virtual table because no
  /// class in the program overrides \p MethodName below it. Only ever true
  /// when the whole program is in front of us: a separately compiled module
  /// may hold the subclass that would have overridden it.
  bool canCallDirectly(ClassInfo *RecvClass, const std::string &MethodName);

  /// \p ReceiverKnown skips the null check: it is set where the receiver is
  /// `self`, which the caller is holding for the duration of the call.
  llvm::Value *emitCall(ClassInfo *RecvClass, const std::string &MethodName,
                        llvm::Value *Receiver,
                        const std::vector<Expression *> &Args, int Line,
                        bool Virtual, const std::string &StaticClass,
                        bool ReceiverKnown = false);

  llvm::Value *makeStringLiteral(const std::string &Value);
  [[noreturn]] void fail(int Line, const std::string &Message);
};

} // namespace catmint

#endif
