;-------------------------------------------
; 将patch.ext补丁程序插入到指定exe文件中首先运行
; 主要演示如何使用程序修改PE文件格式，从而完成想
; 要实现的功能
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
szBuffer    db 1024 dup(?)
dwFunctions db 1024 dup(11h)  ;记录每个动态链接库引用的函数个数。
                                         ;个数,个数，个数，0
szBuffer1   db 1024 dup(0)
szBuffer2   db 1024 dup(0)
bufTemp1         db  200 dup(0),0
bufTemp2         db  200 dup(0),0


dwPatchDataSize      dd ?  ;补丁数据段大小
dwPatchDataStart     dd ?  ;补丁数据起始地址
dwPatchMemDataStart  dd ?  ;补丁数据段在内存中的起始地址
dwDstDataSize        dd ?  ;目标数据段大小
dwDstDataStart       dd ?  ;目标数据起始地址
dwDstRawDataSize     dd ?  ;目标数据在文件中对齐后的大小
dwDstMemDataStart     dd ? ;目标数据段在内存中的起始地址
dwStartAddressinDstDS dd ? ;新增加的补丁数据段在目标文件中的起始位置

dwPatchImportSegSize      dd ?  ;补丁导入表所在段的大小
dwPatchImportSegStart     dd ?  ;补丁导入表所在段的起始地址
dwDstImportSegSize        dd ?  ;目标导入表所在段大小
dwDstImportSegStart       dd ?  ;目标导入表所在段数据起始地址
dwDstImportSegRawSize     dd ?  ;目标导入表所在段数据在文件中对齐后的大小
dwDstImportInFileStart    dd ?  ;目标导入表在文件中的起始地址
dwPatchImportInFileStart  dd ?  ;补丁导入表在文件中的起始位置
dwPatchImportSize         dd ?  ;补丁导入表大小
dwDstImportSize           dd ?  ;目标导入表大小
dwNewImportSize           dd ?  ;生成的新文件的导入表大小  ！！！！！！！这个大小是判断空间够用与否的主要字段
dwPatchDLLCount           dd ?  ;补丁程序中调用DLL的个数
dwPatchFunCount           dd ?  ;补丁程序中调用函数的个数
dwDstDLLCount             dd ?  ;目标程序中调用DLL的个数
dwDstFunCount             dd ?  ;目标程序中调用函数的个数
dwThunkSize               dd ?  ;IAT和originalFirstThunk指向数组的大小，即新文件中导入表的第1部分大小
dwFunDllConstSize         dd ?  ;函数名和动态链接库名常量的大小。
dwImportSpace2            dd ?  ;新文件中导入表的第2部分大小

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
dwDataInMemStart        dd ?  ;数据在新文件的内存中的起始地址


lpDstMemory             dd ?  ;新文件在内存的起始地址
lpPImportInNewFile      dd ?  ;补丁导入表在新文件中的位置
lpImportChange          dd 200 dup(0)   ;格式：四个字节为原值，四个字节为修正值依次排放
lpOriginalFirstThunk    dd ?  ;originalFirstThunk所指向的位置
lpNewImport             dd ?  ;新导入表在文件中的起始位置
lpNewEntryPoint         dd ?  ;补丁代码在新文件中的起始位置


dwPatchImageBase             dd ?  ;补丁程序装载的基地址。
dwDstImageBase               dd ?  ;目标程序装载的基地址。
dwPatchEntryPoint            dd ?  ;补丁程序入口地址
dwDstEntryPoint              dd ?  ;目标程序入口地址

hFile1                  dd ?   
hFile2                  dd ?
hFile                   dd ?




.const
szDllEdit   db 'RichEd20.dll',0
szClassEdit db 'RichEdit20A',0
szFont      db '宋体',0


szFile1     db 'd:\masm32\source\chapter11\patch.exe',256 dup(0)
szFile2     db 'd:\masm32\source\chapter11\HelloWorld.exe',256 dup(0)
szDstFile   db 'c:\bind.exe',256 dup(0)  ;测试文件
               ;c:\Documents and Settings\Administrator\桌面\mspaint.exe
               ;d:\masm32\source\chapter10\HelloWorld.exe



szErr       db '文件格式错误!',0
szErrFormat db '执行中发生了错误!请检查程序',0
szSuccess   db '恭喜你，程序执行到这里是成功的。',0
szNotFound  db '无法查找',0
szoutLine   db '----------------------------------------------------------------------------------------',0dh,0ah,0
szErr110      db '>> 未找到可存放数据的节！',0dh,0ah,0
szErr11      db '>> 目标数据段空间不够，不足以容纳补丁程序的数据！',0dh,0ah,0

szOut11      db '补丁数据段的有效数据大小为：%08x',0dh,0ah,0
szOut12      db '补丁数据段在文件中的起始位置：%08x',0dh,0ah,0
szOut2217    db '补丁数据段在内存中的起始地址：%08x',0dh,0ah,0
szOut13      db '目标数据段的有效数据大小为：%08x',0dh,0ah,0
szOut14      db '目标数据段在文件中的起始位置：%08x',0dh,0ah,0
szOut15      db '目标数据段在文件中对齐后的大小：%08x',0dh,0ah,0
szOut16      db '目标文件的数据段中有空间，剩余空间大小为：%08x,需要大小：%08x。补丁数据段在目标文件中存放的起始位置：%08x',0dh,0ah,0
szOut17      db '目标数据段在内存中的起始地址：%08x',0dh,0ah,0
szOut18      db '目标代码装入地址和程序执行入口：%08x:%08x',0dh,0ah,0
szOut19      db '数据在新文件的内存中的起始地址：%08x',0dh,0ah,0
szOut1911    db '合并以后的导入表修正',0dh,0ah,0
szOut1912    db '   DLL名：%s      Name1原始值：%08x      Name1修正值：%08x',0dh,0ah,0 
szOut1913    db '   函数名：%s     文件起始位置原始值：%08x      文件起始位置修正值：%08x',0dh,0ah,0 
szOut1915    db '   Dll名：%s     FirstThunk原始值：%08x   FirtThunk修正值：%08x',0dh,0ah,0 
szOut1916    db '   Dll名：%s     OriginalFirstThunk原始值：%08x   OriginalFirtThunk修正值：%08x',0dh,0ah,0 
szOut1917    db '数据目录表中对导入表部分的修改',0dh,0ah,0
szOut1918    db '   导入表起始位置   原始值：%08x   修正值：%08x   ',0dh,0ah,0
szOut1919    db '   导入表大小       原始值：%08x   修正值：%08x   ',0dh,0ah,0



szErr20      db '>> 未找到可存放数据的节！',0dh,0ah,0
szErr21      db '>> 目标段空间不够，不足以容纳补丁导入表及相关数据！',0dh,0ah,0

szOut221      db '补丁导入表所在段的有效数据大小为：%08x',0dh,0ah,0
szOut22      db '补丁导入表所在段在文件中的起始位置：%08x',0dh,0ah,0
szOut23      db '目标导入表所在段的有效数据大小为：%08x',0dh,0ah,0
szOut24      db '目标导入表所在段在文件中的起始位置：%08x',0dh,0ah,0
szOut25      db '目标导入表所在段在文件中对齐后的大小：%08x',0dh,0ah,0
szOut26      db '目标文件的导入表所处的段中有空间。剩余空间大小为:%08x,需要大小：%08x。合并以后的导入表在目标文件中存放的起始位置为：%08x',0dh,0ah,0
szOut27      db '补丁程序调用链接库个数：%08x',0dh,0ah,0
szOut28      db '补丁程序调用函数个数：%08x',0dh,0ah,0
szOut29      db '补丁程序调用动态链接库及每个动态链接库调用函数个数明细：',0dh,0ah,0
szOut2210     db '目标程序调用链接库个数：%08x',0dh,0ah,0
szOut2211     db '目标程序调用函数个数：%08x',0dh,0ah,0
szOut2212     db '目标程序调用动态链接库及每个动态链接库调用函数个数明细：',0dh,0ah,0
szOut2213     db '补丁文件导入函数名和动态链接库名字符串常量的大小：%08x',0dh,0ah,0
szOut2214     db '目标文件中原有导入表空间：%08x，补丁程序中导入函数两个相关数组的大小：%08x  前者若大于后者，则bind可继续进行',0dh,0ah,0
szOut2215     db '补丁文件中函数名和动态链接库字符串的大小：%08x',0dh,0ah,0
szOut2216     db '合并以后文件导入表大小（含零结构）：%08x',0dh,0ah,0
szOut2911     db '目标导入表在文件中的起始地址：%08x',0dh,0ah,0
szOut2912     db '补丁导入表在文件中的起始地址：%08x',0dh,0ah,0

