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
include    winResult.inc
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
includelib winResult.lib


ICO_MAIN equ 1000
DLG_MAIN equ 1000
IDC_INFO equ 1001
IDM_MAIN equ 2000
IDM_OPEN equ 2001
IDM_EXIT equ 2002
IDM_1    equ 4000
IDM_2    equ 4001
IDM_3    equ 4002
RESULT_MODULE   equ 5000
ID_TEXT1        equ 5001
ID_TEXT2        equ 5002
IDC_MODULETABLE equ 5003
IDC_OK          equ 5004
ID_STATIC       equ 5005
ID_STATIC1      equ 5006
IDC_BROWSE1     equ 5007
IDC_BROWSE2     equ 5008
IDC_THESAME     equ 5009


.data
hInstance   dd ?
hRichEdit   dd ?
hWinMain    dd ?
hWinEdit    dd ?
dwCount     dd ?
dwColorRed  dd ?
hText1      dd ?
hText2      dd ?
hFile       dd ?

dwPatchCodeSize   dd  ?     ;补丁代码大小
dwNewFileSize     dd  ?     ;新文件大小=目标文件大小+补丁代码大小
dwNewPatchCodeSize  dd ?    ;补丁代码按8位对齐后的大小
dwPatchCodeSegStart  dd ?   ;补丁代码所在节在文件中的起始地址
dwSections           dd ?   ;所有节表大小
dwNewHeaders         dd ?   ;新文件头的大小
dwFileAlign          dd ?   ;文件对齐粒度
dwFirstSectionStart  dd ?   ;目标文件第一节距离文件起始的偏移量
dwOff                dd ?   ;新文件比原来多出来的部分
dwValidHeadSize      dd ?   ;目标文件PE头的有效数据长度
dwHeaderSize         dd ?   ;文件头长度
dwBlock1             dd ?   ;原PE头的有效数据长度+补丁代码的有效数据长度
dwPE_SECTIONSize     dd ?   ;PE头+节表大小



dwDstEntryPoint      dd ?   ;旧的入口地址
dwNewEntryPoint      dd ?   ;新的入口地址

lpPatchPE         dd  ?   ;补丁程序的PE标志在文件中的位置，因为从0开始，所以这个位置也是DOS头的大小
lpDstMemory       dd  ?   ;内存中存放新文件数据的起始地址
lpOthers          dd  ?   ;其他数据在文件中的起始位置


hProcessModuleTable dd ?


szFileName           db MAX_PATH dup(?)
szDstFile            db 'c:\bindA.exe',0
szFileNameOpen1      db 'd:\masm32\source\chapter12\patch1.exe',MAX_PATH dup(0)
szFileNameOpen2      db 'c:\helloworld.exe',MAX_PATH dup(0)

                     ;d:\masm32\source\chapter12\HelloWorld.exe

szResultColName1 db  'PE数据结构相关字段',0
szResultColName2 db  '文件1的值(H)',0
szResultColName3 db  '文件2的值(H)',0
szBuffer         db  256 dup(0),0
bufTemp1         db  200 dup(0),0
bufTemp2         db  200 dup(0),0
szFilter1        db  'Excutable Files',0,'*.exe;*.com',0
                 db  0

.const
szDllEdit   db 'RichEd20.dll',0
szClassEdit db 'RichEdit20A',0
szFont      db '宋体',0
szExtPe     db 'PE File',0,'*.exe;*.dll;*.scr;*.fon;*.drv',0
            db 'All Files(*.*)',0,'*.*',0,0
szErr       db '文件格式错误!',0
szErrFormat db '这个文件不是PE格式的文件!',0
szSuccess   db '恭喜你，程序执行到这里是成功的。',0
szNotFound  db '无法查找',0

szCrLf      db 0dh,0ah,0

