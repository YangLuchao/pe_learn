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
szFileName  db MAX_PATH dup(?)

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
szMsg       db '文件名：%s',0dh,0ah
            db '-----------------------------------------',0dh,0ah,0dh,0ah,0dh,0ah
            db '运行平台：      0x%04x  (014c:Intel 386   014dh:Intel 486  014eh:Intel 586)',0dh,0ah
            db '节的数量：      %d',0dh,0ah
            db '文件属性：      0x%04x  (大尾-禁止多处理器-DLL-系统文件-禁止网络运行-禁止优盘运行-无调试-32位-小尾-X-X-X-无符号-无行-可执行-无重定位)',0dh,0ah
            db '建议装入基地址：  0x%08x',0dh,0ah
            db '文件执行入口(RVA地址)：  0x%04x',0dh,0ah,0dh,0ah,0
szMsgSec    db '---------------------------------------------------------------------------------',0dh,0ah
            db '节的属性参考：',0dh,0ah
            db '  00000020h  包含代码',0dh,0ah
            db '  00000040h  包含已经初始化的数据，如.const',0dh,0ah
            db '  00000080h  包含未初始化数据，如 .data?',0dh,0ah
            db '  02000000h  数据在进程开始以后被丢弃，如.reloc',0dh,0ah
            db '  04000000h  节中数据不经过缓存',0dh,0ah
            db '  08000000h  节中数据不会被交换到磁盘',0dh,0ah
            db '  10000000h  数据将被不同进程共享',0dh,0ah
            db '  20000000h  可执行',0dh,0ah
            db '  40000000h  可读',0dh,0ah
            db '  80000000h  可写',0dh,0ah
            db '常见的代码节一般为：60000020h,数据节一般为：c0000040h，常量节一般为：40000040h',0dh,0ah
            db '---------------------------------------------------------------------------------',0dh,0ah,0dh,0ah,0dh,0ah
            db '节的名称  未对齐前真实长度  内存中的偏移(对齐后的) 文件中对齐后的长度 文件中的偏移  节的属性',0dh,0ah
            db '---------------------------------------------------------------------------------------------',0dh,0ah,0
szFmtSec    db '%s     %08x         %08x              %08x           %08x     %08x',0dh,0ah,0dh,0ah,0dh,0ah,0
szMsg1      db 0dh,0ah,0dh,0ah,0dh,0ah
            db '---------------------------------------------------------------------------------------------',0dh,0ah
            db '导入表所处的节：%s',0dh,0ah
            db '---------------------------------------------------------------------------------------------',0dh,0ah,0
szMsgImport db 0dh,0ah,0dh,0ah
            db '导入库：%s',0dh,0ah
            db '-----------------------------',0dh,0ah,0dh,0ah
            db 'OriginalFirstThunk  %08x',0dh,0ah
            db 'TimeDateStamp       %08x',0dh,0ah
            db 'ForwarderChain      %08x',0dh,0ah
            db 'FirstThunk          %08x',0dh,0ah
            db '-----------------------------',0dh,0ah,0dh,0ah,0
szMsg2      db '%08u         %s',0dh,0ah,0
szMsg3      db '%08u(无函数名，按序号导入)',0dh,0ah,0
szErrNoImport db  0dh,0ah,0dh,0ah
              db  '未发现该文件有导入函数',0dh,0ah,0dh,0ah,0

szMsgExport db 0dh,0ah,0dh,0ah,0dh,0ah
            db '---------------------------------------------------------------------------------------------',0dh,0ah
            db '导出表所处的节：%s',0dh,0ah
            db '---------------------------------------------------------------------------------------------',0dh,0ah
            db '原始文件名：%s',0dh,0ah
            db 'nBase               %08x',0dh,0ah
            db 'NumberOfFunctions   %08x',0dh,0ah
            db 'NuberOfNames        %08x',0dh,0ah
            db 'AddressOfFunctions  %08x',0dh,0ah
            db 'AddressOfNames      %08x',0dh,0ah
            db 'AddressOfNameOrd    %08x',0dh,0ah
            db '-------------------------------------',0dh,0ah,0dh,0ah
            db '导出序号    虚拟地址    导出函数名称',0dh,0ah
            db '-------------------------------------',0dh,0ah,0