szErr30      db '>> 未找到可存放数据的节！',0dh,0ah,0
szErr31      db '>> 目标段空间不够，不足以容纳补丁代码及相关数据！',0dh,0ah,0

szOut331      db '补丁代码所在段的有效数据大小为：%08x',0dh,0ah,0
szOut332      db '补丁代码所在段在文件中的起始位置：%08x',0dh,0ah,0
szOut33      db '目标代码所在段的有效数据大小为：%08x',0dh,0ah,0
szOut34      db '目标代码所在段在文件中的起始位置：%08x',0dh,0ah,0
szOut35      db '目标代码所在段在文件中对齐后的大小：%08x',0dh,0ah,0
szOut36      db '目标文件的代码所处的段中有空间。剩余空间大小为:%08x,需要大小：%08x。合并以后的代码在目标文件中存放的起始位置为：%08x',0dh,0ah,0
szOut37      db '补丁代码在内存中的起始位置：%08x',0dh,0ah,0
szOut38      db '目标代码在内存中的起始位置：%08x',0dh,0ah,0
szOut39      db '补丁程序装载基地址：%08x',0dh,0ah,0
szOut3310     db '补丁代码指令操作数地址需要修正的个数：%08x',0dh,0ah,0
szOut3311     db '补丁代码指令操作数地址需要修正列表：',0dh,0ah,0
szOut3312     db '目标程序调用动态链接库及每个动态链接库调用函数个数明细：',0dh,0ah,0
szOut3313     db '文件偏移：%08x   指令：%xh     操作数：%08x   偏移：%08x  修正后的新值：%08x',0dh,0ah,0
szOut3314     db '文件偏移：%08x   指令：%xh     操作数：%08x   修正后的新值：%08x',0dh,0ah,0

szOut001      db '补丁文件：%s',0
szOut002      db '目标文件：%s',0


szOut123     db '%04x',0
szCrLf      db 0dh,0ah,0
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
; 取导入表所在文件的偏移
; _lpHeader指向内存中PE文件的起始
; 返回值在eax中
;-------------------
getImportInFileStart proc _lpHeader
   local @dwSize
   pushad
   
   mov esi,_lpHeader
   assume esi:ptr IMAGE_DOS_HEADER
   add esi,[esi].e_lfanew    ;调整ESI指针指向PE文件头
   assume esi:ptr IMAGE_NT_HEADERS
   mov eax,[esi].OptionalHeader.DataDirectory[8].VirtualAddress

   invoke _RVAToOffset,_lpHeader,eax
   mov @dwSize,eax
   popad
   mov eax,@dwSize
   ret
getImportInFileStart endp

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
  mov dword ptr dwFunctions[ebx*4],0  ;在dwFunctions最后写一个零双字表示结束
@@:
  assume edi:nothing
  popad
  mov eax,@dwDlls
  mov ebx,@dwFunctions
  ret
_getImportFunctions endp

;---------------------------------
; 获取PE文件的导入表调用的函数名
; 与动态链接库的字符串常量大小
;---------------------------------
_getFunDllSize proc _lpFile
  local @szBuffer[1024]:byte
  local @szSectionName[16]:byte
  local _lpPeHead
  local @dwDlls,@dwFuns,@dwFunctions
  local @dwSize
  
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

  mov @dwSize,0

  .while [edi].OriginalFirstThunk || [edi].TimeDateStamp ||\
         [edi].ForwarderChain || [edi].Name1 || [edi].FirstThunk
    mov @dwFuns,0
    invoke _RVAToOffset,_lpFile,[edi].Name1
    add eax,_lpFile
    push edi
    push ecx
    push ebx
    
    mov edi,eax
    mov cx,0
    .repeat
       mov bl,byte ptr[edi]
       inc cx

       .if bl!=0   ;不为0，表示未结束
         inc @dwSize
       .else       ;是0，则@dwSize多加一，因为每个DLL后都是两个零结束
         add @dwSize,2
         .break
       .endif
       inc edi          
    .until FALSE
    pop ebx
    pop ecx
    pop edi

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
      .if dword ptr [ebx] & IMAGE_ORDINAL_FLAG32 ;按序号导入，无字符串常量
        mov eax,dword ptr [ebx]
        and eax,0ffffh
      .else                                      ;按名称导入
        invoke _RVAToOffset,_lpFile,dword ptr [ebx]
        add eax,_lpFile
        assume eax:ptr IMAGE_IMPORT_BY_NAME
        push edi
        push ecx
        push ebx

        mov edi,eax
        add edi,2
        add @dwSize,2    ;函数编号
        mov cx,0
        .repeat
          mov bl,byte ptr[edi]
          inc cx
          .if bl!=0   ;不为0，表示未结束
            inc @dwSize
          .else       ;是0，则看看计数值是否为偶数，如果是，则@dwSize多加一，因为偶数函数名后为两个零
            test cx,1
            jz @1          
            add @dwSize,2  ;字符个数为偶数
            jmp @2
@1:         add @dwSize,1  ;字符个数为奇数
@2:         .break
          .endif
          inc edi          
        .until FALSE

        pop ebx
        pop ecx
        pop edi

        assume eax:nothing
      .endif
      add ebx,4
    .endw
    add edi,sizeof IMAGE_IMPORT_DESCRIPTOR
  .endw
@@:
  assume edi:nothing
  popad
  mov eax,@dwSize
  ret