szOut100       db '补丁代码段大小：%08x',0dh,0ah,0
szOut104       db '空隙一的大小为：%08x',0dh,0ah,0
szOut101       db '目标PE文件的DOS头大小为：%08x ',0dh,0ah,0
szOut102       db '补丁代码在目标文件中的文件偏移量为：%08x',0dh,0ah,0
szOut103       db '新文件的PE头所处的位置在新文件偏移：%08x处',0dh,0ah,0
szOut105       db '原文件大小为：%08x   加补丁后的新文件的大小为：%08x',0dh,0ah,0
szOut106       db '目标PE的入口地址为：%08x',0dh,0ah,0
szOut107       db '节中需要修正的文件偏移地址如下：',0dh,0ah,0
szOut108       db '   节名：%s     原始偏移：%08x     修正后的偏移：%08x',0dh,0ah,0
szOut109       db '新文件的PE头实际大小为：%08x',0dh,0ah,0
szOut110       db '节表后的数据位于文件的偏移：%08x',0dh,0ah,0
szOut111       db '目标程序所有节表占用的字节数：%08x',0dh,0ah,0
szOut112       db '补丁代码中的E9指令后的操作数修正为：%08x',0dh,0ah,0
szOut113       db '目标PE头的数据的有效长度为:%08x',0dh,0ah,0

szOut1      db '补丁程序：%s',0dh,0ah,0
szOut2      db '目标PE程序：%s',0dh,0ah,0
szOutErr    db '代码段长度大于0DA8h，空隙一的空间不足！',0dh,0ah,0
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


;--------------------------------------
; 获取目标PE头的数据的有效长度
;--------------------------------------
getValidHeadSize proc _lpFileHead
  local @dwReturn
  local @dwTemp
  
  pushad
  mov esi,_lpFileHead
  assume esi:ptr IMAGE_DOS_HEADER
  add esi,[esi].e_lfanew
  assume esi:ptr IMAGE_NT_HEADERS
  mov edx,esi
  add edx,sizeof IMAGE_NT_HEADERS
  assume edx:ptr IMAGE_SECTION_HEADER
  mov eax,[edx].PointerToRawData     ;指向第一个节的起始
  mov @dwTemp,eax

  dec eax
  mov esi,eax
  add esi,_lpFileHead
  mov @dwReturn,0
  .repeat
    mov bl,byte ptr [esi]
    .if bl!=0
      .break
    .endif
    dec esi
    inc @dwReturn
  .until FALSE
  mov eax,@dwTemp
  sub eax,@dwReturn
  add eax,2           ;为有效数据留出两个0字符，假如最后的有效数据为字符串，必须以0结束
  mov @dwReturn,eax

  popad
  mov eax,@dwReturn

  ret
getValidHeadSize endp

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

;------------------------------------------
; 打开输入文件
;------------------------------------------
_OpenFile1	proc
		local	@stOF:OPENFILENAME
		local	@stES:EDITSTREAM

                ;如果打开之前还有文件句柄存在，则先关闭再赋值                
                .if hFile
                   invoke CloseHandle,hFile
                   mov hFile,0
                .endif
                ; 显示“打开文件”对话框
		invoke	RtlZeroMemory,addr @stOF,sizeof @stOF
		mov	@stOF.lStructSize,sizeof @stOF
		push	hWinMain
		pop	@stOF.hwndOwner
                push    hInstance
                pop     @stOF.hInstance
		mov	@stOF.lpstrFilter,offset szFilter1
		mov	@stOF.lpstrFile,offset szFileNameOpen1
		mov	@stOF.nMaxFile,MAX_PATH
		mov	@stOF.Flags,OFN_FILEMUSTEXIST or\
                                    OFN_HIDEREADONLY or OFN_PATHMUSTEXIST
		invoke	GetOpenFileName,addr @stOF
		.if	eax
                        invoke SetWindowText,hText1,addr szFileNameOpen1
		.endif
                invoke wsprintf,addr szBuffer,addr szOut1,addr szFileNameOpen1
                invoke _appendInfo,addr szBuffer
		ret

