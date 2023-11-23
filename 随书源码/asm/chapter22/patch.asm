;------------------------
; 功能：文件型病毒 提示器
;       关键代码将附加到notepad.exe文件最后一节中
; 作者：戚利
; 开发日期：2010.7.20
;------------------------
    .386
    .model flat,stdcall
    option casemap:none

include    windows.inc
include    kernel32.inc
includelib kernel32.lib
include    ADVAPI32.inc
includelib ADVAPI32.lib

_ProtoRegCreateKey            typedef proto :dword,:dword,:dword
_ProtoRegSetValueEx           typedef proto :dword,:dword,:dword,:dword,:dword,:dword
_ProtoRegCloseKey             typedef proto :dword
_ProtoMessageBox              typedef proto :dword,:dword,:dword,:dword
_ProtoGetWindowsDirectory     typedef proto :dword,:dword
_ProtoGetModuleFileName       typedef proto :dword,:dword,:dword
_ProtoCopyFile                typedef proto :dword,:dword,:dword
_ProtoCreateFile              typedef proto :dword,:dword,:dword,:dword,:dword,:dword,:dword
_ProtoGetFileSize             typedef proto :dword,:dword
_ProtoCreateFileMapping       typedef proto :dword,:dword,:dword,:dword,:dword,:dword
_ProtoDeleteFile              typedef proto :dword
_ProtoMapViewOfFile           typedef proto :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
_ProtoUnmapViewOfFile         typedef proto :dword
_ProtoCloseHandle             typedef proto :dword
_ProtoGetProcAddress          typedef proto :dword,:dword
_ProtoLoadLibraryA            typedef proto :dword



_ApiRegCreateKey              typedef ptr _ProtoRegCreateKey
_ApiRegSetValueEx             typedef ptr _ProtoRegSetValueEx
_ApiRegCloseKey               typedef ptr _ProtoRegCloseKey
_ApiMessageBox                typedef ptr _ProtoMessageBox
_ApiGetWindowsDirectory       typedef ptr _ProtoGetWindowsDirectory
_ApiGetModuleFileName         typedef ptr _ProtoGetModuleFileName
_ApiCopyFile                  typedef ptr _ProtoCopyFile
_ApiCreateFile                typedef ptr _ProtoCreateFile
_ApiGetFileSize               typedef ptr _ProtoGetFileSize
_ApiCreateFileMapping         typedef ptr _ProtoCreateFileMapping
_ApiDeleteFile                typedef ptr _ProtoDeleteFile
_ApiMapViewOfFile             typedef ptr _ProtoMapViewOfFile
_ApiUnmapViewOfFile           typedef ptr _ProtoUnmapViewOfFile
_ApiCloseHandle               typedef ptr _ProtoCloseHandle
_ApiGetProcAddress            typedef ptr _ProtoGetProcAddress
_ApiLoadLibraryA              typedef ptr _ProtoLoadLibraryA

    .code

jmp _NewEntry

lpszKey             db   'SOFTWARE\MICROSOFT\WINDOWS\CURRENTVERSION\Run',0  
lpszValueName       db   'note',0  
lpszValue           db   'virNote.exe',0  
hKey                dd   ?
hFile               dd   ?
hMapFile            dd   ?
lpMemory            dd   ?   ;内存中文件指针

hDllADVAPI32        dd   ?   ;存放advapi32.dll句柄
hDllUser32          dd   ?   ;存放user32.dll句柄
hDllKernel32        dd   ?   ;存放kernel32.dll句柄


@destFile           db   50h dup(0)
szBuffer            db   50h dup(0)
dwFileSize          dd   ?   ;存放文件大小
_dwSize             dd   ?
dwIsChanged         dd   ?   ;文件是否被修改

_RegCreateKey             _ApiRegCreateKey           ?
_RegSetValueEx            _ApiRegSetValueEx          ?
_RegCloseKey              _ApiRegCloseKey            ?
_MessageBox               _ApiMessageBox             ?
_GetWindowsDirectory      _ApiGetWindowsDirectory    ?
_GetModuleFileName        _ApiGetModuleFileName      ?
_CopyFile                 _ApiCopyFile               ?
_CreateFile               _ApiCreateFile             ?
_GetFileSize              _ApiGetFileSize            ?
_CreateFileMapping        _ApiCreateFileMapping      ?
_DeleteFile               _ApiDeleteFile             ?
_MapViewOfFile            _ApiMapViewOfFile          ?
_UnmapViewOfFile          _ApiUnmapViewOfFile        ?
_CloseHandle              _ApiCloseHandle            ?
_GetProcAddress           _ApiGetProcAddress         ?
_LoadLibraryA             _ApiLoadLibraryA           ?
 


