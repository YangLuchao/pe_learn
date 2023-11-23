;------------------------
; 获取kernel32.dll的基址
; 从SEH框架空间中搜索kernel32.dll的基地址
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
   mov eax,fs:[0]
   inc eax   ; 如果eax=0FFFFFFFFh，则设置为0
loc1:  
   dec eax
   mov esi,eax ;ESI指向EXCEPTION_REGISTRATION
   mov eax,[eax]  ;eax=EXCEPTION_REGISTRATION.prev
   inc eax        ;如果eax=0FFFFFFFFh，则设置为0
   jne loc1
   lodsd          ;跳过0FFFFFFFFh
   lodsd          ;获取kernel32._except_handler地址
   xor ax,ax      ;按照10000h对齐，舍入
   jmp loc3

loc2:
   sub eax,10000h         
loc3:

   cmp dword ptr [eax],905A4Dh
   jne loc2

   ;输出模块基地址
   invoke wsprintf,addr szBuffer,addr szText,eax
   invoke MessageBox,NULL,addr szBuffer,NULL,MB_OK
   ret
   end start
