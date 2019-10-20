#include "ASTSerialization.h"

#include <cassert>
#include <iostream>

#include "rapidjson/error/en.h"
#include "rapidjson/filereadstream.h"
#include "rapidjson/filewritestream.h"

using namespace catmint;

namespace keys {
const auto NodeType = "NodeType";
const auto NodeID = "NodeID";
const auto LineNumber = "LineNumber";
const auto Classes = "Classes";
const auto Name = "Name";
const auto ClassParent = "Parent";
const auto Features = "Features";
const auto Type = "Type";
const auto Initializer = "Initializer";
const auto ReturnType = "ReturnType";
const auto Body = "Body";
const auto FormalParams = "FormalParams";
const auto Value = "Value";
const auto Expressions = "Expressions";
const auto OpKind = "OperatorKind";
const auto LHS = "LeftHandSide";
const auto RHS = "RightHandSide";
const auto Operand = "Operand";
const auto Object = "Object";
const auto Start = "Start";
const auto End = "End";
const auto Arguments = "Arguments";
const auto Condition = "Condition";
const auto Then = "Then";
const auto Else = "Else";
const auto Scope = "Scope";

const auto ProgramNodeType = "Program";
const auto ClassNodeType = "Class";
const auto AttributeNodeType = "Attribute";
const auto MethodNodeType = "Method";
const auto FormalParamNodeType = "FormalParam";
const auto IntConstantNodeType = "IntegerConstant";
const auto StringConstantNodeType = "StringConstant";
const auto NullConstantNodeType = "NullConstant";
const auto BlockNodeType = "Block";
const auto AssignmentNodeType = "Assignment";
const auto BinaryOperatorNodeType = "BinaryOperator";
const auto UnaryOperatorNodeType = "UnaryOperator";
const auto CastNodeType = "Cast";
const auto SubstringNodeType = "Substring";
const auto DispatchNodeType = "Dispatch";
const auto StaticDispatchNodeType = "StaticDispatch";
const auto NewObjectNodeType = "NewObject";
const auto IfStatementNodeType = "IfStatement";
const auto WhileStatementNodeType = "WhileStatement";
const auto LocalDefinitionNodeType = "LocalDefinition";
const auto SymbolNodeType = "Symbol";
}

ASTSerializer::ASTSerializer(const std::string &filename)
    : outputFile(std::fopen(filename.c_str(), "w")) {
  if (outputFile) {
    outputStream.reset(
        new FileStream(outputFile, writeBuffer, sizeof(writeBuffer)));
    writer.reset(new Writer(*outputStream));
  } else {
    std::cerr << "Error opening output file " << filename << std::endl;
  }
}

ASTSerializer::~ASTSerializer() {
  if (outputFile) {
    if (std::fclose(outputFile)) {
      std::cerr << "Error closing output file" << std::endl;
    }
  }
}

struct ASTSerializer::CreateJSONObject {
  CreateJSONObject(ASTSerializer &S, const ASTSerializer::Writer::Ch *nodeType,
                   TreeNode *Node)
      : parent(S) {
    parent.writer->StartObject();
    parent.writePair(keys::NodeType, nodeType);
    parent.writePair(keys::NodeID, parent.newID(Node));
  }
  ~CreateJSONObject() { parent.writer->EndObject(); }

private:
  ASTSerializer &parent;
};

struct ASTSerializer::CreateJSONArray {
  CreateJSONArray(ASTSerializer &S) : parent(S) { parent.writer->StartArray(); }
  ~CreateJSONArray() { parent.writer->EndArray(); }

private:
  ASTSerializer &parent;
};

void ASTSerializer::writePair(const Writer::Ch *key, const Writer::Ch *value) {
  // TODO: check for errors
  writer->Key(key);
  writer->String(value);
}

void ASTSerializer::writePair(const Writer::Ch *key, int value) {
  writer->Key(key);
  writer->Int(value);
}

bool ASTSerializer::visit(Program *P) {
  assert(isValid() && "Invalid serializer");
  assert(P && "Expected non-null program");

  CreateJSONObject object(*this, keys::ProgramNodeType, P);
  writePair(keys::LineNumber, P->getLineNumber());

  writer->Key(keys::Classes);
  if (P->begin() == P->end()) {
    return true;
  }

  CreateJSONArray array(*this);
  return ASTVisitor::visit(P);
}

bool ASTSerializer::visit(Class *C) {
  assert(isValid() && "Invalid serializer");
  assert(C && "Expected non-null class");

  CreateJSONObject object(*this, keys::ClassNodeType, C);
  writePair(keys::LineNumber, C->getLineNumber());
  writePair(keys::Name, C->getName());

  auto parent = C->getParent();
  if (!parent.empty()) {
    writePair(keys::ClassParent, parent);
  }

  if (C->begin() == C->end()) {
    return true;
  }

  writer->Key(keys::Features);
  CreateJSONArray array(*this);

  return ASTVisitor::visit(C);
}

bool ASTSerializer::visit(Attribute *A) {
  assert(isValid() && "Invalid serializer");
  assert(A && "Expected non-null attribute");

  CreateJSONObject attrObject(*this, keys::AttributeNodeType, A);
  writePair(keys::LineNumber, A->getLineNumber());
  writePair(keys::Name, A->getName());
  writePair(keys::Type, A->getType());

  if (auto Init = A->getInit()) {
    writer->Key(keys::Initializer);
    if (!visit(Init)) {
      return false;
    }
  }

  return true;
}

