;------------------------
; 获取kernel32.dll的基址
; 从PEB结构中搜索kernel32.dll的基地址
; 戚利
; 2010.6.27
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

szText  db 'kernel32.dll的基地址为%08x',0
szOut   db '%08x',0dh,0ah,0
szBuffer db 256 dup(0)

;代码段
    .code

start:

   assume fs:nothing
   mov eax,fs:[30h]  ;获取PEB所在地址
   mov eax,[eax+0ch] ;获取PEB_LDR_DATA 结构指针
   mov esi,[eax+1ch] ;获取InInitializationOrderModuleList 链表头
                     ;第一个LDR_MODULE节点InInitializationOrderModuleList成员的指针
   lodsd             ;获取双向链表当前节点后继的指针
   mov eax,[eax+8]   ;获取kernel32.dll的基地址

   ;输出模块基地址
   invoke wsprintf,addr szBuffer,addr szText,eax
   invoke MessageBox,NULL,addr szBuffer,NULL,MB_OK
   ret
   end start
