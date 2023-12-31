;------------------------
; EXE加密用的补丁程序
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

_QLGetProcessID   typedef proto :dword
_ApiGetProcessID  typedef ptr _QLGetProcessID

_QLOpenProcess   typedef proto :dword,:dword,:dword
_ApiOpenProcess  typedef ptr _QLOpenProcess

_QLWriteProcessMemory   typedef proto :dword,:dword,:dword,:dword,:dword
_ApiWriteProcessMemory  typedef ptr _QLWriteProcessMemory

_QLVirtualProtectEx   typedef proto :dword,:dword,:dword,:dword,:dword
_ApiVirtualProtectEx  typedef ptr _QLVirtualProtectEx


;代码段
    .code

jmp start

;保存目标程序的相关信息：
dstDataDirectory dd 32 dup(0)   ; 原始目标程序的数据目录表+0005h
EncryptionTable db 256 dup(0),0 ; 加密基表 +0085h
dwLastSectionSize    dd  ?      ; 最后一节对齐后的尺寸（以字节计）
dwModuleBase   dd  ?
dwIATValue     dd  ?
dbEncrptValue  db  ?
dwSections     dd  ?

szText         db  'HelloWorldPE',0
szGetProcAddr  db  'GetProcAddress',0
szLoadLib      db  'LoadLibraryA',0
szMessageBox   db  'MessageBoxA',0
szGetProcessID db  'GetProcessId',0
szOpenProcess  db  'OpenProcess',0
szVirtualProtectEx    db  'VirtualProtectEx',0
szWriteProcessMemory  db  'WriteProcessMemory',0

user32_DLL     db  'user32.dll',0,0

dwImageBase    dd  ?  ;目标进程基地址
hProcessID     dd  ?
hProcess       dd  ?
hOldPageValue  dd  ?

;-------------------------------
; 解密算法，可逆算法，字节数不变
; 入口参数：
;   _src:要解密的字节码起始地址
;   _size:要加密的字节码的数量
;-------------------------------
_UnEncrptIt  proc _src,_size,_writeProcessMemory
  local @ret
  local @dwTemp

  pushad
  ;开始按照基表对字节进行加密
  mov esi,_src
  .while TRUE
    mov al,byte ptr [esi]
    mov edi,offset EncryptionTable
    add edi,ebx
    mov @dwTemp,0
    .while TRUE  ;查找基表，索引在@dwTemp中
      mov cl,byte ptr [edi]
      .break .if al==cl ;如果找到，则退出
      inc @dwTemp
      inc edi
    .endw
    
    ;用解密后的字节更新字节码
    mov ecx,@dwTemp
    mov byte ptr dbEncrptValue[ebx],cl

    ;使用远程写入
    push NULL
    push 1
    mov edx,offset dbEncrptValue
    add edx,ebx
    push edx
    push esi   ;??
    push hProcess[ebx]
    call _writeProcessMemory 

    inc esi
    dec _size
    .break .if _size==0
  .endw
  popad
  ret
_UnEncrptIt endp

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


;------------------------------------
; 根据kernel32.dll中的一个地址获取它的基地址
;------------------------------------
_getImageBase  proc _dwKernelRetAddress
   local @dwRet
   local @dwTemp
   pushad

   mov @dwRet,0
   
   mov edi,_dwKernelRetAddress
   and edi,0ffff0000h  ;查找指令所在页的边界，以1000h对齐
   mov eax,edi
   and eax,0ff000000h
   mov @dwTemp,eax
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
     .break .if edi<@dwTemp
   .until FALSE
   popad
   mov eax,@dwRet
   ret
_getImageBase  endp   

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
;---------------------
; 将内存偏移量RVA转换为文件偏移
; lp_FileHead为文件头的起始地址
; _dwRVA为给定的RVA地址
;---------------------
_RVAToOffset proc _lpFileHead,_dwRVA
  local @dwReturn
  
  pushad
  mov esi,_lpFileHead
  assume esi:ptr IMAGE_DOS_HEADER
  add esi,[esi].e_lfanew
  assume esi:ptr IMAGE_NT_HEADERS
  mov edi,_dwRVA
  mov edx,esi
  add edx,sizeof IMAGE_NT_HEADERS
  assume edx:ptr IMAGE_SECTION_HEADER
  movzx ecx,[esi].FileHeader.NumberOfSections
  ;遍历节表
  .repeat
    mov eax,[edx].VirtualAddress
    add eax,[edx].SizeOfRawData        ;计算该节结束RVA，不用Misc的主要原因是有些段的Misc值是错误的！
    .if (edi>=[edx].VirtualAddress)&&(edi<eax)
      mov eax,[edx].VirtualAddress
      sub edi,eax                ;计算RVA在节中的偏移
      mov eax,[edx].PointerToRawData
      add eax,edi                ;加上节在文件中的的起始位置
      jmp @F
    .endif
    add edx,sizeof IMAGE_SECTION_HEADER
  .untilcxz
  assume edx:nothing
  assume esi:nothing
  mov eax,-1
