;------------------------
; 简单DLL动态链接库
; 戚利
; 2011.1.22
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
szText   db  'DLL Hello',0
;代码段
    .code
;------------------
; DLL入口
;------------------
DllEntry   proc  _hInstance,_dwReason,_dwReserved

        mov eax,TRUE
        ret
DllEntry   endp

;-----------------------------------------------------------
; 输出
;-----------------------------------------------------------
sayHello proc
    pushad
    invoke MessageBox,NULL,addr szText,NULL,MB_OK
    popad
    ret 
sayHello endp

      End DllEntry







