; ModuleID = 'runtime.c'
source_filename = "runtime.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.TString = type { %struct.__lcpl_rtti*, i32, i8* }
%struct.__lcpl_rtti = type { %struct.TString*, i32, %struct.__lcpl_rtti*, [0 x i8*] }
%struct.TObject = type { %struct.__lcpl_rtti* }
%struct.TIO = type { %struct.__lcpl_rtti* }

@.str = private unnamed_addr constant [7 x i8] c"Object\00", align 1
@NObject = dso_local global %struct.TString { %struct.__lcpl_rtti* bitcast ({ %struct.TString*, i32, %struct.__lcpl_rtti*, [8 x i8*] }* @RString to %struct.__lcpl_rtti*), i32 6, i8* getelementptr inbounds ([7 x i8], [7 x i8]* @.str, i32 0, i32 0) }, align 8
@.str.1 = private unnamed_addr constant [7 x i8] c"String\00", align 1
@NString = dso_local global %struct.TString { %struct.__lcpl_rtti* bitcast ({ %struct.TString*, i32, %struct.__lcpl_rtti*, [8 x i8*] }* @RString to %struct.__lcpl_rtti*), i32 6, i8* getelementptr inbounds ([7 x i8], [7 x i8]* @.str.1, i32 0, i32 0) }, align 8
@.str.2 = private unnamed_addr constant [3 x i8] c"IO\00", align 1
@NIO = dso_local global %struct.TString { %struct.__lcpl_rtti* bitcast ({ %struct.TString*, i32, %struct.__lcpl_rtti*, [8 x i8*] }* @RString to %struct.__lcpl_rtti*), i32 2, i8* getelementptr inbounds ([3 x i8], [3 x i8]* @.str.2, i32 0, i32 0) }, align 8
@RObject = dso_local global { %struct.TString*, i32, %struct.__lcpl_rtti*, [3 x i8*] } { %struct.TString* @NObject, i32 8, %struct.__lcpl_rtti* null, [3 x i8*] [i8* bitcast (void (%struct.TObject*)* @M6_Object_abort to i8*), i8* bitcast (%struct.TString* (%struct.TObject*)* @M6_Object_typeName to i8*), i8* bitcast (%struct.TObject* (%struct.TObject*)* @M6_Object_copy to i8*)] }, align 8
@RString = dso_local global { %struct.TString*, i32, %struct.__lcpl_rtti*, [8 x i8*] } { %struct.TString* @NString, i32 24, %struct.__lcpl_rtti* bitcast ({ %struct.TString*, i32, %struct.__lcpl_rtti*, [3 x i8*] }* @RObject to %struct.__lcpl_rtti*), [8 x i8*] [i8* bitcast (void (%struct.TObject*)* @M6_Object_abort to i8*), i8* bitcast (%struct.TString* (%struct.TObject*)* @M6_Object_typeName to i8*), i8* bitcast (%struct.TObject* (%struct.TObject*)* @M6_Object_copy to i8*), i8* bitcast (i32 (%struct.TString*)* @M6_String_length to i8*), i8* bitcast (i32 (%struct.TString*)* @M6_String_toInt to i8*), i8* bitcast (%struct.TString* (%struct.TString*, i32, i32)* @M6_String_substring to i8*), i8* bitcast (%struct.TString* (%struct.TString*, %struct.TString*)* @M6_String_concat to i8*), i8* bitcast (i32 (%struct.TString*, %struct.TString*)* @M6_String_equal to i8*)] }, align 8
@RIO = dso_local global { %struct.TString*, i32, %struct.__lcpl_rtti*, [5 x i8*] } { %struct.TString* @NIO, i32 8, %struct.__lcpl_rtti* bitcast ({ %struct.TString*, i32, %struct.__lcpl_rtti*, [3 x i8*] }* @RObject to %struct.__lcpl_rtti*), [5 x i8*] [i8* bitcast (void (%struct.TObject*)* @M6_Object_abort to i8*), i8* bitcast (%struct.TString* (%struct.TObject*)* @M6_Object_typeName to i8*), i8* bitcast (%struct.TObject* (%struct.TObject*)* @M6_Object_copy to i8*), i8* bitcast (%struct.TString* (%struct.TIO*)* @M2_IO_in to i8*), i8* bitcast (%struct.TIO* (%struct.TIO*, %struct.TString*)* @M2_IO_out to i8*)] }, align 8
@.str.4 = private unnamed_addr constant [3 x i8] c"%s\00", align 1
@.str.5 = private unnamed_addr constant [1 x i8] zeroinitializer, align 1
@.str.6 = private unnamed_addr constant [50 x i8] c"Runtime error : Substring indices out of bounds.\0A\00", align 1
@.str.7 = private unnamed_addr constant [52 x i8] c"Runtime error : Calling a method of a void object.\0A\00", align 1
@.str.8 = private unnamed_addr constant [47 x i8] c"Runtime error : Unable to convert %s into %s.\0A\00", align 1
@.str.9 = private unnamed_addr constant [3 x i8] c"%d\00", align 1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @M6_Object_abort(%struct.TObject* %0) #0 {
  %2 = alloca %struct.TObject*, align 8
  store %struct.TObject* %0, %struct.TObject** %2, align 8
  call void @exit(i32 1) #6
  unreachable
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local %struct.TString* @M6_Object_typeName(%struct.TObject* %0) #0 {
  %2 = alloca %struct.TObject*, align 8
  store %struct.TObject* %0, %struct.TObject** %2, align 8
  %3 = load %struct.TObject*, %struct.TObject** %2, align 8
  %4 = getelementptr inbounds %struct.TObject, %struct.TObject* %3, i32 0, i32 0
  %5 = load %struct.__lcpl_rtti*, %struct.__lcpl_rtti** %4, align 8
  %6 = getelementptr inbounds %struct.__lcpl_rtti, %struct.__lcpl_rtti* %5, i32 0, i32 0
  %7 = load %struct.TString*, %struct.TString** %6, align 8
  ret %struct.TString* %7
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local %struct.TObject* @M6_Object_copy(%struct.TObject* %0) #0 {
  %2 = alloca %struct.TObject*, align 8
  %3 = alloca %struct.TObject*, align 8
  store %struct.TObject* %0, %struct.TObject** %2, align 8
  %4 = load %struct.TObject*, %struct.TObject** %2, align 8
  %5 = getelementptr inbounds %struct.TObject, %struct.TObject* %4, i32 0, i32 0
  %6 = load %struct.__lcpl_rtti*, %struct.__lcpl_rtti** %5, align 8
  %7 = getelementptr inbounds %struct.__lcpl_rtti, %struct.__lcpl_rtti* %6, i32 0, i32 1
  %8 = load i32, i32* %7, align 8
  %9 = sext i32 %8 to i64
  %10 = call noalias i8* @malloc(i64 %9) #7
  %11 = bitcast i8* %10 to %struct.TObject*
  store %struct.TObject* %11, %struct.TObject** %3, align 8
  %12 = load %struct.TObject*, %struct.TObject** %3, align 8
  %13 = bitcast %struct.TObject* %12 to i8*
  %14 = load %struct.TObject*, %struct.TObject** %2, align 8
  %15 = bitcast %struct.TObject* %14 to i8*
  %16 = load %struct.TObject*, %struct.TObject** %2, align 8
  %17 = getelementptr inbounds %struct.TObject, %struct.TObject* %16, i32 0, i32 0
  %18 = load %struct.__lcpl_rtti*, %struct.__lcpl_rtti** %17, align 8
  %19 = getelementptr inbounds %struct.__lcpl_rtti, %struct.__lcpl_rtti* %18, i32 0, i32 1
  %20 = load i32, i32* %19, align 8
  %21 = sext i32 %20 to i64
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 8 %13, i8* align 8 %15, i64 %21, i1 false)
  %22 = load %struct.TObject*, %struct.TObject** %3, align 8
  ret %struct.TObject* %22
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @M6_String_length(%struct.TString* %0) #0 {
  %2 = alloca %struct.TString*, align 8
  store %struct.TString* %0, %struct.TString** %2, align 8
  %3 = load %struct.TString*, %struct.TString** %2, align 8
  %4 = getelementptr inbounds %struct.TString, %struct.TString* %3, i32 0, i32 1
  %5 = load i32, i32* %4, align 8
  ret i32 %5
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @M6_String_toInt(%struct.TString* %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca %struct.TString*, align 8
  %4 = alloca i8*, align 8
  %5 = alloca i32, align 4
  store %struct.TString* %0, %struct.TString** %3, align 8
  %6 = load %struct.TString*, %struct.TString** %3, align 8
  %7 = getelementptr inbounds %struct.TString, %struct.TString* %6, i32 0, i32 2
  %8 = load i8*, i8** %7, align 8
  %9 = call i64 @strtol(i8* %8, i8** %4, i32 10) #7
  %10 = trunc i64 %9 to i32
  store i32 %10, i32* %5, align 4
  %11 = load i8*, i8** %4, align 8
  %12 = load i8, i8* %11, align 1
  %13 = icmp ne i8 %12, 0
  br i1 %13, label %14, label %15

14:                                               ; preds = %1
  store i32 0, i32* %2, align 4
  br label %17

15:                                               ; preds = %1
  %16 = load i32, i32* %5, align 4
  store i32 %16, i32* %2, align 4
  br label %17

17:                                               ; preds = %15, %14
  %18 = load i32, i32* %2, align 4
  ret i32 %18
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local %struct.TString* @M6_String_substring(%struct.TString* %0, i32 %1, i32 %2) #0 {
  %4 = alloca %struct.TString*, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca %struct.TString*, align 8
  store %struct.TString* %0, %struct.TString** %4, align 8
  store i32 %1, i32* %5, align 4
  store i32 %2, i32* %6, align 4
  %8 = load i32, i32* %5, align 4
  %9 = icmp slt i32 %8, 0
  br i1 %9, label %20, label %10

10:                                               ; preds = %3
  %11 = load i32, i32* %5, align 4
  %12 = load i32, i32* %6, align 4
  %13 = icmp sgt i32 %11, %12
  br i1 %13, label %20, label %14

14:                                               ; preds = %10
  %15 = load i32, i32* %6, align 4
  %16 = load %struct.TString*, %struct.TString** %4, align 8
  %17 = getelementptr inbounds %struct.TString, %struct.TString* %16, i32 0, i32 1
  %18 = load i32, i32* %17, align 8
  %19 = icmp sgt i32 %15, %18
  br i1 %19, label %20, label %22

20:                                               ; preds = %14, %10, %3
  %21 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([50 x i8], [50 x i8]* @.str.6, i64 0, i64 0))
  call void @exit(i32 1) #6
  unreachable