_OpenFile1	endp
;------------------------------------------
; 打开输入文件
;------------------------------------------
_OpenFile2	proc
		local	@stOF:OPENFILENAME
		local	@stES:EDITSTREAM

                ;如果打开之前还有文件句柄存在，则先关闭再赋值                
                .if hFile
                   invoke CloseHandle,hFile
                   mov hFile,0
                .endif
                ; 显示“打开文件”对话框
		invoke	RtlZeroMemory,addr @stOF,sizeof @stOF
		mov	@stOF.lStructSize,sizeof @stOF
		push	hWinMain
		pop	@stOF.hwndOwner
                push    hInstance
                pop     @stOF.hInstance
		mov	@stOF.lpstrFilter,offset szFilter1
		mov	@stOF.lpstrFile,offset szFileNameOpen2
		mov	@stOF.nMaxFile,MAX_PATH
		mov	@stOF.Flags,OFN_FILEMUSTEXIST or\
                                    OFN_HIDEREADONLY or OFN_PATHMUSTEXIST
		invoke	GetOpenFileName,addr @stOF
		.if	eax
                        invoke SetWindowText,hText2,addr szFileNameOpen2
		.endif
                invoke wsprintf,addr szBuffer,addr szOut2,addr szFileNameOpen2
                invoke _appendInfo,addr szBuffer
                invoke _appendInfo,addr szCrLf
		ret

_OpenFile2	endp

;--------------------------
; 将_lpPoint位置处_dwSize个字节转换为16进制的字符串
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

    ;invoke wsprintf,addr szBuffer,addr szOut2,edx
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

_MemCmp  proc _lp1,_lp2,_size
   local @dwResult:dword

   pushad
   mov esi,_lp1
   mov edi,_lp2
   mov ecx,_size
   .repeat
     mov al,byte ptr [esi]
     mov bl,byte ptr [edi]
     .break .if al!=bl
     inc esi
     inc edi
     dec ecx
     .break .if ecx==0
   .until FALSE
   .if ecx!=0
     mov @dwResult,1
   .else 
     mov @dwResult,0
   .endif
   popad
   mov eax,@dwResult
   ret
_MemCmp  endp


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
;--------------
;
;--------------------
writeToFile proc _lpFile,_dwSize
  local @dwWritten
  pushad
  invoke CreateFile,addr szDstFile,GENERIC_WRITE,\
            FILE_SHARE_READ,\
                0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
  mov hFile,eax
  invoke WriteFile,hFile,_lpFile,_dwSize,addr @dwWritten,NULL
  invoke CloseHandle,hFile      
  popad
  ret
writeToFile endp

;-------------------------------------
; 改变目标PE节的文件偏移属性
;-------------------------------------
changeRawOffset proc _lpHeader0,_lpHeader
  local @dwSize,@dwSectionSize
  local @ret
  local @dwTemp,@dwTemp1
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

  

  mov edi,lpDstMemory
  assume edi:ptr IMAGE_DOS_HEADER
  add edi,[edi].e_lfanew    ;调整ESI指针指向PE文件头
  assume edi:ptr IMAGE_NT_HEADERS
   
  pushad
  invoke _appendInfo,addr szCrLf
  invoke _appendInfo,addr szOut107
  popad

  add edi,sizeof IMAGE_NT_HEADERS   ;edi指向节表位置
  .repeat
     assume edi:ptr IMAGE_SECTION_HEADER
     mov ebx,[edi].PointerToRawData  ;取节在文件中的偏移
     mov @dwTemp,ebx
     add ebx,dwOff      ;修正该值
     mov @dwTemp1,ebx
     mov dword ptr [edi].PointerToRawData,ebx

     ; 显示
     pushad
     mov eax,[edi].VirtualAddress
     inc eax
     invoke _getRVASectionName,_lpHeader,eax
     invoke wsprintf,addr szBuffer,addr szOut108,eax,@dwTemp,@dwTemp1
     invoke _appendInfo,addr szBuffer 
     popad  

     dec @dwSectionSize
     add edi,sizeof IMAGE_SECTION_HEADER
     .break .if @dwSectionSize==0
  .until FALSE
   

  popad 
  ret
