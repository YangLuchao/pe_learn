;-------------------------
; 一个简单的测试API入口函数动态获得的小程序
; 本例将使用动态方法获得hDllKernel32的基址，
; 并从基址处查找相对应的函数，以及偏移
; 实现创建目录的方法、对话框显示方法调用
; 作者：戚利
; 开发日期：2010.6.26
;-------------------------

.386
.model flat,stdcall
option casemap:none

include     windows.inc
include     user32.inc
includelib  user32.lib
;声明函数类型
_ProtoGetProcAddress  typedef proto :dword,:dword
_ProtoLoadLibrary     typedef proto :dword
_ProtoMessageBox      typedef proto :dword,:dword,:dword,:dword
;声明函数
_ApiGetProcAddress    typedef ptr _ProtoGetProcAddress
_ApiLoadLibrary       typedef ptr _ProtoLoadLibrary
_ApiMessageBox        typedef ptr _ProtoMessageBox

.data

CreateDir       dd   ?             ;CreateDirectoryA函数的真实地址
lpCreateDir     dd   ?             ;未用
jmpCreateDir    db   0ffh,025h     ;这是一个跳转指令，即段内跳转jmp 
jmpCDOffset     dd   ?             ;这里紧跟着要跳转到的偏移，该偏移指向CreateDir，

hDllKernel32    dd   ?              ;存放kernel32.dll基址
hDllUser32      dd   ?
dwEsp           dd   ?
szBuffer        db   256 dup(0)

;定义函数
_GetProcAddress _ApiGetProcAddress  ?
_LoadLibrary    _ApiLoadLibrary     ?
_MessageBox     _ApiMessageBox      ?

.const

szLoadLibrary     db  'LoadLibraryA',0
szGetProcAddress  db  'GetProcAddress',0
szUser32          db  'user32.dll',0
szMessageBox      db  'MessageBoxA',0        ;该方法在user32.dll中
szCreateDir       db  'CreateDirectoryA',0   ;该方法在kernel32.dll中

szDir             db  'c:\\BBBN',0         ;要创建的目录
szCaption         db  '动态调用API函数示例',0
szText	          db  '请检查一下c盘根目录下，看是否有目录BBBN的出现？',0
szFmt             db  'return address=%08x',0

.code

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
_GetKernelBase proc _dwKernelRet
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
_GetKernelBase endp

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


start:
  mov eax,dword ptr [esp]  ;将kernel32中的一个地址从堆栈里取出来
  mov dwEsp,eax
  mov eax,offset CreateDir;createDir函数地址变量地址放入到eax中
  mov jmpCDOffset,eax;再放入到jmpCDOffest中
  
  invoke _GetKernelBase,dwEsp;获取kernel32.dll基址

  .if eax;eax不为0
    mov hDllKernel32,eax
    invoke _getApi,hDllKernel32,addr szGetProcAddress   ;获取GetProcAddress函数的内存地址
    mov _GetProcAddress,eax
    .if _GetProcAddress
      invoke _GetProcAddress,hDllKernel32,addr szCreateDir  ;获取创建目录函数的内存地址并调用
      mov CreateDir,eax

      ; 用call的方式调用createDir函数
      push NULL
      mov eax,offset szDir
      push eax
      mov eax,offset jmpCreateDir
      call eax


      invoke _GetProcAddress,hDllKernel32,addr szLoadLibrary  ;获取LoadLibrary函数的内存地址
      mov _LoadLibrary,eax
      .if eax
        invoke _LoadLibrary,addr szUser32                     ;装载user32.dll
        mov hDllUser32,eax
        invoke _GetProcAddress,hDllUser32,addr szMessageBox   ;获得MessageBox函数的内存地址并调用
        mov _MessageBox,eax;将messageBox地址放入到全局变量中
      .endif
    .endif

    .if _MessageBox
      push MB_OK
      mov eax,offset szCaption
      push eax
      mov eax,offset szText
      push eax
      push 00000000
      call _MessageBox;执行messageBox
    .endif
  .endif

  ;在windows2000中，需要先将user32.dll加载进进程空间
  invoke wsprintf,addr szBuffer,addr szFmt,eax

  ;这是关键，如果不使用ret指令返回，则堆栈中将不会是kernel32的某个地址
  ret   

           end start
