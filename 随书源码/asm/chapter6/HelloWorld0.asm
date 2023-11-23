;------------------------
; 无导入表的HelloWorld
; 戚利
; 2010.6.27
;------------------------
    .386
    .model flat,stdcall
    option casemap:none

include    windows.inc

;声明加载函数地址函数，过程类型，两个参数
_QLGetProcAddress typedef proto :dword,:dword   
;声明函数指针(引用)
_ApiGetProcAddress  typedef ptr _QLGetProcAddress  

;声明加载动态链接库函数，过程类型，一个参数
_QLLoadLib        typedef proto :dword
;声明函数的指针(引用)
_ApiLoadLib       typedef ptr _QLLoadLib

;声明messageBox函数，过程类型，4个参数
_QLMessageBoxA    typedef proto :dword,:dword,:dword,:dword
;声明函数指针(引用)
_ApiMessageBoxA   typedef ptr _QLMessageBoxA


;代码段
    .code

szText         db  'HelloWorldPE',0
szGetProcAddr  db  'GetProcAddress',0
szLoadLib      db  'LoadLibraryA',0
szMessageBox   db  'MessageBoxA',0

user32_DLL     db  'user32.dll',0,0

;定义函数
;变量 类型 未初始化
_getProcAddress _ApiGetProcAddress  ?              
_loadLibrary    _ApiLoadLib         ?
_messageBox     _ApiMessageBoxA     ?


hKernel32Base   dd  ?
hUser32Base     dd  ?
lpGetProcAddr   dd  ?
lpLoadLib       dd  ?

;------------------------------------
; 根据kernel32.dll中的一个地址获取它的基地址
;------------------------------------
_getKernelBase  proc _dwKernelRetAddress
   local @dwRet

   pushad
   mov @dwRet,0
   
   mov edi,_dwKernelRetAddress

   ;查找指令所在页的边界，以1000h对齐
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
   mov edi,_lpApi;字符串起始地址挪到EDI中
   mov ecx,-1
   xor al,al;清空al，准备结束标识
   cld;设置方向
   repnz scasb;计算字符串长度
   mov ecx,edi
   sub ecx,_lpApi;结束地址-起始地址，得到字符串长度
   mov @dwLen,ecx;字符串长度挪到局部变量中

   ;从pe文件头的数据目录获取导出表地址
   mov esi,_hModule
   add esi,[esi+3ch]
   assume esi:ptr IMAGE_NT_HEADERS
   mov esi,[esi].OptionalHeader.DataDirectory.VirtualAddress
   add esi,_hModule
   assume esi:ptr IMAGE_EXPORT_DIRECTORY

   ;查找符合名称的导出函数名
   mov ebx,[esi].AddressOfNames;导出函数表RVA
   add ebx,_hModule;修正
   xor edx,edx;清空EDX，做循环计数
   .repeat
     push esi
     mov edi,[ebx];拿到函数名首地址
     add edi,_hModule;修正
     mov esi,_lpApi;目标函数名起始地址
     mov ecx,@dwLen;比较计数
     repz cmpsb;比较
     .if ZERO?
       pop esi
       jmp @F;找到了，跳到下一个@@
     .endif
     pop esi
     add ebx,4;没有找到，ebx+4，找下一个函数名的RVA
     inc edx;循环计数器+1
   .until edx>=[esi].NumberOfNames
   jmp _ret;还是没有找到，跳到跳出方法处
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
    ;传入两个参数调用GetProcAddress函数，获得LoadLibraryA的首址
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
