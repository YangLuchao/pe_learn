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
include    ole32.inc

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
includelib ole32.lib



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
IDC_LIST        equ 5010
IDC_MOVE1       equ 5011
IDC_MOVE2       equ  5012
IDC_MOVE3       equ  5013
IDC_MOVE4       equ  5014
IDC_MOVE5       equ  5015
IDC_MOVE6       equ  5016

TOTAL_FILE_COUNT  equ   100        ;本程序所绑定文件的最大数
BinderFileStruct  STRUCT
  inExeSequence   byte   ?         ;为0表示非执行文件，为1表示加入执行序列
  dwFileOff       dword   ?        ;在宿主中的起始偏移
  dwFileSize      dword    ?       ;文件大小
  name1           db   256 dup(0)  ;文件名，含子目录
BinderFileStruct  ENDS

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
dwNumber    dd ?
dwCount1    dd ?

hModuleListBox  dd  ?

dwFileSizeHigh dd ?
dwFileSizeLow dd ?
dwFileCount dd ?
dwFolderCount dd ?
dwFileSize    dd ?
dwFileOff     dd ?
dwBindFileCount dd ?        ;待绑定的文件数目

dwPatchCodeSize   dd  ?     ;补丁代码大小
dwNewFileSize     dd  ?     ;新文件大小=目标文件大小+补丁代码大小
dwNewPatchCodeSize  dd ?    ;补丁代码按8位对齐后的大小
dwPatchCodeSegStart  dd ?   ;补丁代码所在节在文件中的起始地址
dwSectionCount       dd ?   ;目标文件节的个数
dwSections           dd ?   ;所有节表大小
dwNewHeaders         dd ?   ;新文件头的大小
dwFileAlign          dd ?   ;文件对齐粒度
dwFirstSectionStart  dd ?   ;目标文件第一节距离文件起始的偏移量
dwOff                dd ?   ;新文件比原来多出来的部分
dwValidHeadSize      dd ?   ;目标文件PE头的有效数据长度
dwHeaderSize         dd ?   ;文件头长度
dwBlock1             dd ?   ;原PE头的有效数据长度+补丁代码的有效数据长度
dwPE_SECTIONSize     dd ?   ;PE头+节表大小
dwSectionsLeft       dd ?   ;目标文件所有节数据的大小
dwNewSectionSize     dd ?   ;新增加节对齐后的尺寸
dwNewSectionOff      dd ?   ;新增加节项描述在文件中的偏移
dwDstSizeOfImage     dd ?   ;目标文件内存映像的大小
dwNewSizeOfImage     dd ?   ;新增加的节在内存映像中的大小
dwNewFileAlignSize   dd ?   ;文件对齐后的大小
dwSectionsAlignLeft  dd ?   ;目标文件节在文件中对齐后的大小
dwLastSectionAlignSize  dd ?   ;目标文件最后一节对齐后的最终大小，包含代码
dwLastSectionStart      dd ?   ;目标文件最后一节在文件中的偏移
dwSectionAlign          dd ?   ;节对齐粒度
dwVirtualAddress        dd ?   ;最后一节的起始RVA
dwEIPOff                dd ?   ;新EIP指针和旧EIP指针的距离



dwDstEntryPoint      dd ?   ;旧的入口地址
dwNewEntryPoint      dd ?   ;新的入口地址

lpPatchPE         dd  ?   ;补丁程序的PE标志在文件中的位置，因为从0开始，所以这个位置也是DOS头的大小
lpDstMemory       dd  ?   ;内存中存放新文件数据的起始地址
lpOthers          dd  ?   ;其他数据在文件中的起始位置


lpBinderList1     dd  13ach        ;绑定列表在host.exe文件中的位置，下面的也是
lpBinderList2     dd  8be8h     


hProcessModuleTable dd ?


szFilter   db '*.*',0
szXie      db '\',0
szPath     db 'c:\ql',256 dup(0)
szFileName           db MAX_PATH dup(?)
szDstFile            db 'c:\host.exe',0
szFileNameOpen1      db 'c:\FlexHEX',MAX_PATH dup(0)    ; 要绑定的目录
szFileNameOpen2      db 'd:\masm32\source\chapter15\host.exe',MAX_PATH dup(0)   ; 宿主程序

                     ;d:\masm32\source\chapter12\HelloWorld.exe