22:                                               ; preds = %14
  %23 = call i8* @__lcpl_new(%struct.__lcpl_rtti* bitcast ({ %struct.TString*, i32, %struct.__lcpl_rtti*, [8 x i8*] }* @RString to %struct.__lcpl_rtti*))
  %24 = bitcast i8* %23 to %struct.TString*
  store %struct.TString* %24, %struct.TString** %7, align 8
  %25 = load %struct.TString*, %struct.TString** %7, align 8
  call void @String_init(%struct.TString* %25)
  %26 = load i32, i32* %6, align 4
  %27 = load i32, i32* %5, align 4
  %28 = sub nsw i32 %26, %27
  %29 = load %struct.TString*, %struct.TString** %7, align 8
  %30 = getelementptr inbounds %struct.TString, %struct.TString* %29, i32 0, i32 1
  store i32 %28, i32* %30, align 8
  %31 = load i32, i32* %6, align 4
  %32 = load i32, i32* %5, align 4
  %33 = sub nsw i32 %31, %32
  %34 = add nsw i32 %33, 1
  %35 = sext i32 %34 to i64
  %36 = call noalias i8* @calloc(i64 %35, i64 1) #7
  %37 = load %struct.TString*, %struct.TString** %7, align 8
  %38 = getelementptr inbounds %struct.TString, %struct.TString* %37, i32 0, i32 2
  store i8* %36, i8** %38, align 8
  %39 = load %struct.TString*, %struct.TString** %7, align 8
  %40 = getelementptr inbounds %struct.TString, %struct.TString* %39, i32 0, i32 2
  %41 = load i8*, i8** %40, align 8
  %42 = load %struct.TString*, %struct.TString** %4, align 8
  %43 = getelementptr inbounds %struct.TString, %struct.TString* %42, i32 0, i32 2
  %44 = load i8*, i8** %43, align 8
  %45 = load i32, i32* %5, align 4
  %46 = sext i32 %45 to i64
  %47 = getelementptr inbounds i8, i8* %44, i64 %46
  %48 = load i32, i32* %6, align 4
  %49 = load i32, i32* %5, align 4
  %50 = sub nsw i32 %48, %49
  %51 = sext i32 %50 to i64
  %52 = call i8* @strncpy(i8* %41, i8* %47, i64 %51) #7
  %53 = load %struct.TString*, %struct.TString** %7, align 8
  ret %struct.TString* %53
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local %struct.TString* @M6_String_concat(%struct.TString* %0, %struct.TString* %1) #0 {
  %3 = alloca %struct.TString*, align 8
  %4 = alloca %struct.TString*, align 8
  %5 = alloca i32, align 4
  %6 = alloca %struct.TString*, align 8
  store %struct.TString* %0, %struct.TString** %3, align 8
  store %struct.TString* %1, %struct.TString** %4, align 8
  %7 = load %struct.TString*, %struct.TString** %3, align 8
  %8 = getelementptr inbounds %struct.TString, %struct.TString* %7, i32 0, i32 1
  %9 = load i32, i32* %8, align 8
  %10 = load %struct.TString*, %struct.TString** %4, align 8
  %11 = getelementptr inbounds %struct.TString, %struct.TString* %10, i32 0, i32 1
  %12 = load i32, i32* %11, align 8
  %13 = add nsw i32 %9, %12
  store i32 %13, i32* %5, align 4
  %14 = call i8* @__lcpl_new(%struct.__lcpl_rtti* bitcast ({ %struct.TString*, i32, %struct.__lcpl_rtti*, [8 x i8*] }* @RString to %struct.__lcpl_rtti*))
  %15 = bitcast i8* %14 to %struct.TString*
  store %struct.TString* %15, %struct.TString** %6, align 8
  %16 = load %struct.TString*, %struct.TString** %6, align 8
  call void @String_init(%struct.TString* %16)
  %17 = load i32, i32* %5, align 4
  %18 = load %struct.TString*, %struct.TString** %6, align 8
  %19 = getelementptr inbounds %struct.TString, %struct.TString* %18, i32 0, i32 1
  store i32 %17, i32* %19, align 8
  %20 = load i32, i32* %5, align 4
  %21 = add nsw i32 %20, 1
  %22 = sext i32 %21 to i64
  %23 = call noalias i8* @calloc(i64 %22, i64 1) #7
  %24 = load %struct.TString*, %struct.TString** %6, align 8
  %25 = getelementptr inbounds %struct.TString, %struct.TString* %24, i32 0, i32 2
  store i8* %23, i8** %25, align 8
  %26 = load %struct.TString*, %struct.TString** %6, align 8
  %27 = getelementptr inbounds %struct.TString, %struct.TString* %26, i32 0, i32 2
  %28 = load i8*, i8** %27, align 8
  %29 = load %struct.TString*, %struct.TString** %3, align 8
  %30 = getelementptr inbounds %struct.TString, %struct.TString* %29, i32 0, i32 2
  %31 = load i8*, i8** %30, align 8
  %32 = load %struct.TString*, %struct.TString** %3, align 8
  %33 = getelementptr inbounds %struct.TString, %struct.TString* %32, i32 0, i32 1
  %34 = load i32, i32* %33, align 8
  %35 = sext i32 %34 to i64
  %36 = call i8* @strncpy(i8* %28, i8* %31, i64 %35) #7
  %37 = load %struct.TString*, %struct.TString** %6, align 8
  %38 = getelementptr inbounds %struct.TString, %struct.TString* %37, i32 0, i32 2
  %39 = load i8*, i8** %38, align 8
  %40 = load %struct.TString*, %struct.TString** %4, align 8
  %41 = getelementptr inbounds %struct.TString, %struct.TString* %40, i32 0, i32 2
  %42 = load i8*, i8** %41, align 8
  %43 = load %struct.TString*, %struct.TString** %4, align 8
  %44 = getelementptr inbounds %struct.TString, %struct.TString* %43, i32 0, i32 1
  %45 = load i32, i32* %44, align 8
  %46 = sext i32 %45 to i64
  %47 = call i8* @strncat(i8* %39, i8* %42, i64 %46) #7
  %48 = load %struct.TString*, %struct.TString** %6, align 8
  ret %struct.TString* %48
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @M6_String_equal(%struct.TString* %0, %struct.TString* %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca %struct.TString*, align 8
  %5 = alloca %struct.TString*, align 8
  store %struct.TString* %0, %struct.TString** %4, align 8
  store %struct.TString* %1, %struct.TString** %5, align 8
  %6 = load %struct.TString*, %struct.TString** %4, align 8
  %7 = icmp ne %struct.TString* %6, null
  br i1 %7, label %13, label %8

8:                                                ; preds = %2
  %9 = load %struct.TString*, %struct.TString** %5, align 8
  %10 = icmp ne %struct.TString* %9, null
  %11 = xor i1 %10, true
  %12 = zext i1 %11 to i32
  store i32 %12, i32* %3, align 4
  br label %40

13:                                               ; preds = %2
  %14 = load %struct.TString*, %struct.TString** %5, align 8
  %15 = icmp ne %struct.TString* %14, null
  br i1 %15, label %17, label %16

16:                                               ; preds = %13
  store i32 0, i32* %3, align 4
  br label %40

17:                                               ; preds = %13
  %18 = load %struct.TString*, %struct.TString** %4, align 8
  %19 = getelementptr inbounds %struct.TString, %struct.TString* %18, i32 0, i32 1
  %20 = load i32, i32* %19, align 8
  %21 = load %struct.TString*, %struct.TString** %5, align 8
  %22 = getelementptr inbounds %struct.TString, %struct.TString* %21, i32 0, i32 1
  %23 = load i32, i32* %22, align 8
  %24 = icmp ne i32 %20, %23
  br i1 %24, label %25, label %26

25:                                               ; preds = %17
  store i32 0, i32* %3, align 4
  br label %40

26:                                               ; preds = %17
  %27 = load %struct.TString*, %struct.TString** %4, align 8
  %28 = getelementptr inbounds %struct.TString, %struct.TString* %27, i32 0, i32 2
  %29 = load i8*, i8** %28, align 8
  %30 = load %struct.TString*, %struct.TString** %5, align 8
  %31 = getelementptr inbounds %struct.TString, %struct.TString* %30, i32 0, i32 2
  %32 = load i8*, i8** %31, align 8
  %33 = load %struct.TString*, %struct.TString** %4, align 8
  %34 = getelementptr inbounds %struct.TString, %struct.TString* %33, i32 0, i32 1
  %35 = load i32, i32* %34, align 8
  %36 = sext i32 %35 to i64
  %37 = call i32 @strncmp(i8* %29, i8* %32, i64 %36) #8
  %38 = icmp eq i32 %37, 0
  %39 = zext i1 %38 to i32
  store i32 %39, i32* %3, align 4
  br label %40

40:                                               ; preds = %26, %25, %16, %8
  %41 = load i32, i32* %3, align 4
  ret i32 %41
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local %struct.TString* @M2_IO_in(%struct.TIO* %0) #0 {
  %2 = alloca %struct.TIO*, align 8
  %3 = alloca [256 x i8], align 16
  %4 = alloca %struct.TString*, align 8
  store %struct.TIO* %0, %struct.TIO** %2, align 8
  %5 = getelementptr inbounds [256 x i8], [256 x i8]* %3, i64 0, i64 0
  %6 = call i32 (i8*, ...) @__isoc99_scanf(i8* getelementptr inbounds ([3 x i8], [3 x i8]* @.str.4, i64 0, i64 0), i8* %5)
  %7 = call i8* @__lcpl_new(%struct.__lcpl_rtti* bitcast ({ %struct.TString*, i32, %struct.__lcpl_rtti*, [8 x i8*] }* @RString to %struct.__lcpl_rtti*))
  %8 = bitcast i8* %7 to %struct.TString*
  store %struct.TString* %8, %struct.TString** %4, align 8
  %9 = load %struct.TString*, %struct.TString** %4, align 8
  call void @String_init(%struct.TString* %9)
  %10 = getelementptr inbounds [256 x i8], [256 x i8]* %3, i64 0, i64 0
  %11 = call i64 @strlen(i8* %10) #8
  %12 = trunc i64 %11 to i32
  %13 = load %struct.TString*, %struct.TString** %4, align 8
  %14 = getelementptr inbounds %struct.TString, %struct.TString* %13, i32 0, i32 1
  store i32 %12, i32* %14, align 8
  %15 = load %struct.TString*, %struct.TString** %4, align 8
  %16 = getelementptr inbounds %struct.TString, %struct.TString* %15, i32 0, i32 1
  %17 = load i32, i32* %16, align 8
  %18 = add nsw i32 %17, 1
  %19 = sext i32 %18 to i64
  %20 = call noalias i8* @calloc(i64 %19, i64 1) #7
  %21 = load %struct.TString*, %struct.TString** %4, align 8
  %22 = getelementptr inbounds %struct.TString, %struct.TString* %21, i32 0, i32 2
  store i8* %20, i8** %22, align 8
  %23 = load %struct.TString*, %struct.TString** %4, align 8
  %24 = getelementptr inbounds %struct.TString, %struct.TString* %23, i32 0, i32 2
  %25 = load i8*, i8** %24, align 8
  %26 = getelementptr inbounds [256 x i8], [256 x i8]* %3, i64 0, i64 0
  %27 = call i8* @strcpy(i8* %25, i8* %26) #7
  %28 = load %struct.TString*, %struct.TString** %4, align 8
  ret %struct.TString* %28
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local %struct.TIO* @M2_IO_out(%struct.TIO* %0, %struct.TString* %1) #0 {
  %3 = alloca %struct.TIO*, align 8
  %4 = alloca %struct.TString*, align 8
  store %struct.TIO* %0, %struct.TIO** %3, align 8
  store %struct.TString* %1, %struct.TString** %4, align 8
  %5 = load %struct.TString*, %struct.TString** %4, align 8
  %6 = getelementptr inbounds %struct.TString, %struct.TString* %5, i32 0, i32 2
  %7 = load i8*, i8** %6, align 8
  %8 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([3 x i8], [3 x i8]* @.str.4, i64 0, i64 0), i8* %7)
  %9 = load %struct.TIO*, %struct.TIO** %3, align 8
  ret %struct.TIO* %9
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @Object_init(%struct.TObject* %0) #0 {
  %2 = alloca %struct.TObject*, align 8
  store %struct.TObject* %0, %struct.TObject** %2, align 8
  ret void
}

