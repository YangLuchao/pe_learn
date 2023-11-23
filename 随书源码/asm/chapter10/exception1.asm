;------------------------
; 测试异常处理
; 戚利
; 2011.1.19
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
szText     db  'HelloWorldPE',0
szErr      db  'SEH Error',0
;代码段
    .code
start:
    xor eax,eax
    mov dword ptr [eax],eax;访问0地址，抛出系统异常
    invoke MessageBox,NULL,addr szText,NULL,MB_OK
    invoke ExitProcess,NULL
    end start