szResultColName1 db  '编号',0
szResultColName2 db  '要捆绑的文件',0
szResultColName3 db  '是否进入执行序列',0
szBuffer         db  256 dup(0),0
bufTemp1         db  512 dup(0),0
bufTemp2         db  512 dup(0),0
bufTemp3         db  512 dup(0),0
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
szNotFound  db '无法查找',0
szTooManyFiles db '文件太多，程序捆绑失败，请尝试减少文件数量',0
szSuccess    db '捆绑成功，请查看目标文件c:\host.exe',0
szNewSection db 'PEBindQL',0
sz1          db '%d',0

szCrLf      db 0dh,0ah,0

szOut100       db '补丁代码段大小：%08x',0dh,0ah,0
szOut104       db '空隙一的大小为：%08x',0dh,0ah,0
szOut101       db '目标PE文件头的有效数据长度为：%08x ',0dh,0ah,0
szOut102       db '目标PE文件头有效数据长度对齐后的值为：%08x',0dh,0ah,0
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
szOut114       db '新增节按照文件对齐粒度对齐以后的大小为:%08x',0dh,0ah,0
szOut115       db '新PE文件的入口地址为：%08x',0dh,0ah,0

szOut121       db 'PE文件大小：%08x   对齐以后的大小：%08x',0dh,0ah,0
szOut122       db '目标文件最后一节在文件中的起始偏移：%08x',0dh,0ah,0
szOut123       db '目标文件最后一节对齐后的大小：%08x',0dh,0ah,0
szOut124       db '新文件大小：%08x',0dh,0ah,0

szOut1      db '补丁程序：%s',0dh,0ah,0
szOut2      db '目标PE程序：%s',0dh,0ah,0
szOutErr    db '代码段长度大于0DA8h，空隙一的空间不足！',0dh,0ah,0
lpszHexArr  db  '0123456789ABCDEF',0

.data?
stLVC         LV_COLUMN <?>
stLVI         LV_ITEM   <?>

.code

include _BrowseFolder.asm

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

;---------------------------
; 判断文件是否为EXE文件，根据后缀
;---------------------------
_isExeFile  proc  _lpFileName
  local @szFile[20]:byte
  local @ret

  pushad
  lea edi,@szFile
  mov al,'.'
  stosb
  mov al,'e'
  stosb
  mov al,'x'
  stosb
  mov al,'e'
  stosb
  mov al,0
  stosb

  invoke lstrlen,_lpFileName
  sub eax,4
  mov esi,_lpFileName
  add esi,eax

  lea edi,@szFile
  invoke lstrcmp,esi,edi
  .if !eax  ;相等
     mov @ret,1    
  .else
     mov @ret,0
  .endif   
  popad
  mov eax,@ret
  ret
_isExeFile  endp
;---------------------
; 处理找到的文件
;---------------------
_ProcessFile proc _lpszFile
  local @hFile

  invoke lstrlen,addr szPath
  mov esi,eax
  add esi,_lpszFile
  mov al,byte ptr [esi]
  .if al==5ch
    inc esi
  .endif

  ;显示到列表中
  
  invoke SendMessage,hModuleListBox,LB_ADDSTRING,\
                     0,_lpszFile
  inc dwFileCount
  invoke CreateFile,_lpszFile,GENERIC_READ,FILE_SHARE_READ,0,\
   OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
  .if eax != INVALID_HANDLE_VALUE
   mov @hFile,eax
   invoke GetFileSize,eax,NULL

   add dwFileSizeLow,eax
   adc dwFileSizeHigh,0
   invoke CloseHandle,@hFile
  .endif
  ret

_ProcessFile endp

;----------------------------
; 遍历指定目录szPath下
;  (含子目录)的所有文件
;------------------------------
_FindFile proc _lpszPath
  local @stFindFile:WIN32_FIND_DATA
  local @hFindFile
  local @szPath[MAX_PATH]:byte     ;用来存放“路径\”
  local @szSearch[MAX_PATH]:byte   ;用来存放“路径\*.*”
  local @szFindFile[MAX_PATH]:byte ;用来存放“路径\文件”

  pushad
  invoke lstrcpy,addr @szPath,_lpszPath
  ;在路径后面加上\*.*
