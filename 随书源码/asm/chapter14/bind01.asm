;-------------------------------------------
; 将patch.ext补丁程序插入到指定exe文件中首先运行
; 主要演示如何使用程序修改PE文件格式，从而完成想
; 要实现的功能
; 01-只分析数据段是否满足要求
;-------------------------------------------

.386
.model flat,stdcall
option casemap:none

include    windows.inc
include    user32.inc
include    kernel32.inc
include    gdi32.inc
include    comctl32.inc
include    comdlg32.inc
include    advapi32.inc
include    shell32.inc
include    masm32.inc
include    netapi32.inc
include    winmm.inc
include    ws2_32.inc
include    psapi.inc
include    mpr.inc        ;WNetCancelConnection2
include    iphlpapi.inc   ;SendARP
includelib comctl32.lib
includelib comdlg32.lib
includelib gdi32.lib
includelib user32.lib
includelib kernel32.lib
includelib advapi32.lib
includelib shell32.lib
includelib masm32.lib
includelib netapi32.lib
includelib winmm.lib
includelib ws2_32.lib
includelib psapi.lib
includelib mpr.lib
includelib iphlpapi.lib



ICO_MAIN equ 1000
DLG_MAIN equ 1000
IDC_INFO equ 1001
IDM_MAIN equ 2000
IDM_OPEN equ 2001
IDM_EXIT equ 2002
IDM_1    equ 4000
IDM_2    equ 4001
IDM_3    equ 4002

.data
hInstance   dd ?
hRichEdit   dd ?
hWinMain    dd ?
hWinEdit    dd ?
szFileName  db MAX_PATH dup(?)
szBuffer    db  256 dup(?)

dwPatchDataSize      dd ?  ;补丁数据段大小
dwPatchDataStart     dd ?  ;补丁数据起始地址
dwDstDataSize        dd ?  ;目标数据段大小
dwDstDataStart       dd ?  ;目标数据起始地址
dwDstRawDataSize     dd ?  ;目标数据在文件中对齐后的大小
dwDstMemDataStart     dd ? ;目标数据段在内存中的起始地址
dwStartAddressinDstDS dd ? ;新增加的补丁数据段在目标文件中的起始位置



.const
szDllEdit   db 'RichEd20.dll',0
szClassEdit db 'RichEdit20A',0
szFont      db '宋体',0


szFile1     db 'd:\masm32\source\chapter10\patch.exe',256 dup(0)
szFile2     db 'd:\masm32\source\chapter10\HelloWorld.exe',256 dup(0)
hFile1      dd ?
hFile2      dd ?

szErr       db '文件格式错误!',0
szErrFormat db '这个文件不是PE格式的文件!',0
szSuccess   db '恭喜你，程序执行到这里是成功的。',0
szNotFound  db '无法查找',0
szoutLine   db '----------------------------------------------------------------------------------------',0dh,0ah,0
szErr110      db '>> 未找到可存放数据的节！',0dh,0ah,0
szErr11      db '>> 目标数据段空间不够，不足以容纳补丁程序的数据！',0dh,0ah,0

szOut11      db '补丁数据段的大小为：%08x',0dh,0ah,0
szOut12      db '补丁数据段在文件中的起始位置：%08x',0dh,0ah,0
szOut13      db '目标数据段的大小为：%08x',0dh,0ah,0
szOut14      db '目标数据段在文件中的起始位置：%08x',0dh,0ah,0
szOut15      db '目标数据段在文件中对齐后的大小：%08x',0dh,0ah,0
szOut16      db '目标文件的数据段中有空间，空间大小为%08x,补丁数据段在目标文件中存放的起始位置：%08x',0dh,0ah,0
szOut17      db '目标数据段在内存中的起始地址：%08x',0dh,0ah,0
szOut18      db '目标代码装入地址和程序执行入口：%08x:%08x',0dh,0ah,0


szOut123     db '%04x',0
lpszHexArr  db  '0123456789ABCDEF',0



.data?
stLVC         LV_COLUMN <?>
stLVI         LV_ITEM   <?>


.code

