.386
.model flat,stdcall
option casemap:none

include    windows.inc
include    user32.inc
includelib user32.lib
include    kernel32.inc
includelib kernel32.lib
include    comdlg32.inc
includelib comdlg32.lib


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
totalSize   dd ?   ; 文件大小
lpMemory    dd ?   ; 内存映像文件在内存的起始位置
szFileName  db MAX_PATH dup(?)               ;要打开的文件路径及名称名


szOut2      db 13,10,'打开的文件：%s',13,10,13,10,0
szTitle     db '名称          FOA       总大小       可用空间      可用空间FOA',13,10
            db '-----------------------------------------------------------------------',13,10
            db 0

szOut       db '%s    %08x   %d(%xh)      %d(%xh)     %08x',13,10,0
szHeader    db '.head',0
szBuffer    db 256 dup(0)


szSection   db 10 dup(0),0  ;名称
lpFOA       dd ?            ;FOA
dwTotalSize dd ?            ;总大小
dwAvailable dd ?            ;可用空间
lpAvailable dd ?            ;可用空间FOA


.const
szDllEdit   db 'RichEd20.dll',0
szClassEdit db 'RichEdit20A',0
szFont      db '宋体',0
szExtPe     db 'PE File',0,'*.exe;*.dll;*.scr;*.fon;*.drv',0
            db 'All Files(*.*)',0,'*.*',0,0
szErr       db '文件格式错误!',0
szErrFormat db '这个文件不是PE格式的文件!',0

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
    add eax,[edx].SizeOfRawData        
    ;计算该节结束RVA，
    ;不用Misc的主要原因是有些段的Misc值是错误的！
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


;-------------------
; 定位到PE标识
; _lpHeader 头部基地址
; _dwFlag1
;    为0表示_lpHeader是PE映像头
;    为1表示_lpHeader是内存映射文件头 
; _dwFlag2
;    为0表示返回RVA+模块基地址
;    为1表示返回FOA+文件基地址
;    为2表示返回RVA
;    为3表示返回FOA
; 返回eax=PE标识所在地址
;
; 注意：当_lpHeader是PE映像头时，
;       _dwFlag2为1是无意义的，所以返回FOA
;-------------------
_rPE  proc _lpHeader,_dwFlag1,_dwFlag2
   local @ret
   local @imageBase

   pushad
   mov esi,_lpHeader
   assume esi:ptr IMAGE_DOS_HEADER
   add esi,[esi].e_lfanew
   mov edi,esi
   assume edi:ptr IMAGE_NT_HEADERS
   mov eax,[edi].OptionalHeader.ImageBase  ;程序的建议装载地址
   mov @imageBase,eax

   .if _dwFlag1==0 ;_lpHeader是PE映像头
     .if _dwFlag2==0     ;RVA+模块基地址 
       mov eax,esi
       mov @ret,eax
     .elseif _dwFlag2==1 ;无意义，只返回FOA
       sub esi,_lpHeader
       mov eax,esi
       mov @ret,eax
     .else   ;当_dwFlag2=2或3时返回值相同
       sub esi,_lpHeader
       mov eax,esi
       mov @ret,eax
     .endif
   .else  ;_lpHeader是内存映射文件头
 
     .if _dwFlag2==0     ;RVA+模块基地址 
       sub esi,_lpHeader
       add esi,@imageBase
       mov eax,esi
       mov @ret,eax
     .elseif _dwFlag2==1 ;FOA+文件基地址
       mov eax,esi
       mov @ret,eax
     .else   ;当_dwFlag2=2或3时返回值相同
       sub esi,_lpHeader
       mov eax,esi
       mov @ret,eax
     .endif
   .endif
   popad
   mov eax,@ret
   ret
_rPE endp