bool ASTSerializer::visit(Method *M) {
  assert(isValid() && "Invalid serializer");
  assert(M && "Expected non-null method");

  CreateJSONObject methodObject(*this, "Method", M);
  writePair(keys::LineNumber, M->getLineNumber());
  writePair(keys::Name, M->getName());

  auto ret = M->getReturnType();
  if (!ret.empty()) {
    writePair(keys::ReturnType, ret);
  }

  if (auto body = M->getBody()) {
    writer->Key(keys::Body);
    if (!visit(body)) {
      return false;
    }
  }

  if (M->begin() == M->end()) {
    return true;
  }

  writer->Key(keys::FormalParams);
  CreateJSONArray paramArray(*this);
  for (auto Param : *M) {
    if (!visit(Param)) {
      return false;
    }
  }

  return true;
}

bool ASTSerializer::visit(FormalParam *F) {
  assert(isValid() && "Invalid serializer");
  assert(F && "Expected non-null formal parameter");

  CreateJSONObject object(*this, keys::FormalParamNodeType, F);
  writePair(keys::LineNumber, F->getLineNumber());
  writePair(keys::Name, F->getName());
  writePair(keys::Type, F->getType());

  return true;
}

bool ASTSerializer::visit(Expression *E) {
  assert(isValid() && "Invalid serializer");
  assert(E && "Expected non-null expression");
  return ASTVisitor::visit(E);
}

bool ASTSerializer::visit(IntConstant *IC) {
  assert(isValid() && "Invalid serializer");
  assert(IC && "Expected non-null integer constant");

  CreateJSONObject object(*this, keys::IntConstantNodeType, IC);
  writePair(keys::LineNumber, IC->getLineNumber());
  writePair(keys::Value, IC->getValue());

  return true;
}

bool ASTSerializer::visit(StringConstant *SC) {
  assert(isValid() && "Invalid serializer");
  assert(SC && "Expected non-null string constant");

  CreateJSONObject object(*this, keys::StringConstantNodeType, SC);
  writePair(keys::LineNumber, SC->getLineNumber());
  writePair(keys::Value, SC->getValue());

  return true;
}

bool ASTSerializer::visit(NullConstant *NC) {
  assert(isValid() && "Invalid serializer");
  assert(NC && "Expected non-null null constant :)");

  CreateJSONObject object(*this, keys::NullConstantNodeType, NC);
  writePair(keys::LineNumber, NC->getLineNumber());

  return true;
}

bool ASTSerializer::visit(Block *B) {
  assert(isValid() && "Invalid serializer");
  assert(B && "Expected non-null block");

  CreateJSONObject object(*this, keys::BlockNodeType, B);
  writePair(keys::LineNumber, B->getLineNumber());

  if (B->begin() == B->end()) {
    return true;
  }

  writer->Key(keys::Expressions);
  CreateJSONArray expressions(*this);
  return ASTVisitor::visit(B);
}

bool ASTSerializer::visit(Assignment *A) {
  assert(isValid() && "Invalid serializer");
  assert(A && "Expected non-null assignment");

  CreateJSONObject object(*this, keys::AssignmentNodeType, A);
  writePair(keys::LineNumber, A->getLineNumber());
  writer->Key(keys::LHS);
  auto LHS = A->getSymbol();
  assert(LHS && "Assignment does not have an expression to assign to");
  if (!visit(LHS)) {
    return false;
  }

  writer->Key(keys::RHS);
  auto RHS = A->getExpression();
  assert(RHS && "Assignment does not have an expression to assign");
  if (!visit(RHS)) {
    return false;
  }
  return true;
}

static std::string getBinOpKindSerialization(BinaryOperator::BinOpKind opKind) {
  switch (opKind) {
  case BinaryOperator::Add:
    return "+";
  case BinaryOperator::Sub:
    return "-";
  case BinaryOperator::Mul:
    return "*";
  case BinaryOperator::Div:
    return "/";
  case BinaryOperator::LessThan:
    return "<";
  case BinaryOperator::LessThanEqual:
    return "<=";
  case BinaryOperator::Equal:
    return "==";
  default:
    assert(false && "Unhandled binary operator");
  }
}

bool ASTSerializer::visit(BinaryOperator *BO) {
  assert(isValid() && "Invalid serializer");
  assert(BO && "Expected non-null binary operator");

  CreateJSONObject opObject(*this, keys::BinaryOperatorNodeType, BO);
  writePair(keys::LineNumber, BO->getLineNumber());

  std::string opKind = getBinOpKindSerialization(BO->getOperatorKind());
  writePair(keys::OpKind, opKind);

  writer->Key(keys::LHS);
  auto LHS = BO->getLHS();
  assert(LHS && "Binary operator doesn't have LHS");
  if (!visit(LHS)) {
    return false;
  }

  writer->Key(keys::RHS);
  auto RHS = BO->getRHS();
  assert(RHS && "Binary operator doesn't have RHS");
  if (!visit(RHS)) {
    return false;
  }

  return true;
}

