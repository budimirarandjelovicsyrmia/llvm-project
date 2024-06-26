; RUN: opt < %s -S -passes=globalopt | FileCheck %s

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128"

@.str91250 = global [3 x i8] zeroinitializer

; CHECK: @A = local_unnamed_addr global i64 4
@A = global i64 ptrtoint (ptr getelementptr (i32, ptr null, i64 1) to i64)

; PR11352

@xs = global [2 x i32] zeroinitializer, align 4
; CHECK: @xs = local_unnamed_addr global [2 x i32] [i32 1, i32 1]

; PR12642
%PR12642.struct = type { i8 }
@PR12642.s = global <{}> zeroinitializer, align 1
@PR12642.p = constant ptr getelementptr (i8, ptr @PR12642.s, i64 1), align 8

define internal void @test1() {
entry:
  store i32 1, ptr @xs
  %0 = load i32, ptr @xs, align 4
  store i32 %0, ptr getelementptr inbounds ([2 x i32], ptr @xs, i64 0, i64 1)
  ret void
}

; PR12060

%closure = type { i32 }

@f = internal global %closure zeroinitializer, align 4
@m = global i32 0, align 4
; CHECK-NOT: @f
; CHECK: @m = local_unnamed_addr global i32 13

define internal i32 @test2_helper(ptr %this, i32 %b) {
entry:
  %0 = load i32, ptr %this, align 4
  %add = add nsw i32 %0, %b
  ret i32 %add
}

define internal void @test2() {
entry:
  store i32 4, ptr @f
  %call = call i32 @test2_helper(ptr @f, i32 9)
  store i32 %call, ptr @m, align 4
  ret void
}

; PR19955

@dllimportptr = global ptr null, align 4
; CHECK: @dllimportptr = local_unnamed_addr global ptr null, align 4
@dllimportvar = external dllimport global i32
define internal void @test3() {
entry:
  store ptr @dllimportvar, ptr @dllimportptr, align 4
  ret void
}

@dllexportptr = global ptr null, align 4
; CHECK: @dllexportptr = local_unnamed_addr global ptr @dllexportvar, align 4
@dllexportvar = dllexport global i32 0, align 4
; CHECK: @dllexportvar = dllexport global i32 20, align 4
define internal void @test4() {
entry:
  store i32 20, ptr @dllexportvar, align 4
  store ptr @dllexportvar, ptr @dllexportptr, align 4
  ret void
}

@threadlocalptr = global ptr null, align 4
; CHECK: @threadlocalptr = local_unnamed_addr global ptr null, align 4
@threadlocalvar = external thread_local global i32
define internal void @test5() {
entry:
  %p = call ptr @llvm.threadlocal.address(ptr @threadlocalvar)
  store ptr %p, ptr @threadlocalptr, align 4
  ret void
}

@test6_v1 = internal global { i32, i32 } { i32 42, i32 0 }, align 8
@test6_v2 = global i32 0, align 4
; CHECK: @test6_v2 = local_unnamed_addr global i32 42, align 4
define internal void @test6() {
  %load = load { i32, i32 }, ptr @test6_v1, align 8
  %xv0 = extractvalue { i32, i32 } %load, 0
  %iv = insertvalue { i32, i32 } %load, i32 %xv0, 1
  %xv1 = extractvalue { i32, i32 } %iv, 1
  store i32 %xv1, ptr @test6_v2, align 4
  ret void
}

@llvm.global_ctors = appending constant
  [6 x { i32, ptr, ptr }]
  [{ i32, ptr, ptr } { i32 65535, ptr @test1, ptr null },
   { i32, ptr, ptr } { i32 65535, ptr @test2, ptr null },
   { i32, ptr, ptr } { i32 65535, ptr @test3, ptr null },
   { i32, ptr, ptr } { i32 65535, ptr @test4, ptr null },
   { i32, ptr, ptr } { i32 65535, ptr @test5, ptr null },
   { i32, ptr, ptr } { i32 65535, ptr @test6, ptr null }]
