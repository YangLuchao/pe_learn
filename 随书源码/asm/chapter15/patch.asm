;------------------------
; 无导入表、无数据段、无重定位信息的HelloWorld
; 戚利
; 2010.6.27
;------------------------
    .386
    .model flat,stdcall
    option casemap:none

include    windows.inc


_QLGetProcAddress typedef proto :dword,:dword      ;声明函数
_ApiGetProcAddress  typedef ptr _QLGetProcAddress  ;声明函数引用

_QLLoadLib        typedef proto :dword
_ApiLoadLib       typedef ptr _QLLoadLib

_QLMessageBoxA    typedef proto :dword,:dword,:dword,:dword
_ApiMessageBoxA   typedef ptr _QLMessageBoxA

HookExceptionNo equ 5 
;代码段
    .code
jmp start

szText         db  'HelloWorldPE',0
szGetProcAddr  db  'GetProcAddress',0
szLoadLib      db  'LoadLibraryA',0
szMessageBox   db  'MessageBoxA',0

user32_DLL     db  'user32.dll',0,0

_getProcAddress _ApiGetProcAddress  ?              ;定义函数
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
    
    ;取当前函数的堆栈栈顶值
    mov eax,dword ptr [esp]
    push eax
    call @F   ; 免去重定位
@@:
    pop ebx
    sub ebx,offset @B

    pop eax
    ;获取kernel32.dll的基地址
    invoke _getKernelBase,eax

    ;invoke _Eax2Mem,[ebx+offset hKernel32Base],eax
    
    mov [ebx+offset hKernel32Base],eax

    ;从基地址出发搜索GetProcAddress函数的首址
    mov eax,offset szGetProcAddr
    add eax,ebx

    mov edi,offset hKernel32Base
    mov ecx,[ebx+edi]


    invoke _getApi,ecx,eax
    mov [ebx+offset lpGetProcAddr],eax
    mov [ebx+offset _getProcAddress],eax   ;为函数引用赋值 GetProcAddress

    ;使用GetProcAddress函数的首址，传入两个参数调用GetProcAddress函数，获得LoadLibraryA的首址
    mov eax,offset szLoadLib
    add eax,ebx
   
    mov edi,offset hKernel32Base
    mov ecx,[ebx+edi]
    
    mov edx,offset _getProcAddress
    add edx,ebx
    
    push eax
    push ecx
    call dword ptr [edx]   ; invoke GetProcAddress,hKernel32Base,addr szLoadLib

    mov [ebx+offset _loadLibrary],eax

    ;使用LoadLibrary获取user32.dll的基地址

    mov eax,offset user32_DLL
    add eax,ebx

    mov edi,offset _loadLibrary
    mov edx,[ebx+edi]
    
    push eax
    call edx   ; invoke LoadLibraryA,addr _loadLibrary

    mov [ebx+offset hUser32Base],eax

    ;使用GetProcAddress函数的首址，获得函数MessageBoxA的首址
    mov eax,offset szMessageBox
    add eax,ebx
   
    mov edi,offset hUser32Base
    mov ecx,[ebx+edi]
    
    mov edx,offset _getProcAddress
    add edx,ebx

    push eax
    push ecx
    call dword ptr [edx]   ; invoke GetProcAddress,hUser32Base,addr szMessageBox
    mov [ebx+offset _messageBox],eax

    ;调用函数MessageBoxA
    mov eax,offset szText
    add eax,ebx

    mov edx,offset _messageBox
    add edx,ebx
    
    push MB_OK
    push NULL
    push eax
    push NULL
    call dword ptr [edx]   ; invoke MessageBoxA,NULL,addr szText,NULL,MB_OK

    jmpToStart   db 0E9h,0F0h,0FFh,0FFh,0FFh

    ret

    end start
