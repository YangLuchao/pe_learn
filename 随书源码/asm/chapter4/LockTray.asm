;------------------------
; 锁定任务栏
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
sz1     db  'Shell_TrayWnd',0
hTray  dd  ?

;代码段
    .code
start:
    invoke FindWindow,addr sz1,0
    mov hTray,eax
    invoke ShowWindow,hTray,SW_HIDE
    invoke EnableWindow,hTray,FALSE

    invoke ExitProcess,NULL
    end start