; Function Attrs: noreturn nounwind
declare dso_local void @exit(i32) #1

; Function Attrs: nounwind
declare dso_local noalias i8* @malloc(i64) #2

; Function Attrs: argmemonly nounwind willreturn
declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly, i8* noalias nocapture readonly, i64, i1 immarg) #3

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @IO_init(%struct.TIO* %0) #0 {
  %2 = alloca %struct.TIO*, align 8
  store %struct.TIO* %0, %struct.TIO** %2, align 8
  ret void
}

declare dso_local i32 @__isoc99_scanf(i8*, ...) #4

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i8* @__lcpl_new(%struct.__lcpl_rtti* %0) #0 {
  %2 = alloca %struct.__lcpl_rtti*, align 8
  %3 = alloca i8*, align 8
  store %struct.__lcpl_rtti* %0, %struct.__lcpl_rtti** %2, align 8
  %4 = load %struct.__lcpl_rtti*, %struct.__lcpl_rtti** %2, align 8
  %5 = getelementptr inbounds %struct.__lcpl_rtti, %struct.__lcpl_rtti* %4, i32 0, i32 1
  %6 = load i32, i32* %5, align 8
  %7 = sext i32 %6 to i64
  %8 = call noalias i8* @malloc(i64 %7) #7
  store i8* %8, i8** %3, align 8
  %9 = load i8*, i8** %3, align 8
  %10 = load %struct.__lcpl_rtti*, %struct.__lcpl_rtti** %2, align 8
  %11 = getelementptr inbounds %struct.__lcpl_rtti, %struct.__lcpl_rtti* %10, i32 0, i32 1
  %12 = load i32, i32* %11, align 8
  %13 = sext i32 %12 to i64
  call void @llvm.memset.p0i8.i64(i8* align 1 %9, i8 0, i64 %13, i1 false)
  %14 = load %struct.__lcpl_rtti*, %struct.__lcpl_rtti** %2, align 8
  %15 = load i8*, i8** %3, align 8
  %16 = bitcast i8* %15 to %struct.TObject*
  %17 = getelementptr inbounds %struct.TObject, %struct.TObject* %16, i32 0, i32 0
  store %struct.__lcpl_rtti* %14, %struct.__lcpl_rtti** %17, align 8
  %18 = load i8*, i8** %3, align 8
  ret i8* %18
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @String_init(%struct.TString* %0) #0 {
  %2 = alloca %struct.TString*, align 8
  store %struct.TString* %0, %struct.TString** %2, align 8
  %3 = load %struct.TString*, %struct.TString** %2, align 8
  %4 = getelementptr inbounds %struct.TString, %struct.TString* %3, i32 0, i32 2
  store i8* getelementptr inbounds ([1 x i8], [1 x i8]* @.str.5, i64 0, i64 0), i8** %4, align 8
  %5 = load %struct.TString*, %struct.TString** %2, align 8
  %6 = getelementptr inbounds %struct.TString, %struct.TString* %5, i32 0, i32 1
  store i32 0, i32* %6, align 8
  ret void
}

