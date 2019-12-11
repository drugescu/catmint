#ifndef ASTSERIALIZATION_H
#define ASTSERIALIZATION_H

#include <memory>
#include <string>
#include <unordered_map>

#include "ASTVisitor.h"

#include "rapidjson/document.h"
#include "rapidjson/prettywriter.h"

namespace rapidjson {
class FileReadStream;
class FileWriteStream;
}

namespace catmint {
/// \brief Serialize the catmint AST as JSON
class ASTSerializer : public ASTVisitor {
public:
  /// \brief Create an ASTSerializer that will write to \p filename
  explicit ASTSerializer(const std::string &filename);
  ~ASTSerializer();

  /// \brief Check if the serializer is valid
  ///
  /// A serializer may be invalid if it couldn't open the output file. You
  /// should not invoke any of the \c visit methods on an invalid serializer.
  bool isValid() const { return outputFile != nullptr; }

  /// @{
  /// \brief Methods for writing the AST
  ///
  /// Each method will write the entire subtree corresponding to the given node.
  /// For example, visiting a BinaryOperator will serialize the operator itself
  /// and recursively both of its operands.
  bool visit(Program *P) override;
  bool visit(Class *C) override;
  bool visit(Attribute *F) override;
  bool visit(Method *M) override;
  bool visit(FormalParam *F) override;

  bool visit(Expression *E) override;

  bool visit(IntConstant *IC) override;
  bool visit(FloatConstant *IF) override;
  bool visit(StringConstant *SC) override;
  bool visit(NullConstant *NC) override;
  bool visit(Symbol *Sym) override;

  bool visit(Block *B) override;
  bool visit(Assignment *A) override;
  bool visit(BinaryOperator *BO) override;
  bool visit(UnaryOperator *UO) override;
  bool visit(Cast *C) override;
  bool visit(Substring *S) override;
  bool visit(Slicevector *S) override;
  bool visit(Dispatch *D) override;
  bool visit(StaticDispatch *SD) override;
  bool visit(NewObject *NO) override;
  bool visit(IfStatement *If) override;
  bool visit(WhileStatement *While) override;
  bool visit(ForStatement *For) override; // Pay attention here, new one
  bool visit(LocalDefinition *Local) override; // Also here, changed
  /// @}

private:
  /// @{
  /// \brief Support for giving each node a unique ID
  typedef unsigned int ID;

  ID id = 0;
  ID newID(TreeNode *Node) {
    idMap[Node] = id;
    return id++;
  }

  std::unordered_map<TreeNode *, ID> idMap;

  ID getID(TreeNode *Node) { return idMap[Node]; }
  /// @}

  typedef rapidjson::FileWriteStream FileStream;
  typedef rapidjson::PrettyWriter<FileStream> Writer;

  char writeBuffer[65536];
  std::FILE *outputFile;
  std::unique_ptr<FileStream> outputStream;
  std::unique_ptr<Writer> writer;

  /// @{
  /// \brief Helper classes for creating a JSON object or array
  ///
  /// These helpers will start the object/array when they are constructed and
  /// finish it when they go out of scope (by the same RAII mechanism commonly
  /// used for smart pointers, mutexes etc). The idea is to make sure that we
  /// always finish our object/array.
  struct CreateJSONObject;
  struct CreateJSONArray;
  /// @}

  void writePair(const Writer::Ch *key, const std::string &value) {
    writePair(key, value.c_str());
  }

  void writePair(const Writer::Ch *key, const Writer::Ch *value);
  void writePair(const Writer::Ch *key, int value);
  void writePair(const Writer::Ch *key, double value);
};

/// \brief Deserialize an AST from a JSON file
class ASTDeserializer {
  typedef rapidjson::FileReadStream FileStream;

public:
  /// \brief Create a deserializer object that reads from \p filename
  explicit ASTDeserializer(const std::string &filename);
  ~ASTDeserializer();