@@:
  invoke lstrlen,addr @szPath
  lea esi,@szPath
  add esi,eax
  xor eax,eax
  mov al,'\'
  .if byte ptr [esi-1] != al
   mov word ptr [esi],ax
  .endif
  invoke lstrcpy,addr @szSearch,addr @szPath
  invoke lstrcat,addr @szSearch,addr szFilter
  ;寻找文件
  invoke FindFirstFile,addr @szSearch,addr @stFindFile
  .if eax != INVALID_HANDLE_VALUE
   mov @hFindFile,eax
   .repeat
    invoke lstrcpy,addr @szFindFile,addr @szPath
    invoke lstrcat,addr @szFindFile,addr @stFindFile.cFileName
    .if @stFindFile.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY
     .if @stFindFile.cFileName != '.'
      inc dwFolderCount
      invoke _FindFile,addr @szFindFile
     .endif
    .else
     invoke _ProcessFile,addr @szFindFile
    .endif
    invoke FindNextFile,@hFindFile,addr @stFindFile
   .until eax==FALSE
   invoke FindClose,@hFindFile
  .endif
  popad
  ret
_FindFile endp
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

;-----------------------------
; 对齐
; 入口：eax----对齐的值
;      ecx----对齐因子
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
  add eax,2          ;为有效数据留出两个0字符，假如最后的有效数据为字符串，必须以0结束
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
; 打开捆绑目录
;------------------------------------------
_OpenFile1	proc
		local	@stOF:OPENFILENAME
		local	@stES:EDITSTREAM

                invoke GetCurrentDirectory,sizeof szPath,addr szPath
                invoke _BrowseFolder,NULL,addr szPath
                .if eax
                  invoke SetWindowText,hText1,addr szPath
                .endif
                invoke wsprintf,addr szBuffer,addr szOut1,addr szPath
                invoke _appendInfo,addr szBuffer
                invoke SendMessage,hModuleListBox,LB_RESETCONTENT,0,0
                invoke _FindFile,addr szPath
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


;-------------------------
; 在ListView中增加一个列
; 输入：_dwColumn = 增加的列编号
;	_dwWidth = 列的宽度
;	_lpszHead = 列的标题字符串 
;-------------------------
_ListViewAddColumn	proc  uses ebx ecx _hWinView,_dwColumn,_dwWidth,_lpszHead
		local	@stLVC:LV_COLUMN

		invoke	RtlZeroMemory,addr @stLVC,sizeof LV_COLUMN
		mov	@stLVC.imask,LVCF_TEXT or LVCF_WIDTH or LVCF_FMT
		mov	@stLVC.fmt,LVCFMT_LEFT
		push	_lpszHead
		pop	@stLVC.pszText
		push	_dwWidth
		pop	@stLVC.lx
              push  _dwColumn
              pop   @stLVC.iSubItem
		invoke	SendMessage,_hWinView,LVM_INSERTCOLUMN,_dwColumn,addr @stLVC
		ret
_ListViewAddColumn	endp
;----------------------------------------------------------------------
; 在ListView中新增一行，或修改一行中某个字段的内容
; 输入：_dwItem = 要修改的行的编号
;	_dwSubItem = 要修改的字段的编号，-1表示插入新的行，>=1表示字段的编号
;-----------------------------------------------------------------------
_ListViewSetItem	proc uses ebx ecx _hWinView,_dwItem,_dwSubItem,_lpszText
              invoke  RtlZeroMemory,addr stLVI,sizeof LV_ITEM

              invoke lstrlen,_lpszText
              mov stLVI.cchTextMax,eax
              mov stLVI.imask,LVIF_TEXT
              push _lpszText
              pop stLVI.pszText
              push _dwItem
              pop stLVI.iItem
              push _dwSubItem
              pop stLVI.iSubItem

              .if _dwSubItem == -1
                 mov stLVI.iSubItem,0
                 invoke SendMessage,_hWinView,LVM_INSERTITEM,NULL,addr stLVI
              .else
                 invoke SendMessage,_hWinView,LVM_SETITEM,NULL,addr stLVI
              .endif
              
              ret

_ListViewSetItem	endp
;----------------------
; 清除ListView中的内容
; 删除所有的行和所有的列
;----------------------
_ListViewClear	proc uses ebx ecx _hWinView

		invoke	SendMessage,_hWinView,LVM_DELETEALLITEMS,0,0
		.while	TRUE
			invoke	SendMessage,_hWinView,LVM_DELETECOLUMN,0,0
			.break	.if ! eax
		.endw
		ret

