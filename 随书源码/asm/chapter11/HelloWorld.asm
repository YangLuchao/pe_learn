;------------------------
; 无导入表的HelloWorld
; 戚利
; 2010.6.27
;------------------------
    .386
    .model flat,stdcall
    option casemap:none

include    windows.inc


;声明函数
_QLGetProcAddress typedef proto :dword,:dword  
;声明函数引用    
_ApiGetProcAddress  typedef ptr _QLGetProcAddress

_QLLoadLib        typedef proto :dword
_ApiLoadLib       typedef ptr _QLLoadLib

_QLMessageBoxA    typedef proto :dword,:dword,:dword,:dword
_ApiMessageBoxA   typedef ptr _QLMessageBoxA

;数据段
    .data

szText         db  'HelloWorldPE',0
szGetProcAddr  db  'GetProcAddress',0
szLoadLib      db  'LoadLibraryA',0
szMessageBox   db  'MessageBoxA',0

user32_DLL     db  'user32.dll',0,0

;定义函数
_getProcAddress _ApiGetProcAddress  ?             
_loadLibrary    _ApiLoadLib         ?
_messageBox     _ApiMessageBoxA     ?


hKernel32Base   dd  ?
hUser32Base     dd  ?
lpGetProcAddr   dd  ?
lpLoadLib       dd  ?


;代码段
    .code
;------------------------------------
; 根据kernel32.dll中的一个地址获取它的基地址
;------------------------------------
_getKernelBase  proc _dwKernelRetAddress
   local @dwRet

   pushad
   mov @dwRet,0

   ;查找指令所在页的边界，以1000h对齐   
   mov edi,_dwKernelRetAddress
   and edi,0ffff0000h  

   .repeat

     ;找到kernel32.dll的dos头
     .if word ptr [edi]==IMAGE_DOS_SIGNATURE  
        mov esi,edi
        add esi,[esi+003ch]

        ;找到kernel32.dll的PE头标识
        .if word ptr [esi]==IMAGE_NT_SIGNATURE 
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
; 入口参数：_hModule为动态链接库的基址
;           _lpApi为API函数名的首址
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
    ;取当前函数的堆栈栈顶值
    mov eax,dword ptr [esp]
    ;获取kernel32.dll的基地址
    invoke _getKernelBase,eax
    mov hKernel32Base,eax

    ;从基地址出发搜索GetProcAddress函数的首址
    invoke _getApi,hKernel32Base,addr szGetProcAddr
    mov lpGetProcAddr,eax
    mov _getProcAddress,eax   ;为函数引用赋值 GetProcAddress

    ;使用GetProcAddress函数的首址
    ;传入两个参数调用GetProcAddress函数
    ;获得LoadLibraryA的首址

    invoke _getProcAddress,hKernel32Base,addr szLoadLib
    mov _loadLibrary,eax

    ;使用LoadLibrary获取user32.dll的基地址
    invoke _loadLibrary,addr user32_DLL
    mov hUser32Base,eax

    ;使用GetProcAddress函数的首址，获得函数MessageBoxA的首址
    invoke _getProcAddress,hUser32Base,addr szMessageBox
    mov _messageBox,eax   ;调用函数MessageBoxA
    invoke _messageBox,NULL,offset szText,NULL,MB_OK

    ret
    end start
