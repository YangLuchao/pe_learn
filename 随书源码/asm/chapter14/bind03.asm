;-------------------------------------------
; 将patch.ext补丁程序插入到指定exe文件中首先运行
; 主要演示如何使用程序修改PE文件格式，从而完成想
; 要实现的功能
; 03-只分析代码
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

dwPatchCodeSegSize      dd ?  ;补丁代码所在段的大小
dwPatchCodeSegStart     dd ?  ;补丁代码所在段的起始地址
dwDstCodeSegSize        dd ?  ;目标代码所在段大小
dwDstCodeSegStart       dd ?  ;目标代码所在段数据起始地址
dwDstCodeSegRawSize     dd ?  ;目标代码所在段数据在文件中对齐后的大小
dwPatchCodeSize         dd ?  ;补丁代码大小
dwDstCodeSize           dd ?  ;目标代码大小
dwPatchCodeSegMemStart  dd ?  ;补丁代码所在段数据在内存的起始地址
dwDstCodeSegMemStart    dd ?  ;目标代码所在段数据在内存的起始地址
dwModiCommandCount      dd ?  ;补丁代码中要修正的地址个数

dwImageBase             dd ?  ;程序装载的基地址。

dwNewCodeSize           dd ?  ;生成的新文件的代码大小  ！！！！！！！这个大小是判断空间够用与否的主要字段
dwPatchDLLCount           dd ?  ;补丁程序中调用DLL的个数
dwDstDLLCount             dd ?  ;目标程序中调用DLL的个数



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
szErr30      db '>> 未找到可存放数据的节！',0dh,0ah,0
szErr31      db '>> 目标段空间不够，不足以容纳补丁代码及相关数据！',0dh,0ah,0

szOut331      db '补丁代码所在段的大小为：%08x',0dh,0ah,0
szOut332      db '补丁代码所在段在文件中的起始位置：%08x',0dh,0ah,0
szOut33      db '目标代码所在段的大小为：%08x',0dh,0ah,0
szOut34      db '目标代码所在段在文件中的起始位置：%08x',0dh,0ah,0
szOut35      db '目标代码所在段在文件中对齐后的大小：%08x',0dh,0ah,0
szOut36      db '目标文件的代码所处的段中有空间。剩余空间大小为:%08x,合并以后的代码在段中的起始位置为：%08x',0dh,0ah,0
szOut37      db '补丁代码在内存中的起始位置：%08x',0dh,0ah,0
szOut38      db '目标代码在内存中的起始位置：%08x',0dh,0ah,0
szOut39      db '补丁程序装载基地址：%08x',0dh,0ah,0
szOut3310     db '补丁代码指令操作数地址需要修正的个数：%08x',0dh,0ah,0
szOut3311     db '补丁代码指令操作数地址需要修正列表：',0dh,0ah,0
szOut3312     db '目标程序调用动态链接库及每个动态链接库调用函数个数明细：',0dh,0ah,0
szOut3313     db '文件偏移：%08x   指令：%xh     操作数：%08x',0dh,0ah,0
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

    ;invoke wsprintf,addr szBuffer,addr szOut332,edx
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
; 将文件偏移内转换为存偏移量RVA
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
; 取代码所在节在文件中对齐以后的大小
; _lpHeader指向内存中PE文件的起始
; 返回值在eax中
;-------------------
getCodeSegRawSize proc _lpHeader
   local @dwSize
   pushad
   
   mov esi,_lpHeader
   assume esi:ptr IMAGE_DOS_HEADER
   add esi,[esi].e_lfanew    ;调整ESI指针指向PE文件头
   assume esi:ptr IMAGE_NT_HEADERS
   mov eax,[esi].OptionalHeader.AddressOfEntryPoint

   invoke _getRVASectionRawSize,_lpHeader,eax
   mov @dwSize,eax   
   popad
   mov eax,@dwSize
   ret
getCodeSegRawSize endp

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
; 获取基地址
;-------------------------
getImageBase  proc  _lpFile
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
   mov eax,[edi].ImageBase
   mov @ret,eax
   popad
   mov eax,@ret
   ret
getImageBase endp

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

;------------------------------
;修正68h指令代码的操作数
;入口：edi指向代码开始  ecx代码长度
;出口：eax要修正的操作数个数
;------------------------------
get_68h  proc _lpFile
   local @value
   local @ret
   pushad
   mov @ret,0
   .repeat
     mov bl,byte ptr [edi]
     .if bl==68h
       ;取其后的一个字   68 43 02 04 00
       mov ebx,dword ptr [edi+1]
       mov @value,ebx
       and ebx,0ffff0000h
       ;判断该双字是否以ImageBase开始
       mov edx,dwImageBase
       and edx,0FFFF0000h
       .if ebx==edx
         mov ebx,edi
         sub ebx,_lpFile
         mov edx,68h
         push ecx
         invoke wsprintf,addr szBuffer,addr szOut3313,ebx,edx,@value
         invoke _appendInfo,addr szBuffer
         pop ecx
         inc @ret
       .endif
     .endif
     dec ecx
     .break .if ecx==0
     inc edi
   .until FALSE

   popad
   mov eax,@ret
   ret
get_68h  endp
;------------------------------
;修正FF 25指令代码的操作数
;入口：edi指向代码开始  ecx代码长度
;出口：eax要修正的操作数个数
;------------------------------
get_FF25h  proc _lpFile
   local @value
   local @ret
   pushad
   mov @ret,0
   .repeat
     mov bx,word ptr [edi]
     .if bx==25FFh
       ;取其后的一个字   FF 25 43 02 04 00
       mov ebx,dword ptr [edi+2]
       mov @value,ebx
       and ebx,0ffff0000h
       ;判断该双字是否以ImageBase开始
       mov edx,dwImageBase
       and edx,0FFFF0000h
       .if ebx==edx
         mov ebx,edi
         sub ebx,_lpFile
         mov edx,25FFh
         push ecx
         invoke wsprintf,addr szBuffer,addr szOut3313,ebx,edx,@value
         invoke _appendInfo,addr szBuffer         
         pop ecx
         inc @ret
       .endif
     .endif

     dec ecx
     .break .if ecx==0
     inc edi
   .until FALSE
   popad
   mov eax,@ret
   ret