szMsg4      db '%08x      %08x      %s',0dh,0ah,0
szExportByOrd db  '(按照序号导出)',0
szErrNoExport db 0dh,0ah,0dh,0ah
              db  '未发现该文件有导出函数',0dh,0ah,0dh,0ah,0
szMsgReloc1 db 0dh,0ah,'重定位表所处的节：%s',0dh,0ah,0
szMsgReloc2 db 0dh,0ah
            db '--------------------------------------------------------------------------------------------',0dh,0ah
            db '重定位基地址： %08x',0dh,0ah
            db '重定位项数量： %d',0dh,0ah
            db '--------------------------------------------------------------------------------------------',0dh,0ah
            db '需要重定位的地址列表(ffffffff表示对齐用,不需要重定位)',0dh,0ah
            db '--------------------------------------------------------------------------------------------',0dh,0ah,0
szMsgReloc3 db '%08x  ',0
szCrLf      db 0dh,0ah,0
szMsgReloc4 db 0dh,0ah,'未发现该文件有重定位信息.',0dh,0ah,0

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

;---------------------------------
; 将内存偏移量RVA转换为文件偏移
; lp_FileHead为文件头的起始地址
; _dwRVA为给定的RVA地址
;---------------------------------
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
    ;计算该节结束RVA，不用Misc的主要原因是有些段的Misc值是错误的！
    add eax,[edx].SizeOfRawData 
    .if (edi>=[edx].VirtualAddress)&&(edi<eax)
      mov eax,[edx].VirtualAddress
      ;计算RVA在节中的偏移
      sub edi,eax                
      mov eax,[edx].PointerToRawData
      ;加上节在文件中的的起始位置
      add eax,edi                
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

;-------------------------------------------
; 将距离文件头的文件偏移转换为内存偏移量RVA
; lp_FileHead为文件头的起始地址
; _dwOffset为给定的文件偏移地址
;-------------------------------------------
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
    ;计算该节结束RVA，不用Misc的主要原因是有些段的Misc值是错误的！
    add eax,[edx].SizeOfRawData 
    .if (edi>=[edx].PointerToRawData)&&(edi<eax)
      mov eax,[edx].PointerToRawData
      ;计算RVA在节中的偏移
      sub edi,eax                
      mov eax,[edx].VirtualAddress
      ;加上节在文件中的的起始位置
      add eax,edi                
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
   add esi,[esi+3ch]
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

;--------------------
; 从内存中获取PE文件的主要信息
; 梳理DOS信息 
; _lpFile：镜像偏移
; _lpPeHead：NT头偏移
; _dwSize：镜像大小
;--------------------
_getMainInfo  proc _lpFile,_lpPeHead,_dwSize
  local @szBuffer[1024]:byte;字符串缓冲区
  local @szSecName[16]:byte;节名称

  pushad
  mov edi,_lpPeHead;文件偏移挪到edi中
  assume edi:ptr IMAGE_NT_HEADERS;假设edi是指向NT头结构的指针
  movzx ecx,[edi].FileHeader.Machine          ;运行平台
  movzx edx,[edi].FileHeader.NumberOfSections ;节的数量
  movzx ebx,[edi].FileHeader.Characteristics  ;节的属性
  invoke wsprintf,addr @szBuffer,addr szMsg,\
         addr szFileName,ecx,edx,ebx,\
         [edi].OptionalHeader.ImageBase,\     ;建议装入的地址
         [edi].OptionalHeader.AddressOfEntryPoint;程序执行入口
  invoke SetWindowText,hWinEdit,addr @szBuffer;添加到编辑框中

  ;显示每个节的主要信息
  invoke _appendInfo,addr szMsgSec 
  movzx ecx,[edi].FileHeader.NumberOfSections;节的数量
  add edi,sizeof IMAGE_NT_HEADERS;调整ESI指向节表项
  assume edi:ptr IMAGE_SECTION_HEADER;假设ESI为指向节表项的指针
  .repeat
    push ecx;保持寄存器ecx
    ;获取节的名称，注意长度为8的名称并不以0结尾
    invoke RtlZeroMemory,addr @szSecName,sizeof @szSecName
    push esi;保护esi
    push edi;保护edi
    mov ecx,8;循环8次计数
    mov esi,edi;edi挪到esi
    lea edi,@szSecName;将节表名的地址挪到edi
    cld;设置方向标识符为正向
    @@:
    lodsb;将esi指向的字节装载到al，并且esi+1
    .if !al  ;如果名称为0，则显示为空格
      mov al,' '
    .endif
    stosb;将al中的字节存储到edi指向的地址，并且edi+1
    loop @B;ecx-1，如果ecx!=0，跳到上一个@@继续执行
    pop edi;弹出edi
    pop esi;弹出esi
    ;获取节的主要信息
    invoke wsprintf,addr @szBuffer,addr szFmtSec,\;模板地址
           addr @szSecName,\;节名
           [edi].Misc.VirtualSize,\;节大小
           [edi].VirtualAddress,\;节的偏移地址
           [edi].SizeOfRawData,\;节在文件中对齐后的大小
           [edi].PointerToRawData,\;节在文件中的骗你有
           [edi].Characteristics;节属性
    invoke _appendInfo,addr @szBuffer
    add edi,sizeof IMAGE_SECTION_HEADER;调整edi，指向下一个节表项
    pop ecx;弹出寄存器ecx
  .untilcxz

  assume edi:nothing;还原edi
  popad;弹出所有寄存器
  ret;当前过程执行完成