  /// \brief Check if the deserializer is valid
  ///
  /// A deserializer may be invalid if it couldn't open the output file. You
  /// should not invoke \c getRootNode on an invalid deserializer.
  bool isValid() { return inputFile != nullptr; }

  /// \brief Get the deserialized program
  std::unique_ptr<Program> getRootNode();

private:
  char readBuffer[65536];
  std::FILE *inputFile;
  std::unique_ptr<FileStream> inputStream;

  /// @{
  /// \brief Support for unique node IDs
  /// TODO: share this stuff with the serializer
  typedef unsigned int ID;

  std::unordered_map<ID, TreeNode *> idMap;

  void addNode(ID id, TreeNode *node) { idMap[id] = node; }
  TreeNode *getNode(ID id) { return idMap[id]; }
  /// @}

  /// \brief Parse the ID of a given node
  /// \param tree The JSON object
  /// \param node The AST node that we're parsing the ID for
  ///
  /// We need the AST node in order to keep track of the ID-to-node mapping.
  void parseID(rapidjson::Value &tree, TreeNode *node);
  int parseLineNumber(rapidjson::Value &tree);

  /// \brief Template for creating any given AST node
  ///
  /// It makes sure we don't forget to parse a node's ID.
  template <typename NodeT, typename... Args>
  std::unique_ptr<NodeT> createNode(rapidjson::Value &tree, Args... args) {
    std::unique_ptr<NodeT> node(new NodeT(std::forward<Args>(args)...));
    parseID(tree, node.get());
    return node;
  }

  /// @{
  /// \brief Helpers for parsing AST nodes
  std::unique_ptr<Program> parseProgram(rapidjson::Value &tree);
  std::unique_ptr<Class> parseClass(rapidjson::Value &tree);
  std::unique_ptr<Feature> parseFeature(rapidjson::Value &tree);
  std::unique_ptr<Attribute> parseAttribute(rapidjson::Value &tree);
  std::unique_ptr<Method> parseMethod(rapidjson::Value &tree);
  std::unique_ptr<FormalParam> parseFormalParam(rapidjson::Value &tree);

  std::unique_ptr<Expression> parseExpression(rapidjson::Value &tree);
  std::unique_ptr<IntConstant> parseIntConstant(rapidjson::Value &tree);
  std::unique_ptr<FloatConstant> parseFloatConstant(rapidjson::Value &tree);
  std::unique_ptr<StringConstant> parseStringConstant(rapidjson::Value &tree);
  std::unique_ptr<NullConstant> parseNullConstant(rapidjson::Value &tree);
  std::unique_ptr<Symbol> parseSymbol(rapidjson::Value &tree);
  std::unique_ptr<Block> parseBlock(rapidjson::Value &tree);
  std::unique_ptr<BinaryOperator> parseBinOp(rapidjson::Value &tree);
  std::unique_ptr<UnaryOperator> parseUnaryOp(rapidjson::Value &tree);
  std::unique_ptr<Cast> parseCast(rapidjson::Value &tree);
  std::unique_ptr<Substring> parseSubstring(rapidjson::Value &tree);
  std::unique_ptr<Slicevector> parseSlicevector(rapidjson::Value &tree);
  std::unique_ptr<Dispatch> parseDispatch(rapidjson::Value &tree);
  std::unique_ptr<StaticDispatch> parseStaticDispatch(rapidjson::Value &tree);
  std::unique_ptr<NewObject> parseNewObject(rapidjson::Value &tree);
  std::unique_ptr<IfStatement> parseIfStatement(rapidjson::Value &tree);
  std::unique_ptr<WhileStatement> parseWhileStatement(rapidjson::Value &tree);
  std::unique_ptr<ForStatement> parseForStatement(rapidjson::Value &tree); // Pay attention here in deserialization
  std::unique_ptr<LocalDefinition> parseLocalDefinition(rapidjson::Value &tree); // Also changed, pay attention
  std::unique_ptr<Assignment> parseAssignment(rapidjson::Value &tree);
  /// @}
};
} /* namespace catmint */
#endif /* ASTSERIALIZATION_H */
