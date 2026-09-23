; ModuleID = 'runtime.c'
source_filename = "runtime.c"

%struct.TString = type { ptr, i32, i32, ptr }
%struct.timespec = type { i64, i64 }
%struct.TInteger = type { ptr, i32, i64 }
%struct.__cm_worker = type { ptr, ptr, i64, i64, i32 }
%struct._RuneLocale = type { [8 x i8], [32 x i8], ptr, ptr, i32, [256 x i32], [256 x i32], [256 x i32], %struct._RuneRange, %struct._RuneRange, %struct._RuneRange, ptr, i32, i32, ptr }
%struct._RuneRange = type { i32, ptr }
%struct.tm = type { i32, i32, i32, i32, i32, i32, i32, i32, i32, i64, ptr }

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
@.str.8 = private unnamed_addr constant [7 x i8] c"Worker\00", align 1
@NWorker = global %struct.TString { ptr @RString, i32 0, i32 6, ptr @.str.8 }, align 8
@.str.9 = private unnamed_addr constant [6 x i8] c"Bytes\00", align 1
@NBytes = global %struct.TString { ptr @RString, i32 0, i32 5, ptr @.str.9 }, align 8
@.str.10 = private unnamed_addr constant [5 x i8] c"Ints\00", align 1
@NInts = global %struct.TString { ptr @RString, i32 0, i32 4, ptr @.str.10 }, align 8
@.str.11 = private unnamed_addr constant [7 x i8] c"Floats\00", align 1
@NFloats = global %struct.TString { ptr @RString, i32 0, i32 6, ptr @.str.11 }, align 8
@RObject = global { ptr, i32, [4 x i8], ptr, ptr, [6 x ptr] } { ptr @NObject, i32 16, [4 x i8] zeroinitializer, ptr null, ptr null, [6 x ptr] [ptr @M6_Object_abort, ptr @M6_Object_typeName, ptr @M6_Object_copy, ptr @M6_Object_retain, ptr @M6_Object_release, ptr @M6_Object_refs] }, align 8
@RString = global { ptr, i32, [4 x i8], ptr, ptr, [19 x ptr] } { ptr @NString, i32 24, [4 x i8] zeroinitializer, ptr @RObject, ptr null, [19 x ptr] [ptr @M6_Object_abort, ptr @M6_Object_typeName, ptr @M6_Object_copy, ptr @M6_Object_retain, ptr @M6_Object_release, ptr @M6_Object_refs, ptr @M6_String_length, ptr @M6_String_toInt, ptr @M6_String_substring, ptr @M6_String_concat, ptr @M6_String_equal, ptr @M6_String_at, ptr @M6_String_indexOf, ptr @M6_String_trim, ptr @M6_String_upper, ptr @M6_String_lower, ptr @M6_String_split, ptr @M6_String_replace, ptr @M6_String_toFloat] }, align 8
@RIO = local_unnamed_addr global { ptr, i32, [4 x i8], ptr, ptr, [20 x ptr] } { ptr @NIO, i32 16, [4 x i8] zeroinitializer, ptr @RObject, ptr null, [20 x ptr] [ptr @M6_Object_abort, ptr @M6_Object_typeName, ptr @M6_Object_copy, ptr @M6_Object_retain, ptr @M6_Object_release, ptr @M6_Object_refs, ptr @M2_IO_in, ptr @M2_IO_out, ptr @M2_IO_readLine, ptr @M2_IO_eof, ptr @M2_IO_entropy, ptr @M2_IO_ticks, ptr @M2_IO_epoch, ptr @M2_IO_localOffset, ptr @M2_IO_sleep, ptr @M2_IO_args, ptr @M2_IO_arg, ptr @M2_IO_err, ptr @M2_IO_exit, ptr @M2_IO_allocated] }, align 8
@RFile = global { ptr, i32, [4 x i8], ptr, ptr, [13 x ptr] } { ptr @NFile, i32 24, [4 x i8] zeroinitializer, ptr @RObject, ptr null, [13 x ptr] [ptr @M6_Object_abort, ptr @M6_Object_typeName, ptr @M6_Object_copy, ptr @M6_Object_retain, ptr @M6_Object_release, ptr @M6_Object_refs, ptr @M4_File_open, ptr @M4_File_readLine, ptr @M4_File_readAll, ptr @M4_File_write, ptr @M4_File_eof, ptr @M4_File_close, ptr @M4_File_isOpen] }, align 8
@RMath = local_unnamed_addr global { ptr, i32, [4 x i8], ptr, ptr, [6 x ptr] } { ptr @NMath, i32 16, [4 x i8] zeroinitializer, ptr @RObject, ptr null, [6 x ptr] [ptr @M6_Object_abort, ptr @M6_Object_typeName, ptr @M6_Object_copy, ptr @M6_Object_retain, ptr @M6_Object_release, ptr @M6_Object_refs] }, align 8
@RWorker = local_unnamed_addr global { ptr, i32, [4 x i8], ptr, ptr, [6 x ptr] } { ptr @NWorker, i32 16, [4 x i8] zeroinitializer, ptr @RObject, ptr null, [6 x ptr] [ptr @M6_Object_abort, ptr @M6_Object_typeName, ptr @M6_Object_copy, ptr @M6_Object_retain, ptr @M6_Object_release, ptr @M6_Object_refs] }, align 8
@RBytes = global { ptr, i32, [4 x i8], ptr, ptr, [10 x ptr] } { ptr @NBytes, i32 24, [4 x i8] zeroinitializer, ptr @RObject, ptr null, [10 x ptr] [ptr @M6_Object_abort, ptr @M6_Object_typeName, ptr @M6_Object_copy, ptr @M6_Object_retain, ptr @M6_Object_release, ptr @M6_Object_refs, ptr @M5_Bytes_len, ptr @M5_Bytes_get, ptr @M5_Bytes_set, ptr @M5_Bytes_fill] }, align 8
@RInts = global { ptr, i32, [4 x i8], ptr, ptr, [10 x ptr] } { ptr @NInts, i32 24, [4 x i8] zeroinitializer, ptr @RObject, ptr null, [10 x ptr] [ptr @M6_Object_abort, ptr @M6_Object_typeName, ptr @M6_Object_copy, ptr @M6_Object_retain, ptr @M6_Object_release, ptr @M6_Object_refs, ptr @M4_Ints_len, ptr @M4_Ints_get, ptr @M4_Ints_set, ptr @M4_Ints_fill] }, align 8
@RFloats = global { ptr, i32, [4 x i8], ptr, ptr, [10 x ptr] } { ptr @NFloats, i32 24, [4 x i8] zeroinitializer, ptr @RObject, ptr null, [10 x ptr] [ptr @M6_Object_abort, ptr @M6_Object_typeName, ptr @M6_Object_copy, ptr @M6_Object_retain, ptr @M6_Object_release, ptr @M6_Object_refs, ptr @M6_Floats_len, ptr @M6_Floats_get, ptr @M6_Floats_set, ptr @M6_Floats_fill] }, align 8
@RProcess = global { ptr, i32, [4 x i8], ptr, ptr, [11 x ptr] } { ptr @NProcess, i32 32, [4 x i8] zeroinitializer, ptr @RObject, ptr null, [11 x ptr] [ptr @M6_Object_abort, ptr @M6_Object_typeName, ptr @M6_Object_copy, ptr @M6_Object_retain, ptr @M6_Object_release, ptr @M6_Object_refs, ptr @M7_Process_open, ptr @M7_Process_readLine, ptr @M7_Process_write, ptr @M7_Process_eof, ptr @M7_Process_finish] }, align 8
@RList = global { ptr, i32, [4 x i8], ptr, ptr, [11 x ptr] } { ptr @NList, i32 32, [4 x i8] zeroinitializer, ptr @RObject, ptr null, [11 x ptr] [ptr @M6_Object_abort, ptr @M6_Object_typeName, ptr @M6_Object_copy, ptr @M6_Object_retain, ptr @M6_Object_release, ptr @M6_Object_refs, ptr @M4_List_len, ptr @M4_List_get, ptr @M4_List_set, ptr @M4_List_append, ptr @M4_List_slice] }, align 8
@RInteger = global { ptr, i32, [4 x i8], ptr, ptr, [8 x ptr] } { ptr @NInteger, i32 24, [4 x i8] zeroinitializer, ptr @RObject, ptr null, [8 x ptr] [ptr @M6_Object_abort, ptr @M6_Object_typeName, ptr @M6_Object_copy, ptr @M6_Object_retain, ptr @M6_Object_release, ptr @M6_Object_refs, ptr @M7_Integer_get, ptr @M7_Integer_getLong] }, align 8
@gLiveObjects = internal unnamed_addr global i32 0, align 4
@gEmptyChars = internal global [1 x i8] zeroinitializer, align 1
@.str.13 = private unnamed_addr constant [33 x i8] c"Substring indices out of bounds.\00", align 1
@.str.14 = private unnamed_addr constant [28 x i8] c"String index out of bounds.\00", align 1
@.str.15 = private unnamed_addr constant [6 x i8] c"%255s\00", align 1
@__stdinp = external local_unnamed_addr global ptr, align 8
@.str.17 = private unnamed_addr constant [13 x i8] c"/dev/urandom\00", align 1
@.str.18 = private unnamed_addr constant [3 x i8] c"rb\00", align 1
@M2_IO_ticks.started = internal unnamed_addr global i1 false, align 4
@M2_IO_ticks.origin = internal unnamed_addr global %struct.timespec zeroinitializer, align 8
@.str.19 = private unnamed_addr constant [3 x i8] c"%s\00", align 1
@.str.20 = private unnamed_addr constant [30 x i8] c"Out of memory growing a List.\00", align 1
@.str.21 = private unnamed_addr constant [34 x i8] c"List slice indices out of bounds.\00", align 1
@.str.22 = private unnamed_addr constant [35 x i8] c"Calling a method of a void object.\00", align 1
@.str.23 = private unnamed_addr constant [19 x i8] c"%s does not do %s.\00", align 1
@.str.24 = private unnamed_addr constant [30 x i8] c"Unable to convert %s into %s.\00", align 1
@gSmallIntegersReady = internal unnamed_addr global i1 false, align 4
@gSmallIntegers = internal global [1153 x %struct.TInteger] zeroinitializer, align 8
@.str.25 = private unnamed_addr constant [31 x i8] c"Expected an Integer, found %s.\00", align 1
@.str.26 = private unnamed_addr constant [3 x i8] c"%g\00", align 1
@.str.27 = private unnamed_addr constant [3 x i8] c"%d\00", align 1
@.str.28 = private unnamed_addr constant [5 x i8] c"%lld\00", align 1
@gArgCount = internal unnamed_addr global i32 0, align 4
@gArgValues = internal unnamed_addr global ptr null, align 8
@__stderrp = external local_unnamed_addr global ptr, align 8
@.str.29 = private unnamed_addr constant [30 x i8] c"Out of memory reading a file.\00", align 1
@gHandlers = internal unnamed_addr global ptr null, align 8
@gThrown = internal unnamed_addr global ptr null, align 8
@.str.31 = private unnamed_addr constant [14 x i8] c"Uncaught: %s\0A\00", align 1
@.str.32 = private unnamed_addr constant [32 x i8] c"Uncaught: an object of type %s\0A\00", align 1
@.str.34 = private unnamed_addr constant [20 x i8] c"Runtime error : %s\0A\00", align 1
@gPoolDepth = internal unnamed_addr global i32 0, align 4
@gPoolMarkCapacity = internal unnamed_addr global i32 0, align 4
@gPoolMarks = internal unnamed_addr global ptr null, align 8
@gPoolCount = internal unnamed_addr global i32 0, align 4
@gPoolCapacity = internal unnamed_addr global i32 0, align 4
@gPoolItems = internal unnamed_addr global ptr null, align 8
@.str.37 = private unnamed_addr constant [8 x i8] c"/bin/sh\00", align 1
@.str.38 = private unnamed_addr constant [3 x i8] c"sh\00", align 1
@.str.39 = private unnamed_addr constant [3 x i8] c"-c\00", align 1
@gWorkerCount = internal unnamed_addr global i32 0, align 4
@.str.40 = private unnamed_addr constant [54 x i8] c"too many workers; wait for some before starting more.\00", align 1
@gWorkers = internal global [256 x %struct.__cm_worker] zeroinitializer, align 8
@.str.41 = private unnamed_addr constant [51 x i8] c"no such worker; wait for each handle exactly once.\00", align 1
@.str.42 = private unnamed_addr constant [41 x i8] c"that worker has already been waited for.\00", align 1
@gWorkersCollected = internal unnamed_addr global i32 0, align 4
@.str.44 = private unnamed_addr constant [26 x i8] c"List index out of bounds.\00", align 1
@_DefaultRuneLocale = external local_unnamed_addr global %struct._RuneLocale, align 8
@.str.45 = private unnamed_addr constant [28 x i8] c"%s cannot have %d elements.\00", align 1
@.str.46 = private unnamed_addr constant [31 x i8] c"Out of memory making an array.\00", align 1
@.str.47 = private unnamed_addr constant [32 x i8] c"%s index %d is outside 0 to %d.\00", align 1
@str = private unnamed_addr constant [53 x i8] c"Runtime error : out of memory recording a temporary.\00", align 1
@str.48 = private unnamed_addr constant [47 x i8] c"Runtime error : out of memory making a String.\00", align 1
@str.49 = private unnamed_addr constant [46 x i8] c"Runtime error : out of memory entering a try.\00", align 1
@str.50 = private unnamed_addr constant [15 x i8] c"Uncaught: null\00", align 1
@str.51 = private unnamed_addr constant [46 x i8] c"Runtime error : out of memory opening a pool.\00", align 1

; Function Attrs: cold nofree noreturn nounwind ssp uwtable(sync)
define void @M6_Object_abort(ptr readnone captures(none) %0) #0 {
  tail call void @exit(i32 noundef 1) #39
  unreachable
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(read, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable(sync)
define ptr @M6_Object_typeName(ptr noundef readonly captures(none) %0) #1 {
  %2 = load ptr, ptr %0, align 8, !tbaa !10
  %3 = load ptr, ptr %2, align 8, !tbaa !14
  ret ptr %3
}

; Function Attrs: nounwind ssp uwtable(sync)
define noundef ptr @M6_Object_copy(ptr noundef readonly captures(none) %0) #2 {
  %2 = load ptr, ptr %0, align 8, !tbaa !10
  %3 = tail call ptr @__catmint_new(ptr noundef %2)
  %4 = load ptr, ptr %0, align 8, !tbaa !10
  %5 = getelementptr inbounds nuw i8, ptr %4, i64 8
  %6 = load i32, ptr %5, align 8, !tbaa !6
  %7 = sext i32 %6 to i64
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %3, ptr noundef nonnull align 1 %0, i64 noundef %7, i1 noundef false) #40
  %8 = getelementptr inbounds nuw i8, ptr %3, i64 8
  store i32 1, ptr %8, align 8, !tbaa !16
  %9 = load ptr, ptr %3, align 8, !tbaa !10
  %10 = icmp eq ptr %9, @RString
  br i1 %10, label %11, label %23

11:                                               ; preds = %1
  %12 = getelementptr inbounds nuw i8, ptr %3, i64 16
  %13 = load ptr, ptr %12, align 8, !tbaa !17
  %14 = icmp eq ptr %13, @gEmptyChars
  br i1 %14, label %193, label %15

15:                                               ; preds = %11
  %16 = getelementptr inbounds nuw i8, ptr %3, i64 12
  %17 = load i32, ptr %16, align 4, !tbaa !20
  %18 = sext i32 %17 to i64
  %19 = add nsw i64 %18, 1
  %20 = tail call ptr @calloc(i64 noundef %19, i64 noundef 1) #41
  %21 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %22 = load ptr, ptr %21, align 8, !tbaa !17
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %20, ptr noundef align 1 %22, i64 noundef %18, i1 noundef false) #40
  store ptr %20, ptr %12, align 8, !tbaa !17
  br label %193

23:                                               ; preds = %1
  %24 = icmp eq ptr %9, @RList
  br i1 %24, label %25, label %143

25:                                               ; preds = %23
  %26 = getelementptr inbounds nuw i8, ptr %3, i64 16
  %27 = load i32, ptr %26, align 8, !tbaa !21
  %28 = icmp sgt i32 %27, 0
  br i1 %28, label %29, label %193

29:                                               ; preds = %25
  %30 = getelementptr inbounds nuw i8, ptr %3, i64 24
  %31 = load ptr, ptr %30, align 8, !tbaa !24
  %32 = icmp eq ptr %31, null
  br i1 %32, label %193, label %33

33:                                               ; preds = %29
  %34 = zext nneg i32 %27 to i64
  %35 = shl nuw nsw i64 %34, 3
  %36 = tail call ptr @malloc(i64 noundef %35) #42
  %37 = getelementptr inbounds nuw i8, ptr %0, i64 24
  %38 = load ptr, ptr %37, align 8, !tbaa !24
  %39 = getelementptr inbounds nuw i8, ptr %3, i64 12
  %40 = load i32, ptr %39, align 4, !tbaa !25
  %41 = sext i32 %40 to i64
  %42 = shl nsw i64 %41, 3
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %36, ptr noundef align 1 %38, i64 noundef %42, i1 noundef false) #40
  store ptr %36, ptr %30, align 8, !tbaa !24
  %43 = icmp sgt i32 %40, 0
  br i1 %43, label %44, label %193

44:                                               ; preds = %33
  %45 = zext nneg i32 %40 to i64
  %46 = and i64 %45, 7
  %47 = icmp ult i32 %40, 8
  br i1 %47, label %174, label %48

48:                                               ; preds = %44
  %49 = and i64 %45, 2147483640
  br label %50

50:                                               ; preds = %139, %48
  %51 = phi i64 [ 0, %48 ], [ %140, %139 ]
  %52 = phi i64 [ 0, %48 ], [ %141, %139 ]
  %53 = getelementptr inbounds nuw ptr, ptr %36, i64 %51
  %54 = load ptr, ptr %53, align 8, !tbaa !26
  %55 = icmp eq ptr %54, null
  br i1 %55, label %62, label %56

56:                                               ; preds = %50
  %57 = getelementptr inbounds nuw i8, ptr %54, i64 8
  %58 = load i32, ptr %57, align 8, !tbaa !16
  %59 = icmp sgt i32 %58, 0
  br i1 %59, label %60, label %62

60:                                               ; preds = %56
  %61 = add nuw nsw i32 %58, 1
  store i32 %61, ptr %57, align 8, !tbaa !16
  br label %62

62:                                               ; preds = %50, %56, %60
  %63 = getelementptr inbounds nuw ptr, ptr %36, i64 %51
  %64 = getelementptr inbounds nuw i8, ptr %63, i64 8
  %65 = load ptr, ptr %64, align 8, !tbaa !26
  %66 = icmp eq ptr %65, null
  br i1 %66, label %73, label %67

67:                                               ; preds = %62
  %68 = getelementptr inbounds nuw i8, ptr %65, i64 8
  %69 = load i32, ptr %68, align 8, !tbaa !16
  %70 = icmp sgt i32 %69, 0
  br i1 %70, label %71, label %73

71:                                               ; preds = %67
  %72 = add nuw nsw i32 %69, 1
  store i32 %72, ptr %68, align 8, !tbaa !16
  br label %73

73:                                               ; preds = %71, %67, %62
  %74 = getelementptr inbounds nuw ptr, ptr %36, i64 %51
  %75 = getelementptr inbounds nuw i8, ptr %74, i64 16
  %76 = load ptr, ptr %75, align 8, !tbaa !26
  %77 = icmp eq ptr %76, null
  br i1 %77, label %84, label %78

78:                                               ; preds = %73
  %79 = getelementptr inbounds nuw i8, ptr %76, i64 8
  %80 = load i32, ptr %79, align 8, !tbaa !16
  %81 = icmp sgt i32 %80, 0
  br i1 %81, label %82, label %84

82:                                               ; preds = %78
  %83 = add nuw nsw i32 %80, 1
  store i32 %83, ptr %79, align 8, !tbaa !16
  br label %84

84:                                               ; preds = %82, %78, %73
  %85 = getelementptr inbounds nuw ptr, ptr %36, i64 %51
  %86 = getelementptr inbounds nuw i8, ptr %85, i64 24
  %87 = load ptr, ptr %86, align 8, !tbaa !26
  %88 = icmp eq ptr %87, null
  br i1 %88, label %95, label %89

89:                                               ; preds = %84
  %90 = getelementptr inbounds nuw i8, ptr %87, i64 8
  %91 = load i32, ptr %90, align 8, !tbaa !16
  %92 = icmp sgt i32 %91, 0
  br i1 %92, label %93, label %95

93:                                               ; preds = %89
  %94 = add nuw nsw i32 %91, 1
  store i32 %94, ptr %90, align 8, !tbaa !16
  br label %95

95:                                               ; preds = %93, %89, %84
  %96 = getelementptr inbounds nuw ptr, ptr %36, i64 %51
  %97 = getelementptr inbounds nuw i8, ptr %96, i64 32
  %98 = load ptr, ptr %97, align 8, !tbaa !26
  %99 = icmp eq ptr %98, null
  br i1 %99, label %106, label %100

100:                                              ; preds = %95
  %101 = getelementptr inbounds nuw i8, ptr %98, i64 8
  %102 = load i32, ptr %101, align 8, !tbaa !16
  %103 = icmp sgt i32 %102, 0
  br i1 %103, label %104, label %106

104:                                              ; preds = %100
  %105 = add nuw nsw i32 %102, 1
  store i32 %105, ptr %101, align 8, !tbaa !16
  br label %106

106:                                              ; preds = %104, %100, %95
  %107 = getelementptr inbounds nuw ptr, ptr %36, i64 %51
  %108 = getelementptr inbounds nuw i8, ptr %107, i64 40
  %109 = load ptr, ptr %108, align 8, !tbaa !26
  %110 = icmp eq ptr %109, null
  br i1 %110, label %117, label %111

111:                                              ; preds = %106
  %112 = getelementptr inbounds nuw i8, ptr %109, i64 8
  %113 = load i32, ptr %112, align 8, !tbaa !16
  %114 = icmp sgt i32 %113, 0
  br i1 %114, label %115, label %117

115:                                              ; preds = %111
  %116 = add nuw nsw i32 %113, 1
  store i32 %116, ptr %112, align 8, !tbaa !16
  br label %117

117:                                              ; preds = %115, %111, %106
  %118 = getelementptr inbounds nuw ptr, ptr %36, i64 %51
  %119 = getelementptr inbounds nuw i8, ptr %118, i64 48
  %120 = load ptr, ptr %119, align 8, !tbaa !26
  %121 = icmp eq ptr %120, null
  br i1 %121, label %128, label %122

122:                                              ; preds = %117
  %123 = getelementptr inbounds nuw i8, ptr %120, i64 8
  %124 = load i32, ptr %123, align 8, !tbaa !16
  %125 = icmp sgt i32 %124, 0
  br i1 %125, label %126, label %128

126:                                              ; preds = %122
  %127 = add nuw nsw i32 %124, 1
  store i32 %127, ptr %123, align 8, !tbaa !16
  br label %128

128:                                              ; preds = %126, %122, %117
  %129 = getelementptr inbounds nuw ptr, ptr %36, i64 %51
  %130 = getelementptr inbounds nuw i8, ptr %129, i64 56
  %131 = load ptr, ptr %130, align 8, !tbaa !26
  %132 = icmp eq ptr %131, null
  br i1 %132, label %139, label %133

133:                                              ; preds = %128
  %134 = getelementptr inbounds nuw i8, ptr %131, i64 8
  %135 = load i32, ptr %134, align 8, !tbaa !16
  %136 = icmp sgt i32 %135, 0
  br i1 %136, label %137, label %139

137:                                              ; preds = %133
  %138 = add nuw nsw i32 %135, 1
  store i32 %138, ptr %134, align 8, !tbaa !16
  br label %139

139:                                              ; preds = %137, %133, %128
  %140 = add nuw nsw i64 %51, 8
  %141 = add i64 %52, 8
  %142 = icmp eq i64 %141, %49
  br i1 %142, label %172, label %50, !llvm.loop !27

143:                                              ; preds = %23
  %144 = icmp eq ptr %9, @RFile
  br i1 %144, label %145, label %147

145:                                              ; preds = %143
  %146 = getelementptr inbounds nuw i8, ptr %3, i64 16
  store ptr null, ptr %146, align 8, !tbaa !29
  br label %193

147:                                              ; preds = %143
  %148 = icmp eq ptr %9, @RProcess
  br i1 %148, label %149, label %151

149:                                              ; preds = %147
  %150 = getelementptr inbounds nuw i8, ptr %3, i64 16
  store ptr null, ptr %150, align 8, !tbaa !32
  br label %193

151:                                              ; preds = %147
  %152 = icmp eq ptr %9, @RBytes
  %153 = icmp eq ptr %9, @RInts
  %154 = icmp eq ptr %9, @RFloats
  %155 = or i1 %153, %154
  %156 = or i1 %152, %155
  br i1 %156, label %157, label %193

157:                                              ; preds = %151
  %158 = getelementptr inbounds nuw i8, ptr %3, i64 16
  %159 = load ptr, ptr %158, align 8, !tbaa !34
  %160 = icmp eq ptr %159, null
  br i1 %160, label %193, label %161

161:                                              ; preds = %157
  %162 = getelementptr inbounds nuw i8, ptr %3, i64 12
  %163 = load i32, ptr %162, align 4, !tbaa !36
  %164 = icmp sgt i32 %163, 0
  br i1 %164, label %165, label %193

165:                                              ; preds = %161
  %166 = zext nneg i32 %163 to i64
  %167 = select i1 %152, i64 0, i64 3
  %168 = shl nuw nsw i64 %166, %167
  %169 = tail call ptr @malloc(i64 noundef %168) #42
  %170 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %171 = load ptr, ptr %170, align 8, !tbaa !34
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %169, ptr noundef align 1 %171, i64 noundef %168, i1 noundef false) #40
  store ptr %169, ptr %158, align 8, !tbaa !34
  br label %193

172:                                              ; preds = %139
  %173 = icmp eq i64 %46, 0
  br i1 %173, label %193, label %174

174:                                              ; preds = %172, %44
  %175 = phi i64 [ 0, %44 ], [ %140, %172 ]
  %176 = icmp ne i64 %46, 0
  tail call void @llvm.assume(i1 %176)
  br label %177

177:                                              ; preds = %189, %174
  %178 = phi i64 [ %175, %174 ], [ %190, %189 ]
  %179 = phi i64 [ 0, %174 ], [ %191, %189 ]
  %180 = getelementptr inbounds nuw ptr, ptr %36, i64 %178
  %181 = load ptr, ptr %180, align 8, !tbaa !26
  %182 = icmp eq ptr %181, null
  br i1 %182, label %189, label %183

183:                                              ; preds = %177
  %184 = getelementptr inbounds nuw i8, ptr %181, i64 8
  %185 = load i32, ptr %184, align 8, !tbaa !16
  %186 = icmp sgt i32 %185, 0
  br i1 %186, label %187, label %189

187:                                              ; preds = %183
  %188 = add nuw nsw i32 %185, 1
  store i32 %188, ptr %184, align 8, !tbaa !16
  br label %189

189:                                              ; preds = %187, %183, %177
  %190 = add nuw nsw i64 %178, 1
  %191 = add i64 %179, 1
  %192 = icmp eq i64 %191, %46
  br i1 %192, label %193, label %177, !llvm.loop !37

193:                                              ; preds = %172, %189, %33, %157, %161, %165, %151, %25, %29, %15, %11, %149, %145
  ret ptr %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable(sync)
define noundef ptr @M6_Object_retain(ptr noundef returned captures(address_is_null, ret: address, provenance) %0) #3 {
  %2 = icmp eq ptr %0, null
  br i1 %2, label %9, label %3

3:                                                ; preds = %1
  %4 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %5 = load i32, ptr %4, align 8, !tbaa !16
  %6 = icmp sgt i32 %5, 0
  br i1 %6, label %7, label %9