_getMainInfo endp

;--------------------
; 获取PE文件的导入表
; _lpFile:镜像偏移
; _lpPeHead：NT头偏移
; _dwSize：镜像大小
;--------------------
_getImportInfo proc _lpFile,_lpPeHead,_dwSize
  local @szBuffer[1024]:byte;文本缓冲区
  local @szSectionName[16]:byte;节名称
  
  pushad;保护所有寄存器
  mov edi,_lpPeHead;将镜像偏移地址挪到edi中
  assume edi:ptr IMAGE_NT_HEADERS;假设edi是指向NT头结构的指针
  ;全局指针表RVA
  mov eax,[edi].OptionalHeader.DataDirectory[8].VirtualAddress
  .if !eax
    invoke _appendInfo,addr szErrNoImport
    jmp _Ret
  .endif
  invoke _RVAToOffset,_lpFile,eax;计算导入表在文件中的偏移
  add eax,_lpFile ;调整eax指向导入表文职
  mov edi,eax     ;计算引入表所在文件偏移位置
  assume edi:ptr IMAGE_IMPORT_DESCRIPTOR;假设edi为指向导入表项的指针
  invoke _getRVASectionName,_lpFile,[edi].OriginalFirstThunk;找到桥1所存储的位置在文件中的偏移的节名
  invoke wsprintf,addr @szBuffer,addr szMsg1,eax  ;显示节名
  invoke _appendInfo,addr @szBuffer

  .while [edi].OriginalFirstThunk || [edi].TimeDateStamp ||\
                 [edi].ForwarderChain || [edi].Name1 ||\
                 [edi].FirstThunk
    invoke _RVAToOffset,_lpFile,[edi].Name1;找到dll名的偏移
    add eax,_lpFile;加上文件的偏移，就是dll文字在内存中整体的偏移
    invoke wsprintf,addr @szBuffer,addr szMsgImport,eax,\
           [edi].OriginalFirstThunk,[edi].TimeDateStamp,\
           [edi].ForwarderChain,[edi].FirstThunk
    invoke _appendInfo,addr @szBuffer

    ;获取IMAGE_THUNK_DATA列表到EBX
    .if [edi].OriginalFirstThunk
      mov eax,[edi].OriginalFirstThunk
    .else
      mov eax,[edi].FirstThunk
    .endif
    invoke _RVAToOffset,_lpFile,eax;获取IMAGE_THUNK_DATA的偏移
    add eax,_lpFile;调整偏移转换为全局偏移
    mov ebx,eax
    .while dword ptr [ebx];如果不为 00 00 00 00 则继续循环
      ;按序号导入
      .if dword ptr [ebx] & IMAGE_ORDINAL_FLAG32;IMAGE_ORDINAL_FLAG32 = 0x80000000 & dword ptr [ebx]的值就是判断首位是否为1
                                                ;为1 ebx中存储的值就是代表的是函数编号
        mov eax,dword ptr [ebx]
        and eax,0ffffh
        invoke wsprintf,addr @szBuffer,addr szMsg3,eax
      .else  ;最高位为0，则按名称导入                                      
        invoke _RVAToOffset,_lpFile,dword ptr [ebx];IMAGE_THUNK_DATA存储的是函数的编号和名称的地址
                                                    ;获取该地址在文件中的偏移
        add eax,_lpFile;调整为全局偏移
        assume eax:ptr IMAGE_IMPORT_BY_NAME;假设eax为指向导入函数名称结构体的指针
        movzx ecx,[eax].Hint;导入函数的编号
        invoke wsprintf,addr @szBuffer,\
              addr szMsg2,ecx,addr [eax].Name1;导入函数的名称
        assume eax:nothing
      .endif
      invoke _appendInfo,addr @szBuffer
      add ebx,4;ebx+4，解析下一个IMAGE_THUNK_DATA
    .endw
    ;调整edi,指向下一个导入项
    add edi,sizeof IMAGE_IMPORT_DESCRIPTOR
  .endw
