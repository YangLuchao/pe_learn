;------------------------
; for Angry Angel 3.0 unzip File Header
; 戚利
; 2011.2.19
;------------------------
    .386
    .model flat,stdcall
    option casemap:none

include    windows.inc
include    user32.inc
includelib user32.lib
include    kernel32.inc
includelib kernel32.lib
include    comdlg32.inc
includelib comdlg32.lib


TOTAL_SIZE   equ  162h

;数据段
    .data
szFileSource   db   'c:\worm2.exe',0
szFileDest     db   'c:\worm2_bak.exe',0
dwTotalSize    dd   0
hFileSrc       dd   0
hFileDst       dd   0
dwTemp         dd   0
dwTemp1        dd   0
dwTemp2        dd   0
szCaption      db  'Got you',0
szText         db  'OK!？^_^',0
szBuffer       db   TOTAL_SIZE dup(0)
szBuffer1      db   0ffffh dup(0)

;代码段
    .code

start:

    ;打开文件worm2.exe
    invoke CreateFile,addr szFileSource,GENERIC_READ,\
           FILE_SHARE_READ,\
           0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
    mov hFileSrc,eax
    ;创建另外一个文件worm2_bak.exe
    invoke CreateFile,addr szFileDest,GENERIC_WRITE,\
           FILE_SHARE_READ,\
           0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
    mov hFileDst,eax

    ;解压缩头部
    invoke ReadFile,hFileSrc,addr szBuffer,\
           TOTAL_SIZE,addr dwTemp,0

    mov esi,offset szBuffer
    mov edi,offset szBuffer1
    mov ecx,TOTAL_SIZE
    mov dwTemp2,0
@@0:
    lodsb
    mov bl,al
    sub bl,0
    jz  @@1
    stosb
    inc dwTemp2
    dec ecx
    jecxz @F 
    jmp @@0
@@1:
    dec ecx
    jecxz @F
    lodsb
    push ecx
    xor ecx,ecx
    mov cl,al
    add dwTemp2,ecx
    mov al,0
    rep stosb
    pop ecx

    dec ecx
    jecxz  @F
    jmp @@0
@@:     
    invoke WriteFile,hFileDst,addr szBuffer1,\
                               dwTemp2,addr dwTemp1,NULL

    ;关闭文件
    invoke CloseHandle,hFileDst
    invoke CloseHandle,hFileSrc

    invoke MessageBox,NULL,offset szText,\
                                 offset szCaption,MB_OK
    invoke ExitProcess,NULL
    end start