get_FF25h  endp
;------------------------------
;修正FF 35指令代码的操作数
;入口：edi指向代码开始  ecx代码长度
;出口：eax要修正的操作数个数
;------------------------------
get_FF35h  proc _lpFile
   local @value
   local @ret
   pushad
   mov @ret,0
   .repeat
     mov bx,word ptr [edi]
     .if bx==35FFh
       ;取其后的一个字   FF 25 43 02 04 00
       mov ebx,dword ptr [edi+2]
       mov @value,ebx
       and ebx,0ffff0000h
       ;判断该双字是否以ImageBase开始
       mov edx,dwImageBase
       and edx,0FFFF0000h
       .if ebx==edx
         mov ebx,edi
         sub ebx,_lpFile
         mov edx,35FFh
         push ecx
         invoke wsprintf,addr szBuffer,addr szOut3313,ebx,edx,@value
         invoke _appendInfo,addr szBuffer    
         pop ecx
         inc @ret
       .endif
     .endif

     dec ecx
     .break .if ecx==0
     inc edi
   .until FALSE
   popad
   mov eax,@ret
   ret
get_FF35h  endp
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

 
  ;获取补丁代码所在节的大小
  invoke getCodeSegSize,@lpMemory
  mov dwPatchCodeSegSize,eax

  invoke wsprintf,addr szBuffer,addr szOut331,eax
  invoke _appendInfo,addr szBuffer

  ;获取补丁代码所在节在文件中的起始位置
  invoke getCodeSegStart,@lpMemory
  mov dwPatchCodeSegStart,eax

  invoke wsprintf,addr szBuffer,addr szOut332,eax
  invoke _appendInfo,addr szBuffer

  ;获取补丁代码所在节在内存中的起始位置
  invoke _OffsetToRVA,@lpMemory,dwPatchCodeSegStart
  mov dwPatchCodeSegMemStart,eax

  invoke wsprintf,addr szBuffer,addr szOut37,eax
  invoke _appendInfo,addr szBuffer



  ;获取目标代码所在节的大小
  invoke getCodeSegSize,@lpMemory1
  mov dwDstCodeSegSize,eax

  invoke wsprintf,addr szBuffer,addr szOut33,eax
  invoke _appendInfo,addr szBuffer

  ;获取目标代码所在节在文件中的起始位置
  invoke getCodeSegStart,@lpMemory1
  mov dwDstCodeSegStart,eax

  invoke wsprintf,addr szBuffer,addr szOut34,eax
  invoke _appendInfo,addr szBuffer

  ;获取目标代码所在节的大小
  invoke getCodeSegRawSize,@lpMemory1
  mov dwDstCodeSegRawSize,eax

  invoke wsprintf,addr szBuffer,addr szOut35,eax
  invoke _appendInfo,addr szBuffer


  ;获取目标代码所在节在内存中的起始位置
  invoke _OffsetToRVA,@lpMemory,dwDstCodeSegStart
  mov dwDstCodeSegMemStart,eax

  invoke wsprintf,addr szBuffer,addr szOut38,eax
  invoke _appendInfo,addr szBuffer



  ;从目标代码所在节的最后一个位置起往前查找连续的全0字符
  mov eax,dwDstCodeSegStart
  add eax,dwDstCodeSegRawSize  ;定位到本节的最后一个字节
  mov ecx,dwPatchCodeSegSize   ;补丁代码的长度
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
    mov eax,dwDstCodeSegStart
    add eax,dwDstCodeSegRawSize  ;定位到本节的最后一个字节    
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

    invoke wsprintf,addr szBuffer,addr szOut36,@dwTemp,@dwTemp1
    invoke _appendInfo,addr szBuffer

  .else       ;代码段空间不够
    invoke _appendInfo,addr szErr31
  .endif


  ;获取补丁程序装载基地址
  invoke getImageBase,@lpMemory
  mov dwImageBase,eax
  invoke wsprintf,addr szBuffer,addr szOut39,eax
  invoke _appendInfo,addr szBuffer

  invoke _appendInfo,addr szCrLf

  mov edi,@lpMemory   ;首先修正68h指令
  invoke getEntryPoint,@lpMemory
  invoke _RVAToOffset,@lpMemory,eax
  add edi,eax
  mov ecx,dwPatchCodeSegSize
  invoke get_68h,@lpMemory    ;修正代码后的操作数地址  
  mov dwModiCommandCount,eax

  mov edi,@lpMemory   ;其次修正FF 25指令
  invoke getEntryPoint,@lpMemory
  invoke _RVAToOffset,@lpMemory,eax
  add edi,eax
  mov ecx,dwPatchCodeSegSize
  invoke get_FF25h,@lpMemory
  add dwModiCommandCount,eax

  mov edi,@lpMemory   ;最后修正FF 35指令
  invoke getEntryPoint,@lpMemory
  invoke _RVAToOffset,@lpMemory,eax
  add edi,eax
  mov ecx,dwPatchCodeSegSize
  invoke get_FF35h,@lpMemory
  add dwModiCommandCount,eax

  
  invoke wsprintf,addr szBuffer,addr szOut3310,dwModiCommandCount
  invoke _appendInfo,addr szBuffer  



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