; Function Attrs: nounwind readonly
declare dso_local i64 @strlen(i8*) #5

; Function Attrs: nounwind
declare dso_local noalias i8* @calloc(i64, i64) #2

; Function Attrs: nounwind
declare dso_local i8* @strcpy(i8*, i8*) #2

declare dso_local i32 @printf(i8*, ...) #4

; Function Attrs: nounwind
declare dso_local i64 @strtol(i8*, i8**, i32) #2

; Function Attrs: nounwind
declare dso_local i8* @strncpy(i8*, i8*, i64) #2

; Function Attrs: nounwind
declare dso_local i8* @strncat(i8*, i8*, i64) #2

; Function Attrs: nounwind readonly
declare dso_local i32 @strncmp(i8*, i8*, i64) #5

; Function Attrs: argmemonly nounwind willreturn
declare void @llvm.memset.p0i8.i64(i8* nocapture writeonly, i8, i64, i1 immarg) #3

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @__lcpl_checkNull(i8* %0) #0 {
  %2 = alloca i8*, align 8
  store i8* %0, i8** %2, align 8
  %3 = load i8*, i8** %2, align 8
  %4 = icmp ne i8* %3, null
  br i1 %4, label %7, label %5

5:                                                ; preds = %1
  %6 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([52 x i8], [52 x i8]* @.str.7, i64 0, i64 0))
  call void @exit(i32 1) #6
  unreachable

