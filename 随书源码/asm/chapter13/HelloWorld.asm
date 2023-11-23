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
szOut     db  'Value is:%d',0
szBuffer  db  256 dup(0)
szDataBuffer db 256 dup(0)


szLINI         db '.\_tmp.ini',0
szFailRead     db 'youarefail',0

szSectionName  db  'DPatchPEInfo.exe',0  ;针对不同的程序修改此处的值
szKeyName1    db  'majorImageVersion',0
szKeyName2    db  'minorImageVersion',0
szKeyName3    db  'downloadfile',0

;代码段
    .code
start:

    invoke GetPrivateProfileString,addr szSectionName,\
                                   addr szKeyName3,\
                                   addr szFailRead,\
                                   addr szDataBuffer,\
                                   sizeof szDataBuffer,\
                                   addr szLINI  ;取文件名

    invoke MessageBox,NULL,offset szDataBuffer,NULL,MB_OK

    invoke GetPrivateProfileInt,addr szSectionName,\
                                   addr szKeyName1,\
                                   0,\
                                   addr szLINI  ;取文件名
    invoke wsprintf,addr szBuffer,addr szOut,eax
    invoke MessageBox,NULL,offset szBuffer,NULL,MB_OK


    invoke ExitProcess,NULL
    end start