_ListViewClear	endp

;---------------------
; 返回指定行列的值
; 结果在szBuffer中
;---------------------
_GetListViewItem   proc  _hWinView:DWORD,_dwLine:DWORD,_dwCol:DWORD,_lpszText
              local @stLVI:LV_ITEM
              
              invoke	RtlZeroMemory,addr @stLVI,sizeof LV_ITEM
              invoke RtlZeroMemory,_lpszText,512

              mov  @stLVI.cchTextMax,512
              mov  @stLVI.imask,LVIF_TEXT
              push   _lpszText
              pop  @stLVI.pszText
              push _dwCol
              pop  @stLVI.iSubItem

              invoke SendMessage,_hWinView,LVM_GETITEMTEXT,_dwLine,addr @stLVI
              ret
_GetListViewItem   endp
;---------------------
; 初始化结果表格
;---------------------
_clearResultView  proc uses ebx ecx
             invoke _ListViewClear,hProcessModuleTable

             ;添加表头
             mov ebx,1
             mov eax,100
             lea ecx,szResultColName1
             invoke _ListViewAddColumn,hProcessModuleTable,ebx,eax,ecx

             mov ebx,2
             mov eax,600
             lea ecx,szResultColName2
             invoke _ListViewAddColumn,hProcessModuleTable,ebx,eax,ecx

             mov ebx,3
             mov eax,200
             lea ecx,szResultColName3
             invoke _ListViewAddColumn,hProcessModuleTable,ebx,eax,ecx

             mov dwCount,0
             ret
_clearResultView  endp

;--------------------------------------------
; 在表格中增加一行
; _lpSZ为第一行要显示的字段名
; _lpSP1为第一个文件该字段的位置
; _lpSP2为第二个文件该字段的位置
; _Size为该字段的字节长度
;--------------------------------------------
_addLine proc _lpSZ1,_lpSZ2
  pushad

  inc dwNumber
  invoke _ListViewSetItem,hProcessModuleTable,dwNumber,-1,\
               addr bufTemp1             ;在表格中新增加一行
  mov dwCount,eax
  invoke RtlZeroMemory,addr bufTemp1,200
  invoke wsprintf,addr bufTemp1,addr sz1,dwNumber

  xor ebx,ebx
  invoke _ListViewSetItem,hProcessModuleTable,dwCount,ebx,\
         addr bufTemp1                  ; 
  
  inc ebx
  invoke _ListViewSetItem,hProcessModuleTable,dwCount,ebx,\
                   _lpSZ1 ;文件名
  inc ebx
  invoke _ListViewSetItem,hProcessModuleTable,dwCount,ebx,\
                   _lpSZ2 ;是否在执行序列

  popad
  ret
_addLine  endp



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


;-------------------------
; 重新计算被选择文件的大小
;-------------------------
_calcFileSize  proc
  local @dwCount
  local @hFile1

  pushad

  mov dwFileSizeLow,0
  mov dwFileSizeHigh,0
  invoke SendMessage,hProcessModuleTable,\
        LVM_GETITEMCOUNT,0,0
  mov dwBindFileCount,eax
  mov @dwCount,0
  .repeat
    ;获取指定行指定列的信息，即文件路径
    invoke RtlZeroMemory,addr szBuffer,512
    invoke _GetListViewItem,hProcessModuleTable,\
          @dwCount,1,addr szBuffer
    ;打开文件，求文件大小
    invoke CreateFile,addr szBuffer,GENERIC_READ,\
         FILE_SHARE_READ or FILE_SHARE_WRITE,NULL,\
         OPEN_EXISTING,FILE_ATTRIBUTE_ARCHIVE,NULL

    .if eax!=INVALID_HANDLE_VALUE
      mov @hFile1,eax
      invoke GetFileSize,eax,NULL
      add dwFileSizeLow,eax
      adc dwFileSizeHigh,0
    .endif 
    invoke CloseHandle,@hFile1
    inc @dwCount
    mov eax,dwBindFileCount
    .break .if @dwCount==eax
  .until FALSE

  popad
  ret
_calcFileSize  endp


