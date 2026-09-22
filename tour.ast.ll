; ModuleID = 'tour.ast'
source_filename = "tour.ast"

%struct.__catmint_rtti = type { ptr, i32, ptr, [0 x ptr] }
%struct.TString = type { ptr, i32, ptr }

@RObject = external global %struct.__catmint_rtti
@RString = external global %struct.__catmint_rtti
@RIO = external global %struct.__catmint_rtti
@.name.Animal = private unnamed_addr constant [7 x i8] c"Animal\00", align 1
@NAnimal = global %struct.TString { ptr @RString, i32 6, ptr @.name.Animal }
@RAnimal = global { ptr, i32, ptr, [7 x ptr] } { ptr @NAnimal, i32 8, ptr @RIO, [7 x ptr] [ptr @M6_Object_abort, ptr @M6_Object_typeName, ptr @M6_Object_copy, ptr @M2_IO_in, ptr @M2_IO_out, ptr @M6_Animal_speak, ptr @M6_Animal_introduce] }
@.name.Cat = private unnamed_addr constant [4 x i8] c"Cat\00", align 1
@NCat = global %struct.TString { ptr @RString, i32 3, ptr @.name.Cat }
@RCat = global { ptr, i32, ptr, [7 x ptr] } { ptr @NCat, i32 8, ptr @RAnimal, [7 x ptr] [ptr @M6_Object_abort, ptr @M6_Object_typeName, ptr @M6_Object_copy, ptr @M2_IO_in, ptr @M2_IO_out, ptr @M3_Cat_speak, ptr @M6_Animal_introduce] }
@.name.Dog = private unnamed_addr constant [4 x i8] c"Dog\00", align 1
@NDog = global %struct.TString { ptr @RString, i32 3, ptr @.name.Dog }
@RDog = global { ptr, i32, ptr, [7 x ptr] } { ptr @NDog, i32 8, ptr @RAnimal, [7 x ptr] [ptr @M6_Object_abort, ptr @M6_Object_typeName, ptr @M6_Object_copy, ptr @M2_IO_in, ptr @M2_IO_out, ptr @M3_Dog_speak, ptr @M6_Animal_introduce] }
@.name.Main = private unnamed_addr constant [5 x i8] c"Main\00", align 1
@NMain = global %struct.TString { ptr @RString, i32 4, ptr @.name.Main }
@RMain = global { ptr, i32, ptr, [7 x ptr] } { ptr @NMain, i32 8, ptr @RIO, [7 x ptr] [ptr @M6_Object_abort, ptr @M6_Object_typeName, ptr @M6_Object_copy, ptr @M2_IO_in, ptr @M2_IO_out, ptr @M4_Main_fib, ptr @M4_Main_main] }
@.str = private unnamed_addr constant [4 x i8] c"...\00", align 1
@.strobj = private global %struct.TString { ptr @RString, i32 3, ptr @.str }
@.str.1 = private unnamed_addr constant [7 x i8] c" says \00", align 1
@.strobj.2 = private global %struct.TString { ptr @RString, i32 6, ptr @.str.1 }
@.str.3 = private unnamed_addr constant [2 x i8] c"\0A\00", align 1
@.strobj.4 = private global %struct.TString { ptr @RString, i32 1, ptr @.str.3 }
@.str.5 = private unnamed_addr constant [5 x i8] c"meow\00", align 1
@.strobj.6 = private global %struct.TString { ptr @RString, i32 4, ptr @.str.5 }
@.str.7 = private unnamed_addr constant [5 x i8] c"woof\00", align 1
@.strobj.8 = private global %struct.TString { ptr @RString, i32 4, ptr @.str.7 }
@.str.9 = private unnamed_addr constant [11 x i8] c"fib(10) = \00", align 1
@.strobj.10 = private global %struct.TString { ptr @RString, i32 10, ptr @.str.9 }
@.str.11 = private unnamed_addr constant [2 x i8] c"\0A\00", align 1
@.strobj.12 = private global %struct.TString { ptr @RString, i32 1, ptr @.str.11 }
@.str.13 = private unnamed_addr constant [23 x i8] c"sum of squares 1..4 = \00", align 1
@.strobj.14 = private global %struct.TString { ptr @RString, i32 22, ptr @.str.13 }
@.str.15 = private unnamed_addr constant [2 x i8] c"\0A\00", align 1
@.strobj.16 = private global %struct.TString { ptr @RString, i32 1, ptr @.str.15 }