_getFunDllSize endp


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
;修正E9h指令代码的操作数
;入口：edi指向代码开始  ecx代码长度
;出口：eax要修正的操作数个数
;------------------------------
get_E9h  proc _lpFile,_lpFile1
   local @value,@value1,@off
   local @ret
   local @valueNew
   pushad
   mov @ret,0

   .repeat
     mov bl,byte ptr [edi]
     .if bl==0E9h
       ;取其后的一个字   E9 43 02 04 00
       mov ebx,dword ptr [edi+1]
       mov @value,ebx

       .if ebx==0FFFFFFF0h
         mov ebx,edi
         add ebx,5             ;加上E9指令本身的5个字节
         sub ebx,lpDstMemory
         ;求内存中的地址
         invoke _OffsetToRVA,_lpFile1,ebx
         mov edx,eax
         mov eax,dwDstEntryPoint
         sub eax,edx
         mov @valueNew,eax
         mov edx,0e9h
         pushad
         invoke wsprintf,addr szBuffer,addr szOut3314,ebx,edx,@value,@valueNew
         invoke _appendInfo,addr szBuffer
         popad
         ;更正代码中的操作数地址
         mov eax,@valueNew
         mov dword ptr [edi+1],eax         

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
get_E9h  endp
;------------------------------
;修正A3h指令代码的操作数
;入口：edi指向代码开始  ecx代码长度
;出口：eax要修正的操作数个数
;------------------------------
get_A3h  proc _lpFile
   local @value,@value1,@off
   local @ret
   local @valueNew
   pushad
   mov @ret,0
   mov eax,dwPatchImageBase     ;补丁基地址:040000h
   add eax,dwPatchMemDataStart  ;补丁数据段起始地址：003000h
   mov @value1,eax
   .repeat
     mov bl,byte ptr [edi]
     .if bl==0a3h
       ;取其后的一个字   A3 43 02 04 00
       mov ebx,dword ptr [edi+1]
       mov @value,ebx
       mov eax,@value            ;计算RVA中距离数据段起始的偏移量@off。以便修正新的RVA地址
       sub eax,@value1
       mov @off,eax

       and ebx,0ffff0000h
       ;判断该双字是否以ImageBase开始
       mov edx,dwPatchImageBase
       and edx,0FFFF0000h
       .if ebx==edx
         mov ebx,edi
         sub ebx,lpDstMemory
         mov edx,0a3h
         push ecx
         mov eax,dwDataInMemStart   ;计算新文件中数据在内存的地址@valueNew
         add eax,@off
         mov @valueNew,eax
         invoke wsprintf,addr szBuffer,addr szOut3313,ebx,edx,@value,@off,@valueNew
         invoke _appendInfo,addr szBuffer
         pop ecx
         
         ;更正代码中的操作数地址
         mov eax,@valueNew
         mov dword ptr [edi+1],eax         

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
get_A3h  endp
;------------------------------
;修正B8h指令代码的操作数
;入口：edi指向代码开始  ecx代码长度
;出口：eax要修正的操作数个数
;------------------------------
get_B8h  proc _lpFile
   local @value,@value1,@off
   local @ret
   local @valueNew
   pushad
   mov @ret,0
   mov eax,dwPatchImageBase     ;补丁基地址:040000h
   add eax,dwPatchMemDataStart  ;补丁数据段起始地址：003000h
   mov @value1,eax
   .repeat
     mov bl,byte ptr [edi]
     .if bl==0B8h
       ;取其后的一个字   B8 43 02 04 00
       mov ebx,dword ptr [edi+1]
       mov @value,ebx
       mov eax,@value            ;计算RVA中距离数据段起始的偏移量@off。以便修正新的RVA地址
       sub eax,@value1
       mov @off,eax

       and ebx,0ffff0000h
       ;判断该双字是否以ImageBase开始
       mov edx,dwPatchImageBase
       and edx,0FFFF0000h
       .if ebx==edx
         mov ebx,edi
         sub ebx,lpDstMemory
         mov edx,0b8h
         push ecx
         mov eax,dwDataInMemStart   ;计算新文件中数据在内存的地址@valueNew
         add eax,@off
         mov @valueNew,eax
         invoke wsprintf,addr szBuffer,addr szOut3313,ebx,edx,@value,@off,@valueNew
         invoke _appendInfo,addr szBuffer
         pop ecx
         
         ;更正代码中的操作数地址
         mov eax,@valueNew
         mov dword ptr [edi+1],eax         

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
get_B8h  endp
;------------------------------
;修正68h指令代码的操作数
;入口：edi指向代码开始  ecx代码长度
;出口：eax要修正的操作数个数
;------------------------------
get_68h  proc _lpFile
   local @value,@value1,@off
   local @ret
   local @valueNew
   pushad
   mov @ret,0
   mov eax,dwPatchImageBase     ;补丁基地址:040000h
   add eax,dwPatchMemDataStart  ;补丁数据段起始地址：003000h
   mov @value1,eax
   .repeat
     mov bl,byte ptr [edi]
     .if bl==68h
       ;取其后的一个字   68 43 02 04 00
       mov ebx,dword ptr [edi+1]
       mov @value,ebx
       mov eax,@value            ;计算RVA中距离数据段起始的偏移量@off。以便修正新的RVA地址
       sub eax,@value1
       mov @off,eax

       and ebx,0ffff0000h
       ;判断该双字是否以ImageBase开始
       mov edx,dwPatchImageBase
       and edx,0FFFF0000h
       .if ebx==edx
         mov ebx,edi
         sub ebx,lpDstMemory
         mov edx,68h
         push ecx
         mov eax,dwDataInMemStart   ;计算新文件中数据在内存的地址@valueNew
         add eax,@off
         mov @valueNew,eax
         invoke wsprintf,addr szBuffer,addr szOut3313,ebx,edx,@value,@off,@valueNew
         invoke _appendInfo,addr szBuffer
         pop ecx
         
         ;更正代码中的操作数地址
         mov eax,@valueNew
         mov dword ptr [edi+1],eax         

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

;---------------------------------
; 根据原操作数的值获取指令FF 25新操作数的值
;---------------------------------
getNewValue  proc  _lpFile,_lpFile1,_dwValue
   local @value,@value1,@lpNewJmp,@newValue
   local @ret
   pushad

   ;获取value2
   mov eax,_dwValue
   sub eax,dwPatchImageBase
   mov ebx,_lpFile

   ;获取该位置所在的值
   invoke _RVAToOffset,_lpFile,eax
   mov esi,eax
   add esi,_lpFile
   mov eax,dword ptr [esi]
   
   mov esi,offset lpImportChange       
   .repeat 
     mov ebx,dword ptr [esi]
     .if ebx==eax
       add esi,4
       mov eax,dword ptr [esi]
       mov @newValue,eax
       .break           
     .else
       add esi,8
     .endif
   .until FALSE 
   ;查找value2，并记录找到的位置@lpNewJmp
   mov esi,dwDstImportInFileStart
   add esi,lpDstMemory
   mov eax,@newValue
   .repeat
     mov ebx,dword ptr [esi]
     .if ebx==eax   ;找到该值
       sub esi,lpDstMemory
       mov @lpNewJmp,esi
       .break       
     .else
       add esi,4
     .endif
   .until FALSE
   ;计算新位置在新文件中的内存中的地址
   mov eax,@lpNewJmp
   invoke _OffsetToRVA,_lpFile1,eax
   mov @ret,eax
   popad
   mov eax,@ret
   ret
getNewValue  endp
;------------------------------
;修正FF 25指令代码的操作数  该操作数与导入表有密切关系
;入口：edi指向代码开始  ecx代码长度
;出口：eax要修正的操作数个数
;  首先，通过补丁程序中FF 25指令后的操作数查找原补丁程序对应位置的值value
;  其次，通过查询内存lpImportChange中的配对值获取新的value2
;  最后，从dwDstImportInFileStart开始查找value2并记录该位置lpNewJump
;  获取到的lpNewJump值通过函数_OffsetToRVA转换即为FF 25操作数后的新值
;------------------------------
get_FF25h  proc _lpFile,_lpFile1
   local @value,@value1,@off
   local @ret
   local @valueNew

   
   pushad
   mov @ret,0
   mov eax,dwPatchImageBase     ;补丁基地址:040000h
   add eax,dwPatchMemDataStart  ;补丁数据段起始地址：003000h
   mov @value1,eax
   .repeat
     mov bx,word ptr [edi]
     .if bx==25FFh
       ;取其后的一个字   FF 25 43 02 04 00
       mov ebx,dword ptr [edi+2]
       mov @value,ebx
       and ebx,0ffff0000h
       ;判断该双字是否以ImageBase开始
       mov edx,dwPatchImageBase
       and edx,0FFFF0000h
       .if ebx==edx
         mov ebx,edi
         sub ebx,lpDstMemory
         mov edx,25FFh
         push ecx
         invoke getNewValue,_lpFile,_lpFile1,@value   ;获取新的值
         add eax,dwDstImageBase
         mov @value1,eax
         invoke wsprintf,addr szBuffer,addr szOut3314,ebx,edx,@value,@value1
         invoke _appendInfo,addr szBuffer
         pop ecx
         
         ;更正代码中的操作数地址
         mov eax,@value1
         mov dword ptr [edi+2],eax         

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
   local @value,@value1,@off
   local @ret
   local @valueNew
   pushad
   mov @ret,0
   mov eax,dwPatchImageBase     ;补丁基地址:040000h
   add eax,dwPatchMemDataStart  ;补丁数据段起始地址：003000h
   mov @value1,eax
   .repeat
     mov bx,word ptr [edi]
     .if bx==35FFh
       ;取其后的一个字   FF 35 43 02 04 00
       mov ebx,dword ptr [edi+2]
       mov @value,ebx
       mov eax,@value            ;计算RVA中距离数据段起始的偏移量@off。以便修正新的RVA地址
       sub eax,@value1
       mov @off,eax
       and ebx,0ffff0000h
       ;判断该双字是否以ImageBase开始
       mov edx,dwPatchImageBase
       and edx,0FFFF0000h
       .if ebx==edx
         mov ebx,edi
         sub ebx,lpDstMemory
         mov edx,35FFh
         push ecx
         mov eax,dwDataInMemStart   ;计算新文件中数据在内存的地址@valueNew
         add eax,@off
         mov @valueNew,eax
         invoke wsprintf,addr szBuffer,addr szOut3313,ebx,edx,@value,@off,@valueNew
         invoke _appendInfo,addr szBuffer
         pop ecx
         
         ;更正代码中的操作数地址
         mov eax,@valueNew
         mov dword ptr [edi+2],eax         

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