@@:
  mov @dwReturn,eax
  popad
  mov eax,@dwReturn
  ret
_RVAToOffset endp


;------------------
; 修正IAT表
; 传入全局变量参数
;   dwModuleBase  模块的地址
;   dwImageBase   进程基地址
;------------------
_updateIAT  proc _lpIID,_writeProcessMemory
   local @dwCount

   pushad
   mov @dwCount,0

   mov edi,_lpIID
   assume edi:ptr IMAGE_IMPORT_DESCRIPTOR

   ;获取函数名字字符串
   mov esi,[edi].OriginalFirstThunk
   add esi,dwImageBase[ebx]
   .while TRUE
     mov eax,[esi]
     .break .if !eax
     add eax,dwImageBase[ebx]
     add eax,2  ;跳过hint/name中的hint

     ;此时eax指向了函数字符串
     lea edx,_getApi   ;获取函数地址
     add edx,ebx
     push eax
     push dwModuleBase[ebx]
     call edx
     ;add eax,dwImageBase[ebx]  ;获取函数VA值

     ;将函数地址覆盖IAT对应位置
     push esi
     push eax
     mov esi,[edi].FirstThunk
     add esi,dwImageBase[ebx]  ;ESI指向IAT表开始

     mov eax,@dwCount  ;求索引对应偏移
     sal eax,2
     add esi,eax
     pop eax


     mov dwIATValue[ebx],eax

     ;使用远程写入
     push NULL
     push 4
     mov edx,offset dwIATValue
     add edx,ebx
     push edx
     push esi   ;??
     push hProcess[ebx]
     call _writeProcessMemory 

     ;mov dword ptr [esi],eax   ;将函数VA值写入IAT
     pop esi

     inc @dwCount
     add esi,4
   .endw

   popad
   ret
_updateIAT endp