7:                                                ; preds = %3
  %8 = add nuw nsw i32 %5, 1
  store i32 %8, ptr %4, align 8, !tbaa !16
  br label %9

9:                                                ; preds = %1, %3, %7
  ret ptr %0
}

; Function Attrs: nounwind ssp uwtable(sync)
define void @M6_Object_release(ptr noundef captures(address) %0) #2 {
  %2 = icmp eq ptr %0, null
  br i1 %2, label %11, label %3

3:                                                ; preds = %1
  %4 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %5 = load i32, ptr %4, align 8, !tbaa !16
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %11, label %7

7:                                                ; preds = %3
  %8 = add nsw i32 %5, -1
  store i32 %8, ptr %4, align 8, !tbaa !16
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %10, label %11

10:                                               ; preds = %7
  store i32 1, ptr %4, align 8, !tbaa !16
  tail call fastcc void @object_free(ptr noundef %0)
  br label %11

11:                                               ; preds = %1, %3, %10, %7
  ret void
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable(sync)
define i32 @M6_Object_refs(ptr noundef readonly captures(address_is_null) %0) #4 {
  %2 = icmp eq ptr %0, null
  br i1 %2, label %6, label %3

3:                                                ; preds = %1
  %4 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %5 = load i32, ptr %4, align 8, !tbaa !16
  br label %6

6:                                                ; preds = %1, %3
  %7 = phi i32 [ %5, %3 ], [ 0, %1 ]
  ret i32 %7
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable(sync)
define i32 @M6_String_length(ptr noundef readonly captures(none) %0) #4 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %3 = load i32, ptr %2, align 4, !tbaa !20
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nounwind ssp willreturn uwtable(sync)
define i32 @M6_String_toInt(ptr noundef readonly captures(none) %0) #5 {
  %2 = alloca ptr, align 8
  call void @llvm.lifetime.start.p0(ptr nonnull %2) #40
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %4 = load ptr, ptr %3, align 8, !tbaa !17
  %5 = call i64 @strtol(ptr noundef %4, ptr noundef nonnull %2, i32 noundef 10)
  %6 = load ptr, ptr %2, align 8, !tbaa !39
  %7 = load i8, ptr %6, align 1, !tbaa !40
  %8 = icmp eq i8 %7, 0
  %9 = trunc i64 %5 to i32
  %10 = select i1 %8, i32 %9, i32 0
  call void @llvm.lifetime.end.p0(ptr nonnull %2) #40
  ret i32 %10
}

; Function Attrs: nounwind ssp uwtable(sync)
define nonnull ptr @M6_String_substring(ptr noundef readonly captures(none) %0, i32 noundef %1, i32 noundef %2) #2 {
  %4 = icmp slt i32 %1, 0
  %5 = icmp sgt i32 %1, %2
  %6 = or i1 %4, %5
  br i1 %6, label %11, label %7

7:                                                ; preds = %3
  %8 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %9 = load i32, ptr %8, align 4, !tbaa !20
  %10 = icmp sgt i32 %2, %9
  br i1 %10, label %11, label %12

11:                                               ; preds = %7, %3
  tail call void @__cm_runtimeError(ptr noundef nonnull @.str.13) #43
  unreachable

12:                                               ; preds = %7
  %13 = sub nsw i32 %2, %1
  %14 = tail call fastcc ptr @new_string(i32 noundef %13)
  %15 = getelementptr inbounds nuw i8, ptr %14, i64 16
  %16 = load ptr, ptr %15, align 8, !tbaa !17
  %17 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %18 = load ptr, ptr %17, align 8, !tbaa !17
  %19 = zext nneg i32 %1 to i64
  %20 = getelementptr inbounds nuw i8, ptr %18, i64 %19
  %21 = sext i32 %13 to i64
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %16, ptr noundef align 1 %20, i64 noundef %21, i1 noundef false) #40
  ret ptr %14
}

; Function Attrs: nounwind ssp uwtable(sync)
define nonnull ptr @M6_String_concat(ptr noundef readonly captures(none) %0, ptr noundef readonly captures(none) %1) #2 {
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %4 = load i32, ptr %3, align 4, !tbaa !20
  %5 = getelementptr inbounds nuw i8, ptr %1, i64 12
  %6 = load i32, ptr %5, align 4, !tbaa !20
  %7 = add nsw i32 %6, %4
  %8 = tail call fastcc ptr @new_string(i32 noundef %7)
  %9 = getelementptr inbounds nuw i8, ptr %8, i64 16
  %10 = load ptr, ptr %9, align 8, !tbaa !17
  %11 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %12 = load ptr, ptr %11, align 8, !tbaa !17
  %13 = load i32, ptr %3, align 4, !tbaa !20
  %14 = sext i32 %13 to i64
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %10, ptr noundef align 1 %12, i64 noundef %14, i1 noundef false) #40
  %15 = load ptr, ptr %9, align 8, !tbaa !17
  %16 = load i32, ptr %3, align 4, !tbaa !20
  %17 = sext i32 %16 to i64
  %18 = getelementptr inbounds i8, ptr %15, i64 %17
  %19 = getelementptr inbounds nuw i8, ptr %1, i64 16
  %20 = load ptr, ptr %19, align 8, !tbaa !17
  %21 = load i32, ptr %5, align 4, !tbaa !20
  %22 = sext i32 %21 to i64
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %18, ptr noundef align 1 %20, i64 noundef %22, i1 noundef false) #40
  ret ptr %8
}

; Function Attrs: mustprogress nofree norecurse nounwind ssp willreturn memory(read, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable(sync)
define range(i32 0, 2) i32 @M6_String_equal(ptr noundef readonly captures(address_is_null) %0, ptr noundef readonly captures(address_is_null) %1) #6 {
  %3 = icmp eq ptr %0, null
  %4 = icmp eq ptr %1, null
  %5 = or i1 %3, %4
  %6 = and i1 %3, %4
  br i1 %5, label %21, label %7

7:                                                ; preds = %2
  %8 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %9 = load i32, ptr %8, align 4, !tbaa !20
  %10 = getelementptr inbounds nuw i8, ptr %1, i64 12
  %11 = load i32, ptr %10, align 4, !tbaa !20
  %12 = icmp eq i32 %9, %11
  br i1 %12, label %13, label %21

13:                                               ; preds = %7
  %14 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %15 = load ptr, ptr %14, align 8, !tbaa !17
  %16 = getelementptr inbounds nuw i8, ptr %1, i64 16
  %17 = load ptr, ptr %16, align 8, !tbaa !17
  %18 = sext i32 %9 to i64
  %19 = tail call i32 @strncmp(ptr noundef %15, ptr noundef %17, i64 noundef %18) #40
  %20 = icmp eq i32 %19, 0
  br label %21

21:                                               ; preds = %2, %7, %13
  %22 = phi i1 [ false, %7 ], [ %20, %13 ], [ %6, %2 ]
  %23 = zext i1 %22 to i32
  ret i32 %23
}

; Function Attrs: nounwind ssp uwtable(sync)
define range(i32 0, 256) i32 @M6_String_at(ptr noundef readonly captures(none) %0, i32 noundef %1) #2 {
  %3 = icmp slt i32 %1, 0
  br i1 %3, label %8, label %4

4:                                                ; preds = %2
  %5 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %6 = load i32, ptr %5, align 4, !tbaa !20
  %7 = icmp slt i32 %1, %6
  br i1 %7, label %9, label %8

8:                                                ; preds = %4, %2
  tail call void @__cm_runtimeError(ptr noundef nonnull @.str.14) #43
  unreachable

9:                                                ; preds = %4
  %10 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %11 = load ptr, ptr %10, align 8, !tbaa !17
  %12 = zext nneg i32 %1 to i64
  %13 = getelementptr inbounds nuw i8, ptr %11, i64 %12
  %14 = load i8, ptr %13, align 1, !tbaa !40
  %15 = zext i8 %14 to i32
  ret i32 %15
}

; Function Attrs: nofree norecurse nounwind ssp memory(read, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable(sync)
define i32 @M6_String_indexOf(ptr noundef readonly captures(none) %0, ptr noundef readonly captures(address_is_null) %1) #7 {
  %3 = icmp eq ptr %1, null
  br i1 %3, label %31, label %4

4:                                                ; preds = %2
  %5 = getelementptr inbounds nuw i8, ptr %1, i64 12
  %6 = load i32, ptr %5, align 4, !tbaa !20
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %31, label %8

8:                                                ; preds = %4
  %9 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %10 = load i32, ptr %9, align 4, !tbaa !20
  %11 = icmp slt i32 %10, %6
  br i1 %11, label %31, label %12

12:                                               ; preds = %8
  %13 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %14 = load ptr, ptr %13, align 8, !tbaa !17
  %15 = getelementptr inbounds nuw i8, ptr %1, i64 16
  %16 = load ptr, ptr %15, align 8, !tbaa !17
  %17 = sext i32 %6 to i64
  %18 = add i32 %10, 1
  %19 = sub i32 %18, %6
  %20 = zext i32 %19 to i64
  br label %21

21:                                               ; preds = %12, %26
  %22 = phi i64 [ 0, %12 ], [ %27, %26 ]
  %23 = getelementptr inbounds nuw i8, ptr %14, i64 %22
  %24 = tail call i32 @memcmp(ptr noundef %23, ptr noundef %16, i64 noundef %17)
  %25 = icmp eq i32 %24, 0
  br i1 %25, label %29, label %26

26:                                               ; preds = %21
  %27 = add nuw nsw i64 %22, 1
  %28 = icmp eq i64 %27, %20
  br i1 %28, label %31, label %21, !llvm.loop !41

29:                                               ; preds = %21
  %30 = trunc nuw nsw i64 %22 to i32
  br label %31

31:                                               ; preds = %26, %29, %8, %2, %4
  %32 = phi i32 [ 0, %4 ], [ 0, %2 ], [ -1, %8 ], [ %30, %29 ], [ -1, %26 ]
  ret i32 %32
}

; Function Attrs: nounwind ssp uwtable(sync)
define nonnull ptr @M6_String_trim(ptr noundef readonly captures(none) %0) #2 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %3 = load i32, ptr %2, align 4, !tbaa !20
  %4 = icmp sgt i32 %3, 0
  br i1 %4, label %5, label %59

5:                                                ; preds = %1
  %6 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %7 = zext nneg i32 %3 to i64
  br label %8

8:                                                ; preds = %5, %25
  %9 = phi i64 [ 0, %5 ], [ %26, %25 ]
  %10 = load ptr, ptr %6, align 8, !tbaa !17
  %11 = getelementptr inbounds nuw i8, ptr %10, i64 %9
  %12 = load i8, ptr %11, align 1, !tbaa !40
  %13 = icmp sgt i8 %12, -1
  br i1 %13, label %14, label %19

14:                                               ; preds = %8
  %15 = zext nneg i8 %12 to i64
  %16 = getelementptr inbounds nuw i32, ptr getelementptr inbounds nuw (i8, ptr @_DefaultRuneLocale, i64 60), i64 %15
  %17 = load i32, ptr %16, align 4, !tbaa !6
  %18 = and i32 %17, 16384
  br label %22

19:                                               ; preds = %8
  %20 = zext i8 %12 to i32
  %21 = tail call i32 @__maskrune(i32 noundef %20, i64 noundef 16384) #40
  br label %22

22:                                               ; preds = %14, %19
  %23 = phi i32 [ %18, %14 ], [ %21, %19 ]
  %24 = icmp eq i32 %23, 0
  br i1 %24, label %28, label %25

25:                                               ; preds = %22
  %26 = add nuw nsw i64 %9, 1
  %27 = icmp eq i64 %26, %7
  br i1 %27, label %63, label %8, !llvm.loop !42

28:                                               ; preds = %22
  %29 = trunc nuw nsw i64 %9 to i32
  %30 = icmp sgt i32 %3, %29
  br i1 %30, label %31, label %59

31:                                               ; preds = %28
  %32 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %33 = zext nneg i32 %3 to i64
  %34 = shl i64 %9, 32
  %35 = ashr exact i64 %34, 32
  br label %36

36:                                               ; preds = %31, %54
  %37 = phi i64 [ %33, %31 ], [ %55, %54 ]
  %38 = load ptr, ptr %32, align 8, !tbaa !17
  %39 = getelementptr i8, ptr %38, i64 %37
  %40 = getelementptr i8, ptr %39, i64 -1
  %41 = load i8, ptr %40, align 1, !tbaa !40
  %42 = icmp sgt i8 %41, -1
  br i1 %42, label %43, label %48

43:                                               ; preds = %36
  %44 = zext nneg i8 %41 to i64
  %45 = getelementptr inbounds nuw i32, ptr getelementptr inbounds nuw (i8, ptr @_DefaultRuneLocale, i64 60), i64 %44
  %46 = load i32, ptr %45, align 4, !tbaa !6
  %47 = and i32 %46, 16384
  br label %51

48:                                               ; preds = %36
  %49 = zext i8 %41 to i32
  %50 = tail call i32 @__maskrune(i32 noundef %49, i64 noundef 16384) #40
  br label %51

51:                                               ; preds = %43, %48
  %52 = phi i32 [ %47, %43 ], [ %50, %48 ]
  %53 = icmp eq i32 %52, 0
  br i1 %53, label %57, label %54

54:                                               ; preds = %51
  %55 = add nsw i64 %37, -1
  %56 = icmp sgt i64 %55, %35
  br i1 %56, label %36, label %63, !llvm.loop !43

57:                                               ; preds = %51
  %58 = trunc nsw i64 %37 to i32
  br label %59

59:                                               ; preds = %57, %1, %28
  %60 = phi i32 [ %29, %28 ], [ 0, %1 ], [ %29, %57 ]
  %61 = phi i32 [ %3, %28 ], [ %3, %1 ], [ %58, %57 ]
  %62 = icmp sgt i32 %60, %61
  br i1 %62, label %68, label %63

63:                                               ; preds = %25, %54, %59
  %64 = phi i32 [ %61, %59 ], [ %29, %54 ], [ %3, %25 ]
  %65 = phi i32 [ %60, %59 ], [ %29, %54 ], [ %3, %25 ]
  %66 = load i32, ptr %2, align 4, !tbaa !20
  %67 = icmp sgt i32 %64, %66
  br i1 %67, label %68, label %69

68:                                               ; preds = %63, %59
  tail call void @__cm_runtimeError(ptr noundef nonnull @.str.13) #43
  unreachable

69:                                               ; preds = %63
  %70 = sub nsw i32 %64, %65
  %71 = tail call fastcc ptr @new_string(i32 noundef %70)
  %72 = getelementptr inbounds nuw i8, ptr %71, i64 16
  %73 = load ptr, ptr %72, align 8, !tbaa !17
  %74 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %75 = load ptr, ptr %74, align 8, !tbaa !17
  %76 = zext nneg i32 %65 to i64
  %77 = getelementptr inbounds nuw i8, ptr %75, i64 %76
  %78 = sext i32 %70 to i64
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %73, ptr noundef align 1 %77, i64 noundef %78, i1 noundef false) #40
  ret ptr %71
}

; Function Attrs: nounwind ssp uwtable(sync)
define nonnull ptr @M6_String_upper(ptr noundef readonly captures(none) %0) #2 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %3 = load i32, ptr %2, align 4, !tbaa !20
  %4 = icmp slt i32 %3, 0
  br i1 %4, label %5, label %6

5:                                                ; preds = %1
  tail call void @__cm_runtimeError(ptr noundef nonnull @.str.13) #43
  unreachable

6:                                                ; preds = %1
  %7 = tail call fastcc ptr @new_string(i32 noundef %3)
  %8 = getelementptr inbounds nuw i8, ptr %7, i64 16
  %9 = load ptr, ptr %8, align 8, !tbaa !17
  %10 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %11 = load ptr, ptr %10, align 8, !tbaa !17
  %12 = zext nneg i32 %3 to i64
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %9, ptr noundef align 1 %11, i64 noundef %12, i1 noundef false) #40
  %13 = getelementptr inbounds nuw i8, ptr %7, i64 12
  %14 = load i32, ptr %13, align 4, !tbaa !20
  %15 = icmp sgt i32 %14, 0
  br i1 %15, label %16, label %30

16:                                               ; preds = %6, %16
  %17 = phi i64 [ %26, %16 ], [ 0, %6 ]
  %18 = load ptr, ptr %8, align 8, !tbaa !17
  %19 = getelementptr inbounds nuw i8, ptr %18, i64 %17
  %20 = load i8, ptr %19, align 1, !tbaa !40
  %21 = zext i8 %20 to i32
  %22 = tail call i32 @__toupper(i32 noundef %21) #40
  %23 = trunc i32 %22 to i8
  %24 = load ptr, ptr %8, align 8, !tbaa !17
  %25 = getelementptr inbounds nuw i8, ptr %24, i64 %17
  store i8 %23, ptr %25, align 1, !tbaa !40
  %26 = add nuw nsw i64 %17, 1
  %27 = load i32, ptr %13, align 4, !tbaa !20
  %28 = sext i32 %27 to i64
  %29 = icmp slt i64 %26, %28
  br i1 %29, label %16, label %30, !llvm.loop !44

30:                                               ; preds = %16, %6
  ret ptr %7
}

; Function Attrs: nounwind ssp uwtable(sync)
define nonnull ptr @M6_String_lower(ptr noundef readonly captures(none) %0) #2 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %3 = load i32, ptr %2, align 4, !tbaa !20
  %4 = icmp slt i32 %3, 0
  br i1 %4, label %5, label %6

5:                                                ; preds = %1
  tail call void @__cm_runtimeError(ptr noundef nonnull @.str.13) #43
  unreachable

6:                                                ; preds = %1
  %7 = tail call fastcc ptr @new_string(i32 noundef %3)
  %8 = getelementptr inbounds nuw i8, ptr %7, i64 16
  %9 = load ptr, ptr %8, align 8, !tbaa !17
  %10 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %11 = load ptr, ptr %10, align 8, !tbaa !17
  %12 = zext nneg i32 %3 to i64
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %9, ptr noundef align 1 %11, i64 noundef %12, i1 noundef false) #40
  %13 = getelementptr inbounds nuw i8, ptr %7, i64 12
  %14 = load i32, ptr %13, align 4, !tbaa !20
  %15 = icmp sgt i32 %14, 0
  br i1 %15, label %16, label %30

16:                                               ; preds = %6, %16
  %17 = phi i64 [ %26, %16 ], [ 0, %6 ]
  %18 = load ptr, ptr %8, align 8, !tbaa !17
  %19 = getelementptr inbounds nuw i8, ptr %18, i64 %17
  %20 = load i8, ptr %19, align 1, !tbaa !40
  %21 = zext i8 %20 to i32
  %22 = tail call i32 @__tolower(i32 noundef %21) #40
  %23 = trunc i32 %22 to i8
  %24 = load ptr, ptr %8, align 8, !tbaa !17
  %25 = getelementptr inbounds nuw i8, ptr %24, i64 %17
  store i8 %23, ptr %25, align 1, !tbaa !40
  %26 = add nuw nsw i64 %17, 1
  %27 = load i32, ptr %13, align 4, !tbaa !20
  %28 = sext i32 %27 to i64
  %29 = icmp slt i64 %26, %28
  br i1 %29, label %16, label %30, !llvm.loop !44

30:                                               ; preds = %16, %6
  ret ptr %7
}

; Function Attrs: nounwind ssp uwtable(sync)
define noundef ptr @M6_String_split(ptr noundef readonly captures(none) %0, ptr noundef readonly captures(address_is_null) %1) #2 {
  %3 = tail call ptr @__catmint_new(ptr noundef nonnull @RList)
  %4 = getelementptr inbounds nuw i8, ptr %3, i64 12
  %5 = getelementptr inbounds nuw i8, ptr %3, i64 16
  store <2 x i32> zeroinitializer, ptr %4, align 4, !tbaa !6
  %6 = getelementptr inbounds nuw i8, ptr %3, i64 24
  store ptr null, ptr %6, align 8, !tbaa !24
  %7 = icmp eq ptr %1, null
  br i1 %7, label %19, label %8

8:                                                ; preds = %2
  %9 = getelementptr inbounds nuw i8, ptr %1, i64 12
  %10 = load i32, ptr %9, align 4, !tbaa !20
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %19, label %12

12:                                               ; preds = %8
  %13 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %14 = load i32, ptr %13, align 4, !tbaa !20
  %15 = icmp sgt i32 %10, %14
  br i1 %15, label %117, label %16

16:                                               ; preds = %12
  %17 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %18 = getelementptr inbounds nuw i8, ptr %1, i64 16
  br label %51

19:                                               ; preds = %8, %2
  %20 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %21 = load i32, ptr %20, align 4, !tbaa !20
  %22 = icmp slt i32 %21, 0
  br i1 %22, label %23, label %24

23:                                               ; preds = %19
  tail call void @__cm_runtimeError(ptr noundef nonnull @.str.13) #43
  unreachable

24:                                               ; preds = %19
  %25 = tail call fastcc ptr @new_string(i32 noundef %21)
  %26 = getelementptr inbounds nuw i8, ptr %25, i64 16
  %27 = load ptr, ptr %26, align 8, !tbaa !17
  %28 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %29 = load ptr, ptr %28, align 8, !tbaa !17
  %30 = zext nneg i32 %21 to i64
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %27, ptr noundef align 1 %29, i64 noundef %30, i1 noundef false) #40
  %31 = load i32, ptr %4, align 4, !tbaa !25
  %32 = load i32, ptr %5, align 8, !tbaa !21
  %33 = icmp eq i32 %31, %32
  br i1 %33, label %34, label %45

34:                                               ; preds = %24
  %35 = icmp eq i32 %31, 0
  %36 = shl nsw i32 %31, 1
  %37 = select i1 %35, i32 4, i32 %36
  %38 = load ptr, ptr %6, align 8, !tbaa !24
  %39 = sext i32 %37 to i64
  %40 = shl nsw i64 %39, 3
  %41 = tail call ptr @realloc(ptr noundef %38, i64 noundef %40) #44
  %42 = icmp eq ptr %41, null
  br i1 %42, label %43, label %44

43:                                               ; preds = %34
  tail call void @__cm_runtimeError(ptr noundef nonnull @.str.20) #43
  unreachable

44:                                               ; preds = %34
  store ptr %41, ptr %6, align 8, !tbaa !24
  store i32 %37, ptr %5, align 8, !tbaa !21
  br label %45

45:                                               ; preds = %44, %24
  %46 = getelementptr inbounds nuw i8, ptr %25, i64 8
  %47 = load i32, ptr %46, align 8, !tbaa !16
  %48 = icmp sgt i32 %47, 0
  br i1 %48, label %49, label %154

49:                                               ; preds = %45
  %50 = add nuw nsw i32 %47, 1
  store i32 %50, ptr %46, align 8, !tbaa !16
  br label %154

51:                                               ; preds = %16, %110
  %52 = phi i32 [ %14, %16 ], [ %111, %110 ]
  %53 = phi i32 [ %10, %16 ], [ %112, %110 ]
  %54 = phi i32 [ 0, %16 ], [ %114, %110 ]
  %55 = phi i32 [ 0, %16 ], [ %113, %110 ]
  %56 = load ptr, ptr %17, align 8, !tbaa !17
  %57 = sext i32 %54 to i64
  %58 = getelementptr inbounds i8, ptr %56, i64 %57
  %59 = load ptr, ptr %18, align 8, !tbaa !17
  %60 = sext i32 %53 to i64
  %61 = tail call i32 @memcmp(ptr noundef %58, ptr noundef %59, i64 noundef %60)
  %62 = icmp eq i32 %61, 0
  br i1 %62, label %63, label %108

63:                                               ; preds = %51
  %64 = icmp slt i32 %55, 0
  %65 = icmp sgt i32 %55, %54
  %66 = or i1 %64, %65
  %67 = icmp sgt i32 %54, %52
  %68 = or i1 %66, %67
  br i1 %68, label %69, label %70

69:                                               ; preds = %63
  tail call void @__cm_runtimeError(ptr noundef nonnull @.str.13) #43
  unreachable

70:                                               ; preds = %63
  %71 = sub nsw i32 %54, %55
  %72 = tail call fastcc ptr @new_string(i32 noundef %71)
  %73 = getelementptr inbounds nuw i8, ptr %72, i64 16
  %74 = load ptr, ptr %73, align 8, !tbaa !17
  %75 = load ptr, ptr %17, align 8, !tbaa !17
  %76 = zext nneg i32 %55 to i64
  %77 = getelementptr inbounds nuw i8, ptr %75, i64 %76
  %78 = zext nneg i32 %71 to i64
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %74, ptr noundef align 1 %77, i64 noundef %78, i1 noundef false) #40
  %79 = load i32, ptr %4, align 4, !tbaa !25
  %80 = load i32, ptr %5, align 8, !tbaa !21
  %81 = icmp eq i32 %79, %80
  br i1 %81, label %82, label %93

82:                                               ; preds = %70
  %83 = icmp eq i32 %79, 0
  %84 = shl nsw i32 %79, 1
  %85 = select i1 %83, i32 4, i32 %84
  %86 = load ptr, ptr %6, align 8, !tbaa !24
  %87 = sext i32 %85 to i64
  %88 = shl nsw i64 %87, 3
  %89 = tail call ptr @realloc(ptr noundef %86, i64 noundef %88) #44
  %90 = icmp eq ptr %89, null
  br i1 %90, label %91, label %92

91:                                               ; preds = %82
  tail call void @__cm_runtimeError(ptr noundef nonnull @.str.20) #43
  unreachable

92:                                               ; preds = %82
  store ptr %89, ptr %6, align 8, !tbaa !24
  store i32 %85, ptr %5, align 8, !tbaa !21
  br label %93

93:                                               ; preds = %92, %70
  %94 = getelementptr inbounds nuw i8, ptr %72, i64 8
  %95 = load i32, ptr %94, align 8, !tbaa !16
  %96 = icmp sgt i32 %95, 0
  br i1 %96, label %97, label %99

97:                                               ; preds = %93
  %98 = add nuw nsw i32 %95, 1
  store i32 %98, ptr %94, align 8, !tbaa !16
  br label %99

99:                                               ; preds = %93, %97
  %100 = load ptr, ptr %6, align 8, !tbaa !24
  %101 = load i32, ptr %4, align 4, !tbaa !25
  %102 = sext i32 %101 to i64
  %103 = getelementptr inbounds ptr, ptr %100, i64 %102
  store ptr %72, ptr %103, align 8, !tbaa !26
  %104 = add nsw i32 %101, 1
  store i32 %104, ptr %4, align 4, !tbaa !25
  %105 = load i32, ptr %9, align 4, !tbaa !20
  %106 = add nsw i32 %105, %54
  %107 = load i32, ptr %13, align 4, !tbaa !20
  br label %110

108:                                              ; preds = %51
  %109 = add nsw i32 %54, 1
  br label %110

110:                                              ; preds = %108, %99
  %111 = phi i32 [ %107, %99 ], [ %52, %108 ]
  %112 = phi i32 [ %105, %99 ], [ %53, %108 ]
  %113 = phi i32 [ %106, %99 ], [ %55, %108 ]
  %114 = phi i32 [ %106, %99 ], [ %109, %108 ]
  %115 = add nsw i32 %112, %114
  %116 = icmp sgt i32 %115, %111
  br i1 %116, label %117, label %51, !llvm.loop !45

117:                                              ; preds = %110, %12
  %118 = phi i32 [ 0, %12 ], [ %113, %110 ]
  %119 = phi i32 [ %14, %12 ], [ %111, %110 ]
  %120 = icmp slt i32 %118, 0
  %121 = icmp sgt i32 %118, %119
  %122 = or i1 %120, %121
  br i1 %122, label %123, label %124

123:                                              ; preds = %117
  tail call void @__cm_runtimeError(ptr noundef nonnull @.str.13) #43
  unreachable