;----------------
;初始化窗口程序
;----------------
_init proc
  local @stCf:CHARFORMAT
  
  invoke GetDlgItem,hWinMain,IDC_INFO
  mov hWinEdit,eax
  invoke LoadIcon,hInstance,ICO_MAIN
  invoke SendMessage,hWinMain,WM_SETICON,ICON_BIG,eax       ;为窗口设置图标
  invoke SendMessage,hWinEdit,EM_SETTEXTMODE,TM_PLAINTEXT,0 ;设置编辑控件
  invoke RtlZeroMemory,addr @stCf,sizeof @stCf
  mov @stCf.cbSize,sizeof @stCf
  mov @stCf.yHeight,9*20
  mov @stCf.dwMask,CFM_FACE or CFM_SIZE or CFM_BOLD
  invoke lstrcpy,addr @stCf.szFaceName,addr szFont
  invoke SendMessage,hWinEdit,EM_SETCHARFORMAT,0,addr @stCf
  invoke SendMessage,hWinEdit,EM_EXLIMITTEXT,0,-1
  ret
_init endp

;------------------
; 错误Handler
;------------------
_Handler proc _lpExceptionRecord,_lpSEH,\
              _lpContext,_lpDispathcerContext

  pushad
  mov esi,_lpExceptionRecord
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
_Handler endp

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
    add eax,[edx].Misc             ;计算该节结束RVA
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
  mov eax,offset szNotFound
@@:
  mov @dwReturn,eax
  popad
  mov eax,@dwReturn
  ret
_getRVASectionName  endp
;---------------------
; 往文本框中追加文本
;---------------------
_appendInfo proc _lpsz
  local @stCR:CHARRANGE

  pushad
  invoke GetWindowTextLength,hWinEdit
  mov @stCR.cpMin,eax  ;将插入点移动到最后
  mov @stCR.cpMax,eax
  invoke SendMessage,hWinEdit,EM_EXSETSEL,0,addr @stCR
  invoke SendMessage,hWinEdit,EM_REPLACESEL,FALSE,_lpsz
  popad
  ret
_appendInfo endp

;-------------------
; 取数据段大小
; 数据段定位方法：
; 只要节的标识第6,30,31位为1，则表示符合要求
; _lpHeader指向内存中PE文件的起始
; 返回值在eax中
;-------------------
getDataSize proc _lpHeader
   local @dwSize
   local @dwSectionSize
   pushad
   
   mov esi,_lpHeader
   assume esi:ptr IMAGE_DOS_HEADER
   add esi,[esi].e_lfanew    ;调整ESI指针指向PE文件头
   assume esi:ptr IMAGE_NT_HEADERS
   ;取节的数量
   add esi,4
   assume esi:ptr IMAGE_FILE_HEADER
   movzx ecx,[esi].NumberOfSections
   mov @dwSectionSize,ecx

   add esi,0F4h   ;esi指向节表位置
   .repeat
     assume esi:ptr IMAGE_SECTION_HEADER
     mov ebx,[esi].Characteristics  ;取节的标识
     and ebx,0c0000040h
     .if ebx==0c0000040h
        mov eax,[esi].Misc
        mov @dwSize,eax
        .break
     .endif
     dec @dwSectionSize
     add esi,sizeof IMAGE_SECTION_HEADER
     .break .if @dwSectionSize==0
   .until FALSE
   
   popad
   mov eax,@dwSize
   ret
getDataSize endp

;-------------------
; 取数据段在文件中对齐后的大小
; 数据段定位方法：
; 只要节的标识第6,30,31位为1，则表示符合要求
; _lpHeader指向内存中PE文件的起始
; 返回值在eax中
;-------------------
getRawDataSize proc _lpHeader
   local @dwSize
   local @dwSectionSize
   pushad
   
   mov esi,_lpHeader
   assume esi:ptr IMAGE_DOS_HEADER
   add esi,[esi].e_lfanew    ;调整ESI指针指向PE文件头
   assume esi:ptr IMAGE_NT_HEADERS
   ;取节的数量
   add esi,4
   assume esi:ptr IMAGE_FILE_HEADER
   movzx ecx,[esi].NumberOfSections
   mov @dwSectionSize,ecx

   add esi,0F4h   ;esi指向节表位置
   .repeat
     assume esi:ptr IMAGE_SECTION_HEADER
     mov ebx,[esi].Characteristics  ;取节的标识
     and ebx,0c0000040h
     .if ebx==0c0000040h
        mov eax,[esi].SizeOfRawData
        mov @dwSize,eax
        .break
     .endif
     dec @dwSectionSize
     add esi,sizeof IMAGE_SECTION_HEADER
     .break .if @dwSectionSize==0
   .until FALSE
   
   popad
   mov eax,@dwSize
   ret