;------------------------------
;修正FF 05指令代码的操作数
;入口：edi指向代码开始  ecx代码长度
;出口：eax要修正的操作数个数
;------------------------------
get_FF05h  proc _lpFile
   local @value,@value1,@off
   local @ret
   local @valueNew
   pushad
   mov @ret,0
   mov eax,dwPatchImageBase     ;补丁基地址:040000h
   add eax,dwPatchMemDataStart  ;补丁数据段起始地址：003000h
   mov @value1,eax
   .repeat
     mov bx,word ptr [edi]
     .if bx==05FFh
       ;取其后的一个字   FF 05 43 02 04 00
       mov ebx,dword ptr [edi+2]
       mov @value,ebx
       mov eax,@value            ;计算RVA中距离数据段起始的偏移量@off。以便修正新的RVA地址
       sub eax,@value1
       mov @off,eax
       and ebx,0ffff0000h
       ;判断该双字是否以ImageBase开始
       mov edx,dwPatchImageBase
       and edx,0FFFF0000h
       .if ebx==edx
         mov ebx,edi
         sub ebx,lpDstMemory
         mov edx,05FFh
         push ecx
         mov eax,dwDataInMemStart   ;计算新文件中数据在内存的地址@valueNew
         add eax,@off
         mov @valueNew,eax
         invoke wsprintf,addr szBuffer,addr szOut3313,ebx,edx,@value,@off,@valueNew
         invoke _appendInfo,addr szBuffer
         pop ecx
         
         ;更正代码中的操作数地址
         mov eax,@valueNew
         mov dword ptr [edi+2],eax         

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
get_FF05h  endp

;------------------------------
;修正03 05指令代码的操作数
;入口：edi指向代码开始  ecx代码长度
;出口：eax要修正的操作数个数
;------------------------------
get_0305h  proc _lpFile
   local @value,@value1,@off
   local @ret
   local @valueNew
   pushad
   mov @ret,0
   mov eax,dwPatchImageBase     ;补丁基地址:040000h
   add eax,dwPatchMemDataStart  ;补丁数据段起始地址：003000h
   mov @value1,eax
   .repeat
     mov bx,word ptr [edi]
     .if bx==0503h
       ;取其后的一个字   03 05 43 02 04 00
       mov ebx,dword ptr [edi+2]
       mov @value,ebx
       mov eax,@value            ;计算RVA中距离数据段起始的偏移量@off。以便修正新的RVA地址
       sub eax,@value1
       mov @off,eax
       and ebx,0ffff0000h
       ;判断该双字是否以ImageBase开始
       mov edx,dwPatchImageBase
       and edx,0FFFF0000h
       .if ebx==edx
         mov ebx,edi
         sub ebx,lpDstMemory
         mov edx,0503h
         push ecx
         mov eax,dwDataInMemStart   ;计算新文件中数据在内存的地址@valueNew
         add eax,@off
         mov @valueNew,eax
         invoke wsprintf,addr szBuffer,addr szOut3313,ebx,edx,@value,@off,@valueNew
         invoke _appendInfo,addr szBuffer
         pop ecx
         
         ;更正代码中的操作数地址
         mov eax,@valueNew
         mov dword ptr [edi+2],eax         

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
get_0305h  endp

;------------------------
; 数据段
;------------------------
_dealData   proc _lpFile1,_lpFile2
  local @bufTemp1[10]:byte
  local @dwTemp:dword,@dwTemp1:dword

  pushad
  ;到此为止，两个内存文件的指针已经获取到了。_lpFile1和_lpFile2分别指向两个文件头
  ;下面是从这个文件头开始，找出各数据结构的字段值，进行比较。


  ;获取补丁文件数据段的大小
  invoke getDataSize,_lpFile1
  mov dwPatchDataSize,eax

  .if eax==0  ;未找到存放数据的节
    invoke _appendInfo,addr szErr110
  .else
    invoke wsprintf,addr szBuffer,addr szOut11,eax
    invoke _appendInfo,addr szBuffer
  .endif



  ;获取补丁文件数据段在文件中的起始位置
  invoke getDataStart,_lpFile1
  mov dwPatchDataStart,eax

  invoke wsprintf,addr szBuffer,addr szOut12,eax
  invoke _appendInfo,addr szBuffer

  ;获取补丁数据段在内存中的起始位置
  invoke getDataStartInMem,_lpFile1
  mov dwPatchMemDataStart,eax

  invoke wsprintf,addr szBuffer,addr szOut2217,eax
  invoke _appendInfo,addr szBuffer

  ;获取目标文件数据段的大小
  invoke getDataSize,_lpFile2
  mov dwDstDataSize,eax

  invoke wsprintf,addr szBuffer,addr szOut13,eax
  invoke _appendInfo,addr szBuffer

  ;获取目标文件数据段在内存中的起始位置
  invoke getDataStart,_lpFile2
  mov dwDstDataStart,eax

  invoke wsprintf,addr szBuffer,addr szOut14,eax
  invoke _appendInfo,addr szBuffer

  ;获取目标文件数据段在文件中对齐后的大小
  invoke getRawDataSize,_lpFile2
  mov dwDstRawDataSize,eax

  invoke wsprintf,addr szBuffer,addr szOut15,eax
  invoke _appendInfo,addr szBuffer

  ;获取目标数据段在内存中的起始位置
  invoke getDataStartInMem,_lpFile2
  mov dwDstMemDataStart,eax

  invoke wsprintf,addr szBuffer,addr szOut17,eax
  invoke _appendInfo,addr szBuffer


  ;从本节的最后一个位置起往前查找连续的全0字符
  mov eax,dwDstDataStart
  add eax,dwDstRawDataSize  ;定位到本节的最后一个字节
  mov ecx,dwPatchDataSize
  mov esi,_lpFile2
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

    mov esi,_lpFile2
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
    
    invoke wsprintf,addr szBuffer,addr szOut16,@dwTemp,dwPatchDataSize,@dwTemp1
    invoke _appendInfo,addr szBuffer

 
    ;将补丁数据拷贝到目标文件指定位置处                 （1）
    mov edi,lpDstMemory
    add edi,@dwTemp1

    mov esi,_lpFile1
    add esi,dwPatchDataStart
    mov ecx,dwPatchDataSize
    rep movsb

    ;记录新文件中数据段起始位置在内存中的地址

    invoke getImageBase,_lpFile2
    mov dwDstImageBase,eax
    invoke _OffsetToRVA,_lpFile2,@dwTemp1
    add eax,dwDstImageBase
    mov dwDataInMemStart,eax
    invoke wsprintf,addr szBuffer,addr szOut19,eax
    invoke _appendInfo,addr szBuffer

  .else       ;数据段空间不够
    invoke _appendInfo,addr szErr11
  .endif

  invoke _appendInfo,addr szoutLine


  popad
  ret
_dealData   endp


;------------------------
; 修正补丁导入表FirstThunk参数
; 指针lpImportChange处存放了要修正的值及修正以后的值的所有组合
;------------------------
pasteImport_fun2 proc _lpFile,_lpFile1
  local @szBuffer[1024]:byte
  local @szSectionName[16]:byte
  local _lpPeHead
  local @dwDlls,@dwFuns,@dwFunctions
  local @dwSize,@newValue
  
  pushad
  mov esi,_lpFile
  assume esi:ptr IMAGE_DOS_HEADER
  add esi,[esi].e_lfanew    ;调整esi指针指向PE文件头
  assume esi:ptr IMAGE_NT_HEADERS
  mov eax,[esi].OptionalHeader.DataDirectory[8].VirtualAddress
  .if !eax
    jmp @F
  .endif
  invoke _RVAToOffset,_lpFile,eax
  add eax,_lpFile
  mov esi,eax     ;计算引入表所在文件偏移位置
  assume esi:ptr IMAGE_IMPORT_DESCRIPTOR
  invoke _getRVASectionName,_lpFile,[esi].OriginalFirstThunk

  mov @dwSize,0

  .while [esi].OriginalFirstThunk || [esi].TimeDateStamp ||\
         [esi].ForwarderChain || [esi].Name1 || [esi].FirstThunk

    invoke _RVAToOffset,_lpFile,[esi].FirstThunk
    mov edi,eax
    add edi,_lpFile  ;定位到FirstThunk指向的数组



    .while dword ptr [edi]
       mov eax,dword ptr [edi]
       inc @dwSize

       ;查询lpImportChange,找到修正值
       pushad
       mov esi,offset lpImportChange       
       .repeat 
         mov ebx,dword ptr [esi]
         .if ebx==eax
           add esi,4
           mov eax,dword ptr [esi]
           mov @newValue,eax
           .break           
         .else
           add esi,8
         .endif
       .until FALSE 
       ;将修正后的FirstThunk值写入新文件   （7）
       mov edi,dwDstImportInFileStart
       add edi,lpDstMemory
       mov eax,@dwSize
       dec eax
       mov bl,4
       mul bl
       add edi,eax

       mov eax,@newValue
       mov dword ptr [edi],eax
       popad

       add edi,4
    .endw

    ;写入零结构
    inc @dwSize
    mov edi,dwDstImportInFileStart
    add edi,lpDstMemory
    mov eax,@dwSize
    dec eax
    mov bl,4
    mul bl
    add edi,eax
    mov dword ptr [edi],0 
    add esi,sizeof IMAGE_IMPORT_DESCRIPTOR
  .endw
  add edi,4
  mov lpOriginalFirstThunk,edi

