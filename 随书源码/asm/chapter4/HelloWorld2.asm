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
include    advapi32.inc
includelib advapi32.lib

;数据段
    .data
szText     db  'HelloWorld',0
sz1        db  'SOFTWARE\MICROSOFT\WINDOWS\CURRENTVERSION\RUN',0
sz2        db  'NewValue',0
sz3        db  'd:\masm32\source\chapter5\LockTray.exe',0
@hKey      dd  ?

;代码段
    .code
start:
    invoke RegCreateKey,HKEY_LOCAL_MACHINE,addr sz1,addr @hKey
    invoke RegSetValueEx,@hKey,addr sz2,NULL,\
                 REG_SZ,addr sz3,27h
    invoke RegCloseKey,@hKey

    invoke MessageBox,NULL,offset szText,NULL,MB_OK
    invoke ExitProcess,NULL
    end start