_Ret:
  assume edi:nothing
  popad
  ret
_getImportInfo endp

;--------------------
; 获取PE文件的导出表
;--------------------
_getExportInfo proc _lpFile,_lpPeHead,_dwSize
  local @szBuffer[1024]:byte;字符串缓冲区
  local @szSectionName[16]:byte;节名称
  local @lpAddressOfNames,@dwIndex,@lpAddressOfNameOrdinals
  
  pushad;保护所有的寄存器
  mov esi,_lpPeHead;镜像起始偏移挪到esi中
  assume esi:ptr IMAGE_NT_HEADERS;假设ESI是指向NT头的指针
  mov eax,[esi].OptionalHeader.DataDirectory[0].VirtualAddress;找到导出表的偏移地址
  .if !eax;判断导出地址是否合法
    invoke _appendInfo,addr szErrNoExport
    jmp _Ret
  .endif
  invoke _RVAToOffset,_lpFile,eax;将RVA地址转换为FOA
  add eax,_lpFile;调整为全局地址
  mov edi,eax     ;计算导出表所在文件偏移位置，将地址挪到EDI中
  assume edi:ptr IMAGE_EXPORT_DIRECTORY;假设EDI是指向导出表结构的指针
  invoke _RVAToOffset,_lpFile,[edi].nName;找出动态链接库的DLL名的FOA
  add eax,_lpFile;转全局地址
  mov ecx,eax;将名保存到ecx中
  invoke _getRVASectionName,_lpFile,[edi].nName;获得导出表所处节的节名称
  invoke wsprintf,addr @szBuffer,addr szMsgExport,\
         eax,\;节名称
         ecx,\;导出动态链接库名称
         [edi].nBase,\;导出函数起始编号
         [edi].NumberOfFunctions,\;导出函数个数
         [edi].NumberOfNames,\;有名字的导出函数个数
         [edi].AddressOfFunctions,\;导出函数入口列表
         [edi].AddressOfNames,\;导出函数函数名列表入口
         [edi].AddressOfNameOrdinals;导出函数编号列表入口
  invoke _appendInfo,addr @szBuffer

  invoke _RVAToOffset,_lpFile,[edi].AddressOfNames;找到函数名字数组FOA
  add eax,_lpFile;调整到全局偏移
  mov @lpAddressOfNames,eax;挪到局部变量
  invoke _RVAToOffset,_lpFile,[edi].AddressOfNameOrdinals;找到好处函数编号数组FOA
  add eax,_lpFile;调整到全局偏移
  mov @lpAddressOfNameOrdinals,eax;挪到局部变量中
  invoke _RVAToOffset,_lpFile,[edi].AddressOfFunctions;找到函数地址表数组FOA
  add eax,_lpFile;调整到全局偏移
  mov esi,eax   ;函数的地址表入口地址挪到esi中

  mov ecx,[edi].NumberOfFunctions;导出函数的个数
  mov @dwIndex,0;循环计数
