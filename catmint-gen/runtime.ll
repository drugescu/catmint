; ModuleID = 'runtime.c'
source_filename = "runtime.c"

%struct.TString = type { ptr, i32, i32, ptr }
%struct.timespec = type { i64, i64 }
%struct.TObject = type { ptr, i32 }
%struct.__catmint_rtti = type { ptr, i32, ptr, [0 x ptr] }
%struct.TList = type { ptr, i32, i32, i32, ptr }
%struct.TFile = type { ptr, i32, ptr }
%struct.TProcess = type { ptr, i32, ptr, i32 }
%struct.tm = type { i32, i32, i32, i32, i32, i32, i32, i32, i32, i64, ptr }
%struct.TInteger = type { ptr, i32, i64 }
%struct.__cm_handler = type { ptr, i32, ptr }

@.str = private unnamed_addr constant [7 x i8] c"Object\00", align 1
@NObject = global %struct.TString { ptr @RString, i32 0, i32 6, ptr @.str }, align 8
@.str.1 = private unnamed_addr constant [7 x i8] c"String\00", align 1
@NString = global %struct.TString { ptr @RString, i32 0, i32 6, ptr @.str.1 }, align 8
@.str.2 = private unnamed_addr constant [3 x i8] c"IO\00", align 1
@NIO = global %struct.TString { ptr @RString, i32 0, i32 2, ptr @.str.2 }, align 8
@.str.3 = private unnamed_addr constant [5 x i8] c"List\00", align 1
@NList = global %struct.TString { ptr @RString, i32 0, i32 4, ptr @.str.3 }, align 8
@.str.4 = private unnamed_addr constant [8 x i8] c"Integer\00", align 1
@NInteger = global %struct.TString { ptr @RString, i32 0, i32 7, ptr @.str.4 }, align 8
@.str.5 = private unnamed_addr constant [5 x i8] c"File\00", align 1
@NFile = global %struct.TString { ptr @RString, i32 0, i32 4, ptr @.str.5 }, align 8
@.str.6 = private unnamed_addr constant [5 x i8] c"Math\00", align 1
@NMath = global %struct.TString { ptr @RString, i32 0, i32 4, ptr @.str.6 }, align 8
@.str.7 = private unnamed_addr constant [8 x i8] c"Process\00", align 1
@NProcess = global %struct.TString { ptr @RString, i32 0, i32 7, ptr @.str.7 }, align 8
@RObject = global { ptr, i32, [4 x i8], ptr, [6 x ptr] } { ptr @NObject, i32 16, [4 x i8] zeroinitializer, ptr null, [6 x ptr] [ptr @M6_Object_abort, ptr @M6_Object_typeName, ptr @M6_Object_copy, ptr @M6_Object_retain, ptr @M6_Object_release, ptr @M6_Object_refs] }, align 8
@RString = global { ptr, i32, [4 x i8], ptr, [19 x ptr] } { ptr @NString, i32 24, [4 x i8] zeroinitializer, ptr @RObject, [19 x ptr] [ptr @M6_Object_abort, ptr @M6_Object_typeName, ptr @M6_Object_copy, ptr @M6_Object_retain, ptr @M6_Object_release, ptr @M6_Object_refs, ptr @M6_String_length, ptr @M6_String_toInt, ptr @M6_String_substring, ptr @M6_String_concat, ptr @M6_String_equal, ptr @M6_String_at, ptr @M6_String_indexOf, ptr @M6_String_trim, ptr @M6_String_upper, ptr @M6_String_lower, ptr @M6_String_split, ptr @M6_String_replace, ptr @M6_String_toFloat] }, align 8
@RIO = global { ptr, i32, [4 x i8], ptr, [20 x ptr] } { ptr @NIO, i32 16, [4 x i8] zeroinitializer, ptr @RObject, [20 x ptr] [ptr @M6_Object_abort, ptr @M6_Object_typeName, ptr @M6_Object_copy, ptr @M6_Object_retain, ptr @M6_Object_release, ptr @M6_Object_refs, ptr @M2_IO_in, ptr @M2_IO_out, ptr @M2_IO_readLine, ptr @M2_IO_eof, ptr @M2_IO_entropy, ptr @M2_IO_ticks, ptr @M2_IO_epoch, ptr @M2_IO_localOffset, ptr @M2_IO_sleep, ptr @M2_IO_args, ptr @M2_IO_arg, ptr @M2_IO_err, ptr @M2_IO_exit, ptr @M2_IO_allocated] }, align 8
@RFile = global { ptr, i32, [4 x i8], ptr, [13 x ptr] } { ptr @NFile, i32 24, [4 x i8] zeroinitializer, ptr @RObject, [13 x ptr] [ptr @M6_Object_abort, ptr @M6_Object_typeName, ptr @M6_Object_copy, ptr @M6_Object_retain, ptr @M6_Object_release, ptr @M6_Object_refs, ptr @M4_File_open, ptr @M4_File_readLine, ptr @M4_File_readAll, ptr @M4_File_write, ptr @M4_File_eof, ptr @M4_File_close, ptr @M4_File_isOpen] }, align 8
@RMath = global { ptr, i32, [4 x i8], ptr, [6 x ptr] } { ptr @NMath, i32 16, [4 x i8] zeroinitializer, ptr @RObject, [6 x ptr] [ptr @M6_Object_abort, ptr @M6_Object_typeName, ptr @M6_Object_copy, ptr @M6_Object_retain, ptr @M6_Object_release, ptr @M6_Object_refs] }, align 8
@RProcess = global { ptr, i32, [4 x i8], ptr, [11 x ptr] } { ptr @NProcess, i32 32, [4 x i8] zeroinitializer, ptr @RObject, [11 x ptr] [ptr @M6_Object_abort, ptr @M6_Object_typeName, ptr @M6_Object_copy, ptr @M6_Object_retain, ptr @M6_Object_release, ptr @M6_Object_refs, ptr @M7_Process_start, ptr @M7_Process_readLine, ptr @M7_Process_write, ptr @M7_Process_eof, ptr @M7_Process_finish] }, align 8
@RList = global { ptr, i32, [4 x i8], ptr, [11 x ptr] } { ptr @NList, i32 32, [4 x i8] zeroinitializer, ptr @RObject, [11 x ptr] [ptr @M6_Object_abort, ptr @M6_Object_typeName, ptr @M6_Object_copy, ptr @M6_Object_retain, ptr @M6_Object_release, ptr @M6_Object_refs, ptr @M4_List_len, ptr @M4_List_get, ptr @M4_List_set, ptr @M4_List_append, ptr @M4_List_slice] }, align 8
@RInteger = global { ptr, i32, [4 x i8], ptr, [9 x ptr] } { ptr @NInteger, i32 24, [4 x i8] zeroinitializer, ptr @RObject, [9 x ptr] [ptr @M6_Object_abort, ptr @M6_Object_typeName, ptr @M6_Object_copy, ptr @M6_Object_retain, ptr @M6_Object_release, ptr @M6_Object_refs, ptr @M7_Integer_get, ptr @M7_Integer_set, ptr @M7_Integer_getLong] }, align 8
@gLiveObjects = internal global i32 0, align 4
@gEmptyChars = internal global [1 x i8] zeroinitializer, align 1
@.str.9 = private unnamed_addr constant [33 x i8] c"Substring indices out of bounds.\00", align 1
@.str.10 = private unnamed_addr constant [28 x i8] c"String index out of bounds.\00", align 1
@.str.11 = private unnamed_addr constant [6 x i8] c"%255s\00", align 1
@__stdinp = external global ptr, align 8
@.str.12 = private unnamed_addr constant [1 x i8] zeroinitializer, align 1
@.str.13 = private unnamed_addr constant [13 x i8] c"/dev/urandom\00", align 1
@.str.14 = private unnamed_addr constant [3 x i8] c"rb\00", align 1
@M2_IO_ticks.started = internal global i32 0, align 4
@M2_IO_ticks.origin = internal global %struct.timespec zeroinitializer, align 8
@.str.15 = private unnamed_addr constant [3 x i8] c"%s\00", align 1
@.str.16 = private unnamed_addr constant [30 x i8] c"Out of memory growing a List.\00", align 1
@.str.17 = private unnamed_addr constant [34 x i8] c"List slice indices out of bounds.\00", align 1
@.str.18 = private unnamed_addr constant [35 x i8] c"Calling a method of a void object.\00", align 1
@.str.19 = private unnamed_addr constant [30 x i8] c"Unable to convert %s into %s.\00", align 1
@.str.20 = private unnamed_addr constant [31 x i8] c"Expected an Integer, found %s.\00", align 1
@.str.21 = private unnamed_addr constant [3 x i8] c"%g\00", align 1
@.str.22 = private unnamed_addr constant [3 x i8] c"%d\00", align 1
@.str.23 = private unnamed_addr constant [5 x i8] c"%lld\00", align 1
@gArgCount = internal global i32 0, align 4
@gArgValues = internal global ptr null, align 8
@__stderrp = external global ptr, align 8
@.str.24 = private unnamed_addr constant [30 x i8] c"Out of memory reading a file.\00", align 1
@.str.25 = private unnamed_addr constant [47 x i8] c"Runtime error : out of memory entering a try.\0A\00", align 1
@gHandlers = internal global ptr null, align 8
@gThrown = internal global ptr null, align 8
@.str.26 = private unnamed_addr constant [14 x i8] c"Uncaught: %s\0A\00", align 1
@.str.27 = private unnamed_addr constant [32 x i8] c"Uncaught: an object of type %s\0A\00", align 1
@.str.28 = private unnamed_addr constant [16 x i8] c"Uncaught: null\0A\00", align 1
@.str.29 = private unnamed_addr constant [20 x i8] c"Runtime error : %s\0A\00", align 1
@gPoolDepth = internal global i32 0, align 4
@gPoolMarkCapacity = internal global i32 0, align 4
@gPoolMarks = internal global ptr null, align 8
@.str.30 = private unnamed_addr constant [47 x i8] c"Runtime error : out of memory opening a pool.\0A\00", align 1
@gPoolCount = internal global i32 0, align 4
@gPoolCapacity = internal global i32 0, align 4
@gPoolItems = internal global ptr null, align 8
@.str.31 = private unnamed_addr constant [54 x i8] c"Runtime error : out of memory recording a temporary.\0A\00", align 1
@.str.32 = private unnamed_addr constant [8 x i8] c"/bin/sh\00", align 1
@.str.33 = private unnamed_addr constant [3 x i8] c"sh\00", align 1
@.str.34 = private unnamed_addr constant [3 x i8] c"-c\00", align 1
@.str.35 = private unnamed_addr constant [26 x i8] c"List index out of bounds.\00", align 1

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define void @M6_Object_abort(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  call void @exit(i32 noundef 1) #12
  unreachable
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @M6_Object_typeName(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds nuw %struct.TObject, ptr %3, i32 0, i32 0
  %5 = load ptr, ptr %4, align 8
  %6 = getelementptr inbounds nuw %struct.__catmint_rtti, ptr %5, i32 0, i32 0
  %7 = load ptr, ptr %6, align 8
  ret ptr %7
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @M6_Object_copy(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  %8 = alloca i32, align 4
  store ptr %0, ptr %2, align 8
  %9 = load ptr, ptr %2, align 8
  %10 = getelementptr inbounds nuw %struct.TObject, ptr %9, i32 0, i32 0
  %11 = load ptr, ptr %10, align 8
  %12 = call ptr @__catmint_new(ptr noundef %11)
  store ptr %12, ptr %3, align 8
  %13 = load ptr, ptr %3, align 8
  %14 = load ptr, ptr %2, align 8
  %15 = load ptr, ptr %2, align 8
  %16 = getelementptr inbounds nuw %struct.TObject, ptr %15, i32 0, i32 0
  %17 = load ptr, ptr %16, align 8
  %18 = getelementptr inbounds nuw %struct.__catmint_rtti, ptr %17, i32 0, i32 1
  %19 = load i32, ptr %18, align 8
  %20 = sext i32 %19 to i64
  %21 = load ptr, ptr %3, align 8
  %22 = call i64 @llvm.objectsize.i64.p0(ptr %21, i1 false, i1 true, i1 false)
  %23 = call ptr @__memcpy_chk(ptr noundef %13, ptr noundef %14, i64 noundef %20, i64 noundef %22) #13
  %24 = load ptr, ptr %3, align 8
  %25 = getelementptr inbounds nuw %struct.TObject, ptr %24, i32 0, i32 1
  store i32 1, ptr %25, align 8
  %26 = load ptr, ptr %3, align 8
  %27 = getelementptr inbounds nuw %struct.TObject, ptr %26, i32 0, i32 0
  %28 = load ptr, ptr %27, align 8
  %29 = icmp eq ptr %28, @RString
  br i1 %29, label %30, label %59

30:                                               ; preds = %1
  %31 = load ptr, ptr %3, align 8
  store ptr %31, ptr %4, align 8
  %32 = load ptr, ptr %4, align 8
  %33 = getelementptr inbounds nuw %struct.TString, ptr %32, i32 0, i32 3
  %34 = load ptr, ptr %33, align 8
  %35 = icmp eq ptr %34, @gEmptyChars
  br i1 %35, label %36, label %37

36:                                               ; preds = %30
  br label %58

37:                                               ; preds = %30
  %38 = load ptr, ptr %4, align 8
  %39 = getelementptr inbounds nuw %struct.TString, ptr %38, i32 0, i32 2
  %40 = load i32, ptr %39, align 4
  %41 = sext i32 %40 to i64
  %42 = add i64 %41, 1
  %43 = call ptr @calloc(i64 noundef %42, i64 noundef 1) #14
  store ptr %43, ptr %5, align 8
  %44 = load ptr, ptr %5, align 8
  %45 = load ptr, ptr %2, align 8
  %46 = getelementptr inbounds nuw %struct.TString, ptr %45, i32 0, i32 3
  %47 = load ptr, ptr %46, align 8
  %48 = load ptr, ptr %4, align 8
  %49 = getelementptr inbounds nuw %struct.TString, ptr %48, i32 0, i32 2
  %50 = load i32, ptr %49, align 4
  %51 = sext i32 %50 to i64
  %52 = load ptr, ptr %5, align 8
  %53 = call i64 @llvm.objectsize.i64.p0(ptr %52, i1 false, i1 true, i1 false)
  %54 = call ptr @__memcpy_chk(ptr noundef %44, ptr noundef %47, i64 noundef %51, i64 noundef %53) #13
  %55 = load ptr, ptr %5, align 8
  %56 = load ptr, ptr %4, align 8
  %57 = getelementptr inbounds nuw %struct.TString, ptr %56, i32 0, i32 3
  store ptr %55, ptr %57, align 8
  br label %58

58:                                               ; preds = %37, %36
  br label %133

59:                                               ; preds = %1
  %60 = load ptr, ptr %3, align 8
  %61 = getelementptr inbounds nuw %struct.TObject, ptr %60, i32 0, i32 0
  %62 = load ptr, ptr %61, align 8
  %63 = icmp eq ptr %62, @RList
  br i1 %63, label %64, label %114

64:                                               ; preds = %59
  %65 = load ptr, ptr %3, align 8
  store ptr %65, ptr %6, align 8
  %66 = load ptr, ptr %6, align 8
  %67 = getelementptr inbounds nuw %struct.TList, ptr %66, i32 0, i32 3
  %68 = load i32, ptr %67, align 8
  %69 = icmp sgt i32 %68, 0
  br i1 %69, label %70, label %113

70:                                               ; preds = %64
  %71 = load ptr, ptr %6, align 8
  %72 = getelementptr inbounds nuw %struct.TList, ptr %71, i32 0, i32 4
  %73 = load ptr, ptr %72, align 8
  %74 = icmp ne ptr %73, null
  br i1 %74, label %75, label %113

75:                                               ; preds = %70
  %76 = load ptr, ptr %6, align 8
  %77 = getelementptr inbounds nuw %struct.TList, ptr %76, i32 0, i32 3
  %78 = load i32, ptr %77, align 8
  %79 = sext i32 %78 to i64
  %80 = mul i64 %79, 8
  %81 = call ptr @malloc(i64 noundef %80) #15
  store ptr %81, ptr %7, align 8
  %82 = load ptr, ptr %7, align 8
  %83 = load ptr, ptr %2, align 8
  %84 = getelementptr inbounds nuw %struct.TList, ptr %83, i32 0, i32 4
  %85 = load ptr, ptr %84, align 8
  %86 = load ptr, ptr %6, align 8
  %87 = getelementptr inbounds nuw %struct.TList, ptr %86, i32 0, i32 2
  %88 = load i32, ptr %87, align 4
  %89 = sext i32 %88 to i64
  %90 = mul i64 %89, 8
  %91 = load ptr, ptr %7, align 8
  %92 = call i64 @llvm.objectsize.i64.p0(ptr %91, i1 false, i1 true, i1 false)
  %93 = call ptr @__memcpy_chk(ptr noundef %82, ptr noundef %85, i64 noundef %90, i64 noundef %92) #13
  %94 = load ptr, ptr %7, align 8
  %95 = load ptr, ptr %6, align 8
  %96 = getelementptr inbounds nuw %struct.TList, ptr %95, i32 0, i32 4
  store ptr %94, ptr %96, align 8
  store i32 0, ptr %8, align 4
  br label %97

97:                                               ; preds = %109, %75
  %98 = load i32, ptr %8, align 4
  %99 = load ptr, ptr %6, align 8
  %100 = getelementptr inbounds nuw %struct.TList, ptr %99, i32 0, i32 2
  %101 = load i32, ptr %100, align 4
  %102 = icmp slt i32 %98, %101
  br i1 %102, label %103, label %112

103:                                              ; preds = %97
  %104 = load ptr, ptr %7, align 8
  %105 = load i32, ptr %8, align 4
  %106 = sext i32 %105 to i64
  %107 = getelementptr inbounds ptr, ptr %104, i64 %106
  %108 = load ptr, ptr %107, align 8
  call void @__cm_retain(ptr noundef %108)
  br label %109

109:                                              ; preds = %103
  %110 = load i32, ptr %8, align 4
  %111 = add nsw i32 %110, 1
  store i32 %111, ptr %8, align 4
  br label %97, !llvm.loop !6

112:                                              ; preds = %97
  br label %113

113:                                              ; preds = %112, %70, %64
  br label %132

114:                                              ; preds = %59
  %115 = load ptr, ptr %3, align 8
  %116 = getelementptr inbounds nuw %struct.TObject, ptr %115, i32 0, i32 0
  %117 = load ptr, ptr %116, align 8
  %118 = icmp eq ptr %117, @RFile
  br i1 %118, label %119, label %122

119:                                              ; preds = %114
  %120 = load ptr, ptr %3, align 8
  %121 = getelementptr inbounds nuw %struct.TFile, ptr %120, i32 0, i32 2
  store ptr null, ptr %121, align 8
  br label %131

122:                                              ; preds = %114
  %123 = load ptr, ptr %3, align 8
  %124 = getelementptr inbounds nuw %struct.TObject, ptr %123, i32 0, i32 0
  %125 = load ptr, ptr %124, align 8
  %126 = icmp eq ptr %125, @RProcess
  br i1 %126, label %127, label %130

127:                                              ; preds = %122
  %128 = load ptr, ptr %3, align 8
  %129 = getelementptr inbounds nuw %struct.TProcess, ptr %128, i32 0, i32 2
  store ptr null, ptr %129, align 8
  br label %130

130:                                              ; preds = %127, %122
  br label %131

131:                                              ; preds = %130, %119
  br label %132

132:                                              ; preds = %131, %113
  br label %133

133:                                              ; preds = %132, %58
  %134 = load ptr, ptr %3, align 8
  ret ptr %134
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @M6_Object_retain(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  call void @__cm_retain(ptr noundef %3)
  %4 = load ptr, ptr %2, align 8
  ret ptr %4
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define void @M6_Object_release(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = icmp eq ptr %3, null
  br i1 %4, label %10, label %5

5:                                                ; preds = %1
  %6 = load ptr, ptr %2, align 8
  %7 = getelementptr inbounds nuw %struct.TObject, ptr %6, i32 0, i32 1
  %8 = load i32, ptr %7, align 8
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %10, label %11

10:                                               ; preds = %5, %1
  br label %24

11:                                               ; preds = %5
  %12 = load ptr, ptr %2, align 8
  %13 = getelementptr inbounds nuw %struct.TObject, ptr %12, i32 0, i32 1
  %14 = load i32, ptr %13, align 8
  %15 = sub nsw i32 %14, 1
  store i32 %15, ptr %13, align 8
  %16 = load ptr, ptr %2, align 8
  %17 = getelementptr inbounds nuw %struct.TObject, ptr %16, i32 0, i32 1
  %18 = load i32, ptr %17, align 8
  %19 = icmp eq i32 %18, 0
  br i1 %19, label %20, label %24

20:                                               ; preds = %11
  %21 = load ptr, ptr %2, align 8
  %22 = getelementptr inbounds nuw %struct.TObject, ptr %21, i32 0, i32 1
  store i32 1, ptr %22, align 8
  %23 = load ptr, ptr %2, align 8
  call void @object_free(ptr noundef %23)
  br label %24

24:                                               ; preds = %10, %20, %11
  ret void
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M6_Object_refs(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = icmp eq ptr %3, null
  br i1 %4, label %5, label %6

5:                                                ; preds = %1
  br label %10

6:                                                ; preds = %1
  %7 = load ptr, ptr %2, align 8
  %8 = getelementptr inbounds nuw %struct.TObject, ptr %7, i32 0, i32 1
  %9 = load i32, ptr %8, align 8
  br label %10

10:                                               ; preds = %6, %5
  %11 = phi i32 [ 0, %5 ], [ %9, %6 ]
  ret i32 %11
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M6_String_length(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds nuw %struct.TString, ptr %3, i32 0, i32 2
  %5 = load i32, ptr %4, align 4
  ret i32 %5
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M6_String_toInt(ptr noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  %6 = load ptr, ptr %3, align 8
  %7 = getelementptr inbounds nuw %struct.TString, ptr %6, i32 0, i32 3
  %8 = load ptr, ptr %7, align 8
  %9 = call i64 @strtol(ptr noundef %8, ptr noundef %4, i32 noundef 10)
  %10 = trunc i64 %9 to i32
  store i32 %10, ptr %5, align 4
  %11 = load ptr, ptr %4, align 8
  %12 = load i8, ptr %11, align 1
  %13 = sext i8 %12 to i32
  %14 = icmp ne i32 %13, 0
  br i1 %14, label %15, label %16

15:                                               ; preds = %1
  store i32 0, ptr %2, align 4
  br label %18

16:                                               ; preds = %1
  %17 = load i32, ptr %5, align 4
  store i32 %17, ptr %2, align 4
  br label %18

18:                                               ; preds = %16, %15
  %19 = load i32, ptr %2, align 4
  ret i32 %19
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @M6_String_substring(ptr noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  store ptr %0, ptr %4, align 8
  store i32 %1, ptr %5, align 4
  store i32 %2, ptr %6, align 4
  %8 = load i32, ptr %5, align 4
  %9 = icmp slt i32 %8, 0
  br i1 %9, label %20, label %10

10:                                               ; preds = %3
  %11 = load i32, ptr %5, align 4
  %12 = load i32, ptr %6, align 4
  %13 = icmp sgt i32 %11, %12
  br i1 %13, label %20, label %14

14:                                               ; preds = %10
  %15 = load i32, ptr %6, align 4
  %16 = load ptr, ptr %4, align 8
  %17 = getelementptr inbounds nuw %struct.TString, ptr %16, i32 0, i32 2
  %18 = load i32, ptr %17, align 4
  %19 = icmp sgt i32 %15, %18
  br i1 %19, label %20, label %21

20:                                               ; preds = %14, %10, %3
  call void @__cm_runtimeError(ptr noundef @.str.9)
  br label %21

21:                                               ; preds = %20, %14
  %22 = call ptr @__catmint_new(ptr noundef @RString)
  store ptr %22, ptr %7, align 8
  %23 = load ptr, ptr %7, align 8
  call void @String_init(ptr noundef %23)
  %24 = load i32, ptr %6, align 4
  %25 = load i32, ptr %5, align 4
  %26 = sub nsw i32 %24, %25
  %27 = load ptr, ptr %7, align 8
  %28 = getelementptr inbounds nuw %struct.TString, ptr %27, i32 0, i32 2
  store i32 %26, ptr %28, align 4
  %29 = load i32, ptr %6, align 4
  %30 = load i32, ptr %5, align 4
  %31 = sub nsw i32 %29, %30
  %32 = add nsw i32 %31, 1
  %33 = sext i32 %32 to i64
  %34 = call ptr @calloc(i64 noundef %33, i64 noundef 1) #14
  %35 = load ptr, ptr %7, align 8
  %36 = getelementptr inbounds nuw %struct.TString, ptr %35, i32 0, i32 3
  store ptr %34, ptr %36, align 8
  %37 = load ptr, ptr %7, align 8
  %38 = getelementptr inbounds nuw %struct.TString, ptr %37, i32 0, i32 3
  %39 = load ptr, ptr %38, align 8
  %40 = load ptr, ptr %4, align 8
  %41 = getelementptr inbounds nuw %struct.TString, ptr %40, i32 0, i32 3
  %42 = load ptr, ptr %41, align 8
  %43 = load i32, ptr %5, align 4
  %44 = sext i32 %43 to i64
  %45 = getelementptr inbounds i8, ptr %42, i64 %44
  %46 = load i32, ptr %6, align 4
  %47 = load i32, ptr %5, align 4
  %48 = sub nsw i32 %46, %47
  %49 = sext i32 %48 to i64
  %50 = load ptr, ptr %7, align 8
  %51 = getelementptr inbounds nuw %struct.TString, ptr %50, i32 0, i32 3
  %52 = load ptr, ptr %51, align 8
  %53 = call i64 @llvm.objectsize.i64.p0(ptr %52, i1 false, i1 true, i1 false)
  %54 = call ptr @__memcpy_chk(ptr noundef %39, ptr noundef %45, i64 noundef %49, i64 noundef %53) #13
  %55 = load ptr, ptr %7, align 8
  ret ptr %55
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @M6_String_concat(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  store ptr %0, ptr %3, align 8
  store ptr %1, ptr %4, align 8
  %7 = load ptr, ptr %3, align 8
  %8 = getelementptr inbounds nuw %struct.TString, ptr %7, i32 0, i32 2
  %9 = load i32, ptr %8, align 4
  %10 = load ptr, ptr %4, align 8
  %11 = getelementptr inbounds nuw %struct.TString, ptr %10, i32 0, i32 2
  %12 = load i32, ptr %11, align 4
  %13 = add nsw i32 %9, %12
  store i32 %13, ptr %5, align 4
  %14 = call ptr @__catmint_new(ptr noundef @RString)
  store ptr %14, ptr %6, align 8
  %15 = load ptr, ptr %6, align 8
  call void @String_init(ptr noundef %15)
  %16 = load i32, ptr %5, align 4
  %17 = load ptr, ptr %6, align 8
  %18 = getelementptr inbounds nuw %struct.TString, ptr %17, i32 0, i32 2
  store i32 %16, ptr %18, align 4
  %19 = load i32, ptr %5, align 4
  %20 = add nsw i32 %19, 1
  %21 = sext i32 %20 to i64
  %22 = call ptr @calloc(i64 noundef %21, i64 noundef 1) #14
  %23 = load ptr, ptr %6, align 8
  %24 = getelementptr inbounds nuw %struct.TString, ptr %23, i32 0, i32 3
  store ptr %22, ptr %24, align 8
  %25 = load ptr, ptr %6, align 8
  %26 = getelementptr inbounds nuw %struct.TString, ptr %25, i32 0, i32 3
  %27 = load ptr, ptr %26, align 8
  %28 = load ptr, ptr %3, align 8
  %29 = getelementptr inbounds nuw %struct.TString, ptr %28, i32 0, i32 3
  %30 = load ptr, ptr %29, align 8
  %31 = load ptr, ptr %3, align 8
  %32 = getelementptr inbounds nuw %struct.TString, ptr %31, i32 0, i32 2
  %33 = load i32, ptr %32, align 4
  %34 = sext i32 %33 to i64
  %35 = load ptr, ptr %6, align 8
  %36 = getelementptr inbounds nuw %struct.TString, ptr %35, i32 0, i32 3
  %37 = load ptr, ptr %36, align 8
  %38 = call i64 @llvm.objectsize.i64.p0(ptr %37, i1 false, i1 true, i1 false)
  %39 = call ptr @__strncpy_chk(ptr noundef %27, ptr noundef %30, i64 noundef %34, i64 noundef %38) #13
  %40 = load ptr, ptr %6, align 8
  %41 = getelementptr inbounds nuw %struct.TString, ptr %40, i32 0, i32 3
  %42 = load ptr, ptr %41, align 8
  %43 = load ptr, ptr %4, align 8
  %44 = getelementptr inbounds nuw %struct.TString, ptr %43, i32 0, i32 3
  %45 = load ptr, ptr %44, align 8
  %46 = load ptr, ptr %4, align 8
  %47 = getelementptr inbounds nuw %struct.TString, ptr %46, i32 0, i32 2
  %48 = load i32, ptr %47, align 4
  %49 = sext i32 %48 to i64
  %50 = load ptr, ptr %6, align 8
  %51 = getelementptr inbounds nuw %struct.TString, ptr %50, i32 0, i32 3
  %52 = load ptr, ptr %51, align 8
  %53 = call i64 @llvm.objectsize.i64.p0(ptr %52, i1 false, i1 true, i1 false)
  %54 = call ptr @__strncat_chk(ptr noundef %42, ptr noundef %45, i64 noundef %49, i64 noundef %53) #13
  %55 = load ptr, ptr %6, align 8
  ret ptr %55
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M6_String_equal(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  %6 = load ptr, ptr %4, align 8
  %7 = icmp eq ptr %6, null
  br i1 %7, label %8, label %12

8:                                                ; preds = %2
  %9 = load ptr, ptr %5, align 8
  %10 = icmp eq ptr %9, null
  %11 = zext i1 %10 to i32
  store i32 %11, ptr %3, align 4
  br label %39

12:                                               ; preds = %2
  %13 = load ptr, ptr %5, align 8
  %14 = icmp eq ptr %13, null
  br i1 %14, label %15, label %16

15:                                               ; preds = %12
  store i32 0, ptr %3, align 4
  br label %39

16:                                               ; preds = %12
  %17 = load ptr, ptr %4, align 8
  %18 = getelementptr inbounds nuw %struct.TString, ptr %17, i32 0, i32 2
  %19 = load i32, ptr %18, align 4
  %20 = load ptr, ptr %5, align 8
  %21 = getelementptr inbounds nuw %struct.TString, ptr %20, i32 0, i32 2
  %22 = load i32, ptr %21, align 4
  %23 = icmp ne i32 %19, %22
  br i1 %23, label %24, label %25

24:                                               ; preds = %16
  store i32 0, ptr %3, align 4
  br label %39

25:                                               ; preds = %16
  %26 = load ptr, ptr %4, align 8
  %27 = getelementptr inbounds nuw %struct.TString, ptr %26, i32 0, i32 3
  %28 = load ptr, ptr %27, align 8
  %29 = load ptr, ptr %5, align 8
  %30 = getelementptr inbounds nuw %struct.TString, ptr %29, i32 0, i32 3
  %31 = load ptr, ptr %30, align 8
  %32 = load ptr, ptr %4, align 8
  %33 = getelementptr inbounds nuw %struct.TString, ptr %32, i32 0, i32 2
  %34 = load i32, ptr %33, align 4
  %35 = sext i32 %34 to i64
  %36 = call i32 @strncmp(ptr noundef %28, ptr noundef %31, i64 noundef %35) #13
  %37 = icmp eq i32 %36, 0
  %38 = zext i1 %37 to i32
  store i32 %38, ptr %3, align 4
  br label %39

39:                                               ; preds = %25, %24, %15, %8
  %40 = load i32, ptr %3, align 4
  ret i32 %40
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M6_String_at(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %5 = load i32, ptr %4, align 4
  %6 = icmp slt i32 %5, 0
  br i1 %6, label %13, label %7

7:                                                ; preds = %2
  %8 = load i32, ptr %4, align 4
  %9 = load ptr, ptr %3, align 8
  %10 = getelementptr inbounds nuw %struct.TString, ptr %9, i32 0, i32 2
  %11 = load i32, ptr %10, align 4
  %12 = icmp sge i32 %8, %11
  br i1 %12, label %13, label %14

13:                                               ; preds = %7, %2
  call void @__cm_runtimeError(ptr noundef @.str.10)
  br label %14

14:                                               ; preds = %13, %7
  %15 = load ptr, ptr %3, align 8
  %16 = getelementptr inbounds nuw %struct.TString, ptr %15, i32 0, i32 3
  %17 = load ptr, ptr %16, align 8
  %18 = load i32, ptr %4, align 4
  %19 = sext i32 %18 to i64
  %20 = getelementptr inbounds i8, ptr %17, i64 %19
  %21 = load i8, ptr %20, align 1
  %22 = zext i8 %21 to i32
  ret i32 %22
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M6_String_indexOf(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  %8 = load ptr, ptr %5, align 8
  %9 = icmp eq ptr %8, null
  br i1 %9, label %15, label %10

10:                                               ; preds = %2
  %11 = load ptr, ptr %5, align 8
  %12 = getelementptr inbounds nuw %struct.TString, ptr %11, i32 0, i32 2
  %13 = load i32, ptr %12, align 4
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %15, label %16

15:                                               ; preds = %10, %2
  store i32 0, ptr %3, align 4
  br label %51

16:                                               ; preds = %10
  %17 = load ptr, ptr %4, align 8
  %18 = getelementptr inbounds nuw %struct.TString, ptr %17, i32 0, i32 2
  %19 = load i32, ptr %18, align 4
  %20 = load ptr, ptr %5, align 8
  %21 = getelementptr inbounds nuw %struct.TString, ptr %20, i32 0, i32 2
  %22 = load i32, ptr %21, align 4
  %23 = sub nsw i32 %19, %22
  store i32 %23, ptr %7, align 4
  store i32 0, ptr %6, align 4
  br label %24

24:                                               ; preds = %47, %16
  %25 = load i32, ptr %6, align 4
  %26 = load i32, ptr %7, align 4
  %27 = icmp sle i32 %25, %26
  br i1 %27, label %28, label %50

28:                                               ; preds = %24
  %29 = load ptr, ptr %4, align 8
  %30 = getelementptr inbounds nuw %struct.TString, ptr %29, i32 0, i32 3
  %31 = load ptr, ptr %30, align 8
  %32 = load i32, ptr %6, align 4
  %33 = sext i32 %32 to i64
  %34 = getelementptr inbounds i8, ptr %31, i64 %33
  %35 = load ptr, ptr %5, align 8
  %36 = getelementptr inbounds nuw %struct.TString, ptr %35, i32 0, i32 3
  %37 = load ptr, ptr %36, align 8
  %38 = load ptr, ptr %5, align 8
  %39 = getelementptr inbounds nuw %struct.TString, ptr %38, i32 0, i32 2
  %40 = load i32, ptr %39, align 4
  %41 = sext i32 %40 to i64
  %42 = call i32 @memcmp(ptr noundef %34, ptr noundef %37, i64 noundef %41)
  %43 = icmp eq i32 %42, 0
  br i1 %43, label %44, label %46

44:                                               ; preds = %28
  %45 = load i32, ptr %6, align 4
  store i32 %45, ptr %3, align 4
  br label %51

46:                                               ; preds = %28
  br label %47

47:                                               ; preds = %46
  %48 = load i32, ptr %6, align 4
  %49 = add nsw i32 %48, 1
  store i32 %49, ptr %6, align 4
  br label %24, !llvm.loop !8

50:                                               ; preds = %24
  store i32 -1, ptr %3, align 4
  br label %51

51:                                               ; preds = %50, %44, %15
  %52 = load i32, ptr %3, align 4
  ret i32 %52
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @M6_String_trim(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store ptr %0, ptr %2, align 8
  store i32 0, ptr %3, align 4
  %5 = load ptr, ptr %2, align 8
  %6 = getelementptr inbounds nuw %struct.TString, ptr %5, i32 0, i32 2
  %7 = load i32, ptr %6, align 4
  store i32 %7, ptr %4, align 4
  br label %8

8:                                                ; preds = %25, %1
  %9 = load i32, ptr %3, align 4
  %10 = load i32, ptr %4, align 4
  %11 = icmp slt i32 %9, %10
  br i1 %11, label %12, label %23

12:                                               ; preds = %8
  %13 = load ptr, ptr %2, align 8
  %14 = getelementptr inbounds nuw %struct.TString, ptr %13, i32 0, i32 3
  %15 = load ptr, ptr %14, align 8
  %16 = load i32, ptr %3, align 4
  %17 = sext i32 %16 to i64
  %18 = getelementptr inbounds i8, ptr %15, i64 %17
  %19 = load i8, ptr %18, align 1
  %20 = zext i8 %19 to i32
  %21 = call i32 @isspace(i32 noundef %20) #16
  %22 = icmp ne i32 %21, 0
  br label %23

23:                                               ; preds = %12, %8
  %24 = phi i1 [ false, %8 ], [ %22, %12 ]
  br i1 %24, label %25, label %28

25:                                               ; preds = %23
  %26 = load i32, ptr %3, align 4
  %27 = add nsw i32 %26, 1
  store i32 %27, ptr %3, align 4
  br label %8, !llvm.loop !9

28:                                               ; preds = %23
  br label %29

29:                                               ; preds = %47, %28
  %30 = load i32, ptr %4, align 4
  %31 = load i32, ptr %3, align 4
  %32 = icmp sgt i32 %30, %31
  br i1 %32, label %33, label %45

33:                                               ; preds = %29
  %34 = load ptr, ptr %2, align 8
  %35 = getelementptr inbounds nuw %struct.TString, ptr %34, i32 0, i32 3
  %36 = load ptr, ptr %35, align 8
  %37 = load i32, ptr %4, align 4
  %38 = sub nsw i32 %37, 1
  %39 = sext i32 %38 to i64
  %40 = getelementptr inbounds i8, ptr %36, i64 %39
  %41 = load i8, ptr %40, align 1
  %42 = zext i8 %41 to i32
  %43 = call i32 @isspace(i32 noundef %42) #16
  %44 = icmp ne i32 %43, 0
  br label %45

45:                                               ; preds = %33, %29
  %46 = phi i1 [ false, %29 ], [ %44, %33 ]
  br i1 %46, label %47, label %50

47:                                               ; preds = %45
  %48 = load i32, ptr %4, align 4
  %49 = add nsw i32 %48, -1
  store i32 %49, ptr %4, align 4
  br label %29, !llvm.loop !10

50:                                               ; preds = %45
  %51 = load ptr, ptr %2, align 8
  %52 = load i32, ptr %3, align 4
  %53 = load i32, ptr %4, align 4
  %54 = call ptr @M6_String_substring(ptr noundef %51, i32 noundef %52, i32 noundef %53)
  ret ptr %54
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @M6_String_upper(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = call ptr @string_mapped(ptr noundef %3, i32 noundef 1)
  ret ptr %4
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @M6_String_lower(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = call ptr @string_mapped(ptr noundef %3, i32 noundef 0)
  ret ptr %4
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @M6_String_split(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  %9 = call ptr @__catmint_new(ptr noundef @RList)
  store ptr %9, ptr %6, align 8
  store i32 0, ptr %7, align 4
  %10 = load ptr, ptr %6, align 8
  call void @List_init(ptr noundef %10)
  %11 = load ptr, ptr %5, align 8
  %12 = icmp eq ptr %11, null
  br i1 %12, label %18, label %13

13:                                               ; preds = %2
  %14 = load ptr, ptr %5, align 8
  %15 = getelementptr inbounds nuw %struct.TString, ptr %14, i32 0, i32 2
  %16 = load i32, ptr %15, align 4
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %18, label %27

18:                                               ; preds = %13, %2
  %19 = load ptr, ptr %6, align 8
  %20 = load ptr, ptr %4, align 8
  %21 = load ptr, ptr %4, align 8
  %22 = getelementptr inbounds nuw %struct.TString, ptr %21, i32 0, i32 2
  %23 = load i32, ptr %22, align 4
  %24 = call ptr @M6_String_substring(ptr noundef %20, i32 noundef 0, i32 noundef %23)
  %25 = call ptr @M4_List_append(ptr noundef %19, ptr noundef %24)
  %26 = load ptr, ptr %6, align 8
  store ptr %26, ptr %3, align 8
  br label %81

27:                                               ; preds = %13
  store i32 0, ptr %8, align 4
  br label %28

28:                                               ; preds = %70, %27
  %29 = load i32, ptr %8, align 4
  %30 = load ptr, ptr %5, align 8
  %31 = getelementptr inbounds nuw %struct.TString, ptr %30, i32 0, i32 2
  %32 = load i32, ptr %31, align 4
  %33 = add nsw i32 %29, %32
  %34 = load ptr, ptr %4, align 8
  %35 = getelementptr inbounds nuw %struct.TString, ptr %34, i32 0, i32 2
  %36 = load i32, ptr %35, align 4
  %37 = icmp sle i32 %33, %36
  br i1 %37, label %38, label %71

38:                                               ; preds = %28
  %39 = load ptr, ptr %4, align 8
  %40 = getelementptr inbounds nuw %struct.TString, ptr %39, i32 0, i32 3
  %41 = load ptr, ptr %40, align 8
  %42 = load i32, ptr %8, align 4
  %43 = sext i32 %42 to i64
  %44 = getelementptr inbounds i8, ptr %41, i64 %43
  %45 = load ptr, ptr %5, align 8
  %46 = getelementptr inbounds nuw %struct.TString, ptr %45, i32 0, i32 3
  %47 = load ptr, ptr %46, align 8
  %48 = load ptr, ptr %5, align 8
  %49 = getelementptr inbounds nuw %struct.TString, ptr %48, i32 0, i32 2
  %50 = load i32, ptr %49, align 4
  %51 = sext i32 %50 to i64
  %52 = call i32 @memcmp(ptr noundef %44, ptr noundef %47, i64 noundef %51)
  %53 = icmp eq i32 %52, 0
  br i1 %53, label %54, label %67

54:                                               ; preds = %38
  %55 = load ptr, ptr %6, align 8
  %56 = load ptr, ptr %4, align 8
  %57 = load i32, ptr %7, align 4
  %58 = load i32, ptr %8, align 4
  %59 = call ptr @M6_String_substring(ptr noundef %56, i32 noundef %57, i32 noundef %58)
  %60 = call ptr @M4_List_append(ptr noundef %55, ptr noundef %59)
  %61 = load ptr, ptr %5, align 8
  %62 = getelementptr inbounds nuw %struct.TString, ptr %61, i32 0, i32 2
  %63 = load i32, ptr %62, align 4
  %64 = load i32, ptr %8, align 4
  %65 = add nsw i32 %64, %63
  store i32 %65, ptr %8, align 4
  %66 = load i32, ptr %8, align 4
  store i32 %66, ptr %7, align 4
  br label %70

67:                                               ; preds = %38
  %68 = load i32, ptr %8, align 4
  %69 = add nsw i32 %68, 1
  store i32 %69, ptr %8, align 4
  br label %70

70:                                               ; preds = %67, %54
  br label %28, !llvm.loop !11

71:                                               ; preds = %28
  %72 = load ptr, ptr %6, align 8
  %73 = load ptr, ptr %4, align 8
  %74 = load i32, ptr %7, align 4
  %75 = load ptr, ptr %4, align 8
  %76 = getelementptr inbounds nuw %struct.TString, ptr %75, i32 0, i32 2
  %77 = load i32, ptr %76, align 4
  %78 = call ptr @M6_String_substring(ptr noundef %73, i32 noundef %74, i32 noundef %77)
  %79 = call ptr @M4_List_append(ptr noundef %72, ptr noundef %78)
  %80 = load ptr, ptr %6, align 8
  store ptr %80, ptr %3, align 8
  br label %81

81:                                               ; preds = %71, %18
  %82 = load ptr, ptr %3, align 8
  ret ptr %82
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @M6_String_replace(ptr noundef %0, ptr noundef %1, ptr noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca ptr, align 8
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  %13 = alloca i32, align 4
  store ptr %0, ptr %5, align 8
  store ptr %1, ptr %6, align 8
  store ptr %2, ptr %7, align 8
  store i32 0, ptr %10, align 4
  store i32 0, ptr %11, align 4
  store i32 0, ptr %12, align 4
  %14 = load ptr, ptr %6, align 8
  %15 = icmp eq ptr %14, null
  br i1 %15, label %24, label %16

16:                                               ; preds = %3
  %17 = load ptr, ptr %6, align 8
  %18 = getelementptr inbounds nuw %struct.TString, ptr %17, i32 0, i32 2
  %19 = load i32, ptr %18, align 4
  %20 = icmp eq i32 %19, 0
  br i1 %20, label %24, label %21

21:                                               ; preds = %16
  %22 = load ptr, ptr %7, align 8
  %23 = icmp eq ptr %22, null
  br i1 %23, label %24, label %30

24:                                               ; preds = %21, %16, %3
  %25 = load ptr, ptr %5, align 8
  %26 = load ptr, ptr %5, align 8
  %27 = getelementptr inbounds nuw %struct.TString, ptr %26, i32 0, i32 2
  %28 = load i32, ptr %27, align 4
  %29 = call ptr @M6_String_substring(ptr noundef %25, i32 noundef 0, i32 noundef %28)
  store ptr %29, ptr %4, align 8
  br label %174

30:                                               ; preds = %21
  store i32 0, ptr %11, align 4
  br label %31

31:                                               ; preds = %68, %30
  %32 = load i32, ptr %11, align 4
  %33 = load ptr, ptr %6, align 8
  %34 = getelementptr inbounds nuw %struct.TString, ptr %33, i32 0, i32 2
  %35 = load i32, ptr %34, align 4
  %36 = add nsw i32 %32, %35
  %37 = load ptr, ptr %5, align 8
  %38 = getelementptr inbounds nuw %struct.TString, ptr %37, i32 0, i32 2
  %39 = load i32, ptr %38, align 4
  %40 = icmp sle i32 %36, %39
  br i1 %40, label %41, label %69

41:                                               ; preds = %31
  %42 = load ptr, ptr %5, align 8
  %43 = getelementptr inbounds nuw %struct.TString, ptr %42, i32 0, i32 3
  %44 = load ptr, ptr %43, align 8
  %45 = load i32, ptr %11, align 4
  %46 = sext i32 %45 to i64
  %47 = getelementptr inbounds i8, ptr %44, i64 %46
  %48 = load ptr, ptr %6, align 8
  %49 = getelementptr inbounds nuw %struct.TString, ptr %48, i32 0, i32 3
  %50 = load ptr, ptr %49, align 8
  %51 = load ptr, ptr %6, align 8
  %52 = getelementptr inbounds nuw %struct.TString, ptr %51, i32 0, i32 2
  %53 = load i32, ptr %52, align 4
  %54 = sext i32 %53 to i64
  %55 = call i32 @memcmp(ptr noundef %47, ptr noundef %50, i64 noundef %54)
  %56 = icmp eq i32 %55, 0
  br i1 %56, label %57, label %65

57:                                               ; preds = %41
  %58 = load i32, ptr %12, align 4
  %59 = add nsw i32 %58, 1
  store i32 %59, ptr %12, align 4
  %60 = load ptr, ptr %6, align 8
  %61 = getelementptr inbounds nuw %struct.TString, ptr %60, i32 0, i32 2
  %62 = load i32, ptr %61, align 4
  %63 = load i32, ptr %11, align 4
  %64 = add nsw i32 %63, %62
  store i32 %64, ptr %11, align 4
  br label %68

65:                                               ; preds = %41
  %66 = load i32, ptr %11, align 4
  %67 = add nsw i32 %66, 1
  store i32 %67, ptr %11, align 4
  br label %68

68:                                               ; preds = %65, %57
  br label %31, !llvm.loop !12

69:                                               ; preds = %31
  %70 = load i32, ptr %12, align 4
  %71 = load ptr, ptr %7, align 8
  %72 = getelementptr inbounds nuw %struct.TString, ptr %71, i32 0, i32 2
  %73 = load i32, ptr %72, align 4
  %74 = load ptr, ptr %6, align 8
  %75 = getelementptr inbounds nuw %struct.TString, ptr %74, i32 0, i32 2
  %76 = load i32, ptr %75, align 4
  %77 = sub nsw i32 %73, %76
  %78 = mul nsw i32 %70, %77
  store i32 %78, ptr %13, align 4
  %79 = call ptr @__catmint_new(ptr noundef @RString)
  store ptr %79, ptr %8, align 8
  %80 = load ptr, ptr %8, align 8
  call void @String_init(ptr noundef %80)
  %81 = load ptr, ptr %5, align 8
  %82 = getelementptr inbounds nuw %struct.TString, ptr %81, i32 0, i32 2
  %83 = load i32, ptr %82, align 4
  %84 = load i32, ptr %13, align 4
  %85 = add nsw i32 %83, %84
  %86 = load ptr, ptr %8, align 8
  %87 = getelementptr inbounds nuw %struct.TString, ptr %86, i32 0, i32 2
  store i32 %85, ptr %87, align 4
  %88 = load ptr, ptr %8, align 8
  %89 = getelementptr inbounds nuw %struct.TString, ptr %88, i32 0, i32 2
  %90 = load i32, ptr %89, align 4
  %91 = sext i32 %90 to i64
  %92 = add i64 %91, 1
  %93 = call ptr @calloc(i64 noundef %92, i64 noundef 1) #14
  store ptr %93, ptr %9, align 8
  %94 = load ptr, ptr %9, align 8
  %95 = load ptr, ptr %8, align 8
  %96 = getelementptr inbounds nuw %struct.TString, ptr %95, i32 0, i32 3
  store ptr %94, ptr %96, align 8
  store i32 0, ptr %11, align 4
  br label %97

97:                                               ; preds = %171, %69
  %98 = load i32, ptr %11, align 4
  %99 = load ptr, ptr %5, align 8
  %100 = getelementptr inbounds nuw %struct.TString, ptr %99, i32 0, i32 2
  %101 = load i32, ptr %100, align 4
  %102 = icmp slt i32 %98, %101
  br i1 %102, label %103, label %172

103:                                              ; preds = %97
  %104 = load i32, ptr %11, align 4
  %105 = load ptr, ptr %6, align 8
  %106 = getelementptr inbounds nuw %struct.TString, ptr %105, i32 0, i32 2
  %107 = load i32, ptr %106, align 4
  %108 = add nsw i32 %104, %107
  %109 = load ptr, ptr %5, align 8
  %110 = getelementptr inbounds nuw %struct.TString, ptr %109, i32 0, i32 2
  %111 = load i32, ptr %110, align 4
  %112 = icmp sle i32 %108, %111
  br i1 %112, label %113, label %157

113:                                              ; preds = %103
  %114 = load ptr, ptr %5, align 8
  %115 = getelementptr inbounds nuw %struct.TString, ptr %114, i32 0, i32 3
  %116 = load ptr, ptr %115, align 8
  %117 = load i32, ptr %11, align 4
  %118 = sext i32 %117 to i64
  %119 = getelementptr inbounds i8, ptr %116, i64 %118
  %120 = load ptr, ptr %6, align 8
  %121 = getelementptr inbounds nuw %struct.TString, ptr %120, i32 0, i32 3
  %122 = load ptr, ptr %121, align 8
  %123 = load ptr, ptr %6, align 8
  %124 = getelementptr inbounds nuw %struct.TString, ptr %123, i32 0, i32 2
  %125 = load i32, ptr %124, align 4
  %126 = sext i32 %125 to i64
  %127 = call i32 @memcmp(ptr noundef %119, ptr noundef %122, i64 noundef %126)
  %128 = icmp eq i32 %127, 0
  br i1 %128, label %129, label %157

129:                                              ; preds = %113
  %130 = load ptr, ptr %9, align 8
  %131 = load i32, ptr %10, align 4
  %132 = sext i32 %131 to i64
  %133 = getelementptr inbounds i8, ptr %130, i64 %132
  %134 = load ptr, ptr %7, align 8
  %135 = getelementptr inbounds nuw %struct.TString, ptr %134, i32 0, i32 3
  %136 = load ptr, ptr %135, align 8
  %137 = load ptr, ptr %7, align 8
  %138 = getelementptr inbounds nuw %struct.TString, ptr %137, i32 0, i32 2
  %139 = load i32, ptr %138, align 4
  %140 = sext i32 %139 to i64
  %141 = load ptr, ptr %9, align 8
  %142 = load i32, ptr %10, align 4
  %143 = sext i32 %142 to i64
  %144 = getelementptr inbounds i8, ptr %141, i64 %143
  %145 = call i64 @llvm.objectsize.i64.p0(ptr %144, i1 false, i1 true, i1 false)
  %146 = call ptr @__memcpy_chk(ptr noundef %133, ptr noundef %136, i64 noundef %140, i64 noundef %145) #13
  %147 = load ptr, ptr %7, align 8
  %148 = getelementptr inbounds nuw %struct.TString, ptr %147, i32 0, i32 2
  %149 = load i32, ptr %148, align 4
  %150 = load i32, ptr %10, align 4
  %151 = add nsw i32 %150, %149
  store i32 %151, ptr %10, align 4
  %152 = load ptr, ptr %6, align 8
  %153 = getelementptr inbounds nuw %struct.TString, ptr %152, i32 0, i32 2
  %154 = load i32, ptr %153, align 4
  %155 = load i32, ptr %11, align 4
  %156 = add nsw i32 %155, %154
  store i32 %156, ptr %11, align 4
  br label %171

157:                                              ; preds = %113, %103
  %158 = load ptr, ptr %5, align 8
  %159 = getelementptr inbounds nuw %struct.TString, ptr %158, i32 0, i32 3
  %160 = load ptr, ptr %159, align 8
  %161 = load i32, ptr %11, align 4
  %162 = add nsw i32 %161, 1
  store i32 %162, ptr %11, align 4
  %163 = sext i32 %161 to i64
  %164 = getelementptr inbounds i8, ptr %160, i64 %163
  %165 = load i8, ptr %164, align 1
  %166 = load ptr, ptr %9, align 8
  %167 = load i32, ptr %10, align 4
  %168 = add nsw i32 %167, 1
  store i32 %168, ptr %10, align 4
  %169 = sext i32 %167 to i64
  %170 = getelementptr inbounds i8, ptr %166, i64 %169
  store i8 %165, ptr %170, align 1
  br label %171

171:                                              ; preds = %157, %129
  br label %97, !llvm.loop !13

172:                                              ; preds = %97
  %173 = load ptr, ptr %8, align 8
  store ptr %173, ptr %4, align 8
  br label %174

174:                                              ; preds = %172, %24
  %175 = load ptr, ptr %4, align 8
  ret ptr %175
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define double @M6_String_toFloat(ptr noundef %0) #0 {
  %2 = alloca double, align 8
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  %5 = alloca double, align 8
  store ptr %0, ptr %3, align 8
  %6 = load ptr, ptr %3, align 8
  %7 = getelementptr inbounds nuw %struct.TString, ptr %6, i32 0, i32 3
  %8 = load ptr, ptr %7, align 8
  %9 = call double @"\01_strtod"(ptr noundef %8, ptr noundef %4)
  store double %9, ptr %5, align 8
  %10 = load ptr, ptr %4, align 8
  %11 = load i8, ptr %10, align 1
  %12 = sext i8 %11 to i32
  %13 = icmp ne i32 %12, 0
  br i1 %13, label %14, label %15

14:                                               ; preds = %1
  store double 0.000000e+00, ptr %2, align 8
  br label %17

15:                                               ; preds = %1
  %16 = load double, ptr %5, align 8
  store double %16, ptr %2, align 8
  br label %17

17:                                               ; preds = %15, %14
  %18 = load double, ptr %2, align 8
  ret double %18
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @M2_IO_in(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca [256 x i8], align 1
  store ptr %0, ptr %2, align 8
  %4 = load ptr, ptr %2, align 8
  %5 = getelementptr inbounds [256 x i8], ptr %3, i64 0, i64 0
  store i8 0, ptr %5, align 1
  %6 = getelementptr inbounds [256 x i8], ptr %3, i64 0, i64 0
  %7 = call i32 (ptr, ...) @scanf(ptr noundef @.str.11, ptr noundef %6)
  %8 = icmp ne i32 %7, 1
  br i1 %8, label %9, label %11

9:                                                ; preds = %1
  %10 = getelementptr inbounds [256 x i8], ptr %3, i64 0, i64 0
  store i8 0, ptr %10, align 1
  br label %11

11:                                               ; preds = %9, %1
  %12 = getelementptr inbounds [256 x i8], ptr %3, i64 0, i64 0
  %13 = call ptr @make_string(ptr noundef %12)
  ret ptr %13
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @M2_IO_out(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  store ptr %0, ptr %3, align 8
  store ptr %1, ptr %4, align 8
  %5 = load ptr, ptr %4, align 8
  %6 = getelementptr inbounds nuw %struct.TString, ptr %5, i32 0, i32 3
  %7 = load ptr, ptr %6, align 8
  %8 = call i32 (ptr, ...) @printf(ptr noundef @.str.15, ptr noundef %7)
  %9 = load ptr, ptr %3, align 8
  ret ptr %9
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @M2_IO_readLine(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca ptr, align 8
  %4 = alloca [1024 x i8], align 1
  %5 = alloca i64, align 8
  store ptr %0, ptr %3, align 8
  %6 = load ptr, ptr %3, align 8
  %7 = getelementptr inbounds [1024 x i8], ptr %4, i64 0, i64 0
  %8 = load ptr, ptr @__stdinp, align 8
  %9 = call ptr @fgets(ptr noundef %7, i32 noundef 1024, ptr noundef %8)
  %10 = icmp ne ptr %9, null
  br i1 %10, label %13, label %11

11:                                               ; preds = %1
  %12 = call ptr @make_string(ptr noundef @.str.12)
  store ptr %12, ptr %2, align 8
  br label %32

13:                                               ; preds = %1
  %14 = getelementptr inbounds [1024 x i8], ptr %4, i64 0, i64 0
  %15 = call i64 @strlen(ptr noundef %14) #13
  store i64 %15, ptr %5, align 8
  %16 = load i64, ptr %5, align 8
  %17 = icmp ugt i64 %16, 0
  br i1 %17, label %18, label %29

18:                                               ; preds = %13
  %19 = load i64, ptr %5, align 8
  %20 = sub i64 %19, 1
  %21 = getelementptr inbounds nuw [1024 x i8], ptr %4, i64 0, i64 %20
  %22 = load i8, ptr %21, align 1
  %23 = sext i8 %22 to i32
  %24 = icmp eq i32 %23, 10
  br i1 %24, label %25, label %29

25:                                               ; preds = %18
  %26 = load i64, ptr %5, align 8
  %27 = sub i64 %26, 1
  %28 = getelementptr inbounds nuw [1024 x i8], ptr %4, i64 0, i64 %27
  store i8 0, ptr %28, align 1
  br label %29

29:                                               ; preds = %25, %18, %13
  %30 = getelementptr inbounds [1024 x i8], ptr %4, i64 0, i64 0
  %31 = call ptr @make_string(ptr noundef %30)
  store ptr %31, ptr %2, align 8
  br label %32

32:                                               ; preds = %29, %11
  %33 = load ptr, ptr %2, align 8
  ret ptr %33
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M2_IO_eof(ptr noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  %5 = load ptr, ptr %3, align 8
  %6 = load ptr, ptr @__stdinp, align 8
  %7 = call i32 @fgetc(ptr noundef %6)
  store i32 %7, ptr %4, align 4
  %8 = load i32, ptr %4, align 4
  %9 = icmp eq i32 %8, -1
  br i1 %9, label %10, label %11

10:                                               ; preds = %1
  store i32 1, ptr %2, align 4
  br label %15

11:                                               ; preds = %1
  %12 = load i32, ptr %4, align 4
  %13 = load ptr, ptr @__stdinp, align 8
  %14 = call i32 @ungetc(i32 noundef %12, ptr noundef %13)
  store i32 0, ptr %2, align 4
  br label %15

15:                                               ; preds = %11, %10
  %16 = load i32, ptr %2, align 4
  ret i32 %16
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M2_IO_entropy(ptr noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i64, align 8
  store ptr %0, ptr %3, align 8
  store i32 0, ptr %4, align 4
  %7 = load ptr, ptr %3, align 8
  %8 = call ptr @"\01_fopen"(ptr noundef @.str.13, ptr noundef @.str.14)
  store ptr %8, ptr %5, align 8
  %9 = load ptr, ptr %5, align 8
  %10 = icmp ne ptr %9, null
  br i1 %10, label %11, label %22

11:                                               ; preds = %1
  %12 = load ptr, ptr %5, align 8
  %13 = call i64 @fread(ptr noundef %4, i64 noundef 4, i64 noundef 1, ptr noundef %12)
  store i64 %13, ptr %6, align 8
  %14 = load ptr, ptr %5, align 8
  %15 = call i32 @fclose(ptr noundef %14)
  %16 = load i64, ptr %6, align 8
  %17 = icmp eq i64 %16, 1
  br i1 %17, label %18, label %21

18:                                               ; preds = %11
  %19 = load i32, ptr %4, align 4
  %20 = and i32 %19, 2147483647
  store i32 %20, ptr %2, align 4
  br label %33

21:                                               ; preds = %11
  br label %22

22:                                               ; preds = %21, %1
  %23 = call i64 @time(ptr noundef null)
  %24 = trunc i64 %23 to i32
  %25 = mul i32 %24, -1640531535
  store i32 %25, ptr %4, align 4
  %26 = call i64 @"\01_clock"()
  %27 = trunc i64 %26 to i32
  %28 = mul i32 %27, 40503
  %29 = load i32, ptr %4, align 4
  %30 = xor i32 %29, %28
  store i32 %30, ptr %4, align 4
  %31 = load i32, ptr %4, align 4
  %32 = and i32 %31, 2147483647
  store i32 %32, ptr %2, align 4
  br label %33

33:                                               ; preds = %22, %18
  %34 = load i32, ptr %2, align 4
  ret i32 %34
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M2_IO_ticks(ptr noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  %4 = alloca %struct.timespec, align 8
  %5 = alloca i64, align 8
  %6 = alloca i64, align 8
  store ptr %0, ptr %3, align 8
  %7 = load ptr, ptr %3, align 8
  %8 = call i32 @clock_gettime(i32 noundef 6, ptr noundef %4)
  %9 = icmp ne i32 %8, 0
  br i1 %9, label %10, label %11

10:                                               ; preds = %1
  store i32 0, ptr %2, align 4
  br label %30

11:                                               ; preds = %1
  %12 = load i32, ptr @M2_IO_ticks.started, align 4
  %13 = icmp ne i32 %12, 0
  br i1 %13, label %15, label %14

14:                                               ; preds = %11
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 @M2_IO_ticks.origin, ptr align 8 %4, i64 16, i1 false)
  store i32 1, ptr @M2_IO_ticks.started, align 4
  br label %15

15:                                               ; preds = %14, %11
  %16 = getelementptr inbounds nuw %struct.timespec, ptr %4, i32 0, i32 0
  %17 = load i64, ptr %16, align 8
  %18 = load i64, ptr @M2_IO_ticks.origin, align 8
  %19 = sub nsw i64 %17, %18
  store i64 %19, ptr %5, align 8
  %20 = getelementptr inbounds nuw %struct.timespec, ptr %4, i32 0, i32 1
  %21 = load i64, ptr %20, align 8
  %22 = load i64, ptr getelementptr inbounds nuw (%struct.timespec, ptr @M2_IO_ticks.origin, i32 0, i32 1), align 8
  %23 = sub nsw i64 %21, %22
  %24 = sdiv i64 %23, 1000000
  store i64 %24, ptr %6, align 8
  %25 = load i64, ptr %5, align 8
  %26 = mul nsw i64 %25, 1000
  %27 = load i64, ptr %6, align 8
  %28 = add nsw i64 %26, %27
  %29 = trunc i64 %28 to i32
  store i32 %29, ptr %2, align 4
  br label %30

30:                                               ; preds = %15, %10
  %31 = load i32, ptr %2, align 4
  ret i32 %31
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i64 @M2_IO_epoch(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = call i64 @time(ptr noundef null)
  ret i64 %4
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M2_IO_localOffset(ptr noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  %4 = alloca i64, align 8
  %5 = alloca %struct.tm, align 8
  %6 = alloca %struct.tm, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  %10 = load ptr, ptr %3, align 8
  %11 = call i64 @time(ptr noundef null)
  store i64 %11, ptr %4, align 8
  %12 = call ptr @localtime_r(ptr noundef %4, ptr noundef %5)
  %13 = icmp ne ptr %12, null
  br i1 %13, label %14, label %17

14:                                               ; preds = %1
  %15 = call ptr @gmtime_r(ptr noundef %4, ptr noundef %6)
  %16 = icmp ne ptr %15, null
  br i1 %16, label %18, label %17

17:                                               ; preds = %14, %1
  store i32 0, ptr %2, align 4
  br label %59

18:                                               ; preds = %14
  %19 = getelementptr inbounds nuw %struct.tm, ptr %5, i32 0, i32 2
  %20 = load i32, ptr %19, align 8
  %21 = mul nsw i32 %20, 3600
  %22 = getelementptr inbounds nuw %struct.tm, ptr %5, i32 0, i32 1
  %23 = load i32, ptr %22, align 4
  %24 = mul nsw i32 %23, 60
  %25 = add nsw i32 %21, %24
  %26 = getelementptr inbounds nuw %struct.tm, ptr %5, i32 0, i32 0
  %27 = load i32, ptr %26, align 8
  %28 = add nsw i32 %25, %27
  store i32 %28, ptr %7, align 4
  %29 = getelementptr inbounds nuw %struct.tm, ptr %6, i32 0, i32 2
  %30 = load i32, ptr %29, align 8
  %31 = mul nsw i32 %30, 3600
  %32 = getelementptr inbounds nuw %struct.tm, ptr %6, i32 0, i32 1
  %33 = load i32, ptr %32, align 4
  %34 = mul nsw i32 %33, 60
  %35 = add nsw i32 %31, %34
  %36 = getelementptr inbounds nuw %struct.tm, ptr %6, i32 0, i32 0
  %37 = load i32, ptr %36, align 8
  %38 = add nsw i32 %35, %37
  store i32 %38, ptr %8, align 4
  %39 = getelementptr inbounds nuw %struct.tm, ptr %5, i32 0, i32 7
  %40 = load i32, ptr %39, align 4
  %41 = getelementptr inbounds nuw %struct.tm, ptr %6, i32 0, i32 7
  %42 = load i32, ptr %41, align 4
  %43 = sub nsw i32 %40, %42
  store i32 %43, ptr %9, align 4
  %44 = load i32, ptr %9, align 4
  %45 = icmp sgt i32 %44, 1
  br i1 %45, label %46, label %47

46:                                               ; preds = %18
  store i32 -1, ptr %9, align 4
  br label %52

47:                                               ; preds = %18
  %48 = load i32, ptr %9, align 4
  %49 = icmp slt i32 %48, -1
  br i1 %49, label %50, label %51

50:                                               ; preds = %47
  store i32 1, ptr %9, align 4
  br label %51

51:                                               ; preds = %50, %47
  br label %52

52:                                               ; preds = %51, %46
  %53 = load i32, ptr %7, align 4
  %54 = load i32, ptr %8, align 4
  %55 = sub nsw i32 %53, %54
  %56 = load i32, ptr %9, align 4
  %57 = mul nsw i32 %56, 86400
  %58 = add nsw i32 %55, %57
  store i32 %58, ptr %2, align 4
  br label %59

59:                                               ; preds = %52, %17
  %60 = load i32, ptr %2, align 4
  ret i32 %60
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @M2_IO_sleep(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca %struct.timespec, align 8
  store ptr %0, ptr %4, align 8
  store i32 %1, ptr %5, align 4
  %7 = load i32, ptr %5, align 4
  %8 = icmp sle i32 %7, 0
  br i1 %8, label %9, label %11

9:                                                ; preds = %2
  %10 = load ptr, ptr %4, align 8
  store ptr %10, ptr %3, align 8
  br label %23

11:                                               ; preds = %2
  %12 = load i32, ptr %5, align 4
  %13 = sdiv i32 %12, 1000
  %14 = sext i32 %13 to i64
  %15 = getelementptr inbounds nuw %struct.timespec, ptr %6, i32 0, i32 0
  store i64 %14, ptr %15, align 8
  %16 = load i32, ptr %5, align 4
  %17 = srem i32 %16, 1000
  %18 = sext i32 %17 to i64
  %19 = mul nsw i64 %18, 1000000
  %20 = getelementptr inbounds nuw %struct.timespec, ptr %6, i32 0, i32 1
  store i64 %19, ptr %20, align 8
  %21 = call i32 @"\01_nanosleep"(ptr noundef %6, ptr noundef null)
  %22 = load ptr, ptr %4, align 8
  store ptr %22, ptr %3, align 8
  br label %23

23:                                               ; preds = %11, %9
  %24 = load ptr, ptr %3, align 8
  ret ptr %24
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M2_IO_args(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = load i32, ptr @gArgCount, align 4
  ret i32 %4
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @M2_IO_arg(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store i32 %1, ptr %5, align 4
  %6 = load ptr, ptr %4, align 8
  %7 = load i32, ptr %5, align 4
  %8 = icmp slt i32 %7, 0
  br i1 %8, label %16, label %9

9:                                                ; preds = %2
  %10 = load i32, ptr %5, align 4
  %11 = load i32, ptr @gArgCount, align 4
  %12 = icmp sge i32 %10, %11
  br i1 %12, label %16, label %13

13:                                               ; preds = %9
  %14 = load ptr, ptr @gArgValues, align 8
  %15 = icmp eq ptr %14, null
  br i1 %15, label %16, label %18

16:                                               ; preds = %13, %9, %2
  %17 = call ptr @make_string(ptr noundef @.str.12)
  store ptr %17, ptr %3, align 8
  br label %25

18:                                               ; preds = %13
  %19 = load ptr, ptr @gArgValues, align 8
  %20 = load i32, ptr %5, align 4
  %21 = sext i32 %20 to i64
  %22 = getelementptr inbounds ptr, ptr %19, i64 %21
  %23 = load ptr, ptr %22, align 8
  %24 = call ptr @make_string(ptr noundef %23)
  store ptr %24, ptr %3, align 8
  br label %25

25:                                               ; preds = %18, %16
  %26 = load ptr, ptr %3, align 8
  ret ptr %26
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @M2_IO_err(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  store ptr %0, ptr %3, align 8
  store ptr %1, ptr %4, align 8
  %5 = load ptr, ptr %4, align 8
  %6 = getelementptr inbounds nuw %struct.TString, ptr %5, i32 0, i32 3
  %7 = load ptr, ptr %6, align 8
  %8 = load ptr, ptr @__stderrp, align 8
  %9 = call i32 @"\01_fputs"(ptr noundef %7, ptr noundef %8)
  %10 = load ptr, ptr %3, align 8
  ret ptr %10
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define void @M2_IO_exit(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %5 = load ptr, ptr %3, align 8
  %6 = load i32, ptr %4, align 4
  call void @exit(i32 noundef %6) #12
  unreachable
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M2_IO_allocated(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = load i32, ptr @gLiveObjects, align 4
  ret i32 %4
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M4_File_open(ptr noundef %0, ptr noundef %1, ptr noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  store ptr %2, ptr %6, align 8
  %7 = load ptr, ptr %4, align 8
  %8 = getelementptr inbounds nuw %struct.TFile, ptr %7, i32 0, i32 2
  %9 = load ptr, ptr %8, align 8
  %10 = icmp ne ptr %9, null
  br i1 %10, label %11, label %18

11:                                               ; preds = %3
  %12 = load ptr, ptr %4, align 8
  %13 = getelementptr inbounds nuw %struct.TFile, ptr %12, i32 0, i32 2
  %14 = load ptr, ptr %13, align 8
  %15 = call i32 @fclose(ptr noundef %14)
  %16 = load ptr, ptr %4, align 8
  %17 = getelementptr inbounds nuw %struct.TFile, ptr %16, i32 0, i32 2
  store ptr null, ptr %17, align 8
  br label %18

18:                                               ; preds = %11, %3
  %19 = load ptr, ptr %5, align 8
  %20 = getelementptr inbounds nuw %struct.TString, ptr %19, i32 0, i32 3
  %21 = load ptr, ptr %20, align 8
  %22 = load ptr, ptr %6, align 8
  %23 = getelementptr inbounds nuw %struct.TString, ptr %22, i32 0, i32 3
  %24 = load ptr, ptr %23, align 8
  %25 = call ptr @"\01_fopen"(ptr noundef %21, ptr noundef %24)
  %26 = load ptr, ptr %4, align 8
  %27 = getelementptr inbounds nuw %struct.TFile, ptr %26, i32 0, i32 2
  store ptr %25, ptr %27, align 8
  %28 = load ptr, ptr %4, align 8
  %29 = getelementptr inbounds nuw %struct.TFile, ptr %28, i32 0, i32 2
  %30 = load ptr, ptr %29, align 8
  %31 = icmp ne ptr %30, null
  %32 = zext i1 %31 to i32
  ret i32 %32
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @M4_File_readLine(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca ptr, align 8
  %4 = alloca [4096 x i8], align 1
  %5 = alloca i64, align 8
  store ptr %0, ptr %3, align 8
  %6 = load ptr, ptr %3, align 8
  %7 = getelementptr inbounds nuw %struct.TFile, ptr %6, i32 0, i32 2
  %8 = load ptr, ptr %7, align 8
  %9 = icmp ne ptr %8, null
  br i1 %9, label %10, label %17

10:                                               ; preds = %1
  %11 = getelementptr inbounds [4096 x i8], ptr %4, i64 0, i64 0
  %12 = load ptr, ptr %3, align 8
  %13 = getelementptr inbounds nuw %struct.TFile, ptr %12, i32 0, i32 2
  %14 = load ptr, ptr %13, align 8
  %15 = call ptr @fgets(ptr noundef %11, i32 noundef 4096, ptr noundef %14)
  %16 = icmp ne ptr %15, null
  br i1 %16, label %19, label %17

17:                                               ; preds = %10, %1
  %18 = call ptr @make_string(ptr noundef @.str.12)
  store ptr %18, ptr %2, align 8
  br label %38

19:                                               ; preds = %10
  %20 = getelementptr inbounds [4096 x i8], ptr %4, i64 0, i64 0
  %21 = call i64 @strlen(ptr noundef %20) #13
  store i64 %21, ptr %5, align 8
  %22 = load i64, ptr %5, align 8
  %23 = icmp ugt i64 %22, 0
  br i1 %23, label %24, label %35

24:                                               ; preds = %19
  %25 = load i64, ptr %5, align 8
  %26 = sub i64 %25, 1
  %27 = getelementptr inbounds nuw [4096 x i8], ptr %4, i64 0, i64 %26
  %28 = load i8, ptr %27, align 1
  %29 = sext i8 %28 to i32
  %30 = icmp eq i32 %29, 10
  br i1 %30, label %31, label %35

31:                                               ; preds = %24
  %32 = load i64, ptr %5, align 8
  %33 = sub i64 %32, 1
  %34 = getelementptr inbounds nuw [4096 x i8], ptr %4, i64 0, i64 %33
  store i8 0, ptr %34, align 1
  br label %35

35:                                               ; preds = %31, %24, %19
  %36 = getelementptr inbounds [4096 x i8], ptr %4, i64 0, i64 0
  %37 = call ptr @make_string(ptr noundef %36)
  store ptr %37, ptr %2, align 8
  br label %38

38:                                               ; preds = %35, %17
  %39 = load ptr, ptr %2, align 8
  ret ptr %39
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @M4_File_readAll(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca i64, align 8
  %7 = alloca i64, align 8
  %8 = alloca i64, align 8
  store ptr %0, ptr %3, align 8
  store ptr null, ptr %5, align 8
  store i64 0, ptr %6, align 8
  store i64 0, ptr %7, align 8
  %9 = load ptr, ptr %3, align 8
  %10 = getelementptr inbounds nuw %struct.TFile, ptr %9, i32 0, i32 2
  %11 = load ptr, ptr %10, align 8
  %12 = icmp ne ptr %11, null
  br i1 %12, label %15, label %13

13:                                               ; preds = %1
  %14 = call ptr @make_string(ptr noundef @.str.12)
  store ptr %14, ptr %2, align 8
  br label %72

15:                                               ; preds = %1
  br label %16

16:                                               ; preds = %52, %15
  %17 = load i64, ptr %6, align 8
  %18 = add i64 %17, 4096
  %19 = add i64 %18, 1
  %20 = load i64, ptr %7, align 8
  %21 = icmp ugt i64 %19, %20
  br i1 %21, label %22, label %38

22:                                               ; preds = %16
  %23 = load i64, ptr %7, align 8
  %24 = icmp eq i64 %23, 0
  br i1 %24, label %25, label %26

25:                                               ; preds = %22
  br label %29

26:                                               ; preds = %22
  %27 = load i64, ptr %7, align 8
  %28 = mul i64 %27, 2
  br label %29

29:                                               ; preds = %26, %25
  %30 = phi i64 [ 8192, %25 ], [ %28, %26 ]
  store i64 %30, ptr %7, align 8
  %31 = load ptr, ptr %5, align 8
  %32 = load i64, ptr %7, align 8
  %33 = call ptr @realloc(ptr noundef %31, i64 noundef %32) #17
  store ptr %33, ptr %5, align 8
  %34 = load ptr, ptr %5, align 8
  %35 = icmp ne ptr %34, null
  br i1 %35, label %37, label %36

36:                                               ; preds = %29
  call void @__cm_runtimeError(ptr noundef @.str.24)
  br label %37

37:                                               ; preds = %36, %29
  br label %38

38:                                               ; preds = %37, %16
  %39 = load ptr, ptr %5, align 8
  %40 = load i64, ptr %6, align 8
  %41 = getelementptr inbounds nuw i8, ptr %39, i64 %40
  %42 = load ptr, ptr %3, align 8
  %43 = getelementptr inbounds nuw %struct.TFile, ptr %42, i32 0, i32 2
  %44 = load ptr, ptr %43, align 8
  %45 = call i64 @fread(ptr noundef %41, i64 noundef 1, i64 noundef 4096, ptr noundef %44)
  store i64 %45, ptr %8, align 8
  %46 = load i64, ptr %8, align 8
  %47 = load i64, ptr %6, align 8
  %48 = add i64 %47, %46
  store i64 %48, ptr %6, align 8
  %49 = load i64, ptr %8, align 8
  %50 = icmp ult i64 %49, 4096
  br i1 %50, label %51, label %52

51:                                               ; preds = %38
  br label %53

52:                                               ; preds = %38
  br label %16

53:                                               ; preds = %51
  %54 = load ptr, ptr %5, align 8
  %55 = icmp ne ptr %54, null
  br i1 %55, label %58, label %56

56:                                               ; preds = %53
  %57 = call ptr @make_string(ptr noundef @.str.12)
  store ptr %57, ptr %2, align 8
  br label %72

58:                                               ; preds = %53
  %59 = load ptr, ptr %5, align 8
  %60 = load i64, ptr %6, align 8
  %61 = getelementptr inbounds nuw i8, ptr %59, i64 %60
  store i8 0, ptr %61, align 1
  %62 = call ptr @__catmint_new(ptr noundef @RString)
  store ptr %62, ptr %4, align 8
  %63 = load ptr, ptr %4, align 8
  call void @String_init(ptr noundef %63)
  %64 = load i64, ptr %6, align 8
  %65 = trunc i64 %64 to i32
  %66 = load ptr, ptr %4, align 8
  %67 = getelementptr inbounds nuw %struct.TString, ptr %66, i32 0, i32 2
  store i32 %65, ptr %67, align 4
  %68 = load ptr, ptr %5, align 8
  %69 = load ptr, ptr %4, align 8
  %70 = getelementptr inbounds nuw %struct.TString, ptr %69, i32 0, i32 3
  store ptr %68, ptr %70, align 8
  %71 = load ptr, ptr %4, align 8
  store ptr %71, ptr %2, align 8
  br label %72

72:                                               ; preds = %58, %56, %13
  %73 = load ptr, ptr %2, align 8
  ret ptr %73
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @M4_File_write(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  store ptr %0, ptr %3, align 8
  store ptr %1, ptr %4, align 8
  %5 = load ptr, ptr %3, align 8
  %6 = getelementptr inbounds nuw %struct.TFile, ptr %5, i32 0, i32 2
  %7 = load ptr, ptr %6, align 8
  %8 = icmp ne ptr %7, null
  br i1 %8, label %9, label %21

9:                                                ; preds = %2
  %10 = load ptr, ptr %4, align 8
  %11 = getelementptr inbounds nuw %struct.TString, ptr %10, i32 0, i32 3
  %12 = load ptr, ptr %11, align 8
  %13 = load ptr, ptr %4, align 8
  %14 = getelementptr inbounds nuw %struct.TString, ptr %13, i32 0, i32 2
  %15 = load i32, ptr %14, align 4
  %16 = sext i32 %15 to i64
  %17 = load ptr, ptr %3, align 8
  %18 = getelementptr inbounds nuw %struct.TFile, ptr %17, i32 0, i32 2
  %19 = load ptr, ptr %18, align 8
  %20 = call i64 @"\01_fwrite"(ptr noundef %12, i64 noundef 1, i64 noundef %16, ptr noundef %19)
  br label %21

21:                                               ; preds = %9, %2
  %22 = load ptr, ptr %3, align 8
  ret ptr %22
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M4_File_eof(ptr noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  %5 = load ptr, ptr %3, align 8
  %6 = getelementptr inbounds nuw %struct.TFile, ptr %5, i32 0, i32 2
  %7 = load ptr, ptr %6, align 8
  %8 = icmp ne ptr %7, null
  br i1 %8, label %10, label %9

9:                                                ; preds = %1
  store i32 1, ptr %2, align 4
  br label %24

10:                                               ; preds = %1
  %11 = load ptr, ptr %3, align 8
  %12 = getelementptr inbounds nuw %struct.TFile, ptr %11, i32 0, i32 2
  %13 = load ptr, ptr %12, align 8
  %14 = call i32 @fgetc(ptr noundef %13)
  store i32 %14, ptr %4, align 4
  %15 = load i32, ptr %4, align 4
  %16 = icmp eq i32 %15, -1
  br i1 %16, label %17, label %18

17:                                               ; preds = %10
  store i32 1, ptr %2, align 4
  br label %24

18:                                               ; preds = %10
  %19 = load i32, ptr %4, align 4
  %20 = load ptr, ptr %3, align 8
  %21 = getelementptr inbounds nuw %struct.TFile, ptr %20, i32 0, i32 2
  %22 = load ptr, ptr %21, align 8
  %23 = call i32 @ungetc(i32 noundef %19, ptr noundef %22)
  store i32 0, ptr %2, align 4
  br label %24

24:                                               ; preds = %18, %17, %9
  %25 = load i32, ptr %2, align 4
  ret i32 %25
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @M4_File_close(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds nuw %struct.TFile, ptr %3, i32 0, i32 2
  %5 = load ptr, ptr %4, align 8
  %6 = icmp ne ptr %5, null
  br i1 %6, label %7, label %14

7:                                                ; preds = %1
  %8 = load ptr, ptr %2, align 8
  %9 = getelementptr inbounds nuw %struct.TFile, ptr %8, i32 0, i32 2
  %10 = load ptr, ptr %9, align 8
  %11 = call i32 @fclose(ptr noundef %10)
  %12 = load ptr, ptr %2, align 8
  %13 = getelementptr inbounds nuw %struct.TFile, ptr %12, i32 0, i32 2
  store ptr null, ptr %13, align 8
  br label %14

14:                                               ; preds = %7, %1
  %15 = load ptr, ptr %2, align 8
  ret ptr %15
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M4_File_isOpen(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds nuw %struct.TFile, ptr %3, i32 0, i32 2
  %5 = load ptr, ptr %4, align 8
  %6 = icmp ne ptr %5, null
  %7 = zext i1 %6 to i32
  ret i32 %7
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M7_Process_start(ptr noundef %0, ptr noundef %1, ptr noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  store ptr %2, ptr %6, align 8
  %7 = load ptr, ptr %4, align 8
  %8 = getelementptr inbounds nuw %struct.TProcess, ptr %7, i32 0, i32 2
  %9 = load ptr, ptr %8, align 8
  %10 = icmp ne ptr %9, null
  br i1 %10, label %11, label %18

11:                                               ; preds = %3
  %12 = load ptr, ptr %4, align 8
  %13 = getelementptr inbounds nuw %struct.TProcess, ptr %12, i32 0, i32 2
  %14 = load ptr, ptr %13, align 8
  %15 = call i32 @pclose(ptr noundef %14)
  %16 = load ptr, ptr %4, align 8
  %17 = getelementptr inbounds nuw %struct.TProcess, ptr %16, i32 0, i32 2
  store ptr null, ptr %17, align 8
  br label %18

18:                                               ; preds = %11, %3
  %19 = load ptr, ptr %5, align 8
  %20 = getelementptr inbounds nuw %struct.TString, ptr %19, i32 0, i32 3
  %21 = load ptr, ptr %20, align 8
  %22 = load ptr, ptr %6, align 8
  %23 = getelementptr inbounds nuw %struct.TString, ptr %22, i32 0, i32 3
  %24 = load ptr, ptr %23, align 8
  %25 = call ptr @"\01_popen"(ptr noundef %21, ptr noundef %24)
  %26 = load ptr, ptr %4, align 8
  %27 = getelementptr inbounds nuw %struct.TProcess, ptr %26, i32 0, i32 2
  store ptr %25, ptr %27, align 8
  %28 = load ptr, ptr %4, align 8
  %29 = getelementptr inbounds nuw %struct.TProcess, ptr %28, i32 0, i32 2
  %30 = load ptr, ptr %29, align 8
  %31 = icmp ne ptr %30, null
  %32 = zext i1 %31 to i32
  ret i32 %32
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @M7_Process_readLine(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca ptr, align 8
  %4 = alloca [4096 x i8], align 1
  %5 = alloca i64, align 8
  store ptr %0, ptr %3, align 8
  %6 = load ptr, ptr %3, align 8
  %7 = getelementptr inbounds nuw %struct.TProcess, ptr %6, i32 0, i32 2
  %8 = load ptr, ptr %7, align 8
  %9 = icmp ne ptr %8, null
  br i1 %9, label %10, label %17

10:                                               ; preds = %1
  %11 = getelementptr inbounds [4096 x i8], ptr %4, i64 0, i64 0
  %12 = load ptr, ptr %3, align 8
  %13 = getelementptr inbounds nuw %struct.TProcess, ptr %12, i32 0, i32 2
  %14 = load ptr, ptr %13, align 8
  %15 = call ptr @fgets(ptr noundef %11, i32 noundef 4096, ptr noundef %14)
  %16 = icmp ne ptr %15, null
  br i1 %16, label %19, label %17

17:                                               ; preds = %10, %1
  %18 = call ptr @make_string(ptr noundef @.str.12)
  store ptr %18, ptr %2, align 8
  br label %38

19:                                               ; preds = %10
  %20 = getelementptr inbounds [4096 x i8], ptr %4, i64 0, i64 0
  %21 = call i64 @strlen(ptr noundef %20) #13
  store i64 %21, ptr %5, align 8
  %22 = load i64, ptr %5, align 8
  %23 = icmp ugt i64 %22, 0
  br i1 %23, label %24, label %35

24:                                               ; preds = %19
  %25 = load i64, ptr %5, align 8
  %26 = sub i64 %25, 1
  %27 = getelementptr inbounds nuw [4096 x i8], ptr %4, i64 0, i64 %26
  %28 = load i8, ptr %27, align 1
  %29 = sext i8 %28 to i32
  %30 = icmp eq i32 %29, 10
  br i1 %30, label %31, label %35

31:                                               ; preds = %24
  %32 = load i64, ptr %5, align 8
  %33 = sub i64 %32, 1
  %34 = getelementptr inbounds nuw [4096 x i8], ptr %4, i64 0, i64 %33
  store i8 0, ptr %34, align 1
  br label %35

35:                                               ; preds = %31, %24, %19
  %36 = getelementptr inbounds [4096 x i8], ptr %4, i64 0, i64 0
  %37 = call ptr @make_string(ptr noundef %36)
  store ptr %37, ptr %2, align 8
  br label %38

38:                                               ; preds = %35, %17
  %39 = load ptr, ptr %2, align 8
  ret ptr %39
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @M7_Process_write(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  store ptr %0, ptr %3, align 8
  store ptr %1, ptr %4, align 8
  %5 = load ptr, ptr %3, align 8
  %6 = getelementptr inbounds nuw %struct.TProcess, ptr %5, i32 0, i32 2
  %7 = load ptr, ptr %6, align 8
  %8 = icmp ne ptr %7, null
  br i1 %8, label %9, label %21

9:                                                ; preds = %2
  %10 = load ptr, ptr %4, align 8
  %11 = getelementptr inbounds nuw %struct.TString, ptr %10, i32 0, i32 3
  %12 = load ptr, ptr %11, align 8
  %13 = load ptr, ptr %4, align 8
  %14 = getelementptr inbounds nuw %struct.TString, ptr %13, i32 0, i32 2
  %15 = load i32, ptr %14, align 4
  %16 = sext i32 %15 to i64
  %17 = load ptr, ptr %3, align 8
  %18 = getelementptr inbounds nuw %struct.TProcess, ptr %17, i32 0, i32 2
  %19 = load ptr, ptr %18, align 8
  %20 = call i64 @"\01_fwrite"(ptr noundef %12, i64 noundef 1, i64 noundef %16, ptr noundef %19)
  br label %21

21:                                               ; preds = %9, %2
  %22 = load ptr, ptr %3, align 8
  ret ptr %22
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M7_Process_eof(ptr noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  %5 = load ptr, ptr %3, align 8
  %6 = getelementptr inbounds nuw %struct.TProcess, ptr %5, i32 0, i32 2
  %7 = load ptr, ptr %6, align 8
  %8 = icmp ne ptr %7, null
  br i1 %8, label %10, label %9

9:                                                ; preds = %1
  store i32 1, ptr %2, align 4
  br label %24

10:                                               ; preds = %1
  %11 = load ptr, ptr %3, align 8
  %12 = getelementptr inbounds nuw %struct.TProcess, ptr %11, i32 0, i32 2
  %13 = load ptr, ptr %12, align 8
  %14 = call i32 @fgetc(ptr noundef %13)
  store i32 %14, ptr %4, align 4
  %15 = load i32, ptr %4, align 4
  %16 = icmp eq i32 %15, -1
  br i1 %16, label %17, label %18

17:                                               ; preds = %10
  store i32 1, ptr %2, align 4
  br label %24

18:                                               ; preds = %10
  %19 = load i32, ptr %4, align 4
  %20 = load ptr, ptr %3, align 8
  %21 = getelementptr inbounds nuw %struct.TProcess, ptr %20, i32 0, i32 2
  %22 = load ptr, ptr %21, align 8
  %23 = call i32 @ungetc(i32 noundef %19, ptr noundef %22)
  store i32 0, ptr %2, align 4
  br label %24

24:                                               ; preds = %18, %17, %9
  %25 = load i32, ptr %2, align 4
  ret i32 %25
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M7_Process_finish(ptr noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  %5 = load ptr, ptr %3, align 8
  %6 = getelementptr inbounds nuw %struct.TProcess, ptr %5, i32 0, i32 2
  %7 = load ptr, ptr %6, align 8
  %8 = icmp ne ptr %7, null
  br i1 %8, label %10, label %9

9:                                                ; preds = %1
  store i32 -1, ptr %2, align 4
  br label %23

10:                                               ; preds = %1
  %11 = load ptr, ptr %3, align 8
  %12 = getelementptr inbounds nuw %struct.TProcess, ptr %11, i32 0, i32 2
  %13 = load ptr, ptr %12, align 8
  %14 = call i32 @pclose(ptr noundef %13)
  store i32 %14, ptr %4, align 4
  %15 = load ptr, ptr %3, align 8
  %16 = getelementptr inbounds nuw %struct.TProcess, ptr %15, i32 0, i32 2
  store ptr null, ptr %16, align 8
  %17 = load i32, ptr %4, align 4
  %18 = icmp eq i32 %17, -1
  br i1 %18, label %19, label %20

19:                                               ; preds = %10
  store i32 -1, ptr %2, align 4
  br label %23

20:                                               ; preds = %10
  %21 = load i32, ptr %4, align 4
  %22 = call i32 @exit_status(i32 noundef %21)
  store i32 %22, ptr %2, align 4
  br label %23

23:                                               ; preds = %20, %19, %9
  %24 = load i32, ptr %2, align 4
  ret i32 %24
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M4_List_len(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds nuw %struct.TList, ptr %3, i32 0, i32 2
  %5 = load i32, ptr %4, align 4
  ret i32 %5
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @M4_List_get(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %5 = load ptr, ptr %3, align 8
  %6 = load i32, ptr %4, align 4
  call void @list_bounds(ptr noundef %5, i32 noundef %6)
  %7 = load ptr, ptr %3, align 8
  %8 = getelementptr inbounds nuw %struct.TList, ptr %7, i32 0, i32 4
  %9 = load ptr, ptr %8, align 8
  %10 = load i32, ptr %4, align 4
  %11 = sext i32 %10 to i64
  %12 = getelementptr inbounds ptr, ptr %9, i64 %11
  %13 = load ptr, ptr %12, align 8
  ret ptr %13
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @M4_List_set(ptr noundef %0, i32 noundef %1, ptr noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  store ptr %0, ptr %4, align 8
  store i32 %1, ptr %5, align 4
  store ptr %2, ptr %6, align 8
  %8 = load ptr, ptr %4, align 8
  %9 = load i32, ptr %5, align 4
  call void @list_bounds(ptr noundef %8, i32 noundef %9)
  %10 = load ptr, ptr %4, align 8
  %11 = getelementptr inbounds nuw %struct.TList, ptr %10, i32 0, i32 4
  %12 = load ptr, ptr %11, align 8
  %13 = load i32, ptr %5, align 4
  %14 = sext i32 %13 to i64
  %15 = getelementptr inbounds ptr, ptr %12, i64 %14
  %16 = load ptr, ptr %15, align 8
  store ptr %16, ptr %7, align 8
  %17 = load ptr, ptr %6, align 8
  call void @__cm_retain(ptr noundef %17)
  %18 = load ptr, ptr %6, align 8
  %19 = load ptr, ptr %4, align 8
  %20 = getelementptr inbounds nuw %struct.TList, ptr %19, i32 0, i32 4
  %21 = load ptr, ptr %20, align 8
  %22 = load i32, ptr %5, align 4
  %23 = sext i32 %22 to i64
  %24 = getelementptr inbounds ptr, ptr %21, i64 %23
  store ptr %18, ptr %24, align 8
  %25 = load ptr, ptr %7, align 8
  call void @__cm_release(ptr noundef %25)
  %26 = load ptr, ptr %6, align 8
  ret ptr %26
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @M4_List_append(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  store ptr %0, ptr %3, align 8
  store ptr %1, ptr %4, align 8
  %7 = load ptr, ptr %3, align 8
  %8 = getelementptr inbounds nuw %struct.TList, ptr %7, i32 0, i32 2
  %9 = load i32, ptr %8, align 4
  %10 = load ptr, ptr %3, align 8
  %11 = getelementptr inbounds nuw %struct.TList, ptr %10, i32 0, i32 3
  %12 = load i32, ptr %11, align 8
  %13 = icmp eq i32 %9, %12
  br i1 %13, label %14, label %44

14:                                               ; preds = %2
  %15 = load ptr, ptr %3, align 8
  %16 = getelementptr inbounds nuw %struct.TList, ptr %15, i32 0, i32 3
  %17 = load i32, ptr %16, align 8
  %18 = icmp eq i32 %17, 0
  br i1 %18, label %19, label %20

19:                                               ; preds = %14
  br label %25

20:                                               ; preds = %14
  %21 = load ptr, ptr %3, align 8
  %22 = getelementptr inbounds nuw %struct.TList, ptr %21, i32 0, i32 3
  %23 = load i32, ptr %22, align 8
  %24 = mul nsw i32 %23, 2
  br label %25

25:                                               ; preds = %20, %19
  %26 = phi i32 [ 4, %19 ], [ %24, %20 ]
  store i32 %26, ptr %5, align 4
  %27 = load ptr, ptr %3, align 8
  %28 = getelementptr inbounds nuw %struct.TList, ptr %27, i32 0, i32 4
  %29 = load ptr, ptr %28, align 8
  %30 = load i32, ptr %5, align 4
  %31 = sext i32 %30 to i64
  %32 = mul i64 %31, 8
  %33 = call ptr @realloc(ptr noundef %29, i64 noundef %32) #17
  store ptr %33, ptr %6, align 8
  %34 = load ptr, ptr %6, align 8
  %35 = icmp ne ptr %34, null
  br i1 %35, label %37, label %36

36:                                               ; preds = %25
  call void @__cm_runtimeError(ptr noundef @.str.16)
  br label %37

37:                                               ; preds = %36, %25
  %38 = load ptr, ptr %6, align 8
  %39 = load ptr, ptr %3, align 8
  %40 = getelementptr inbounds nuw %struct.TList, ptr %39, i32 0, i32 4
  store ptr %38, ptr %40, align 8
  %41 = load i32, ptr %5, align 4
  %42 = load ptr, ptr %3, align 8
  %43 = getelementptr inbounds nuw %struct.TList, ptr %42, i32 0, i32 3
  store i32 %41, ptr %43, align 8
  br label %44

44:                                               ; preds = %37, %2
  %45 = load ptr, ptr %4, align 8
  call void @__cm_retain(ptr noundef %45)
  %46 = load ptr, ptr %4, align 8
  %47 = load ptr, ptr %3, align 8
  %48 = getelementptr inbounds nuw %struct.TList, ptr %47, i32 0, i32 4
  %49 = load ptr, ptr %48, align 8
  %50 = load ptr, ptr %3, align 8
  %51 = getelementptr inbounds nuw %struct.TList, ptr %50, i32 0, i32 2
  %52 = load i32, ptr %51, align 4
  %53 = sext i32 %52 to i64
  %54 = getelementptr inbounds ptr, ptr %49, i64 %53
  store ptr %46, ptr %54, align 8
  %55 = load ptr, ptr %3, align 8
  %56 = getelementptr inbounds nuw %struct.TList, ptr %55, i32 0, i32 2
  %57 = load i32, ptr %56, align 4
  %58 = add nsw i32 %57, 1
  store i32 %58, ptr %56, align 4
  %59 = load ptr, ptr %3, align 8
  ret ptr %59
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @M4_List_slice(ptr noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store i32 %1, ptr %5, align 4
  store i32 %2, ptr %6, align 4
  %9 = load i32, ptr %5, align 4
  %10 = icmp slt i32 %9, 0
  br i1 %10, label %21, label %11

11:                                               ; preds = %3
  %12 = load i32, ptr %5, align 4
  %13 = load i32, ptr %6, align 4
  %14 = icmp sgt i32 %12, %13
  br i1 %14, label %21, label %15

15:                                               ; preds = %11
  %16 = load i32, ptr %6, align 4
  %17 = load ptr, ptr %4, align 8
  %18 = getelementptr inbounds nuw %struct.TList, ptr %17, i32 0, i32 2
  %19 = load i32, ptr %18, align 4
  %20 = icmp sgt i32 %16, %19
  br i1 %20, label %21, label %22

21:                                               ; preds = %15, %11, %3
  call void @__cm_runtimeError(ptr noundef @.str.17)
  br label %22

22:                                               ; preds = %21, %15
  %23 = call ptr @__catmint_new(ptr noundef @RList)
  store ptr %23, ptr %7, align 8
  %24 = load ptr, ptr %7, align 8
  call void @List_init(ptr noundef %24)
  %25 = load i32, ptr %5, align 4
  store i32 %25, ptr %8, align 4
  br label %26

26:                                               ; preds = %40, %22
  %27 = load i32, ptr %8, align 4
  %28 = load i32, ptr %6, align 4
  %29 = icmp slt i32 %27, %28
  br i1 %29, label %30, label %43

30:                                               ; preds = %26
  %31 = load ptr, ptr %7, align 8
  %32 = load ptr, ptr %4, align 8
  %33 = getelementptr inbounds nuw %struct.TList, ptr %32, i32 0, i32 4
  %34 = load ptr, ptr %33, align 8
  %35 = load i32, ptr %8, align 4
  %36 = sext i32 %35 to i64
  %37 = getelementptr inbounds ptr, ptr %34, i64 %36
  %38 = load ptr, ptr %37, align 8
  %39 = call ptr @M4_List_append(ptr noundef %31, ptr noundef %38)
  br label %40

40:                                               ; preds = %30
  %41 = load i32, ptr %8, align 4
  %42 = add nsw i32 %41, 1
  store i32 %42, ptr %8, align 4
  br label %26, !llvm.loop !14

43:                                               ; preds = %26
  %44 = load ptr, ptr %7, align 8
  ret ptr %44
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M7_Integer_get(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds nuw %struct.TInteger, ptr %3, i32 0, i32 2
  %5 = load i64, ptr %4, align 8
  %6 = trunc i64 %5 to i32
  ret i32 %6
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @M7_Integer_set(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %5 = load i32, ptr %4, align 4
  %6 = sext i32 %5 to i64
  %7 = load ptr, ptr %3, align 8
  %8 = getelementptr inbounds nuw %struct.TInteger, ptr %7, i32 0, i32 2
  store i64 %6, ptr %8, align 8
  %9 = load ptr, ptr %3, align 8
  ret ptr %9
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i64 @M7_Integer_getLong(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds nuw %struct.TInteger, ptr %3, i32 0, i32 2
  %5 = load i64, ptr %4, align 8
  ret i64 %5
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @__catmint_new(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %4 = load ptr, ptr %2, align 8
  %5 = getelementptr inbounds nuw %struct.__catmint_rtti, ptr %4, i32 0, i32 1
  %6 = load i32, ptr %5, align 8
  %7 = sext i32 %6 to i64
  %8 = call ptr @malloc(i64 noundef %7) #15
  store ptr %8, ptr %3, align 8
  %9 = load ptr, ptr %3, align 8
  %10 = load ptr, ptr %2, align 8
  %11 = getelementptr inbounds nuw %struct.__catmint_rtti, ptr %10, i32 0, i32 1
  %12 = load i32, ptr %11, align 8
  %13 = sext i32 %12 to i64
  %14 = load ptr, ptr %3, align 8
  %15 = call i64 @llvm.objectsize.i64.p0(ptr %14, i1 false, i1 true, i1 false)
  %16 = call ptr @__memset_chk(ptr noundef %9, i32 noundef 0, i64 noundef %13, i64 noundef %15) #13
  %17 = load ptr, ptr %2, align 8
  %18 = load ptr, ptr %3, align 8
  %19 = getelementptr inbounds nuw %struct.TObject, ptr %18, i32 0, i32 0
  store ptr %17, ptr %19, align 8
  %20 = load ptr, ptr %3, align 8
  %21 = getelementptr inbounds nuw %struct.TObject, ptr %20, i32 0, i32 1
  store i32 1, ptr %21, align 8
  %22 = load i32, ptr @gLiveObjects, align 4
  %23 = add nsw i32 %22, 1
  store i32 %23, ptr @gLiveObjects, align 4
  %24 = load ptr, ptr %3, align 8
  call void @__cm_poolAdd(ptr noundef %24)
  %25 = load ptr, ptr %3, align 8
  ret ptr %25
}

; Function Attrs: allocsize(0)
declare ptr @malloc(i64 noundef) #1

; Function Attrs: nounwind
declare ptr @__memset_chk(ptr noundef, i32 noundef, i64 noundef, i64 noundef) #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.objectsize.i64.p0(ptr, i1 immarg, i1 immarg, i1 immarg) #3

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define void @__cm_poolAdd(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %5 = load i32, ptr @gPoolDepth, align 4
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %10, label %7

7:                                                ; preds = %1
  %8 = load ptr, ptr %2, align 8
  %9 = icmp eq ptr %8, null
  br i1 %9, label %10, label %11

10:                                               ; preds = %7, %1
  br label %44

11:                                               ; preds = %7
  %12 = load i32, ptr @gPoolCount, align 4
  %13 = load i32, ptr @gPoolCapacity, align 4
  %14 = icmp eq i32 %12, %13
  br i1 %14, label %15, label %36

15:                                               ; preds = %11
  %16 = load i32, ptr @gPoolCapacity, align 4
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %18, label %19

18:                                               ; preds = %15
  br label %22

19:                                               ; preds = %15
  %20 = load i32, ptr @gPoolCapacity, align 4
  %21 = mul nsw i32 %20, 2
  br label %22

22:                                               ; preds = %19, %18
  %23 = phi i32 [ 64, %18 ], [ %21, %19 ]
  store i32 %23, ptr %3, align 4
  %24 = load ptr, ptr @gPoolItems, align 8
  %25 = load i32, ptr %3, align 4
  %26 = sext i32 %25 to i64
  %27 = mul i64 %26, 8
  %28 = call ptr @realloc(ptr noundef %24, i64 noundef %27) #17
  store ptr %28, ptr %4, align 8
  %29 = load ptr, ptr %4, align 8
  %30 = icmp ne ptr %29, null
  br i1 %30, label %33, label %31

31:                                               ; preds = %22
  %32 = call i32 (ptr, ...) @printf(ptr noundef @.str.31)
  call void @exit(i32 noundef 1) #12
  unreachable

33:                                               ; preds = %22
  %34 = load ptr, ptr %4, align 8
  store ptr %34, ptr @gPoolItems, align 8
  %35 = load i32, ptr %3, align 4
  store i32 %35, ptr @gPoolCapacity, align 4
  br label %36

36:                                               ; preds = %33, %11
  %37 = load ptr, ptr %2, align 8
  %38 = load ptr, ptr @gPoolItems, align 8
  %39 = load i32, ptr @gPoolCount, align 4
  %40 = sext i32 %39 to i64
  %41 = getelementptr inbounds ptr, ptr %38, i64 %40
  store ptr %37, ptr %41, align 8
  %42 = load i32, ptr @gPoolCount, align 4
  %43 = add nsw i32 %42, 1
  store i32 %43, ptr @gPoolCount, align 4
  br label %44

44:                                               ; preds = %36, %10
  ret void
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define void @Object_init(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define void @IO_init(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define void @String_init(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds nuw %struct.TString, ptr %3, i32 0, i32 3
  store ptr @gEmptyChars, ptr %4, align 8
  %5 = load ptr, ptr %2, align 8
  %6 = getelementptr inbounds nuw %struct.TString, ptr %5, i32 0, i32 2
  store i32 0, ptr %6, align 4
  ret void
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define void @List_init(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds nuw %struct.TList, ptr %3, i32 0, i32 2
  store i32 0, ptr %4, align 4
  %5 = load ptr, ptr %2, align 8
  %6 = getelementptr inbounds nuw %struct.TList, ptr %5, i32 0, i32 3
  store i32 0, ptr %6, align 8
  %7 = load ptr, ptr %2, align 8
  %8 = getelementptr inbounds nuw %struct.TList, ptr %7, i32 0, i32 4
  store ptr null, ptr %8, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define void @Integer_init(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds nuw %struct.TInteger, ptr %3, i32 0, i32 2
  store i64 0, ptr %4, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define void @File_init(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds nuw %struct.TFile, ptr %3, i32 0, i32 2
  store ptr null, ptr %4, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define void @Math_init(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define void @Process_init(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds nuw %struct.TProcess, ptr %3, i32 0, i32 2
  store ptr null, ptr %4, align 8
  %5 = load ptr, ptr %2, align 8
  %6 = getelementptr inbounds nuw %struct.TProcess, ptr %5, i32 0, i32 3
  store i32 0, ptr %6, align 8
  ret void
}

; Function Attrs: noreturn
declare void @exit(i32 noundef) #4

; Function Attrs: nounwind
declare ptr @__memcpy_chk(ptr noundef, ptr noundef, i64 noundef, i64 noundef) #2

; Function Attrs: allocsize(0,1)
declare ptr @calloc(i64 noundef, i64 noundef) #5

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define void @__cm_retain(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %4 = load ptr, ptr %2, align 8
  store ptr %4, ptr %3, align 8
  %5 = load ptr, ptr %3, align 8
  %6 = icmp ne ptr %5, null
  br i1 %6, label %7, label %17

7:                                                ; preds = %1
  %8 = load ptr, ptr %3, align 8
  %9 = getelementptr inbounds nuw %struct.TObject, ptr %8, i32 0, i32 1
  %10 = load i32, ptr %9, align 8
  %11 = icmp sgt i32 %10, 0
  br i1 %11, label %12, label %17

12:                                               ; preds = %7
  %13 = load ptr, ptr %3, align 8
  %14 = getelementptr inbounds nuw %struct.TObject, ptr %13, i32 0, i32 1
  %15 = load i32, ptr %14, align 8
  %16 = add nsw i32 %15, 1
  store i32 %16, ptr %14, align 8
  br label %17

17:                                               ; preds = %12, %7, %1
  ret void
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define void @__cm_release(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  call void @M6_Object_release(ptr noundef %3)
  ret void
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define internal void @object_free(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = icmp eq ptr %3, null
  br i1 %4, label %10, label %5

5:                                                ; preds = %1
  %6 = load ptr, ptr %2, align 8
  %7 = getelementptr inbounds nuw %struct.TObject, ptr %6, i32 0, i32 1
  %8 = load i32, ptr %7, align 8
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %10, label %11

10:                                               ; preds = %5, %1
  br label %18

11:                                               ; preds = %5
  %12 = load ptr, ptr %2, align 8
  call void @release_owned_buffers(ptr noundef %12)
  %13 = load ptr, ptr %2, align 8
  %14 = getelementptr inbounds nuw %struct.TObject, ptr %13, i32 0, i32 1
  store i32 0, ptr %14, align 8
  %15 = load i32, ptr @gLiveObjects, align 4
  %16 = sub nsw i32 %15, 1
  store i32 %16, ptr @gLiveObjects, align 4
  %17 = load ptr, ptr %2, align 8
  call void @free(ptr noundef %17)
  br label %18

18:                                               ; preds = %11, %10
  ret void
}

declare i64 @strtol(ptr noundef, ptr noundef, i32 noundef) #6

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define void @__cm_runtimeError(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr @gHandlers, align 8
  %4 = icmp ne ptr %3, null
  br i1 %4, label %5, label %8

5:                                                ; preds = %1
  %6 = load ptr, ptr %2, align 8
  %7 = call ptr @make_string(ptr noundef %6)
  call void @__cm_throw(ptr noundef %7)
  br label %8

8:                                                ; preds = %5, %1
  %9 = load ptr, ptr %2, align 8
  %10 = call i32 (ptr, ...) @printf(ptr noundef @.str.29, ptr noundef %9)
  call void @exit(i32 noundef 1) #12
  unreachable
}

; Function Attrs: nounwind
declare ptr @__strncpy_chk(ptr noundef, ptr noundef, i64 noundef, i64 noundef) #2

; Function Attrs: nounwind
declare ptr @__strncat_chk(ptr noundef, ptr noundef, i64 noundef, i64 noundef) #2

; Function Attrs: nounwind
declare i32 @strncmp(ptr noundef, ptr noundef, i64 noundef) #2

declare i32 @scanf(ptr noundef, ...) #6

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define internal ptr @make_string(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %4 = call ptr @__catmint_new(ptr noundef @RString)
  store ptr %4, ptr %3, align 8
  %5 = load ptr, ptr %3, align 8
  call void @String_init(ptr noundef %5)
  %6 = load ptr, ptr %2, align 8
  %7 = call i64 @strlen(ptr noundef %6) #13
  %8 = trunc i64 %7 to i32
  %9 = load ptr, ptr %3, align 8
  %10 = getelementptr inbounds nuw %struct.TString, ptr %9, i32 0, i32 2
  store i32 %8, ptr %10, align 4
  %11 = load ptr, ptr %3, align 8
  %12 = getelementptr inbounds nuw %struct.TString, ptr %11, i32 0, i32 2
  %13 = load i32, ptr %12, align 4
  %14 = sext i32 %13 to i64
  %15 = add i64 %14, 1
  %16 = call ptr @calloc(i64 noundef %15, i64 noundef 1) #14
  %17 = load ptr, ptr %3, align 8
  %18 = getelementptr inbounds nuw %struct.TString, ptr %17, i32 0, i32 3
  store ptr %16, ptr %18, align 8
  %19 = load ptr, ptr %3, align 8
  %20 = getelementptr inbounds nuw %struct.TString, ptr %19, i32 0, i32 3
  %21 = load ptr, ptr %20, align 8
  %22 = load ptr, ptr %2, align 8
  %23 = load ptr, ptr %3, align 8
  %24 = getelementptr inbounds nuw %struct.TString, ptr %23, i32 0, i32 3
  %25 = load ptr, ptr %24, align 8
  %26 = call i64 @llvm.objectsize.i64.p0(ptr %25, i1 false, i1 true, i1 false)
  %27 = call ptr @__strcpy_chk(ptr noundef %21, ptr noundef %22, i64 noundef %26) #13
  %28 = load ptr, ptr %3, align 8
  ret ptr %28
}

declare ptr @fgets(ptr noundef, i32 noundef, ptr noundef) #6

; Function Attrs: nounwind
declare i64 @strlen(ptr noundef) #2

declare i32 @fgetc(ptr noundef) #6

declare i32 @ungetc(i32 noundef, ptr noundef) #6

declare ptr @"\01_fopen"(ptr noundef, ptr noundef) #6

declare i64 @fread(ptr noundef, i64 noundef, i64 noundef, ptr noundef) #6

declare i32 @fclose(ptr noundef) #6

declare i64 @time(ptr noundef) #6

declare i64 @"\01_clock"() #6

declare i32 @clock_gettime(i32 noundef, ptr noundef) #6

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #7

declare ptr @localtime_r(ptr noundef, ptr noundef) #6

declare ptr @gmtime_r(ptr noundef, ptr noundef) #6

declare i32 @"\01_nanosleep"(ptr noundef, ptr noundef) #6

declare i32 @printf(ptr noundef, ...) #6

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define internal void @list_bounds(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %5 = load i32, ptr %4, align 4
  %6 = icmp slt i32 %5, 0
  br i1 %6, label %13, label %7

7:                                                ; preds = %2
  %8 = load i32, ptr %4, align 4
  %9 = load ptr, ptr %3, align 8
  %10 = getelementptr inbounds nuw %struct.TList, ptr %9, i32 0, i32 2
  %11 = load i32, ptr %10, align 4
  %12 = icmp sge i32 %8, %11
  br i1 %12, label %13, label %14

13:                                               ; preds = %7, %2
  call void @__cm_runtimeError(ptr noundef @.str.35)
  br label %14

14:                                               ; preds = %13, %7
  ret void
}

; Function Attrs: allocsize(1)
declare ptr @realloc(ptr noundef, i64 noundef) #8

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define void @__cm_checkNull(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = icmp eq ptr %3, null
  br i1 %4, label %5, label %6

5:                                                ; preds = %1
  call void @__cm_runtimeError(ptr noundef @.str.18)
  br label %6

6:                                                ; preds = %5, %1
  ret void
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @__cm_isType(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  %7 = load ptr, ptr %4, align 8
  %8 = icmp eq ptr %7, null
  br i1 %8, label %9, label %10

9:                                                ; preds = %2
  store i32 0, ptr %3, align 4
  br label %28

10:                                               ; preds = %2
  %11 = load ptr, ptr %4, align 8
  %12 = getelementptr inbounds nuw %struct.TObject, ptr %11, i32 0, i32 0
  %13 = load ptr, ptr %12, align 8
  store ptr %13, ptr %6, align 8
  br label %14

14:                                               ; preds = %23, %10
  %15 = load ptr, ptr %6, align 8
  %16 = icmp ne ptr %15, null
  br i1 %16, label %17, label %27

17:                                               ; preds = %14
  %18 = load ptr, ptr %6, align 8
  %19 = load ptr, ptr %5, align 8
  %20 = icmp eq ptr %18, %19
  br i1 %20, label %21, label %22

21:                                               ; preds = %17
  store i32 1, ptr %3, align 4
  br label %28

22:                                               ; preds = %17
  br label %23

23:                                               ; preds = %22
  %24 = load ptr, ptr %6, align 8
  %25 = getelementptr inbounds nuw %struct.__catmint_rtti, ptr %24, i32 0, i32 2
  %26 = load ptr, ptr %25, align 8
  store ptr %26, ptr %6, align 8
  br label %14, !llvm.loop !15

27:                                               ; preds = %14
  store i32 0, ptr %3, align 4
  br label %28

28:                                               ; preds = %27, %21, %9
  %29 = load i32, ptr %3, align 4
  ret i32 %29
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @__cm_cast(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  %8 = alloca [256 x i8], align 1
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  %9 = load ptr, ptr %4, align 8
  %10 = icmp eq ptr %9, null
  br i1 %10, label %11, label %12

11:                                               ; preds = %2
  store ptr null, ptr %3, align 8
  br label %45

12:                                               ; preds = %2
  %13 = load ptr, ptr %4, align 8
  %14 = getelementptr inbounds nuw %struct.TObject, ptr %13, i32 0, i32 0
  %15 = load ptr, ptr %14, align 8
  store ptr %15, ptr %6, align 8
  %16 = load ptr, ptr %6, align 8
  store ptr %16, ptr %7, align 8
  br label %17

17:                                               ; preds = %27, %12
  %18 = load ptr, ptr %7, align 8
  %19 = icmp ne ptr %18, null
  br i1 %19, label %20, label %31

20:                                               ; preds = %17
  %21 = load ptr, ptr %7, align 8
  %22 = load ptr, ptr %5, align 8
  %23 = icmp eq ptr %21, %22
  br i1 %23, label %24, label %26

24:                                               ; preds = %20
  %25 = load ptr, ptr %4, align 8
  store ptr %25, ptr %3, align 8
  br label %45

26:                                               ; preds = %20
  br label %27

27:                                               ; preds = %26
  %28 = load ptr, ptr %7, align 8
  %29 = getelementptr inbounds nuw %struct.__catmint_rtti, ptr %28, i32 0, i32 2
  %30 = load ptr, ptr %29, align 8
  store ptr %30, ptr %7, align 8
  br label %17, !llvm.loop !16

31:                                               ; preds = %17
  %32 = getelementptr inbounds [256 x i8], ptr %8, i64 0, i64 0
  %33 = load ptr, ptr %6, align 8
  %34 = getelementptr inbounds nuw %struct.__catmint_rtti, ptr %33, i32 0, i32 0
  %35 = load ptr, ptr %34, align 8
  %36 = getelementptr inbounds nuw %struct.TString, ptr %35, i32 0, i32 3
  %37 = load ptr, ptr %36, align 8
  %38 = load ptr, ptr %5, align 8
  %39 = getelementptr inbounds nuw %struct.__catmint_rtti, ptr %38, i32 0, i32 0
  %40 = load ptr, ptr %39, align 8
  %41 = getelementptr inbounds nuw %struct.TString, ptr %40, i32 0, i32 3
  %42 = load ptr, ptr %41, align 8
  %43 = call i32 (ptr, i64, i32, i64, ptr, ...) @__snprintf_chk(ptr noundef %32, i64 noundef 256, i32 noundef 0, i64 noundef 256, ptr noundef @.str.19, ptr noundef %37, ptr noundef %42)
  %44 = getelementptr inbounds [256 x i8], ptr %8, i64 0, i64 0
  call void @__cm_runtimeError(ptr noundef %44)
  store ptr null, ptr %3, align 8
  br label %45

45:                                               ; preds = %31, %24, %11
  %46 = load ptr, ptr %3, align 8
  ret ptr %46
}

declare i32 @__snprintf_chk(ptr noundef, i64 noundef, i32 noundef, i64 noundef, ptr noundef, ...) #6

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @__cm_boxLong(i64 noundef %0) #0 {
  %2 = alloca i64, align 8
  %3 = alloca ptr, align 8
  store i64 %0, ptr %2, align 8
  %4 = call ptr @__catmint_new(ptr noundef @RInteger)
  store ptr %4, ptr %3, align 8
  %5 = load ptr, ptr %3, align 8
  call void @Integer_init(ptr noundef %5)
  %6 = load i64, ptr %2, align 8
  %7 = load ptr, ptr %3, align 8
  %8 = getelementptr inbounds nuw %struct.TInteger, ptr %7, i32 0, i32 2
  store i64 %6, ptr %8, align 8
  %9 = load ptr, ptr %3, align 8
  ret ptr %9
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i64 @__cm_unboxLong(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca [256 x i8], align 1
  store ptr %0, ptr %2, align 8
  %4 = load ptr, ptr %2, align 8
  call void @__cm_checkNull(ptr noundef %4)
  %5 = load ptr, ptr %2, align 8
  %6 = getelementptr inbounds nuw %struct.TObject, ptr %5, i32 0, i32 0
  %7 = load ptr, ptr %6, align 8
  %8 = icmp ne ptr %7, @RInteger
  br i1 %8, label %9, label %20

9:                                                ; preds = %1
  %10 = getelementptr inbounds [256 x i8], ptr %3, i64 0, i64 0
  %11 = load ptr, ptr %2, align 8
  %12 = getelementptr inbounds nuw %struct.TObject, ptr %11, i32 0, i32 0
  %13 = load ptr, ptr %12, align 8
  %14 = getelementptr inbounds nuw %struct.__catmint_rtti, ptr %13, i32 0, i32 0
  %15 = load ptr, ptr %14, align 8
  %16 = getelementptr inbounds nuw %struct.TString, ptr %15, i32 0, i32 3
  %17 = load ptr, ptr %16, align 8
  %18 = call i32 (ptr, i64, i32, i64, ptr, ...) @__snprintf_chk(ptr noundef %10, i64 noundef 256, i32 noundef 0, i64 noundef 256, ptr noundef @.str.20, ptr noundef %17)
  %19 = getelementptr inbounds [256 x i8], ptr %3, i64 0, i64 0
  call void @__cm_runtimeError(ptr noundef %19)
  br label %20

20:                                               ; preds = %9, %1
  %21 = load ptr, ptr %2, align 8
  %22 = getelementptr inbounds nuw %struct.TInteger, ptr %21, i32 0, i32 2
  %23 = load i64, ptr %22, align 8
  ret i64 %23
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @__cm_equals(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  %8 = load ptr, ptr %4, align 8
  %9 = load ptr, ptr %5, align 8
  %10 = icmp eq ptr %8, %9
  br i1 %10, label %11, label %12

11:                                               ; preds = %2
  store i32 1, ptr %3, align 4
  br label %50

12:                                               ; preds = %2
  %13 = load ptr, ptr %4, align 8
  %14 = icmp eq ptr %13, null
  br i1 %14, label %18, label %15

15:                                               ; preds = %12
  %16 = load ptr, ptr %5, align 8
  %17 = icmp eq ptr %16, null
  br i1 %17, label %18, label %19

18:                                               ; preds = %15, %12
  store i32 0, ptr %3, align 4
  br label %50

19:                                               ; preds = %15
  %20 = load ptr, ptr %4, align 8
  %21 = getelementptr inbounds nuw %struct.TObject, ptr %20, i32 0, i32 0
  %22 = load ptr, ptr %21, align 8
  store ptr %22, ptr %6, align 8
  %23 = load ptr, ptr %5, align 8
  %24 = getelementptr inbounds nuw %struct.TObject, ptr %23, i32 0, i32 0
  %25 = load ptr, ptr %24, align 8
  store ptr %25, ptr %7, align 8
  %26 = load ptr, ptr %6, align 8
  %27 = load ptr, ptr %7, align 8
  %28 = icmp ne ptr %26, %27
  br i1 %28, label %29, label %30

29:                                               ; preds = %19
  store i32 0, ptr %3, align 4
  br label %50

30:                                               ; preds = %19
  %31 = load ptr, ptr %6, align 8
  %32 = icmp eq ptr %31, @RString
  br i1 %32, label %33, label %37

33:                                               ; preds = %30
  %34 = load ptr, ptr %4, align 8
  %35 = load ptr, ptr %5, align 8
  %36 = call i32 @M6_String_equal(ptr noundef %34, ptr noundef %35)
  store i32 %36, ptr %3, align 4
  br label %50

37:                                               ; preds = %30
  %38 = load ptr, ptr %6, align 8
  %39 = icmp eq ptr %38, @RInteger
  br i1 %39, label %40, label %49

40:                                               ; preds = %37
  %41 = load ptr, ptr %4, align 8
  %42 = getelementptr inbounds nuw %struct.TInteger, ptr %41, i32 0, i32 2
  %43 = load i64, ptr %42, align 8
  %44 = load ptr, ptr %5, align 8
  %45 = getelementptr inbounds nuw %struct.TInteger, ptr %44, i32 0, i32 2
  %46 = load i64, ptr %45, align 8
  %47 = icmp eq i64 %43, %46
  %48 = zext i1 %47 to i32
  store i32 %48, ptr %3, align 4
  br label %50

49:                                               ; preds = %37
  store i32 0, ptr %3, align 4
  br label %50

50:                                               ; preds = %49, %40, %33, %29, %18, %11
  %51 = load i32, ptr %3, align 4
  ret i32 %51
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @__cm_floatToString(double noundef %0) #0 {
  %2 = alloca double, align 8
  %3 = alloca [64 x i8], align 1
  store double %0, ptr %2, align 8
  %4 = getelementptr inbounds [64 x i8], ptr %3, i64 0, i64 0
  call void @llvm.memset.p0.i64(ptr align 1 %4, i8 0, i64 64, i1 false)
  %5 = getelementptr inbounds [64 x i8], ptr %3, i64 0, i64 0
  %6 = load double, ptr %2, align 8
  %7 = call i32 (ptr, i64, i32, i64, ptr, ...) @__snprintf_chk(ptr noundef %5, i64 noundef 64, i32 noundef 0, i64 noundef 64, ptr noundef @.str.21, double noundef %6)
  %8 = getelementptr inbounds [64 x i8], ptr %3, i64 0, i64 0
  %9 = call ptr @make_string(ptr noundef %8)
  ret ptr %9
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #9

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @__cm_intToString(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca [32 x i8], align 1
  store i32 %0, ptr %2, align 4
  %4 = getelementptr inbounds [32 x i8], ptr %3, i64 0, i64 0
  call void @llvm.memset.p0.i64(ptr align 1 %4, i8 0, i64 32, i1 false)
  %5 = getelementptr inbounds [32 x i8], ptr %3, i64 0, i64 0
  %6 = load i32, ptr %2, align 4
  %7 = call i32 (ptr, i64, i32, i64, ptr, ...) @__snprintf_chk(ptr noundef %5, i64 noundef 32, i32 noundef 0, i64 noundef 32, ptr noundef @.str.22, i32 noundef %6)
  %8 = getelementptr inbounds [32 x i8], ptr %3, i64 0, i64 0
  %9 = call ptr @make_string(ptr noundef %8)
  ret ptr %9
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @__cm_longToString(i64 noundef %0) #0 {
  %2 = alloca i64, align 8
  %3 = alloca [32 x i8], align 1
  store i64 %0, ptr %2, align 8
  %4 = getelementptr inbounds [32 x i8], ptr %3, i64 0, i64 0
  call void @llvm.memset.p0.i64(ptr align 1 %4, i8 0, i64 32, i1 false)
  %5 = getelementptr inbounds [32 x i8], ptr %3, i64 0, i64 0
  %6 = load i64, ptr %2, align 8
  %7 = call i32 (ptr, i64, i32, i64, ptr, ...) @__snprintf_chk(ptr noundef %5, i64 noundef 32, i32 noundef 0, i64 noundef 32, ptr noundef @.str.23, i64 noundef %6)
  %8 = getelementptr inbounds [32 x i8], ptr %3, i64 0, i64 0
  %9 = call ptr @make_string(ptr noundef %8)
  ret ptr %9
}

declare i32 @memcmp(ptr noundef, ptr noundef, i64 noundef) #6

; Function Attrs: nounwind willreturn memory(read)
declare i32 @isspace(i32 noundef) #10

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define internal ptr @string_mapped(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i8, align 1
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %8 = load ptr, ptr %3, align 8
  %9 = load ptr, ptr %3, align 8
  %10 = getelementptr inbounds nuw %struct.TString, ptr %9, i32 0, i32 2
  %11 = load i32, ptr %10, align 4
  %12 = call ptr @M6_String_substring(ptr noundef %8, i32 noundef 0, i32 noundef %11)
  store ptr %12, ptr %5, align 8
  store i32 0, ptr %6, align 4
  br label %13

13:                                               ; preds = %46, %2
  %14 = load i32, ptr %6, align 4
  %15 = load ptr, ptr %5, align 8
  %16 = getelementptr inbounds nuw %struct.TString, ptr %15, i32 0, i32 2
  %17 = load i32, ptr %16, align 4
  %18 = icmp slt i32 %14, %17
  br i1 %18, label %19, label %49

19:                                               ; preds = %13
  %20 = load ptr, ptr %5, align 8
  %21 = getelementptr inbounds nuw %struct.TString, ptr %20, i32 0, i32 3
  %22 = load ptr, ptr %21, align 8
  %23 = load i32, ptr %6, align 4
  %24 = sext i32 %23 to i64
  %25 = getelementptr inbounds i8, ptr %22, i64 %24
  %26 = load i8, ptr %25, align 1
  store i8 %26, ptr %7, align 1
  %27 = load i32, ptr %4, align 4
  %28 = icmp ne i32 %27, 0
  br i1 %28, label %29, label %33

29:                                               ; preds = %19
  %30 = load i8, ptr %7, align 1
  %31 = zext i8 %30 to i32
  %32 = call i32 @toupper(i32 noundef %31) #16
  br label %37

33:                                               ; preds = %19
  %34 = load i8, ptr %7, align 1
  %35 = zext i8 %34 to i32
  %36 = call i32 @tolower(i32 noundef %35) #16
  br label %37

37:                                               ; preds = %33, %29
  %38 = phi i32 [ %32, %29 ], [ %36, %33 ]
  %39 = trunc i32 %38 to i8
  %40 = load ptr, ptr %5, align 8
  %41 = getelementptr inbounds nuw %struct.TString, ptr %40, i32 0, i32 3
  %42 = load ptr, ptr %41, align 8
  %43 = load i32, ptr %6, align 4
  %44 = sext i32 %43 to i64
  %45 = getelementptr inbounds i8, ptr %42, i64 %44
  store i8 %39, ptr %45, align 1
  br label %46

46:                                               ; preds = %37
  %47 = load i32, ptr %6, align 4
  %48 = add nsw i32 %47, 1
  store i32 %48, ptr %6, align 4
  br label %13, !llvm.loop !17

49:                                               ; preds = %13
  %50 = load ptr, ptr %5, align 8
  ret ptr %50
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @M6_String_chr(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca [2 x i8], align 1
  store i32 %0, ptr %2, align 4
  %4 = load i32, ptr %2, align 4
  %5 = and i32 %4, 255
  %6 = trunc i32 %5 to i8
  %7 = getelementptr inbounds [2 x i8], ptr %3, i64 0, i64 0
  store i8 %6, ptr %7, align 1
  %8 = getelementptr inbounds [2 x i8], ptr %3, i64 0, i64 1
  store i8 0, ptr %8, align 1
  %9 = getelementptr inbounds [2 x i8], ptr %3, i64 0, i64 0
  %10 = call ptr @make_string(ptr noundef %9)
  ret ptr %10
}

declare double @"\01_strtod"(ptr noundef, ptr noundef) #6

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define void @__cm_setArgs(i32 noundef %0, ptr noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  store i32 %0, ptr %3, align 4
  store ptr %1, ptr %4, align 8
  %5 = load i32, ptr %3, align 4
  store i32 %5, ptr @gArgCount, align 4
  %6 = load ptr, ptr %4, align 8
  store ptr %6, ptr @gArgValues, align 8
  ret void
}

declare i32 @"\01_fputs"(ptr noundef, ptr noundef) #6

declare i64 @"\01_fwrite"(ptr noundef, i64 noundef, i64 noundef, ptr noundef) #6

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M4_File_exists(ptr noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  store ptr %0, ptr %3, align 8
  %5 = load ptr, ptr %3, align 8
  %6 = getelementptr inbounds nuw %struct.TString, ptr %5, i32 0, i32 3
  %7 = load ptr, ptr %6, align 8
  %8 = call ptr @"\01_fopen"(ptr noundef %7, ptr noundef @.str.14)
  store ptr %8, ptr %4, align 8
  %9 = load ptr, ptr %4, align 8
  %10 = icmp ne ptr %9, null
  br i1 %10, label %12, label %11

11:                                               ; preds = %1
  store i32 0, ptr %2, align 4
  br label %15

12:                                               ; preds = %1
  %13 = load ptr, ptr %4, align 8
  %14 = call i32 @fclose(ptr noundef %13)
  store i32 1, ptr %2, align 4
  br label %15

15:                                               ; preds = %12, %11
  %16 = load i32, ptr %2, align 4
  ret i32 %16
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M4_File_remove(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds nuw %struct.TString, ptr %3, i32 0, i32 3
  %5 = load ptr, ptr %4, align 8
  %6 = call i32 @remove(ptr noundef %5)
  %7 = icmp eq i32 %6, 0
  %8 = zext i1 %7 to i32
  ret i32 %8
}

declare i32 @remove(ptr noundef) #6

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define double @M4_Math_sqrt(double noundef %0) #0 {
  %2 = alloca double, align 8
  store double %0, ptr %2, align 8
  %3 = load double, ptr %2, align 8
  %4 = call double @llvm.sqrt.f64(double %3)
  ret double %4
}

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sqrt.f64(double) #11

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define double @M4_Math_pow(double noundef %0, double noundef %1) #0 {
  %3 = alloca double, align 8
  %4 = alloca double, align 8
  store double %0, ptr %3, align 8
  store double %1, ptr %4, align 8
  %5 = load double, ptr %3, align 8
  %6 = load double, ptr %4, align 8
  %7 = call double @llvm.pow.f64(double %5, double %6)
  ret double %7
}

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.pow.f64(double, double) #11

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define double @M4_Math_exp(double noundef %0) #0 {
  %2 = alloca double, align 8
  store double %0, ptr %2, align 8
  %3 = load double, ptr %2, align 8
  %4 = call double @llvm.exp.f64(double %3)
  ret double %4
}

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.exp.f64(double) #11

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define double @M4_Math_log(double noundef %0) #0 {
  %2 = alloca double, align 8
  store double %0, ptr %2, align 8
  %3 = load double, ptr %2, align 8
  %4 = call double @llvm.log.f64(double %3)
  ret double %4
}

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.log.f64(double) #11

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define double @M4_Math_log10(double noundef %0) #0 {
  %2 = alloca double, align 8
  store double %0, ptr %2, align 8
  %3 = load double, ptr %2, align 8
  %4 = call double @llvm.log10.f64(double %3)
  ret double %4
}

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.log10.f64(double) #11

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define double @M4_Math_sin(double noundef %0) #0 {
  %2 = alloca double, align 8
  store double %0, ptr %2, align 8
  %3 = load double, ptr %2, align 8
  %4 = call double @llvm.sin.f64(double %3)
  ret double %4
}

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sin.f64(double) #11

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define double @M4_Math_cos(double noundef %0) #0 {
  %2 = alloca double, align 8
  store double %0, ptr %2, align 8
  %3 = load double, ptr %2, align 8
  %4 = call double @llvm.cos.f64(double %3)
  ret double %4
}

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.cos.f64(double) #11

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define double @M4_Math_tan(double noundef %0) #0 {
  %2 = alloca double, align 8
  store double %0, ptr %2, align 8
  %3 = load double, ptr %2, align 8
  %4 = call double @llvm.tan.f64(double %3)
  ret double %4
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.tan.f64(double) #3

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define double @M4_Math_atan2(double noundef %0, double noundef %1) #0 {
  %3 = alloca double, align 8
  %4 = alloca double, align 8
  store double %0, ptr %3, align 8
  store double %1, ptr %4, align 8
  %5 = load double, ptr %3, align 8
  %6 = load double, ptr %4, align 8
  %7 = call double @llvm.atan2.f64(double %5, double %6)
  ret double %7
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.atan2.f64(double, double) #3

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define double @M4_Math_floor(double noundef %0) #0 {
  %2 = alloca double, align 8
  store double %0, ptr %2, align 8
  %3 = load double, ptr %2, align 8
  %4 = call double @llvm.floor.f64(double %3)
  ret double %4
}

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.floor.f64(double) #11

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define double @M4_Math_ceil(double noundef %0) #0 {
  %2 = alloca double, align 8
  store double %0, ptr %2, align 8
  %3 = load double, ptr %2, align 8
  %4 = call double @llvm.ceil.f64(double %3)
  ret double %4
}

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.ceil.f64(double) #11

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define double @M4_Math_round(double noundef %0) #0 {
  %2 = alloca double, align 8
  store double %0, ptr %2, align 8
  %3 = load double, ptr %2, align 8
  %4 = call double @llvm.round.f64(double %3)
  ret double %4
}

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.round.f64(double) #11

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define double @M4_Math_absf(double noundef %0) #0 {
  %2 = alloca double, align 8
  store double %0, ptr %2, align 8
  %3 = load double, ptr %2, align 8
  %4 = call double @llvm.fabs.f64(double %3)
  ret double %4
}

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fabs.f64(double) #11

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M4_Math_abs(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  %3 = load i32, ptr %2, align 4
  %4 = icmp slt i32 %3, 0
  br i1 %4, label %5, label %8

5:                                                ; preds = %1
  %6 = load i32, ptr %2, align 4
  %7 = sub nsw i32 0, %6
  br label %10

8:                                                ; preds = %1
  %9 = load i32, ptr %2, align 4
  br label %10

10:                                               ; preds = %8, %5
  %11 = phi i32 [ %7, %5 ], [ %9, %8 ]
  ret i32 %11
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M4_Math_min(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  store i32 %1, ptr %4, align 4
  %5 = load i32, ptr %3, align 4
  %6 = load i32, ptr %4, align 4
  %7 = icmp slt i32 %5, %6
  br i1 %7, label %8, label %10

8:                                                ; preds = %2
  %9 = load i32, ptr %3, align 4
  br label %12

10:                                               ; preds = %2
  %11 = load i32, ptr %4, align 4
  br label %12

12:                                               ; preds = %10, %8
  %13 = phi i32 [ %9, %8 ], [ %11, %10 ]
  ret i32 %13
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M4_Math_max(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  store i32 %1, ptr %4, align 4
  %5 = load i32, ptr %3, align 4
  %6 = load i32, ptr %4, align 4
  %7 = icmp sgt i32 %5, %6
  br i1 %7, label %8, label %10

8:                                                ; preds = %2
  %9 = load i32, ptr %3, align 4
  br label %12

10:                                               ; preds = %2
  %11 = load i32, ptr %4, align 4
  br label %12

12:                                               ; preds = %10, %8
  %13 = phi i32 [ %9, %8 ], [ %11, %10 ]
  ret i32 %13
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define double @M4_Math_pi() #0 {
  ret double 0x400921FB54442D18
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define double @M4_Math_e() #0 {
  ret double 0x4005BF0A8B145769
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define void @__cm_pushHandler(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %4 = call ptr @malloc(i64 noundef 24) #15
  store ptr %4, ptr %3, align 8
  %5 = load ptr, ptr %3, align 8
  %6 = icmp ne ptr %5, null
  br i1 %6, label %9, label %7

7:                                                ; preds = %1
  %8 = call i32 (ptr, ...) @printf(ptr noundef @.str.25)
  call void @exit(i32 noundef 1) #12
  unreachable

9:                                                ; preds = %1
  %10 = load ptr, ptr %2, align 8
  %11 = load ptr, ptr %3, align 8
  %12 = getelementptr inbounds nuw %struct.__cm_handler, ptr %11, i32 0, i32 0
  store ptr %10, ptr %12, align 8
  %13 = call i32 @__cm_poolDepth()
  %14 = load ptr, ptr %3, align 8
  %15 = getelementptr inbounds nuw %struct.__cm_handler, ptr %14, i32 0, i32 1
  store i32 %13, ptr %15, align 8
  %16 = load ptr, ptr @gHandlers, align 8
  %17 = load ptr, ptr %3, align 8
  %18 = getelementptr inbounds nuw %struct.__cm_handler, ptr %17, i32 0, i32 2
  store ptr %16, ptr %18, align 8
  %19 = load ptr, ptr %3, align 8
  store ptr %19, ptr @gHandlers, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @__cm_poolDepth() #0 {
  %1 = load i32, ptr @gPoolDepth, align 4
  ret i32 %1
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define void @__cm_popHandler() #0 {
  %1 = alloca ptr, align 8
  %2 = load ptr, ptr @gHandlers, align 8
  store ptr %2, ptr %1, align 8
  %3 = load ptr, ptr %1, align 8
  %4 = icmp ne ptr %3, null
  br i1 %4, label %6, label %5

5:                                                ; preds = %0
  br label %11

6:                                                ; preds = %0
  %7 = load ptr, ptr %1, align 8
  %8 = getelementptr inbounds nuw %struct.__cm_handler, ptr %7, i32 0, i32 2
  %9 = load ptr, ptr %8, align 8
  store ptr %9, ptr @gHandlers, align 8
  %10 = load ptr, ptr %1, align 8
  call void @free(ptr noundef %10)
  br label %11

11:                                               ; preds = %6, %5
  ret void
}

declare void @free(ptr noundef) #6

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define ptr @__cm_caught() #0 {
  %1 = load ptr, ptr @gThrown, align 8
  ret ptr %1
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define void @__cm_throw(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %5 = load ptr, ptr @gHandlers, align 8
  store ptr %5, ptr %3, align 8
  %6 = load ptr, ptr %2, align 8
  store ptr %6, ptr @gThrown, align 8
  %7 = load ptr, ptr %3, align 8
  %8 = icmp ne ptr %7, null
  br i1 %8, label %38, label %9

9:                                                ; preds = %1
  %10 = load ptr, ptr %2, align 8
  %11 = icmp ne ptr %10, null
  br i1 %11, label %12, label %22

12:                                               ; preds = %9
  %13 = load ptr, ptr %2, align 8
  %14 = getelementptr inbounds nuw %struct.TObject, ptr %13, i32 0, i32 0
  %15 = load ptr, ptr %14, align 8
  %16 = icmp eq ptr %15, @RString
  br i1 %16, label %17, label %22

17:                                               ; preds = %12
  %18 = load ptr, ptr %2, align 8
  %19 = getelementptr inbounds nuw %struct.TString, ptr %18, i32 0, i32 3
  %20 = load ptr, ptr %19, align 8
  %21 = call i32 (ptr, ...) @printf(ptr noundef @.str.26, ptr noundef %20)
  br label %37

22:                                               ; preds = %12, %9
  %23 = load ptr, ptr %2, align 8
  %24 = icmp ne ptr %23, null
  br i1 %24, label %25, label %34

25:                                               ; preds = %22
  %26 = load ptr, ptr %2, align 8
  %27 = getelementptr inbounds nuw %struct.TObject, ptr %26, i32 0, i32 0
  %28 = load ptr, ptr %27, align 8
  %29 = getelementptr inbounds nuw %struct.__catmint_rtti, ptr %28, i32 0, i32 0
  %30 = load ptr, ptr %29, align 8
  %31 = getelementptr inbounds nuw %struct.TString, ptr %30, i32 0, i32 3
  %32 = load ptr, ptr %31, align 8
  %33 = call i32 (ptr, ...) @printf(ptr noundef @.str.27, ptr noundef %32)
  br label %36

34:                                               ; preds = %22
  %35 = call i32 (ptr, ...) @printf(ptr noundef @.str.28)
  br label %36

36:                                               ; preds = %34, %25
  br label %37

37:                                               ; preds = %36, %17
  call void @exit(i32 noundef 1) #12
  unreachable

38:                                               ; preds = %1
  %39 = load ptr, ptr %3, align 8
  %40 = getelementptr inbounds nuw %struct.__cm_handler, ptr %39, i32 0, i32 0
  %41 = load ptr, ptr %40, align 8
  store ptr %41, ptr %4, align 8
  %42 = load ptr, ptr %3, align 8
  %43 = getelementptr inbounds nuw %struct.__cm_handler, ptr %42, i32 0, i32 2
  %44 = load ptr, ptr %43, align 8
  store ptr %44, ptr @gHandlers, align 8
  %45 = load ptr, ptr %3, align 8
  %46 = getelementptr inbounds nuw %struct.__cm_handler, ptr %45, i32 0, i32 1
  %47 = load i32, ptr %46, align 8
  call void @__cm_poolUnwind(i32 noundef %47)
  %48 = load ptr, ptr %3, align 8
  call void @free(ptr noundef %48)
  %49 = load ptr, ptr %4, align 8
  %50 = getelementptr inbounds [48 x i32], ptr %49, i64 0, i64 0
  call void @longjmp(ptr noundef %50, i32 noundef 1) #12
  unreachable
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define void @__cm_poolUnwind(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  br label %3

3:                                                ; preds = %7, %1
  %4 = load i32, ptr @gPoolDepth, align 4
  %5 = load i32, ptr %2, align 4
  %6 = icmp sgt i32 %4, %5
  br i1 %6, label %7, label %8

7:                                                ; preds = %3
  call void @__cm_poolPop()
  br label %3, !llvm.loop !18

8:                                                ; preds = %3
  ret void
}

; Function Attrs: noreturn
declare void @longjmp(ptr noundef, i32 noundef) #4

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define void @__cm_poolPush() #0 {
  %1 = alloca i32, align 4
  %2 = alloca ptr, align 8
  %3 = load i32, ptr @gPoolDepth, align 4
  %4 = load i32, ptr @gPoolMarkCapacity, align 4
  %5 = icmp eq i32 %3, %4
  br i1 %5, label %6, label %27

6:                                                ; preds = %0
  %7 = load i32, ptr @gPoolMarkCapacity, align 4
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %9, label %10

9:                                                ; preds = %6
  br label %13

10:                                               ; preds = %6
  %11 = load i32, ptr @gPoolMarkCapacity, align 4
  %12 = mul nsw i32 %11, 2
  br label %13

13:                                               ; preds = %10, %9
  %14 = phi i32 [ 32, %9 ], [ %12, %10 ]
  store i32 %14, ptr %1, align 4
  %15 = load ptr, ptr @gPoolMarks, align 8
  %16 = load i32, ptr %1, align 4
  %17 = sext i32 %16 to i64
  %18 = mul i64 %17, 4
  %19 = call ptr @realloc(ptr noundef %15, i64 noundef %18) #17
  store ptr %19, ptr %2, align 8
  %20 = load ptr, ptr %2, align 8
  %21 = icmp ne ptr %20, null
  br i1 %21, label %24, label %22

22:                                               ; preds = %13
  %23 = call i32 (ptr, ...) @printf(ptr noundef @.str.30)
  call void @exit(i32 noundef 1) #12
  unreachable

24:                                               ; preds = %13
  %25 = load ptr, ptr %2, align 8
  store ptr %25, ptr @gPoolMarks, align 8
  %26 = load i32, ptr %1, align 4
  store i32 %26, ptr @gPoolMarkCapacity, align 4
  br label %27

27:                                               ; preds = %24, %0
  %28 = load i32, ptr @gPoolCount, align 4
  %29 = load ptr, ptr @gPoolMarks, align 8
  %30 = load i32, ptr @gPoolDepth, align 4
  %31 = sext i32 %30 to i64
  %32 = getelementptr inbounds i32, ptr %29, i64 %31
  store i32 %28, ptr %32, align 4
  %33 = load i32, ptr @gPoolDepth, align 4
  %34 = add nsw i32 %33, 1
  store i32 %34, ptr @gPoolDepth, align 4
  ret void
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define void @__cm_poolPop() #0 {
  %1 = alloca i32, align 4
  %2 = alloca ptr, align 8
  %3 = load i32, ptr @gPoolDepth, align 4
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %5, label %6

5:                                                ; preds = %0
  br label %28

6:                                                ; preds = %0
  %7 = load i32, ptr @gPoolDepth, align 4
  %8 = sub nsw i32 %7, 1
  store i32 %8, ptr @gPoolDepth, align 4
  %9 = load ptr, ptr @gPoolMarks, align 8
  %10 = load i32, ptr @gPoolDepth, align 4
  %11 = sext i32 %10 to i64
  %12 = getelementptr inbounds i32, ptr %9, i64 %11
  %13 = load i32, ptr %12, align 4
  store i32 %13, ptr %1, align 4
  br label %14

14:                                               ; preds = %18, %6
  %15 = load i32, ptr @gPoolCount, align 4
  %16 = load i32, ptr %1, align 4
  %17 = icmp sgt i32 %15, %16
  br i1 %17, label %18, label %28

18:                                               ; preds = %14
  %19 = load ptr, ptr @gPoolItems, align 8
  %20 = load i32, ptr @gPoolCount, align 4
  %21 = sub nsw i32 %20, 1
  %22 = sext i32 %21 to i64
  %23 = getelementptr inbounds ptr, ptr %19, i64 %22
  %24 = load ptr, ptr %23, align 8
  store ptr %24, ptr %2, align 8
  %25 = load i32, ptr @gPoolCount, align 4
  %26 = sub nsw i32 %25, 1
  store i32 %26, ptr @gPoolCount, align 4
  %27 = load ptr, ptr %2, align 8
  call void @__cm_release(ptr noundef %27)
  br label %14, !llvm.loop !19

28:                                               ; preds = %5, %14
  ret void
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M7_Process_run(ptr noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  %5 = load ptr, ptr %3, align 8
  %6 = getelementptr inbounds nuw %struct.TString, ptr %5, i32 0, i32 3
  %7 = load ptr, ptr %6, align 8
  %8 = call i32 @"\01_system"(ptr noundef %7)
  store i32 %8, ptr %4, align 4
  %9 = load i32, ptr %4, align 4
  %10 = icmp eq i32 %9, -1
  br i1 %10, label %11, label %12

11:                                               ; preds = %1
  store i32 -1, ptr %2, align 4
  br label %15

12:                                               ; preds = %1
  %13 = load i32, ptr %4, align 4
  %14 = call i32 @exit_status(i32 noundef %13)
  store i32 %14, ptr %2, align 4
  br label %15

15:                                               ; preds = %12, %11
  %16 = load i32, ptr %2, align 4
  ret i32 %16
}

declare i32 @"\01_system"(ptr noundef) #6

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define internal i32 @exit_status(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  %4 = load i32, ptr %3, align 4
  %5 = and i32 %4, 127
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %7, label %11

7:                                                ; preds = %1
  %8 = load i32, ptr %3, align 4
  %9 = ashr i32 %8, 8
  %10 = and i32 %9, 255
  store i32 %10, ptr %2, align 4
  br label %24

11:                                               ; preds = %1
  %12 = load i32, ptr %3, align 4
  %13 = and i32 %12, 127
  %14 = icmp ne i32 %13, 127
  br i1 %14, label %15, label %23

15:                                               ; preds = %11
  %16 = load i32, ptr %3, align 4
  %17 = and i32 %16, 127
  %18 = icmp ne i32 %17, 0
  br i1 %18, label %19, label %23

19:                                               ; preds = %15
  %20 = load i32, ptr %3, align 4
  %21 = and i32 %20, 127
  %22 = add nsw i32 128, %21
  store i32 %22, ptr %2, align 4
  br label %24

23:                                               ; preds = %15, %11
  store i32 -1, ptr %2, align 4
  br label %24

24:                                               ; preds = %23, %19, %7
  %25 = load i32, ptr %2, align 4
  ret i32 %25
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M7_Process_spawn(ptr noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  %5 = call i32 @fork()
  store i32 %5, ptr %4, align 4
  %6 = load i32, ptr %4, align 4
  %7 = icmp slt i32 %6, 0
  br i1 %7, label %8, label %9

8:                                                ; preds = %1
  store i32 0, ptr %2, align 4
  br label %19

9:                                                ; preds = %1
  %10 = load i32, ptr %4, align 4
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %12, label %17

12:                                               ; preds = %9
  %13 = load ptr, ptr %3, align 8
  %14 = getelementptr inbounds nuw %struct.TString, ptr %13, i32 0, i32 3
  %15 = load ptr, ptr %14, align 8
  %16 = call i32 (ptr, ptr, ...) @execl(ptr noundef @.str.32, ptr noundef @.str.33, ptr noundef @.str.34, ptr noundef %15, ptr noundef null)
  call void @_exit(i32 noundef 127) #12
  unreachable

17:                                               ; preds = %9
  %18 = load i32, ptr %4, align 4
  store i32 %18, ptr %2, align 4
  br label %19

19:                                               ; preds = %17, %8
  %20 = load i32, ptr %2, align 4
  ret i32 %20
}

declare i32 @fork() #6

declare i32 @execl(ptr noundef, ptr noundef, ...) #6

; Function Attrs: noreturn
declare void @_exit(i32 noundef) #4

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M7_Process_wait(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  store i32 0, ptr %4, align 4
  %5 = load i32, ptr %3, align 4
  %6 = icmp sle i32 %5, 0
  br i1 %6, label %7, label %8

7:                                                ; preds = %1
  store i32 -1, ptr %2, align 4
  br label %16

8:                                                ; preds = %1
  %9 = load i32, ptr %3, align 4
  %10 = call i32 @"\01_waitpid"(i32 noundef %9, ptr noundef %4, i32 noundef 0)
  %11 = icmp slt i32 %10, 0
  br i1 %11, label %12, label %13

12:                                               ; preds = %8
  store i32 -1, ptr %2, align 4
  br label %16

13:                                               ; preds = %8
  %14 = load i32, ptr %4, align 4
  %15 = call i32 @exit_status(i32 noundef %14)
  store i32 %15, ptr %2, align 4
  br label %16

16:                                               ; preds = %13, %12, %7
  %17 = load i32, ptr %2, align 4
  ret i32 %17
}

declare i32 @"\01_waitpid"(i32 noundef, ptr noundef, i32 noundef) #6

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @M7_Process_pid() #0 {
  %1 = call i32 @getpid()
  ret i32 %1
}

declare i32 @getpid() #6

declare i32 @pclose(ptr noundef) #6

declare ptr @"\01_popen"(ptr noundef, ptr noundef) #6

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define internal void @release_owned_buffers(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %8 = load ptr, ptr %2, align 8
  %9 = getelementptr inbounds nuw %struct.TObject, ptr %8, i32 0, i32 0
  %10 = load ptr, ptr %9, align 8
  %11 = icmp eq ptr %10, @RString
  br i1 %11, label %12, label %32

12:                                               ; preds = %1
  %13 = load ptr, ptr %2, align 8
  store ptr %13, ptr %3, align 8
  %14 = load ptr, ptr %3, align 8
  %15 = getelementptr inbounds nuw %struct.TString, ptr %14, i32 0, i32 3
  %16 = load ptr, ptr %15, align 8
  %17 = icmp ne ptr %16, null
  br i1 %17, label %18, label %27

18:                                               ; preds = %12
  %19 = load ptr, ptr %3, align 8
  %20 = getelementptr inbounds nuw %struct.TString, ptr %19, i32 0, i32 3
  %21 = load ptr, ptr %20, align 8
  %22 = icmp ne ptr %21, @gEmptyChars
  br i1 %22, label %23, label %27

23:                                               ; preds = %18
  %24 = load ptr, ptr %3, align 8
  %25 = getelementptr inbounds nuw %struct.TString, ptr %24, i32 0, i32 3
  %26 = load ptr, ptr %25, align 8
  call void @free(ptr noundef %26)
  br label %27

27:                                               ; preds = %23, %18, %12
  %28 = load ptr, ptr %3, align 8
  %29 = getelementptr inbounds nuw %struct.TString, ptr %28, i32 0, i32 3
  store ptr @gEmptyChars, ptr %29, align 8
  %30 = load ptr, ptr %3, align 8
  %31 = getelementptr inbounds nuw %struct.TString, ptr %30, i32 0, i32 2
  store i32 0, ptr %31, align 4
  br label %107

32:                                               ; preds = %1
  %33 = load ptr, ptr %2, align 8
  %34 = getelementptr inbounds nuw %struct.TObject, ptr %33, i32 0, i32 0
  %35 = load ptr, ptr %34, align 8
  %36 = icmp eq ptr %35, @RList
  br i1 %36, label %37, label %66

37:                                               ; preds = %32
  %38 = load ptr, ptr %2, align 8
  store ptr %38, ptr %4, align 8
  store i32 0, ptr %5, align 4
  br label %39

39:                                               ; preds = %53, %37
  %40 = load i32, ptr %5, align 4
  %41 = load ptr, ptr %4, align 8
  %42 = getelementptr inbounds nuw %struct.TList, ptr %41, i32 0, i32 2
  %43 = load i32, ptr %42, align 4
  %44 = icmp slt i32 %40, %43
  br i1 %44, label %45, label %56

45:                                               ; preds = %39
  %46 = load ptr, ptr %4, align 8
  %47 = getelementptr inbounds nuw %struct.TList, ptr %46, i32 0, i32 4
  %48 = load ptr, ptr %47, align 8
  %49 = load i32, ptr %5, align 4
  %50 = sext i32 %49 to i64
  %51 = getelementptr inbounds ptr, ptr %48, i64 %50
  %52 = load ptr, ptr %51, align 8
  call void @__cm_release(ptr noundef %52)
  br label %53

53:                                               ; preds = %45
  %54 = load i32, ptr %5, align 4
  %55 = add nsw i32 %54, 1
  store i32 %55, ptr %5, align 4
  br label %39, !llvm.loop !20

56:                                               ; preds = %39
  %57 = load ptr, ptr %4, align 8
  %58 = getelementptr inbounds nuw %struct.TList, ptr %57, i32 0, i32 4
  %59 = load ptr, ptr %58, align 8
  call void @free(ptr noundef %59)
  %60 = load ptr, ptr %4, align 8
  %61 = getelementptr inbounds nuw %struct.TList, ptr %60, i32 0, i32 4
  store ptr null, ptr %61, align 8
  %62 = load ptr, ptr %4, align 8
  %63 = getelementptr inbounds nuw %struct.TList, ptr %62, i32 0, i32 2
  store i32 0, ptr %63, align 4
  %64 = load ptr, ptr %4, align 8
  %65 = getelementptr inbounds nuw %struct.TList, ptr %64, i32 0, i32 3
  store i32 0, ptr %65, align 8
  br label %106

66:                                               ; preds = %32
  %67 = load ptr, ptr %2, align 8
  %68 = getelementptr inbounds nuw %struct.TObject, ptr %67, i32 0, i32 0
  %69 = load ptr, ptr %68, align 8
  %70 = icmp eq ptr %69, @RFile
  br i1 %70, label %71, label %85

71:                                               ; preds = %66
  %72 = load ptr, ptr %2, align 8
  store ptr %72, ptr %6, align 8
  %73 = load ptr, ptr %6, align 8
  %74 = getelementptr inbounds nuw %struct.TFile, ptr %73, i32 0, i32 2
  %75 = load ptr, ptr %74, align 8
  %76 = icmp ne ptr %75, null
  br i1 %76, label %77, label %84

77:                                               ; preds = %71
  %78 = load ptr, ptr %6, align 8
  %79 = getelementptr inbounds nuw %struct.TFile, ptr %78, i32 0, i32 2
  %80 = load ptr, ptr %79, align 8
  %81 = call i32 @fclose(ptr noundef %80)
  %82 = load ptr, ptr %6, align 8
  %83 = getelementptr inbounds nuw %struct.TFile, ptr %82, i32 0, i32 2
  store ptr null, ptr %83, align 8
  br label %84

84:                                               ; preds = %77, %71
  br label %105

85:                                               ; preds = %66
  %86 = load ptr, ptr %2, align 8
  %87 = getelementptr inbounds nuw %struct.TObject, ptr %86, i32 0, i32 0
  %88 = load ptr, ptr %87, align 8
  %89 = icmp eq ptr %88, @RProcess
  br i1 %89, label %90, label %104

90:                                               ; preds = %85
  %91 = load ptr, ptr %2, align 8
  store ptr %91, ptr %7, align 8
  %92 = load ptr, ptr %7, align 8
  %93 = getelementptr inbounds nuw %struct.TProcess, ptr %92, i32 0, i32 2
  %94 = load ptr, ptr %93, align 8
  %95 = icmp ne ptr %94, null
  br i1 %95, label %96, label %103

96:                                               ; preds = %90
  %97 = load ptr, ptr %7, align 8
  %98 = getelementptr inbounds nuw %struct.TProcess, ptr %97, i32 0, i32 2
  %99 = load ptr, ptr %98, align 8
  %100 = call i32 @pclose(ptr noundef %99)
  %101 = load ptr, ptr %7, align 8
  %102 = getelementptr inbounds nuw %struct.TProcess, ptr %101, i32 0, i32 2
  store ptr null, ptr %102, align 8
  br label %103

103:                                              ; preds = %96, %90
  br label %104

104:                                              ; preds = %103, %85
  br label %105

105:                                              ; preds = %104, %84
  br label %106

106:                                              ; preds = %105, %56
  br label %107

107:                                              ; preds = %106, %27
  ret void
}

; Function Attrs: nounwind
declare ptr @__strcpy_chk(ptr noundef, ptr noundef, i64 noundef) #2

; Function Attrs: nounwind willreturn memory(read)
declare i32 @toupper(i32 noundef) #10

; Function Attrs: nounwind willreturn memory(read)
declare i32 @tolower(i32 noundef) #10

attributes #0 = { noinline nounwind optnone ssp uwtable(sync) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+altnzcv,+ccdp,+ccidx,+ccpp,+complxnum,+crc,+dit,+dotprod,+flagm,+fp-armv8,+fp16fml,+fptoint,+fullfp16,+jsconv,+lse,+neon,+pauth,+perfmon,+predres,+ras,+rcpc,+rdm,+sb,+sha2,+sha3,+specrestrict,+ssbs,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8a" }
attributes #1 = { allocsize(0) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+altnzcv,+ccdp,+ccidx,+ccpp,+complxnum,+crc,+dit,+dotprod,+flagm,+fp-armv8,+fp16fml,+fptoint,+fullfp16,+jsconv,+lse,+neon,+pauth,+perfmon,+predres,+ras,+rcpc,+rdm,+sb,+sha2,+sha3,+specrestrict,+ssbs,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8a" }
attributes #2 = { nounwind "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+altnzcv,+ccdp,+ccidx,+ccpp,+complxnum,+crc,+dit,+dotprod,+flagm,+fp-armv8,+fp16fml,+fptoint,+fullfp16,+jsconv,+lse,+neon,+pauth,+perfmon,+predres,+ras,+rcpc,+rdm,+sb,+sha2,+sha3,+specrestrict,+ssbs,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8a" }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { noreturn "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+altnzcv,+ccdp,+ccidx,+ccpp,+complxnum,+crc,+dit,+dotprod,+flagm,+fp-armv8,+fp16fml,+fptoint,+fullfp16,+jsconv,+lse,+neon,+pauth,+perfmon,+predres,+ras,+rcpc,+rdm,+sb,+sha2,+sha3,+specrestrict,+ssbs,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8a" }
attributes #5 = { allocsize(0,1) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+altnzcv,+ccdp,+ccidx,+ccpp,+complxnum,+crc,+dit,+dotprod,+flagm,+fp-armv8,+fp16fml,+fptoint,+fullfp16,+jsconv,+lse,+neon,+pauth,+perfmon,+predres,+ras,+rcpc,+rdm,+sb,+sha2,+sha3,+specrestrict,+ssbs,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8a" }
attributes #6 = { "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+altnzcv,+ccdp,+ccidx,+ccpp,+complxnum,+crc,+dit,+dotprod,+flagm,+fp-armv8,+fp16fml,+fptoint,+fullfp16,+jsconv,+lse,+neon,+pauth,+perfmon,+predres,+ras,+rcpc,+rdm,+sb,+sha2,+sha3,+specrestrict,+ssbs,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8a" }
attributes #7 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #8 = { allocsize(1) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+altnzcv,+ccdp,+ccidx,+ccpp,+complxnum,+crc,+dit,+dotprod,+flagm,+fp-armv8,+fp16fml,+fptoint,+fullfp16,+jsconv,+lse,+neon,+pauth,+perfmon,+predres,+ras,+rcpc,+rdm,+sb,+sha2,+sha3,+specrestrict,+ssbs,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8a" }
attributes #9 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #10 = { nounwind willreturn memory(read) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+altnzcv,+ccdp,+ccidx,+ccpp,+complxnum,+crc,+dit,+dotprod,+flagm,+fp-armv8,+fp16fml,+fptoint,+fullfp16,+jsconv,+lse,+neon,+pauth,+perfmon,+predres,+ras,+rcpc,+rdm,+sb,+sha2,+sha3,+specrestrict,+ssbs,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8a" }
attributes #11 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
attributes #12 = { noreturn }
attributes #13 = { nounwind }
attributes #14 = { allocsize(0,1) }
attributes #15 = { allocsize(0) }
attributes #16 = { nounwind willreturn memory(read) }
attributes #17 = { allocsize(1) }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 5]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 1}
!4 = !{i32 7, !"frame-pointer", i32 4}
!5 = !{!"Homebrew clang version 22.1.8"}
!6 = distinct !{!6, !7}
!7 = !{!"llvm.loop.mustprogress"}
!8 = distinct !{!8, !7}
!9 = distinct !{!9, !7}
!10 = distinct !{!10, !7}
!11 = distinct !{!11, !7}
!12 = distinct !{!12, !7}
!13 = distinct !{!13, !7}
!14 = distinct !{!14, !7}
!15 = distinct !{!15, !7}
!16 = distinct !{!16, !7}
!17 = distinct !{!17, !7}
!18 = distinct !{!18, !7}
!19 = distinct !{!19, !7}
!20 = distinct !{!20, !7}