@@:
  assume esi:nothing
  popad
  mov eax,@dwSize
  ret
pasteImport_fun2 endp

;-----------------------
; 获取指定编号的动态链接库FirstThunk的内存地址
;-----------------------
getNewFirstThunk  proc  _lpFile,_lpFile1,_dwSize
  local @ret
  local @dwSize,@dwTemp


  pushad
  mov eax,_dwSize
  mov esi,dwDstImportInFileStart
  add esi,lpDstMemory
  dec _dwSize
  .repeat
    .break .if _dwSize==0
    mov eax,dword ptr [esi]    
    .if eax==0
      dec _dwSize
    .endif
    add esi,4
  .until FALSE

  sub esi,lpDstMemory
  invoke _OffsetToRVA,_lpFile1,esi
  mov @ret,eax   
  popad
  mov eax,@ret
  ret
getNewFirstThunk endp

;-----------------------
; 获取指定编号的动态链接库OriginalFirstThunk的内存地址
;-----------------------
getNewOriginalFirstThunk  proc  _lpFile,_lpFile1,_dwSize
  local @ret
  local @dwSize,@dwTemp


  pushad
  mov esi,lpOriginalFirstThunk
  dec _dwSize
  .repeat
    .break .if _dwSize==0
    mov eax,dword ptr [esi]    
    .if eax==0
      dec _dwSize
    .endif
    add esi,4
  .until FALSE

  sub esi,lpDstMemory
  invoke _OffsetToRVA,_lpFile1,esi
  mov @ret,eax   
  popad
  mov eax,@ret
  ret
getNewOriginalFirstThunk endp
;------------------------
; 返回第_dwSize个DLL动态链接库的名称
; 所在位置的地址
;------------------------
getDllName proc _lpFile,_lpFile1,_dwSize
  local @szBuffer[1024]:byte
  local @szSectionName[16]:byte
  local _lpCurrent
  local @dwDlls,@dwFuns,@dwFunctions
  local @dwSize
  local @dwTemp,@dwTemp1

  pushad
  mov esi,_lpFile
  assume esi:ptr IMAGE_DOS_HEADER
  add esi,[esi].e_lfanew    ;调整ESI指针指向PE文件头
  assume esi:ptr IMAGE_NT_HEADERS
  mov eax,[esi].OptionalHeader.DataDirectory[8].VirtualAddress
  .if !eax
    jmp @F
  .endif
  invoke _RVAToOffset,_lpFile,eax
  add eax,_lpFile
  mov esi,eax     ;计算引入表所在文件偏移位置
  assume esi:ptr IMAGE_IMPORT_DESCRIPTOR
  invoke _getRVASectionName,_lpFile,[esi].OriginalFirstThunk

  mov @dwSize,0

  .while [esi].OriginalFirstThunk || [esi].TimeDateStamp ||\
         [esi].ForwarderChain || [esi].Name1 || [esi].FirstThunk
    inc @dwSize
    mov eax,_dwSize
    .if eax==@dwSize
       invoke _RVAToOffset,_lpFile,[esi].Name1
       add eax,_lpFile
       mov @dwSize,eax
       .break
    .endif
    add esi,sizeof IMAGE_IMPORT_DESCRIPTOR
  .endw

@@:
  assume esi:nothing
  popad
  mov eax,@dwSize
  ret
getDllName endp

;------------------------
; 修正补丁导入表OriginalFirstThunk参数
; 指针lpImportChange处存放了要修正的值及修正以后的值的所有组合
;------------------------
pasteImport_fun3 proc _lpFile,_lpFile1
  local @szBuffer[1024]:byte
  local @szSectionName[16]:byte
  local _lpPeHead
  local @dwDlls,@dwFuns,@dwFunctions
  local @dwSize,@newValue
  local @dwTemp,@dwTemp1
  
  pushad
  mov esi,_lpFile
  assume esi:ptr IMAGE_DOS_HEADER
  add esi,[esi].e_lfanew    ;调整esi指针指向PE文件头
  assume esi:ptr IMAGE_NT_HEADERS
  mov eax,[esi].OptionalHeader.DataDirectory[8].VirtualAddress
  .if !eax
    jmp @F
  .endif
  invoke _RVAToOffset,_lpFile,eax
  add eax,_lpFile
  mov esi,eax     ;计算引入表所在文件偏移位置
  assume esi:ptr IMAGE_IMPORT_DESCRIPTOR
  invoke _getRVASectionName,_lpFile,[esi].OriginalFirstThunk

  mov @dwSize,0

  .while [esi].OriginalFirstThunk || [esi].TimeDateStamp ||\
         [esi].ForwarderChain || [esi].Name1 || [esi].FirstThunk

    invoke _RVAToOffset,_lpFile,[esi].OriginalFirstThunk
    mov edi,eax
    add edi,_lpFile  ;定位到OriginalFirstThunk指向的数组



    .while dword ptr [edi]
       mov eax,dword ptr [edi]
       inc @dwSize

       ;查询lpImportChange,找到修正值
       pushad
       mov esi,offset lpImportChange       
       nop
       nop

       .repeat 
         mov ebx,dword ptr [esi]
         .if ebx==eax
           add esi,4
           mov eax,dword ptr [esi]
           mov @newValue,eax
           .break           
         .else
           add esi,8
         .endif
       .until FALSE 
       ;将修正后的值@newValue写入新文件        （8）
       mov edi,lpOriginalFirstThunk
       mov eax,@dwSize
       dec eax
       mov bl,4
       mul bl
       add edi,eax

       mov eax,@newValue
       mov dword ptr [edi],eax
       popad

       add edi,4
    .endw

    ;写入零结构
    inc @dwSize
    mov edi,lpOriginalFirstThunk
    mov eax,@dwSize
    dec eax
    mov bl,4
    mul bl
    add edi,eax
    mov dword ptr [edi],0    

    add esi,sizeof IMAGE_IMPORT_DESCRIPTOR
  .endw


  mov edi,lpPImportInNewFile  ;补丁导入表在新文件中的位置
  add edi,lpDstMemory
  assume edi:ptr IMAGE_IMPORT_DESCRIPTOR
  mov ecx,dwPatchDLLCount

  mov @dwSize,0
  .repeat
    inc @dwSize
    ;获取文件偏移量
    mov ebx,dword ptr [edi].FirstThunk   ;@dwTemp中存放着FirstThunk的初始值
    mov @dwTemp,ebx
    
    ;从FirstThunk指向的数组中查找，@dwSize为第几个动态链接库。实际上就是找第几个为零的偏移地址
    invoke getNewFirstThunk,_lpFile,_lpFile1,@dwSize
    mov @dwTemp1,eax                     ;@dwTemp1中存放着FirstThunk的修正值     (9)
    mov dword ptr [edi].FirstThunk,eax   ;修正

    invoke getDllName,_lpFile,_lpFile1,@dwSize

    ;显示输出更改前的.Name1值与更改后的.Name1值
    pushad
    invoke wsprintf,addr szBuffer,addr szOut1915,eax,@dwTemp,@dwTemp1
    invoke _appendInfo,addr szBuffer    
    popad

    mov ebx,dword ptr [edi].OriginalFirstThunk   ;@dwTemp中存放着OriginalFirstThunk的初始值
    mov @dwTemp,ebx
    
    ;从FirstThunk指向的数组中查找，@dwSize为第几个动态链接库。实际上就是找第几个为零的偏移地址
    invoke getNewOriginalFirstThunk,_lpFile,_lpFile1,@dwSize
    mov @dwTemp1,eax                     ;@dwTemp1中存放着OriginalFirstThunk的修正值   (10)
    mov dword ptr [edi].OriginalFirstThunk,eax   ;修正

    invoke getDllName,_lpFile,_lpFile1,@dwSize

    ;显示输出更改前的.Name1值与更改后的.Name1值
    pushad
    invoke wsprintf,addr szBuffer,addr szOut1916,eax,@dwTemp,@dwTemp1
    invoke _appendInfo,addr szBuffer    
    popad



    add edi,sizeof IMAGE_IMPORT_DESCRIPTOR
    dec ecx
    .break .if ecx==0
  .until FALSE  
  