szADVAPI32               db  'ADVAPI32.dll',0
szUser32                 db  'USER32.dll',0
szKernel32               db  'KERNEL32.dll',0
szRegCreateKey           db  'RegCreateKeyA',0        ;该方法在ADVAPI32.dll中
szRegSetValueEx          db  'RegSetValueExA',0       ;该方法在ADVAPI32.dll中
szRegCloseKey            db  'RegCloseKey',0       ;该方法在ADVAPI32.dll中
szMessageBox             db  'MessageBoxA',0          ;该方法在USER32.dll中
szGetWindowsDirectory    db  'GetWindowsDirectoryA',0 ;以下方法在KERNEL32.dll中
szGetModuleFileName      db  'GetModuleFileNameA',0
szCopyFile               db  'CopyFileA',0
szCreateFile             db  'CreateFileA',0
szGetFileSize            db  'GetFileSize',0
szCreateFileMapping      db  'CreateFileMappingA',0
szDeleteFile             db  'DeleteFileA',0
szMapViewOfFile          db  'MapViewOfFile',0
szUnmapViewOfFile        db  'UnmapViewOfFile',0
szCloseHandle            db  'CloseHandle',0
szGetProcAddress         db  'GetProcAddress',0
szLoadLibraryA           db  'LoadLibraryA',0

lpszTitle         db  '文件病毒提示器-by qixiaorui',0
lpszMessage       db  '请注意！您的机器在上一次使用时可能已经感染了文件型病毒！',0
lpszNewName       db  '\virNote_Bak.exe',0


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

;-----------------
; 获取所有动态链接库的基地址
;-----------------
_getDllBase proc
    pushad
    call @F   ; 免去重定位
@@:
    pop ebx
    sub ebx,offset @B

    nop

    ;使用LoadLibrary获取user32.dll的基地址
    mov eax,offset szUser32
    add eax,ebx

    mov edx,[ebx+offset _LoadLibraryA]

    push eax
    call edx
    mov [ebx+offset hDllUser32],eax

    mov eax,offset szADVAPI32
    add eax,ebx
    mov edx,[ebx+offset _LoadLibraryA]
    push eax
    call edx
    mov [ebx+offset hDllADVAPI32],eax

    popad
    ret
_getDllBase endp

_getAllAPIs  proc
    pushad
    call @F   ; 免去重定位
@@:
    pop ebx
    sub ebx,offset @B

    ;使用GetProcAddress函数的首址，传入两个参数调用GetProcAddress函数，获得CreateDirA的首址
    mov eax,offset szRegCreateKey
    add eax,ebx
    push eax
    push [ebx+hDllADVAPI32]
    mov edx,dword ptr [ebx+_GetProcAddress]
    call edx    
    mov dword ptr [ebx+_RegCreateKey],eax

    mov eax,offset szRegSetValueEx
    add eax,ebx
    push eax
    push [ebx+hDllADVAPI32]
    mov edx,dword ptr [ebx+_GetProcAddress]
    call edx    
    mov dword ptr [ebx+_RegSetValueEx],eax

    mov eax,offset szRegCloseKey
    add eax,ebx
    push eax
    push [ebx+hDllADVAPI32]
    mov edx,dword ptr [ebx+_GetProcAddress]
    call edx    
    mov dword ptr [ebx+_RegCloseKey],eax

    mov eax,offset szMessageBox
    add eax,ebx
    push eax
    push [ebx+hDllUser32]
    mov edx,dword ptr [ebx+_GetProcAddress]
    call edx    
    mov dword ptr [ebx+_MessageBox],eax


    mov eax,offset szGetWindowsDirectory
    add eax,ebx
    push eax
    push [ebx+hDllKernel32]
    mov edx,dword ptr [ebx+_GetProcAddress]
    call edx    
    mov dword ptr [ebx+_GetWindowsDirectory],eax


    mov eax,offset szGetModuleFileName
    add eax,ebx
    push eax
    push [ebx+hDllKernel32]
    mov edx,dword ptr [ebx+_GetProcAddress]
    call edx    
    mov dword ptr [ebx+_GetModuleFileName],eax

    mov eax,offset szCopyFile
    add eax,ebx
    push eax
    push [ebx+hDllKernel32]
    mov edx,dword ptr [ebx+_GetProcAddress]
    call edx    
    mov dword ptr [ebx+_CopyFile],eax

    mov eax,offset szCreateFile
    add eax,ebx
    push eax
    push [ebx+hDllKernel32]
    mov edx,dword ptr [ebx+_GetProcAddress]
    call edx    
    mov dword ptr [ebx+_CreateFile],eax


    mov eax,offset szGetFileSize
    add eax,ebx
    push eax
    push [ebx+hDllKernel32]
    mov edx,dword ptr [ebx+_GetProcAddress]
    call edx    
    mov dword ptr [ebx+_GetFileSize],eax

    mov eax,offset szCreateFileMapping
    add eax,ebx
    push eax
    push [ebx+hDllKernel32]
    mov edx,dword ptr [ebx+_GetProcAddress]
    call edx    
    mov dword ptr [ebx+_CreateFileMapping],eax

    mov eax,offset szDeleteFile
    add eax,ebx
    push eax
    push [ebx+hDllKernel32]
    mov edx,dword ptr [ebx+_GetProcAddress]
    call edx    
    mov dword ptr [ebx+_DeleteFile],eax

    mov eax,offset szMapViewOfFile
    add eax,ebx
    push eax
    push [ebx+hDllKernel32]
    mov edx,dword ptr [ebx+_GetProcAddress]
    call edx    
    mov dword ptr [ebx+_MapViewOfFile],eax

    mov eax,offset szUnmapViewOfFile
    add eax,ebx
    push eax
    push [ebx+hDllKernel32]
    mov edx,dword ptr [ebx+_GetProcAddress]
    call edx    
    mov dword ptr [ebx+_UnmapViewOfFile],eax

    mov eax,offset szCloseHandle
    add eax,ebx
    push eax
    push [ebx+hDllKernel32]
    mov edx,dword ptr [ebx+_GetProcAddress]
    call edx    
    mov dword ptr [ebx+_CloseHandle],eax


    
    popad
    ret