bool ASTSerializer::visit(UnaryOperator *UO) {
  assert(isValid() && "Invalid serializer");
  assert(UO && "Expected non-null unary operator");

  CreateJSONObject opObject(*this, keys::UnaryOperatorNodeType, UO);
  writePair(keys::LineNumber, UO->getLineNumber());

  std::string opKind;
  switch (UO->getOperatorKind()) {
  case UnaryOperator::Minus:
    opKind = "-";
    break;
  case UnaryOperator::Not:
    opKind = "!";
    break;
  default:
    assert(false && "Unhandled unary operator");
  }

  writePair(keys::OpKind, opKind);

  writer->Key(keys::Operand);
  auto operand = UO->getOperand();
  assert(operand && "Unary operator doesn't have operand");
  return visit(operand);
}

bool ASTSerializer::visit(Cast *C) {
  assert(isValid() && "Invalid serializer");
  assert(C && "Expected non-null cast");

  CreateJSONObject castObject(*this, keys::CastNodeType, C);
  writePair(keys::LineNumber, C->getLineNumber());
  writePair(keys::Type, C->getType());

  writer->Key(keys::Operand);
  auto ToCast = C->getExpressionToCast();
  assert(ToCast && "Unary operator doesn't have operand");
  return visit(ToCast);
}

bool ASTSerializer::visit(Substring *S) {
  assert(isValid() && "Invalid serializer");
  assert(S && "Expected non-null substring operator");

  CreateJSONObject substringObject(*this, keys::SubstringNodeType, S);
  writePair(keys::LineNumber, S->getLineNumber());

  if (auto strObject = S->getString()) {
    writer->Key(keys::Object);
    assert(strObject && "Substring operator doesn't have string object");
    if (!visit(strObject)) {
      return false;
    }
  }

  writer->Key(keys::Start);
  auto start = S->getStart();
  assert(start && "Substring operator doesn't have start index");
  if (!visit(start)) {
    return false;
  }

  writer->Key(keys::End);
  auto end = S->getEnd();
  assert(end && "Substring operator doesn't have end index");
  if (!visit(end)) {
    return false;
  }

  return true;
}

bool ASTSerializer::visit(Dispatch *D) {
  assert(isValid() && "Invalid serializer");
  assert(D && "Expected non-null dispatch");

  CreateJSONObject dispatchObject(*this, keys::DispatchNodeType, D);
  writePair(keys::LineNumber, D->getLineNumber());
  writePair(keys::Name, D->getName());

  if (auto object = D->getObject()) {
    writer->Key(keys::Object);
    assert(object && "Dispatch doesn't have object");
    if (!visit(object)) {
      return false;
    }
  }

  if (D->begin() == D->end()) {
    return true;
  }

  writer->Key(keys::Arguments);
  CreateJSONArray arguments(*this);
  for (auto arg : *D) {
    if (!visit(arg)) {
      return false;
    }
  }

  return true;
}

bool ASTSerializer::visit(StaticDispatch *SD) {
  assert(isValid() && "Invalid serializer");
  assert(SD && "Expected non-null static dispatch");

  CreateJSONObject dispatchObject(*this, keys::StaticDispatchNodeType, SD);
  writePair(keys::LineNumber, SD->getLineNumber());
  writePair(keys::Type, SD->getType());
  writePair(keys::Name, SD->getName());

  if (auto object = SD->getObject()) {
    writer->Key(keys::Object);
    assert(object && "Static dispatch doesn't have object");
    if (!visit(object)) {
      return false;
    }
  }

  if (SD->begin() == SD->end()) {
    return true;
  }

  writer->Key(keys::Arguments);
  CreateJSONArray arguments(*this);
  for (auto arg : *SD) {
    if (!visit(arg)) {
      return false;
    }
  }

  return true;
}

bool ASTSerializer::visit(NewObject *NO) {
  assert(isValid() && "Invalid serializer");
  assert(NO && "Expected non-null new operator");

  CreateJSONObject newObject(*this, keys::NewObjectNodeType, NO);
  writePair(keys::LineNumber, NO->getLineNumber());
  writePair(keys::Type, NO->getType());
  return true;
}

bool ASTSerializer::visit(IfStatement *If) {
  assert(isValid() && "Invalid serializer");
  assert(If && "Expected non-null if statement");

  CreateJSONObject ifObject(*this, keys::IfStatementNodeType, If);
  writePair(keys::LineNumber, If->getLineNumber());

  writer->Key(keys::Condition);
  auto condExpr = If->getCond();
  assert(condExpr && "If doesn't have condition");
  if (!visit(condExpr)) {
    return false;
  }

  writer->Key(keys::Then);
  auto thenExpr = If->getThen();
  assert(thenExpr && "If doesn't have then branch");
  if (!visit(thenExpr)) {
    return false;
  }

  if (auto elseExpr = If->getElse()) {
    writer->Key(keys::Else);
    if (!visit(elseExpr)) {
      return false;
    }
  }

  return true;
}

bool ASTSerializer::visit(WhileStatement *While) {
  assert(isValid() && "Invalid serializer");
  assert(While && "Expected non-null while statement");

  CreateJSONObject whileObject(*this, keys::WhileStatementNodeType, While);
  writePair(keys::LineNumber, While->getLineNumber());

  writer->Key(keys::Condition);
  auto cond = While->getCond();
  assert(cond && "While doesn't have condition");
  if (!visit(cond)) {
    return false;
  }

  writer->Key(keys::Body);
  auto body = While->getBody();
  assert(body && "While doesn't have body");
  return visit(body);
}