@@:
  assume esi:nothing
  popad
  mov eax,@dwSize
  ret
pasteImport_fun3 endp

;------------------------
; 补丁导入表函数调用数据引入及参数修正
; _off为新文件中存放补丁导入表函数常量的位置
;------------------------
pasteImport_fun proc _lpFile,_lpFile1,_off
  local @szBuffer[1024]:byte
  local @szSectionName[16]:byte
  local _lpPeHead
  local @dwDlls,@dwFuns,@dwFunctions
  local @dwSize,@dwTemp,@dwTemp1
  local @lpFirstThunk,@lpImportChange
  
  pushad
  mov esi,_lpFile
  assume esi:ptr IMAGE_DOS_HEADER
  add esi,[esi].e_lfanew    ;调整ESI指针指向PE文件头
  assume esi:ptr IMAGE_NT_HEADERS
  mov eax,[esi].OptionalHeader.DataDirectory[8].VirtualAddress
  .if !eax
    jmp @F
  .endif
  invoke _RVAToOffset,_lpFile,eax
  add eax,_lpFile
  mov esi,eax     ;计算引入表所在文件偏移位置
  assume esi:ptr IMAGE_IMPORT_DESCRIPTOR
  invoke _getRVASectionName,_lpFile,[esi].OriginalFirstThunk

  mov edi,_off

  ;初始化@lpFirstThunk，使其指向原目标文件的导入表位置（此处数据已转移）
  mov eax,dwDstImportInFileStart
  add eax,lpDstMemory
  mov @lpFirstThunk,eax

  ;为导入表修正值结构赋值
  mov eax,offset lpImportChange
  mov @lpImportChange,eax

  mov @dwSize,0


  .while [esi].OriginalFirstThunk || [esi].TimeDateStamp ||\
         [esi].ForwarderChain || [esi].Name1 || [esi].FirstThunk

    ;获取IMAGE_THUNK_DATA列表到EBX
    .if [esi].OriginalFirstThunk
      mov eax,[esi].OriginalFirstThunk
    .else
      mov eax,[esi].FirstThunk
    .endif
    invoke _RVAToOffset,_lpFile,eax
    add eax,_lpFile
    mov ebx,eax

    push edi
    mov edi,@lpFirstThunk

    .while dword ptr [ebx]
      .if dword ptr [ebx] & IMAGE_ORDINAL_FLAG32 ;按序号导入，无字符串常量
        mov eax,dword ptr [ebx]
        ; 将该值原样写入原目标文件导入表所在位置
        mov dword ptr [edi],eax
      .else                                      ;按名称导入
        invoke _RVAToOffset,_lpFile,dword ptr [ebx]
        add eax,_lpFile
        assume eax:ptr IMAGE_IMPORT_BY_NAME
        push esi
        push ecx
        push ebx


        push edi
        mov edi,_off
        mov esi,eax

        ;显示每个函数的偏移量及修正值
        pushad 
        ;补丁程序偏移
        mov eax,esi
        sub eax,_lpFile
        invoke _OffsetToRVA,_lpFile,eax
        mov @dwTemp,eax
        ;目标程序偏移
        mov eax,edi
        sub eax,lpDstMemory
        invoke _OffsetToRVA,_lpFile1,eax
        mov @dwTemp1,eax
        
        add esi,2

        ;将修正前的值和修正后的值排列到lpImportChange处   （6）
        mov edi,offset lpImportChange
        mov eax,@dwSize
        mov bl,4
        mul bl
        add edi,eax
        mov eax,@dwTemp
        mov dword ptr [edi],eax
        inc @dwSize

        mov edi,offset lpImportChange
        mov eax,@dwSize
        mov bl,4
        mul bl
        add edi,eax
        mov eax,@dwTemp1 
        mov dword ptr [edi],eax
        inc @dwSize

        invoke wsprintf,addr szBuffer,addr szOut1913,esi,@dwTemp,@dwTemp1
        invoke _appendInfo,addr szBuffer    

        popad

        mov bx,word ptr [esi]  ; 函数编号
        mov word ptr [edi],bx
        add esi,2
        add edi,2
        add _off,2
        mov cx,0
        .repeat
          mov bl,byte ptr[esi]
          inc cx
          .if bl!=0   ;不为0，表示未结束
            mov byte ptr [edi],bl
            inc edi
            inc _off
          .else       ;是0，则看看计数值是否为偶数，如果是，则@dwSize多加一，因为偶数函数名后为两个零
            test cx,1
            jz @1   
            mov byte ptr [edi],0   ;字符个数为偶数，写两个零
            inc _off
            inc edi
            mov byte ptr [edi],0
            inc _off
            inc edi
            jmp @2
@1:         mov byte ptr [edi],0   ;字符个数为奇数，写一个零
            inc _off
            inc edi
@2:         .break
          .endif
          inc esi          
        .until FALSE
        pop edi

        pop ebx
        pop ecx
        pop esi

        assume eax:nothing
      .endif
      add edi,4
      add ebx,4
    .endw
    mov dword ptr [edi],0  ;写入0字节
    add edi,4
    mov @lpFirstThunk,edi  ;修正指针
    pop edi

    add esi,sizeof IMAGE_IMPORT_DESCRIPTOR
  .endw
  ;修正导入表FirstThunk两个数组的值
  invoke pasteImport_fun2,_lpFile,_lpFile1
  invoke pasteImport_fun3,_lpFile,_lpFile1

@@:
  assume esi:nothing
  popad
  mov eax,@dwSize
  ret
pasteImport_fun endp


;------------------------
; 补丁导入表常量数据引入及参数修正
; _off为新文件中存放补丁导入表常量的位置
;------------------------
pasteImport proc _lpFile,_lpFile1,_off
  local @szBuffer[1024]:byte
  local @szSectionName[16]:byte
  local _lpCurrent
  local @dwDlls,@dwFuns,@dwFunctions
  local @dwSize
  local @dwTemp,@dwTemp1

  pushad
  mov esi,_lpFile
  assume esi:ptr IMAGE_DOS_HEADER
  add esi,[esi].e_lfanew    ;调整ESI指针指向PE文件头
  assume esi:ptr IMAGE_NT_HEADERS
  mov eax,[esi].OptionalHeader.DataDirectory[8].VirtualAddress
  .if !eax
    jmp @F
  .endif
  invoke _RVAToOffset,_lpFile,eax
  add eax,_lpFile
  mov esi,eax     ;计算引入表所在文件偏移位置
  assume esi:ptr IMAGE_IMPORT_DESCRIPTOR
  invoke _getRVASectionName,_lpFile,[esi].OriginalFirstThunk

  mov edi,_off

  mov @dwSize,0

  .while [esi].OriginalFirstThunk || [esi].TimeDateStamp ||\
         [esi].ForwarderChain || [esi].Name1 || [esi].FirstThunk
    mov @dwFuns,0
    invoke _RVAToOffset,_lpFile,[esi].Name1
    add eax,_lpFile
    push esi
    push ecx
    push ebx
    
    mov esi,eax
    mov cx,0
    .repeat
       mov bl,byte ptr[esi]
       mov byte ptr [edi],bl
       inc edi
 
       inc cx

       .if bl==0 ;是0
         .break
       .endif
       inc esi          
    .until FALSE
    pop ebx
    pop ecx
    pop esi
    mov byte ptr [edi],0   ;每个DLL名称后都有两个0
    inc edi
    add esi,sizeof IMAGE_IMPORT_DESCRIPTOR
  .endw
  mov _lpCurrent,edi

  ;修正导入表中指向动态链接库常量字符串的RVA值      （5）
  mov edi,lpPImportInNewFile
  add edi,lpDstMemory
  assume edi:ptr IMAGE_IMPORT_DESCRIPTOR
  mov ecx,dwPatchDLLCount

  ;esi指向新文件中DLL常量字符串起始
  mov esi,_off
  .repeat
    ;获取文件偏移量
    mov ebx,dword ptr [edi].Name1
    mov @dwTemp,ebx

    mov eax,esi
    sub eax,lpDstMemory
    ;获取在目标文件内存中的偏移量
    invoke _OffsetToRVA,_lpFile1,eax
    mov @dwTemp1,eax

    ;显示输出更改前的.Name1值与更改后的.Name1值     
    pushad
    invoke _appendInfo,addr szCrLf
    invoke _appendInfo,addr szOut1911  
    invoke _appendInfo,addr szCrLf 
    invoke wsprintf,addr szBuffer,addr szOut1912,esi,@dwTemp,@dwTemp1
    invoke _appendInfo,addr szBuffer    
    popad

    ;修正.Name1的值
    mov dword ptr [edi].Name1,eax
    add edi,sizeof IMAGE_IMPORT_DESCRIPTOR

    ;重新计算esi的值
    .repeat
      mov bl,byte ptr[esi]
      inc esi
      .if bl==0
        inc esi
        .break
      .endif
    .until FALSE
    dec ecx
    .break .if ecx==0
  .until FALSE  

  ;紧接着修正函数调用部分
  invoke pasteImport_fun,_lpFile,_lpFile1,_lpCurrent 


  ;修正数据目录表中对导入表的描述(RVA地址和大小)
  mov esi,lpDstMemory
  assume esi:ptr IMAGE_DOS_HEADER
  add esi,[esi].e_lfanew    ;调整ESI指针指向PE文件头
  assume esi:ptr IMAGE_NT_HEADERS
  mov ebx,[esi].OptionalHeader.DataDirectory[8].VirtualAddress
  mov ecx,[esi].OptionalHeader.DataDirectory[8].isize
  mov eax,lpNewImport
  invoke _OffsetToRVA,_lpFile1,eax
  mov [esi].OptionalHeader.DataDirectory[8].VirtualAddress,eax
  mov edx,dwNewImportSize  ;修正大小
  mov [esi].OptionalHeader.DataDirectory[8].isize,edx

  ;输出
  invoke _appendInfo,addr szCrLf  
  invoke _appendInfo,addr szOut1917  
  invoke _appendInfo,addr szCrLf 
  pushad
  invoke wsprintf,addr szBuffer,addr szOut1918,ebx,eax
  popad
  invoke _appendInfo,addr szBuffer    
  pushad
  invoke wsprintf,addr szBuffer,addr szOut1919,ecx,edx
  popad
  invoke _appendInfo,addr szBuffer    
  invoke _appendInfo,addr szCrLf  
  