;--------------------
; 填充绑定列表
; 入口参数：
;  _dwNumber   绑定文件顺号，定位用
;  _inExe      是否在执行列表中
;  _dwOff      所在文件偏移
;  _Size       文件大小
;  _lpSZ       路径  d:\masm32\source\a\b\c\host.exe
;              注意这是绝对路径，要求填充时更改为相对当前目录的相对路径a\b\c\host.exe
;--------------------
_writeToBinderList  proc  _dwNumber,_inExe,_dwOff,_Size,_lpSZ
  local @dwSize
  local @dwTemp

  pushad


  mov eax,lpDstMemory      ;向两处捆绑列表中写入捆绑文件的数量
  add eax,lpBinderList1
  add eax,4
  mov esi,eax

  xor edx,edx               ;定位指针
  mov eax,_dwNumber
  mov ebx,sizeof BinderFileStruct
  mul ebx
  add esi,eax

  assume esi:ptr BinderFileStruct

  mov eax,lpDstMemory      ;向两处捆绑列表中写入捆绑文件的数量
  add eax,lpBinderList2
  add eax,4
  mov edi,eax

  xor edx,edx
  mov eax,_dwNumber         ;定位指针
  mov ebx,sizeof BinderFileStruct
  mul ebx
  add edi,eax

  assume edi:ptr BinderFileStruct


  mov eax,_inExe
  mov byte ptr [esi].inExeSequence,al
  mov eax,_dwOff
  mov [esi].dwFileOff,eax
  mov eax,_Size
  mov [esi].dwFileSize,eax



  pushad
  invoke lstrlen,_lpSZ
  mov @dwSize,eax
  invoke lstrlen,addr szPath    ;获取当前目录字符串的长度
  mov @dwTemp,eax
  inc @dwTemp         ;跳过斜杠
  popad
  mov eax,_lpSZ        ;跳过当前目录
  add eax,@dwTemp
  mov _lpSZ,eax
  mov eax,@dwSize
  sub eax,@dwTemp
  invoke MemCopy,_lpSZ,addr [esi].name1,eax
     
  mov eax,_inExe
  mov byte ptr [edi].inExeSequence,al
  mov eax,_dwOff
  mov [edi].dwFileOff,eax
  mov eax,_Size
  mov [edi].dwFileSize,eax

  mov eax,@dwSize
  sub eax,@dwTemp
  invoke MemCopy,_lpSZ,addr [edi].name1,eax

  popad
  ret