bool ASTSerializer::visit(LocalDefinition *Local) {
  assert(isValid() && "Invalid serializer");
  assert(Local && "Expected non-null local definition");

  CreateJSONObject object(*this, keys::LocalDefinitionNodeType, Local);
  writePair(keys::LineNumber, Local->getLineNumber());
  writePair(keys::Name, Local->getName());
  writePair(keys::Type, Local->getType());

  if (auto Scope = Local->getScope()) {
    // TODO: assert(Scope && "Local definition doesn't have scope"); set scope
    // during syntax analysis
    writePair(keys::Scope, getID(Scope));
  }

  if (auto Init = Local->getInit()) {
    writer->Key(keys::Initializer);
    if (!visit(Init)) {
      return false;
    }
  }

  return true;
}

bool ASTSerializer::visit(Symbol *Sym) {
  assert(isValid() && "Invalid serializer");
  assert(Sym && "Expected non-null symbol");

  CreateJSONObject object(*this, keys::SymbolNodeType, Sym);
  writePair(keys::LineNumber, Sym->getLineNumber());
  writePair(keys::Name, Sym->getName());
  return true;
}

ASTDeserializer::ASTDeserializer(const std::string &filename)
    : inputFile(std::fopen(filename.c_str(), "r")) {
  if (inputFile) {
    inputStream.reset(
        new FileStream(inputFile, readBuffer, sizeof(readBuffer)));
  } else {
    std::cerr << "Error opening input file " << filename << std::endl;
  }
}

ASTDeserializer::~ASTDeserializer() {
  if (inputFile) {
    if (std::fclose(inputFile)) {
      std::cerr << "Error closing input file" << std::endl;
    }
  }
}

std::unique_ptr<Program> ASTDeserializer::getRootNode() {
  assert(isValid() && "Invalid deserializer");

  rapidjson::Document tree;
  (void)tree.ParseStream(*inputStream);

  if (tree.HasParseError()) {
    std::cerr << "Failed to parse input JSON: "
              << rapidjson::GetParseError_En(tree.GetParseError()) << std::endl;
    return nullptr;
  }

  assert(tree.IsObject() && "Expected program object");
  return parseProgram(tree);
}

void ASTDeserializer::parseID(rapidjson::Value &tree, TreeNode *node) {
  assert(tree.HasMember(keys::NodeID) && "Nodes must have ids");
  assert(tree[keys::NodeID].IsUint() && "Invalid node id");

  addNode(tree[keys::NodeID].GetUint(), node);
}

int ASTDeserializer::parseLineNumber(rapidjson::Value &tree) {
  assert(tree.HasMember(keys::LineNumber) && "Nodes must have line numbers");

  auto &lineNumberTree = tree[keys::LineNumber];
  assert(lineNumberTree.IsInt() && "Invalid line number");

  return lineNumberTree.GetInt();
}

std::unique_ptr<Program> ASTDeserializer::parseProgram(rapidjson::Value &tree) {
  assert(tree.HasMember(keys::NodeType) &&
         tree[keys::NodeType] == keys::ProgramNodeType &&
         "Expected program object");

  auto program = createNode<Program>(tree, parseLineNumber(tree));

  if (tree.HasMember(keys::Classes)) {
    auto &classes = tree[keys::Classes];
    assert(classes.IsArray() && "Classes should live in an array");
    for (auto b = classes.Begin(), e = classes.End(); b != e; ++b) {
      auto &classTree = *b;
      assert(classTree.IsObject() && "Expected class object");
      auto classNode = parseClass(classTree);
      assert(classNode && "Expected non-null class");
      program->addClass(std::move(classNode));
    }
  }

  return program;
}

std::unique_ptr<Class> ASTDeserializer::parseClass(rapidjson::Value &tree) {
  assert(tree.HasMember(keys::NodeType) &&
         tree[keys::NodeType] == keys::ClassNodeType &&
         "Expected class object");

  assert(tree.HasMember(keys::Name) && "Class without name");

  std::string parent;
  if (tree.HasMember(keys::ClassParent)) {
    assert(tree[keys::ClassParent].IsString() && "Invalid parent for class");
    parent = tree[keys::ClassParent].GetString();
  }

  auto classNode = createNode<Class>(tree, parseLineNumber(tree),
                                     tree[keys::Name].GetString(), parent);

  if (tree.HasMember(keys::Features)) {
    auto &features = tree[keys::Features];
    assert(features.IsArray() && "Features must be in an array");
    for (auto b = features.Begin(), e = features.End(); b != e; ++b) {
      auto &featureTree = *b;
      assert(featureTree.IsObject() && "Expected feature object");
      auto featureNode = parseFeature(featureTree);
      assert(featureNode && "Expected non-null feature");
      classNode->addFeature(std::move(featureNode));
    }
  }

  return classNode;
}

std::unique_ptr<Feature> ASTDeserializer::parseFeature(rapidjson::Value &tree) {
  assert(tree.HasMember(keys::NodeType) && "Expected feature object");
  if (tree[keys::NodeType] == keys::AttributeNodeType) {
    return parseAttribute(tree);
  }

  if (tree[keys::NodeType] == keys::MethodNodeType) {
    return parseMethod(tree);
  }

  assert(false && "Unknown feature type");
  return nullptr;
}

