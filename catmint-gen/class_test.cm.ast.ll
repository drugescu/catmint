; ModuleID = 'class_test.cm.ast'
source_filename = "class_test.cm.ast"

%struct.__catmint_rtti = type { %struct.TString*, i32, %struct.__catmint_rtti*, [0 x i8*] }
%struct.TString = type { %struct.__catmint_rtti*, i32, i8* }
%struct.TIO = type { %struct.__catmint_rtti* }

@RString = external global %struct.__catmint_rtti
@RIO = external global %struct.__catmint_rtti
@0 = private unnamed_addr constant [14 x i8] c"Hello World!\0A\00", align 1
@1 = private unnamed_addr constant [14 x i8] c"Hello World!\0A\00", align 1
@2 = private unnamed_addr constant [14 x i8] c"Hello World!\0A\00", align 1
@3 = private unnamed_addr constant [14 x i8] c"Hello World!\0A\00", align 1
@4 = private unnamed_addr constant [6 x i8] c"test\0A\00", align 1

declare %struct.TIO* @M2_IO_out(%struct.TIO*, %struct.TString*)

declare %struct.TIO* @M2_IO_in(%struct.TIO*)

declare i8* @__catmint_new(%struct.__catmint_rtti*)

define void @M4_Main_main() {
entry_block:
  %0 = call i8* @__catmint_new(%struct.__catmint_rtti* @RString)
  %1 = bitcast i8* %0 to %struct.TString*
  %2 = getelementptr %struct.TString, %struct.TString* %1, i32 0, i32 1
  store i32 13, i32* %2
  %3 = getelementptr %struct.TString, %struct.TString* %1, i32 0, i32 2
  store i8* getelementptr inbounds ([14 x i8], [14 x i8]* @0, i32 0, i32 0), i8** %3
  %4 = call i8* @__catmint_new(%struct.__catmint_rtti* @RIO)
  %5 = bitcast i8* %4 to %struct.TIO*
  %6 = call %struct.TIO* @M2_IO_out(%struct.TIO* %5, %struct.TString* %1)
  br label %entry_block1

entry_block1:                                     ; preds = %entry_block
  %7 = call i8* @__catmint_new(%struct.__catmint_rtti* @RString)
  %8 = bitcast i8* %7 to %struct.TString*
  %9 = getelementptr %struct.TString, %struct.TString* %8, i32 0, i32 1
  store i32 13, i32* %9
  %10 = getelementptr %struct.TString, %struct.TString* %8, i32 0, i32 2
  store i8* getelementptr inbounds ([14 x i8], [14 x i8]* @1, i32 0, i32 0), i8** %10
  %11 = call i8* @__catmint_new(%struct.__catmint_rtti* @RIO)
  %12 = bitcast i8* %11 to %struct.TIO*
  %13 = call %struct.TIO* @M2_IO_out(%struct.TIO* %12, %struct.TString* %8)
  br label %entry_block2

entry_block2:                                     ; preds = %entry_block1
  %14 = call i8* @__catmint_new(%struct.__catmint_rtti* @RString)
  %15 = bitcast i8* %14 to %struct.TString*
  %16 = getelementptr %struct.TString, %struct.TString* %15, i32 0, i32 1
  store i32 13, i32* %16
  %17 = getelementptr %struct.TString, %struct.TString* %15, i32 0, i32 2
  store i8* getelementptr inbounds ([14 x i8], [14 x i8]* @2, i32 0, i32 0), i8** %17
  %18 = call i8* @__catmint_new(%struct.__catmint_rtti* @RIO)
  %19 = bitcast i8* %18 to %struct.TIO*
  %20 = call %struct.TIO* @M2_IO_out(%struct.TIO* %19, %struct.TString* %15)
  br label %entry_block3

entry_block3:                                     ; preds = %entry_block2
  %21 = call i8* @__catmint_new(%struct.__catmint_rtti* @RString)
  %22 = bitcast i8* %21 to %struct.TString*
  %23 = getelementptr %struct.TString, %struct.TString* %22, i32 0, i32 1
  store i32 13, i32* %23
  %24 = getelementptr %struct.TString, %struct.TString* %22, i32 0, i32 2
  store i8* getelementptr inbounds ([14 x i8], [14 x i8]* @3, i32 0, i32 0), i8** %24
  %25 = call i8* @__catmint_new(%struct.__catmint_rtti* @RIO)
  %26 = bitcast i8* %25 to %struct.TIO*
  %27 = call %struct.TIO* @M2_IO_out(%struct.TIO* %26, %struct.TString* %22)
  %28 = call i8* @__catmint_new(%struct.__catmint_rtti* @RString)
  %29 = bitcast i8* %28 to %struct.TString*
  %30 = getelementptr %struct.TString, %struct.TString* %29, i32 0, i32 1
  store i32 5, i32* %30
  %31 = getelementptr %struct.TString, %struct.TString* %29, i32 0, i32 2
  store i8* getelementptr inbounds ([6 x i8], [6 x i8]* @4, i32 0, i32 0), i8** %31
  %32 = call i8* @__catmint_new(%struct.__catmint_rtti* @RIO)
  %33 = bitcast i8* %32 to %struct.TIO*
  %34 = call %struct.TIO* @M2_IO_out(%struct.TIO* %33, %struct.TString* %29)
  %35 = call i8* @__catmint_new(%struct.__catmint_rtti* @RIO)
  %36 = bitcast i8* %35 to %struct.TIO*
  %37 = call %struct.TIO* @M2_IO_in(%struct.TIO* %36)
  ret void
}

define i32 @main() {
  call void @M4_Main_main()
  ret i32 0
}