_writeToBinderList endp

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
  local @dwCount,@dwInExe
  

  ;打开宿主程序，并映射到内存文件
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

  ;重新计算文件大小
  invoke _calcFileSize

  mov eax,dwFileSizeLow
  add eax,@dwFileSize1
  adc dwFileSizeHigh,0

  mov eax,dwFileSizeHigh
  .if eax>0  ;附加的字节数太大，程序捆绑失败
    invoke MessageBox,NULL,addr szTooManyFiles,NULL,MB_OK
    jmp _ErrFormat1
  .endif
  mov eax,dwBindFileCount
  .if eax>TOTAL_FILE_COUNT  ;文件太多，程序捆绑失败
    invoke MessageBox,NULL,addr szTooManyFiles,NULL,MB_OK
    jmp _ErrFormat1
  .endif

  ;将文件的大小按照文件对齐粒度对齐 
  invoke getFileAlign,@lpMemory1
  mov dwFileAlign,eax
  xchg eax,ecx
  mov eax,@dwFileSize1
  invoke _align
  mov dwNewFileAlignSize,eax

  invoke wsprintf,addr szBuffer,addr szOut121,@dwFileSize1,dwNewFileAlignSize
  invoke _appendInfo,addr szBuffer 

  ;求最后一节在文件中的偏移
  invoke getLastSectionStart,@lpMemory1
  mov dwLastSectionStart,eax

  invoke wsprintf,addr szBuffer,addr szOut122,eax
  invoke _appendInfo,addr szBuffer 

  ;求最后一节大小
  mov eax,dwNewFileAlignSize
  sub eax,dwLastSectionStart
  add eax,dwFileSizeLow
  ;将该值按照文件对齐粒度对齐
  mov ecx,dwFileAlign
  invoke _align
  mov dwLastSectionAlignSize,eax      ;最后一节附加了捆绑文件的新大小

  invoke wsprintf,addr szBuffer,addr szOut123,eax
  invoke _appendInfo,addr szBuffer 


  ;求新文件大小
  mov eax,dwLastSectionStart
  add eax,dwLastSectionAlignSize
  mov dwNewFileSize,eax

  invoke wsprintf,addr szBuffer,addr szOut124,eax
  invoke _appendInfo,addr szBuffer 
 

  ;申请内存空间
  invoke GlobalAlloc,GHND,dwNewFileSize
  mov @hDstFile,eax
  invoke GlobalLock,@hDstFile
  mov lpDstMemory,eax   ;将指针给@lpDst

  
  ;将目标文件拷贝到内存区域
  mov ecx,@dwFileSize1   
  invoke MemCopy,@lpMemory1,lpDstMemory,ecx


  ;拷贝捆绑文件
  
  ;计算列表中数据的数目
  invoke SendMessage,hProcessModuleTable,\
        LVM_GETITEMCOUNT,0,0
  mov dwBindFileCount,eax
  mov @dwCount,0

  mov edi,lpDstMemory
  add edi,dwNewFileAlignSize

  .repeat
    push edi
    ;获取指定行指定列的信息，即文件路径
    invoke RtlZeroMemory,addr szBuffer,512
    invoke _GetListViewItem,hProcessModuleTable,\
          @dwCount,1,addr szBuffer
    ;invoke MessageBox,NULL,addr szBuffer,NULL,MB_OK    
    

    invoke CreateFile,addr szBuffer,GENERIC_READ,\
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
          .endif
        .endif
      .endif
    .endif    

    
    invoke RtlZeroMemory,addr bufTemp1,512
    invoke _GetListViewItem,hProcessModuleTable,\
          @dwCount,2,addr bufTemp1    
    invoke atodw,addr bufTemp1
    mov @dwInExe,eax         ;是否在EXE执行序列

    ;invoke MessageBox,NULL,addr szBuffer,NULL,MB_OK

    mov eax,lpDstMemory      ;向两处捆绑列表中写入捆绑文件的数量
    add eax,lpBinderList1
    xchg ebx,eax
    mov eax,dwBindFileCount
    mov dword ptr [ebx],eax
   
    mov eax,lpDstMemory
    add eax,lpBinderList2
    xchg ebx,eax
    mov eax,dwBindFileCount
    mov dword ptr [ebx],eax


    pop edi
    mov edx,edi              ;取文件在目标中的偏移值
    sub edx,lpDstMemory
   
    ;将相关值写入捆绑列表    顺号   是否在EXE序列    偏移   文件大小   文件名
    invoke _writeToBinderList,@dwCount,@dwInExe,edx,@dwFileSize,addr szBuffer
    
    mov esi,@lpMemory
    ;将文件内容拷贝到目标文件
    mov ecx,@dwFileSize
    rep movsb
    
    ;取消映射
    push edi
    invoke UnmapViewOfFile,@lpMemory
    invoke CloseHandle,@hMapFile
    invoke CloseHandle,@hFile
    pop edi

    inc @dwCount
    nop
    mov eax,dwBindFileCount
    .break .if @dwCount==eax
  .until FALSE


  ;---------------------------到此为止，数据拷贝完毕  

  ;修正

  ;计算SizeOfRawData
  invoke _getRVACount,lpDstMemory
  xor edx,edx
  dec eax
  mov ecx,sizeof IMAGE_SECTION_HEADER
  mul ecx

  mov edi,lpDstMemory
  assume edi:ptr IMAGE_DOS_HEADER
  add edi,[edi].e_lfanew
  add edi,sizeof IMAGE_NT_HEADERS  
  add edi,eax
  assume edi:ptr IMAGE_SECTION_HEADER
  mov eax,dwLastSectionAlignSize
  mov [edi].SizeOfRawData,eax

  ;计算Misc值
  invoke getSectionAlign,@lpMemory1
  mov dwSectionAlign,eax
  xchg eax,ecx
  mov eax,dwLastSectionAlignSize
  invoke _align
  mov [edi].Misc,eax

  ;计算VirtualAddress

  mov eax,[edi].VirtualAddress  ;取原始RVA值
  mov dwVirtualAddress,eax

  mov edi,lpDstMemory
  assume edi:ptr IMAGE_DOS_HEADER
  add edi,[edi].e_lfanew    
  assume edi:ptr IMAGE_NT_HEADERS
  ;修正SizeOfImage
  mov eax,dwLastSectionAlignSize
  mov ecx,dwSectionAlign
  invoke _align
  ;获取最后一个节的VirtualAddress
  add eax,dwVirtualAddress
  mov [edi].OptionalHeader.SizeOfImage,eax  
  
  
 
  ;将新文件内容写入到c:\host.exe
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
; 弹出窗口程序
;-------------------
_resultProcMain   proc  uses ebx edi esi hProcessModuleDlg:HWND,wMsg,wParam,lParam
          local @dwCount
          local @lpLFI:LVFINDINFO
          local @stLVI:LV_ITEM

          mov eax,wMsg

          .if eax==WM_CLOSE
             invoke EndDialog,hProcessModuleDlg,NULL
          .elseif eax==WM_INITDIALOG
             invoke GetDlgItem,hProcessModuleDlg,IDC_MODULETABLE
             mov hProcessModuleTable,eax
             invoke GetDlgItem,hProcessModuleDlg,ID_TEXT1
             mov hText1,eax
             invoke GetDlgItem,hProcessModuleDlg,ID_TEXT2
             mov hText2,eax

             invoke GetDlgItem,hProcessModuleDlg,IDC_LIST
             mov hModuleListBox,eax

             invoke SendMessage,hProcessModuleTable,LVM_SETEXTENDEDLISTVIEWSTYLE,\
                    0,LVS_EX_GRIDLINES or LVS_EX_FULLROWSELECT
             invoke ShowWindow,hProcessModuleTable,SW_SHOW
             invoke _clearResultView
             mov dwNumber,0

          .elseif eax==WM_NOTIFY
            mov eax,lParam
            mov ebx,lParam
            ;更改各控件状态
            mov eax,[eax+NMHDR.hwndFrom]
            .if eax==hProcessModuleTable
                mov ebx,lParam
                .if [ebx+NMHDR.code]==NM_CUSTOMDRAW  ;绘画时
                  mov ebx,lParam
                  assume ebx:ptr NMLVCUSTOMDRAW  
                  .if [ebx].nmcd.dwDrawStage==CDDS_PREPAINT
                     invoke SetWindowLong,hProcessModuleDlg,DWL_MSGRESULT,CDRF_NOTIFYITEMDRAW
                     mov eax,TRUE
                  .elseif [ebx].nmcd.dwDrawStage==CDDS_ITEMPREPAINT

                     invoke _GetListViewItem,hProcessModuleTable,[ebx].nmcd.dwItemSpec,1,\
                        addr bufTemp1
                     invoke _GetListViewItem,hProcessModuleTable,[ebx].nmcd.dwItemSpec,2,\
                        addr bufTemp2
                     invoke atodw,addr bufTemp2
                     
                     ;invoke lstrlen,addr bufTemp1
                     ;invoke _MemCmp,addr bufTemp1,addr bufTemp2,eax
                     
                     .if eax==1
                        mov [ebx].clrTextBk,0a0a0ffh
                     .else
                        mov [ebx].clrTextBk,0ffffffh
                     .endif
                     invoke SetWindowLong,hProcessModuleDlg,DWL_MSGRESULT,CDRF_DODEFAULT
                     mov eax,TRUE
                   .endif
                .elseif [ebx+NMHDR.code]==NM_CLICK
                    assume ebx:ptr NMLISTVIEW
                .endif
            .endif
          .elseif eax==WM_COMMAND
             mov eax,wParam
             .if ax==IDC_OK  ;执行捆绑
                invoke _openFile
                invoke MessageBox,NULL,addr szSuccess,NULL,MB_OK
             .elseif ax==IDC_BROWSE1
                invoke _OpenFile1
             .elseif ax==IDC_BROWSE2
                invoke _OpenFile2
             .elseif ax==IDC_MOVE1   ;全部选中
                ; 将listbox中的所有值都填入表格中
                 mov dwNumber,0
                 invoke _clearResultView
                 invoke SendMessage,hModuleListBox,\
                        LB_GETCOUNT,0,0
                 mov dwCount1,eax

                 invoke wsprintf,addr bufTemp2,addr sz1,dwCount1        ;均不在执行序列
                 invoke _appendInfo,addr bufTemp2
                 invoke _appendInfo,addr szCrLf

                 mov @dwCount,0
                 .repeat
                   invoke RtlZeroMemory,addr szBuffer,512
                   invoke SendMessage,hModuleListBox,\
                        LB_GETTEXT,@dwCount,addr szBuffer
                   invoke _appendInfo,addr szCrLf
                   invoke _appendInfo,addr szBuffer
                   invoke _appendInfo,addr szCrLf

                   invoke wsprintf,addr bufTemp3,addr sz1,0        ;均不在执行序列
                   invoke _addLine,addr szBuffer,addr bufTemp3
                   
                   inc @dwCount
                   dec dwCount1
                   mov eax,dwCount1
                   .break .if eax==0
                 .until FALSE
             .elseif ax==IDC_MOVE2   ;全部选中，凡是EXE文件均加入执行序列
                ; 将listbox中的所有值都填入表格中
                 mov dwNumber,0
                 invoke _clearResultView
                 invoke SendMessage,hModuleListBox,\
                        LB_GETCOUNT,0,0
                 mov dwCount1,eax

                 invoke wsprintf,addr bufTemp2,addr sz1,dwCount1        ;均不在执行序列
                 invoke _appendInfo,addr bufTemp2
                 invoke _appendInfo,addr szCrLf

                 mov @dwCount,0
                 .repeat
                   invoke RtlZeroMemory,addr szBuffer,512
                   invoke SendMessage,hModuleListBox,\
                        LB_GETTEXT,@dwCount,addr szBuffer
                   invoke _appendInfo,addr szCrLf
                   invoke _appendInfo,addr szBuffer
                   invoke _appendInfo,addr szCrLf

                   invoke _isExeFile,addr szBuffer
                   .if eax==0
                     invoke wsprintf,addr bufTemp3,addr sz1,0        ;均不在执行序列
                     invoke _addLine,addr szBuffer,addr bufTemp3
                   .else
                     invoke wsprintf,addr bufTemp3,addr sz1,1        ;均不在执行序列
                     invoke _addLine,addr szBuffer,addr bufTemp3
                   .endif
                   inc @dwCount
                   dec dwCount1
                   mov eax,dwCount1
                   .break .if eax==0
                 .until FALSE
             .elseif ax==IDC_MOVE3   ;选中一个
                ; 将listbox中的所有值都填入表格中
                invoke RtlZeroMemory,addr szBuffer,512
                invoke SendMessage,hModuleListBox,LB_GETCURSEL,0,0
                invoke SendMessage,hModuleListBox,\
                      LB_GETTEXT,eax,addr szBuffer
                invoke _appendInfo,addr szCrLf
                invoke _appendInfo,addr szBuffer
                invoke _appendInfo,addr szCrLf

                invoke wsprintf,addr bufTemp3,addr sz1,0        ;均不在执行序列
                invoke _addLine,addr szBuffer,addr bufTemp3
             .elseif ax==IDC_MOVE4   ;选中一个，加入执行序列
                ; 将listbox中的所有值都填入表格中
                invoke RtlZeroMemory,addr szBuffer,512
                invoke SendMessage,hModuleListBox,LB_GETCURSEL,0,0
                invoke SendMessage,hModuleListBox,\
                      LB_GETTEXT,eax,addr szBuffer
                invoke _appendInfo,addr szCrLf
                invoke _appendInfo,addr szBuffer
                invoke _appendInfo,addr szCrLf

                invoke wsprintf,addr bufTemp3,addr sz1,1        ;均不在执行序列
                invoke _addLine,addr szBuffer,addr bufTemp3     
             .elseif ax==IDC_MOVE5   ;移除当前选中
                invoke SendDlgItemMessage,hProcessModuleDlg,\   ;获取当前表格选中的行
                        IDC_MODULETABLE,LVM_GETSELECTIONMARK,0,0 
                .if eax!=-1
                  invoke SendDlgItemMessage,hProcessModuleDlg,\
                         IDC_MODULETABLE,LVM_DELETEITEM,eax,0
                  dec dwNumber
                .endif
             .elseif ax==IDC_MOVE6   ;全部取消
                 invoke _clearResultView
                 mov dwNumber,0
             .endif
         .else
             mov eax,FALSE
             ret
         .endif
         mov eax,TRUE
         ret
_resultProcMain    endp


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
         invoke DialogBoxParam,hInstance,RESULT_MODULE,hWnd,\
               offset _resultProcMain,0
         invoke InvalidateRect,hWnd,NULL,TRUE
         invoke UpdateWindow,hWnd
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