std::unique_ptr<Attribute>
ASTDeserializer::parseAttribute(rapidjson::Value &tree) {
  assert(tree.IsObject() && tree.HasMember(keys::NodeType) &&
         tree[keys::NodeType] == keys::AttributeNodeType &&
         "Expected attribute object");

  assert(tree.HasMember(keys::Name) && "Attribute without name");
  assert(tree[keys::Name].IsString() && "Invalid attribute name");

  assert(tree.HasMember(keys::Type) && "Attribute without type");
  assert(tree[keys::Type].IsString() && "Invalid attribute type");
  auto attribute = createNode<Attribute>(tree, parseLineNumber(tree),
                                         tree[keys::Name].GetString(),
                                         tree[keys::Type].GetString());

  if (tree.HasMember(keys::Initializer)) {
    auto init = parseExpression(tree[keys::Initializer]);
    assert(init && "Expected non-null initializer");
    attribute->setInit(std::move(init));
  }

  return attribute;
}

std::unique_ptr<Method> ASTDeserializer::parseMethod(rapidjson::Value &tree) {
  assert(tree.IsObject() && tree.HasMember(keys::NodeType) &&
         tree[keys::NodeType] == keys::MethodNodeType &&
         "Expected method object");

  assert(tree.HasMember(keys::Name) && "Method without name");
  assert(tree[keys::Name].IsString() && "Invalid method name");

  std::unique_ptr<Expression> body(nullptr);
  if (tree.HasMember(keys::Body)) {
    assert(tree[keys::Body].IsObject() && "Invalid method body");

    body = parseExpression(tree[keys::Body]);
    assert(body && "Expected non-null method body");
  }

  std::string returnType;
  if (tree.HasMember(keys::ReturnType)) {
    assert(tree[keys::ReturnType].IsString() && "Invalid method return type");
    returnType = tree[keys::ReturnType].GetString();
  }

  auto method = createNode<Method>(tree, parseLineNumber(tree),
                                   tree[keys::Name].GetString(), returnType,
                                   std::move(body));

  if (tree.HasMember(keys::FormalParams)) {
    auto &formalParams = tree[keys::FormalParams];
    assert(formalParams.IsArray() && "Formal params must be in an array");
    for (auto b = formalParams.Begin(), e = formalParams.End(); b != e; ++b) {
      auto &formalParamTree = *b;
      assert(formalParamTree.IsObject() && "Expected formal param object");
      auto formalParamNode = parseFormalParam(formalParamTree);
      assert(formalParamNode && "Expected non-null formal param");
      method->addParameter(std::move(formalParamNode));
    }
  }

  return method;
}

std::unique_ptr<FormalParam>
ASTDeserializer::parseFormalParam(rapidjson::Value &tree) {
  assert(tree.IsObject() && tree.HasMember(keys::NodeType) &&
         tree[keys::NodeType] == keys::FormalParamNodeType &&
         "Expected formal param object");

  assert(tree.HasMember(keys::Name) && "Formal param without name");
  assert(tree[keys::Name].IsString() && "Invalid formal param name");

  assert(tree.HasMember(keys::Type) && "Formal param without type");
  assert(tree[keys::Type].IsString() && "Invalid formal param type");

  return createNode<FormalParam>(tree, parseLineNumber(tree),
                                 tree[keys::Name].GetString(),
                                 tree[keys::Type].GetString());
}

std::unique_ptr<Expression>
ASTDeserializer::parseExpression(rapidjson::Value &tree) {
  assert(tree.IsObject() && tree.HasMember(keys::NodeType) &&
         "Expected expression object");

  auto &nodeType = tree[keys::NodeType];
  if (nodeType == keys::IntConstantNodeType) {
    return parseIntConstant(tree);
  } else if (nodeType == keys::StringConstantNodeType) {
    return parseStringConstant(tree);
  } else if (nodeType == keys::NullConstantNodeType) {
    return parseNullConstant(tree);
  } else if (nodeType == keys::SymbolNodeType) {
    return parseSymbol(tree);
  } else if (nodeType == keys::BlockNodeType) {
    return parseBlock(tree);
  } else if (nodeType == keys::BinaryOperatorNodeType) {
    return parseBinOp(tree);
  } else if (nodeType == keys::UnaryOperatorNodeType) {
    return parseUnaryOp(tree);
  } else if (nodeType == keys::CastNodeType) {
    return parseCast(tree);
  } else if (nodeType == keys::SubstringNodeType) {
    return parseSubstring(tree);
  } else if (nodeType == keys::DispatchNodeType) {
    return parseDispatch(tree);
  } else if (nodeType == keys::StaticDispatchNodeType) {
    return parseStaticDispatch(tree);
  } else if (nodeType == keys::NewObjectNodeType) {
    return parseNewObject(tree);
  } else if (nodeType == keys::IfStatementNodeType) {
    return parseIfStatement(tree);
  } else if (nodeType == keys::WhileStatementNodeType) {
    return parseWhileStatement(tree);
  } else if (nodeType == keys::LocalDefinitionNodeType) {
    return parseLocalDefinition(tree);
  } else if (nodeType == keys::AssignmentNodeType) {
    return parseAssignment(tree);
  }

  assert(false && "Unknown expression kind");
  return nullptr;
}