7:                                                ; preds = %1
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i8* @__lcpl_cast(i8* %0, %struct.__lcpl_rtti* %1) #0 {
  %3 = alloca i8*, align 8
  %4 = alloca i8*, align 8
  %5 = alloca %struct.__lcpl_rtti*, align 8
  %6 = alloca %struct.__lcpl_rtti*, align 8
  %7 = alloca %struct.__lcpl_rtti*, align 8
  store i8* %0, i8** %4, align 8
  store %struct.__lcpl_rtti* %1, %struct.__lcpl_rtti** %5, align 8
  %8 = load i8*, i8** %4, align 8
  %9 = icmp eq i8* %8, null
  br i1 %9, label %10, label %11

10:                                               ; preds = %2
  store i8* null, i8** %3, align 8
  br label %42

11:                                               ; preds = %2
  %12 = load i8*, i8** %4, align 8
  %13 = bitcast i8* %12 to %struct.TObject*
  %14 = getelementptr inbounds %struct.TObject, %struct.TObject* %13, i32 0, i32 0
  %15 = load %struct.__lcpl_rtti*, %struct.__lcpl_rtti** %14, align 8
  store %struct.__lcpl_rtti* %15, %struct.__lcpl_rtti** %6, align 8
  %16 = load %struct.__lcpl_rtti*, %struct.__lcpl_rtti** %6, align 8
  store %struct.__lcpl_rtti* %16, %struct.__lcpl_rtti** %7, align 8
  br label %17

