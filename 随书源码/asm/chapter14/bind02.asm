;-------------------------------------------
; 将patch.ext补丁程序插入到指定exe文件中首先运行
; 主要演示如何使用程序修改PE文件格式，从而完成想
; 要实现的功能
; 02-只分析导入表
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

dwFunctions db 1024 dup(11h)  ;记录每个动态链接库引用的函数个数。
                                         ;个数,个数，个数，0
szBuffer1   db 1024 dup(0)
szBuffer2   db 1024 dup(0)
bufTemp1         db  200 dup(0),0
bufTemp2         db  200 dup(0),0

dwPatchImportSegSize      dd ?  ;补丁导入表所在段的大小
dwPatchImportSegStart     dd ?  ;补丁导入表所在段的起始地址
dwDstImportSegSize        dd ?  ;目标导入表所在段大小
dwDstImportSegStart       dd ?  ;目标导入表所在段数据起始地址
dwDstImportSegRawSize     dd ?  ;目标导入表所在段数据在文件中对齐后的大小
dwPatchImportSize         dd ?  ;补丁导入表大小
dwDstImportSize           dd ?  ;目标导入表大小
dwNewImportSize           dd ?  ;生成的新文件的导入表大小  ！！！！！！！这个大小是判断空间够用与否的主要字段
dwPatchDLLCount           dd ?  ;补丁程序中调用DLL的个数
dwDstDLLCount             dd ?  ;目标程序中调用DLL的个数



;dwDstMemDataStart         dd ?  ;目标导入表所在段在内存中的起始地址
;dwStartAddressinDstRS     dd ?  ;新增加的补丁导入表所在段的数据在目标文件中的起始位置



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
szErr20      db '>> 未找到可存放数据的节！',0dh,0ah,0
szErr21      db '>> 目标段空间不够，不足以容纳补丁导入表及相关数据！',0dh,0ah,0

szOut221      db '补丁导入表所在段的大小为：%08x',0dh,0ah,0
szOut22      db '补丁导入表所在段在文件中的起始位置：%08x',0dh,0ah,0
szOut23      db '目标导入表所在段的大小为：%08x',0dh,0ah,0
szOut24      db '目标导入表所在段在文件中的起始位置：%08x',0dh,0ah,0
szOut25      db '目标导入表所在段在文件中对齐后的大小：%08x',0dh,0ah,0
szOut26      db '目标文件的导入表所处的段中有空间。剩余空间大小为:%08x,合并以后的导入表在段中的起始位置为：%08x',0dh,0ah,0
szOut27      db '补丁程序调用链接库个数：%08x',0dh,0ah,0
szOut28      db '补丁程序调用函数个数：%08x',0dh,0ah,0
szOut29      db '补丁程序调用动态链接库及每个动态链接库调用函数个数明细：',0dh,0ah,0
szOut2210     db '目标程序调用链接库个数：%08x',0dh,0ah,0
szOut2211     db '目标程序调用函数个数：%08x',0dh,0ah,0
szOut2212     db '目标程序调用动态链接库及每个动态链接库调用函数个数明细：',0dh,0ah,0

szCrLf      db 0dh,0ah,0

szOut       db '%08x',0
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

;--------------------------
; 将bufTemp2位置处_dwSize个字节转换为16进制的字符串
; bufTemp1处为转换后的字符串
;--------------------------
_Byte2Hex     proc _dwSize
  local @dwSize:dword

  pushad
  mov esi,offset bufTemp2
  mov edi,offset bufTemp1
  mov @dwSize,0
  .repeat
    mov al,byte ptr [esi]

    mov bl,al
    xor edx,edx
    xor eax,eax
    mov al,bl
    mov cx,16
    div cx   ;结果高位在al中，余数在dl中


    xor bx,bx
    mov bl,al
    movzx edi,bx
    mov bl,byte ptr lpszHexArr[edi]
    mov eax,@dwSize
    mov byte ptr bufTemp1[eax],bl


    inc @dwSize

    xor bx,bx
    mov bl,dl
    movzx edi,bx

    ;invoke wsprintf,addr szBuffer,addr szOut22,edx
    ;invoke MessageBox,NULL,addr szBuffer,NULL,MB_OK

    mov bl,byte ptr lpszHexArr[edi]
    mov eax,@dwSize
    mov byte ptr bufTemp1[eax],bl

    inc @dwSize
    mov bl,20h
    mov eax,@dwSize
    mov byte ptr bufTemp1[eax],bl
    inc @dwSize
    inc esi
    dec _dwSize
    .break .if _dwSize==0
   .until FALSE

   mov bl,0
   mov eax,@dwSize
   mov byte ptr bufTemp1[eax],bl

   popad
   ret
_Byte2Hex    endp
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
  mov eax,offset szNotFound
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
  mov eax,offset szNotFound
@@:
  mov @dwReturn,eax
  popad
  mov eax,@dwReturn
  ret
_getRVASectionSize  endp

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
  mov eax,offset szNotFound