std::unique_ptr<Assignment>
ASTDeserializer::parseAssignment(rapidjson::Value &tree) {
  assert(tree.IsObject() && tree.HasMember(keys::NodeType) &&
         tree[keys::NodeType] == keys::AssignmentNodeType &&
         "Expected assignment object");

  assert(tree.HasMember(keys::LHS) && "Assignment without LHS");
  assert(tree[keys::LHS].IsString() && "Invalid LHS for assignment");

  assert(tree.HasMember(keys::RHS) && "Assignment without RHS");
  assert(tree[keys::RHS].IsObject() && "Invalid RHS for assignment");

  auto RHS = parseExpression(tree[keys::RHS]);
  assert(RHS && "Expected non-null expression node");

  return createNode<Assignment>(tree, parseLineNumber(tree),
                                tree[keys::LHS].GetString(), std::move(RHS));
}

std::unique_ptr<IntConstant>
ASTDeserializer::parseIntConstant(rapidjson::Value &tree) {
  assert(tree.IsObject() && tree.HasMember(keys::NodeType) &&
         tree[keys::NodeType] == keys::IntConstantNodeType &&
         "Expected int constant object");

  assert(tree.HasMember(keys::Value) && "Int constant without value");
  assert(tree[keys::Value].IsInt() && "Invalid value for int constant");
  // TODO: figure out about unsigned etc

  return createNode<IntConstant>(tree, parseLineNumber(tree),
                                 tree[keys::Value].GetInt());
}

std::unique_ptr<StringConstant>
ASTDeserializer::parseStringConstant(rapidjson::Value &tree) {
  assert(tree.IsObject() && tree.HasMember(keys::NodeType) &&
         tree[keys::NodeType] == keys::StringConstantNodeType &&
         "Expected string constant object");

  assert(tree.HasMember(keys::Value) && "String constant without value");
  assert(tree[keys::Value].IsString() && "Invalid value for string constant");

  return createNode<StringConstant>(tree, parseLineNumber(tree),
                                    tree[keys::Value].GetString());
}

std::unique_ptr<NullConstant>
ASTDeserializer::parseNullConstant(rapidjson::Value &tree) {
  assert(tree.IsObject() && tree.HasMember(keys::NodeType) &&
         tree[keys::NodeType] == keys::NullConstantNodeType &&
         "Expected null constant object");
  return createNode<NullConstant>(tree, parseLineNumber(tree));
}

std::unique_ptr<Symbol> ASTDeserializer::parseSymbol(rapidjson::Value &tree) {
  assert(tree.IsObject() && tree.HasMember(keys::NodeType) &&
         tree[keys::NodeType] == keys::SymbolNodeType &&
         "Expected symbol object");

  assert(tree.HasMember(keys::Name) && "Symbol without name");
  assert(tree[keys::Name].IsString() && "Invalid symbol name");

  return createNode<Symbol>(tree, parseLineNumber(tree),
                            tree[keys::Name].GetString());
}

std::unique_ptr<Block> ASTDeserializer::parseBlock(rapidjson::Value &tree) {
  assert(tree.IsObject() && tree.HasMember(keys::NodeType) &&
         tree[keys::NodeType] == keys::BlockNodeType &&
         "Expected block object");

  auto block = createNode<Block>(tree, parseLineNumber(tree));

  if (tree.HasMember(keys::Expressions)) {
    assert(tree[keys::Expressions].IsArray() && "Expressions not in array");

    auto &expressions = tree[keys::Expressions];
    for (auto b = expressions.Begin(), e = expressions.End(); b != e; ++b) {
      auto &expressionTree = *b;
      assert(expressionTree.IsObject() && "Expected expression object");
      auto expressionNode = parseExpression(expressionTree);
      assert(expressionNode && "Expected non-null expression node");
      block->addExpression(std::move(expressionNode));
    }
  }

  return block;
}

static BinaryOperator::BinOpKind getBinOpKind(rapidjson::Value &tree) {
  assert(tree.HasMember(keys::OpKind) && "Binary operator without op kind");

  auto &opKind = tree[keys::OpKind];
  assert(opKind.IsString() && "Invalid binary op kind");

  if (opKind == "+") {
    return BinaryOperator::Add;
  } else if (opKind == "-") {
    return BinaryOperator::Sub;
  } else if (opKind == "*") {
    return BinaryOperator::Mul;
  } else if (opKind == "/") {
    return BinaryOperator::Div;
  } else if (opKind == "<") {
    return BinaryOperator::LessThan;
  } else if (opKind == "<=") {
    return BinaryOperator::LessThanEqual;
  } else if (opKind == "==") {
    return BinaryOperator::Equal;
  }

  assert(false && "Unknown binary operator kind");
  return BinaryOperator::Invalid;
}

std::unique_ptr<BinaryOperator>
ASTDeserializer::parseBinOp(rapidjson::Value &tree) {
  assert(tree.IsObject() && tree.HasMember(keys::NodeType) &&
         tree[keys::NodeType] == keys::BinaryOperatorNodeType &&
         "Expected binary operator object");

  assert(tree.HasMember(keys::LHS) && "Binary operator without LHS");
  assert(tree[keys::LHS].IsObject() && "Invalid LHS for binary operator");

  auto LHS = parseExpression(tree[keys::LHS]);
  assert(LHS && "Expected non-null expression node");

  assert(tree.HasMember(keys::RHS) && "Binary operator without RHS");
  assert(tree[keys::RHS].IsObject() && "Invalid RHS for binary operator");

  auto RHS = parseExpression(tree[keys::RHS]);
  assert(RHS && "Expected non-null expression node");

  return createNode<BinaryOperator>(tree, parseLineNumber(tree),
                                    getBinOpKind(tree), std::move(LHS),
                                    std::move(RHS));
}