getRawDataSize endp
;-------------------
; 取数据段在文件中的起始位置
; 数据段定位方法：
; 只要节的标识第6,30,31位为1，则表示符合要求
; _lpHeader指向内存中PE文件的起始
; 返回值在eax中
;-------------------
getDataStart proc _lpHeader
   local @dwStart
   local @dwSectionSize
   pushad
   
   mov esi,_lpHeader
   assume esi:ptr IMAGE_DOS_HEADER
   add esi,[esi].e_lfanew    ;调整ESI指针指向PE文件头
   assume esi:ptr IMAGE_NT_HEADERS
   ;取节的数量
   add esi,4
   assume esi:ptr IMAGE_FILE_HEADER
   movzx ecx,[esi].NumberOfSections
   mov @dwSectionSize,ecx

   add esi,0F4h   ;esi指向节表位置
   .repeat
     assume esi:ptr IMAGE_SECTION_HEADER
     mov ebx,[esi].Characteristics  ;取节的标识
     and ebx,0c0000040h
     .if ebx==0c0000040h
        mov eax,[esi].PointerToRawData
        mov @dwStart,eax
        .break
     .endif
     dec @dwSectionSize
     add esi,sizeof IMAGE_SECTION_HEADER
     .break .if @dwSectionSize==0
   .until FALSE
   
   popad
   mov eax,@dwStart
   ret
getDataStart endp

;-------------------
; 取数据段在内存中的起始位置
; 数据段定位方法：
; 只要节的标识第6,30,31位为1，则表示符合要求
; _lpHeader指向内存中PE文件的起始
; 返回值在eax中
;-------------------
getDataStartInMem proc _lpHeader
   local @dwStart
   local @dwSectionSize
   pushad
   
   mov esi,_lpHeader
   assume esi:ptr IMAGE_DOS_HEADER
   add esi,[esi].e_lfanew    ;调整ESI指针指向PE文件头
   assume esi:ptr IMAGE_NT_HEADERS
   ;取节的数量
   add esi,4
   assume esi:ptr IMAGE_FILE_HEADER
   movzx ecx,[esi].NumberOfSections
   mov @dwSectionSize,ecx

   add esi,0F4h   ;esi指向节表位置
   .repeat
     assume esi:ptr IMAGE_SECTION_HEADER
     mov ebx,[esi].Characteristics  ;取节的标识
     and ebx,0c0000040h
     .if ebx==0c0000040h
        mov eax,[esi].VirtualAddress
        mov @dwStart,eax
        .break
     .endif
     dec @dwSectionSize
     add esi,sizeof IMAGE_SECTION_HEADER
     .break .if @dwSectionSize==0
   .until FALSE
   
   popad
   mov eax,@dwStart
   ret
getDataStartInMem endp