124:                                              ; preds = %117
  %125 = sub nsw i32 %119, %118
  %126 = tail call fastcc ptr @new_string(i32 noundef %125)
  %127 = getelementptr inbounds nuw i8, ptr %126, i64 16
  %128 = load ptr, ptr %127, align 8, !tbaa !17
  %129 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %130 = load ptr, ptr %129, align 8, !tbaa !17
  %131 = zext nneg i32 %118 to i64
  %132 = getelementptr inbounds nuw i8, ptr %130, i64 %131
  %133 = zext nneg i32 %125 to i64
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %128, ptr noundef align 1 %132, i64 noundef %133, i1 noundef false) #40
  %134 = load i32, ptr %4, align 4, !tbaa !25
  %135 = load i32, ptr %5, align 8, !tbaa !21
  %136 = icmp eq i32 %134, %135
  br i1 %136, label %137, label %148

137:                                              ; preds = %124
  %138 = icmp eq i32 %134, 0
  %139 = shl nsw i32 %134, 1
  %140 = select i1 %138, i32 4, i32 %139
  %141 = load ptr, ptr %6, align 8, !tbaa !24
  %142 = sext i32 %140 to i64
  %143 = shl nsw i64 %142, 3
  %144 = tail call ptr @realloc(ptr noundef %141, i64 noundef %143) #44
  %145 = icmp eq ptr %144, null
  br i1 %145, label %146, label %147

146:                                              ; preds = %137
  tail call void @__cm_runtimeError(ptr noundef nonnull @.str.20) #43
  unreachable

147:                                              ; preds = %137
  store ptr %144, ptr %6, align 8, !tbaa !24
  store i32 %140, ptr %5, align 8, !tbaa !21
  br label %148

148:                                              ; preds = %147, %124
  %149 = getelementptr inbounds nuw i8, ptr %126, i64 8
  %150 = load i32, ptr %149, align 8, !tbaa !16
  %151 = icmp sgt i32 %150, 0
  br i1 %151, label %152, label %154

152:                                              ; preds = %148
  %153 = add nuw nsw i32 %150, 1
  store i32 %153, ptr %149, align 8, !tbaa !16
  br label %154

154:                                              ; preds = %152, %148, %49, %45
  %155 = phi ptr [ %25, %49 ], [ %25, %45 ], [ %126, %148 ], [ %126, %152 ]
  %156 = load ptr, ptr %6, align 8, !tbaa !24
  %157 = load i32, ptr %4, align 4, !tbaa !25
  %158 = sext i32 %157 to i64
  %159 = getelementptr inbounds ptr, ptr %156, i64 %158
  store ptr %155, ptr %159, align 8, !tbaa !26
  %160 = add nsw i32 %157, 1
  store i32 %160, ptr %4, align 4, !tbaa !25
  ret ptr %3
}

; Function Attrs: nounwind ssp uwtable(sync)
define nonnull ptr @M6_String_replace(ptr noundef readonly captures(none) %0, ptr noundef readonly captures(address_is_null) %1, ptr noundef readonly captures(address_is_null) %2) #2 {
  %4 = icmp eq ptr %1, null
  br i1 %4, label %21, label %5

5:                                                ; preds = %3
  %6 = getelementptr inbounds nuw i8, ptr %1, i64 12
  %7 = load i32, ptr %6, align 4, !tbaa !20
  %8 = icmp eq i32 %7, 0
  %9 = icmp eq ptr %2, null
  %10 = or i1 %9, %8
  br i1 %10, label %21, label %11

11:                                               ; preds = %5
  %12 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %13 = load i32, ptr %12, align 4, !tbaa !20
  %14 = icmp sgt i32 %7, %13
  br i1 %14, label %47, label %15

15:                                               ; preds = %11
  %16 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %17 = load ptr, ptr %16, align 8, !tbaa !17
  %18 = getelementptr inbounds nuw i8, ptr %1, i64 16
  %19 = load ptr, ptr %18, align 8, !tbaa !17
  %20 = sext i32 %7 to i64
  br label %33

21:                                               ; preds = %5, %3
  %22 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %23 = load i32, ptr %22, align 4, !tbaa !20
  %24 = icmp slt i32 %23, 0
  br i1 %24, label %25, label %26

25:                                               ; preds = %21
  tail call void @__cm_runtimeError(ptr noundef nonnull @.str.13) #43
  unreachable

26:                                               ; preds = %21
  %27 = tail call fastcc ptr @new_string(i32 noundef %23)
  %28 = getelementptr inbounds nuw i8, ptr %27, i64 16
  %29 = load ptr, ptr %28, align 8, !tbaa !17
  %30 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %31 = load ptr, ptr %30, align 8, !tbaa !17
  %32 = zext nneg i32 %23 to i64
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %29, ptr noundef align 1 %31, i64 noundef %32, i1 noundef false) #40
  br label %98

33:                                               ; preds = %15, %33
  %34 = phi i32 [ %7, %15 ], [ %45, %33 ]
  %35 = phi i32 [ 0, %15 ], [ %44, %33 ]
  %36 = phi i32 [ 0, %15 ], [ %42, %33 ]
  %37 = sext i32 %36 to i64
  %38 = getelementptr inbounds i8, ptr %17, i64 %37
  %39 = tail call i32 @memcmp(ptr noundef %38, ptr noundef %19, i64 noundef %20)
  %40 = icmp eq i32 %39, 0
  %41 = add nsw i32 %36, 1
  %42 = select i1 %40, i32 %34, i32 %41
  %43 = zext i1 %40 to i32
  %44 = add nuw nsw i32 %35, %43
  %45 = add nsw i32 %42, %7
  %46 = icmp sgt i32 %45, %13
  br i1 %46, label %47, label %33, !llvm.loop !46

47:                                               ; preds = %33, %11
  %48 = phi i32 [ 0, %11 ], [ %44, %33 ]
  %49 = getelementptr inbounds nuw i8, ptr %2, i64 12
  %50 = load i32, ptr %49, align 4, !tbaa !20
  %51 = sub nsw i32 %50, %7
  %52 = mul nsw i32 %51, %48
  %53 = add nsw i32 %52, %13
  %54 = tail call fastcc ptr @new_string(i32 noundef %53)
  %55 = getelementptr inbounds nuw i8, ptr %54, i64 16
  %56 = load ptr, ptr %55, align 8, !tbaa !17
  %57 = load i32, ptr %12, align 4, !tbaa !20
  %58 = icmp sgt i32 %57, 0
  br i1 %58, label %59, label %98

59:                                               ; preds = %47
  %60 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %61 = getelementptr inbounds nuw i8, ptr %1, i64 16
  %62 = getelementptr inbounds nuw i8, ptr %2, i64 16
  br label %63

63:                                               ; preds = %59, %91
  %64 = phi i32 [ %57, %59 ], [ %96, %91 ]
  %65 = phi i32 [ 0, %59 ], [ %94, %91 ]
  %66 = phi i32 [ 0, %59 ], [ %95, %91 ]
  %67 = load i32, ptr %6, align 4, !tbaa !20
  %68 = add nsw i32 %67, %65
  %69 = icmp sgt i32 %68, %64
  %70 = load ptr, ptr %60, align 8, !tbaa !17
  %71 = sext i32 %65 to i64
  br i1 %69, label %86, label %72

72:                                               ; preds = %63
  %73 = getelementptr inbounds i8, ptr %70, i64 %71
  %74 = load ptr, ptr %61, align 8, !tbaa !17
  %75 = sext i32 %67 to i64
  %76 = tail call i32 @memcmp(ptr noundef %73, ptr noundef %74, i64 noundef %75)
  %77 = icmp eq i32 %76, 0
  br i1 %77, label %78, label %86

78:                                               ; preds = %72
  %79 = sext i32 %66 to i64
  %80 = getelementptr inbounds i8, ptr %56, i64 %79
  %81 = load ptr, ptr %62, align 8, !tbaa !17
  %82 = load i32, ptr %49, align 4, !tbaa !20
  %83 = sext i32 %82 to i64
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %80, ptr noundef align 1 %81, i64 noundef %83, i1 noundef false) #40
  %84 = load i32, ptr %49, align 4, !tbaa !20
  %85 = load i32, ptr %6, align 4, !tbaa !20
  br label %91

86:                                               ; preds = %63, %72
  %87 = getelementptr inbounds i8, ptr %70, i64 %71
  %88 = load i8, ptr %87, align 1, !tbaa !40
  %89 = sext i32 %66 to i64
  %90 = getelementptr inbounds i8, ptr %56, i64 %89
  store i8 %88, ptr %90, align 1, !tbaa !40
  br label %91

91:                                               ; preds = %86, %78
  %92 = phi i32 [ %84, %78 ], [ 1, %86 ]
  %93 = phi i32 [ %85, %78 ], [ 1, %86 ]
  %94 = add nsw i32 %93, %65
  %95 = add nsw i32 %92, %66
  %96 = load i32, ptr %12, align 4, !tbaa !20
  %97 = icmp slt i32 %94, %96
  br i1 %97, label %63, label %98, !llvm.loop !47

98:                                               ; preds = %91, %47, %26
  %99 = phi ptr [ %27, %26 ], [ %54, %47 ], [ %54, %91 ]
  ret ptr %99
}

; Function Attrs: nounwind ssp uwtable(sync)
define double @M6_String_toFloat(ptr noundef readonly captures(none) %0) #2 {
  %2 = alloca ptr, align 8
  call void @llvm.lifetime.start.p0(ptr nonnull %2) #40
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %4 = load ptr, ptr %3, align 8, !tbaa !17
  %5 = call double @"\01_strtod"(ptr noundef %4, ptr noundef nonnull %2) #40
  %6 = load ptr, ptr %2, align 8, !tbaa !39
  %7 = load i8, ptr %6, align 1, !tbaa !40
  %8 = icmp eq i8 %7, 0
  %9 = select i1 %8, double %5, double 0.000000e+00
  call void @llvm.lifetime.end.p0(ptr nonnull %2) #40
  ret double %9
}

; Function Attrs: nounwind ssp uwtable(sync)
define nonnull ptr @M2_IO_in(ptr readnone captures(none) %0) #2 {
  %2 = alloca [256 x i8], align 1
  call void @llvm.lifetime.start.p0(ptr nonnull %2) #40
  store i8 0, ptr %2, align 1, !tbaa !40
  %3 = call i32 (ptr, ...) @scanf(ptr noundef nonnull @.str.15, ptr noundef nonnull %2)
  %4 = icmp eq i32 %3, 1
  br i1 %4, label %6, label %5

5:                                                ; preds = %1
  store i8 0, ptr %2, align 1, !tbaa !40
  br label %6

6:                                                ; preds = %5, %1
  %7 = call i64 @strlen(ptr noundef nonnull readonly dereferenceable(1) %2) #40
  %8 = trunc i64 %7 to i32
  %9 = call fastcc ptr @new_string(i32 noundef %8)
  %10 = getelementptr inbounds nuw i8, ptr %9, i64 16
  %11 = load ptr, ptr %10, align 8, !tbaa !17
  call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %11, ptr noundef nonnull readonly align 1 %2, i64 noundef %7, i1 noundef false) #40
  call void @llvm.lifetime.end.p0(ptr nonnull %2) #40
  ret ptr %9
}

; Function Attrs: nofree nounwind ssp uwtable(sync)
define noundef ptr @M2_IO_out(ptr noundef readnone returned captures(ret: address, provenance) %0, ptr noundef readonly captures(none) %1) #8 {
  %3 = getelementptr inbounds nuw i8, ptr %1, i64 16
  %4 = load ptr, ptr %3, align 8, !tbaa !17
  %5 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.19, ptr noundef %4)
  ret ptr %0
}

; Function Attrs: nounwind ssp uwtable(sync)
define nonnull ptr @M2_IO_readLine(ptr readnone captures(none) %0) #2 {
  %2 = alloca [1024 x i8], align 1
  call void @llvm.lifetime.start.p0(ptr nonnull %2) #40
  %3 = load ptr, ptr @__stdinp, align 8, !tbaa !48
  %4 = call ptr @fgets(ptr noundef nonnull %2, i32 noundef 1024, ptr noundef %3)
  %5 = icmp eq ptr %4, null
  br i1 %5, label %6, label %8

6:                                                ; preds = %1
  %7 = call fastcc ptr @new_string(i32 noundef 0)
  br label %23

8:                                                ; preds = %1
  %9 = call i64 @strlen(ptr noundef nonnull dereferenceable(1) %2) #40
  %10 = icmp eq i64 %9, 0
  br i1 %10, label %17, label %11

11:                                               ; preds = %8
  %12 = getelementptr i8, ptr %2, i64 %9
  %13 = getelementptr i8, ptr %12, i64 -1
  %14 = load i8, ptr %13, align 1, !tbaa !40
  %15 = icmp eq i8 %14, 10
  br i1 %15, label %16, label %17

16:                                               ; preds = %11
  store i8 0, ptr %13, align 1, !tbaa !40
  br label %17

17:                                               ; preds = %16, %11, %8
  %18 = call i64 @strlen(ptr noundef nonnull readonly dereferenceable(1) %2) #40
  %19 = trunc i64 %18 to i32
  %20 = call fastcc ptr @new_string(i32 noundef %19)
  %21 = getelementptr inbounds nuw i8, ptr %20, i64 16
  %22 = load ptr, ptr %21, align 8, !tbaa !17
  call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %22, ptr noundef nonnull readonly align 1 %2, i64 noundef %18, i1 noundef false) #40
  br label %23

23:                                               ; preds = %17, %6
  %24 = phi ptr [ %20, %17 ], [ %7, %6 ]
  call void @llvm.lifetime.end.p0(ptr nonnull %2) #40
  ret ptr %24
}

; Function Attrs: nofree nounwind ssp uwtable(sync)
define range(i32 0, 2) i32 @M2_IO_eof(ptr readnone captures(none) %0) #8 {
  %2 = load ptr, ptr @__stdinp, align 8, !tbaa !48
  %3 = tail call i32 @fgetc(ptr noundef %2)
  %4 = icmp eq i32 %3, -1
  br i1 %4, label %8, label %5

5:                                                ; preds = %1
  %6 = load ptr, ptr @__stdinp, align 8, !tbaa !48
  %7 = tail call i32 @ungetc(i32 noundef %3, ptr noundef %6)
  br label %8

8:                                                ; preds = %1, %5
  %9 = phi i32 [ 0, %5 ], [ 1, %1 ]
  ret i32 %9
}

; Function Attrs: nounwind ssp uwtable(sync)
define range(i32 0, -2147483648) i32 @M2_IO_entropy(ptr readnone captures(none) %0) #2 {
  %2 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(ptr nonnull %2) #40
  store i32 0, ptr %2, align 4, !tbaa !6
  %3 = tail call ptr @"\01_fopen"(ptr noundef nonnull @.str.17, ptr noundef nonnull @.str.18) #40
  %4 = icmp eq ptr %3, null
  br i1 %4, label %10, label %5

5:                                                ; preds = %1
  %6 = call i64 @fread(ptr noundef nonnull %2, i64 noundef 4, i64 noundef 1, ptr noundef nonnull %3)
  %7 = tail call i32 @fclose(ptr noundef nonnull %3)
  %8 = icmp eq i64 %6, 1
  %9 = load i32, ptr %2, align 4
  br i1 %8, label %18, label %10

10:                                               ; preds = %5, %1
  %11 = tail call i64 @time(ptr noundef null) #40
  %12 = trunc i64 %11 to i32
  %13 = mul i32 %12, -1640531535
  %14 = tail call i64 @"\01_clock"() #40
  %15 = trunc i64 %14 to i32
  %16 = mul i32 %15, 40503
  %17 = xor i32 %16, %13
  br label %18

18:                                               ; preds = %5, %10
  %19 = phi i32 [ %17, %10 ], [ %9, %5 ]
  %20 = and i32 %19, 2147483647
  call void @llvm.lifetime.end.p0(ptr nonnull %2) #40
  ret i32 %20
}

; Function Attrs: nounwind ssp uwtable(sync)
define i32 @M2_IO_ticks(ptr readnone captures(none) %0) #2 {
  %2 = alloca %struct.timespec, align 8
  call void @llvm.lifetime.start.p0(ptr nonnull %2) #40
  %3 = call i32 @clock_gettime(i32 noundef 6, ptr noundef nonnull %2) #40
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %5, label %20

5:                                                ; preds = %1
  %6 = load i1, ptr @M2_IO_ticks.started, align 4
  br i1 %6, label %8, label %7

7:                                                ; preds = %5
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 8 dereferenceable(16) @M2_IO_ticks.origin, ptr noundef nonnull align 8 dereferenceable(16) %2, i64 16, i1 false), !tbaa.struct !49
  store i1 true, ptr @M2_IO_ticks.started, align 4
  br label %8

8:                                                ; preds = %7, %5
  %9 = load i64, ptr %2, align 8, !tbaa !52
  %10 = load i64, ptr @M2_IO_ticks.origin, align 8, !tbaa !52
  %11 = sub nsw i64 %9, %10
  %12 = getelementptr inbounds nuw i8, ptr %2, i64 8
  %13 = load i64, ptr %12, align 8, !tbaa !54
  %14 = load i64, ptr getelementptr inbounds nuw (i8, ptr @M2_IO_ticks.origin, i64 8), align 8, !tbaa !54
  %15 = sub nsw i64 %13, %14
  %16 = sdiv i64 %15, 1000000
  %17 = mul nsw i64 %11, 1000
  %18 = add nsw i64 %16, %17
  %19 = trunc i64 %18 to i32
  br label %20

20:                                               ; preds = %1, %8
  %21 = phi i32 [ %19, %8 ], [ 0, %1 ]
  call void @llvm.lifetime.end.p0(ptr nonnull %2) #40
  ret i32 %21
}

; Function Attrs: nounwind ssp uwtable(sync)
define i64 @M2_IO_epoch(ptr readnone captures(none) %0) #2 {
  %2 = tail call i64 @time(ptr noundef null) #40
  ret i64 %2
}

; Function Attrs: nounwind ssp uwtable(sync)
define i32 @M2_IO_localOffset(ptr readnone captures(none) %0) #2 {
  %2 = alloca i64, align 8
  %3 = alloca %struct.tm, align 8
  %4 = alloca %struct.tm, align 8
  call void @llvm.lifetime.start.p0(ptr nonnull %2) #40
  call void @llvm.lifetime.start.p0(ptr nonnull %3) #40
  call void @llvm.lifetime.start.p0(ptr nonnull %4) #40
  %5 = tail call i64 @time(ptr noundef null) #40
  store i64 %5, ptr %2, align 8, !tbaa !50
  %6 = call ptr @localtime_r(ptr noundef nonnull %2, ptr noundef nonnull %3) #40
  %7 = icmp eq ptr %6, null
  br i1 %7, label %40, label %8

8:                                                ; preds = %1
  %9 = call ptr @gmtime_r(ptr noundef nonnull %2, ptr noundef nonnull %4) #40
  %10 = icmp eq ptr %9, null
  br i1 %10, label %40, label %11

11:                                               ; preds = %8
  %12 = getelementptr inbounds nuw i8, ptr %3, i64 8
  %13 = load i32, ptr %12, align 8, !tbaa !55
  %14 = getelementptr inbounds nuw i8, ptr %3, i64 4
  %15 = load i32, ptr %14, align 4, !tbaa !57
  %16 = load i32, ptr %3, align 8, !tbaa !58
  %17 = getelementptr inbounds nuw i8, ptr %4, i64 8
  %18 = load i32, ptr %17, align 8, !tbaa !55
  %19 = getelementptr inbounds nuw i8, ptr %4, i64 4
  %20 = load i32, ptr %19, align 4, !tbaa !57
  %21 = load i32, ptr %4, align 8, !tbaa !58
  %22 = getelementptr inbounds nuw i8, ptr %3, i64 28
  %23 = load i32, ptr %22, align 4, !tbaa !59
  %24 = getelementptr inbounds nuw i8, ptr %4, i64 28
  %25 = load i32, ptr %24, align 4, !tbaa !59
  %26 = sub nsw i32 %23, %25
  %27 = icmp sgt i32 %26, 1
  %28 = icmp slt i32 %26, -1
  %29 = mul nsw i32 %26, 86400
  %30 = select i1 %28, i32 86400, i32 %29
  %31 = select i1 %27, i32 -86400, i32 %30
  %32 = sub i32 %15, %20
  %33 = mul i32 %32, 60
  %34 = sub i32 %13, %18
  %35 = mul i32 %34, 3600
  %36 = sub i32 %16, %21
  %37 = add i32 %36, %35
  %38 = add i32 %37, %33
  %39 = add i32 %38, %31
  br label %40

40:                                               ; preds = %1, %8, %11
  %41 = phi i32 [ %39, %11 ], [ 0, %8 ], [ 0, %1 ]
  call void @llvm.lifetime.end.p0(ptr nonnull %4) #40
  call void @llvm.lifetime.end.p0(ptr nonnull %3) #40
  call void @llvm.lifetime.end.p0(ptr nonnull %2) #40
  ret i32 %41
}

; Function Attrs: nounwind ssp uwtable(sync)
define noundef ptr @M2_IO_sleep(ptr noundef readnone returned captures(ret: address, provenance) %0, i32 noundef %1) #2 {
  %3 = alloca %struct.timespec, align 8
  call void @llvm.lifetime.start.p0(ptr nonnull %3) #40
  %4 = icmp slt i32 %1, 1
  br i1 %4, label %14, label %5

5:                                                ; preds = %2
  %6 = udiv i32 %1, 1000
  %7 = zext nneg i32 %6 to i64
  store i64 %7, ptr %3, align 8, !tbaa !52
  %8 = mul i32 %6, 1000
  %9 = sub i32 %1, %8
  %10 = mul nuw nsw i32 %9, 1000000
  %11 = zext nneg i32 %10 to i64
  %12 = getelementptr inbounds nuw i8, ptr %3, i64 8
  store i64 %11, ptr %12, align 8, !tbaa !54
  %13 = call i32 @"\01_nanosleep"(ptr noundef nonnull %3, ptr noundef null) #40
  br label %14

14:                                               ; preds = %2, %5
  call void @llvm.lifetime.end.p0(ptr nonnull %3) #40
  ret ptr %0
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(read, argmem: none, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable(sync)
define i32 @M2_IO_args(ptr readnone captures(none) %0) #9 {
  %2 = load i32, ptr @gArgCount, align 4, !tbaa !6
  ret i32 %2
}

; Function Attrs: nounwind ssp uwtable(sync)
define nonnull ptr @M2_IO_arg(ptr readnone captures(none) %0, i32 noundef %1) #2 {
  %3 = icmp slt i32 %1, 0
  br i1 %3, label %10, label %4

4:                                                ; preds = %2
  %5 = load i32, ptr @gArgCount, align 4, !tbaa !6
  %6 = icmp sge i32 %1, %5
  %7 = load ptr, ptr @gArgValues, align 8
  %8 = icmp eq ptr %7, null
  %9 = select i1 %6, i1 true, i1 %8
  br i1 %9, label %10, label %12

10:                                               ; preds = %4, %2
  %11 = tail call fastcc ptr @new_string(i32 noundef 0)
  br label %21

12:                                               ; preds = %4
  %13 = zext nneg i32 %1 to i64
  %14 = getelementptr inbounds nuw ptr, ptr %7, i64 %13
  %15 = load ptr, ptr %14, align 8, !tbaa !39
  %16 = tail call i64 @strlen(ptr noundef nonnull readonly dereferenceable(1) %15) #40
  %17 = trunc i64 %16 to i32
  %18 = tail call fastcc ptr @new_string(i32 noundef %17)
  %19 = getelementptr inbounds nuw i8, ptr %18, i64 16
  %20 = load ptr, ptr %19, align 8, !tbaa !17
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %20, ptr noundef nonnull readonly align 1 %15, i64 noundef %16, i1 noundef false) #40
  br label %21

21:                                               ; preds = %12, %10
  %22 = phi ptr [ %11, %10 ], [ %18, %12 ]
  ret ptr %22
}

; Function Attrs: nounwind ssp uwtable(sync)
define noundef ptr @M2_IO_err(ptr noundef readnone returned captures(ret: address, provenance) %0, ptr noundef readonly captures(none) %1) #2 {
  %3 = getelementptr inbounds nuw i8, ptr %1, i64 16
  %4 = load ptr, ptr %3, align 8, !tbaa !17
  %5 = load ptr, ptr @__stderrp, align 8, !tbaa !48
  %6 = tail call i32 @"\01_fputs"(ptr noundef %4, ptr noundef %5) #40
  ret ptr %0
}

; Function Attrs: nofree noreturn nounwind ssp uwtable(sync)
define void @M2_IO_exit(ptr readnone captures(none) %0, i32 noundef %1) #10 {
  tail call void @exit(i32 noundef %1) #45
  unreachable
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(read, argmem: none, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable(sync)
define i32 @M2_IO_allocated(ptr readnone captures(none) %0) #9 {
  %2 = load i32, ptr @gLiveObjects, align 4, !tbaa !6
  ret i32 %2
}

; Function Attrs: nounwind ssp uwtable(sync)
define range(i32 0, 2) i32 @M4_File_open(ptr noundef captures(none) %0, ptr noundef readonly captures(none) %1, ptr noundef readonly captures(none) %2) #2 {
  %4 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %5 = load ptr, ptr %4, align 8, !tbaa !29
  %6 = icmp eq ptr %5, null
  br i1 %6, label %9, label %7

7:                                                ; preds = %3
  %8 = tail call i32 @fclose(ptr noundef nonnull %5)
  store ptr null, ptr %4, align 8, !tbaa !29
  br label %9

9:                                                ; preds = %7, %3
  %10 = getelementptr inbounds nuw i8, ptr %1, i64 16
  %11 = load ptr, ptr %10, align 8, !tbaa !17
  %12 = getelementptr inbounds nuw i8, ptr %2, i64 16
  %13 = load ptr, ptr %12, align 8, !tbaa !17
  %14 = tail call ptr @"\01_fopen"(ptr noundef %11, ptr noundef %13) #40
  store ptr %14, ptr %4, align 8, !tbaa !29
  %15 = icmp ne ptr %14, null
  %16 = zext i1 %15 to i32
  ret i32 %16
}

; Function Attrs: nounwind ssp uwtable(sync)
define nonnull ptr @M4_File_readLine(ptr noundef readonly captures(none) %0) #2 {
  %2 = alloca [4096 x i8], align 1
  call void @llvm.lifetime.start.p0(ptr nonnull %2) #40
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %4 = load ptr, ptr %3, align 8, !tbaa !29
  %5 = icmp eq ptr %4, null
  br i1 %5, label %9, label %6

6:                                                ; preds = %1
  %7 = call ptr @fgets(ptr noundef nonnull %2, i32 noundef 4096, ptr noundef nonnull %4)
  %8 = icmp eq ptr %7, null
  br i1 %8, label %9, label %11

9:                                                ; preds = %6, %1
  %10 = call fastcc ptr @new_string(i32 noundef 0)
  br label %26

11:                                               ; preds = %6
  %12 = call i64 @strlen(ptr noundef nonnull dereferenceable(1) %2) #40
  %13 = icmp eq i64 %12, 0
  br i1 %13, label %20, label %14

14:                                               ; preds = %11
  %15 = getelementptr i8, ptr %2, i64 %12
  %16 = getelementptr i8, ptr %15, i64 -1
  %17 = load i8, ptr %16, align 1, !tbaa !40
  %18 = icmp eq i8 %17, 10
  br i1 %18, label %19, label %20

19:                                               ; preds = %14
  store i8 0, ptr %16, align 1, !tbaa !40
  br label %20

20:                                               ; preds = %19, %14, %11
  %21 = call i64 @strlen(ptr noundef nonnull readonly dereferenceable(1) %2) #40
  %22 = trunc i64 %21 to i32
  %23 = call fastcc ptr @new_string(i32 noundef %22)
  %24 = getelementptr inbounds nuw i8, ptr %23, i64 16
  %25 = load ptr, ptr %24, align 8, !tbaa !17
  call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %25, ptr noundef nonnull readonly align 1 %2, i64 noundef %21, i1 noundef false) #40
  br label %26

