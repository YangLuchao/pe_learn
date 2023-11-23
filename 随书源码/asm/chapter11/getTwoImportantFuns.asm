;------------------------
; 获取kernel32.dll的基址
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

_QLGetProcAddress typedef proto :dword,:dword      ;声明函数
_ApiGetProcAddress  typedef ptr _QLGetProcAddress  ;声明函数引用

;数据段
    .data
szText         db  'kernel32.dll在本程序地址空间的基地址为：%08x',0dh,0ah,0
szText1        db  'GetProcAddress代码在本程序地址空间的首址为：%08x',0dh,0ah,0
szText2        db  'LoadLibraryA代码在本程序地址空间的首址为：%08x',0dh,0ah,0

szGetProcAddr  db  'GetProcAddress',0
szLoadLib      db  'LoadLibraryA',0

_getProcAddress _ApiGetProcAddress  ?              ;定义函数

kernel32Base   dd  ?    ;kernel32.dl基址
lpGetProcAddr  dd  ?    ;getProcessAdd地址
lpLoadLib      dd  ?    ;loadLib地址

szBuffer       db 256 dup(0)

;代码段
    .code
;------------------------------------
; 根据kernel32.dll中的一个地址获取它的基地址
;------------------------------------
_getKernelBase  proc _dwKernelRetAddress
   local @dwRet

   pushad
   mov @dwRet,0
   
   mov edi,_dwKernelRetAddress
   and edi,0ffff0000h  ;查找指令所在页的边界，以1000h对齐

   .repeat
     .if word ptr [edi]==IMAGE_DOS_SIGNATURE  ;找到kernel32.dll的dos头
        mov esi,edi
        add esi,[esi+003ch]
        .if word ptr [esi]==IMAGE_NT_SIGNATURE ;找到kernel32.dll的PE头标识
          mov @dwRet,edi
          .break
        .endif
     .endif
     sub edi,010000h
     .break .if edi<070000000h
   .until FALSE
   popad
   mov eax,@dwRet
   ret
_getKernelBase  endp   

;-------------------------------
; 获取指定字符串的API函数的调用地址
; 入口参数：_hModule为动态链接库的基址，_lpApi为API函数名的首址
; 出口参数：eax为函数在虚拟地址空间中的真实地址
;-------------------------------
_getApi proc _hModule,_lpApi
   local @ret
   local @dwLen

   pushad
   mov @ret,0
   ;计算API字符串的长度，含最后的零
   mov edi,_lpApi
   mov ecx,-1
   xor al,al
   cld
   repnz scasb
   mov ecx,edi
   sub ecx,_lpApi
   mov @dwLen,ecx

   ;从pe文件头的数据目录获取导出表地址
   mov esi,_hModule
   add esi,[esi+3ch]
   assume esi:ptr IMAGE_NT_HEADERS
   mov esi,[esi].OptionalHeader.DataDirectory.VirtualAddress
   add esi,_hModule
   assume esi:ptr IMAGE_EXPORT_DIRECTORY

   ;查找符合名称的导出函数名
   mov ebx,[esi].AddressOfNames
   add ebx,_hModule
   xor edx,edx
   .repeat
     push esi
     mov edi,[ebx]
     add edi,_hModule
     mov esi,_lpApi
     mov ecx,@dwLen
     repz cmpsb
     .if ZERO?
       pop esi
       jmp @F
     .endif
     pop esi
     add ebx,4
     inc edx
   .until edx>=[esi].NumberOfNames
   jmp _ret
@@:
   ;通过API名称索引获取序号索引再获取地址索引
   sub ebx,[esi].AddressOfNames
   sub ebx,_hModule
   shr ebx,1
   add ebx,[esi].AddressOfNameOrdinals
   add ebx,_hModule
   movzx eax,word ptr [ebx]
   shl eax,2
   add eax,[esi].AddressOfFunctions
   add eax,_hModule
   
   ;从地址表得到导出函数的地址
   mov eax,[eax]
   add eax,_hModule
   mov @ret,eax

_ret:
   assume esi:nothing
   popad
   mov eax,@ret
   ret
_getApi endp

start:
    mov eax,dword ptr [esp]
    invoke _getKernelBase,eax;获取kernel32.dll地址
    mov kernel32Base,eax;存在全局变量中
    invoke wsprintf,addr szBuffer,addr szText,eax
    invoke MessageBox,NULL,addr szBuffer,NULL,MB_OK;输出

    invoke _getApi,kernel32Base,addr szGetProcAddr;获取getPorcessAddr函数地址
    mov lpGetProcAddr,eax       ;getPorcessAddr函数地址存入全局变量中
    mov _getProcAddress,eax     ;为函数引用赋值 GetProcAddress
    invoke wsprintf,addr szBuffer,addr szText1,eax
    invoke MessageBox,NULL,addr szBuffer,NULL,MB_OK;输出函数地址


    invoke _getProcAddress,kernel32Base,addr szLoadLib;获取loadLib函数地址
    mov lpLoadLib,eax
    invoke wsprintf,addr szBuffer,addr szText2,eax
    invoke MessageBox,NULL,addr szBuffer,NULL,MB_OK ;输出函数地址

    ret
    end start