;--------------------
; 打开PE文件并处理
;--------------------
_OpenFile proc
  local @stOF:OPENFILENAME
  local @hFile,@dwFileSize,@hMapFile,@lpMemory
  local @hFile1,@dwFileSize1,@hMapFile1,@lpMemory1
  local @bufTemp1[10]:byte
  local @dwTemp:dword,@dwTemp1:dword


  invoke CreateFile,addr szFile1,GENERIC_READ,\
         FILE_SHARE_READ or FILE_SHARE_WRITE,NULL,\
         OPEN_EXISTING,FILE_ATTRIBUTE_ARCHIVE,NULL

  .if eax!=INVALID_HANDLE_VALUE
    mov @hFile,eax
    invoke GetFileSize,eax,NULL
    mov @dwFileSize,eax
    .if eax
      invoke CreateFileMapping,@hFile,\  ;内存映射文件
             NULL,PAGE_READONLY,0,0,NULL
      .if eax
        mov @hMapFile,eax
        invoke MapViewOfFile,eax,\
               FILE_MAP_READ,0,0,0
        .if eax
          mov @lpMemory,eax              ;获得文件在内存的映象起始位置
          assume fs:nothing
          push ebp
          push offset _ErrFormat
          push offset _Handler
          push fs:[0]
          mov fs:[0],esp

          ;检测PE文件是否有效
          mov esi,@lpMemory
          assume esi:ptr IMAGE_DOS_HEADER
          .if [esi].e_magic!=IMAGE_DOS_SIGNATURE  ;判断是否有MZ字样
            jmp _ErrFormat
          .endif
          add esi,[esi].e_lfanew    ;调整ESI指针指向PE文件头
          assume esi:ptr IMAGE_NT_HEADERS
          .if [esi].Signature!=IMAGE_NT_SIGNATURE ;判断是否有PE字样
            jmp _ErrFormat
          .endif
        .endif
      .endif
    .endif
  .endif

  invoke CreateFile,addr szFile2,GENERIC_READ,\
         FILE_SHARE_READ or FILE_SHARE_WRITE,NULL,\
         OPEN_EXISTING,FILE_ATTRIBUTE_ARCHIVE,NULL

  .if eax!=INVALID_HANDLE_VALUE
    mov @hFile1,eax
    invoke GetFileSize,eax,NULL
    mov @dwFileSize1,eax
    .if eax
      invoke CreateFileMapping,@hFile1,\  ;内存映射文件
             NULL,PAGE_READONLY,0,0,NULL
      .if eax
        mov @hMapFile1,eax
        invoke MapViewOfFile,eax,\
               FILE_MAP_READ,0,0,0
        .if eax
          mov @lpMemory1,eax              ;获得文件在内存的映象起始位置
          assume fs:nothing
          push ebp
          push offset _ErrFormat1
          push offset _Handler
          push fs:[0]
          mov fs:[0],esp

          ;检测PE文件是否有效
          mov esi,@lpMemory1
          assume esi:ptr IMAGE_DOS_HEADER
          .if [esi].e_magic!=IMAGE_DOS_SIGNATURE  ;判断是否有MZ字样
            jmp _ErrFormat1
          .endif
          add esi,[esi].e_lfanew    ;调整ESI指针指向PE文件头
          assume esi:ptr IMAGE_NT_HEADERS
          .if [esi].Signature!=IMAGE_NT_SIGNATURE ;判断是否有PE字样
            jmp _ErrFormat1
          .endif
        .endif
      .endif
    .endif
  .endif

  ;到此为止，两个内存文件的指针已经获取到了。@lpMemory和@lpMemory1分别指向两个文件头
  ;下面是从这个文件头开始，找出各数据结构的字段值，进行比较。


  ;获取补丁文件数据段的大小
  invoke getDataSize,@lpMemory
  mov dwPatchDataSize,eax

  .if eax==0  ;未找到存放数据的节
    invoke _appendInfo,addr szErr110
  .else
    invoke wsprintf,addr szBuffer,addr szOut11,eax
    invoke _appendInfo,addr szBuffer
  .endif



  ;获取补丁文件数据段在内存中的起始位置
  invoke getDataStart,@lpMemory
  mov dwPatchDataStart,eax

  invoke wsprintf,addr szBuffer,addr szOut12,eax
  invoke _appendInfo,addr szBuffer

  ;获取目标文件数据段的大小
  invoke getDataSize,@lpMemory1
  mov dwDstDataSize,eax

  invoke wsprintf,addr szBuffer,addr szOut13,eax
  invoke _appendInfo,addr szBuffer

  ;获取目标文件数据段在内存中的起始位置
  invoke getDataStart,@lpMemory1
  mov dwDstDataStart,eax

  invoke wsprintf,addr szBuffer,addr szOut14,eax
  invoke _appendInfo,addr szBuffer

  ;获取目标文件数据段在文件中对齐后的大小
  invoke getRawDataSize,@lpMemory1
  mov dwDstRawDataSize,eax

  invoke wsprintf,addr szBuffer,addr szOut15,eax
  invoke _appendInfo,addr szBuffer

  ;获取目标数据段在内存中的起始位置
  invoke getDataStartInMem,@lpMemory1
  mov dwDstMemDataStart,eax

  invoke wsprintf,addr szBuffer,addr szOut17,eax
  invoke _appendInfo,addr szBuffer


  ;从本节的最后一个位置起往前查找连续的全0字符
  mov eax,dwDstDataStart
  add eax,dwDstRawDataSize  ;定位到本节的最后一个字节
  mov ecx,dwPatchDataSize
  mov esi,@lpMemory1
  add esi,eax
  dec esi
  .repeat
    mov bl,byte ptr[esi]
    .break .if bl!=0
    dec esi
    dec ecx
    dec eax
    .break .if ecx==0
  .until FALSE
  .if ecx==0  ;表示找到了连续可用的空间
    mov @dwTemp1,eax
    sub eax,dwPatchDataSize
    mov dwStartAddressinDstDS,eax

    mov @dwTemp,0

    mov esi,@lpMemory1
    mov eax,dwDstDataStart
    add eax,dwDstRawDataSize  ;定位到本节的最后一个字节
    add esi,eax
    dec esi
    .repeat
      mov bl,byte ptr [esi]
      .break .if bl!=0
      inc @dwTemp
      dec esi
    .until FALSE
    
    invoke wsprintf,addr szBuffer,addr szOut16,@dwTemp,@dwTemp1
    invoke _appendInfo,addr szBuffer
  .else       ;数据段空间不够
    invoke _appendInfo,addr szErr11
  .endif

  invoke _appendInfo,addr szoutLine

  ;调整ESI,EDI指向DOS头
  mov esi,@lpMemory
  assume esi:ptr IMAGE_DOS_HEADER
  mov edi,@lpMemory1
  assume edi:ptr IMAGE_DOS_HEADER

  add edi,[edi].e_lfanew    ;调整ESI指针指向PE文件头
  assume edi:ptr IMAGE_NT_HEADERS
  ;取程序装载地址
  add edi,4
  add edi,sizeof IMAGE_FILE_HEADER
  assume edi:ptr IMAGE_OPTIONAL_HEADER32
  mov eax,[edi].ImageBase
  mov ebx,[edi].AddressOfEntryPoint
  invoke wsprintf,addr szBuffer,addr szOut18,eax,ebx
  invoke _appendInfo,addr szBuffer


  jmp _ErrorExit  ;正常退出