26:                                               ; preds = %20, %9
  %27 = phi ptr [ %23, %20 ], [ %10, %9 ]
  call void @llvm.lifetime.end.p0(ptr nonnull %2) #40
  ret ptr %27
}

; Function Attrs: nounwind ssp uwtable(sync)
define ptr @M4_File_readAll(ptr noundef readonly captures(none) %0) #2 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %3 = load ptr, ptr %2, align 8, !tbaa !29
  %4 = icmp eq ptr %3, null
  br i1 %4, label %5, label %7

5:                                                ; preds = %1
  %6 = tail call fastcc ptr @new_string(i32 noundef 0)
  br label %38

7:                                                ; preds = %1, %20
  %8 = phi ptr [ %21, %20 ], [ null, %1 ]
  %9 = phi i64 [ %26, %20 ], [ 0, %1 ]
  %10 = phi i64 [ %22, %20 ], [ 0, %1 ]
  %11 = add i64 %9, 4097
  %12 = icmp ugt i64 %11, %10
  br i1 %12, label %13, label %20

13:                                               ; preds = %7
  %14 = icmp eq i64 %10, 0
  %15 = shl i64 %10, 1
  %16 = select i1 %14, i64 8192, i64 %15
  %17 = tail call ptr @realloc(ptr noundef %8, i64 noundef %16) #44
  %18 = icmp eq ptr %17, null
  br i1 %18, label %19, label %20

19:                                               ; preds = %13
  tail call void @__cm_runtimeError(ptr noundef nonnull @.str.29) #43
  unreachable

20:                                               ; preds = %13, %7
  %21 = phi ptr [ %17, %13 ], [ %8, %7 ]
  %22 = phi i64 [ %16, %13 ], [ %10, %7 ]
  %23 = getelementptr inbounds nuw i8, ptr %21, i64 %9
  %24 = load ptr, ptr %2, align 8, !tbaa !29
  %25 = tail call i64 @fread(ptr noundef %23, i64 noundef 1, i64 noundef 4096, ptr noundef %24)
  %26 = add i64 %25, %9
  %27 = icmp ult i64 %25, 4096
  br i1 %27, label %28, label %7

28:                                               ; preds = %20
  %29 = icmp eq ptr %21, null
  br i1 %29, label %30, label %32

30:                                               ; preds = %28
  %31 = tail call fastcc ptr @new_string(i32 noundef 0)
  br label %38

32:                                               ; preds = %28
  %33 = getelementptr inbounds nuw i8, ptr %21, i64 %26
  store i8 0, ptr %33, align 1, !tbaa !40
  %34 = tail call ptr @__catmint_new(ptr noundef nonnull @RString)
  %35 = getelementptr inbounds nuw i8, ptr %34, i64 16
  %36 = getelementptr inbounds nuw i8, ptr %34, i64 12
  %37 = trunc i64 %26 to i32
  store i32 %37, ptr %36, align 4, !tbaa !20
  store ptr %21, ptr %35, align 8, !tbaa !17
  br label %38

38:                                               ; preds = %32, %30, %5
  %39 = phi ptr [ %34, %32 ], [ %31, %30 ], [ %6, %5 ]
  ret ptr %39
}

; Function Attrs: nounwind ssp uwtable(sync)
define noundef ptr @M4_File_write(ptr noundef readonly returned captures(ret: address, provenance) %0, ptr noundef readonly captures(none) %1) #2 {
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %4 = load ptr, ptr %3, align 8, !tbaa !29
  %5 = icmp eq ptr %4, null
  br i1 %5, label %13, label %6

6:                                                ; preds = %2
  %7 = getelementptr inbounds nuw i8, ptr %1, i64 16
  %8 = load ptr, ptr %7, align 8, !tbaa !17
  %9 = getelementptr inbounds nuw i8, ptr %1, i64 12
  %10 = load i32, ptr %9, align 4, !tbaa !20
  %11 = sext i32 %10 to i64
  %12 = tail call i64 @"\01_fwrite"(ptr noundef %8, i64 noundef 1, i64 noundef %11, ptr noundef nonnull %4) #40
  br label %13

13:                                               ; preds = %6, %2
  ret ptr %0
}

; Function Attrs: nofree nounwind ssp uwtable(sync)
define range(i32 0, 2) i32 @M4_File_eof(ptr noundef readonly captures(none) %0) #8 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %3 = load ptr, ptr %2, align 8, !tbaa !29
  %4 = icmp eq ptr %3, null
  br i1 %4, label %11, label %5

5:                                                ; preds = %1
  %6 = tail call i32 @fgetc(ptr noundef nonnull %3)
  %7 = icmp eq i32 %6, -1
  br i1 %7, label %11, label %8

8:                                                ; preds = %5
  %9 = load ptr, ptr %2, align 8, !tbaa !29
  %10 = tail call i32 @ungetc(i32 noundef %6, ptr noundef %9)
  br label %11

11:                                               ; preds = %5, %1, %8
  %12 = phi i32 [ 1, %1 ], [ 0, %8 ], [ 1, %5 ]
  ret i32 %12
}

; Function Attrs: nofree nounwind ssp uwtable(sync)
define noundef ptr @M4_File_close(ptr noundef returned captures(ret: address, provenance) %0) #8 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %3 = load ptr, ptr %2, align 8, !tbaa !29
  %4 = icmp eq ptr %3, null
  br i1 %4, label %7, label %5

5:                                                ; preds = %1
  %6 = tail call i32 @fclose(ptr noundef nonnull %3)
  store ptr null, ptr %2, align 8, !tbaa !29
  br label %7

7:                                                ; preds = %5, %1
  ret ptr %0
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable(sync)
define range(i32 0, 2) i32 @M4_File_isOpen(ptr noundef readonly captures(none) %0) #4 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %3 = load ptr, ptr %2, align 8, !tbaa !29
  %4 = icmp ne ptr %3, null
  %5 = zext i1 %4 to i32
  ret i32 %5
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable(sync)
define i32 @M5_Bytes_len(ptr noundef readonly captures(none) %0) #4 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %3 = load i32, ptr %2, align 4, !tbaa !36
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable(sync)
define range(i32 0, 256) i32 @M5_Bytes_get(ptr noundef readonly captures(none) %0, i32 noundef %1) #2 {
  %3 = alloca [128 x i8], align 1
  %4 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %5 = load i32, ptr %4, align 4, !tbaa !36
  %6 = icmp sgt i32 %1, -1
  %7 = icmp slt i32 %1, %5
  %8 = and i1 %6, %7
  br i1 %8, label %12, label %9

9:                                                ; preds = %2
  call void @llvm.lifetime.start.p0(ptr nonnull %3) #40
  %10 = add nsw i32 %5, -1
  %11 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr nonnull dereferenceable(1) %3, i64 128, ptr nonnull @.str.47, ptr nonnull @.str.9, i32 %1, i32 %10)
  call void @__cm_runtimeError(ptr noundef nonnull %3) #43
  unreachable

12:                                               ; preds = %2
  %13 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %14 = load ptr, ptr %13, align 8, !tbaa !34
  %15 = zext nneg i32 %1 to i64
  %16 = getelementptr inbounds nuw i8, ptr %14, i64 %15
  %17 = load i8, ptr %16, align 1, !tbaa !40
  %18 = zext i8 %17 to i32
  ret i32 %18
}

; Function Attrs: nounwind ssp uwtable(sync)
define noundef i32 @M5_Bytes_set(ptr noundef readonly captures(none) %0, i32 noundef %1, i32 noundef returned %2) #2 {
  %4 = alloca [128 x i8], align 1
  %5 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %6 = load i32, ptr %5, align 4, !tbaa !36
  %7 = icmp sgt i32 %1, -1
  %8 = icmp slt i32 %1, %6
  %9 = and i1 %7, %8
  br i1 %9, label %13, label %10

10:                                               ; preds = %3
  call void @llvm.lifetime.start.p0(ptr nonnull %4) #40
  %11 = add nsw i32 %6, -1
  %12 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr nonnull dereferenceable(1) %4, i64 128, ptr nonnull @.str.47, ptr nonnull @.str.9, i32 %1, i32 %11)
  call void @__cm_runtimeError(ptr noundef nonnull %4) #43
  unreachable

13:                                               ; preds = %3
  %14 = trunc i32 %2 to i8
  %15 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %16 = load ptr, ptr %15, align 8, !tbaa !34
  %17 = zext nneg i32 %1 to i64
  %18 = getelementptr inbounds nuw i8, ptr %16, i64 %17
  store i8 %14, ptr %18, align 1, !tbaa !40
  ret i32 %2
}

; Function Attrs: nofree norecurse nounwind ssp memory(readwrite, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable(sync)
define noundef ptr @M5_Bytes_fill(ptr noundef readonly returned captures(ret: address, provenance) %0, i32 noundef %1) #11 {
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %4 = load ptr, ptr %3, align 8, !tbaa !34
  %5 = icmp eq ptr %4, null
  br i1 %5, label %11, label %6

6:                                                ; preds = %2
  %7 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %8 = load i32, ptr %7, align 4, !tbaa !36
  %9 = sext i32 %8 to i64
  %10 = trunc i32 %1 to i8
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 %4, i8 noundef %10, i64 noundef %9, i1 noundef false) #40
  br label %11

11:                                               ; preds = %6, %2
  ret ptr %0
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable(sync)
define i32 @M4_Ints_len(ptr noundef readonly captures(none) %0) #4 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %3 = load i32, ptr %2, align 4, !tbaa !60
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable(sync)
define i64 @M4_Ints_get(ptr noundef readonly captures(none) %0, i32 noundef %1) #2 {
  %3 = alloca [128 x i8], align 1
  %4 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %5 = load i32, ptr %4, align 4, !tbaa !60
  %6 = icmp sgt i32 %1, -1
  %7 = icmp slt i32 %1, %5
  %8 = and i1 %6, %7
  br i1 %8, label %12, label %9

9:                                                ; preds = %2
  call void @llvm.lifetime.start.p0(ptr nonnull %3) #40
  %10 = add nsw i32 %5, -1
  %11 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr nonnull dereferenceable(1) %3, i64 128, ptr nonnull @.str.47, ptr nonnull @.str.10, i32 %1, i32 %10)
  call void @__cm_runtimeError(ptr noundef nonnull %3) #43
  unreachable

12:                                               ; preds = %2
  %13 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %14 = load ptr, ptr %13, align 8, !tbaa !63
  %15 = zext nneg i32 %1 to i64
  %16 = getelementptr inbounds nuw i64, ptr %14, i64 %15
  %17 = load i64, ptr %16, align 8, !tbaa !64
  ret i64 %17
}

; Function Attrs: nounwind ssp uwtable(sync)
define noundef i64 @M4_Ints_set(ptr noundef readonly captures(none) %0, i32 noundef %1, i64 noundef returned %2) #2 {
  %4 = alloca [128 x i8], align 1
  %5 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %6 = load i32, ptr %5, align 4, !tbaa !60
  %7 = icmp sgt i32 %1, -1
  %8 = icmp slt i32 %1, %6
  %9 = and i1 %7, %8
  br i1 %9, label %13, label %10

10:                                               ; preds = %3
  call void @llvm.lifetime.start.p0(ptr nonnull %4) #40
  %11 = add nsw i32 %6, -1
  %12 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr nonnull dereferenceable(1) %4, i64 128, ptr nonnull @.str.47, ptr nonnull @.str.10, i32 %1, i32 %11)
  call void @__cm_runtimeError(ptr noundef nonnull %4) #43
  unreachable

13:                                               ; preds = %3
  %14 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %15 = load ptr, ptr %14, align 8, !tbaa !63
  %16 = zext nneg i32 %1 to i64
  %17 = getelementptr inbounds nuw i64, ptr %15, i64 %16
  store i64 %2, ptr %17, align 8, !tbaa !64
  ret i64 %2
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(write, argmem: readwrite, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable(sync)
define noundef ptr @M4_Ints_fill(ptr noundef readonly returned captures(ret: address, provenance) %0, i64 noundef %1) #12 {
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %4 = load i32, ptr %3, align 4, !tbaa !60
  %5 = icmp sgt i32 %4, 0
  br i1 %5, label %6, label %32

6:                                                ; preds = %2
  %7 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %8 = load ptr, ptr %7, align 8, !tbaa !63
  %9 = zext nneg i32 %4 to i64
  %10 = icmp ult i32 %4, 8
  br i1 %10, label %25, label %11

11:                                               ; preds = %6
  %12 = and i64 %9, 2147483640
  %13 = insertelement <2 x i64> poison, i64 %1, i64 0
  %14 = shufflevector <2 x i64> %13, <2 x i64> poison, <2 x i32> zeroinitializer
  br label %15

15:                                               ; preds = %15, %11
  %16 = phi i64 [ 0, %11 ], [ %21, %15 ]
  %17 = getelementptr inbounds nuw i64, ptr %8, i64 %16
  %18 = getelementptr inbounds nuw i8, ptr %17, i64 16
  %19 = getelementptr inbounds nuw i8, ptr %17, i64 32
  %20 = getelementptr inbounds nuw i8, ptr %17, i64 48
  store <2 x i64> %14, ptr %17, align 8, !tbaa !64
  store <2 x i64> %14, ptr %18, align 8, !tbaa !64
  store <2 x i64> %14, ptr %19, align 8, !tbaa !64
  store <2 x i64> %14, ptr %20, align 8, !tbaa !64
  %21 = add nuw i64 %16, 8
  %22 = icmp eq i64 %21, %12
  br i1 %22, label %23, label %15, !llvm.loop !66

23:                                               ; preds = %15
  %24 = icmp eq i64 %12, %9
  br i1 %24, label %32, label %25

25:                                               ; preds = %6, %23
  %26 = phi i64 [ 0, %6 ], [ %12, %23 ]
  br label %27

27:                                               ; preds = %25, %27
  %28 = phi i64 [ %30, %27 ], [ %26, %25 ]
  %29 = getelementptr inbounds nuw i64, ptr %8, i64 %28
  store i64 %1, ptr %29, align 8, !tbaa !64
  %30 = add nuw nsw i64 %28, 1
  %31 = icmp eq i64 %30, %9
  br i1 %31, label %32, label %27, !llvm.loop !69

32:                                               ; preds = %27, %23, %2
  ret ptr %0
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable(sync)
define i32 @M6_Floats_len(ptr noundef readonly captures(none) %0) #4 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %3 = load i32, ptr %2, align 4, !tbaa !70
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable(sync)
define double @M6_Floats_get(ptr noundef readonly captures(none) %0, i32 noundef %1) #2 {
  %3 = alloca [128 x i8], align 1
  %4 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %5 = load i32, ptr %4, align 4, !tbaa !70
  %6 = icmp sgt i32 %1, -1
  %7 = icmp slt i32 %1, %5
  %8 = and i1 %6, %7
  br i1 %8, label %12, label %9

9:                                                ; preds = %2
  call void @llvm.lifetime.start.p0(ptr nonnull %3) #40
  %10 = add nsw i32 %5, -1
  %11 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr nonnull dereferenceable(1) %3, i64 128, ptr nonnull @.str.47, ptr nonnull @.str.11, i32 %1, i32 %10)
  call void @__cm_runtimeError(ptr noundef nonnull %3) #43
  unreachable

12:                                               ; preds = %2
  %13 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %14 = load ptr, ptr %13, align 8, !tbaa !73
  %15 = zext nneg i32 %1 to i64
  %16 = getelementptr inbounds nuw double, ptr %14, i64 %15
  %17 = load double, ptr %16, align 8, !tbaa !74
  ret double %17
}

; Function Attrs: nounwind ssp uwtable(sync)
define noundef double @M6_Floats_set(ptr noundef readonly captures(none) %0, i32 noundef %1, double noundef returned %2) #2 {
  %4 = alloca [128 x i8], align 1
  %5 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %6 = load i32, ptr %5, align 4, !tbaa !70
  %7 = icmp sgt i32 %1, -1
  %8 = icmp slt i32 %1, %6
  %9 = and i1 %7, %8
  br i1 %9, label %13, label %10

10:                                               ; preds = %3
  call void @llvm.lifetime.start.p0(ptr nonnull %4) #40
  %11 = add nsw i32 %6, -1
  %12 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr nonnull dereferenceable(1) %4, i64 128, ptr nonnull @.str.47, ptr nonnull @.str.11, i32 %1, i32 %11)
  call void @__cm_runtimeError(ptr noundef nonnull %4) #43
  unreachable

13:                                               ; preds = %3
  %14 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %15 = load ptr, ptr %14, align 8, !tbaa !73
  %16 = zext nneg i32 %1 to i64
  %17 = getelementptr inbounds nuw double, ptr %15, i64 %16
  store double %2, ptr %17, align 8, !tbaa !74
  ret double %2
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(write, argmem: readwrite, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable(sync)
define noundef ptr @M6_Floats_fill(ptr noundef readonly returned captures(ret: address, provenance) %0, double noundef %1) #12 {
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %4 = load i32, ptr %3, align 4, !tbaa !70
  %5 = icmp sgt i32 %4, 0
  br i1 %5, label %6, label %32

6:                                                ; preds = %2
  %7 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %8 = load ptr, ptr %7, align 8, !tbaa !73
  %9 = zext nneg i32 %4 to i64
  %10 = icmp ult i32 %4, 8
  br i1 %10, label %25, label %11

11:                                               ; preds = %6
  %12 = and i64 %9, 2147483640
  %13 = insertelement <2 x double> poison, double %1, i64 0
  %14 = shufflevector <2 x double> %13, <2 x double> poison, <2 x i32> zeroinitializer
  br label %15

15:                                               ; preds = %15, %11
  %16 = phi i64 [ 0, %11 ], [ %21, %15 ]
  %17 = getelementptr inbounds nuw double, ptr %8, i64 %16
  %18 = getelementptr inbounds nuw i8, ptr %17, i64 16
  %19 = getelementptr inbounds nuw i8, ptr %17, i64 32
  %20 = getelementptr inbounds nuw i8, ptr %17, i64 48
  store <2 x double> %14, ptr %17, align 8, !tbaa !74
  store <2 x double> %14, ptr %18, align 8, !tbaa !74
  store <2 x double> %14, ptr %19, align 8, !tbaa !74
  store <2 x double> %14, ptr %20, align 8, !tbaa !74
  %21 = add nuw i64 %16, 8
  %22 = icmp eq i64 %21, %12
  br i1 %22, label %23, label %15, !llvm.loop !76

23:                                               ; preds = %15
  %24 = icmp eq i64 %12, %9
  br i1 %24, label %32, label %25

25:                                               ; preds = %6, %23
  %26 = phi i64 [ 0, %6 ], [ %12, %23 ]
  br label %27

27:                                               ; preds = %25, %27
  %28 = phi i64 [ %30, %27 ], [ %26, %25 ]
  %29 = getelementptr inbounds nuw double, ptr %8, i64 %28
  store double %1, ptr %29, align 8, !tbaa !74
  %30 = add nuw nsw i64 %28, 1
  %31 = icmp eq i64 %30, %9
  br i1 %31, label %32, label %27, !llvm.loop !77

32:                                               ; preds = %27, %23, %2
  ret ptr %0
}

; Function Attrs: nounwind ssp uwtable(sync)
define range(i32 0, 2) i32 @M7_Process_open(ptr noundef captures(none) %0, ptr noundef readonly captures(none) %1, ptr noundef readonly captures(none) %2) #2 {
  %4 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %5 = load ptr, ptr %4, align 8, !tbaa !32
  %6 = icmp eq ptr %5, null
  br i1 %6, label %9, label %7

7:                                                ; preds = %3
  %8 = tail call i32 @pclose(ptr noundef nonnull %5)
  store ptr null, ptr %4, align 8, !tbaa !32
  br label %9

9:                                                ; preds = %7, %3
  %10 = getelementptr inbounds nuw i8, ptr %1, i64 16
  %11 = load ptr, ptr %10, align 8, !tbaa !17
  %12 = getelementptr inbounds nuw i8, ptr %2, i64 16
  %13 = load ptr, ptr %12, align 8, !tbaa !17
  %14 = tail call ptr @"\01_popen"(ptr noundef %11, ptr noundef %13) #40
  store ptr %14, ptr %4, align 8, !tbaa !32
  %15 = icmp ne ptr %14, null
  %16 = zext i1 %15 to i32
  ret i32 %16
}

; Function Attrs: nounwind ssp uwtable(sync)
define nonnull ptr @M7_Process_readLine(ptr noundef readonly captures(none) %0) #2 {
  %2 = alloca [4096 x i8], align 1
  call void @llvm.lifetime.start.p0(ptr nonnull %2) #40
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %4 = load ptr, ptr %3, align 8, !tbaa !32
  %5 = icmp eq ptr %4, null
  br i1 %5, label %9, label %6

6:                                                ; preds = %1
  %7 = call ptr @fgets(ptr noundef nonnull %2, i32 noundef 4096, ptr noundef nonnull %4)
  %8 = icmp eq ptr %7, null
  br i1 %8, label %9, label %11

9:                                                ; preds = %6, %1
  %10 = call fastcc ptr @new_string(i32 noundef 0)
  br label %26

11:                                               ; preds = %6
  %12 = call i64 @strlen(ptr noundef nonnull dereferenceable(1) %2) #40
  %13 = icmp eq i64 %12, 0
  br i1 %13, label %20, label %14

14:                                               ; preds = %11
  %15 = getelementptr i8, ptr %2, i64 %12
  %16 = getelementptr i8, ptr %15, i64 -1
  %17 = load i8, ptr %16, align 1, !tbaa !40
  %18 = icmp eq i8 %17, 10
  br i1 %18, label %19, label %20

19:                                               ; preds = %14
  store i8 0, ptr %16, align 1, !tbaa !40
  br label %20

20:                                               ; preds = %19, %14, %11
  %21 = call i64 @strlen(ptr noundef nonnull readonly dereferenceable(1) %2) #40
  %22 = trunc i64 %21 to i32
  %23 = call fastcc ptr @new_string(i32 noundef %22)
  %24 = getelementptr inbounds nuw i8, ptr %23, i64 16
  %25 = load ptr, ptr %24, align 8, !tbaa !17
  call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %25, ptr noundef nonnull readonly align 1 %2, i64 noundef %21, i1 noundef false) #40
  br label %26

26:                                               ; preds = %20, %9
  %27 = phi ptr [ %23, %20 ], [ %10, %9 ]
  call void @llvm.lifetime.end.p0(ptr nonnull %2) #40
  ret ptr %27
}

; Function Attrs: nounwind ssp uwtable(sync)
define noundef ptr @M7_Process_write(ptr noundef readonly returned captures(ret: address, provenance) %0, ptr noundef readonly captures(none) %1) #2 {
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %4 = load ptr, ptr %3, align 8, !tbaa !32
  %5 = icmp eq ptr %4, null
  br i1 %5, label %13, label %6

6:                                                ; preds = %2
  %7 = getelementptr inbounds nuw i8, ptr %1, i64 16
  %8 = load ptr, ptr %7, align 8, !tbaa !17
  %9 = getelementptr inbounds nuw i8, ptr %1, i64 12
  %10 = load i32, ptr %9, align 4, !tbaa !20
  %11 = sext i32 %10 to i64
  %12 = tail call i64 @"\01_fwrite"(ptr noundef %8, i64 noundef 1, i64 noundef %11, ptr noundef nonnull %4) #40
  br label %13

13:                                               ; preds = %6, %2
  ret ptr %0
}

; Function Attrs: nofree nounwind ssp uwtable(sync)
define range(i32 0, 2) i32 @M7_Process_eof(ptr noundef readonly captures(none) %0) #8 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %3 = load ptr, ptr %2, align 8, !tbaa !32
  %4 = icmp eq ptr %3, null
  br i1 %4, label %11, label %5

5:                                                ; preds = %1
  %6 = tail call i32 @fgetc(ptr noundef nonnull %3)
  %7 = icmp eq i32 %6, -1
  br i1 %7, label %11, label %8

8:                                                ; preds = %5
  %9 = load ptr, ptr %2, align 8, !tbaa !32
  %10 = tail call i32 @ungetc(i32 noundef %6, ptr noundef %9)
  br label %11

11:                                               ; preds = %5, %1, %8
  %12 = phi i32 [ 1, %1 ], [ 0, %8 ], [ 1, %5 ]
  ret i32 %12
}

; Function Attrs: nofree nounwind ssp uwtable(sync)
define range(i32 -1, 256) i32 @M7_Process_finish(ptr noundef captures(none) %0) #8 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %3 = load ptr, ptr %2, align 8, !tbaa !32
  %4 = icmp eq ptr %3, null
  br i1 %4, label %15, label %5

5:                                                ; preds = %1
  %6 = tail call i32 @pclose(ptr noundef nonnull %3)
  store ptr null, ptr %2, align 8, !tbaa !32
  %7 = icmp eq i32 %6, -1
  br i1 %7, label %15, label %8

8:                                                ; preds = %5
  %9 = and i32 %6, 127
  switch i32 %9, label %13 [
    i32 0, label %10
    i32 127, label %15
  ]

10:                                               ; preds = %8
  %11 = lshr i32 %6, 8
  %12 = and i32 %11, 255
  br label %15

13:                                               ; preds = %8
  %14 = or disjoint i32 %9, 128
  br label %15

15:                                               ; preds = %13, %10, %8, %5, %1
  %16 = phi i32 [ -1, %1 ], [ -1, %5 ], [ %12, %10 ], [ %14, %13 ], [ -1, %8 ]
  ret i32 %16
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable(sync)
define i32 @M4_List_len(ptr noundef readonly captures(none) %0) #4 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %3 = load i32, ptr %2, align 4, !tbaa !25
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable(sync)
define ptr @M4_List_get(ptr noundef readonly captures(none) %0, i32 noundef %1) #2 {
  %3 = icmp slt i32 %1, 0
  br i1 %3, label %8, label %4

4:                                                ; preds = %2
  %5 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %6 = load i32, ptr %5, align 4, !tbaa !25
  %7 = icmp slt i32 %1, %6
  br i1 %7, label %9, label %8

8:                                                ; preds = %4, %2
  tail call void @__cm_runtimeError(ptr noundef nonnull @.str.44) #43
  unreachable

9:                                                ; preds = %4
  %10 = getelementptr inbounds nuw i8, ptr %0, i64 24
  %11 = load ptr, ptr %10, align 8, !tbaa !24
  %12 = zext nneg i32 %1 to i64
  %13 = getelementptr inbounds nuw ptr, ptr %11, i64 %12
  %14 = load ptr, ptr %13, align 8, !tbaa !26
  ret ptr %14
}

; Function Attrs: nounwind ssp uwtable(sync)
define noundef ptr @M4_List_set(ptr noundef readonly captures(none) %0, i32 noundef %1, ptr noundef returned %2) #2 {
  %4 = icmp slt i32 %1, 0
  br i1 %4, label %9, label %5

5:                                                ; preds = %3
  %6 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %7 = load i32, ptr %6, align 4, !tbaa !25
  %8 = icmp slt i32 %1, %7
  br i1 %8, label %10, label %9

9:                                                ; preds = %5, %3
  tail call void @__cm_runtimeError(ptr noundef nonnull @.str.44) #43
  unreachable

10:                                               ; preds = %5
  %11 = getelementptr inbounds nuw i8, ptr %0, i64 24
  %12 = load ptr, ptr %11, align 8, !tbaa !24
  %13 = zext nneg i32 %1 to i64
  %14 = getelementptr inbounds nuw ptr, ptr %12, i64 %13
  %15 = load ptr, ptr %14, align 8, !tbaa !26
  %16 = icmp eq ptr %2, null
  br i1 %16, label %23, label %17

17:                                               ; preds = %10
  %18 = getelementptr inbounds nuw i8, ptr %2, i64 8
  %19 = load i32, ptr %18, align 8, !tbaa !16
  %20 = icmp sgt i32 %19, 0
  br i1 %20, label %21, label %23

21:                                               ; preds = %17
  %22 = add nuw nsw i32 %19, 1
  store i32 %22, ptr %18, align 8, !tbaa !16
  br label %23