@@:
  mov @dwReturn,eax
  popad
  mov eax,@dwReturn
  ret
_getRVASectionRawSize  endp
;-------------------
; 取导入表所在节的大小
; 数据段定位方法：
; 只要节的标识第6,30,31位为1，则表示符合要求
; _lpHeader指向内存中PE文件的起始
; 返回值在eax中
;-------------------
getImportSegSize proc _lpHeader
   local @dwSize
   pushad
   
   mov esi,_lpHeader
   assume esi:ptr IMAGE_DOS_HEADER
   add esi,[esi].e_lfanew    ;调整ESI指针指向PE文件头
   assume esi:ptr IMAGE_NT_HEADERS
   mov eax,[esi].OptionalHeader.DataDirectory[8].VirtualAddress

   invoke _getRVASectionSize,_lpHeader,eax
   mov @dwSize,eax   
   popad
   mov eax,@dwSize
   ret
getImportSegSize endp

;-------------------
; 取导入表所在节在文件中对齐以后的大小
; 数据段定位方法：
; 只要节的标识第6,30,31位为1，则表示符合要求
; _lpHeader指向内存中PE文件的起始
; 返回值在eax中
;-------------------
getImportSegRawSize proc _lpHeader
   local @dwSize
   pushad
   
   mov esi,_lpHeader
   assume esi:ptr IMAGE_DOS_HEADER
   add esi,[esi].e_lfanew    ;调整ESI指针指向PE文件头
   assume esi:ptr IMAGE_NT_HEADERS
   mov eax,[esi].OptionalHeader.DataDirectory[8].VirtualAddress

   invoke _getRVASectionRawSize,_lpHeader,eax
   mov @dwSize,eax   
   popad
   mov eax,@dwSize
   ret
getImportSegRawSize endp

;-------------------
; 取补丁导入表所在节的大小
; 数据段定位方法：
; 只要节的标识第6,30,31位为1，则表示符合要求
; _lpHeader指向内存中PE文件的起始
; 返回值在eax中
;-------------------
getImportSegStart proc _lpHeader
   local @dwStart
   pushad
   
   mov esi,_lpHeader
   assume esi:ptr IMAGE_DOS_HEADER
   add esi,[esi].e_lfanew    ;调整ESI指针指向PE文件头
   assume esi:ptr IMAGE_NT_HEADERS
   mov eax,[esi].OptionalHeader.DataDirectory[8].VirtualAddress
   invoke _getRVASectionStart,_lpHeader,eax
   mov @dwStart,eax   
   popad
   mov eax,@dwStart
   ret
getImportSegStart endp

;---------------------------------
; 获取PE文件的导入表调用的函数个数
;---------------------------------
_getImportFunctions proc _lpFile
  local @szBuffer[1024]:byte
  local @szSectionName[16]:byte
  local _lpPeHead
  local @dwDlls,@dwFuns,@dwFunctions
  
  pushad
  mov edi,_lpFile
  assume edi:ptr IMAGE_DOS_HEADER
  add edi,[edi].e_lfanew    ;调整ESI指针指向PE文件头
  assume edi:ptr IMAGE_NT_HEADERS
  mov eax,[edi].OptionalHeader.DataDirectory[8].VirtualAddress
  .if !eax
    jmp @F
  .endif
  invoke _RVAToOffset,_lpFile,eax
  add eax,_lpFile
  mov edi,eax     ;计算引入表所在文件偏移位置
  assume edi:ptr IMAGE_IMPORT_DESCRIPTOR
  invoke _getRVASectionName,_lpFile,[edi].OriginalFirstThunk

  mov @dwFuns,0
  mov @dwFunctions,0
  mov @dwDlls,0

  .while [edi].OriginalFirstThunk || [edi].TimeDateStamp ||\
         [edi].ForwarderChain || [edi].Name1 || [edi].FirstThunk
    mov @dwFuns,0
    invoke _RVAToOffset,_lpFile,[edi].Name1
    add eax,_lpFile

    ;获取IMAGE_THUNK_DATA列表到EBX
    .if [edi].OriginalFirstThunk
      mov eax,[edi].OriginalFirstThunk
    .else
      mov eax,[edi].FirstThunk
    .endif
    invoke _RVAToOffset,_lpFile,eax
    add eax,_lpFile
    mov ebx,eax
    .while dword ptr [ebx]
      inc @dwFuns 
      inc @dwFunctions
      .if dword ptr [ebx] & IMAGE_ORDINAL_FLAG32 ;按序号导入
        mov eax,dword ptr [ebx]
        and eax,0ffffh
      .else                                      ;按名称导入
        invoke _RVAToOffset,_lpFile,dword ptr [ebx]
        add eax,_lpFile
        assume eax:ptr IMAGE_IMPORT_BY_NAME
        movzx ecx,[eax].Hint
        assume eax:nothing
      .endif
      add ebx,4
    .endw
    mov eax,@dwFuns
    mov ebx,@dwDlls
    mov dword ptr dwFunctions[ebx*4],eax
    mov dword ptr dwFunctions[ebx*4+4],0
    inc @dwDlls
    add edi,sizeof IMAGE_IMPORT_DESCRIPTOR
  .endw
  mov ebx,@dwDlls
  mov dword ptr dwFunctions[ebx*4],0