17:                                               ; preds = %26, %11
  %18 = load %struct.__lcpl_rtti*, %struct.__lcpl_rtti** %7, align 8
  %19 = icmp ne %struct.__lcpl_rtti* %18, null
  br i1 %19, label %20, label %30

20:                                               ; preds = %17
  %21 = load %struct.__lcpl_rtti*, %struct.__lcpl_rtti** %7, align 8
  %22 = load %struct.__lcpl_rtti*, %struct.__lcpl_rtti** %5, align 8
  %23 = icmp eq %struct.__lcpl_rtti* %21, %22
  br i1 %23, label %24, label %26

24:                                               ; preds = %20
  %25 = load i8*, i8** %4, align 8
  store i8* %25, i8** %3, align 8
  br label %42

26:                                               ; preds = %20
  %27 = load %struct.__lcpl_rtti*, %struct.__lcpl_rtti** %7, align 8
  %28 = getelementptr inbounds %struct.__lcpl_rtti, %struct.__lcpl_rtti* %27, i32 0, i32 2
  %29 = load %struct.__lcpl_rtti*, %struct.__lcpl_rtti** %28, align 8
  store %struct.__lcpl_rtti* %29, %struct.__lcpl_rtti** %7, align 8
  br label %17

30:                                               ; preds = %17
  %31 = load %struct.__lcpl_rtti*, %struct.__lcpl_rtti** %6, align 8
  %32 = getelementptr inbounds %struct.__lcpl_rtti, %struct.__lcpl_rtti* %31, i32 0, i32 0
  %33 = load %struct.TString*, %struct.TString** %32, align 8
  %34 = getelementptr inbounds %struct.TString, %struct.TString* %33, i32 0, i32 2
  %35 = load i8*, i8** %34, align 8
  %36 = load %struct.__lcpl_rtti*, %struct.__lcpl_rtti** %5, align 8
  %37 = getelementptr inbounds %struct.__lcpl_rtti, %struct.__lcpl_rtti* %36, i32 0, i32 0
  %38 = load %struct.TString*, %struct.TString** %37, align 8
  %39 = getelementptr inbounds %struct.TString, %struct.TString* %38, i32 0, i32 2
  %40 = load i8*, i8** %39, align 8
  %41 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([47 x i8], [47 x i8]* @.str.8, i64 0, i64 0), i8* %35, i8* %40)
  call void @exit(i32 1) #6
  unreachable