23:                                               ; preds = %10, %17, %21
  store ptr %2, ptr %14, align 8, !tbaa !26
  %24 = icmp eq ptr %15, null
  br i1 %24, label %33, label %25

25:                                               ; preds = %23
  %26 = getelementptr inbounds nuw i8, ptr %15, i64 8
  %27 = load i32, ptr %26, align 8, !tbaa !16
  %28 = icmp eq i32 %27, 0
  br i1 %28, label %33, label %29

29:                                               ; preds = %25
  %30 = add nsw i32 %27, -1
  store i32 %30, ptr %26, align 8, !tbaa !16
  %31 = icmp eq i32 %30, 0
  br i1 %31, label %32, label %33

32:                                               ; preds = %29
  store i32 1, ptr %26, align 8, !tbaa !16
  tail call fastcc void @object_free(ptr noundef %15)
  br label %33

33:                                               ; preds = %23, %25, %29, %32
  ret ptr %2
}

; Function Attrs: nounwind ssp uwtable(sync)
define noundef ptr @M4_List_append(ptr noundef returned captures(ret: address, provenance) %0, ptr noundef %1) #2 {
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %4 = load i32, ptr %3, align 4, !tbaa !25
  %5 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %6 = load i32, ptr %5, align 8, !tbaa !21
  %7 = icmp eq i32 %4, %6
  br i1 %7, label %8, label %20

8:                                                ; preds = %2
  %9 = icmp eq i32 %4, 0
  %10 = shl nsw i32 %4, 1
  %11 = select i1 %9, i32 4, i32 %10
  %12 = getelementptr inbounds nuw i8, ptr %0, i64 24
  %13 = load ptr, ptr %12, align 8, !tbaa !24
  %14 = sext i32 %11 to i64
  %15 = shl nsw i64 %14, 3
  %16 = tail call ptr @realloc(ptr noundef %13, i64 noundef %15) #44
  %17 = icmp eq ptr %16, null
  br i1 %17, label %18, label %19

18:                                               ; preds = %8
  tail call void @__cm_runtimeError(ptr noundef nonnull @.str.20) #43
  unreachable

19:                                               ; preds = %8
  store ptr %16, ptr %12, align 8, !tbaa !24
  store i32 %11, ptr %5, align 8, !tbaa !21
  br label %20

20:                                               ; preds = %19, %2
  %21 = icmp eq ptr %1, null
  br i1 %21, label %28, label %22

22:                                               ; preds = %20
  %23 = getelementptr inbounds nuw i8, ptr %1, i64 8
  %24 = load i32, ptr %23, align 8, !tbaa !16
  %25 = icmp sgt i32 %24, 0
  br i1 %25, label %26, label %28

26:                                               ; preds = %22
  %27 = add nuw nsw i32 %24, 1
  store i32 %27, ptr %23, align 8, !tbaa !16
  br label %28

28:                                               ; preds = %20, %22, %26
  %29 = getelementptr inbounds nuw i8, ptr %0, i64 24
  %30 = load ptr, ptr %29, align 8, !tbaa !24
  %31 = load i32, ptr %3, align 4, !tbaa !25
  %32 = sext i32 %31 to i64
  %33 = getelementptr inbounds ptr, ptr %30, i64 %32
  store ptr %1, ptr %33, align 8, !tbaa !26
  %34 = add nsw i32 %31, 1
  store i32 %34, ptr %3, align 4, !tbaa !25
  ret ptr %0
}

; Function Attrs: nounwind ssp uwtable(sync)
define noundef ptr @M4_List_slice(ptr noundef readonly captures(none) %0, i32 noundef %1, i32 noundef %2) #2 {
  %4 = icmp slt i32 %1, 0
  %5 = icmp sgt i32 %1, %2
  %6 = or i1 %4, %5
  br i1 %6, label %11, label %7

7:                                                ; preds = %3
  %8 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %9 = load i32, ptr %8, align 4, !tbaa !25
  %10 = icmp sgt i32 %2, %9
  br i1 %10, label %11, label %12

11:                                               ; preds = %7, %3
  tail call void @__cm_runtimeError(ptr noundef nonnull @.str.21) #43
  unreachable

12:                                               ; preds = %7
  %13 = tail call ptr @__catmint_new(ptr noundef nonnull @RList)
  %14 = getelementptr inbounds nuw i8, ptr %13, i64 12
  %15 = getelementptr inbounds nuw i8, ptr %13, i64 16
  store <2 x i32> zeroinitializer, ptr %14, align 4, !tbaa !6
  %16 = getelementptr inbounds nuw i8, ptr %13, i64 24
  store ptr null, ptr %16, align 8, !tbaa !24
  %17 = icmp slt i32 %1, %2
  br i1 %17, label %18, label %58

18:                                               ; preds = %12
  %19 = getelementptr inbounds nuw i8, ptr %0, i64 24
  %20 = zext nneg i32 %1 to i64
  br label %21

21:                                               ; preds = %18, %49
  %22 = phi i32 [ 0, %18 ], [ %41, %49 ]
  %23 = phi i32 [ 0, %18 ], [ %54, %49 ]
  %24 = phi i64 [ %20, %18 ], [ %55, %49 ]
  %25 = load ptr, ptr %19, align 8, !tbaa !24
  %26 = getelementptr inbounds nuw ptr, ptr %25, i64 %24
  %27 = load ptr, ptr %26, align 8, !tbaa !26
  %28 = icmp eq i32 %23, %22
  br i1 %28, label %29, label %40

29:                                               ; preds = %21
  %30 = icmp eq i32 %22, 0
  %31 = shl nsw i32 %22, 1
  %32 = select i1 %30, i32 4, i32 %31
  %33 = load ptr, ptr %16, align 8, !tbaa !24
  %34 = sext i32 %32 to i64
  %35 = shl nsw i64 %34, 3
  %36 = tail call ptr @realloc(ptr noundef %33, i64 noundef %35) #44
  %37 = icmp eq ptr %36, null
  br i1 %37, label %38, label %39

38:                                               ; preds = %29
  tail call void @__cm_runtimeError(ptr noundef nonnull @.str.20) #43
  unreachable

39:                                               ; preds = %29
  store ptr %36, ptr %16, align 8, !tbaa !24
  store i32 %32, ptr %15, align 8, !tbaa !21
  br label %40

40:                                               ; preds = %39, %21
  %41 = phi i32 [ %32, %39 ], [ %22, %21 ]
  %42 = icmp eq ptr %27, null
  br i1 %42, label %49, label %43

43:                                               ; preds = %40
  %44 = getelementptr inbounds nuw i8, ptr %27, i64 8
  %45 = load i32, ptr %44, align 8, !tbaa !16
  %46 = icmp sgt i32 %45, 0
  br i1 %46, label %47, label %49

47:                                               ; preds = %43
  %48 = add nuw nsw i32 %45, 1
  store i32 %48, ptr %44, align 8, !tbaa !16
  br label %49

49:                                               ; preds = %40, %43, %47
  %50 = load ptr, ptr %16, align 8, !tbaa !24
  %51 = load i32, ptr %14, align 4, !tbaa !25
  %52 = sext i32 %51 to i64
  %53 = getelementptr inbounds ptr, ptr %50, i64 %52
  store ptr %27, ptr %53, align 8, !tbaa !26
  %54 = add nsw i32 %51, 1
  store i32 %54, ptr %14, align 4, !tbaa !25
  %55 = add nuw nsw i64 %24, 1
  %56 = trunc nuw i64 %55 to i32
  %57 = icmp sgt i32 %2, %56
  br i1 %57, label %21, label %58, !llvm.loop !78

58:                                               ; preds = %49, %12
  ret ptr %13
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable(sync)
define i32 @M7_Integer_get(ptr noundef readonly captures(none) %0) #4 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %3 = load i64, ptr %2, align 8, !tbaa !79
  %4 = trunc i64 %3 to i32
  ret i32 %4
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable(sync)
define i64 @M7_Integer_getLong(ptr noundef readonly captures(none) %0) #4 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %3 = load i64, ptr %2, align 8, !tbaa !79
  ret i64 %3
}

; Function Attrs: nounwind ssp uwtable(sync)
define noundef ptr @__catmint_new(ptr noundef %0) local_unnamed_addr #2 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %3 = load i32, ptr %2, align 8, !tbaa !6
  %4 = sext i32 %3 to i64
  %5 = tail call ptr @malloc(i64 noundef %4) #42
  tail call void @llvm.memset.p0.i64(ptr noundef align 1 %5, i8 noundef 0, i64 noundef %4, i1 noundef false) #40
  store ptr %0, ptr %5, align 8, !tbaa !10
  %6 = getelementptr inbounds nuw i8, ptr %5, i64 8
  store i32 1, ptr %6, align 8, !tbaa !16
  %7 = load i32, ptr @gLiveObjects, align 4, !tbaa !6
  %8 = add nsw i32 %7, 1
  store i32 %8, ptr @gLiveObjects, align 4, !tbaa !6
  %9 = load i32, ptr @gPoolDepth, align 4, !tbaa !6
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %32, label %11

11:                                               ; preds = %1
  %12 = load i32, ptr @gPoolCount, align 4, !tbaa !6
  %13 = load i32, ptr @gPoolCapacity, align 4, !tbaa !6
  %14 = icmp eq i32 %12, %13
  %15 = load ptr, ptr @gPoolItems, align 8, !tbaa !81
  br i1 %14, label %16, label %27

16:                                               ; preds = %11
  %17 = icmp eq i32 %12, 0
  %18 = shl nsw i32 %12, 1
  %19 = select i1 %17, i32 64, i32 %18
  %20 = sext i32 %19 to i64
  %21 = shl nsw i64 %20, 3
  %22 = tail call ptr @realloc(ptr noundef %15, i64 noundef %21) #44
  %23 = icmp eq ptr %22, null
  br i1 %23, label %24, label %26

24:                                               ; preds = %16
  %25 = tail call i32 @puts(ptr nonnull dereferenceable(1) @str)
  tail call void @exit(i32 noundef 1) #39
  unreachable

26:                                               ; preds = %16
  store ptr %22, ptr @gPoolItems, align 8, !tbaa !81
  store i32 %19, ptr @gPoolCapacity, align 4, !tbaa !6
  br label %27

27:                                               ; preds = %26, %11
  %28 = phi ptr [ %22, %26 ], [ %15, %11 ]
  %29 = sext i32 %12 to i64
  %30 = getelementptr inbounds ptr, ptr %28, i64 %29
  store ptr %5, ptr %30, align 8, !tbaa !26
  %31 = add nsw i32 %12, 1
  store i32 %31, ptr @gPoolCount, align 4, !tbaa !6
  br label %32

32:                                               ; preds = %1, %27
  ret ptr %5
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(ptr captures(none)) #13

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #14

; Function Attrs: nounwind ssp uwtable(sync)
define void @__cm_poolAdd(ptr noundef %0) local_unnamed_addr #2 {
  %2 = load i32, ptr @gPoolDepth, align 4, !tbaa !6
  %3 = icmp eq i32 %2, 0
  %4 = icmp eq ptr %0, null
  %5 = or i1 %4, %3
  br i1 %5, label %27, label %6

6:                                                ; preds = %1
  %7 = load i32, ptr @gPoolCount, align 4, !tbaa !6
  %8 = load i32, ptr @gPoolCapacity, align 4, !tbaa !6
  %9 = icmp eq i32 %7, %8
  %10 = load ptr, ptr @gPoolItems, align 8, !tbaa !81
  br i1 %9, label %11, label %22

11:                                               ; preds = %6
  %12 = icmp eq i32 %7, 0
  %13 = shl nsw i32 %7, 1
  %14 = select i1 %12, i32 64, i32 %13
  %15 = sext i32 %14 to i64
  %16 = shl nsw i64 %15, 3
  %17 = tail call ptr @realloc(ptr noundef %10, i64 noundef %16) #44
  %18 = icmp eq ptr %17, null
  br i1 %18, label %19, label %21

19:                                               ; preds = %11
  %20 = tail call i32 @puts(ptr nonnull dereferenceable(1) @str)
  tail call void @exit(i32 noundef 1) #39
  unreachable

21:                                               ; preds = %11
  store ptr %17, ptr @gPoolItems, align 8, !tbaa !81
  store i32 %14, ptr @gPoolCapacity, align 4, !tbaa !6
  br label %22

22:                                               ; preds = %21, %6
  %23 = phi ptr [ %17, %21 ], [ %10, %6 ]
  %24 = sext i32 %7 to i64
  %25 = getelementptr inbounds ptr, ptr %23, i64 %24
  store ptr %0, ptr %25, align 8, !tbaa !26
  %26 = add nsw i32 %7, 1
  store i32 %26, ptr @gPoolCount, align 4, !tbaa !6
  br label %27

27:                                               ; preds = %1, %22
  ret void
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(ptr captures(none)) #13

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable(sync)
define void @Object_init(ptr noundef readnone captures(none) %0) local_unnamed_addr #15 {
  ret void
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable(sync)
define void @IO_init(ptr noundef readnone captures(none) %0) local_unnamed_addr #15 {
  ret void
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable(sync)
define void @String_init(ptr noundef writeonly captures(none) initializes((12, 24)) %0) local_unnamed_addr #16 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 16
  store ptr @gEmptyChars, ptr %2, align 8, !tbaa !17
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 12
  store i32 0, ptr %3, align 4, !tbaa !20
  ret void
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable(sync)
define void @List_init(ptr noundef writeonly captures(none) initializes((12, 20), (24, 32)) %0) local_unnamed_addr #16 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 12
  store <2 x i32> zeroinitializer, ptr %2, align 4, !tbaa !6
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 24
  store ptr null, ptr %3, align 8, !tbaa !24
  ret void
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable(sync)
define void @Integer_init(ptr noundef writeonly captures(none) initializes((16, 24)) %0) local_unnamed_addr #16 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 16
  store i64 0, ptr %2, align 8, !tbaa !79
  ret void
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable(sync)
define void @File_init(ptr noundef writeonly captures(none) initializes((16, 24)) %0) local_unnamed_addr #16 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 16
  store ptr null, ptr %2, align 8, !tbaa !29
  ret void
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable(sync)
define void @Math_init(ptr noundef readnone captures(none) %0) local_unnamed_addr #15 {
  ret void
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable(sync)
define void @Process_init(ptr noundef writeonly captures(none) initializes((16, 28)) %0) local_unnamed_addr #16 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 16
  store ptr null, ptr %2, align 8, !tbaa !32
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 24
  store i32 0, ptr %3, align 8, !tbaa !82
  ret void
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable(sync)
define void @Worker_init(ptr noundef readnone captures(none) %0) local_unnamed_addr #15 {
  ret void
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable(sync)
define void @Bytes_init(ptr noundef writeonly captures(none) initializes((12, 24)) %0) local_unnamed_addr #16 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 12
  store i32 0, ptr %2, align 4, !tbaa !36
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 16
  store ptr null, ptr %3, align 8, !tbaa !34
  ret void
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable(sync)
define void @Ints_init(ptr noundef writeonly captures(none) initializes((12, 24)) %0) local_unnamed_addr #16 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 12
  store i32 0, ptr %2, align 4, !tbaa !60
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 16
  store ptr null, ptr %3, align 8, !tbaa !63
  ret void
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable(sync)
define void @Floats_init(ptr noundef writeonly captures(none) initializes((12, 24)) %0) local_unnamed_addr #16 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 12
  store i32 0, ptr %2, align 4, !tbaa !70
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 16
  store ptr null, ptr %3, align 8, !tbaa !73
  ret void
}

; Function Attrs: nofree noreturn
declare void @exit(i32 noundef) local_unnamed_addr #17

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,zeroed") allocsize(0,1) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @calloc(i64 noundef, i64 noundef) local_unnamed_addr #18

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable(sync)
define void @__cm_retain(ptr noundef captures(address_is_null) %0) local_unnamed_addr #3 {
  %2 = icmp eq ptr %0, null
  br i1 %2, label %9, label %3

3:                                                ; preds = %1
  %4 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %5 = load i32, ptr %4, align 8, !tbaa !16
  %6 = icmp sgt i32 %5, 0
  br i1 %6, label %7, label %9

7:                                                ; preds = %3
  %8 = add nuw nsw i32 %5, 1
  store i32 %8, ptr %4, align 8, !tbaa !16
  br label %9

9:                                                ; preds = %7, %3, %1
  ret void
}

; Function Attrs: nounwind ssp uwtable(sync)
define void @__cm_release(ptr noundef captures(address) %0) local_unnamed_addr #2 {
  %2 = icmp eq ptr %0, null
  br i1 %2, label %11, label %3

3:                                                ; preds = %1
  %4 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %5 = load i32, ptr %4, align 8, !tbaa !16
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %11, label %7

7:                                                ; preds = %3
  %8 = add nsw i32 %5, -1
  store i32 %8, ptr %4, align 8, !tbaa !16
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %10, label %11

10:                                               ; preds = %7
  store i32 1, ptr %4, align 8, !tbaa !16
  tail call fastcc void @object_free(ptr noundef %0)
  br label %11

11:                                               ; preds = %1, %3, %7, %10
  ret void
}

; Function Attrs: nounwind ssp uwtable(sync)
define internal fastcc void @object_free(ptr noundef nonnull captures(address) %0) unnamed_addr #2 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %3 = load i32, ptr %2, align 8, !tbaa !16
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %78, label %5

5:                                                ; preds = %1
  %6 = load ptr, ptr %0, align 8, !tbaa !10
  %7 = icmp eq ptr %6, @RString
  br i1 %7, label %8, label %18

8:                                                ; preds = %5
  %9 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %10 = load ptr, ptr %9, align 8, !tbaa !17
  %11 = icmp eq ptr %10, null
  %12 = icmp eq ptr %10, @gEmptyChars
  %13 = or i1 %11, %12
  %14 = getelementptr inbounds nuw i8, ptr %0, i64 24
  %15 = icmp eq ptr %10, %14
  %16 = select i1 %13, i1 true, i1 %15
  br i1 %16, label %75, label %17

17:                                               ; preds = %8
  tail call void @free(ptr noundef nonnull %10)
  br label %75

18:                                               ; preds = %5
  %19 = icmp eq ptr %6, @RList
  br i1 %19, label %20, label %50

20:                                               ; preds = %18
  %21 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %22 = load i32, ptr %21, align 4, !tbaa !25
  %23 = icmp sgt i32 %22, 0
  br i1 %23, label %24, label %47

24:                                               ; preds = %20
  %25 = getelementptr inbounds nuw i8, ptr %0, i64 24
  br label %26

26:                                               ; preds = %24, %42
  %27 = phi i32 [ %22, %24 ], [ %43, %42 ]
  %28 = phi i64 [ 0, %24 ], [ %44, %42 ]
  %29 = load ptr, ptr %25, align 8, !tbaa !24
  %30 = getelementptr inbounds nuw ptr, ptr %29, i64 %28
  %31 = load ptr, ptr %30, align 8, !tbaa !26
  %32 = icmp eq ptr %31, null
  br i1 %32, label %42, label %33

33:                                               ; preds = %26
  %34 = getelementptr inbounds nuw i8, ptr %31, i64 8
  %35 = load i32, ptr %34, align 8, !tbaa !16
  %36 = icmp eq i32 %35, 0
  br i1 %36, label %42, label %37

37:                                               ; preds = %33
  %38 = add nsw i32 %35, -1
  store i32 %38, ptr %34, align 8, !tbaa !16
  %39 = icmp eq i32 %38, 0
  br i1 %39, label %40, label %42

40:                                               ; preds = %37
  store i32 1, ptr %34, align 8, !tbaa !16
  tail call fastcc void @object_free(ptr noundef %31)
  %41 = load i32, ptr %21, align 4, !tbaa !25
  br label %42

42:                                               ; preds = %26, %33, %37, %40
  %43 = phi i32 [ %27, %26 ], [ %27, %33 ], [ %27, %37 ], [ %41, %40 ]
  %44 = add nuw nsw i64 %28, 1
  %45 = sext i32 %43 to i64
  %46 = icmp slt i64 %44, %45
  br i1 %46, label %26, label %47, !llvm.loop !83

47:                                               ; preds = %42, %20
  %48 = getelementptr inbounds nuw i8, ptr %0, i64 24
  %49 = load ptr, ptr %48, align 8, !tbaa !24
  tail call void @free(ptr noundef %49)
  br label %75

50:                                               ; preds = %18
  %51 = icmp eq ptr %6, @RFile
  br i1 %51, label %52, label %58

52:                                               ; preds = %50
  %53 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %54 = load ptr, ptr %53, align 8, !tbaa !29
  %55 = icmp eq ptr %54, null
  br i1 %55, label %75, label %56

56:                                               ; preds = %52
  %57 = tail call i32 @fclose(ptr noundef nonnull %54)
  br label %75

58:                                               ; preds = %50
  %59 = icmp eq ptr %6, @RProcess
  br i1 %59, label %60, label %66

60:                                               ; preds = %58
  %61 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %62 = load ptr, ptr %61, align 8, !tbaa !32
  %63 = icmp eq ptr %62, null
  br i1 %63, label %75, label %64

64:                                               ; preds = %60
  %65 = tail call i32 @pclose(ptr noundef nonnull %62)
  br label %75

66:                                               ; preds = %58
  %67 = icmp eq ptr %6, @RBytes
  %68 = icmp eq ptr %6, @RInts
  %69 = or i1 %67, %68
  %70 = icmp eq ptr %6, @RFloats
  %71 = or i1 %70, %69
  br i1 %71, label %72, label %75

72:                                               ; preds = %66
  %73 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %74 = load ptr, ptr %73, align 8, !tbaa !34
  tail call void @free(ptr noundef %74)
  br label %75

75:                                               ; preds = %8, %17, %47, %52, %56, %60, %64, %66, %72
  %76 = load i32, ptr @gLiveObjects, align 4, !tbaa !6
  %77 = add nsw i32 %76, -1
  store i32 %77, ptr @gLiveObjects, align 4, !tbaa !6
  tail call void @free(ptr noundef nonnull %0)
  br label %78

78:                                               ; preds = %1, %75
  ret void
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn
declare i64 @strtol(ptr noundef readonly, ptr noundef captures(none), i32 noundef) local_unnamed_addr #19

; Function Attrs: noreturn nounwind ssp uwtable(sync)
define void @__cm_runtimeError(ptr noundef %0) local_unnamed_addr #20 {
  %2 = load ptr, ptr @gHandlers, align 8, !tbaa !84
  %3 = icmp eq ptr %2, null
  br i1 %3, label %6, label %4

4:                                                ; preds = %1
  %5 = tail call fastcc ptr @make_string(ptr noundef %0)
  tail call void @__cm_throw(ptr noundef nonnull %5) #43
  unreachable

6:                                                ; preds = %1
  %7 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.34, ptr noundef %0)
  tail call void @exit(i32 noundef 1) #39
  unreachable
}

; Function Attrs: nounwind ssp uwtable(sync)
define internal fastcc nonnull ptr @new_string(i32 noundef %0) unnamed_addr #2 {
  %2 = sext i32 %0 to i64
  %3 = add nsw i64 %2, 25
  %4 = tail call ptr @malloc(i64 noundef %3) #42
  %5 = icmp eq ptr %4, null
  br i1 %5, label %6, label %8

6:                                                ; preds = %1
  %7 = tail call i32 @puts(ptr nonnull dereferenceable(1) @str.48)
  tail call void @exit(i32 noundef 1) #39
  unreachable

8:                                                ; preds = %1
  store ptr @RString, ptr %4, align 8, !tbaa !86
  %9 = getelementptr inbounds nuw i8, ptr %4, i64 8
  store i32 1, ptr %9, align 8, !tbaa !87
  %10 = getelementptr inbounds nuw i8, ptr %4, i64 12
  store i32 %0, ptr %10, align 4, !tbaa !20
  %11 = getelementptr inbounds nuw i8, ptr %4, i64 24
  %12 = getelementptr inbounds nuw i8, ptr %4, i64 16
  store ptr %11, ptr %12, align 8, !tbaa !17
  %13 = getelementptr inbounds i8, ptr %11, i64 %2
  store i8 0, ptr %13, align 1, !tbaa !40
  %14 = load i32, ptr @gLiveObjects, align 4, !tbaa !6
  %15 = add nsw i32 %14, 1
  store i32 %15, ptr @gLiveObjects, align 4, !tbaa !6
  %16 = load i32, ptr @gPoolDepth, align 4, !tbaa !6
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %39, label %18

18:                                               ; preds = %8
  %19 = load i32, ptr @gPoolCount, align 4, !tbaa !6
  %20 = load i32, ptr @gPoolCapacity, align 4, !tbaa !6
  %21 = icmp eq i32 %19, %20
  %22 = load ptr, ptr @gPoolItems, align 8, !tbaa !81
  br i1 %21, label %23, label %34

23:                                               ; preds = %18
  %24 = icmp eq i32 %19, 0
  %25 = shl nsw i32 %19, 1
  %26 = select i1 %24, i32 64, i32 %25
  %27 = sext i32 %26 to i64
  %28 = shl nsw i64 %27, 3
  %29 = tail call ptr @realloc(ptr noundef %22, i64 noundef %28) #44
  %30 = icmp eq ptr %29, null
  br i1 %30, label %31, label %33

31:                                               ; preds = %23
  %32 = tail call i32 @puts(ptr nonnull dereferenceable(1) @str)
  tail call void @exit(i32 noundef 1) #39
  unreachable

33:                                               ; preds = %23
  store ptr %29, ptr @gPoolItems, align 8, !tbaa !81
  store i32 %26, ptr @gPoolCapacity, align 4, !tbaa !6
  br label %34

34:                                               ; preds = %33, %18
  %35 = phi ptr [ %29, %33 ], [ %22, %18 ]
  %36 = sext i32 %19 to i64
  %37 = getelementptr inbounds ptr, ptr %35, i64 %36
  store ptr %4, ptr %37, align 8, !tbaa !26
  %38 = add nsw i32 %19, 1
  store i32 %38, ptr @gPoolCount, align 4, !tbaa !6
  br label %39

39:                                               ; preds = %8, %34
  ret ptr %4
}