@@:
  assume esi:nothing
  popad
  mov eax,@dwSize
  ret
pasteImport endp




;------------------------
; 导入表
;------------------------
_dealImport   proc _lpFile1,_lpFile2
  local @bufTemp1[10]:byte
  local @dwTemp:dword,@dwTemp1:dword

  pushad
  ;获取补丁导入表所在节的大小
  invoke getImportSegSize,_lpFile1
  mov dwPatchImportSegSize,eax

  invoke wsprintf,addr szBuffer,addr szOut221,eax
  invoke _appendInfo,addr szBuffer

  ;获取补丁导入表所在节在文件中的起始位置
  invoke getImportSegStart,_lpFile1
  mov dwPatchImportSegStart,eax

  invoke wsprintf,addr szBuffer,addr szOut22,eax
  invoke _appendInfo,addr szBuffer

  ;获取补丁导入表在文件中的起始位置
  invoke getImportInFileStart,_lpFile1
  mov dwPatchImportInFileStart,eax

  invoke wsprintf,addr szBuffer,addr szOut2912,eax
  invoke _appendInfo,addr szBuffer

  ;获取目标导入表所在节的大小
  invoke getImportSegSize,_lpFile2
  mov dwDstImportSegSize,eax

  invoke wsprintf,addr szBuffer,addr szOut23,eax
  invoke _appendInfo,addr szBuffer

  ;获取目标导入表所在节在文件中的起始位置
  invoke getImportSegStart,_lpFile2
  mov dwDstImportSegStart,eax

  invoke wsprintf,addr szBuffer,addr szOut24,eax
  invoke _appendInfo,addr szBuffer


  ;获取目标导入表在文件中的起始位置
  invoke getImportInFileStart,_lpFile2
  mov dwDstImportInFileStart,eax

  invoke wsprintf,addr szBuffer,addr szOut2911,eax
  invoke _appendInfo,addr szBuffer



  ;获取目标导入表所在节的大小
  invoke getImportSegRawSize,_lpFile2
  mov dwDstImportSegRawSize,eax

  invoke wsprintf,addr szBuffer,addr szOut25,eax
  invoke _appendInfo,addr szBuffer


  ;获取补丁导入表dll库个数和functions个数
  invoke _getImportFunctions,_lpFile1
  mov dwPatchDLLCount,eax
  mov dwPatchFunCount,ebx
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
  invoke _getImportFunctions,_lpFile2
  mov dwDstDLLCount,eax
  mov dwDstFunCount,ebx
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
  mov eax,dwDstDLLCount
  add eax,dwPatchDLLCount
  inc eax                  ;新文件调用动态链接库个数+1
  mov edx,0
  mov bx,14h
  mul bx                   ;eax中存放了新导入表大小
  mov dwNewImportSize,eax

  ;求函数名和动态链接库名的常量大小
  mov eax,0
  invoke _getFunDllSize,_lpFile1
  mov dwFunDllConstSize,eax

  add eax,dwNewImportSize   ;目标文件导入表所在节必须存在的空闲空间大小
  mov dwImportSpace2,eax

  ;目标导入表大小，含0结构
  mov eax,dwDstDLLCount
  inc eax
  mov edx,0
  mov bx,14h
  mul bx
  mov dwDstImportSize,eax

  ;补丁导入表大小，含0结构
  mov eax,dwPatchDLLCount
  inc eax
  mov edx,0
  mov bx,14h
  mul bx
  mov dwPatchImportSize,eax
  

  ;计算补丁程序IAT表和originalFirstThunk指向数组的大小之和
  mov eax,dwPatchFunCount
  add eax,dwPatchDLLCount
  mov edx,0
  mov bx,8
  mul bx
  mov dwThunkSize,eax

  
  invoke wsprintf,addr szBuffer,addr szOut2214,dwDstImportSize,dwThunkSize
  invoke _appendInfo,addr szBuffer



  invoke wsprintf,addr szBuffer,addr szOut2213,dwFunDllConstSize
  invoke _appendInfo,addr szBuffer

  invoke wsprintf,addr szBuffer,addr szOut2216,dwNewImportSize
  invoke _appendInfo,addr szBuffer
  
  

  ;从目标导入表所在节的最后一个位置起往前查找连续的全0字符
  mov eax,dwDstImportSegStart
  add eax,dwDstImportSegRawSize  ;定位到本节的最后一个字节
  mov ecx,dwImportSpace2
  mov esi,_lpFile2
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
    mov esi,_lpFile2
    add esi,eax
    dec esi
    .repeat
      mov bl,byte ptr [esi]
      .break .if bl!=0
      inc @dwTemp
      dec esi
      dec eax
    .until FALSE
    mov eax,@dwTemp1
    mov lpNewImport,eax
    
    invoke wsprintf,addr szBuffer,addr szOut26,@dwTemp,dwImportSpace2,@dwTemp1
    invoke _appendInfo,addr szBuffer

    ;将目标文件的导入表复制到指定位置         （4）
    mov esi,_lpFile2
    add esi,dwDstImportInFileStart

    mov edi,lpDstMemory
    add edi,@dwTemp1
    mov ecx,dwDstImportSize
    rep movsb

    ;此时edi指向导入表的最后一个位置，向前返回14h的零IMAGE_IMPORT_DESCRIPTOR结构
    sub edi,14h

    push edi   ;计算补丁导入表在新文件的偏移
    sub edi,lpDstMemory
    mov lpPImportInNewFile,edi
    pop edi

    ;将补丁导入表复制到紧接下来的位置          （5）
    mov esi,_lpFile1
    add esi,dwPatchImportInFileStart
    mov ecx,dwPatchImportSize
    rep movsb

    ;分析补丁导入表内容
    ;从补丁导入表获得动态链接库常量内容，添加到新文件
    invoke pasteImport,_lpFile1,_lpFile2,edi        


  .else       ;导入表段空间不够
    invoke _appendInfo,addr szErr21
    jmp @ret
  .endif

  invoke _appendInfo,addr szoutLine


@ret:
  popad
  ret
_dealImport   endp