_goThere  proc
   local @first
   local _getProcAddress:_ApiGetProcAddress   ;定义函数
   local _loadLibrary:_ApiLoadLib
   local _messageBox:_ApiMessageBoxA
   local _getProcessID:_ApiGetProcessID
   local _openProcess:_ApiOpenProcess
   local _writeProcessMemory:_ApiWriteProcessMemory
   local _virtualProtectEx:_ApiVirtualProtectEx

   local hKernel32Base:dword
   local hUser32Base:dword
   local lpGetProcAddr:dword
   local lpLoadLib:dword

   local lpGetProcessID:dword
   local lpOpenProcess:dword
   local lpWriteProcessMemory:dword
   local lpVirtualProtectEx:dword


   pushad

    ;获取kernel32.dll的基地址
    invoke _getKernelBase,eax

    mov hKernel32Base,eax

    ;从基地址出发搜索GetProcAddress函数的首址
    mov eax,offset szGetProcAddr
    add eax,ebx

    mov edi,hKernel32Base
    mov ecx,edi

    invoke _getApi,ecx,eax
    mov lpGetProcAddr,eax
    ;为函数引用赋值 GetProcAddress
    mov _getProcAddress,eax   

    ;使用GetProcAddress函数的首址，
    ;传入两个参数调用GetProcAddress函数，
    ;获得LoadLibraryA的首址
    mov eax,offset szLoadLib
    add eax,ebx
    invoke _getProcAddress,hKernel32Base,eax
    mov _loadLibrary,eax

    ;使用LoadLibrary获取user32.dll的基地址
    mov eax,offset user32_DLL
    add eax,ebx
    invoke _loadLibrary,eax

    mov hUser32Base,eax

    ;使用GetProcAddress函数的首址，
    ;获得函数MessageBoxA的首址
    mov eax,offset szMessageBox
    add eax,ebx
    invoke _getProcAddress,hUser32Base,eax
    mov _messageBox,eax


    mov eax,offset szGetProcessID
    add eax,ebx
    invoke _getProcAddress,hKernel32Base,eax
    mov _getProcessID,eax

    mov eax,offset szOpenProcess
    add eax,ebx
    invoke _getProcAddress,hKernel32Base,eax
    mov _openProcess,eax

    mov eax,offset szVirtualProtectEx
    add eax,ebx
    invoke _getProcAddress,hKernel32Base,eax
    mov _virtualProtectEx,eax

    mov eax,offset szWriteProcessMemory
    add eax,ebx
    invoke _getProcAddress,hKernel32Base,eax
    mov _writeProcessMemory,eax


    ;调用函数MessageBoxA
    mov eax,offset szText
    add eax,ebx
    invoke _messageBox,NULL,eax,NULL,MB_OK

    ;获取目标进程的基地址
    mov eax,offset dwImageBase
    add eax,ebx

    push eax
    lea edx,_getImageBase
    add edx,ebx
    call edx
    mov dwImageBase[ebx],eax


    ;还原目标进程的数据目录表
    mov esi,dwImageBase[ebx]
    add esi,[esi+3ch]
    add esi,78h
    push esi

    assume fs:nothing
    mov eax,fs:[20h]
    mov hProcessID[ebx],eax


    push hProcessID[ebx]
    push FALSE
    push PROCESS_ALL_ACCESS
    call _openProcess
    mov hProcess[ebx],eax  ;找到的进程句柄在hProcess中

    

    ;设置文件头部分为可读可写可执行
    lea edx,hOldPageValue
    add edx,ebx
    push edx
    push PAGE_EXECUTE_READWRITE
    ;获取SizeOfImage大小
    push esi
    mov esi,dwImageBase[ebx]
    add esi,[esi+3ch]
    assume esi:ptr IMAGE_NT_HEADERS
    mov edx,[esi].OptionalHeader.SizeOfImage
    pop esi
    push edx   ;设置页面大小
    push dwImageBase[ebx]
    push hProcess[ebx]
    call _virtualProtectEx  

    pop esi
    push NULL
    push 16*8
    mov edx,offset dstDataDirectory
    add edx,ebx
    push edx
    push esi
    push hProcess[ebx]
    call _writeProcessMemory 

    ;解密数据
    mov edi,dwImageBase[ebx]
    assume edi:ptr IMAGE_DOS_HEADER
    add edi,[edi].e_lfanew
    assume edi:ptr IMAGE_NT_HEADERS
    ;获取节的个数
    movzx eax,[edi].FileHeader.NumberOfSections
    mov dwSections[ebx],eax
    add edi,sizeof IMAGE_NT_HEADERS

    dec eax
    mov ecx,sizeof IMAGE_SECTION_HEADER   ;定位到最后一个节
    mul ecx
    add edi,eax   
    assume edi:ptr IMAGE_SECTION_HEADER

    mov @first,1

    .while TRUE
       mov esi,[edi].VirtualAddress
       add esi,dwImageBase[ebx]     ;要解密的起始地址

       .if @first  ;如果是最后一节，补丁工具更改了此处的大小，
                   ;必须使用由补丁工具传入的原始值
         mov ecx,dwLastSectionSize[ebx]
         mov @first,0
       .else       ;如果是其他节，则使用SizeOfRawData
         mov ecx,[edi].SizeOfRawData
       .endif

       push _writeProcessMemory
       push ecx
       push esi
       mov edx,offset _UnEncrptIt
       add edx,ebx
       call edx

       dec dwSections[ebx]
       sub edi,sizeof IMAGE_SECTION_HEADER
       .break .if dwSections[ebx]==0
    .endw


    ;遍历目标进程导入表
    mov edi,offset dstDataDirectory
    add edi,ebx
    add edi,8  ;定位到导入表项
    mov eax,dword ptr [edi] ;获取VirtualAddress

    ;未做判断，假设处理的PE文件均有导入表
    add eax,dwImageBase[ebx] ;所在内存偏移

    mov edi,eax     ;计算引入表所在文件偏移位置
    assume edi:ptr IMAGE_IMPORT_DESCRIPTOR
    .while [edi].Name1
       push edi
       mov eax,dword ptr [edi].Name1 ;取第一个动态链接库名字字符串所在的RVA值
       add eax,dwImageBase[ebx]      ;在内存定位只需加上基地址即可

       ;动态加载该dll
       invoke _loadLibrary,eax
       mov dwModuleBase[ebx],eax    

       ;修正从该链接库引入的函数IAT项
       lea edx,offset _updateIAT
       add edx,ebx
       push _writeProcessMemory
       push edi
       call edx
       pop edi
       add edi,sizeof IMAGE_IMPORT_DESCRIPTOR
    .endw
    popad
    ret
_goThere endp

start:
    ;取当前函数的堆栈栈顶值
    mov eax,dword ptr [esp]
    push eax
    call @F   ; 免去重定位
@@:
    pop ebx
    sub ebx,offset @B
    pop eax
    invoke _goThere
    jmpToStart   db 0E9h,0F0h,0FFh,0FFh,0FFh

    ret

    end start