; Function Attrs: nounwind ssp uwtable(sync)
define nonnull ptr @__cm_concatAll(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %6, label %4

4:                                                ; preds = %2
  %5 = tail call fastcc ptr @new_string(i32 noundef 0)
  br label %299

6:                                                ; preds = %2
  %7 = zext nneg i32 %1 to i64
  %8 = and i64 %7, 7
  %9 = icmp ult i32 %1, 8
  br i1 %9, label %100, label %10

10:                                               ; preds = %6
  %11 = and i64 %7, 2147483640
  br label %12

12:                                               ; preds = %93, %10
  %13 = phi i64 [ 0, %10 ], [ %95, %93 ]
  %14 = phi i32 [ 0, %10 ], [ %94, %93 ]
  %15 = phi i64 [ 0, %10 ], [ %96, %93 ]
  %16 = getelementptr inbounds nuw ptr, ptr %0, i64 %13
  %17 = load ptr, ptr %16, align 8, !tbaa !26
  %18 = icmp eq ptr %17, null
  br i1 %18, label %23, label %19

19:                                               ; preds = %12
  %20 = getelementptr inbounds nuw i8, ptr %17, i64 12
  %21 = load i32, ptr %20, align 4, !tbaa !20
  %22 = add nsw i32 %21, %14
  br label %23

23:                                               ; preds = %12, %19
  %24 = phi i32 [ %22, %19 ], [ %14, %12 ]
  %25 = getelementptr inbounds nuw ptr, ptr %0, i64 %13
  %26 = getelementptr inbounds nuw i8, ptr %25, i64 8
  %27 = load ptr, ptr %26, align 8, !tbaa !26
  %28 = icmp eq ptr %27, null
  br i1 %28, label %33, label %29

29:                                               ; preds = %23
  %30 = getelementptr inbounds nuw i8, ptr %27, i64 12
  %31 = load i32, ptr %30, align 4, !tbaa !20
  %32 = add nsw i32 %31, %24
  br label %33

33:                                               ; preds = %29, %23
  %34 = phi i32 [ %32, %29 ], [ %24, %23 ]
  %35 = getelementptr inbounds nuw ptr, ptr %0, i64 %13
  %36 = getelementptr inbounds nuw i8, ptr %35, i64 16
  %37 = load ptr, ptr %36, align 8, !tbaa !26
  %38 = icmp eq ptr %37, null
  br i1 %38, label %43, label %39

39:                                               ; preds = %33
  %40 = getelementptr inbounds nuw i8, ptr %37, i64 12
  %41 = load i32, ptr %40, align 4, !tbaa !20
  %42 = add nsw i32 %41, %34
  br label %43

43:                                               ; preds = %39, %33
  %44 = phi i32 [ %42, %39 ], [ %34, %33 ]
  %45 = getelementptr inbounds nuw ptr, ptr %0, i64 %13
  %46 = getelementptr inbounds nuw i8, ptr %45, i64 24
  %47 = load ptr, ptr %46, align 8, !tbaa !26
  %48 = icmp eq ptr %47, null
  br i1 %48, label %53, label %49

49:                                               ; preds = %43
  %50 = getelementptr inbounds nuw i8, ptr %47, i64 12
  %51 = load i32, ptr %50, align 4, !tbaa !20
  %52 = add nsw i32 %51, %44
  br label %53

53:                                               ; preds = %49, %43
  %54 = phi i32 [ %52, %49 ], [ %44, %43 ]
  %55 = getelementptr inbounds nuw ptr, ptr %0, i64 %13
  %56 = getelementptr inbounds nuw i8, ptr %55, i64 32
  %57 = load ptr, ptr %56, align 8, !tbaa !26
  %58 = icmp eq ptr %57, null
  br i1 %58, label %63, label %59

59:                                               ; preds = %53
  %60 = getelementptr inbounds nuw i8, ptr %57, i64 12
  %61 = load i32, ptr %60, align 4, !tbaa !20
  %62 = add nsw i32 %61, %54
  br label %63

63:                                               ; preds = %59, %53
  %64 = phi i32 [ %62, %59 ], [ %54, %53 ]
  %65 = getelementptr inbounds nuw ptr, ptr %0, i64 %13
  %66 = getelementptr inbounds nuw i8, ptr %65, i64 40
  %67 = load ptr, ptr %66, align 8, !tbaa !26
  %68 = icmp eq ptr %67, null
  br i1 %68, label %73, label %69

69:                                               ; preds = %63
  %70 = getelementptr inbounds nuw i8, ptr %67, i64 12
  %71 = load i32, ptr %70, align 4, !tbaa !20
  %72 = add nsw i32 %71, %64
  br label %73

73:                                               ; preds = %69, %63
  %74 = phi i32 [ %72, %69 ], [ %64, %63 ]
  %75 = getelementptr inbounds nuw ptr, ptr %0, i64 %13
  %76 = getelementptr inbounds nuw i8, ptr %75, i64 48
  %77 = load ptr, ptr %76, align 8, !tbaa !26
  %78 = icmp eq ptr %77, null
  br i1 %78, label %83, label %79

79:                                               ; preds = %73
  %80 = getelementptr inbounds nuw i8, ptr %77, i64 12
  %81 = load i32, ptr %80, align 4, !tbaa !20
  %82 = add nsw i32 %81, %74
  br label %83

83:                                               ; preds = %79, %73
  %84 = phi i32 [ %82, %79 ], [ %74, %73 ]
  %85 = getelementptr inbounds nuw ptr, ptr %0, i64 %13
  %86 = getelementptr inbounds nuw i8, ptr %85, i64 56
  %87 = load ptr, ptr %86, align 8, !tbaa !26
  %88 = icmp eq ptr %87, null
  br i1 %88, label %93, label %89

89:                                               ; preds = %83
  %90 = getelementptr inbounds nuw i8, ptr %87, i64 12
  %91 = load i32, ptr %90, align 4, !tbaa !20
  %92 = add nsw i32 %91, %84
  br label %93

93:                                               ; preds = %89, %83
  %94 = phi i32 [ %92, %89 ], [ %84, %83 ]
  %95 = add nuw nsw i64 %13, 8
  %96 = add i64 %15, 8
  %97 = icmp eq i64 %96, %11
  br i1 %97, label %98, label %12, !llvm.loop !88

98:                                               ; preds = %93
  %99 = icmp eq i64 %8, 0
  br i1 %99, label %120, label %100

100:                                              ; preds = %98, %6
  %101 = phi i64 [ 0, %6 ], [ %95, %98 ]
  %102 = phi i32 [ 0, %6 ], [ %94, %98 ]
  %103 = icmp ne i64 %8, 0
  tail call void @llvm.assume(i1 %103)
  br label %104

104:                                              ; preds = %115, %100
  %105 = phi i64 [ %101, %100 ], [ %117, %115 ]
  %106 = phi i32 [ %102, %100 ], [ %116, %115 ]
  %107 = phi i64 [ 0, %100 ], [ %118, %115 ]
  %108 = getelementptr inbounds nuw ptr, ptr %0, i64 %105
  %109 = load ptr, ptr %108, align 8, !tbaa !26
  %110 = icmp eq ptr %109, null
  br i1 %110, label %115, label %111

111:                                              ; preds = %104
  %112 = getelementptr inbounds nuw i8, ptr %109, i64 12
  %113 = load i32, ptr %112, align 4, !tbaa !20
  %114 = add nsw i32 %113, %106
  br label %115

115:                                              ; preds = %111, %104
  %116 = phi i32 [ %114, %111 ], [ %106, %104 ]
  %117 = add nuw nsw i64 %105, 1
  %118 = add i64 %107, 1
  %119 = icmp eq i64 %118, %8
  br i1 %119, label %120, label %104, !llvm.loop !89

120:                                              ; preds = %115, %98
  %121 = phi i32 [ %94, %98 ], [ %116, %115 ]
  %122 = tail call fastcc ptr @new_string(i32 noundef %121)
  %123 = getelementptr inbounds nuw i8, ptr %122, i64 16
  %124 = and i64 %7, 7
  %125 = icmp ult i32 %1, 8
  br i1 %125, label %272, label %126

126:                                              ; preds = %120
  %127 = and i64 %7, 2147483640
  br label %128

128:                                              ; preds = %265, %126
  %129 = phi i64 [ 0, %126 ], [ %267, %265 ]
  %130 = phi i32 [ 0, %126 ], [ %266, %265 ]
  %131 = phi i64 [ 0, %126 ], [ %268, %265 ]
  %132 = getelementptr inbounds nuw ptr, ptr %0, i64 %129
  %133 = load ptr, ptr %132, align 8, !tbaa !26
  %134 = icmp eq ptr %133, null
  br i1 %134, label %146, label %135

135:                                              ; preds = %128
  %136 = load ptr, ptr %123, align 8, !tbaa !17
  %137 = sext i32 %130 to i64
  %138 = getelementptr inbounds i8, ptr %136, i64 %137
  %139 = getelementptr inbounds nuw i8, ptr %133, i64 16
  %140 = load ptr, ptr %139, align 8, !tbaa !17
  %141 = getelementptr inbounds nuw i8, ptr %133, i64 12
  %142 = load i32, ptr %141, align 4, !tbaa !20
  %143 = sext i32 %142 to i64
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %138, ptr noundef align 1 %140, i64 noundef %143, i1 noundef false) #40
  %144 = load i32, ptr %141, align 4, !tbaa !20
  %145 = add nsw i32 %144, %130
  br label %146

146:                                              ; preds = %128, %135
  %147 = phi i32 [ %145, %135 ], [ %130, %128 ]
  %148 = getelementptr inbounds nuw ptr, ptr %0, i64 %129
  %149 = getelementptr inbounds nuw i8, ptr %148, i64 8
  %150 = load ptr, ptr %149, align 8, !tbaa !26
  %151 = icmp eq ptr %150, null
  br i1 %151, label %163, label %152

152:                                              ; preds = %146
  %153 = load ptr, ptr %123, align 8, !tbaa !17
  %154 = sext i32 %147 to i64
  %155 = getelementptr inbounds i8, ptr %153, i64 %154
  %156 = getelementptr inbounds nuw i8, ptr %150, i64 16
  %157 = load ptr, ptr %156, align 8, !tbaa !17
  %158 = getelementptr inbounds nuw i8, ptr %150, i64 12
  %159 = load i32, ptr %158, align 4, !tbaa !20
  %160 = sext i32 %159 to i64
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %155, ptr noundef align 1 %157, i64 noundef %160, i1 noundef false) #40
  %161 = load i32, ptr %158, align 4, !tbaa !20
  %162 = add nsw i32 %161, %147
  br label %163

163:                                              ; preds = %152, %146
  %164 = phi i32 [ %162, %152 ], [ %147, %146 ]
  %165 = getelementptr inbounds nuw ptr, ptr %0, i64 %129
  %166 = getelementptr inbounds nuw i8, ptr %165, i64 16
  %167 = load ptr, ptr %166, align 8, !tbaa !26
  %168 = icmp eq ptr %167, null
  br i1 %168, label %180, label %169

169:                                              ; preds = %163
  %170 = load ptr, ptr %123, align 8, !tbaa !17
  %171 = sext i32 %164 to i64
  %172 = getelementptr inbounds i8, ptr %170, i64 %171
  %173 = getelementptr inbounds nuw i8, ptr %167, i64 16
  %174 = load ptr, ptr %173, align 8, !tbaa !17
  %175 = getelementptr inbounds nuw i8, ptr %167, i64 12
  %176 = load i32, ptr %175, align 4, !tbaa !20
  %177 = sext i32 %176 to i64
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %172, ptr noundef align 1 %174, i64 noundef %177, i1 noundef false) #40
  %178 = load i32, ptr %175, align 4, !tbaa !20
  %179 = add nsw i32 %178, %164
  br label %180

180:                                              ; preds = %169, %163
  %181 = phi i32 [ %179, %169 ], [ %164, %163 ]
  %182 = getelementptr inbounds nuw ptr, ptr %0, i64 %129
  %183 = getelementptr inbounds nuw i8, ptr %182, i64 24
  %184 = load ptr, ptr %183, align 8, !tbaa !26
  %185 = icmp eq ptr %184, null
  br i1 %185, label %197, label %186

186:                                              ; preds = %180
  %187 = load ptr, ptr %123, align 8, !tbaa !17
  %188 = sext i32 %181 to i64
  %189 = getelementptr inbounds i8, ptr %187, i64 %188
  %190 = getelementptr inbounds nuw i8, ptr %184, i64 16
  %191 = load ptr, ptr %190, align 8, !tbaa !17
  %192 = getelementptr inbounds nuw i8, ptr %184, i64 12
  %193 = load i32, ptr %192, align 4, !tbaa !20
  %194 = sext i32 %193 to i64
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %189, ptr noundef align 1 %191, i64 noundef %194, i1 noundef false) #40
  %195 = load i32, ptr %192, align 4, !tbaa !20
  %196 = add nsw i32 %195, %181
  br label %197

197:                                              ; preds = %186, %180
  %198 = phi i32 [ %196, %186 ], [ %181, %180 ]
  %199 = getelementptr inbounds nuw ptr, ptr %0, i64 %129
  %200 = getelementptr inbounds nuw i8, ptr %199, i64 32
  %201 = load ptr, ptr %200, align 8, !tbaa !26
  %202 = icmp eq ptr %201, null
  br i1 %202, label %214, label %203

203:                                              ; preds = %197
  %204 = load ptr, ptr %123, align 8, !tbaa !17
  %205 = sext i32 %198 to i64
  %206 = getelementptr inbounds i8, ptr %204, i64 %205
  %207 = getelementptr inbounds nuw i8, ptr %201, i64 16
  %208 = load ptr, ptr %207, align 8, !tbaa !17
  %209 = getelementptr inbounds nuw i8, ptr %201, i64 12
  %210 = load i32, ptr %209, align 4, !tbaa !20
  %211 = sext i32 %210 to i64
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %206, ptr noundef align 1 %208, i64 noundef %211, i1 noundef false) #40
  %212 = load i32, ptr %209, align 4, !tbaa !20
  %213 = add nsw i32 %212, %198
  br label %214

214:                                              ; preds = %203, %197
  %215 = phi i32 [ %213, %203 ], [ %198, %197 ]
  %216 = getelementptr inbounds nuw ptr, ptr %0, i64 %129
  %217 = getelementptr inbounds nuw i8, ptr %216, i64 40
  %218 = load ptr, ptr %217, align 8, !tbaa !26
  %219 = icmp eq ptr %218, null
  br i1 %219, label %231, label %220

220:                                              ; preds = %214
  %221 = load ptr, ptr %123, align 8, !tbaa !17
  %222 = sext i32 %215 to i64
  %223 = getelementptr inbounds i8, ptr %221, i64 %222
  %224 = getelementptr inbounds nuw i8, ptr %218, i64 16
  %225 = load ptr, ptr %224, align 8, !tbaa !17
  %226 = getelementptr inbounds nuw i8, ptr %218, i64 12
  %227 = load i32, ptr %226, align 4, !tbaa !20
  %228 = sext i32 %227 to i64
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %223, ptr noundef align 1 %225, i64 noundef %228, i1 noundef false) #40
  %229 = load i32, ptr %226, align 4, !tbaa !20
  %230 = add nsw i32 %229, %215
  br label %231

231:                                              ; preds = %220, %214
  %232 = phi i32 [ %230, %220 ], [ %215, %214 ]
  %233 = getelementptr inbounds nuw ptr, ptr %0, i64 %129
  %234 = getelementptr inbounds nuw i8, ptr %233, i64 48
  %235 = load ptr, ptr %234, align 8, !tbaa !26
  %236 = icmp eq ptr %235, null
  br i1 %236, label %248, label %237

237:                                              ; preds = %231
  %238 = load ptr, ptr %123, align 8, !tbaa !17
  %239 = sext i32 %232 to i64
  %240 = getelementptr inbounds i8, ptr %238, i64 %239
  %241 = getelementptr inbounds nuw i8, ptr %235, i64 16
  %242 = load ptr, ptr %241, align 8, !tbaa !17
  %243 = getelementptr inbounds nuw i8, ptr %235, i64 12
  %244 = load i32, ptr %243, align 4, !tbaa !20
  %245 = sext i32 %244 to i64
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %240, ptr noundef align 1 %242, i64 noundef %245, i1 noundef false) #40
  %246 = load i32, ptr %243, align 4, !tbaa !20
  %247 = add nsw i32 %246, %232
  br label %248

248:                                              ; preds = %237, %231
  %249 = phi i32 [ %247, %237 ], [ %232, %231 ]
  %250 = getelementptr inbounds nuw ptr, ptr %0, i64 %129
  %251 = getelementptr inbounds nuw i8, ptr %250, i64 56
  %252 = load ptr, ptr %251, align 8, !tbaa !26
  %253 = icmp eq ptr %252, null
  br i1 %253, label %265, label %254

254:                                              ; preds = %248
  %255 = load ptr, ptr %123, align 8, !tbaa !17
  %256 = sext i32 %249 to i64
  %257 = getelementptr inbounds i8, ptr %255, i64 %256
  %258 = getelementptr inbounds nuw i8, ptr %252, i64 16
  %259 = load ptr, ptr %258, align 8, !tbaa !17
  %260 = getelementptr inbounds nuw i8, ptr %252, i64 12
  %261 = load i32, ptr %260, align 4, !tbaa !20
  %262 = sext i32 %261 to i64
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %257, ptr noundef align 1 %259, i64 noundef %262, i1 noundef false) #40
  %263 = load i32, ptr %260, align 4, !tbaa !20
  %264 = add nsw i32 %263, %249
  br label %265

265:                                              ; preds = %254, %248
  %266 = phi i32 [ %264, %254 ], [ %249, %248 ]
  %267 = add nuw nsw i64 %129, 8
  %268 = add i64 %131, 8
  %269 = icmp eq i64 %268, %127
  br i1 %269, label %270, label %128, !llvm.loop !90

270:                                              ; preds = %265
  %271 = icmp eq i64 %124, 0
  br i1 %271, label %299, label %272

272:                                              ; preds = %270, %120
  %273 = phi i64 [ 0, %120 ], [ %267, %270 ]
  %274 = phi i32 [ 0, %120 ], [ %266, %270 ]
  %275 = icmp ne i64 %124, 0
  tail call void @llvm.assume(i1 %275)
  br label %276

276:                                              ; preds = %294, %272
  %277 = phi i64 [ %273, %272 ], [ %296, %294 ]
  %278 = phi i32 [ %274, %272 ], [ %295, %294 ]
  %279 = phi i64 [ 0, %272 ], [ %297, %294 ]
  %280 = getelementptr inbounds nuw ptr, ptr %0, i64 %277
  %281 = load ptr, ptr %280, align 8, !tbaa !26
  %282 = icmp eq ptr %281, null
  br i1 %282, label %294, label %283

283:                                              ; preds = %276
  %284 = load ptr, ptr %123, align 8, !tbaa !17
  %285 = sext i32 %278 to i64
  %286 = getelementptr inbounds i8, ptr %284, i64 %285
  %287 = getelementptr inbounds nuw i8, ptr %281, i64 16
  %288 = load ptr, ptr %287, align 8, !tbaa !17
  %289 = getelementptr inbounds nuw i8, ptr %281, i64 12
  %290 = load i32, ptr %289, align 4, !tbaa !20
  %291 = sext i32 %290 to i64
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %286, ptr noundef align 1 %288, i64 noundef %291, i1 noundef false) #40
  %292 = load i32, ptr %289, align 4, !tbaa !20
  %293 = add nsw i32 %292, %278
  br label %294

294:                                              ; preds = %283, %276
  %295 = phi i32 [ %293, %283 ], [ %278, %276 ]
  %296 = add nuw nsw i64 %277, 1
  %297 = add i64 %279, 1
  %298 = icmp eq i64 %297, %124
  br i1 %298, label %299, label %276, !llvm.loop !91

299:                                              ; preds = %270, %294, %4
  %300 = phi ptr [ %5, %4 ], [ %122, %294 ], [ %122, %270 ]
  ret ptr %300
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: read)
declare i32 @strncmp(ptr noundef captures(none), ptr noundef captures(none), i64 noundef) local_unnamed_addr #21

; Function Attrs: nofree nounwind
declare noundef i32 @scanf(ptr noundef readonly captures(none), ...) local_unnamed_addr #22

; Function Attrs: nounwind ssp uwtable(sync)
define internal fastcc nonnull ptr @make_string(ptr noundef readonly captures(none) %0) unnamed_addr #2 {
  %2 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %0) #40
  %3 = trunc i64 %2 to i32
  %4 = tail call fastcc ptr @new_string(i32 noundef %3)
  %5 = getelementptr inbounds nuw i8, ptr %4, i64 16
  %6 = load ptr, ptr %5, align 8, !tbaa !17
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %6, ptr noundef nonnull align 1 %0, i64 noundef %2, i1 noundef false) #40
  ret ptr %4
}

; Function Attrs: nofree nounwind
declare noundef ptr @fgets(ptr noundef writeonly, i32 noundef, ptr noundef captures(none)) local_unnamed_addr #22

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: read)
declare i64 @strlen(ptr noundef captures(none)) local_unnamed_addr #21

; Function Attrs: nofree nounwind
declare noundef i32 @fgetc(ptr noundef captures(none)) local_unnamed_addr #22

; Function Attrs: nofree nounwind
declare noundef i32 @ungetc(i32 noundef, ptr noundef captures(none)) local_unnamed_addr #22

declare ptr @"\01_fopen"(ptr noundef, ptr noundef) local_unnamed_addr #23

; Function Attrs: nofree nounwind
declare noundef i64 @fread(ptr noundef writeonly captures(none), i64 noundef, i64 noundef, ptr noundef captures(none)) local_unnamed_addr #22

; Function Attrs: nofree nounwind
declare noundef i32 @fclose(ptr noundef captures(none)) local_unnamed_addr #22

declare i64 @time(ptr noundef) local_unnamed_addr #23

declare i64 @"\01_clock"() local_unnamed_addr #23

declare i32 @clock_gettime(i32 noundef, ptr noundef) local_unnamed_addr #23

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #24

declare ptr @localtime_r(ptr noundef, ptr noundef) local_unnamed_addr #23

declare ptr @gmtime_r(ptr noundef, ptr noundef) local_unnamed_addr #23

declare i32 @"\01_nanosleep"(ptr noundef, ptr noundef) local_unnamed_addr #23

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr noundef readonly captures(none), ...) local_unnamed_addr #22

; Function Attrs: mustprogress nounwind willreturn allockind("realloc") allocsize(1) memory(argmem: readwrite, inaccessiblemem: readwrite)
declare noalias noundef ptr @realloc(ptr allocptr noundef captures(none), i64 noundef) local_unnamed_addr #25

; Function Attrs: nounwind ssp uwtable(sync)
define void @__cm_checkNull(ptr noundef readnone captures(address_is_null) %0) local_unnamed_addr #2 {
  %2 = icmp eq ptr %0, null
  br i1 %2, label %3, label %4

3:                                                ; preds = %1
  tail call void @__cm_runtimeError(ptr noundef nonnull @.str.22) #43
  unreachable

4:                                                ; preds = %1
  ret void
}

; Function Attrs: nounwind ssp uwtable(sync)
define i32 @__cm_ifaceBase(ptr noundef readonly captures(address_is_null) %0, ptr noundef readonly captures(address) %1) local_unnamed_addr #2 {
  %3 = alloca [256 x i8], align 1
  %4 = icmp eq ptr %0, null
  br i1 %4, label %8, label %5

5:                                                ; preds = %2
  %6 = load ptr, ptr %0, align 8, !tbaa !92
  %7 = icmp eq ptr %6, null
  br i1 %7, label %29, label %9

8:                                                ; preds = %2
  tail call void @__cm_runtimeError(ptr noundef nonnull @.str.22) #43
  unreachable

9:                                                ; preds = %5, %25
  %10 = phi ptr [ %27, %25 ], [ %6, %5 ]
  %11 = getelementptr inbounds nuw i8, ptr %10, i64 24
  %12 = load ptr, ptr %11, align 8, !tbaa !26
  %13 = icmp eq ptr %12, null
  br i1 %13, label %25, label %14

14:                                               ; preds = %9
  %15 = load ptr, ptr %12, align 8, !tbaa !93
  %16 = icmp eq ptr %15, null
  br i1 %16, label %25, label %17

17:                                               ; preds = %14, %21
  %18 = phi ptr [ %23, %21 ], [ %15, %14 ]
  %19 = phi ptr [ %22, %21 ], [ %12, %14 ]
  %20 = icmp eq ptr %18, %1
  br i1 %20, label %37, label %21

21:                                               ; preds = %17
  %22 = getelementptr inbounds nuw i8, ptr %19, i64 16
  %23 = load ptr, ptr %22, align 8, !tbaa !93
  %24 = icmp eq ptr %23, null
  br i1 %24, label %25, label %17, !llvm.loop !95

25:                                               ; preds = %21, %14, %9
  %26 = getelementptr inbounds nuw i8, ptr %10, i64 16
  %27 = load ptr, ptr %26, align 8, !tbaa !92
  %28 = icmp eq ptr %27, null
  br i1 %28, label %29, label %9, !llvm.loop !96

29:                                               ; preds = %25, %5
  call void @llvm.lifetime.start.p0(ptr nonnull %3) #40
  %30 = load ptr, ptr %6, align 8, !tbaa !14
  %31 = getelementptr inbounds nuw i8, ptr %30, i64 16
  %32 = load ptr, ptr %31, align 8, !tbaa !17
  %33 = load ptr, ptr %1, align 8, !tbaa !14
  %34 = getelementptr inbounds nuw i8, ptr %33, i64 16
  %35 = load ptr, ptr %34, align 8, !tbaa !17
  %36 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr nonnull dereferenceable(1) %3, i64 256, ptr nonnull @.str.23, ptr %32, ptr %35)
  call void @__cm_runtimeError(ptr noundef nonnull %3) #43
  unreachable

37:                                               ; preds = %17
  %38 = getelementptr inbounds nuw i8, ptr %19, i64 8
  %39 = load i32, ptr %38, align 8, !tbaa !97
  ret i32 %39
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(read, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable(sync)
define range(i32 0, 2) i32 @__cm_isType(ptr noundef readonly captures(address_is_null) %0, ptr noundef readnone captures(address) %1) local_unnamed_addr #26 {
  %3 = icmp eq ptr %0, null
  br i1 %3, label %34, label %4

4:                                                ; preds = %2
  %5 = load ptr, ptr %0, align 8, !tbaa !92
  %6 = icmp eq ptr %5, null
  br i1 %6, label %34, label %11

7:                                                ; preds = %11
  %8 = getelementptr inbounds nuw i8, ptr %12, i64 16
  %9 = load ptr, ptr %8, align 8, !tbaa !92
  %10 = icmp eq ptr %9, null
  br i1 %10, label %14, label %11, !llvm.loop !98

11:                                               ; preds = %4, %7
  %12 = phi ptr [ %9, %7 ], [ %5, %4 ]
  %13 = icmp eq ptr %12, %1
  br i1 %13, label %34, label %7

14:                                               ; preds = %7, %30
  %15 = phi ptr [ %32, %30 ], [ %5, %7 ]
  %16 = getelementptr inbounds nuw i8, ptr %15, i64 24
  %17 = load ptr, ptr %16, align 8, !tbaa !26
  %18 = icmp eq ptr %17, null
  br i1 %18, label %30, label %19

19:                                               ; preds = %14
  %20 = load ptr, ptr %17, align 8, !tbaa !93
  %21 = icmp eq ptr %20, null
  br i1 %21, label %30, label %26

22:                                               ; preds = %26
  %23 = getelementptr inbounds nuw i8, ptr %28, i64 16
  %24 = load ptr, ptr %23, align 8, !tbaa !93
  %25 = icmp eq ptr %24, null
  br i1 %25, label %30, label %26, !llvm.loop !99

26:                                               ; preds = %19, %22
  %27 = phi ptr [ %24, %22 ], [ %20, %19 ]
  %28 = phi ptr [ %23, %22 ], [ %17, %19 ]
  %29 = icmp eq ptr %27, %1
  br i1 %29, label %34, label %22

30:                                               ; preds = %22, %19, %14
  %31 = getelementptr inbounds nuw i8, ptr %15, i64 16
  %32 = load ptr, ptr %31, align 8, !tbaa !92
  %33 = icmp eq ptr %32, null
  br i1 %33, label %34, label %14, !llvm.loop !100

34:                                               ; preds = %11, %30, %26, %4, %2
  %35 = phi i32 [ 0, %4 ], [ 0, %2 ], [ 1, %26 ], [ 0, %30 ], [ 1, %11 ]
  ret i32 %35
}

; Function Attrs: nounwind ssp uwtable(sync)
define noundef ptr @__cm_cast(ptr noundef readonly returned captures(address_is_null, ret: address, provenance) %0, ptr noundef readonly captures(address) %1) local_unnamed_addr #2 {
  %3 = alloca [256 x i8], align 1
  %4 = icmp eq ptr %0, null
  br i1 %4, label %43, label %5

5:                                                ; preds = %2
  %6 = load ptr, ptr %0, align 8, !tbaa !10
  %7 = icmp eq ptr %6, null
  br i1 %7, label %35, label %8

8:                                                ; preds = %5, %11
  %9 = phi ptr [ %13, %11 ], [ %6, %5 ]
  %10 = icmp eq ptr %9, %1
  br i1 %10, label %43, label %11

11:                                               ; preds = %8
  %12 = getelementptr inbounds nuw i8, ptr %9, i64 16
  %13 = load ptr, ptr %12, align 8, !tbaa !92
  %14 = icmp eq ptr %13, null
  br i1 %14, label %15, label %8, !llvm.loop !101

15:                                               ; preds = %11, %31
  %16 = phi ptr [ %33, %31 ], [ %6, %11 ]
  %17 = getelementptr inbounds nuw i8, ptr %16, i64 24
  %18 = load ptr, ptr %17, align 8, !tbaa !26
  %19 = icmp eq ptr %18, null
  br i1 %19, label %31, label %20

