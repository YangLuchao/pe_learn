;------------------------
; 导出表导出私有函数测试
; 戚利
; 2010.6.28
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
szBuffer   db 200 dup(0)
szBuffer1  db 200 dup(0)
szOut      db  '(400:600) eax=%d',0


winResu   db  'winResult.dll',0
SLWA     db  'TopXY',0
pSLWA    dd  ?

;代码段
    .code

;-------------------------------
;  私有函数模拟
;-------------------------------
NTopXY proc wDim:DWORD,sDim:DWORD
     shr sDim,1 
     shr wDim,1
     mov eax,wDim
     sub sDim,eax
     mov eax,sDim
     ret
NTopXY endp
start:
    invoke NTopXY,400,600
    invoke wsprintf,addr szBuffer,addr szOut,eax
    invoke MessageBox,NULL,offset szBuffer,NULL,MB_OK

    invoke LoadLibrary,addr winResu
    invoke GetProcAddress,eax,ADDR SLWA
    mov pSLWA,eax

    push 600
    push 400 
    call pSLWA
    invoke wsprintf,addr szBuffer1,addr szOut,eax
    invoke MessageBox,NULL,offset szBuffer1,NULL,MB_OK

    invoke ExitProcess,NULL
    end start