static UnaryOperator::UnaryOpKind getOpKind(rapidjson::Value &tree) {
  assert(tree.HasMember(keys::OpKind) && "Unary operator without op kind");
  assert(tree[keys::OpKind].IsString() && "Invalid op kind for unary operator");

  auto &opKind = tree[keys::OpKind];
  if (opKind == "-") {
    return UnaryOperator::Minus;
  }

  if (opKind == "!") {
    return UnaryOperator::Not;
  }

  assert(false && "Unknown unary operator kind");
  return UnaryOperator::Invalid;
}

std::unique_ptr<UnaryOperator>
ASTDeserializer::parseUnaryOp(rapidjson::Value &tree) {
  assert(tree.IsObject() && tree.HasMember(keys::NodeType) &&
         tree[keys::NodeType] == keys::UnaryOperatorNodeType &&
         "Expected unary operator object");

  assert(tree.HasMember(keys::Operand) && "Unary operator without operand");
  assert(tree[keys::Operand].IsObject() &&
         "Invalid operand for unary operator");

  auto operand = parseExpression(tree[keys::Operand]);
  assert(operand && "Expected non-null expression node");

  return createNode<UnaryOperator>(tree, parseLineNumber(tree), getOpKind(tree),
                                   std::move(operand));
}

std::unique_ptr<Cast> ASTDeserializer::parseCast(rapidjson::Value &tree) {
  assert(tree.IsObject() && tree.HasMember(keys::NodeType) &&
         tree[keys::NodeType] == keys::CastNodeType && "Expected cast object");

  assert(tree.HasMember(keys::Type) && "Cast without type");
  assert(tree[keys::Type].IsString() && "Invalid type for cast");

  auto type = tree[keys::Type].GetString();

  assert(tree.HasMember(keys::Operand) && "Cast without operand");
  assert(tree[keys::Operand].IsObject() && "Invalid operand for cast");

  auto operand = parseExpression(tree[keys::Operand]);
  assert(operand && "Expected non-null expression node");

  return createNode<Cast>(tree, parseLineNumber(tree), type,
                          std::move(operand));
}

std::unique_ptr<Substring>
ASTDeserializer::parseSubstring(rapidjson::Value &tree) {
  assert(tree.IsObject() && tree.HasMember(keys::NodeType) &&
         tree[keys::NodeType] == keys::SubstringNodeType &&
         "Expected substring object");

  std::unique_ptr<Expression> stringObject = nullptr;
  if (tree.HasMember(keys::Object)) {
    assert(tree[keys::Object].IsObject() &&
           "Invalid string object for substring");

    stringObject = parseExpression(tree[keys::Object]);
    assert(stringObject && "Expected non-null expression node");
  }

  assert(tree.HasMember(keys::Start) && "Substring without start");
  assert(tree[keys::Start].IsObject() && "Invalid start for substring");

  auto start = parseExpression(tree[keys::Start]);
  assert(start && "Expected non-null expression node");

  assert(tree.HasMember(keys::End) && "Substring without end");
  assert(tree[keys::End].IsObject() && "Invalid end for substring");

  auto end = parseExpression(tree[keys::End]);
  assert(end && "Expected non-null expression node");

  return createNode<Substring>(tree, parseLineNumber(tree),
                               std::move(stringObject), std::move(start),
                               std::move(end));
}

std::unique_ptr<Dispatch>
ASTDeserializer::parseDispatch(rapidjson::Value &tree) {
  assert(tree.IsObject() && tree.HasMember(keys::NodeType) &&
         tree[keys::NodeType] == keys::DispatchNodeType &&
         "Expected dispatch object");

  std::unique_ptr<Expression> object(nullptr);
  if (tree.HasMember(keys::Object)) {
    assert(tree[keys::Object].IsObject() && "Invalid object for dispatch");

    object = parseExpression(tree[keys::Object]);
    assert(object && "Expected non-null expression node");
  }

  assert(tree.HasMember(keys::Name) && "Dispatch without name");
  assert(tree[keys::Name].IsString() && "Invalid name for dispatch");

  auto dispatch =
      createNode<Dispatch>(tree, parseLineNumber(tree),
                           tree[keys::Name].GetString(), std::move(object));

  if (tree.HasMember(keys::Arguments)) {
    assert(tree[keys::Arguments].IsArray() && "Arguments not in array");

    auto &args = tree[keys::Arguments];
    for (auto b = args.Begin(), e = args.End(); b != e; ++b) {
      auto &argTree = *b;
      assert(argTree.IsObject() && "Expected argument object");
      auto argNode = parseExpression(argTree);
      assert(argNode && "Expected non-null expression node");
      dispatch->addArgument(std::move(argNode));
    }
  }

  return dispatch;
}