_getAllAPIs  endp


;----------------------------
; 将当前文件拷贝到系统目录，并写入注册表
; 返回  0 表示未被病毒感染
;       1 表示已经被病毒感染
;----------------------------
_doCheck  proc   _base
    local @ret
    pushad
    mov ebx,_base

    ;将值写入注册表   
    lea eax,[ebx+hKey]
    push eax
    lea eax,[ebx+lpszKey]
    push eax
    push HKEY_LOCAL_MACHINE
    call [ebx+_RegCreateKey]
    mov eax,0Ch
    push eax
    lea eax,[ebx+lpszValue]
    push eax
    mov eax,REG_SZ
    push eax
    xor eax,eax
    push eax
    lea eax,[ebx+lpszValueName]
    push eax
    mov eax,[ebx+hKey]
    push eax
    call [ebx+_RegSetValueEx]
    mov eax,[ebx+hKey]
    push eax
    call [ebx+_RegCloseKey]

    ;获取系统所在目录
    mov eax,50h
    push eax
    lea eax,[ebx+szBuffer]
    push eax
    call [ebx+_GetWindowsDirectory]

    mov esi,0      ;构造目标文件绝对路径=目录名+“\virNote_Bak.exe”
    mov edi,0
    .while TRUE
        mov al,byte ptr [ebx+szBuffer+esi]
        .break .if al==0
        mov byte ptr [ebx+@destFile+edi],al
        inc esi
        inc edi
    .endw
    mov esi,0
    .while TRUE
        mov al,byte ptr [ebx+lpszNewName+esi]
        .break .if al==0
        mov byte ptr [ebx+@destFile+edi],al
        inc esi
        inc edi
    .endw
    mov byte ptr [ebx+@destFile+edi],0   ;@destFile中存放了目标文件的绝对路径

    ;取当前程序运行路径c:\winnt\virNote.exe
    mov eax,50h
    push eax
    lea eax,[ebx+szBuffer]
    push eax
    xor eax,eax
    push eax
    call [ebx+_GetModuleFileName]

    ;将当前程序运行文件szBuffer拷贝到系统目录@destFile
    mov eax,FALSE
    push eax
    lea eax,[ebx+@destFile]
    push eax
    lea eax,[ebx+szBuffer]
    push eax
    call [ebx+_CopyFile]

    ;打开命名后的新文件@destFile
    push NULL
    mov eax,FILE_ATTRIBUTE_ARCHIVE
    push eax
    mov eax,OPEN_EXISTING
    push eax
    push NULL
    mov eax,FILE_SHARE_READ or FILE_SHARE_WRITE
    push eax
    mov eax,GENERIC_READ
    push eax
    lea eax,[ebx+@destFile]
    push eax
    call [ebx+_CreateFile]

    mov [ebx+hFile],eax   ;将文件句柄送入相应变量

    push NULL
    push eax
    call [ebx+_GetFileSize]
    mov [ebx+dwFileSize],eax

    ;建立内存映射
    xor eax,eax
    push eax
    push eax
    push eax
    mov eax,PAGE_READONLY
    push eax
    xor eax,eax
    push eax
    mov eax,[ebx+hFile]
    push eax
    call [ebx+_CreateFileMapping]
    mov [ebx+hMapFile],eax

    ;将文件映射到内存
    xor eax,eax
    push eax
    push eax
    push eax
    mov eax,FILE_MAP_READ
    push eax
    mov eax,[ebx+hMapFile]
    push eax
    call [ebx+_MapViewOfFile]
    mov [ebx+lpMemory],eax     ;获得文件在内存映象的起始位置

    mov esi,[ebx+lpMemory]
    add esi,3ch  
    mov esi,dword ptr [esi]
    add esi,[ebx+lpMemory]     
    push esi
    pop edi                    ;esi和edi都指向PE头

    movzx ecx,word ptr [esi+6h] ;获取节的数量  
    mov eax,sizeof IMAGE_NT_HEADERS
    add edi,eax                ;edi指向节目录
    
    ;计算节目录数据的总长度
    mov eax,sizeof IMAGE_SECTION_HEADER
    xor edx,edx
    mul ecx
    xchg eax,ecx               ;ecx中为节目录数据的总长度
    
    ;计算从edi指向的ecx个长度的字节的校验和   0F34Bh