declare ptr @__catmint_new(ptr)

declare ptr @__lcpl_intToString(i32)

declare void @__lcpl_checkNull(ptr)

declare ptr @__lcpl_cast(ptr, ptr)

declare ptr @M6_String_substring(ptr, i32, i32)

declare ptr @M6_String_concat(ptr, ptr)

declare i32 @M6_String_equal(ptr, ptr)

define ptr @M6_Animal_speak(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  ret ptr @.strobj
}

define void @M6_Animal_introduce(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %self.val = load ptr, ptr %self, align 8
  %self.val1 = load ptr, ptr %self, align 8
  call void @__lcpl_checkNull(ptr %self.val1)
  %rtti = load ptr, ptr %self.val1, align 8
  %type.slot = getelementptr %struct.__catmint_rtti, ptr %rtti, i32 0, i32 3, i32 1
  %type.fn = load ptr, ptr %type.slot, align 8
  %1 = call ptr %type.fn(ptr %self.val1)
  call void @__lcpl_checkNull(ptr %self.val)
  %rtti2 = load ptr, ptr %self.val, align 8
  %out.slot = getelementptr %struct.__catmint_rtti, ptr %rtti2, i32 0, i32 3, i32 4
  %out.fn = load ptr, ptr %out.slot, align 8
  %2 = call ptr %out.fn(ptr %self.val, ptr %1)
  %self.val3 = load ptr, ptr %self, align 8
  call void @__lcpl_checkNull(ptr %self.val3)
  %rtti4 = load ptr, ptr %self.val3, align 8
  %out.slot5 = getelementptr %struct.__catmint_rtti, ptr %rtti4, i32 0, i32 3, i32 4
  %out.fn6 = load ptr, ptr %out.slot5, align 8
  %3 = call ptr %out.fn6(ptr %self.val3, ptr @.strobj.2)
  %self.val7 = load ptr, ptr %self, align 8
  %self.val8 = load ptr, ptr %self, align 8
  call void @__lcpl_checkNull(ptr %self.val8)
  %rtti9 = load ptr, ptr %self.val8, align 8
  %speak.slot = getelementptr %struct.__catmint_rtti, ptr %rtti9, i32 0, i32 3, i32 5
  %speak.fn = load ptr, ptr %speak.slot, align 8
  %4 = call ptr %speak.fn(ptr %self.val8)
  call void @__lcpl_checkNull(ptr %self.val7)
  %rtti10 = load ptr, ptr %self.val7, align 8
  %out.slot11 = getelementptr %struct.__catmint_rtti, ptr %rtti10, i32 0, i32 3, i32 4
  %out.fn12 = load ptr, ptr %out.slot11, align 8
  %5 = call ptr %out.fn12(ptr %self.val7, ptr %4)
  %self.val13 = load ptr, ptr %self, align 8
  call void @__lcpl_checkNull(ptr %self.val13)
  %rtti14 = load ptr, ptr %self.val13, align 8
  %out.slot15 = getelementptr %struct.__catmint_rtti, ptr %rtti14, i32 0, i32 3, i32 4
  %out.fn16 = load ptr, ptr %out.slot15, align 8
  %6 = call ptr %out.fn16(ptr %self.val13, ptr @.strobj.4)
  ret void
}

define ptr @M3_Cat_speak(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  ret ptr @.strobj.6
}

define ptr @M3_Dog_speak(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  ret ptr @.strobj.8
}