;------------------------
; 代码段
;------------------------
_dealCode   proc _lpFile1,_lpFile2
  local @bufTemp1[10]:byte
  local @dwTemp:dword,@dwTemp1:dword
  pushad
  ;调整ESI,EDI指向DOS头
  mov esi,_lpFile1
  assume esi:ptr IMAGE_DOS_HEADER
  mov edi,_lpFile2
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

  invoke _appendInfo,addr szCrLf

  ;获取两个文件的入口地址
  invoke getEntryPoint,_lpFile1
  mov dwPatchEntryPoint,eax
  invoke getEntryPoint,_lpFile2
  mov dwDstEntryPoint,eax


  ;获取补丁代码所在节的大小
  invoke getCodeSegSize,_lpFile1
  mov dwPatchCodeSegSize,eax

  invoke wsprintf,addr szBuffer,addr szOut331,eax
  invoke _appendInfo,addr szBuffer

  ;获取补丁代码所在节在文件中的起始位置
  invoke getCodeSegStart,_lpFile1
  mov dwPatchCodeSegStart,eax

  invoke wsprintf,addr szBuffer,addr szOut332,eax
  invoke _appendInfo,addr szBuffer

  ;获取补丁代码所在节在内存中的起始位置
  invoke _OffsetToRVA,_lpFile1,dwPatchCodeSegStart
  mov dwPatchCodeSegMemStart,eax

  invoke wsprintf,addr szBuffer,addr szOut37,eax
  invoke _appendInfo,addr szBuffer



  ;获取目标代码所在节的大小
  invoke getCodeSegSize,_lpFile2
  mov dwDstCodeSegSize,eax

  invoke wsprintf,addr szBuffer,addr szOut33,eax
  invoke _appendInfo,addr szBuffer

  ;获取目标代码所在节在文件中的起始位置
  invoke getCodeSegStart,_lpFile2
  mov dwDstCodeSegStart,eax

  invoke wsprintf,addr szBuffer,addr szOut34,eax
  invoke _appendInfo,addr szBuffer

  ;获取目标代码所在节的大小
  invoke getCodeSegRawSize,_lpFile2
  mov dwDstCodeSegRawSize,eax

  invoke wsprintf,addr szBuffer,addr szOut35,eax
  invoke _appendInfo,addr szBuffer


  ;获取目标代码所在节在内存中的起始位置
  invoke _OffsetToRVA,_lpFile1,dwDstCodeSegStart
  mov dwDstCodeSegMemStart,eax

  invoke wsprintf,addr szBuffer,addr szOut38,eax
  invoke _appendInfo,addr szBuffer



  ;从目标代码所在节的最后一个位置起往前查找连续的全0字符
  mov eax,dwDstCodeSegStart
  add eax,dwDstCodeSegRawSize  ;定位到本节的最后一个字节
  mov ecx,dwPatchCodeSegSize   ;补丁代码的长度
  mov esi,_lpFile2
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
    mov esi,_lpFile2
    add esi,eax
    dec esi
    .repeat
      mov bl,byte ptr [esi]
      .break .if bl!=0
      inc @dwTemp
      dec esi
      dec eax
    .until FALSE
    mov eax,@dwTemp1
    mov lpNewEntryPoint,eax
    invoke wsprintf,addr szBuffer,addr szOut36,@dwTemp,dwPatchCodeSegSize,@dwTemp1
    invoke _appendInfo,addr szBuffer

    ;将代码段的代码复制到目标文件中。   （2）

    mov edi,lpDstMemory
    add edi,@dwTemp1

    mov esi,_lpFile1
    add esi,dwPatchCodeSegStart
    mov ecx,dwPatchCodeSegSize
    rep movsb
  .else       ;代码段空间不够
    invoke _appendInfo,addr szErr31
    jmp @ret
  .endif

  invoke _appendInfo,addr szoutLine

  ;获取补丁程序装载基地址
  invoke getImageBase,_lpFile1
  mov dwPatchImageBase,eax
  invoke wsprintf,addr szBuffer,addr szOut39,eax
  invoke _appendInfo,addr szBuffer

  invoke _appendInfo,addr szCrLf

                                      ;修正除FF 25指令外其他指令的操作数  （3）

  mov edi,lpDstMemory   ;修正68指令
  add edi,@dwTemp1
  mov ecx,dwPatchCodeSegSize
  invoke get_68h,_lpFile1    ;修正代码后的操作数地址  
  mov dwModiCommandCount,eax

  mov edi,lpDstMemory   ;修正A3指令
  add edi,@dwTemp1
  mov ecx,dwPatchCodeSegSize
  invoke get_A3h,_lpFile1    ;修正代码后的操作数地址  
  add dwModiCommandCount,eax

  mov edi,lpDstMemory   ;修正B8指令
  add edi,@dwTemp1
  mov ecx,dwPatchCodeSegSize
  invoke get_B8h,_lpFile1    ;修正代码后的操作数地址  
  add dwModiCommandCount,eax

  mov edi,lpDstMemory   ;修正FF 05指令
  add edi,@dwTemp1
  mov ecx,dwPatchCodeSegSize
  invoke get_FF05h,_lpFile1
  add dwModiCommandCount,eax

  mov edi,lpDstMemory   ;修正03 05指令
  add edi,@dwTemp1
  mov ecx,dwPatchCodeSegSize
  invoke get_0305h,_lpFile1
  add dwModiCommandCount,eax

  mov edi,lpDstMemory   ;修正FF 35指令
  add edi,@dwTemp1
  mov ecx,dwPatchCodeSegSize
  invoke get_FF35h,_lpFile1
  add dwModiCommandCount,eax



  mov edi,lpDstMemory   ;修正FF 25指令  操作数比较特殊
  add edi,@dwTemp1
  mov ecx,dwPatchCodeSegSize
  invoke get_FF25h,_lpFile1,_lpFile2
  add dwModiCommandCount,eax

  mov edi,lpDstMemory   ;修正E9指令
  add edi,@dwTemp1
  mov ecx,dwPatchCodeSegSize
  invoke get_E9h,_lpFile1,_lpFile2    ;修正代码后的操作数地址  
  add dwModiCommandCount,eax
  
  invoke wsprintf,addr szBuffer,addr szOut3310,dwModiCommandCount
  invoke _appendInfo,addr szBuffer  

  ;修正PE文件入口地址
   mov edi,lpDstMemory
   assume edi:ptr IMAGE_DOS_HEADER

   add edi,[edi].e_lfanew    ;调整ESI指针指向PE文件头
   assume edi:ptr IMAGE_NT_HEADERS
   add edi,4
   add edi,sizeof IMAGE_FILE_HEADER
   assume edi:ptr IMAGE_OPTIONAL_HEADER32
   mov ebx,lpNewEntryPoint
   invoke _OffsetToRVA,_lpFile2,ebx
   mov [edi].AddressOfEntryPoint,eax  

@ret:
  popad
  ret
_dealCode   endp

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

;--------------------
; 打开PE文件并处理
;--------------------
_OpenFile proc
  local @stOF:OPENFILENAME
  local @hFile,@dwFileSize,@hMapFile,@lpMemory
  local @hFile1,@dwFileSize1,@hMapFile1,@lpMemory1
  local @bufTemp1[10]:byte
  local @dwTemp:dword,@dwTemp1:dword
  local @dwBuffer,@lpDst,@hDstFile

  invoke wsprintf,addr szBuffer,addr szOut001,addr szFile1
  invoke _appendInfo,addr szBuffer  
  invoke _appendInfo,addr szCrLf  

  invoke wsprintf,addr szBuffer,addr szOut002,addr szFile2
  invoke _appendInfo,addr szBuffer  
  invoke _appendInfo,addr szCrLf  
  invoke _appendInfo,addr szCrLf  
  
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


  ;获取目标文件大小

  ;为目标文件分配内存
  invoke GlobalAlloc,GHND,@dwFileSize1
  mov @hDstFile,eax
  invoke GlobalLock,@hDstFile
  mov lpDstMemory,eax   ;将指针给@lpDst
  ;将目标文件拷贝到内存区域
  invoke MemCopy,@lpMemory1,lpDstMemory,@dwFileSize1

  invoke _dealData,@lpMemory,@lpMemory1
  invoke _dealImport,@lpMemory,@lpMemory1
  invoke _dealCode,@lpMemory,@lpMemory1

  invoke writeToFile,lpDstMemory,@dwFileSize1

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