std::unique_ptr<StaticDispatch>
ASTDeserializer::parseStaticDispatch(rapidjson::Value &tree) {
  assert(tree.IsObject() && tree.HasMember(keys::NodeType) &&
         tree[keys::NodeType] == keys::StaticDispatchNodeType &&
         "Expected static dispatch object");

  std::unique_ptr<Expression> object(nullptr);
  if (tree.HasMember(keys::Object)) {
    assert(tree[keys::Object].IsObject() &&
           "Invalid object for static dispatch");

    object = parseExpression(tree[keys::Object]);
    assert(object && "Expected non-null expression node");
  }

  assert(tree.HasMember(keys::Name) && "Staic dispatch without name");
  assert(tree[keys::Name].IsString() && "Invalid name for static dispatch");

  assert(tree.HasMember(keys::Type) && "Static dispatch without type");
  assert(tree[keys::Type].IsString() && "Invalid type for static dispatch");

  auto dispatch = createNode<StaticDispatch>(
      tree, parseLineNumber(tree), std::move(object),
      tree[keys::Type].GetString(), tree[keys::Name].GetString());

  if (tree.HasMember(keys::Arguments)) {
    assert(tree[keys::Arguments].IsArray() && "Arguments not in array");

    auto &args = tree[keys::Arguments];
    for (auto b = args.Begin(), e = args.End(); b != e; ++b) {
      auto &argTree = *b;
      assert(argTree.IsObject() && "Expected argument object");
      auto argNode = parseExpression(argTree);
      assert(argNode && "Expected non-null expression node");
      dispatch->addArgument(std::move(argNode));
    }
  }

  return dispatch;
}

std::unique_ptr<NewObject>
ASTDeserializer::parseNewObject(rapidjson::Value &tree) {
  assert(tree.IsObject() && tree.HasMember(keys::NodeType) &&
         tree[keys::NodeType] == keys::NewObjectNodeType &&
         "Expected new operator object");

  assert(tree.HasMember(keys::Type) && "New operator without type");
  assert(tree[keys::Type].IsString() && "Invalid type for new operator");

  return createNode<NewObject>(tree, parseLineNumber(tree),
                               tree[keys::Type].GetString());
}

std::unique_ptr<IfStatement>
ASTDeserializer::parseIfStatement(rapidjson::Value &tree) {
  assert(tree.IsObject() && tree.HasMember(keys::NodeType) &&
         tree[keys::NodeType] == keys::IfStatementNodeType &&
         "Expected if statement object");

  assert(tree.HasMember(keys::Condition) && "If statement without condition");
  assert(tree[keys::Condition].IsObject() &&
         "Invalid condition for if statement");

  auto cond = parseExpression(tree[keys::Condition]);
  assert(cond && "Expected non-null expression node");

  assert(tree.HasMember(keys::Then) && "If statement without then branch");
  assert(tree[keys::Then].IsObject() && "Invalid then branch for if statement");

  auto then = parseExpression(tree[keys::Then]);
  assert(then && "Expected non-null expression node");

  std::unique_ptr<Expression> elseOrNull(nullptr);
  if (tree.HasMember(keys::Else)) {
    assert(tree[keys::Else].IsObject() &&
           "Invalid else branch for if statement");

    elseOrNull = parseExpression(tree[keys::Else]);
    assert(elseOrNull && "Expected non-null expression node");
  }

  return createNode<IfStatement>(tree, parseLineNumber(tree), std::move(cond),
                                 std::move(then), std::move(elseOrNull));
}

std::unique_ptr<WhileStatement>
ASTDeserializer::parseWhileStatement(rapidjson::Value &tree) {
  assert(tree.IsObject() && tree.HasMember(keys::NodeType) &&
         tree[keys::NodeType] == keys::WhileStatementNodeType &&
         "Expected while statement object");

  assert(tree.HasMember(keys::Condition) &&
         "While statement without condition");
  assert(tree[keys::Condition].IsObject() &&
         "Invalid condition for while statement");

  auto cond = parseExpression(tree[keys::Condition]);
  assert(cond && "Expected non-null expression node");

  assert(tree.HasMember(keys::Body) && "While statement without body");
  assert(tree[keys::Body].IsObject() && "Invalid body for while statement");

  auto body = parseExpression(tree[keys::Body]);
  assert(body && "Expected non-null expression node");

  return createNode<WhileStatement>(tree, parseLineNumber(tree),
                                    std::move(cond), std::move(body));
}

std::unique_ptr<LocalDefinition>
ASTDeserializer::parseLocalDefinition(rapidjson::Value &tree) {
  assert(tree.IsObject() && tree.HasMember(keys::NodeType) &&
         tree[keys::NodeType] == keys::LocalDefinitionNodeType &&
         "Expected while statement object");

  assert(tree.HasMember(keys::Name) && "Local definition without name");
  assert(tree[keys::Name].IsString() && "Invalid name for local definition");

  assert(tree.HasMember(keys::Type) && "Local definition without type");
  assert(tree[keys::Type].IsString() && "Invalid type for local definition");

  auto localDef = createNode<LocalDefinition>(tree, parseLineNumber(tree),
                                              tree[keys::Name].GetString(),
                                              tree[keys::Type].GetString());

  // TODO: handle scope
  //  assert(tree.HasMember(keys::Scope) && "Local definition without
  //  scope");
  //  assert(tree[keys::Scope].IsInt() && "Invalid scope for local
  //  definition");

  //  auto scopeNode = getNode(tree[keys::Scope].GetInt());
  //  assert(scopeNode && "Unknown scope");
  //
  //  localDef->setScope(dynamic_cast<Expression *>(scopeNode));

  if (tree.HasMember(keys::Initializer)) {
    assert(tree[keys::Initializer].IsObject() &&
           "Invalid initializer for local definition");

    auto init = parseExpression(tree[keys::Initializer]);
    assert(init && "Expected non-null expression");

    localDef->setInit(std::move(init));
  }

  return localDef;
}