@@:
  pushad;暂存所有寄存器
  mov eax,@dwIndex;计数器挪到eax中
  push edi;暂存edi的值
  mov ecx,[edi].NumberOfNames;导出函数个数
  cld;设置方向标识为0，正向
  mov edi,@lpAddressOfNameOrdinals;将导出函数编号地址挪到edi中
  repnz scasw
  .if ZERO?  ;找到函数名称
    ;-----------------------------------这一坨有点绕，就是根据编号找名字
    sub edi,@lpAddressOfNameOrdinals
    sub edi,2
    shl edi,1
    add edi,@lpAddressOfNames
    invoke _RVAToOffset,_lpFile,dword ptr [edi]
    add eax,_lpFile
    ;-----------------------------------这一坨有点绕，就是根据编号找名字
  .else
    mov eax,offset szExportByOrd
  .endif
  pop edi
  ;序号在ecx中
  mov ecx,@dwIndex
  add ecx,[edi].nBase
  invoke wsprintf,addr @szBuffer,addr szMsg4,\
         ecx,dword ptr [esi],eax
  invoke _appendInfo,addr @szBuffer
  popad
  add esi,4
  inc @dwIndex
  loop @B;跳到上一个@@继续指向
_Ret:
  assume esi:nothing
  assume edi:nothing
  popad
  ret
_getExportInfo endp

;--------------------
; 获取PE文件的重定位信息
;--------------------
_getRelocInfo proc  _lpFile,_lpPeHead,_dwSize
  local @szBuffer[1024]:byte
  local @szSectionName[16]:byte

  pushad
  mov esi,_lpPeHead
  assume esi:ptr IMAGE_NT_HEADERS
  mov eax,[esi].OptionalHeader.DataDirectory[8*5].VirtualAddress
  .if !eax
    invoke _appendInfo,addr szMsgReloc4
    jmp _ret
  .endif
  push eax
  invoke _RVAToOffset,_lpFile,eax
  add eax,_lpFile
  mov esi,eax
  pop eax
  invoke _getRVASectionName,_lpFile,eax
  invoke wsprintf,addr @szBuffer,addr szMsgReloc1,eax
  invoke _appendInfo,addr @szBuffer
  assume esi:ptr IMAGE_BASE_RELOCATION
  ;循环处理每个重定位块
  .while [esi].VirtualAddress
    cld
    lodsd   ;eax=[esi].VirtualAddress
    mov ebx,eax
    lodsd   ;eax=[esi].SizeofBlock
    sub eax,sizeof IMAGE_BASE_RELOCATION  ;块总长度-两个dd
    shr eax,1                             ;然后除以2，得到重定位项数量
                                          ;除以2是因为重定位项是word
    push eax
    invoke wsprintf,addr @szBuffer,addr szMsgReloc2,ebx,eax
    invoke _appendInfo,addr @szBuffer
    pop ecx                               ;重定位项数量
    xor edi,edi
    .repeat
      push ecx
      lodsw
      mov cx,ax
      and cx,0f000h    ;得到高四位
      .if cx==03000h   ;重定位地址指向的双字的32位都需要休正
        and ax,0fffh
        movzx eax,ax
        add eax,ebx    ;得到修正以前的偏移，
                       ;该偏移加上装入时的基址就是绝对地址
      .else            ;该重定位项无意义，仅用来作为对齐
        mov eax,-1
      .endif
      invoke wsprintf,addr @szBuffer,addr szMsgReloc3,eax
      inc edi
      .if edi==8       ;每显示8个项目换行
        invoke lstrcat,addr @szBuffer,addr szCrLf
        xor edi,edi
      .endif
      invoke _appendInfo,addr @szBuffer
      pop ecx
    .untilcxz
    .if edi
      invoke _appendInfo,addr szCrLf
    .endif
  .endw
_ret:
  assume esi:nothing
  popad
  ret