_ErrFormat:
          invoke MessageBox,hWinMain,offset szErrFormat,NULL,MB_OK
_ErrorExit:
          pop fs:[0]
          add esp,0ch
          invoke UnmapViewOfFile,@lpMemory
          invoke CloseHandle,@hMapFile
          invoke CloseHandle,@hFile
          jmp @F
_ErrFormat1:
          invoke MessageBox,hWinMain,offset szErrFormat,NULL,MB_OK
_ErrorExit1:
          pop fs:[0]
          add esp,0ch
          invoke UnmapViewOfFile,@lpMemory1
          invoke CloseHandle,@hMapFile1
          invoke CloseHandle,@hFile1
@@:        
  ret
_OpenFile endp
;-------------------
; 窗口程序
;-------------------
_ProcDlgMain proc uses ebx edi esi hWnd,wMsg,wParam,lParam
  mov eax,wMsg
  .if eax==WM_CLOSE
    invoke EndDialog,hWnd,NULL
  .elseif eax==WM_INITDIALOG  ;初始化
    push hWnd
    pop hWinMain
    call _init
  .elseif eax==WM_COMMAND     ;菜单
    mov eax,wParam
    .if eax==IDM_EXIT       ;退出
      invoke EndDialog,hWnd,NULL 
    .elseif eax==IDM_OPEN   ;打开文件
      invoke _OpenFile

    .elseif eax==IDM_1  

    .elseif eax==IDM_2

    .elseif eax==IDM_3

    .endif
  .else
    mov eax,FALSE
    ret
  .endif
  mov eax,TRUE
  ret
_ProcDlgMain endp

start:
  invoke LoadLibrary,offset szDllEdit
  mov hRichEdit,eax
  invoke GetModuleHandle,NULL
  mov hInstance,eax
  invoke DialogBoxParam,hInstance,\
         DLG_MAIN,NULL,offset _ProcDlgMain,NULL
  invoke FreeLibrary,hRichEdit
  invoke ExitProcess,NULL
  end start