42:                                               ; preds = %24, %10
  %43 = load i8*, i8** %3, align 8
  ret i8* %43
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local %struct.TString* @__lcpl_intToString(i32 %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca [32 x i8], align 16
  %4 = alloca %struct.TString*, align 8
  store i32 %0, i32* %2, align 4
  %5 = bitcast [32 x i8]* %3 to i8*
  call void @llvm.memset.p0i8.i64(i8* align 16 %5, i8 0, i64 32, i1 false)
  %6 = getelementptr inbounds [32 x i8], [32 x i8]* %3, i64 0, i64 0
  %7 = load i32, i32* %2, align 4
  %8 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* %6, i64 32, i8* getelementptr inbounds ([3 x i8], [3 x i8]* @.str.9, i64 0, i64 0), i32 %7) #7
  %9 = call i8* @__lcpl_new(%struct.__lcpl_rtti* bitcast ({ %struct.TString*, i32, %struct.__lcpl_rtti*, [8 x i8*] }* @RString to %struct.__lcpl_rtti*))
  %10 = bitcast i8* %9 to %struct.TString*
  store %struct.TString* %10, %struct.TString** %4, align 8
  %11 = load %struct.TString*, %struct.TString** %4, align 8
  call void @String_init(%struct.TString* %11)
  %12 = getelementptr inbounds [32 x i8], [32 x i8]* %3, i64 0, i64 0
  %13 = call i64 @strlen(i8* %12) #8
  %14 = trunc i64 %13 to i32
  %15 = load %struct.TString*, %struct.TString** %4, align 8
  %16 = getelementptr inbounds %struct.TString, %struct.TString* %15, i32 0, i32 1
  store i32 %14, i32* %16, align 8
  %17 = load %struct.TString*, %struct.TString** %4, align 8
  %18 = getelementptr inbounds %struct.TString, %struct.TString* %17, i32 0, i32 1
  %19 = load i32, i32* %18, align 8
  %20 = add nsw i32 %19, 1
  %21 = sext i32 %20 to i64
  %22 = call noalias i8* @calloc(i64 %21, i64 1) #7
  %23 = load %struct.TString*, %struct.TString** %4, align 8
  %24 = getelementptr inbounds %struct.TString, %struct.TString* %23, i32 0, i32 2
  store i8* %22, i8** %24, align 8
  %25 = load %struct.TString*, %struct.TString** %4, align 8
  %26 = getelementptr inbounds %struct.TString, %struct.TString* %25, i32 0, i32 2
  %27 = load i8*, i8** %26, align 8
  %28 = getelementptr inbounds [32 x i8], [32 x i8]* %3, i64 0, i64 0
  %29 = call i8* @strcpy(i8* %27, i8* %28) #7
  %30 = load %struct.TString*, %struct.TString** %4, align 8
  ret %struct.TString* %30
}

; Function Attrs: nounwind
declare dso_local i32 @snprintf(i8*, i64, i8*, ...) #2

attributes #0 = { noinline nounwind optnone uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { noreturn nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { argmemonly nounwind willreturn }
attributes #4 = { "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #5 = { nounwind readonly "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #6 = { noreturn nounwind }
attributes #7 = { nounwind }
attributes #8 = { nounwind readonly }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{!"clang version 10.0.0-4ubuntu1 "}