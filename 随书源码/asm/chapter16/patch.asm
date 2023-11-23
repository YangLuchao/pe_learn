;-------------------------
; 一段附加到其他PE文件的小程序
; 本段代码使用了API函数地址动态获取以及重定位技术
; 程序功能：实现创建目录的方法
; 作者：戚利
; 开发日期：2010.6.30
;-------------------------

    .386
    .model flat,stdcall
    option casemap:none

include    windows.inc


;声明函数
_ProtoGetProcAddress  typedef proto :dword,:dword
_ProtoLoadLibrary     typedef proto :dword
_ProtoCreateDir       typedef proto :dword,:dword

;声明函数指针
_ApiGetProcAddress    typedef ptr _ProtoGetProcAddress
_ApiLoadLibrary       typedef ptr _ProtoLoadLibrary
_ApiCreateDir         typedef ptr _ProtoCreateDir


;被添加到目标文件的代码从这里开始，到APPEND_CODE_END处结束

    .code

jmp _NewEntry


szGetProcAddr  db  'GetProcAddress',0
szLoadLib      db  'LoadLibraryA',0
szCreateDir    db  'CreateDirectoryA',0   ;该方法在kernel32.dll中
szDir          db  'c:\\BBBN',0           ;要创建的目录


;-----------------------------
; 错误 Handler
;-----------------------------------------
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

;-------------------------------------------
; 在内存中扫描 Kernel32.dll 的基址
; 从指定的基址处向高地址搜索。
;-------------------------------------------

_getKernelBase proc _dwKernelRet
  local @dwReturn
  
  pushad
  mov @dwReturn,0

  ;重定位
  call @F
@@:
  pop ebx
  sub ebx,offset @B

  ;创建用于错误处理的SEH结构
  assume fs:nothing
  push ebp
  lea eax,[ebx+offset _ret]
  push eax
  lea eax,[ebx+offset _SEHHandler]
  push eax
  push fs:[0]
  mov fs:[0],esp

  ;查找kernel32.dll的基址
  mov edi,_dwKernelRet
  and edi,0ffff0000h   ;找到返回地址按内存对齐的头
  .while TRUE
    .if word ptr [edi]==IMAGE_DOS_SIGNATURE
      mov esi,edi
      add esi,[esi+3ch]
      .if word ptr [esi]==IMAGE_NT_SIGNATURE
        mov @dwReturn,edi
        .break
      .endif
    .endif
_ret:
    sub edi,010000h             ;调整一个内存页面，继续查找
    .break .if edi<070000000h   ;直到地址小于070000000h
  .endw  
  pop fs:[0]
  add esp,0ch
  popad
  mov eax,@dwReturn
  ret
_getKernelBase endp

;------------------------------------------------
; 从内存中模块的导出表中获取某个 API 的入口地址
;------------------------------------------------
_getApi  proc  _hModule,_lpszApi
  local @dwReturn,@dwStringLen
  
  pushad
  mov @dwReturn,0
  call @F
@@:
  pop ebx
  sub ebx,offset @B

  ;创建用于错误处理的SEH结构
  assume fs:nothing
  push ebp
  lea eax,[ebx+offset _ret]
  push eax
  lea eax,[ebx+offset _SEHHandler]
  push eax
  push fs:[0]
  mov fs:[0],esp

  ;计算API字符串的长度（注意带尾部的0）
  mov edi,_lpszApi
  mov ecx,-1
  xor al,al
  cld
  repnz scasb
  mov ecx,edi
  sub ecx,_lpszApi
  mov @dwStringLen,ecx
  ;从DLL文件头的数据目录中获取导出表的位置
  mov esi,_hModule
  add esi,[esi+3ch]
  assume esi:ptr IMAGE_NT_HEADERS
  mov esi,[esi].OptionalHeader.DataDirectory.VirtualAddress
  add esi,_hModule
  assume esi:ptr IMAGE_EXPORT_DIRECTORY
  mov ebx,[esi].AddressOfNames
  add ebx,_hModule
  xor edx,edx
  .repeat
    push esi
    mov edi,[ebx]
    add edi,_hModule
    mov esi,_lpszApi
    mov ecx,@dwStringLen
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
  ;API名称索引->序号索引->地址索引
  sub ebx,[esi].AddressOfNames
  sub ebx,_hModule
  shr ebx,1
  add ebx,[esi].AddressOfNameOrdinals
  add ebx,_hModule
  movzx eax,word ptr [ebx]
  shl eax,2
  add eax,[esi].AddressOfFunctions
  add eax,_hModule
  ;从地址表得到导出函数地址
  mov eax,[eax]
  add eax,_hModule
  mov @dwReturn,eax
_ret:
  pop fs:[0]
  add esp,0ch
  assume esi:nothing
  popad
  mov eax,@dwReturn
  ret
_getApi  endp

_start  proc
    local hKernel32Base:dword              ;存放kernel32.dll基址
    local hUser32Base:dword

    local _getProcAddress:_ApiGetProcAddress  ;定义函数
    local _loadLibrary:_ApiLoadLibrary
    local _createDir:_ApiCreateDir    

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
    mov _getProcAddress,eax   ;为函数引用赋值 GetProcAddress

    ;使用GetProcAddress函数的首址，传入两个参数调用GetProcAddress函数，获得CreateDirA的首址
    mov eax,offset szCreateDir
    add eax,ebx
    invoke _getProcAddress,hKernel32Base,eax
    mov _createDir,eax
    
    ;调用创建目录的函数
    mov eax,offset szDir
    add eax,ebx
    invoke _createDir,eax,NULL

    popad
    ret
_start  endp

; EXE文件新的入口地址

_NewEntry:
    ;取当前函数的堆栈栈顶值
    mov eax,dword ptr [esp]
    push eax
    call @F   ; 免去重定位
@@:
    pop ebx
    sub ebx,offset @B
    pop eax
    invoke _start
    jmpToStart   db 0E9h,0F0h,0FFh,0FFh,0FFh
    ret
    end _NewEntry