define i32 @M4_Main_fib(ptr %0, i32 %1) {
entry:
  %n = alloca i32, align 4
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  store i32 %1, ptr %n, align 4
  %n1 = load i32, ptr %n, align 4
  %cmp = icmp slt i32 %n1, 2
  %cmp.i32 = zext i1 %cmp to i32
  %ifcond = icmp ne i32 %cmp.i32, 0
  br i1 %ifcond, label %if.then, label %if.else

if.then:                                          ; preds = %entry
  %n2 = load i32, ptr %n, align 4
  ret i32 %n2

if.else:                                          ; preds = %entry
  %self.val = load ptr, ptr %self, align 8
  %n3 = load i32, ptr %n, align 4
  %sub = sub i32 %n3, 1
  call void @__lcpl_checkNull(ptr %self.val)
  %rtti = load ptr, ptr %self.val, align 8
  %fib.slot = getelementptr %struct.__catmint_rtti, ptr %rtti, i32 0, i32 3, i32 5
  %fib.fn = load ptr, ptr %fib.slot, align 8
  %2 = call i32 %fib.fn(ptr %self.val, i32 %sub)
  %self.val4 = load ptr, ptr %self, align 8
  %n5 = load i32, ptr %n, align 4
  %sub6 = sub i32 %n5, 2
  call void @__lcpl_checkNull(ptr %self.val4)
  %rtti7 = load ptr, ptr %self.val4, align 8
  %fib.slot8 = getelementptr %struct.__catmint_rtti, ptr %rtti7, i32 0, i32 3, i32 5
  %fib.fn9 = load ptr, ptr %fib.slot8, align 8
  %3 = call i32 %fib.fn9(ptr %self.val4, i32 %sub6)
  %add = add i32 %2, %3
  ret i32 %add

if.end:                                           ; No predecessors!
  unreachable
}