;-------------------
; 定位到指定索引的数据目录项所在数据的起始地址
; _lpHeader 头部基地址
; _index 数据目录表索引，从0开始
; _dwFlag1
;    为0表示_lpHeader是PE映像头
;    为1表示_lpHeader是内存映射文件头 
; _dwFlag2
;    为0表示返回RVA+模块基地址
;    为1表示返回FOA+文件基地址
;    为2表示返回RVA
;    为3表示返回FOA
; 返回eax=指定索引的数据目录项的数据所在地址
;-------------------
_rDDEntry  proc _lpHeader,_index,_dwFlag1,_dwFlag2
   local @ret,@ret1,@ret2
   local @imageBase
   pushad
   mov esi,_lpHeader
   assume esi:ptr IMAGE_DOS_HEADER
   add esi,[esi].e_lfanew   ;PE标识
   assume esi:ptr IMAGE_NT_HEADERS
   mov eax,[esi].OptionalHeader.ImageBase  ;程序的建议装载地址
   mov @imageBase,eax

   add esi,0078h ;指向DataDirectory
   
   xor eax,eax  ;索引*8
   mov eax,_index
   mov bx,8
   mul bx
   mov ebx,eax   
   ; 取出指定索引数据目录项的位置,是RVA
   mov eax,dword ptr [esi][ebx]
   mov @ret1,eax

   .if _dwFlag1==0  ;_lpHeader是PE映像头  
     .if _dwFlag2==0     ;RVA+模块基地址
       add eax,_lpHeader 
       mov @ret,eax
     .elseif _dwFlag2==1 ;无意义，返回FOA 
       invoke _RVAToOffset,_lpHeader,eax
       mov @ret,eax  
     .elseif _dwFlag2==2 ;RVA
       mov @ret,eax
     .elseif _dwFlag2==3 ;FOA
       invoke _RVAToOffset,_lpHeader,eax
       mov @ret,eax
     .endif
  .else  ;_lpHeader是内存映射文件头
     .if _dwFlag2==0     ;RVA+模块基地址
       add eax,@imageBase
       mov @ret,eax
     .elseif _dwFlag2==1 ;FOA+文件基地址
       ;先将RVA转换为文件偏移
       invoke _RVAToOffset,_lpHeader,eax
       mov @ret2,eax  
       add eax,_lpHeader
       mov @ret,eax
     .elseif _dwFlag2==2 ;RVA
       mov @ret,eax
     .elseif _dwFlag2==3 ;FOA
       ;先将RVA转换为文件偏移
       invoke _RVAToOffset,_lpHeader,eax
       mov @ret,eax
     .endif
  .endif
   popad
   mov eax,@ret
   ret
_rDDEntry endp

;-------------------
; 定位到指定索引的节表项
; _lpHeader 头部基地址
; _index 表示第几个节表项，从0开始
; _dwFlag1
;    为0表示_lpHeader是PE映像头
;    为1表示_lpHeader是内存映射文件头 
; _dwFlag2
;    为0表示返回RVA+模块基地址
;    为1表示返回FOA+文件基地址
;    为2表示返回RVA
;    为3表示返回FOA
; 返回eax=指定索引的节表项所在地址
;-------------------
_rSection  proc _lpHeader,_index,_dwFlag1,_dwFlag2
   local @ret,@ret1,@ret2
   local @imageBase
   pushad
   mov esi,_lpHeader
   assume esi:ptr IMAGE_DOS_HEADER
   add esi,[esi].e_lfanew   ;PE标识
   assume esi:ptr IMAGE_NT_HEADERS
   mov eax,[esi].OptionalHeader.ImageBase  ;程序的建议装载地址
   mov @imageBase,eax

   mov eax,[esi].OptionalHeader.NumberOfRvaAndSizes
   mov bx,8
   mul bx
   
   add esi,0078h ;指向DataDirectory
   add esi,eax   ;加上DataDirectory的大小,指向节表开始
   
   xor eax,eax  ;索引*40
   mov eax,_index
   mov bx,40
   mul bx

   add esi,eax   ;索引项所在地址

   .if _dwFlag1==0  ;_lpHeader是PE映像头  
     .if _dwFlag2==0     ;RVA+模块基地址
       mov eax,esi 
       mov @ret,eax
     .else
       sub esi,_lpHeader
       mov eax,esi
       mov @ret,eax
     .endif
  .else  ;_lpHeader是内存映射文件头
     .if _dwFlag2==0     ;RVA+模块基地址
       sub esi,_lpHeader
       add esi,@imageBase
       mov @ret,eax
     .elseif _dwFlag2==1 ;FOA+文件基地址
       mov eax,esi
       mov @ret,eax
     .else
       sub esi,_lpHeader
       mov eax,esi
       mov @ret,eax
     .endif
  .endif
   popad
   mov eax,@ret
   ret
_rSection endp