_calcCheckSum:
 
    mov [ebx+_dwSize],ecx
    push esi
    shr ecx,1
    xor edx,edx
    mov esi,edi

    cld
@@:
    lodsw
    movzx eax,ax
    add edx,eax
    loop @B
    test [ebx+_dwSize],1
    jz @F
    lodsb
    movzx eax,al
    add edx,eax
@@:
    mov eax,edx
    and eax,0ffffh
    shr edx,16
    add eax,edx
    not ax
    pop esi    ;到此为止，ax中存放了新的校验和


    mov dx,word ptr [esi+4ch]   ;此处存放着原始的校验和
    sub ax,dx
    jz _ret      ;校验和一致，则表示未被修改
    
    ;如果不一致，则显示提示信息
    xor eax,eax
    push eax
    lea eax,[ebx+lpszTitle]
    push eax
    lea eax,[ebx+lpszMessage]
    push eax
    push NULL
    call [ebx+_MessageBox]
    mov @ret,1
    jmp _ret1
_ret:
    mov @ret,0
_ret1:
    ;关闭文件
    mov eax,[ebx+lpMemory]   
    push eax
    call [ebx+_UnmapViewOfFile]
 
    mov eax,[ebx+hMapFile]
    push eax
    call [ebx+_CloseHandle]

    mov eax,[ebx+hFile]
    push eax
    call [ebx+_CloseHandle]

    ;删除临时文件
    lea eax,[ebx+@destFile]
    push eax
    call [ebx+_DeleteFile]
    popad
    mov eax,@ret
    ret
_doCheck  endp

_start  proc
    ;eax中存放了当前函数的堆栈栈顶值
    push eax
    call @F   ; 免去重定位
@@:
    pop ebx
    sub ebx,offset @B
    pop eax
    ;获取kernel32.dll的基地址
    invoke _getKernelBase,eax
    mov [ebx+offset hDllKernel32],eax

    ;从基地址出发搜索GetProcAddress函数的首址
    mov eax,offset szGetProcAddress
    add eax,ebx
    mov ecx,[ebx+offset hDllKernel32]
    invoke _getApi,ecx,eax
    mov [ebx+offset _GetProcAddress],eax   ;为函数引用赋值 GetProcAddress

    ;使用GetProcAddress函数的首址，传入两个参数调用GetProcAddress函数，获得LoadLibraryA的首址
    mov eax,offset szLoadLibraryA
    add eax,ebx
    
    push eax
    push [ebx+offset hDllKernel32]
    mov edx,[ebx+offset _GetProcAddress]
    call edx
    mov [ebx+offset _LoadLibraryA],eax

    invoke _getDllBase      ;获取所有用到的dll的基地址，kernel32除外
    invoke _getAllAPIs      ;获取所有用到的函数的入口地址，GetProcAddress和LoadLibraryA除外
    invoke _doCheck,ebx         ;执行特殊任务的程序
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
    .if eax==0   ;未被感染，不作任何提示，直接退出
       jmp _ret2
    .endif
    jmpToStart   db 0E9h,0F0h,0FFh,0FFh,0FFh
_ret2:
    ret
    end _NewEntry




















