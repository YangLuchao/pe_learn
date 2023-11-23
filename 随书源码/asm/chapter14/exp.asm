;------------------------
; 我的第一个基于WIN32的汇编程序
; 戚利
; 2006.2.28
;------------------------
    .386
    .model flat,stdcall
    option casemap:none

include    windows.inc
include    user32.inc
includelib user32.lib
include    kernel32.inc
includelib kernel32.lib

;数据段
    .data
szText     db  'HelloWorld',0
;代码段
    .code
_exp1  proc _lpsz
      pushad
      mov eax,_lpsz
      popad
      ret
_exp1  endp

start:

_b1:  mov eax,0
      invoke _exp1,addr szText
      jmp _b2
      mov ebx,0
_b2:  jmp _b1

      invoke MessageBox,NULL,offset szText,NULL,MB_OK
      invoke ExitProcess,NULL
    end start


