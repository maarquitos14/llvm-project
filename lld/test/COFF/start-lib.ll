; REQUIRES: x86

; RUN: rm -rf %t.dir
; RUN: split-file %s %t.dir

; RUN: llc -filetype=obj %t.dir/main.ll -o %t.obj
; RUN: llc -filetype=obj %t.dir/start-lib1.ll -o %t1.obj
; RUN: llc -filetype=obj %t.dir/start-lib2.ll -o %t2.obj
; RUN: opt -thinlto-bc %t.dir/main.ll -o %t.bc
; RUN: opt -thinlto-bc %t.dir/start-lib1.ll -o %t1.bc
; RUN: opt -thinlto-bc %t.dir/start-lib2.ll -o %t2.bc
;
; RUN: lld-link -out:%t1.exe -entry:main -opt:noref -lldmap:%t1.map \
; RUN:     %t.obj %t1.obj %t2.obj
; RUN: FileCheck --check-prefix=TEST1 %s < %t1.map
; RUN: lld-link -out:%t1.exe -entry:main -opt:noref -lldmap:%t1.thinlto.map \
; RUN:     %t.bc %t1.bc %t2.bc
; RUN: FileCheck --check-prefix=TEST1 %s < %t1.thinlto.map
; TEST1: foo
; TEST1: bar
;
; RUN: lld-link -out:%t2.exe -entry:main -opt:noref -lldmap:%t2.map \
; RUN:     %t.obj -start-lib %t1.obj -end-lib %t2.obj
; RUN: FileCheck --check-prefix=TEST2 %s < %t2.map
; RUN: lld-link -out:%t2.exe -entry:main -opt:noref -lldmap:%t2.thinlto.map \
; RUN:     %t.bc -start-lib %t1.bc -end-lib %t2.bc
; RUN: FileCheck --check-prefix=TEST2 %s < %t2.thinlto.map
; TEST2:     Address Size Align Out In Symbol
; TEST2-NOT:                           {{ }}foo{{$}}
; TEST2:                               {{ }}bar{{$}}
; TEST2-NOT:                           {{ }}foo{{$}}
;
; RUN: lld-link -out:%t3.exe -entry:main -opt:noref -lldmap:%t3.map \
; RUN:     %t.obj -start-lib %t1.obj %t2.obj
; RUN: FileCheck --check-prefix=TEST3 %s < %t3.map
; RUN: lld-link -out:%t3.exe -entry:main -opt:noref -lldmap:%t3.thinlto.map \
; RUN:     %t.bc -start-lib %t1.bc %t2.bc
; RUN: FileCheck --check-prefix=TEST3 %s < %t3.thinlto.map
; TEST3:     Address Size Align Out In Symbol
; TEST3-NOT: {{ }}foo{{$}}
; TEST3-NOT: {{ }}bar{{$}}


#--- main.ll

target datalayout = "e-m:w-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"

define void @main() {
  ret void
}


#--- start-lib1.ll

target datalayout = "e-m:w-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"

declare i32 @bar()

define i32 @foo() {
  %1 = call i32 () @bar()
  %2 = add i32 %1, 1
  ret i32 %2
}

!llvm.linker.options = !{!0}
!0 = !{!"/INCLUDE:foo"}


#--- start-lib2.ll

target datalayout = "e-m:w-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"

define i32 @bar() {
  ret i32 1
}

!llvm.linker.options = !{!0}
!0 = !{!"/INCLUDE:bar"}