20:                                               ; preds = %15
  %21 = load ptr, ptr %18, align 8, !tbaa !93
  %22 = icmp eq ptr %21, null
  br i1 %22, label %31, label %27

23:                                               ; preds = %27
  %24 = getelementptr inbounds nuw i8, ptr %29, i64 16
  %25 = load ptr, ptr %24, align 8, !tbaa !93
  %26 = icmp eq ptr %25, null
  br i1 %26, label %31, label %27, !llvm.loop !99

27:                                               ; preds = %20, %23
  %28 = phi ptr [ %25, %23 ], [ %21, %20 ]
  %29 = phi ptr [ %24, %23 ], [ %18, %20 ]
  %30 = icmp eq ptr %28, %1
  br i1 %30, label %43, label %23

31:                                               ; preds = %23, %20, %15
  %32 = getelementptr inbounds nuw i8, ptr %16, i64 16
  %33 = load ptr, ptr %32, align 8, !tbaa !92
  %34 = icmp eq ptr %33, null
  br i1 %34, label %35, label %15, !llvm.loop !100

35:                                               ; preds = %31, %5
  call void @llvm.lifetime.start.p0(ptr nonnull %3) #40
  %36 = load ptr, ptr %6, align 8, !tbaa !14
  %37 = getelementptr inbounds nuw i8, ptr %36, i64 16
  %38 = load ptr, ptr %37, align 8, !tbaa !17
  %39 = load ptr, ptr %1, align 8, !tbaa !14
  %40 = getelementptr inbounds nuw i8, ptr %39, i64 16
  %41 = load ptr, ptr %40, align 8, !tbaa !17
  %42 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr nonnull dereferenceable(1) %3, i64 256, ptr nonnull @.str.24, ptr %38, ptr %41)
  call void @__cm_runtimeError(ptr noundef nonnull %3) #43
  unreachable

43:                                               ; preds = %8, %27, %2
  ret ptr %0
}

; Function Attrs: nounwind ssp uwtable(sync)
define noundef ptr @__cm_boxLong(i64 noundef %0) local_unnamed_addr #2 {
  %2 = add i64 %0, 128
  %3 = icmp ult i64 %2, 1153
  br i1 %3, label %4, label %34

4:                                                ; preds = %1
  %5 = load i1, ptr @gSmallIntegersReady, align 4
  br i1 %5, label %31, label %6

6:                                                ; preds = %4, %6
  %7 = phi i64 [ %28, %6 ], [ 0, %4 ]
  %8 = add i64 %7, -128
  %9 = add i64 %7, -127
  %10 = add i64 %7, -126
  %11 = add i64 %7, -125
  %12 = getelementptr %struct.TInteger, ptr @gSmallIntegers, i64 %8
  %13 = getelementptr %struct.TInteger, ptr @gSmallIntegers, i64 %9
  %14 = getelementptr %struct.TInteger, ptr @gSmallIntegers, i64 %10
  %15 = getelementptr %struct.TInteger, ptr @gSmallIntegers, i64 %11
  %16 = getelementptr i8, ptr %12, i64 3072
  %17 = getelementptr i8, ptr %13, i64 3072
  %18 = getelementptr i8, ptr %14, i64 3072
  %19 = getelementptr i8, ptr %15, i64 3072
  store ptr @RInteger, ptr %16, align 8, !tbaa !102
  store ptr @RInteger, ptr %17, align 8, !tbaa !102
  store ptr @RInteger, ptr %18, align 8, !tbaa !102
  store ptr @RInteger, ptr %19, align 8, !tbaa !102
  %20 = getelementptr i8, ptr %12, i64 3080
  %21 = getelementptr i8, ptr %13, i64 3080
  %22 = getelementptr i8, ptr %14, i64 3080
  %23 = getelementptr i8, ptr %15, i64 3080
  store i32 0, ptr %20, align 8, !tbaa !103
  store i32 0, ptr %21, align 8, !tbaa !103
  store i32 0, ptr %22, align 8, !tbaa !103
  store i32 0, ptr %23, align 8, !tbaa !103
  %24 = getelementptr i8, ptr %12, i64 3088
  %25 = getelementptr i8, ptr %13, i64 3088
  %26 = getelementptr i8, ptr %14, i64 3088
  %27 = getelementptr i8, ptr %15, i64 3088
  store i64 %8, ptr %24, align 8, !tbaa !79
  store i64 %9, ptr %25, align 8, !tbaa !79
  store i64 %10, ptr %26, align 8, !tbaa !79
  store i64 %11, ptr %27, align 8, !tbaa !79
  %28 = add nuw i64 %7, 4
  %29 = icmp eq i64 %28, 1152
  br i1 %29, label %30, label %6, !llvm.loop !104

30:                                               ; preds = %6
  store ptr @RInteger, ptr getelementptr inbounds nuw (i8, ptr @gSmallIntegers, i64 27648), align 8, !tbaa !102
  store i32 0, ptr getelementptr inbounds nuw (i8, ptr @gSmallIntegers, i64 27656), align 8, !tbaa !103
  store i64 1024, ptr getelementptr inbounds nuw (i8, ptr @gSmallIntegers, i64 27664), align 8, !tbaa !79
  store i1 true, ptr @gSmallIntegersReady, align 4
  br label %31

31:                                               ; preds = %30, %4
  %32 = getelementptr %struct.TInteger, ptr @gSmallIntegers, i64 %0
  %33 = getelementptr i8, ptr %32, i64 3072
  br label %37

34:                                               ; preds = %1
  %35 = tail call ptr @__catmint_new(ptr noundef nonnull @RInteger)
  %36 = getelementptr inbounds nuw i8, ptr %35, i64 16
  store i64 %0, ptr %36, align 8, !tbaa !79
  br label %37

37:                                               ; preds = %34, %31
  %38 = phi ptr [ %33, %31 ], [ %35, %34 ]
  ret ptr %38
}

; Function Attrs: nounwind ssp uwtable(sync)
define i64 @__cm_unboxLong(ptr noundef readonly captures(address_is_null) %0) local_unnamed_addr #2 {
  %2 = alloca [256 x i8], align 1
  %3 = icmp eq ptr %0, null
  br i1 %3, label %4, label %5

4:                                                ; preds = %1
  tail call void @__cm_runtimeError(ptr noundef nonnull @.str.22) #43
  unreachable

5:                                                ; preds = %1
  %6 = load ptr, ptr %0, align 8, !tbaa !10
  %7 = icmp eq ptr %6, @RInteger
  br i1 %7, label %13, label %8

8:                                                ; preds = %5
  call void @llvm.lifetime.start.p0(ptr nonnull %2) #40
  %9 = load ptr, ptr %6, align 8, !tbaa !14
  %10 = getelementptr inbounds nuw i8, ptr %9, i64 16
  %11 = load ptr, ptr %10, align 8, !tbaa !17
  %12 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr nonnull dereferenceable(1) %2, i64 256, ptr nonnull @.str.25, ptr %11)
  call void @__cm_runtimeError(ptr noundef nonnull %2) #43
  unreachable

13:                                               ; preds = %5
  %14 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %15 = load i64, ptr %14, align 8, !tbaa !79
  ret i64 %15
}

; Function Attrs: mustprogress nofree norecurse nounwind ssp willreturn memory(read, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable(sync)
define range(i32 0, 2) i32 @__cm_equals(ptr noundef readonly captures(address) %0, ptr noundef readonly captures(address) %1) local_unnamed_addr #6 {
  %3 = icmp eq ptr %0, %1
  br i1 %3, label %36, label %4

4:                                                ; preds = %2
  %5 = icmp eq ptr %0, null
  %6 = icmp eq ptr %1, null
  %7 = or i1 %5, %6
  br i1 %7, label %36, label %8

8:                                                ; preds = %4
  %9 = load ptr, ptr %0, align 8, !tbaa !10
  %10 = load ptr, ptr %1, align 8, !tbaa !10
  %11 = icmp eq ptr %9, %10
  br i1 %11, label %12, label %36

12:                                               ; preds = %8
  %13 = icmp eq ptr %9, @RString
  br i1 %13, label %14, label %28

14:                                               ; preds = %12
  %15 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %16 = load i32, ptr %15, align 4, !tbaa !20
  %17 = getelementptr inbounds nuw i8, ptr %1, i64 12
  %18 = load i32, ptr %17, align 4, !tbaa !20
  %19 = icmp eq i32 %16, %18
  br i1 %19, label %20, label %36

20:                                               ; preds = %14
  %21 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %22 = load ptr, ptr %21, align 8, !tbaa !17
  %23 = getelementptr inbounds nuw i8, ptr %1, i64 16
  %24 = load ptr, ptr %23, align 8, !tbaa !17
  %25 = sext i32 %16 to i64
  %26 = tail call i32 @strncmp(ptr noundef %22, ptr noundef %24, i64 noundef %25) #40
  %27 = icmp eq i32 %26, 0
  br label %36

28:                                               ; preds = %12
  %29 = icmp eq ptr %9, @RInteger
  br i1 %29, label %30, label %36

30:                                               ; preds = %28
  %31 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %32 = load i64, ptr %31, align 8, !tbaa !79
  %33 = getelementptr inbounds nuw i8, ptr %1, i64 16
  %34 = load i64, ptr %33, align 8, !tbaa !79
  %35 = icmp eq i64 %32, %34
  br label %36

36:                                               ; preds = %20, %14, %28, %8, %4, %2, %30
  %37 = phi i1 [ false, %8 ], [ true, %2 ], [ false, %4 ], [ false, %28 ], [ %35, %30 ], [ false, %14 ], [ %27, %20 ]
  %38 = zext i1 %37 to i32
  ret i32 %38
}

; Function Attrs: nounwind ssp uwtable(sync)
define nonnull ptr @__cm_floatToString(double noundef %0) local_unnamed_addr #2 {
  %2 = alloca [64 x i8], align 1
  call void @llvm.lifetime.start.p0(ptr nonnull %2) #40
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(64) %2, i8 0, i64 64, i1 false)
  %3 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr nonnull dereferenceable(1) %2, i64 64, ptr nonnull @.str.26, double %0)
  %4 = call i64 @strlen(ptr noundef nonnull readonly dereferenceable(1) %2) #40
  %5 = trunc i64 %4 to i32
  %6 = tail call fastcc ptr @new_string(i32 noundef %5)
  %7 = getelementptr inbounds nuw i8, ptr %6, i64 16
  %8 = load ptr, ptr %7, align 8, !tbaa !17
  call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %8, ptr noundef nonnull readonly align 1 %2, i64 noundef %4, i1 noundef false) #40
  call void @llvm.lifetime.end.p0(ptr nonnull %2) #40
  ret ptr %6
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #27

; Function Attrs: nounwind ssp uwtable(sync)
define nonnull ptr @__cm_intToString(i32 noundef %0) local_unnamed_addr #2 {
  %2 = alloca [32 x i8], align 1
  call void @llvm.lifetime.start.p0(ptr nonnull %2) #40
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(32) %2, i8 0, i64 32, i1 false)
  %3 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr nonnull dereferenceable(1) %2, i64 32, ptr nonnull @.str.27, i32 %0)
  %4 = call i64 @strlen(ptr noundef nonnull readonly dereferenceable(1) %2) #40
  %5 = trunc i64 %4 to i32
  %6 = tail call fastcc ptr @new_string(i32 noundef %5)
  %7 = getelementptr inbounds nuw i8, ptr %6, i64 16
  %8 = load ptr, ptr %7, align 8, !tbaa !17
  call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %8, ptr noundef nonnull readonly align 1 %2, i64 noundef %4, i1 noundef false) #40
  call void @llvm.lifetime.end.p0(ptr nonnull %2) #40
  ret ptr %6
}

; Function Attrs: nounwind ssp uwtable(sync)
define nonnull ptr @__cm_longToString(i64 noundef %0) local_unnamed_addr #2 {
  %2 = alloca [32 x i8], align 1
  call void @llvm.lifetime.start.p0(ptr nonnull %2) #40
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(32) %2, i8 0, i64 32, i1 false)
  %3 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr nonnull dereferenceable(1) %2, i64 32, ptr nonnull @.str.28, i64 %0)
  %4 = call i64 @strlen(ptr noundef nonnull readonly dereferenceable(1) %2) #40
  %5 = trunc i64 %4 to i32
  %6 = tail call fastcc ptr @new_string(i32 noundef %5)
  %7 = getelementptr inbounds nuw i8, ptr %6, i64 16
  %8 = load ptr, ptr %7, align 8, !tbaa !17
  call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %8, ptr noundef nonnull readonly align 1 %2, i64 noundef %4, i1 noundef false) #40
  call void @llvm.lifetime.end.p0(ptr nonnull %2) #40
  ret ptr %6
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: read)
declare i32 @memcmp(ptr noundef captures(none), ptr noundef captures(none), i64 noundef) local_unnamed_addr #21

; Function Attrs: nounwind ssp uwtable(sync)
define nonnull ptr @M6_String_chr(i32 noundef %0) local_unnamed_addr #2 {
  %2 = alloca [2 x i8], align 1
  call void @llvm.lifetime.start.p0(ptr nonnull %2) #40
  %3 = trunc i32 %0 to i8
  store i8 %3, ptr %2, align 1, !tbaa !40
  %4 = getelementptr inbounds nuw i8, ptr %2, i64 1
  store i8 0, ptr %4, align 1, !tbaa !40
  %5 = call i64 @strlen(ptr noundef nonnull readonly dereferenceable(1) %2) #40
  %6 = trunc i64 %5 to i32
  %7 = tail call fastcc ptr @new_string(i32 noundef %6)
  %8 = getelementptr inbounds nuw i8, ptr %7, i64 16
  %9 = load ptr, ptr %8, align 8, !tbaa !17
  call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %9, ptr noundef nonnull readonly align 1 %2, i64 noundef %5, i1 noundef false) #40
  call void @llvm.lifetime.end.p0(ptr nonnull %2) #40
  ret ptr %7
}

declare double @"\01_strtod"(ptr noundef, ptr noundef) local_unnamed_addr #23

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(write, argmem: none, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable(sync)
define void @__cm_setArgs(i32 noundef %0, ptr noundef %1) local_unnamed_addr #28 {
  store i32 %0, ptr @gArgCount, align 4, !tbaa !6
  store ptr %1, ptr @gArgValues, align 8, !tbaa !105
  ret void
}

declare i32 @"\01_fputs"(ptr noundef, ptr noundef) local_unnamed_addr #23

declare i64 @"\01_fwrite"(ptr noundef, i64 noundef, i64 noundef, ptr noundef) local_unnamed_addr #23

; Function Attrs: nounwind ssp uwtable(sync)
define range(i32 0, 2) i32 @M4_File_exists(ptr noundef readonly captures(none) %0) local_unnamed_addr #2 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %3 = load ptr, ptr %2, align 8, !tbaa !17
  %4 = tail call ptr @"\01_fopen"(ptr noundef %3, ptr noundef nonnull @.str.18) #40
  %5 = icmp eq ptr %4, null
  br i1 %5, label %8, label %6

6:                                                ; preds = %1
  %7 = tail call i32 @fclose(ptr noundef nonnull %4)
  br label %8

8:                                                ; preds = %1, %6
  %9 = phi i32 [ 1, %6 ], [ 0, %1 ]
  ret i32 %9
}

; Function Attrs: nofree nounwind ssp uwtable(sync)
define range(i32 0, 2) i32 @M4_File_remove(ptr noundef readonly captures(none) %0) local_unnamed_addr #8 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %3 = load ptr, ptr %2, align 8, !tbaa !17
  %4 = tail call i32 @remove(ptr noundef %3)
  %5 = icmp eq i32 %4, 0
  %6 = zext i1 %5 to i32
  ret i32 %6
}

; Function Attrs: nofree nounwind
declare noundef i32 @remove(ptr noundef readonly captures(none)) local_unnamed_addr #22

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable(sync)
define noundef double @M4_Math_sqrt(double noundef %0) local_unnamed_addr #15 {
  %2 = tail call double @llvm.sqrt.f64(double %0)
  ret double %2
}

; Function Attrs: mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sqrt.f64(double) #29

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable(sync)
define noundef double @M4_Math_pow(double noundef %0, double noundef %1) local_unnamed_addr #15 {
  %3 = tail call double @llvm.pow.f64(double %0, double %1)
  ret double %3
}

; Function Attrs: mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.pow.f64(double, double) #29

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable(sync)
define noundef double @M4_Math_exp(double noundef %0) local_unnamed_addr #15 {
  %2 = tail call double @llvm.exp.f64(double %0)
  ret double %2
}

; Function Attrs: mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.exp.f64(double) #29

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable(sync)
define noundef double @M4_Math_log(double noundef %0) local_unnamed_addr #15 {
  %2 = tail call double @llvm.log.f64(double %0)
  ret double %2
}

; Function Attrs: mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.log.f64(double) #29

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable(sync)
define noundef double @M4_Math_log10(double noundef %0) local_unnamed_addr #15 {
  %2 = tail call double @llvm.log10.f64(double %0)
  ret double %2
}

; Function Attrs: mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.log10.f64(double) #29

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable(sync)
define noundef double @M4_Math_sin(double noundef %0) local_unnamed_addr #15 {
  %2 = tail call double @llvm.sin.f64(double %0)
  ret double %2
}

; Function Attrs: mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sin.f64(double) #29

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable(sync)
define noundef double @M4_Math_cos(double noundef %0) local_unnamed_addr #15 {
  %2 = tail call double @llvm.cos.f64(double %0)
  ret double %2
}

; Function Attrs: mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.cos.f64(double) #29

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable(sync)
define double @M4_Math_tan(double noundef %0) local_unnamed_addr #15 {
  %2 = tail call double @llvm.tan.f64(double %0)
  ret double %2
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.tan.f64(double) #30

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable(sync)
define double @M4_Math_atan2(double noundef %0, double noundef %1) local_unnamed_addr #15 {
  %3 = tail call double @llvm.atan2.f64(double %0, double %1)
  ret double %3
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.atan2.f64(double, double) #30

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable(sync)
define noundef double @M4_Math_floor(double noundef %0) local_unnamed_addr #15 {
  %2 = tail call double @llvm.floor.f64(double %0)
  ret double %2
}

; Function Attrs: mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.floor.f64(double) #29

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable(sync)
define noundef double @M4_Math_ceil(double noundef %0) local_unnamed_addr #15 {
  %2 = tail call double @llvm.ceil.f64(double %0)
  ret double %2
}

; Function Attrs: mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.ceil.f64(double) #29

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable(sync)
define noundef double @M4_Math_round(double noundef %0) local_unnamed_addr #15 {
  %2 = tail call double @llvm.round.f64(double %0)
  ret double %2
}

; Function Attrs: mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.round.f64(double) #29

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable(sync)
define noundef double @M4_Math_absf(double noundef %0) local_unnamed_addr #15 {
  %2 = tail call double @llvm.fabs.f64(double %0)
  ret double %2
}

; Function Attrs: mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fabs.f64(double) #29

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable(sync)
define range(i32 0, -2147483648) i32 @M4_Math_abs(i32 noundef %0) local_unnamed_addr #15 {
  %2 = tail call i32 @llvm.abs.i32(i32 %0, i1 true)
  ret i32 %2
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable(sync)
define noundef i32 @M4_Math_min(i32 noundef %0, i32 noundef %1) local_unnamed_addr #15 {
  %3 = tail call i32 @llvm.smin.i32(i32 %0, i32 %1)
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable(sync)
define noundef i32 @M4_Math_max(i32 noundef %0, i32 noundef %1) local_unnamed_addr #15 {
  %3 = tail call i32 @llvm.smax.i32(i32 %0, i32 %1)
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable(sync)
define noundef double @M4_Math_pi() local_unnamed_addr #15 {
  ret double 0x400921FB54442D18
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable(sync)
define noundef double @M4_Math_e() local_unnamed_addr #15 {
  ret double 0x4005BF0A8B145769
}

; Function Attrs: nofree nounwind ssp uwtable(sync)
define void @__cm_pushHandler(ptr noundef %0) local_unnamed_addr #8 {
  %2 = tail call dereferenceable_or_null(24) ptr @malloc(i64 noundef 24) #42
  %3 = icmp eq ptr %2, null
  br i1 %3, label %4, label %6

4:                                                ; preds = %1
  %5 = tail call i32 @puts(ptr nonnull dereferenceable(1) @str.49)
  tail call void @exit(i32 noundef 1) #39
  unreachable

6:                                                ; preds = %1
  store ptr %0, ptr %2, align 8, !tbaa !107
  %7 = load i32, ptr @gPoolDepth, align 4, !tbaa !6
  %8 = getelementptr inbounds nuw i8, ptr %2, i64 8
  store i32 %7, ptr %8, align 8, !tbaa !110
  %9 = load ptr, ptr @gHandlers, align 8, !tbaa !84
  %10 = getelementptr inbounds nuw i8, ptr %2, i64 16
  store ptr %9, ptr %10, align 8, !tbaa !111
  store ptr %2, ptr @gHandlers, align 8, !tbaa !84
  ret void
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(read, argmem: none, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable(sync)
define i32 @__cm_poolDepth() local_unnamed_addr #9 {
  %1 = load i32, ptr @gPoolDepth, align 4, !tbaa !6
  ret i32 %1
}

; Function Attrs: mustprogress nounwind ssp willreturn memory(readwrite, target_mem0: none, target_mem1: none) uwtable(sync)
define void @__cm_popHandler() local_unnamed_addr #31 {
  %1 = load ptr, ptr @gHandlers, align 8, !tbaa !84
  %2 = icmp eq ptr %1, null
  br i1 %2, label %6, label %3

3:                                                ; preds = %0
  %4 = getelementptr inbounds nuw i8, ptr %1, i64 16
  %5 = load ptr, ptr %4, align 8, !tbaa !111
  store ptr %5, ptr @gHandlers, align 8, !tbaa !84
  tail call void @free(ptr noundef nonnull %1)
  br label %6

6:                                                ; preds = %0, %3
  ret void
}

; Function Attrs: mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite)
declare void @free(ptr allocptr noundef captures(none)) local_unnamed_addr #32

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(read, argmem: none, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable(sync)
define ptr @__cm_caught() local_unnamed_addr #9 {
  %1 = load ptr, ptr @gThrown, align 8, !tbaa !26
  ret ptr %1
}

; Function Attrs: noreturn nounwind ssp uwtable(sync)
define void @__cm_throw(ptr noundef %0) local_unnamed_addr #20 {
  %2 = load ptr, ptr @gHandlers, align 8, !tbaa !84
  store ptr %0, ptr @gThrown, align 8, !tbaa !26
  %3 = icmp eq ptr %2, null
  br i1 %3, label %4, label %21

4:                                                ; preds = %1
  %5 = icmp eq ptr %0, null
  br i1 %5, label %18, label %6

6:                                                ; preds = %4
  %7 = load ptr, ptr %0, align 8, !tbaa !10
  %8 = icmp eq ptr %7, @RString
  br i1 %8, label %9, label %13

9:                                                ; preds = %6
  %10 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %11 = load ptr, ptr %10, align 8, !tbaa !17
  %12 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.31, ptr noundef %11)
  br label %20

13:                                               ; preds = %6
  %14 = load ptr, ptr %7, align 8, !tbaa !14
  %15 = getelementptr inbounds nuw i8, ptr %14, i64 16
  %16 = load ptr, ptr %15, align 8, !tbaa !17
  %17 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.32, ptr noundef %16)
  br label %20

18:                                               ; preds = %4
  %19 = tail call i32 @puts(ptr nonnull dereferenceable(1) @str.50)
  br label %20

20:                                               ; preds = %13, %18, %9
  tail call void @exit(i32 noundef 1) #39
  unreachable

21:                                               ; preds = %1
  %22 = load ptr, ptr %2, align 8, !tbaa !107
  %23 = getelementptr inbounds nuw i8, ptr %2, i64 16
  %24 = load ptr, ptr %23, align 8, !tbaa !111
  store ptr %24, ptr @gHandlers, align 8, !tbaa !84
  %25 = getelementptr inbounds nuw i8, ptr %2, i64 8
  %26 = load i32, ptr %25, align 8, !tbaa !110
  tail call void @__cm_poolUnwind(i32 noundef %26)
  tail call void @free(ptr noundef nonnull %2)
  tail call void @longjmp(ptr noundef %22, i32 noundef 1) #45
  unreachable
}

; Function Attrs: nounwind ssp uwtable(sync)
define void @__cm_poolUnwind(i32 noundef %0) local_unnamed_addr #2 {
  %2 = load i32, ptr @gPoolDepth, align 4, !tbaa !6
  %3 = icmp sgt i32 %2, %0
  br i1 %3, label %4, label %44

4:                                                ; preds = %1, %41
  %5 = phi i32 [ %42, %41 ], [ %2, %1 ]
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %41, label %7

7:                                                ; preds = %4
  %8 = add nsw i32 %5, -1
  store i32 %8, ptr @gPoolDepth, align 4, !tbaa !6
  %9 = load ptr, ptr @gPoolMarks, align 8, !tbaa !112
  %10 = sext i32 %8 to i64
  %11 = getelementptr inbounds i32, ptr %9, i64 %10
  %12 = load i32, ptr %11, align 4, !tbaa !6
  %13 = load i32, ptr @gPoolCount, align 4, !tbaa !6
  %14 = icmp sgt i32 %13, %12
  br i1 %14, label %15, label %41

15:                                               ; preds = %7
  %16 = load ptr, ptr @gPoolItems, align 8, !tbaa !81
  br label %17

17:                                               ; preds = %35, %15
  %18 = phi ptr [ %37, %35 ], [ %16, %15 ]
  %19 = phi i32 [ %36, %35 ], [ %13, %15 ]
  %20 = add nsw i32 %19, -1
  %21 = sext i32 %20 to i64
  %22 = getelementptr inbounds ptr, ptr %18, i64 %21
  %23 = load ptr, ptr %22, align 8, !tbaa !26
  store i32 %20, ptr @gPoolCount, align 4, !tbaa !6
  %24 = icmp eq ptr %23, null
  br i1 %24, label %35, label %25

25:                                               ; preds = %17
  %26 = getelementptr inbounds nuw i8, ptr %23, i64 8
  %27 = load i32, ptr %26, align 8, !tbaa !16
  %28 = icmp eq i32 %27, 0
  br i1 %28, label %35, label %29

29:                                               ; preds = %25
  %30 = add nsw i32 %27, -1
  store i32 %30, ptr %26, align 8, !tbaa !16
  %31 = icmp eq i32 %30, 0
  br i1 %31, label %32, label %35

32:                                               ; preds = %29
  store i32 1, ptr %26, align 8, !tbaa !16
  tail call fastcc void @object_free(ptr noundef %23)
  %33 = load ptr, ptr @gPoolItems, align 8, !tbaa !81
  %34 = load i32, ptr @gPoolCount, align 4, !tbaa !6
  br label %35

35:                                               ; preds = %32, %29, %25, %17
  %36 = phi i32 [ %20, %17 ], [ %20, %25 ], [ %20, %29 ], [ %34, %32 ]
  %37 = phi ptr [ %18, %17 ], [ %18, %25 ], [ %18, %29 ], [ %33, %32 ]
  %38 = icmp sgt i32 %36, %12
  br i1 %38, label %17, label %39, !llvm.loop !113

39:                                               ; preds = %35
  %40 = load i32, ptr @gPoolDepth, align 4, !tbaa !6
  br label %41

41:                                               ; preds = %39, %4, %7
  %42 = phi i32 [ %40, %39 ], [ 0, %4 ], [ %8, %7 ]
  %43 = icmp sgt i32 %42, %0
  br i1 %43, label %4, label %44, !llvm.loop !114

44:                                               ; preds = %41, %1
  ret void
}

; Function Attrs: noreturn
declare void @longjmp(ptr noundef, i32 noundef) local_unnamed_addr #33