;--------------------
; 打开PE文件并处理
;--------------------
_openFile proc
  local @stOF:OPENFILENAME
  local @hFile,@dwFileSize,@hMapFile,@lpMemory
  local @dwSections
  local @dwTemp,@dwOff

  invoke RtlZeroMemory,addr @stOF,sizeof @stOF
  mov @stOF.lStructSize,sizeof @stOF
  push hWinMain
  pop @stOF.hwndOwner
  mov @stOF.lpstrFilter,offset szExtPe
  mov @stOF.lpstrFile,offset szFileName
  mov @stOF.nMaxFile,MAX_PATH
  mov @stOF.Flags,OFN_PATHMUSTEXIST or OFN_FILEMUSTEXIST
  invoke GetOpenFileName,addr @stOF  ;让用户选择打开的文件
  .if !eax
    jmp @F
  .endif
  invoke CreateFile,addr szFileName,GENERIC_READ,\
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
          ;获得文件在内存的映象起始位置
          mov @lpMemory,eax
          assume fs:nothing
          push ebp
          push offset _ErrFormat
          push offset _Handler
          push fs:[0]
          mov fs:[0],esp

          ;检测PE文件是否有效
          mov esi,@lpMemory
          assume esi:ptr IMAGE_DOS_HEADER

          ;判断是否有MZ字样
          .if [esi].e_magic!=IMAGE_DOS_SIGNATURE
            jmp _ErrFormat
          .endif

          ;调整ESI指针指向PE文件头
          add esi,[esi].e_lfanew
          assume esi:ptr IMAGE_NT_HEADERS
          ;判断是否有PE字样
          .if [esi].Signature!=IMAGE_NT_SIGNATURE
            jmp _ErrFormat
          .endif

          mov eax,[esi].OptionalHeader.SizeOfHeaders
          movzx eax,[esi].FileHeader.NumberOfSections
          mov @dwSections,eax

          invoke wsprintf,addr szBuffer,addr szOut2,\
                         addr szFileName
          invoke _appendInfo,addr szBuffer
          invoke _appendInfo,addr szTitle

          ;获取各节的内容
          mov eax,@dwSections
          mov @dwTemp,eax
          sub @dwTemp,1

          .while @dwTemp!=0FFFFFFFFh
            mov eax,@dwSections
            dec eax
            .if @dwTemp==eax  ;表示最后一个节
               mov eax,@dwFileSize ;文件大小
               mov @dwOff,eax
            .else
               mov eax,lpFOA
               mov @dwOff,eax ;上一个节的起始
            .endif
            invoke _rSection,@lpMemory,@dwTemp,1,3
            add eax,@lpMemory
            mov esi,eax
            assume esi:ptr IMAGE_SECTION_HEADER
            mov eax,dword ptr [esi].PointerToRawData
            mov lpFOA,eax

            ;获取节的名字
            pushad
            invoke RtlZeroMemory,addr szSection,10
            popad

            nop
            push esi
            push edi
            mov edi,offset szSection
            mov ecx,8
            cld
            rep movsb
            pop edi
            pop esi

            mov edi,@dwOff
            add edi,@lpMemory
            xor ecx,ecx
loc2:       dec edi
            mov al,byte ptr [edi]
            .if al==0
              inc ecx
              jmp loc2          
            .endif

            mov dwAvailable,ecx

            ;计算节区尺寸
            mov eax,@dwOff
            sub eax,lpFOA
            mov dwTotalSize,eax
            sub eax,dwAvailable
            add eax,lpFOA
            mov lpAvailable,eax
            invoke wsprintf,addr szBuffer,addr szOut,\
                              addr szSection,\
                              lpFOA,\
                              dwTotalSize,\
                              dwTotalSize,\
                              dwAvailable,\
                              dwAvailable,\
                              lpAvailable
            invoke _appendInfo,addr szBuffer            

            dec @dwTemp
          .endw 

          ;获取文件头部可用空间
          ;定位到第一个节表项
          invoke _rSection,@lpMemory,0,1,3
          add eax,@lpMemory
          mov esi,eax
          assume esi:ptr IMAGE_SECTION_HEADER
          mov eax,dword ptr [esi].PointerToRawData
          mov dwTotalSize,eax

          xor ecx,ecx
          add eax,@lpMemory ;指向文件头的尾部
          mov edi,eax
loc1:     dec edi
          mov al,byte ptr [edi]
          .if al==0
            inc ecx
            jmp loc1          
          .endif
          mov dwAvailable,ecx
          mov lpFOA,0
          mov eax,dwTotalSize
          sub eax,dwAvailable
          mov lpAvailable,eax
          invoke wsprintf,addr szBuffer,addr szOut,\
                              addr szHeader,\
                              lpFOA,\
                              dwTotalSize,\
                              dwTotalSize,\
                              dwAvailable,\
                              dwAvailable,\
                              lpAvailable
          invoke _appendInfo,addr szBuffer
          jmp _ErrorExit
 
_ErrFormat:
          invoke MessageBox,hWinMain,offset szErrFormat,\
                                                 NULL,MB_OK
_ErrorExit:
          pop fs:[0]
          add esp,0ch
          invoke UnmapViewOfFile,@lpMemory
        .endif
        invoke CloseHandle,@hMapFile
      .endif
      invoke CloseHandle,@hFile
    .endif
  .endif
@@:        
  ret
_openFile endp
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
  .elseif eax==WM_COMMAND  ;菜单
    mov eax,wParam
    .if eax==IDM_EXIT       ;退出
      invoke EndDialog,hWnd,NULL 
    .elseif eax==IDM_OPEN   ;打开文件
      invoke _openFile
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