changeRawOffset  endp

;--------------------
; 打开PE文件并处理
;--------------------
_openFile proc
  local @stOF:OPENFILENAME
  local @hFile,@dwFileSize,@hMapFile,@lpMemory
  local @hFile1,@dwFileSize1,@hMapFile1,@lpMemory1
  local @bufTemp1[10]:byte
  local @dwTemp:dword,@dwTemp1:dword
  local @dwBuffer,@lpDst,@hDstFile
  

  invoke CreateFile,addr szFileNameOpen1,GENERIC_READ,\
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

  invoke CreateFile,addr szFileNameOpen2,GENERIC_READ,\
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


  ;到此为止，
  ;两个内存文件的指针已经获取到了。
  ;@lpMemory和@lpMemory1分别指向连个文件头

  ;补丁代码段大小        
  invoke getCodeSegSize,@lpMemory
  mov dwPatchCodeSize,eax 

  invoke wsprintf,addr szBuffer,addr szOut100,eax
  invoke _appendInfo,addr szBuffer   

  ;调整ESI,EDI指向DOS头
  mov esi,@lpMemory
  assume esi:ptr IMAGE_DOS_HEADER
  mov edi,@lpMemory1
  assume edi:ptr IMAGE_DOS_HEADER

  nop

  ;查找原PE头的有效数据长度
  invoke getValidHeadSize,@lpMemory1
  mov dwValidHeadSize,eax

  invoke wsprintf,addr szBuffer,addr szOut113,eax
  invoke _appendInfo,addr szBuffer   

  mov eax,dwPatchCodeSize
  add eax,dwValidHeadSize 
  mov dwBlock1,eax  ;原PE头有效数据长度+补丁代码有效数据

  ;将数据按8位对齐
  
  xor edx,edx
  mov bx,8
  div bx
  .if edx>0
    inc eax
  .endif
  xor edx,edx
  mov bx,8
  mul bx
  mov lpPatchPE,eax     ;新文件大小以8字节为单位对齐

  pushad
  invoke wsprintf,addr szBuffer,addr szOut101,lpPatchPE
  invoke _appendInfo,addr szBuffer 
  invoke wsprintf,addr szBuffer,addr szOut102,lpPatchPE
  invoke _appendInfo,addr szBuffer 
  popad  


  invoke _getRVACount,@lpMemory1
  inc eax   
  xor edx,edx
  mov bx,sizeof IMAGE_SECTION_HEADER
  mul bx
  mov dword ptr dwSections,eax
  pushad
  invoke wsprintf,addr szBuffer,addr szOut111,dwSections
  invoke _appendInfo,addr szBuffer 
  popad  

  ;EAX中存放了PE头和节表大小的和
  add eax,sizeof IMAGE_NT_HEADERS   
  mov dwPE_SECTIONSize,eax

  mov ebx,lpPatchPE  
  add ebx,eax
  mov dwHeaderSize,ebx   ;头的有效数据大小


  .if ebx>1000h   ;空隙一的空间不足
    invoke _appendInfo,addr szOutErr   
    ret
  .endif

  ;将文件头按照文件FileAlign对齐
  invoke getFileAlign,@lpMemory1
  mov dwFileAlign,eax
  mov ebx,eax
  
  xor edx,edx
  mov eax,dwHeaderSize    ;文件头的实际大小

  pushad
  invoke wsprintf,addr szBuffer,addr szOut109,dwHeaderSize
  invoke _appendInfo,addr szBuffer 
  popad  

  div bx
  .if edx>0
    inc eax
  .endif
  xor edx,edx
  mov ebx,dwFileAlign
  mul bx      ;eax中是求出的对齐了以后的文件头大小
  mov dword ptr lpOthers,eax

  pushad
  invoke wsprintf,addr szBuffer,addr szOut110,lpOthers
  invoke _appendInfo,addr szBuffer 
  popad  

  ;求新文件大小
  mov esi,@lpMemory1
  assume esi:ptr IMAGE_DOS_HEADER
  add esi,[esi].e_lfanew
  assume esi:ptr IMAGE_NT_HEADERS
  mov edx,esi
  add edx,sizeof IMAGE_NT_HEADERS
  mov esi,edx    ;节表的起始位置
  ;求第一节的文件偏移
  assume esi:ptr IMAGE_SECTION_HEADER
  mov eax,[esi].PointerToRawData
  ;判断该值与lpOthers的区别，其差为文件多出的部分
  mov ebx,lpOthers
  sub ebx,eax
  mov dwOff,ebx     ;dwOff是文件多出的部分
   
  mov eax,@dwFileSize1
  ;目标文件的大小+对齐后的补丁代码大小为新文件大小
  add eax,dwOff    
  mov dwNewFileSize,eax

  pushad
  invoke wsprintf,addr szBuffer,addr szOut105,\
                                   @dwFileSize1,eax
  invoke _appendInfo,addr szBuffer    
  popad


  ;申请内存空间
  invoke GlobalAlloc,GHND,dwNewFileSize
  mov @hDstFile,eax
  invoke GlobalLock,@hDstFile
  mov lpDstMemory,eax   ;将指针给@lpDst

  
  ;将目标文件的DOS头部分拷贝到内存区域
  ;目标文件DOS头+Dos Stub+其他有效数据的大小
  mov ecx,dwValidHeadSize   
  invoke MemCopy,@lpMemory1,lpDstMemory,ecx

  ;获取补丁代码所在节在文件中的起始位置
  invoke getCodeSegStart,@lpMemory
  mov dwPatchCodeSegStart,eax

  ;拷贝补丁代码
  mov esi,dwPatchCodeSegStart  
  add esi,@lpMemory

  mov edi,lpDstMemory
  add edi,dwValidHeadSize
  mov ecx,dwPatchCodeSize
  invoke MemCopy,esi,edi,ecx

  ;拷贝PE头及目标节表
  mov esi,@lpMemory1
  assume esi:ptr IMAGE_DOS_HEADER
  add esi,[esi].e_lfanew

  mov edi,lpDstMemory
  add edi,lpPatchPE
 
  mov ecx,dwPE_SECTIONSize
        
  invoke MemCopy,esi,edi,ecx

  
  ;定位到lpOthers
  ;拷贝节的详细内容
  mov esi,@lpMemory1
  assume esi:ptr IMAGE_DOS_HEADER
  add esi,[esi].e_lfanew
  assume esi:ptr IMAGE_NT_HEADERS
  mov edx,esi
  add edx,sizeof IMAGE_NT_HEADERS
  mov esi,edx    ;节表的起始位置

  ;求节表中第一节的文件偏移
  assume esi:ptr IMAGE_SECTION_HEADER
  mov eax,[esi].PointerToRawData
  mov dwFirstSectionStart,eax
  mov esi,@lpMemory1
  add esi,dwFirstSectionStart


  ;判断该值与lpOthers的区别，其差为文件多出的部分
  mov ebx,lpOthers
  sub ebx,eax
  mov dwOff,ebx     ;dwOff是文件多出的部分
   
  mov edi,lpDstMemory
  add edi,lpOthers
  ;将剩余的节的数据拷贝到指定位置

  mov ecx,@dwFileSize1
  sub ecx,dwFirstSectionStart

  invoke MemCopy,esi,edi,ecx


  mov eax,dwValidHeadSize
  ;新入口指针=代码在文件中的起始偏移
  ;因为文件头被装入内存页面00000000h处。
  mov dwNewEntryPoint,eax  


  ;获得函数入口地址：
  invoke getEntryPoint,@lpMemory1
  mov dwDstEntryPoint,eax
  pushad
  invoke wsprintf,addr szBuffer,addr szOut106,eax
  invoke _appendInfo,addr szBuffer    
  popad



  ;修正各种值
  ;更改DOS头大小，即设置间隙一
  mov edi,lpDstMemory
  assume edi:ptr IMAGE_DOS_HEADER
  mov eax,lpPatchPE
  mov [edi].e_lfanew,eax

  
  ;修正函数入口地址  
  mov esi,@lpMemory
  assume esi:ptr IMAGE_DOS_HEADER
  mov edi,lpDstMemory
  assume edi:ptr IMAGE_DOS_HEADER
  add esi,[esi].e_lfanew    
  assume esi:ptr IMAGE_NT_HEADERS
  add edi,[edi].e_lfanew    
  assume edi:ptr IMAGE_NT_HEADERS
  mov eax,dwNewEntryPoint
  mov [edi].OptionalHeader.AddressOfEntryPoint,eax

  

  ;修正补丁代码中的E9指令后的操作数  
  mov eax,lpDstMemory
  add eax,dwBlock1
  sub eax,5   ;EAX指向了E9的操作数
  mov edi,eax

  sub eax,lpDstMemory
  add eax,4
 
  mov ebx,dwDstEntryPoint
  sub ebx,eax
  mov dword ptr [edi],ebx

  pushad
  invoke wsprintf,addr szBuffer,addr szOut112,ebx
  invoke _appendInfo,addr szBuffer    
  popad
  
  
  ;修正节表中记录文件偏移的几个字段
  invoke changeRawOffset,@lpMemory,@lpMemory1

  ;修正SizeOfCode
  ;因为该值只影响调试，不影响执行效果，所以不做修改

  ;修正SizeOfHeaders   最重要，如果不修改程序无法运行
  mov edi,lpDstMemory
  assume edi:ptr IMAGE_DOS_HEADER
  add edi,[edi].e_lfanew    
  assume edi:ptr IMAGE_NT_HEADERS
  mov eax,lpOthers
  mov [edi].OptionalHeader.SizeOfHeaders,eax

  ;修正SizeOfImage
  ;因为该值没有发生变化，所以无需修改
  
  ;将新文件内容写入到c:\bindA.exe
  invoke writeToFile,lpDstMemory,dwNewFileSize
 
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
_openFile endp