@@:
  assume edi:nothing
  popad
  mov eax,@dwDlls
  mov ebx,@dwFunctions
  ret
_getImportFunctions endp


;-----------------------
; 获取导入表大小，含全0结构
;-----------------------
getImportSize  proc  _lpFile
  local @dwTemp:dword
  pushad
  invoke _getImportFunctions,_lpFile
  add eax,1
  mov edx,0
  mov bx,14h
  mul bx
  mov @dwTemp,eax  

  popad
  mov eax,@dwTemp
  ret
getImportSize  endp

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

 
  ;获取补丁导入表所在节的大小
  invoke getImportSegSize,@lpMemory
  mov dwPatchImportSegSize,eax

  invoke wsprintf,addr szBuffer,addr szOut221,eax
  invoke _appendInfo,addr szBuffer

  ;获取补丁导入表所在节在文件中的起始位置
  invoke getImportSegStart,@lpMemory
  mov dwPatchImportSegStart,eax

  invoke wsprintf,addr szBuffer,addr szOut22,eax
  invoke _appendInfo,addr szBuffer
  ;获取目标导入表所在节的大小
  invoke getImportSegSize,@lpMemory1
  mov dwDstImportSegSize,eax

  invoke wsprintf,addr szBuffer,addr szOut23,eax
  invoke _appendInfo,addr szBuffer

  ;获取目标导入表所在节在文件中的起始位置
  invoke getImportSegStart,@lpMemory1
  mov dwDstImportSegStart,eax

  invoke wsprintf,addr szBuffer,addr szOut24,eax
  invoke _appendInfo,addr szBuffer

  ;获取目标导入表所在节的大小
  invoke getImportSegRawSize,@lpMemory1
  mov dwDstImportSegRawSize,eax

  invoke wsprintf,addr szBuffer,addr szOut25,eax
  invoke _appendInfo,addr szBuffer


  ;获取补丁导入表dll库个数和functions个数
  invoke _getImportFunctions,@lpMemory
  mov dwPatchDLLCount,eax
  invoke wsprintf,addr szBuffer,addr szOut27,eax
  invoke _appendInfo,addr szBuffer
  invoke wsprintf,addr szBuffer,addr szOut28,ebx
  invoke _appendInfo,addr szBuffer

  ;显示每个动态链接库的函数个数：
  invoke _appendInfo,addr szOut29
  invoke MemCopy,addr dwFunctions,addr bufTemp2,40
  invoke _Byte2Hex,40
  invoke _appendInfo,addr bufTemp1
  invoke _appendInfo,addr szCrLf

  ;获取目标导入表dll库个数和functions个数
  invoke _getImportFunctions,@lpMemory1
  mov dwDstDLLCount,eax

  invoke wsprintf,addr szBuffer,addr szOut2210,eax
  invoke _appendInfo,addr szBuffer
  invoke wsprintf,addr szBuffer,addr szOut2211,ebx
  invoke _appendInfo,addr szBuffer

  ;显示每个动态链接库的函数个数：
  invoke _appendInfo,addr szOut2212
  invoke MemCopy,addr dwFunctions,addr bufTemp2,40
  invoke _Byte2Hex,40
  invoke _appendInfo,addr bufTemp1
  invoke _appendInfo,addr szCrLf


  ;求连接生成的新文件的导入表大小
  invoke getImportSize,@lpMemory   ;补丁导入表大小
  mov dwPatchImportSize,eax
  invoke getImportSize,@lpMemory1  ;目标文件导入表大小
  mov dwDstImportSize,eax
  add eax,dwPatchImportSize
  sub eax,14h                      ;新文件导入表大小在eax中
  mov dwNewImportSize,eax

  ;invoke wsprintf,addr szBuffer,addr szOut,ecx
  ;invoke _appendInfo,addr szBuffer


  ;从目标导入表所在节的最后一个位置起往前查找连续的全0字符
  mov eax,dwDstImportSegStart
  add eax,dwDstImportSegRawSize  ;定位到本节的最后一个字节
  mov ecx,dwNewImportSize
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
    mov @dwTemp,0
    mov @dwTemp1,eax
    mov eax,dwDstImportSegStart
    add eax,dwDstImportSegRawSize  ;定位到本节的最后一个字节    
    mov esi,@lpMemory1
    add esi,eax
    dec esi
    .repeat
      mov bl,byte ptr [esi]
      .break .if bl!=0
      inc @dwTemp
      dec esi
      dec eax
    .until FALSE

    invoke wsprintf,addr szBuffer,addr szOut26,@dwTemp,@dwTemp1
    invoke _appendInfo,addr szBuffer

  .else       ;导入表段空间不够
    invoke _appendInfo,addr szErr21
  .endif





  ;


  invoke _appendInfo,addr szoutLine


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