; Function Attrs: nounwind ssp uwtable(sync)
define void @__cm_poolPush() local_unnamed_addr #2 {
  %1 = load i32, ptr @gPoolDepth, align 4, !tbaa !6
  %2 = load i32, ptr @gPoolMarkCapacity, align 4, !tbaa !6
  %3 = icmp eq i32 %1, %2
  %4 = load ptr, ptr @gPoolMarks, align 8, !tbaa !112
  br i1 %3, label %5, label %16

5:                                                ; preds = %0
  %6 = icmp eq i32 %1, 0
  %7 = shl nsw i32 %1, 1
  %8 = select i1 %6, i32 32, i32 %7
  %9 = sext i32 %8 to i64
  %10 = shl nsw i64 %9, 2
  %11 = tail call ptr @realloc(ptr noundef %4, i64 noundef %10) #44
  %12 = icmp eq ptr %11, null
  br i1 %12, label %13, label %15

13:                                               ; preds = %5
  %14 = tail call i32 @puts(ptr nonnull dereferenceable(1) @str.51)
  tail call void @exit(i32 noundef 1) #39
  unreachable

15:                                               ; preds = %5
  store ptr %11, ptr @gPoolMarks, align 8, !tbaa !112
  store i32 %8, ptr @gPoolMarkCapacity, align 4, !tbaa !6
  br label %16

16:                                               ; preds = %15, %0
  %17 = phi ptr [ %11, %15 ], [ %4, %0 ]
  %18 = load i32, ptr @gPoolCount, align 4, !tbaa !6
  %19 = sext i32 %1 to i64
  %20 = getelementptr inbounds i32, ptr %17, i64 %19
  store i32 %18, ptr %20, align 4, !tbaa !6
  %21 = add nsw i32 %1, 1
  store i32 %21, ptr @gPoolDepth, align 4, !tbaa !6
  ret void
}

; Function Attrs: nounwind ssp uwtable(sync)
define void @__cm_poolPop() local_unnamed_addr #2 {
  %1 = load i32, ptr @gPoolDepth, align 4, !tbaa !6
  %2 = icmp eq i32 %1, 0
  br i1 %2, label %35, label %3

3:                                                ; preds = %0
  %4 = add nsw i32 %1, -1
  store i32 %4, ptr @gPoolDepth, align 4, !tbaa !6
  %5 = load ptr, ptr @gPoolMarks, align 8, !tbaa !112
  %6 = sext i32 %4 to i64
  %7 = getelementptr inbounds i32, ptr %5, i64 %6
  %8 = load i32, ptr %7, align 4, !tbaa !6
  %9 = load i32, ptr @gPoolCount, align 4, !tbaa !6
  %10 = icmp sgt i32 %9, %8
  br i1 %10, label %11, label %35

11:                                               ; preds = %3
  %12 = load ptr, ptr @gPoolItems, align 8, !tbaa !81
  br label %13

13:                                               ; preds = %11, %31
  %14 = phi ptr [ %33, %31 ], [ %12, %11 ]
  %15 = phi i32 [ %32, %31 ], [ %9, %11 ]
  %16 = add nsw i32 %15, -1
  %17 = sext i32 %16 to i64
  %18 = getelementptr inbounds ptr, ptr %14, i64 %17
  %19 = load ptr, ptr %18, align 8, !tbaa !26
  store i32 %16, ptr @gPoolCount, align 4, !tbaa !6
  %20 = icmp eq ptr %19, null
  br i1 %20, label %31, label %21

21:                                               ; preds = %13
  %22 = getelementptr inbounds nuw i8, ptr %19, i64 8
  %23 = load i32, ptr %22, align 8, !tbaa !16
  %24 = icmp eq i32 %23, 0
  br i1 %24, label %31, label %25

25:                                               ; preds = %21
  %26 = add nsw i32 %23, -1
  store i32 %26, ptr %22, align 8, !tbaa !16
  %27 = icmp eq i32 %26, 0
  br i1 %27, label %28, label %31

28:                                               ; preds = %25
  store i32 1, ptr %22, align 8, !tbaa !16
  tail call fastcc void @object_free(ptr noundef %19)
  %29 = load ptr, ptr @gPoolItems, align 8, !tbaa !81
  %30 = load i32, ptr @gPoolCount, align 4, !tbaa !6
  br label %31

31:                                               ; preds = %13, %21, %25, %28
  %32 = phi i32 [ %16, %13 ], [ %16, %21 ], [ %16, %25 ], [ %30, %28 ]
  %33 = phi ptr [ %14, %13 ], [ %14, %21 ], [ %14, %25 ], [ %29, %28 ]
  %34 = icmp sgt i32 %32, %8
  br i1 %34, label %13, label %35, !llvm.loop !113

35:                                               ; preds = %31, %3, %0
  ret void
}

; Function Attrs: nounwind ssp uwtable(sync)
define range(i32 -1, 256) i32 @M7_Process_run(ptr noundef readonly captures(none) %0) local_unnamed_addr #2 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %3 = load ptr, ptr %2, align 8, !tbaa !17
  %4 = tail call i32 @"\01_system"(ptr noundef %3) #40
  %5 = icmp eq i32 %4, -1
  br i1 %5, label %13, label %6

6:                                                ; preds = %1
  %7 = and i32 %4, 127
  switch i32 %7, label %11 [
    i32 0, label %8
    i32 127, label %13
  ]

8:                                                ; preds = %6
  %9 = lshr i32 %4, 8
  %10 = and i32 %9, 255
  br label %13

11:                                               ; preds = %6
  %12 = or disjoint i32 %7, 128
  br label %13

13:                                               ; preds = %11, %8, %6, %1
  %14 = phi i32 [ -1, %1 ], [ %10, %8 ], [ %12, %11 ], [ -1, %6 ]
  ret i32 %14
}

declare i32 @"\01_system"(ptr noundef) local_unnamed_addr #23

; Function Attrs: nounwind ssp uwtable(sync)
define range(i32 0, -2147483648) i32 @M7_Process_start(ptr noundef readonly captures(none) %0) local_unnamed_addr #2 {
  %2 = tail call i32 @fork() #40
  %3 = icmp slt i32 %2, 0
  br i1 %3, label %10, label %4

4:                                                ; preds = %1
  %5 = icmp eq i32 %2, 0
  br i1 %5, label %6, label %10

6:                                                ; preds = %4
  %7 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %8 = load ptr, ptr %7, align 8, !tbaa !17
  %9 = tail call i32 (ptr, ptr, ...) @execl(ptr noundef nonnull @.str.37, ptr noundef nonnull @.str.38, ptr noundef nonnull @.str.39, ptr noundef %8, ptr noundef null) #40
  tail call void @_exit(i32 noundef 127) #45
  unreachable

10:                                               ; preds = %4, %1
  %11 = phi i32 [ 0, %1 ], [ %2, %4 ]
  ret i32 %11
}

; Function Attrs: nofree
declare i32 @fork() local_unnamed_addr #34

; Function Attrs: nofree
declare i32 @execl(ptr noundef, ptr noundef, ...) local_unnamed_addr #34

; Function Attrs: noreturn
declare void @_exit(i32 noundef) local_unnamed_addr #33

; Function Attrs: nounwind ssp uwtable(sync)
define range(i32 -1, 256) i32 @M7_Process_wait(i32 noundef %0) local_unnamed_addr #2 {
  %2 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(ptr nonnull %2) #40
  store i32 0, ptr %2, align 4, !tbaa !6
  %3 = icmp slt i32 %0, 1
  br i1 %3, label %15, label %4

4:                                                ; preds = %1
  %5 = call i32 @"\01_waitpid"(i32 noundef %0, ptr noundef nonnull %2, i32 noundef 0) #40
  %6 = icmp slt i32 %5, 0
  br i1 %6, label %15, label %7

7:                                                ; preds = %4
  %8 = load i32, ptr %2, align 4, !tbaa !6
  %9 = and i32 %8, 127
  switch i32 %9, label %13 [
    i32 0, label %10
    i32 127, label %15
  ]

10:                                               ; preds = %7
  %11 = lshr i32 %8, 8
  %12 = and i32 %11, 255
  br label %15

13:                                               ; preds = %7
  %14 = or disjoint i32 %9, 128
  br label %15

15:                                               ; preds = %13, %10, %7, %4, %1
  %16 = phi i32 [ -1, %4 ], [ -1, %1 ], [ %12, %10 ], [ %14, %13 ], [ -1, %7 ]
  call void @llvm.lifetime.end.p0(ptr nonnull %2) #40
  ret i32 %16
}

declare i32 @"\01_waitpid"(i32 noundef, ptr noundef, i32 noundef) local_unnamed_addr #23

; Function Attrs: nounwind ssp uwtable(sync)
define i32 @M7_Process_pid() local_unnamed_addr #2 {
  %1 = tail call i32 @getpid() #40
  ret i32 %1
}

declare i32 @getpid() local_unnamed_addr #23

; Function Attrs: nofree nounwind
declare noundef i32 @pclose(ptr noundef captures(none)) local_unnamed_addr #22

declare ptr @"\01_popen"(ptr noundef, ptr noundef) local_unnamed_addr #23

; Function Attrs: nounwind ssp uwtable(sync)
define range(i32 -2147483647, -2147483648) i32 @__cm_workerStart(ptr noundef %0, i64 noundef %1) local_unnamed_addr #2 {
  %3 = load i32, ptr @gWorkerCount, align 4, !tbaa !6
  %4 = icmp sgt i32 %3, 255
  br i1 %4, label %5, label %6

5:                                                ; preds = %2
  tail call void @__cm_runtimeError(ptr noundef nonnull @.str.40) #43
  unreachable

6:                                                ; preds = %2
  %7 = sext i32 %3 to i64
  %8 = getelementptr inbounds %struct.__cm_worker, ptr @gWorkers, i64 %7
  %9 = getelementptr inbounds nuw i8, ptr %8, i64 8
  store ptr %0, ptr %9, align 8, !tbaa !115
  %10 = getelementptr inbounds nuw i8, ptr %8, i64 16
  store i64 %1, ptr %10, align 8, !tbaa !118
  %11 = getelementptr inbounds nuw i8, ptr %8, i64 24
  store i64 0, ptr %11, align 8, !tbaa !119
  %12 = getelementptr inbounds nuw i8, ptr %8, i64 32
  store i32 1, ptr %12, align 8, !tbaa !120
  %13 = tail call i32 @pthread_create(ptr noundef nonnull %8, ptr noundef null, ptr noundef nonnull @worker_body, ptr noundef nonnull %8) #40
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %16, label %15

15:                                               ; preds = %6
  store i32 0, ptr %12, align 8, !tbaa !120
  br label %19

16:                                               ; preds = %6
  %17 = load i32, ptr @gWorkerCount, align 4, !tbaa !6
  %18 = add nsw i32 %17, 1
  store i32 %18, ptr @gWorkerCount, align 4, !tbaa !6
  br label %19

19:                                               ; preds = %16, %15
  %20 = phi i32 [ 0, %15 ], [ %18, %16 ]
  ret i32 %20
}

declare i32 @pthread_create(ptr noundef, ptr noundef, ptr noundef, ptr noundef) local_unnamed_addr #23

; Function Attrs: nounwind ssp uwtable(sync)
define internal noalias noundef ptr @worker_body(ptr noundef captures(none) initializes((24, 32)) %0) #2 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %3 = load ptr, ptr %2, align 8, !tbaa !115
  %4 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %5 = load i64, ptr %4, align 8, !tbaa !118
  %6 = tail call i64 %3(i64 noundef %5) #40
  %7 = getelementptr inbounds nuw i8, ptr %0, i64 24
  store i64 %6, ptr %7, align 8, !tbaa !119
  ret ptr null
}

; Function Attrs: nounwind ssp uwtable(sync)
define i64 @M6_Worker_wait(i32 noundef %0) local_unnamed_addr #2 {
  %2 = icmp eq i32 %0, 0
  br i1 %2, label %27, label %3

3:                                                ; preds = %1
  %4 = icmp slt i32 %0, 1
  %5 = load i32, ptr @gWorkerCount, align 4
  %6 = icmp sgt i32 %0, %5
  %7 = select i1 %4, i1 true, i1 %6
  br i1 %7, label %8, label %9

8:                                                ; preds = %3
  tail call void @__cm_runtimeError(ptr noundef nonnull @.str.41) #43
  unreachable

9:                                                ; preds = %3
  %10 = zext nneg i32 %0 to i64
  %11 = getelementptr %struct.__cm_worker, ptr @gWorkers, i64 %10
  %12 = getelementptr i8, ptr %11, i64 -8
  %13 = load i32, ptr %12, align 8, !tbaa !120
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %15, label %16

15:                                               ; preds = %9
  tail call void @__cm_runtimeError(ptr noundef nonnull @.str.42) #43
  unreachable

16:                                               ; preds = %9
  %17 = getelementptr i8, ptr %11, i64 -40
  %18 = load ptr, ptr %17, align 8, !tbaa !121
  %19 = tail call i32 @"\01_pthread_join"(ptr noundef %18, ptr noundef null) #40
  store i32 0, ptr %12, align 8, !tbaa !120
  %20 = load i32, ptr @gWorkersCollected, align 4, !tbaa !6
  %21 = add nsw i32 %20, 1
  store i32 %21, ptr @gWorkersCollected, align 4, !tbaa !6
  %22 = getelementptr i8, ptr %11, i64 -16
  %23 = load i64, ptr %22, align 8, !tbaa !119
  %24 = load i32, ptr @gWorkerCount, align 4, !tbaa !6
  %25 = icmp eq i32 %21, %24
  br i1 %25, label %26, label %27

26:                                               ; preds = %16
  store i32 0, ptr @gWorkerCount, align 4, !tbaa !6
  store i32 0, ptr @gWorkersCollected, align 4, !tbaa !6
  br label %27

27:                                               ; preds = %16, %26, %1
  %28 = phi i64 [ 0, %1 ], [ %23, %26 ], [ %23, %16 ]
  ret i64 %28
}

declare i32 @"\01_pthread_join"(ptr noundef, ptr noundef) local_unnamed_addr #23

; Function Attrs: nounwind ssp uwtable(sync)
define i32 @M6_Worker_count() local_unnamed_addr #2 {
  %1 = tail call i64 @sysconf(i32 noundef 58) #40
  %2 = icmp sgt i64 %1, 0
  %3 = trunc i64 %1 to i32
  %4 = select i1 %2, i32 %3, i32 1
  ret i32 %4
}

declare i64 @sysconf(i32 noundef) local_unnamed_addr #23

; Function Attrs: nounwind ssp uwtable(sync)
define void @M5_Bytes_init(ptr noundef captures(none) %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = alloca [128 x i8], align 1
  %4 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %5 = load ptr, ptr %4, align 8, !tbaa !34
  tail call void @free(ptr noundef %5)
  %6 = icmp slt i32 %1, 0
  br i1 %6, label %7, label %9

7:                                                ; preds = %2
  call void @llvm.lifetime.start.p0(ptr nonnull %3) #40
  %8 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr nonnull dereferenceable(1) %3, i64 128, ptr nonnull @.str.45, ptr nonnull @.str.9, i32 %1)
  call void @__cm_runtimeError(ptr noundef nonnull %3) #43
  unreachable

9:                                                ; preds = %2
  %10 = icmp eq i32 %1, 0
  br i1 %10, label %16, label %11

11:                                               ; preds = %9
  %12 = zext nneg i32 %1 to i64
  %13 = tail call ptr @calloc(i64 noundef %12, i64 noundef 1) #41
  %14 = icmp eq ptr %13, null
  br i1 %14, label %15, label %16

15:                                               ; preds = %11
  tail call void @__cm_runtimeError(ptr noundef nonnull @.str.46) #43
  unreachable

16:                                               ; preds = %9, %11
  %17 = phi ptr [ null, %9 ], [ %13, %11 ]
  store ptr %17, ptr %4, align 8, !tbaa !34
  %18 = getelementptr inbounds nuw i8, ptr %0, i64 12
  store i32 %1, ptr %18, align 4, !tbaa !36
  ret void
}

; Function Attrs: nounwind ssp uwtable(sync)
define void @M4_Ints_init(ptr noundef captures(none) %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = alloca [128 x i8], align 1
  %4 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %5 = load ptr, ptr %4, align 8, !tbaa !63
  tail call void @free(ptr noundef %5)
  %6 = icmp slt i32 %1, 0
  br i1 %6, label %7, label %9

7:                                                ; preds = %2
  call void @llvm.lifetime.start.p0(ptr nonnull %3) #40
  %8 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr nonnull dereferenceable(1) %3, i64 128, ptr nonnull @.str.45, ptr nonnull @.str.10, i32 %1)
  call void @__cm_runtimeError(ptr noundef nonnull %3) #43
  unreachable

9:                                                ; preds = %2
  %10 = icmp eq i32 %1, 0
  br i1 %10, label %16, label %11

11:                                               ; preds = %9
  %12 = zext nneg i32 %1 to i64
  %13 = tail call ptr @calloc(i64 noundef %12, i64 noundef 8) #41
  %14 = icmp eq ptr %13, null
  br i1 %14, label %15, label %16

15:                                               ; preds = %11
  tail call void @__cm_runtimeError(ptr noundef nonnull @.str.46) #43
  unreachable

16:                                               ; preds = %9, %11
  %17 = phi ptr [ null, %9 ], [ %13, %11 ]
  store ptr %17, ptr %4, align 8, !tbaa !63
  %18 = getelementptr inbounds nuw i8, ptr %0, i64 12
  store i32 %1, ptr %18, align 4, !tbaa !60
  ret void
}

; Function Attrs: nounwind ssp uwtable(sync)
define void @M6_Floats_init(ptr noundef captures(none) %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = alloca [128 x i8], align 1
  %4 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %5 = load ptr, ptr %4, align 8, !tbaa !73
  tail call void @free(ptr noundef %5)
  %6 = icmp slt i32 %1, 0
  br i1 %6, label %7, label %9

7:                                                ; preds = %2
  call void @llvm.lifetime.start.p0(ptr nonnull %3) #40
  %8 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr nonnull dereferenceable(1) %3, i64 128, ptr nonnull @.str.45, ptr nonnull @.str.11, i32 %1)
  call void @__cm_runtimeError(ptr noundef nonnull %3) #43
  unreachable

9:                                                ; preds = %2
  %10 = icmp eq i32 %1, 0
  br i1 %10, label %16, label %11

11:                                               ; preds = %9
  %12 = zext nneg i32 %1 to i64
  %13 = tail call ptr @calloc(i64 noundef %12, i64 noundef 8) #41
  %14 = icmp eq ptr %13, null
  br i1 %14, label %15, label %16

15:                                               ; preds = %11
  tail call void @__cm_runtimeError(ptr noundef nonnull @.str.46) #43
  unreachable

16:                                               ; preds = %9, %11
  %17 = phi ptr [ null, %9 ], [ %13, %11 ]
  store ptr %17, ptr %4, align 8, !tbaa !73
  %18 = getelementptr inbounds nuw i8, ptr %0, i64 12
  store i32 %1, ptr %18, align 4, !tbaa !70
  ret void
}

declare i32 @__maskrune(i32 noundef, i64 noundef) local_unnamed_addr #23

declare i32 @__toupper(i32 noundef) local_unnamed_addr #23

declare i32 @__tolower(i32 noundef) local_unnamed_addr #23

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #35

; Function Attrs: nofree nounwind
declare noundef i32 @snprintf(ptr noalias noundef writeonly captures(none), i64 noundef, ptr noundef readonly captures(none), ...) local_unnamed_addr #35

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.abs.i32(i32, i1 immarg) #36

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smin.i32(i32, i32) #37

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #37

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write)
declare void @llvm.assume(i1 noundef) #38

attributes #0 = { cold nofree noreturn nounwind ssp uwtable(sync) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #1 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(read, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable(sync) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #2 = { nounwind ssp uwtable(sync) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable(sync) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #4 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable(sync) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #5 = { mustprogress nofree norecurse nounwind ssp willreturn uwtable(sync) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #6 = { mustprogress nofree norecurse nounwind ssp willreturn memory(read, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable(sync) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #7 = { nofree norecurse nounwind ssp memory(read, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable(sync) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #8 = { nofree nounwind ssp uwtable(sync) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #9 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(read, argmem: none, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable(sync) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #10 = { nofree noreturn nounwind ssp uwtable(sync) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #11 = { nofree norecurse nounwind ssp memory(readwrite, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable(sync) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #12 = { nofree norecurse nosync nounwind ssp memory(write, argmem: readwrite, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable(sync) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #13 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #14 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #15 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable(sync) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #16 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable(sync) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #17 = { nofree noreturn "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #18 = { mustprogress nofree nounwind willreturn allockind("alloc,zeroed") allocsize(0,1) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #19 = { mustprogress nocallback nofree nounwind willreturn "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #20 = { noreturn nounwind ssp uwtable(sync) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #21 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #22 = { nofree nounwind "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #23 = { "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #24 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #25 = { mustprogress nounwind willreturn allockind("realloc") allocsize(1) memory(argmem: readwrite, inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #26 = { nofree norecurse nosync nounwind ssp memory(read, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable(sync) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #27 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #28 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(write, argmem: none, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable(sync) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #29 = { mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
attributes #30 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #31 = { mustprogress nounwind ssp willreturn memory(readwrite, target_mem0: none, target_mem1: none) uwtable(sync) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #32 = { mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #33 = { noreturn "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #34 = { nofree "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #35 = { nofree nounwind }
attributes #36 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #37 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
attributes #38 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write) }
attributes #39 = { cold noreturn nounwind }
attributes #40 = { nounwind }
attributes #41 = { allocsize(0,1) }
attributes #42 = { allocsize(0) }
attributes #43 = { noreturn }
attributes #44 = { allocsize(1) }
attributes #45 = { noreturn nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}
!llvm.errno.tbaa = !{!6}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 5]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 1}
!4 = !{i32 7, !"frame-pointer", i32 4}
!5 = !{!"Homebrew clang version 22.1.8"}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !12, i64 0}
!11 = !{!"TObject", !12, i64 0, !7, i64 8}
!12 = !{!"p1 _ZTS14__catmint_rtti", !13, i64 0}
!13 = !{!"any pointer", !8, i64 0}
!14 = !{!15, !15, i64 0}
!15 = !{!"p1 _ZTS7TString", !13, i64 0}
!16 = !{!11, !7, i64 8}
!17 = !{!18, !19, i64 16}
!18 = !{!"TString", !12, i64 0, !7, i64 8, !7, i64 12, !19, i64 16}
!19 = !{!"p1 omnipotent char", !13, i64 0}
!20 = !{!18, !7, i64 12}
!21 = !{!22, !7, i64 16}
!22 = !{!"TList", !12, i64 0, !7, i64 8, !7, i64 12, !7, i64 16, !23, i64 24}
!23 = !{!"any p2 pointer", !13, i64 0}
!24 = !{!22, !23, i64 24}
!25 = !{!22, !7, i64 12}
!26 = !{!13, !13, i64 0}
!27 = distinct !{!27, !28}
!28 = !{!"llvm.loop.mustprogress"}
!29 = !{!30, !31, i64 16}
!30 = !{!"TFile", !12, i64 0, !7, i64 8, !31, i64 16}
!31 = !{!"p1 _ZTS7__sFILE", !13, i64 0}
!32 = !{!33, !31, i64 16}
!33 = !{!"TProcess", !12, i64 0, !7, i64 8, !31, i64 16, !7, i64 24}
!34 = !{!35, !19, i64 16}
!35 = !{!"TBytes", !12, i64 0, !7, i64 8, !7, i64 12, !19, i64 16}
!36 = !{!35, !7, i64 12}
!37 = distinct !{!37, !38}
!38 = !{!"llvm.loop.unroll.disable"}
!39 = !{!19, !19, i64 0}
!40 = !{!8, !8, i64 0}
!41 = distinct !{!41, !28}
!42 = distinct !{!42, !28}
!43 = distinct !{!43, !28}
!44 = distinct !{!44, !28}
!45 = distinct !{!45, !28}
!46 = distinct !{!46, !28}
!47 = distinct !{!47, !28}
!48 = !{!31, !31, i64 0}
!49 = !{i64 0, i64 8, !50, i64 8, i64 8, !50}
!50 = !{!51, !51, i64 0}
!51 = !{!"long", !8, i64 0}
!52 = !{!53, !51, i64 0}
!53 = !{!"timespec", !51, i64 0, !51, i64 8}
!54 = !{!53, !51, i64 8}
!55 = !{!56, !7, i64 8}
!56 = !{!"tm", !7, i64 0, !7, i64 4, !7, i64 8, !7, i64 12, !7, i64 16, !7, i64 20, !7, i64 24, !7, i64 28, !7, i64 32, !51, i64 40, !19, i64 48}
!57 = !{!56, !7, i64 4}
!58 = !{!56, !7, i64 0}
!59 = !{!56, !7, i64 28}
!60 = !{!61, !7, i64 12}
!61 = !{!"TInts", !12, i64 0, !7, i64 8, !7, i64 12, !62, i64 16}
!62 = !{!"p1 long long", !13, i64 0}
!63 = !{!61, !62, i64 16}
!64 = !{!65, !65, i64 0}
!65 = !{!"long long", !8, i64 0}
!66 = distinct !{!66, !28, !67, !68}
!67 = !{!"llvm.loop.isvectorized", i32 1}
!68 = !{!"llvm.loop.unroll.runtime.disable"}
!69 = distinct !{!69, !28, !68, !67}
!70 = !{!71, !7, i64 12}
!71 = !{!"TFloats", !12, i64 0, !7, i64 8, !7, i64 12, !72, i64 16}
!72 = !{!"p1 double", !13, i64 0}
!73 = !{!71, !72, i64 16}
!74 = !{!75, !75, i64 0}
!75 = !{!"double", !8, i64 0}
!76 = distinct !{!76, !28, !67, !68}
!77 = distinct !{!77, !28, !68, !67}
!78 = distinct !{!78, !28}
!79 = !{!80, !65, i64 16}
!80 = !{!"TInteger", !12, i64 0, !7, i64 8, !65, i64 16}
!81 = !{!23, !23, i64 0}
!82 = !{!33, !7, i64 24}
!83 = distinct !{!83, !28}
!84 = !{!85, !85, i64 0}
!85 = !{!"p1 _ZTS12__cm_handler", !13, i64 0}
!86 = !{!18, !12, i64 0}
!87 = !{!18, !7, i64 8}
!88 = distinct !{!88, !28}
!89 = distinct !{!89, !38}
!90 = distinct !{!90, !28}
!91 = distinct !{!91, !38}
!92 = !{!12, !12, i64 0}
!93 = !{!94, !12, i64 0}
!94 = !{!"__cm_iface", !12, i64 0, !7, i64 8}
!95 = distinct !{!95, !28}
!96 = distinct !{!96, !28}
!97 = !{!94, !7, i64 8}
!98 = distinct !{!98, !28}
!99 = distinct !{!99, !28}
!100 = distinct !{!100, !28}
!101 = distinct !{!101, !28}
!102 = !{!80, !12, i64 0}
!103 = !{!80, !7, i64 8}
!104 = distinct !{!104, !28, !67, !68}
!105 = !{!106, !106, i64 0}
!106 = !{!"p2 omnipotent char", !23, i64 0}
!107 = !{!108, !109, i64 0}
!108 = !{!"__cm_handler", !109, i64 0, !7, i64 8, !85, i64 16}
!109 = !{!"p1 int", !13, i64 0}
!110 = !{!108, !7, i64 8}
!111 = !{!108, !85, i64 16}
!112 = !{!109, !109, i64 0}
!113 = distinct !{!113, !28}
!114 = distinct !{!114, !28}
!115 = !{!116, !13, i64 8}
!116 = !{!"__cm_worker", !117, i64 0, !13, i64 8, !65, i64 16, !65, i64 24, !7, i64 32}
!117 = !{!"p1 _ZTS17_opaque_pthread_t", !13, i64 0}
!118 = !{!116, !65, i64 16}
!119 = !{!116, !65, i64 24}
!120 = !{!116, !7, i64 32}
!121 = !{!116, !117, i64 0}