;-------------------
;打开对比窗口
;-------------------
_doComp proc
  pushad

  popad
  ret
_doComp endp
;-------------------
; 窗口程序
;-------------------
_ProcDlgMain proc uses ebx edi esi hWnd,wMsg,wParam,lParam
  mov eax,wMsg
  .if eax==WM_CLOSE
    invoke FadeOutClose,hWnd
    invoke EndDialog,hWnd,NULL
  .elseif eax==WM_INITDIALOG  ;初始化
    push hWnd
    pop hWinMain
    call _init
    invoke FadeInOpen,hWnd
  .elseif eax==WM_COMMAND     ;菜单
    mov eax,wParam
    .if eax==IDM_EXIT       ;退出
      invoke FadeOutClose,hWnd
      invoke EndDialog,hWnd,NULL 
    .elseif eax==IDM_OPEN   ;打开文件
        invoke _OpenFile1
    .elseif eax==IDM_1  
        invoke _OpenFile2
    .elseif eax==IDM_2
        ;将内存映射文件复制一份，留出间隙一
        invoke _openFile
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
  invoke InitCommonControls
  invoke LoadLibrary,offset szDllEdit
  mov hRichEdit,eax
  invoke GetModuleHandle,NULL
  mov hInstance,eax
  invoke DialogBoxParam,hInstance,\
         DLG_MAIN,NULL,offset _ProcDlgMain,NULL
  invoke FreeLibrary,hRichEdit
  invoke ExitProcess,NULL
  end start



