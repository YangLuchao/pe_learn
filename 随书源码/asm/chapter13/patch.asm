;-------------------------
; 补丁代码
; 本段代码使用了API函数地址动态获取以及重定位技术
; 程序功能：弹出对话框
; 作者：戚利
; 开发日期：2011.2.22
;-------------------------

    .386
    .model flat,stdcall
    option casemap:none

include    windows.inc

;注意此处不静态包含引入任何其他动态链接库

_ProtoGetProcAddress  typedef proto :dword,:dword
_ProtoLoadLibrary     typedef proto :dword

_ApiGetProcAddress    typedef ptr _ProtoGetProcAddress
_ApiLoadLibrary       typedef ptr _ProtoLoadLibrary


;-------------------------------------------
; 补丁代码中引入的其他动态链接库的函数的声明
;-------------------------------------------


_ProtoMessageBox       typedef proto :dword,:dword,:dword,:dword
_ApiMessageBox         typedef ptr _ProtoMessageBox


;被添加到目标文件的代码从这里开始，到APPEND_CODE_END处结束

    .code

jmp _NewEntry

; 以下内容为两个重要函数名
; 几乎所有补丁都必须使用的
szGetProcAddr  db  'GetProcAddress',0
szLoadLib      db  'LoadLibraryA',0

;------------------------------------------------------
; 补丁代码中其他全局变量的定义
;------------------------------------------------------

szUser32Dll    db  'user32.dll',0
szMessageBox   db  'MessageBoxA',0   ;该方法在kernel32.dll中
szHello        db  'HelloWorldPE',0  ;要创建的目录


;-----------------------------
; 错误 Handler
;-----------------------------
_SEHHandler proc _lpException,_lpSEH,_lpContext,_lpDispatcher
  pushad
  mov esi,_lpException
  mov edi,_lpContext
  assume esi:ptr EXCEPTION_RECORD,edi:ptr CONTEXT
  mov eax,_lpSEH
  push [eax+0ch]
  pop [edi].regEbp
  push [eax+8]
  pop [edi].regEip
  push eax
  pop [edi].regEsp
  assume esi:nothing,edi:nothing
  popad
  mov eax,ExceptionContinueExecution
  ret
_SEHHandler endp

;------------------------------------
; 获取kernel32.dll的基地址
;------------------------------------
_getKernelBase  proc
   local @dwRet

   pushad

   assume fs:nothing
   mov eax,fs:[30h] ;获取PEB所在地址
   mov eax,[eax+0ch] ;获取PEB_LDR_DATA 结构指针
   mov esi,[eax+1ch] ;获取InInitializationOrderModuleList 链表头
   ;第一个LDR_MODULE节点InInitializationOrderModuleList成员的指针
   lodsd             ;获取双向链表当前节点后继的指针
   mov eax,[eax+8]   ;获取kernel32.dll的基地址
   mov @dwRet,eax
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

;------------------------
; 补丁功能部分
; 传入三个参数：
;      _kernel:kernel32.dll的基地址
;      _getAddr:函数GetProcAddress地址
;      _loadLib:函数LoadLibraryA地址
;------------------------
_patchFun  proc _kernel,_getAddr,_loadLib

    ;------------------------------------------------------
    ; 补丁功能代码局部变量定义
    ;------------------------------------------------------

    local hUser32Base:dword
    local _messageBox:_ApiMessageBox    


    pushad


    ;------------------------------------------------------
    ; 补丁功能代码，以下只是一个范例，功能为弹出对话框
    ;------------------------------------------------------


    ;获取user32.dll的基地址
    mov eax,offset szUser32Dll
    add eax,ebx

    mov edx,_loadLib
    push eax
    call edx
    mov hUser32Base,eax


    ;使用GetProcAddress函数的首址，
    ;传入两个参数调用GetProcAddress函数，
    ;获得MessageBoxA的首址
    mov eax,offset szMessageBox
    add eax,ebx
   
    mov edx,_getAddr
    mov ecx,hUser32Base
    push eax
    push ecx
    call edx
    mov _messageBox,eax
    
    ;调用函数MessageBox !!
    mov eax,offset szHello
    add eax,ebx
    mov edx,_messageBox

    push MB_OK
    push NULL
    push eax
    push NULL
    call edx


    popad
    ret
_patchFun  endp


_start  proc
    local hKernel32Base:dword  ;存放kernel32.dll基址

    local _getProcAddress:_ApiGetProcAddress  ;定义函数
    local _loadLibrary:_ApiLoadLibrary

    pushad

    ;获取kernel32.dll的基地址
    lea edx,_getKernelBase
    add edx,ebx
    call edx
    mov hKernel32Base,eax

    ;从基地址出发搜索GetProcAddress函数的首址
    mov eax,offset szGetProcAddr
    add eax,ebx

    mov edi,hKernel32Base
    mov ecx,edi
    lea edx,_getApi
    add edx,ebx

    push eax
    push ecx
    call edx
    mov _getProcAddress,eax

    ;从基地址出发搜索LoadLibraryA函数的首址
    mov eax,offset szLoadLib
    add eax,ebx

    mov edi,hKernel32Base
    mov ecx,edi
    lea edx,_getApi
    add edx,ebx

    push eax
    push ecx
    call edx
    mov _loadLibrary,eax

    ;调用补丁代码
    lea edx,_patchFun
    add edx,ebx

    push _loadLibrary
    push _getProcAddress
    push hKernel32Base
    call edx

    popad
    ret
_start  endp

; EXE文件新的入口地址

_NewEntry:
    call @F   ; 免去重定位
@@:
    pop ebx
    sub ebx,offset @B

    invoke _start
    jmpToStart   db 0E9h,0F0h,0FFh,0FFh,0FFh
    ret
    end _NewEntry