define void @M4_Main_main(ptr %0) {
entry:
  %total = alloca i32, align 4
  %i = alloca i32, align 4
  %a = alloca ptr, align 8
  %d = alloca ptr, align 8
  %c = alloca ptr, align 8
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %c.obj = call ptr @__catmint_new(ptr @RCat)
  call void @Cat_init(ptr %c.obj)
  store ptr %c.obj, ptr %c, align 8
  %c1 = load ptr, ptr %c, align 8
  call void @__lcpl_checkNull(ptr %c1)
  %rtti = load ptr, ptr %c1, align 8
  %introduce.slot = getelementptr %struct.__catmint_rtti, ptr %rtti, i32 0, i32 3, i32 6
  %introduce.fn = load ptr, ptr %introduce.slot, align 8
  call void %introduce.fn(ptr %c1)
  %d.obj = call ptr @__catmint_new(ptr @RDog)
  call void @Dog_init(ptr %d.obj)
  store ptr %d.obj, ptr %d, align 8
  %d2 = load ptr, ptr %d, align 8
  call void @__lcpl_checkNull(ptr %d2)
  %rtti3 = load ptr, ptr %d2, align 8
  %introduce.slot4 = getelementptr %struct.__catmint_rtti, ptr %rtti3, i32 0, i32 3, i32 6
  %introduce.fn5 = load ptr, ptr %introduce.slot4, align 8
  call void %introduce.fn5(ptr %d2)
  %a.obj = call ptr @__catmint_new(ptr @RAnimal)
  call void @Animal_init(ptr %a.obj)
  store ptr %a.obj, ptr %a, align 8
  %a6 = load ptr, ptr %a, align 8
  call void @__lcpl_checkNull(ptr %a6)
  %rtti7 = load ptr, ptr %a6, align 8
  %introduce.slot8 = getelementptr %struct.__catmint_rtti, ptr %rtti7, i32 0, i32 3, i32 6
  %introduce.fn9 = load ptr, ptr %introduce.slot8, align 8
  call void %introduce.fn9(ptr %a6)
  %self.val = load ptr, ptr %self, align 8
  call void @__lcpl_checkNull(ptr %self.val)
  %rtti10 = load ptr, ptr %self.val, align 8
  %out.slot = getelementptr %struct.__catmint_rtti, ptr %rtti10, i32 0, i32 3, i32 4
  %out.fn = load ptr, ptr %out.slot, align 8
  %1 = call ptr %out.fn(ptr %self.val, ptr @.strobj.10)
  %self.val11 = load ptr, ptr %self, align 8
  %self.val12 = load ptr, ptr %self, align 8
  call void @__lcpl_checkNull(ptr %self.val12)
  %rtti13 = load ptr, ptr %self.val12, align 8
  %fib.slot = getelementptr %struct.__catmint_rtti, ptr %rtti13, i32 0, i32 3, i32 5
  %fib.fn = load ptr, ptr %fib.slot, align 8
  %2 = call i32 %fib.fn(ptr %self.val12, i32 10)
  %int.str = call ptr @__lcpl_intToString(i32 %2)
  call void @__lcpl_checkNull(ptr %self.val11)
  %rtti14 = load ptr, ptr %self.val11, align 8
  %out.slot15 = getelementptr %struct.__catmint_rtti, ptr %rtti14, i32 0, i32 3, i32 4
  %out.fn16 = load ptr, ptr %out.slot15, align 8
  %3 = call ptr %out.fn16(ptr %self.val11, ptr %int.str)
  %self.val17 = load ptr, ptr %self, align 8
  call void @__lcpl_checkNull(ptr %self.val17)
  %rtti18 = load ptr, ptr %self.val17, align 8
  %out.slot19 = getelementptr %struct.__catmint_rtti, ptr %rtti18, i32 0, i32 3, i32 4
  %out.fn20 = load ptr, ptr %out.slot19, align 8
  %4 = call ptr %out.fn20(ptr %self.val17, ptr @.strobj.12)
  store i32 0, ptr %i, align 4
  store i32 1, ptr %i, align 4
  store i32 0, ptr %total, align 4
  store i32 0, ptr %total, align 4
  br label %while.cond

while.cond:                                       ; preds = %while.body, %entry
  %i21 = load i32, ptr %i, align 4
  %cmp = icmp sle i32 %i21, 4
  %cmp.i32 = zext i1 %cmp to i32
  %whilecond = icmp ne i32 %cmp.i32, 0
  br i1 %whilecond, label %while.body, label %while.end

while.body:                                       ; preds = %while.cond
  %total22 = load i32, ptr %total, align 4
  %i23 = load i32, ptr %i, align 4
  %i24 = load i32, ptr %i, align 4
  %mul = mul i32 %i23, %i24
  %add = add i32 %total22, %mul
  store i32 %add, ptr %total, align 4
  %i25 = load i32, ptr %i, align 4
  %add26 = add i32 %i25, 1
  store i32 %add26, ptr %i, align 4
  br label %while.cond

while.end:                                        ; preds = %while.cond
  %self.val27 = load ptr, ptr %self, align 8
  call void @__lcpl_checkNull(ptr %self.val27)
  %rtti28 = load ptr, ptr %self.val27, align 8
  %out.slot29 = getelementptr %struct.__catmint_rtti, ptr %rtti28, i32 0, i32 3, i32 4
  %out.fn30 = load ptr, ptr %out.slot29, align 8
  %5 = call ptr %out.fn30(ptr %self.val27, ptr @.strobj.14)
  %self.val31 = load ptr, ptr %self, align 8
  %total32 = load i32, ptr %total, align 4
  %int.str33 = call ptr @__lcpl_intToString(i32 %total32)
  call void @__lcpl_checkNull(ptr %self.val31)
  %rtti34 = load ptr, ptr %self.val31, align 8
  %out.slot35 = getelementptr %struct.__catmint_rtti, ptr %rtti34, i32 0, i32 3, i32 4
  %out.fn36 = load ptr, ptr %out.slot35, align 8
  %6 = call ptr %out.fn36(ptr %self.val31, ptr %int.str33)
  %self.val37 = load ptr, ptr %self, align 8
  call void @__lcpl_checkNull(ptr %self.val37)
  %rtti38 = load ptr, ptr %self.val37, align 8
  %out.slot39 = getelementptr %struct.__catmint_rtti, ptr %rtti38, i32 0, i32 3, i32 4
  %out.fn40 = load ptr, ptr %out.slot39, align 8
  %7 = call ptr %out.fn40(ptr %self.val37, ptr @.strobj.16)
  ret void
}

declare void @M6_Object_abort(ptr)

declare ptr @M6_Object_typeName(ptr)

declare ptr @M6_Object_copy(ptr)

declare ptr @M2_IO_in(ptr)

declare ptr @M2_IO_out(ptr, ptr)

define void @Animal_init(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  call void @IO_init(ptr %0)
  ret void
}

declare void @IO_init(ptr)

define void @Cat_init(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  call void @Animal_init(ptr %0)
  ret void
}

define void @Dog_init(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  call void @Animal_init(ptr %0)
  ret void
}

define void @Main_init(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  call void @IO_init(ptr %0)
  ret void
}

define i32 @main() {
entry:
  %main.obj = call ptr @__catmint_new(ptr @RMain)
  call void @Main_init(ptr %main.obj)
  call void @M4_Main_main(ptr %main.obj)
  ret i32 0
}
