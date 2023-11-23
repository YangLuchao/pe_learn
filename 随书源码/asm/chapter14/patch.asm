;------------------------
; 补丁程序
; author：戚利
; date：2010.6.3
;------------------------
    .386
    .model flat,stdcall
    option casemap:none

include    windows.inc
include    advapi32.inc
includelib advapi32.lib

;数据段
    .data
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

    jmpToStart   db 0E9h,0F0h,0FFh,0FFh,0FFh
    ret
    end start
