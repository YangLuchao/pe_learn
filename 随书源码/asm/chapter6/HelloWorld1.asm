;------------------------
; 无导入表、无数据段、无重定位信息的HelloWorld
; 戚利
; 2010.6.27
;------------------------
    .386
    .model flat,stdcall
    option casemap:none

include    windows.inc

;声明函数，过程类型，两个参数
_QLGetProcAddress typedef proto :dword,:dword   
;声明函数引用（指针）， _QLGetProcAddress类型，_ApiGetProcAddress名称
_ApiGetProcAddress  typedef ptr _QLGetProcAddress  
;声明函数，过程类型，一个参数
_QLLoadLib        typedef proto :dword
;声明函数引用（指针），_QLLoadLib类型，_ApiLoadLib指针名称
_ApiLoadLib       typedef ptr _QLLoadLib
;声明函数，过程类型，一个四个函数
_QLMessageBoxA    typedef proto :dword,:dword,:dword,:dword
;声明函数引用(指针)，_QLMessageBoxA类型，_ApiMessageBoxA名称
_ApiMessageBoxA   typedef ptr _QLMessageBoxA


;代码段
    .code

szText         db  'HelloWorldPE',0
szGetProcAddr  db  'GetProcAddress',0
szLoadLib      db  'LoadLibraryA',0
szMessageBox   db  'MessageBoxA',0

user32_DLL     db  'user32.dll',0,0

;定义函数
;定义获取函数地址函数指针
_getProcAddress _ApiGetProcAddress  ?     
;定义加载动态链接库函数指针        
_loadLibrary    _ApiLoadLib         ?
;定义messageBox函数指针
_messageBox     _ApiMessageBoxA     ?

;kernel32.dll动态链接库基址
hKernel32Base   dd  ?
;user32.dll动态链接库基址
hUser32Base     dd  ?
;获取函数地址函数地址
lpGetProcAddr   dd  ?
;加载动态链接库函数地址
lpLoadLib       dd  ?


;------------------------------------
; 根据kernel32.dll中的一个地址获取它的基地址
; _dwKernelRetAddress:当前函数的堆栈栈顶值
;------------------------------------
_getKernelBase  proc _dwKernelRetAddress
   local @dwRet

   pushad

   mov @dwRet,0
   
   mov edi,_dwKernelRetAddress
   and edi,0ffff0000h  ;查找指令所在页的边界，以1000h对齐

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
; 这个函数很重要，通过函数名查找到函数地址
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
    ;----------------------------免去重定位表
    ;取当前函数的堆栈栈顶值
    mov eax,dword ptr [esp]
    push eax
    call @F   ; 免去重定位
@@:
    pop ebx
    sub ebx,offset @B;重定位修正值挪到ebx中
    ;----------------------------免去重定位表

    pop eax
    ;获取kernel32.dll的基地址
    invoke _getKernelBase,eax;返回值EAX存储kernel32基址
    ;修正hKernel32Base全局变量地址，将计算出的kernel32基址挪到全局变量中
    mov [ebx + offset hKernel32Base],eax

    ;从基地址出发搜索GetProcAddress函数的首址
    mov eax,offset szGetProcAddr
    add eax,ebx;修正全局变量

    mov edi,offset hKernel32Base
    mov ecx,[ebx+edi];所有的函数地址,动态链接库地址，全局变量地址，都加上地址差


    invoke _getApi,ecx,eax;ecx存储kernel32基址，eax存储目标函数名偏移地址
    mov [ebx+offset lpGetProcAddr],eax;获得GetProcAddres函数的地址，挪到全局变量中

    ;为函数引用赋值 GetProcAddress
    mov [ebx+offset _getProcAddress],eax   ;同时将GetProcAddres函数地址挪到定义的函数中

    ;使用GetProcAddress函数的首址
    ;传入两个参数调用GetProcAddress函数，获得LoadLibraryA的首址
    mov eax,offset szLoadLib;LoadLibraryA函数挪到eax中作为参数
    add eax,ebx;修正
   
    mov edi,offset hKernel32Base;kernel32.dll基址挪到edi中，作为参数
    mov ecx,[ebx+edi];修正
    
    mov edx,offset _getProcAddress;GetProcAddress函数地址挪到edx中，准备调用
    add edx,ebx
    
    ;模仿调用 invoke GetProcAddress,hKernel32Base,addr szLoadLib
    ;std调用约定，参数从右到左传递
    push eax
    push ecx
    call dword ptr [edx]   ;执行调用

    mov [ebx+offset _loadLibrary],eax;获得LoadLibraryA函数的地址，存储到全局变量中

    ;使用LoadLibrary获取user32.dll的基地址
    mov eax,offset user32_DLL
    add eax,ebx;修正

    mov edi,offset _loadLibrary;LoadLibraryA函数地址
    mov edx,[ebx+edi];修正
    
    push eax   ; 传参
    call edx   ; invoke LoadLibraryA,addr _loadLibrary

    mov [ebx+offset hUser32Base],eax;user32.dll基址挪到全局变量中

    ;使用GetProcAddress函数的首址，获得函数MessageBoxA的首址
    mov eax,offset szMessageBox
    add eax,ebx;修正
   
    mov edi,offset hUser32Base;user32.dll基址
    mov ecx,[ebx+edi];修正
    
    mov edx,offset _getProcAddress;GetProcAddress函数地址
    add edx,ebx;修正


    ;模仿调用 invoke GetProcAddress,hUser32Base,addr szMessageBox
    push eax
    push ecx
    call dword ptr [edx]   
    mov [ebx+offset _messageBox],eax;MessageBoxA函数地址挪到全局变量中

    ;调用函数MessageBoxA
    mov eax,offset szText
    add eax,ebx

    mov edx,offset _messageBox
    add edx,ebx

    ;模仿调用 invoke MessageBoxA,NULL,addr szText,NULL,MB_OK    
    push 0;#define MB_OK 0x00000000L
    push NULL
    push eax
    push NULL
    call dword ptr [edx]   

    ret
    end start
