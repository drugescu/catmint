
#ifndef INCLUDE_STRINGCONSTANTS_H_
#define INCLUDE_STRINGCONSTANTS_H_

namespace catmint {

namespace strings {
const auto Null = "Null";
const auto Void = "Void";
const auto Int = "Int";
// The sized integer types. Int32 is another spelling of Int and is folded
// into it by the parser, so only these three names ever reach the generator
// alongside Int.
const auto Int8 = "Int8";
const auto Int16 = "Int16";
const auto Int32 = "Int32";
const auto Int64 = "Int64";
// Float is the 64-bit double; Float64 is another spelling of it, folded into
// it by the parser as Int32 is into Int. Float32 is the one extra name that
// reaches the generator.
const auto Float = "Float";
const auto Float32 = "Float32";

const auto Self = "self";
const auto MainClass = "Main";
const auto MainMethod = "main";
// A constructor is a method under this name, so `new T(a, b)` is a call and
// needs no separate machinery in the type table or the vtable.
const auto Init = "init";

const auto Object = "Object";
const auto Abort = "abort";
const auto TypeName = "type";
const auto Copy = "copy";

const auto String = "String";
const auto Length = "len";
const auto ToInt = "toInt";

const auto Io = "IO";
const auto Message = "message";
const auto Out = "out";
const auto In = "input";
const auto ReadLine = "readLine";
const auto Eof = "eof";
const auto Entropy = "entropy";
const auto Ticks = "ticks";
const auto Epoch = "epoch";
const auto LocalOffset = "localOffset";
const auto Sleep = "sleep";
const auto List = "List";
const auto File = "File";
const auto Math = "Math";
const auto Process = "Process";
const auto Worker = "Worker";
const auto Handles = "Handles";
const auto Bytes = "Bytes";
/// An opaque machine pointer: what a C function hands back and takes again.
/// A value, not an object -- no run-time type information, no reference
/// count, nothing for the memory machinery to see.
const auto Ptr = "Ptr";
/// The method a class may write to say what happens when its last reference
/// goes. Named in the run-time type information rather than given a virtual
/// table slot, so adding it renumbered nothing.
const auto Finalize = "finalize";
const auto Ints = "Ints";
const auto Floats = "Floats";
const auto Fill = "fill";
const auto Integer = "Integer";
const auto Get = "get";
const auto GetLong = "getLong";
const auto Set = "set";
const auto Append = "append";
const auto Slice = "slice";
const auto Substr = "substr";
const auto Concat = "concat";
const auto Equals = "equals";
const auto At = "at";

const auto Symbol = "Symbol";
const auto ComplexType = "ComplexType";
const auto Unknown = "Unknown";
}
}

#endif /* INCLUDE_STRINGCONSTANTS_H_ */