_getRelocInfo endp
;--------------------
; 打开PE文件并处理
;--------------------
_openFile proc
  local @stOF:OPENFILENAME;需要打开的文件结构体
  local @hFile,@dwFileSize,@hMapFile,@lpMemory;文件句柄，文件大小，内存镜像句柄，内存镜像起始地址

  invoke RtlZeroMemory,addr @stOF,sizeof @stOF;清空内存
  mov @stOF.lStructSize,sizeof @stOF;设置结构体大小
  push hWinMain
  pop @stOF.hwndOwner;将当前空间句柄放入到文件结构体中
  mov @stOF.lpstrFilter,offset szExtPe;选取文件的文件格式过滤器
  mov @stOF.lpstrFile,offset szFileName;文件名全路径缓冲区
  mov @stOF.nMaxFile,MAX_PATH
  mov @stOF.Flags,OFN_PATHMUSTEXIST or OFN_FILEMUSTEXIST
  invoke GetOpenFileName,addr @stOF  ;让用户选择打开的文件
  .if !eax;判断加载的文件是否合法
    jmp @F
  .endif
  ;打开文件
  invoke CreateFile,addr szFileName,GENERIC_READ,\
         FILE_SHARE_READ or FILE_SHARE_WRITE,NULL,\
         OPEN_EXISTING,FILE_ATTRIBUTE_ARCHIVE,NULL
  .if eax!=INVALID_HANDLE_VALUE;判断打开的文件是否合法
    mov @hFile,eax
    invoke GetFileSize,eax,NULL;查询文件大小
    mov @dwFileSize,eax;将文件大小挪到局部变量中
    .if eax
      invoke CreateFileMapping,@hFile,\  ;内存映射文件
             NULL,PAGE_READONLY,0,0,NULL
      .if eax
        mov @hMapFile,eax;将内存镜像的句柄放入到局部变量中
        invoke MapViewOfFile,eax,\;创建镜像映射
               FILE_MAP_READ,0,0,0
        .if eax
          ;获得文件在内存的映象起始位置
          mov @lpMemory,eax
          ;-----------------------------异常处理起始
          assume fs:nothing
          push ebp
          push offset _ErrFormat
          push offset _Handler
          push fs:[0]
          mov fs:[0],esp
          ;-----------------------------异常处理起始

          ;检测PE文件是否有效
          mov esi,@lpMemory
          assume esi:ptr IMAGE_DOS_HEADER;假设esi是指向DOS头结构的指针

          ;判断是否有MZ字样
          .if [esi].e_magic!=IMAGE_DOS_SIGNATURE
            jmp _ErrFormat;否则跳入到异常流程
          .endif

          ;调整ESI指针指向PE文件头
          add esi,[esi].e_lfanew
          assume esi:ptr IMAGE_NT_HEADERS;假设esi是指向NT头的指针
          ;判断是否有PE字样
          .if [esi].Signature!=IMAGE_NT_SIGNATURE
            jmp _ErrFormat;否则跳入到异常流程
          .endif

          ;到此为止，该文件的验证已经完成。为PE结构文件
          ;接下来分析分件映射到内存中的数据，并显示主要参数
          invoke _getMainInfo,@lpMemory,esi,@dwFileSize
          ;显示导入表
          invoke _getImportInfo,@lpMemory,esi,@dwFileSize
          ;显示导出表
          invoke _getExportInfo,@lpMemory,esi,@dwFileSize
          ;显示重定位信息
          invoke _getRelocInfo,@lpMemory,esi,@dwFileSize


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
  .elseif eax==WM_COMMAND     ;菜单
    mov eax,wParam
    .if eax==IDM_EXIT       ;退出
      invoke EndDialog,hWnd,NULL 
    .elseif eax==IDM_OPEN   ;打开文件
      call _openFile
    .elseif eax==IDM_1  ;以下三个菜单是7岁的儿子完成的！！
      invoke MessageBox,NULL,offset szErrFormat,offset szErr,MB_ICONWARNING
    .elseif eax==IDM_2
      invoke MessageBox,NULL,offset szErrFormat,offset szErr,MB_ICONQUESTION	
    .elseif eax==IDM_3
      invoke MessageBox,NULL,offset szErrFormat,offset szErr,MB_YESNOCANCEL
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



