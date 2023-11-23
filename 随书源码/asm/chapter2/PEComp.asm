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
dwCount     dd是多少 ?
dwColorRed  dd ?
hText1      dd ?
hText2      dd ?
hFile       dd ?  ;定义的文件句柄，多出重复使用，使用前需初始化


hProcessModuleTable dd ?


szFileName           db MAX_PATH dup(?)
szFileNameOpen1      db MAX_PATH dup(0)
szFileNameOpen2      db MAX_PATH dup(0)


szResultColName1 db  'PE数据结构相关字段',0
szResultColName2 db  '文件1的值(H)',0
szResultColName3 db  '文件2的值(H)',0
szBuffer         db  256 dup(0),0
bufTemp1         db  200 dup(0),0
bufTemp2         db  200 dup(0),0
szFilter1        db  'Excutable Files',0,'*.exe;*.com',0;文件类型过滤
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


szRec1      db 'IMAGE_DOS_HEADER.e_magic',0;dos头标识
szRec2      db 'IMAGE_DOS_HEADER.e_cblp',0
szRec3      db 'IMAGE_DOS_HEADER.e_cp',0
szRec4      db 'IMAGE_DOS_HEADER.e_crlc',0
szRec5      db 'IMAGE_DOS_HEADER.e_cparhdr',0
szRec6      db 'IMAGE_DOS_HEADER.e_minalloc',0
szRec7      db 'IMAGE_DOS_HEADER.e_maxalloc',0
szRec8      db 'IMAGE_DOS_HEADER.e_ss',0
szRec9      db 'IMAGE_DOS_HEADER.e_sp',0
szRec10     db 'IMAGE_DOS_HEADER.e_csum',0
szRec11     db 'IMAGE_DOS_HEADER.e_ip',0
szRec12     db 'IMAGE_DOS_HEADER.e_cs',0
szRec13     db 'IMAGE_DOS_HEADER.e_lfarlc',0
szRec14     db 'IMAGE_DOS_HEADER.e_ovno',0
szRec15     db 'IMAGE_DOS_HEADER.e_res',0
szRec16     db 'IMAGE_DOS_HEADER.e_oemid',0
szRec17     db 'IMAGE_DOS_HEADER.e_oeminfo',0
szRec18     db 'IMAGE_DOS_HEADER.e_res2',0
szRec19     db 'IMAGE_DOS_HEADER.e_lfanew',0;pe头相对偏移

szRec20     db 'IMAGE_NT_HEADERS.Signature',0;pe头标识

szRec21     db 'IMAGE_FILE_HEADER.Machine',0;运行平台
szRec22     db 'IMAGE_FILE_HEADER.NumberOfSections',0;pe中节的数量
szRec23     db 'IMAGE_FILE_HEADER.TimeDateStamp',0;文件创建日期和时间
szRec24     db 'IMAGE_FILE_HEADER.PointerToSymbolTable',0
szRec25     db 'IMAGE_FILE_HEADER.NumberOfSymbols',0
szRec26     db 'IMAGE_FILE_HEADER.SizeOfOptionalHeader',0;扩展头长度，32为224字节，64为240字节
szRec27     db 'IMAGE_FILE_HEADER.Characteristics',0;文件属性

szRec28     db 'IMAGE_OPTIONAL_HEADER32.Magic',0;魔术字
szRec29     db 'IMAGE_OPTIONAL_HEADER32.MajorLinkerVersion',0;链接其大版本
szRec30     db 'IMAGE_OPTIONAL_HEADER32.MinorLinkerVersion',0;链接器小版本
szRec31     db 'IMAGE_OPTIONAL_HEADER32.SizeOfCode',0;代码节总大小
szRec32     db 'IMAGE_OPTIONAL_HEADER32.SizeOfInitializedData',0;已初始化节的大小
szRec33     db 'IMAGE_OPTIONAL_HEADER32.SizeOfUninitializedData',0;未初始化节的大小
szRec34     db 'IMAGE_OPTIONAL_HEADER32.AddressOfEntryPoint',0;执行入口rva
szRec35     db 'IMAGE_OPTIONAL_HEADER32.BaseOfCode',0;代码节起始rva
szRec36     db 'IMAGE_OPTIONAL_HEADER32.BaseOfData',;数据节起始rva
szRec37     db 'IMAGE_OPTIONAL_HEADER32.ImageBase',0;程序建议装载地址，exe:0040 0000 dll:0010 0000
szRec38     db 'IMAGE_OPTIONAL_HEADER32.SectionAlignment',0;内存中对齐的粒度
szRec39     db 'IMAGE_OPTIONAL_HEADER32.FileAlignment',0;文件中对齐的粒度
szRec40     db 'IMAGE_OPTIONAL_HEADER32.MajorOperatingSystemVersion',0;操作系统大版本号
szRec41     db 'IMAGE_OPTIONAL_HEADER32.MinorOperatingSystemVersion',0;操作系统小版本号
szRec42     db 'IMAGE_OPTIONAL_HEADER32.MajorImageVersion',0;PE镜像的大版本号
szRec43     db 'IMAGE_OPTIONAL_HEADER32.MinorImageVersion',0;PE镜像的小版本号
szRec44     db 'IMAGE_OPTIONAL_HEADER32.MajorSubsystemVersion',0;所需子系统的大版本号
szRec45     db 'IMAGE_OPTIONAL_HEADER32.MinorSubsystemVersion',0;所需子系统的小版本号
szRec46     db 'IMAGE_OPTIONAL_HEADER32.Win32VersionValue',0
szRec47     db 'IMAGE_OPTIONAL_HEADER32.SizeOfImage',0;内存中整个PE镜像的大小
szRec48     db 'IMAGE_OPTIONAL_HEADER32.SizeOfHeaders',0;所有头+节表的大小
szRec49     db 'IMAGE_OPTIONAL_HEADER32.CheckSum',0;校验和
szRec50     db 'IMAGE_OPTIONAL_HEADER32.Subsystem',0;文件子系统
szRec51     db 'IMAGE_OPTIONAL_HEADER32.DllCharacteristics',0;dll文件的特性
szRec52     db 'IMAGE_OPTIONAL_HEADER32.SizeOfStackReserve',0;初始化时栈的大小
szRec53     db 'IMAGE_OPTIONAL_HEADER32.SizeOfStackCommit',0;初始化时栈实际提交的大小
szRec54     db 'IMAGE_OPTIONAL_HEADER32.SizeOfHeapReserve',0;初始化时堆的大小
szRec55     db 'IMAGE_OPTIONAL_HEADER32.SizeOfHeapCommit',0;初始化时堆实际提交的大小
szRec56     db 'IMAGE_OPTIONAL_HEADER32.LoaderFlags',0
szRec57     db 'IMAGE_OPTIONAL_HEADER32.NumberOfRvaAndSizes',0;数据目录项个数，一般时16个

szRec58     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(Export)',0;导出表RVA
szRec59     db 'IMAGE_DATA_DIRECTORY.isize(Export)',0;导出表大小
szRec60     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(Import)',0;导入表rva
szRec61     db 'IMAGE_DATA_DIRECTORY.isize(Import)',0;导入表大小
szRec62     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(Resource)',0;资源表RVA
szRec63     db 'IMAGE_DATA_DIRECTORY.isize(Resource)',0;资源表大小
szRec64     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(Exception)',0;异常表RVA
szRec65     db 'IMAGE_DATA_DIRECTORY.isize(Exception)',0;异常表大小
szRec66     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(Security)',0;安全表RVA
szRec67     db 'IMAGE_DATA_DIRECTORY.isize(Security)',0;安全表大小
szRec68     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(BaseReloc)',0;重定位表RVA
szRec69     db 'IMAGE_DATA_DIRECTORY.isize(BaseReloc)',0;重定位表大小
szRec70     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(Debug)',0;调试表RVA
szRec71     db 'IMAGE_DATA_DIRECTORY.isize(Debug)',0;调试表大小
szRec72     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(Architecture)',0;版权表RVA
szRec73     db 'IMAGE_DATA_DIRECTORY.isize(Architecture)',0;版权表大小
szRec74     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(GlobalPTR)',0;全局指针表RVA
szRec75     db 'IMAGE_DATA_DIRECTORY.isize(GlobalPTR)',0;全局指针表大小
szRec76     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(TLS)',0;线程本地存储表RVA
szRec77     db 'IMAGE_DATA_DIRECTORY.isize(TLS)',0;线程本地存储表大小
szRec78     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(Load_Config)',0;加载配置表RVA
szRec79     db 'IMAGE_DATA_DIRECTORY.isize(Load_Config)',0;加载配置表大小
szRec80     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(Bound_Import)',0;绑定导入表RVA
szRec81     db 'IMAGE_DATA_DIRECTORY.isize(Bound_Import)',0;绑定导入表大小
szRec82     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(IAT)',0;IAT（导入地址表）RVA
szRec83     db 'IMAGE_DATA_DIRECTORY.isize(IAT)',0;IAT（导入地址表）大小
szRec84     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(Delay_Import)',0;延迟导入表RVA
szRec85     db 'IMAGE_DATA_DIRECTORY.isize(Delay_Import)',0;延迟导入表大小
szRec86     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(Com_Descriptor)',0;CLR表RVA
szRec87     db 'IMAGE_DATA_DIRECTORY.isize(Com_Descriptor)',0;CLR表大小
szRec88     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(Reserved)',0;预留表RVA
szRec89     db 'IMAGE_DATA_DIRECTORY.isize(Reserved)',0;预留表大小

szRec90     db 'IMAGE_SECTION_HEADER%d.Name1',0;节名
szRec91     db 'IMAGE_SECTION_HEADER%d.VirtualSize',0;节大小
szRec92     db 'IMAGE_SECTION_HEADER%d.VirtualAddress',0;节RVA
szRec93     db 'IMAGE_SECTION_HEADER%d.SizeOfRawData',0;节在文件中对齐后的大小
szRec94     db 'IMAGE_SECTION_HEADER%d.PointerToRawData',0;节在文件中的偏移
szRec95     db 'IMAGE_SECTION_HEADER%d.PointerToRelocations',0;
szRec96     db 'IMAGE_SECTION_HEADER%d.PointerToLinenumbers',0;
szRec97     db 'IMAGE_SECTION_HEADER%d.NumberOfRelocations',0;
szRec98     db 'IMAGE_SECTION_HEADER%d.NumberOfLinenumbers',0;
szRec99     db 'IMAGE_SECTION_HEADER%d.Characteristics',0;节属性


szOut1      db '%02x',0
szOut2      db '%04x',0
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
; 在ASM的实现中，该函数没有的到使用，因为对字节的操作能很好的拿到数据，不需要进行转换
; _lpFileHead:文件起始偏移
; _dwRVA:想要转为FOA的RVA
;---------------------
_RVAToOffset proc _lpFileHead,_dwRVA
  local @dwReturn
  
  pushad
  mov esi,_lpFileHead;文件起始偏移挪到esi
  assume esi:ptr IMAGE_DOS_HEADER;假设esi是指向DOS头结构的指针
  add esi,[esi].e_lfanew;NT头偏移挪到esi 中
  assume esi:ptr IMAGE_NT_HEADERS;假设esi是指向NT头结构的指针
  mov edi,_dwRVA;目标RVA挪到edi中
  mov edx,esi;esi挪到edx中
  add edx,sizeof IMAGE_NT_HEADERS;调edx，将edx指向节表项偏移
  assume edx:ptr IMAGE_SECTION_HEADER;假设edx是节表项的结构的指针
  movzx ecx,[esi].FileHeader.NumberOfSections;将节的数目挪到ecx中
  ;遍历节表
  .repeat
    mov eax,[edx].VirtualAddress  ;将当前节的RVA挪到EAX中
    add eax,[edx].SizeOfRawData  ;计算该节结束RVA
    .if (edi>=[edx].VirtualAddress)&&(edi<eax);目标地址需要大于当前节的起始地址，需要小于当前节的结束地址
      mov eax,[edx].VirtualAddress;符合条件，再次将当前节的起始地址挪到EAX中
      sub edi,eax                ;目标RVA-节的起始RVA，计算目标RVA对于节起始地址的偏移
      mov eax,[edx].PointerToRawData;将当前节的起始地址的文件偏移挪到eax中
      add eax,edi                ;加上节在文件中的的起始位置加上相对偏移
      jmp @F ;跳到下一个@@处执行
    .endif
    add edx,sizeof IMAGE_SECTION_HEADER;当前节不符合条件，调整edx执行下一个节表项偏移
  .untilcxz;知道ecx等于0，跳出循环
  assume edx:nothing;还原edx
  assume esi:nothing;还原esi
  mov eax,-1    ;没有找到设置结果标识为-1
@@:
  mov @dwReturn,eax;将结果存入局部变量中
  popad     ;弹出保护的寄存器
  mov eax,@dwReturn ;将计算结果放入到EAX中
  ret   ;结束过程调用
_RVAToOffset endp

;------------------------
; 获取RVA所在节的名称
; _lpFileHead:镜像头偏移地址
; _dwRVA:要计算的RVA
;------------------------
_getRVASectionName  proc _lpFileHead,_dwRVA
  local @dwReturn
  
  pushad;保护全部寄存器
  mov esi,_lpFileHead;镜像偏移头放到esi中
  assume esi:ptr IMAGE_DOS_HEADER;假设esi是指向DOS头的指针
  add esi,[esi].e_lfanew;调整esi，指向NT头
  assume esi:ptr IMAGE_NT_HEADERS;假设esi是指向NT头的指针
  mov edi,_dwRVA;要计算的RVA地址放入到edi中
  mov edx,esi;将指向NT头的指针放入到edx中
  add edx,sizeof IMAGE_NT_HEADERS;调整edx指向节表项
  assume edx:ptr IMAGE_SECTION_HEADER;假设EDX为指向节表项结构的指针
  movzx ecx,[esi].FileHeader.NumberOfSections;将节表项的数量放入ECX中，进行计数
  ;遍历节表
  .repeat
    mov eax,[edx].VirtualAddress  ;将节表的RVA放入到EAX中
    add eax,[edx].SizeOfRawData  ;计算该节结束RVA
    .if (edi>=[edx].VirtualAddress)&&(edi<eax);目标地址需要符合条件，大于等于当前节表起始地址，小于当前节表的结束地址
      mov eax,edx;符合条件将当前节表项的起始地址放入到eax中
      jmp @F;直接跳到下一个@@处继续指向
    .endif
    add edx,sizeof IMAGE_SECTION_HEADER;如果当前节表项不符合条件，调整edx指针，指向下一个节表项
  .untilcxz;知道ecx=0，跳出循环
  assume edx:nothing;还原edx
  assume esi:nothing;还原esi
  mov eax,offset szNotFound;没有找到就像没有找到的标识放入到eax中
@@:
  mov @dwReturn,eax;找到了就将找到的地址放入到局部变量中暂存
  popad;弹出保护的所有寄存器
  mov eax,@dwReturn;将局部变量的值挪到eax中
  ret;结束当前过程
_getRVASectionName  endp


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
             mov eax,200
             lea ecx,szResultColName1
             invoke _ListViewAddColumn,hProcessModuleTable,ebx,eax,ecx

             mov ebx,2
             mov eax,400
             lea ecx,szResultColName2
             invoke _ListViewAddColumn,hProcessModuleTable,ebx,eax,ecx

             mov ebx,3
             mov eax,400
             lea ecx,szResultColName3
             invoke _ListViewAddColumn,hProcessModuleTable,ebx,eax,ecx

             mov dwCount,0
             ret
_clearResultView  endp

;------------------------------------------
; 打开输入文件
;------------------------------------------
_OpenFile1	proc
		local	@stOF:OPENFILENAME;局部变量，文件打开结构
		local	@stES:EDITSTREAM;？没有用

    ;如果打开之前还有文件句柄存在，则先关闭再赋值  
    ;使用前初始化              
    .if hFile
       invoke CloseHandle,hFile
       mov hFile,0
    .endif
    ; 显示“打开文件”对话框
    ; 清空内存
		invoke	RtlZeroMemory,addr @stOF,sizeof @stOF
    ;设置@stOF中结构体大小属性
		mov	@stOF.lStructSize,sizeof @stOF
		push	hWinMain
		pop	  @stOF.hwndOwner
    push  hInstance;给文件所属控件赋值
    pop   @stOF.hInstance
		mov	@stOF.lpstrFilter,offset szFilter1  ;文件类型过滤
		mov	@stOF.lpstrFile,offset szFileNameOpen1;文件名称缓冲区
		mov	@stOF.nMaxFile,MAX_PATH
		mov	@stOF.Flags,OFN_FILEMUSTEXIST or\
                                    OFN_HIDEREADONLY or OFN_PATHMUSTEXIST
    ; 执行打开文件                                
		invoke	GetOpenFileName,addr @stOF
		.if	eax
      ; 将打开的文件全路径写入控件中
      invoke SetWindowText,hText1,addr szFileNameOpen1
		.endif
		ret

_OpenFile1	endp
;------------------------------------------
; 打开输入文件
; 和openFile1完成一样
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

;--------------------------------------------
; 在表格中增加一行
; _lpSZ为第一行要显示的字段名
; _lpSP1为第一个文件该字段的位置
; _lpSP2为第二个文件该字段的位置
; _Size为该字段的字节长度
;--------------------------------------------
_addLine proc _lpSZ,_lpSP1,_lpSP2,_Size
  pushad

  invoke _ListViewSetItem,hProcessModuleTable,dwCount,-1,\
               _lpSZ             ;在表格中新增加一行
  mov dwCount,eax

  xor ebx,ebx
  invoke _ListViewSetItem,hProcessModuleTable,dwCount,ebx,\
         _lpSZ                   ;显示字段名
  
  invoke RtlZeroMemory,addr szBuffer,50
  invoke MemCopy,_lpSP1,addr bufTemp2,_Size
  invoke _Byte2Hex,_Size

  ;将指定字段按照十六进制显示，格式：一个字节+一个空格
  invoke lstrcat,addr szBuffer,addr bufTemp1
  inc ebx
  invoke _ListViewSetItem,hProcessModuleTable,dwCount,ebx,\
                   addr szBuffer ;第一个文件中的值

  invoke RtlZeroMemory,addr szBuffer,50
  invoke MemCopy,_lpSP2,addr bufTemp2,_Size
  invoke _Byte2Hex,_Size
  invoke lstrcat,addr szBuffer,addr bufTemp1
  inc ebx
  invoke _ListViewSetItem,hProcessModuleTable,dwCount,ebx,\
                   addr szBuffer ;第二个文件中的值

  popad
  ret
_addLine  endp

;-----------------------
; IMAGE_DOS_HEADER头信息
; 解析DOS头
;-----------------------
_Header1 proc 
  pushad

  invoke _addLine,addr szRec1,esi,edi,2 ;DOS头标识MZ
  add esi,2
  add edi,2
  invoke _addLine,addr szRec2,esi,edi,2
  add esi,2
  add edi,2
  invoke _addLine,addr szRec3,esi,edi,2
  add esi,2
  add edi,2
  invoke _addLine,addr szRec4,esi,edi,2
  add esi,2
  add edi,2
  invoke _addLine,addr szRec5,esi,edi,2
  add esi,2
  add edi,2
  invoke _addLine,addr szRec6,esi,edi,2
  add esi,2
  add edi,2
  invoke _addLine,addr szRec7,esi,edi,2
  add esi,2
  add edi,2
  invoke _addLine,addr szRec8,esi,edi,2
  add esi,2
  add edi,2
  invoke _addLine,addr szRec9,esi,edi,2
  add esi,2
  add edi,2
  invoke _addLine,addr szRec10,esi,edi,2
  add esi,2
  add edi,2
  invoke _addLine,addr szRec11,esi,edi,2
  add esi,2
  add edi,2
  invoke _addLine,addr szRec12,esi,edi,2
  add esi,2
  add edi,2
  invoke _addLine,addr szRec13,esi,edi,2
  add esi,2
  add edi,2
  invoke _addLine,addr szRec14,esi,edi,2
  add esi,2
  add edi,2
  invoke _addLine,addr szRec15,esi,edi,8
  add esi,8
  add edi,8
  invoke _addLine,addr szRec16,esi,edi,2
  add esi,2
  add edi,2
  invoke _addLine,addr szRec17,esi,edi,2
  add esi,2
  add edi,2
  invoke _addLine,addr szRec18,esi,edi,20
  add esi,20
  add edi,20
  invoke _addLine,addr szRec19,esi,edi,4;PE头偏移地址
  popad
  ret
_Header1 endp

;-----------------------
; IMAGE_DOS_HEADER头信息
;-----------------------
_Header2 proc 
  pushad

  invoke _addLine,addr szRec20,esi,edi,4;PE头标识
  add esi,4
  add edi,4
  invoke _addLine,addr szRec21,esi,edi,2;运行平台
  add esi,2
  add edi,2
  invoke _addLine,addr szRec22,esi,edi,2;PE中节的数量
  add esi,2
  add edi,2
  invoke _addLine,addr szRec23,esi,edi,4;文件创建日期和时间
  add esi,4
  add edi,4
  invoke _addLine,addr szRec24,esi,edi,4;
  add esi,4
  add edi,4
  invoke _addLine,addr szRec25,esi,edi,4;
  add esi,4
  add edi,4
  invoke _addLine,addr szRec26,esi,edi,2;扩展头大小，32位224位，64位240位
  add esi,2
  add edi,2
  invoke _addLine,addr szRec27,esi,edi,2;文件属性
  add esi,2
  add edi,2
  invoke _addLine,addr szRec28,esi,edi,2;魔术字
  add esi,2
  add edi,2
  invoke _addLine,addr szRec29,esi,edi,1;连接器大版本
  add esi,1
  add edi,1
  invoke _addLine,addr szRec30,esi,edi,1;连接器小版本
  add esi,1
  add edi,1
  invoke _addLine,addr szRec31,esi,edi,4;代码节总大小
  add esi,4
  add edi,4
  invoke _addLine,addr szRec32,esi,edi,4;已初始化节的大小
  add esi,4
  add edi,4
  invoke _addLine,addr szRec33,esi,edi,4;未初始化节的大小
  add esi,4
  add edi,4
  invoke _addLine,addr szRec34,esi,edi,4;执行入口RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec35,esi,edi,4;代码节起始RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec36,esi,edi,4;数据节起始RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec37,esi,edi,4;程序建议装载地址：EXE：0040 0000 DLL：1000 0000
  add esi,4
  add edi,4
  invoke _addLine,addr szRec38,esi,edi,4;内存中对齐的粒度
  add esi,4
  add edi,4
  invoke _addLine,addr szRec39,esi,edi,4;文件中对齐的粒度
  add esi,4
  add edi,4
  invoke _addLine,addr szRec40,esi,edi,2;操作系统大版本号
  add esi,2
  add edi,2
  invoke _addLine,addr szRec41,esi,edi,2;操作系统小版本号
  add esi,2
  add edi,2
  invoke _addLine,addr szRec42,esi,edi,2;PE镜像大版本号
  add esi,2
  add edi,2
  invoke _addLine,addr szRec43,esi,edi,2;PE镜像小版本号
  add esi,2
  add edi,2
  invoke _addLine,addr szRec44,esi,edi,2;所需子系统的大版本
  add esi,2
  add edi,2
  invoke _addLine,addr szRec45,esi,edi,2;所需子系统的小版本
  add esi,2
  add edi,2
  invoke _addLine,addr szRec46,esi,edi,4;//
  add esi,4
  add edi,4
  invoke _addLine,addr szRec47,esi,edi,4;内存中整个PE镜像的大小
  add esi,4
  add edi,4
  invoke _addLine,addr szRec48,esi,edi,4;所有头加节表的大小
  add esi,4
  add edi,4
  invoke _addLine,addr szRec49,esi,edi,4;校验和
  add esi,4
  add edi,4
  invoke _addLine,addr szRec50,esi,edi,2;文件子系统
  add esi,2
  add edi,2
  invoke _addLine,addr szRec51,esi,edi,2;DLL文件特性
  add esi,2
  add edi,2
  invoke _addLine,addr szRec52,esi,edi,4;初始化时栈的大小
  add esi,4
  add edi,4
  invoke _addLine,addr szRec53,esi,edi,4;初始化时栈实际提交的大小
  add esi,4
  add edi,4
  invoke _addLine,addr szRec54,esi,edi,4;初始化时堆的大小
  add esi,4
  add edi,4
  invoke _addLine,addr szRec55,esi,edi,4;初始化时堆实际的大小
  add esi,4
  add edi,4
  invoke _addLine,addr szRec56,esi,edi,4;
  add esi,4
  add edi,4
  invoke _addLine,addr szRec57,esi,edi,4;数据目录项个数，一般16个

  ;IMAGE_DATA_DIRECTORY

  add esi,4
  add edi,4
  invoke _addLine,addr szRec58,esi,edi,4;导出表RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec59,esi,edi,4;导出表大小
  add esi,4
  add edi,4
  invoke _addLine,addr szRec60,esi,edi,4;导入表RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec61,esi,edi,4;导入表大小
  add esi,4
  add edi,4
  invoke _addLine,addr szRec62,esi,edi,4;资源表RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec63,esi,edi,4;资源表大小
  add esi,4
  add edi,4
  invoke _addLine,addr szRec64,esi,edi,4;异常表RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec65,esi,edi,4;异常表大小
  add esi,4
  add edi,4
  invoke _addLine,addr szRec66,esi,edi,4;安全表RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec67,esi,edi,4;安全表大小
  add esi,4
  add edi,4
  invoke _addLine,addr szRec68,esi,edi,4;重定位表RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec69,esi,edi,4;重定位表大小
  add esi,4
  add edi,4
  invoke _addLine,addr szRec70,esi,edi,4;调试表RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec71,esi,edi,4;调试表大小
  add esi,4
  add edi,4
  invoke _addLine,addr szRec72,esi,edi,4;版权表RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec73,esi,edi,4;版权表大小
  add esi,4
  add edi,4
  invoke _addLine,addr szRec74,esi,edi,4;版权表RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec75,esi,edi,4;版权表大小
  add esi,4
  add edi,4
  invoke _addLine,addr szRec76,esi,edi,4;全局指针表RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec77,esi,edi,4;全局指针表大小
  add esi,4
  add edi,4
  invoke _addLine,addr szRec78,esi,edi,4;线程本地存储RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec79,esi,edi,4;线程本地存储大小
  add esi,4
  add edi,4
  invoke _addLine,addr szRec80,esi,edi,4;加载配置表RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec81,esi,edi,4;加载配置表大小
  add esi,4
  add edi,4
  invoke _addLine,addr szRec82,esi,edi,4;绑定导入表RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec83,esi,edi,4;绑定导入表大小
  add esi,4
  add edi,4
  invoke _addLine,addr szRec84,esi,edi,4;IAT（导入地址表）RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec85,esi,edi,4;IAT（导入地址表）大小
  add esi,4
  add edi,4
  invoke _addLine,addr szRec86,esi,edi,4;CLR表RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec87,esi,edi,4;CLR表大小
  add esi,4
  add edi,4
  invoke _addLine,addr szRec88,esi,edi,4;预留表RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec89,esi,edi,4;预留表大小


  popad
  ret
_Header2 endp

;---------------------------------------
; 节表
;  eax=节序号
;---------------------------------------
_Header3 proc 
  local _dwValue:dword
  pushad
  mov _dwValue,eax

  invoke wsprintf,addr szBuffer,addr szRec90,_dwValue   
  invoke _addLine,addr szBuffer,esi,edi,8;
  add esi,8
  add edi,8
  invoke wsprintf,addr szBuffer,addr szRec91,_dwValue  ; 节区名称
  invoke _addLine,addr szBuffer,esi,edi,4
  add esi,4
  add edi,4
  invoke wsprintf,addr szBuffer,addr szRec92,_dwValue   ;节区尺寸
  invoke _addLine,addr szBuffer,esi,edi,4
  add esi,4
  add edi,4
  invoke wsprintf,addr szBuffer,addr szRec93,_dwValue   ;节区RVA地址
  invoke _addLine,addr szBuffer,esi,edi,4
  add esi,4
  add edi,4
  invoke wsprintf,addr szBuffer,addr szRec94,_dwValue   ;在文件中对齐后的大小
  invoke _addLine,addr szBuffer,esi,edi,4
  add esi,4
  add edi,4
  invoke wsprintf,addr szBuffer,addr szRec95,_dwValue   ;在文件中的偏移
  invoke _addLine,addr szBuffer,esi,edi,4
  add esi,4
  add edi,4
  invoke wsprintf,addr szBuffer,addr szRec96,_dwValue   ;
  invoke _addLine,addr szBuffer,esi,edi,4
  add esi,4
  add edi,4
  invoke wsprintf,addr szBuffer,addr szRec97,_dwValue   ;
  invoke _addLine,addr szBuffer,esi,edi,2
  add esi,2
  add edi,2
  invoke wsprintf,addr szBuffer,addr szRec98,_dwValue   ;
  invoke _addLine,addr szBuffer,esi,edi,2
  add esi,2
  add edi,2
  invoke wsprintf,addr szBuffer,addr szRec99,_dwValue   ;节属性
  invoke _addLine,addr szBuffer,esi,edi,4

  popad
  ret
_Header3 endp


;_goHere


;--------------------
; 打开PE文件并处理
; 处理两个文件，进行对比
;--------------------
_openFile proc
  local @stOF:OPENFILENAME;打开文件结构
  local @hFile,@dwFileSize,@hMapFile,@lpMemory;文件句柄，文件大小，文件内存镜像句柄，镜像内存起始偏移
  local @hFile1,@dwFileSize1,@hMapFile1,@lpMemory1
  local @bufTemp1[10]:byte
  local @dwTemp:dword


  ; 处理文件1
  ; 到开文件1
  invoke CreateFile,addr szFileNameOpen1,GENERIC_READ,\
         FILE_SHARE_READ or FILE_SHARE_WRITE,NULL,\
         OPEN_EXISTING,FILE_ATTRIBUTE_ARCHIVE,NULL

  .if eax!=INVALID_HANDLE_VALUE;判断文件1是否合法
    mov @hFile,eax;文件1句柄
    invoke GetFileSize,eax,NULL;获取文件1的大小
    mov @dwFileSize,eax;将值放好
    .if eax;判断文件创建是否合法
      invoke CreateFileMapping,@hFile,\  ;创建文件镜像
             NULL,PAGE_READONLY,0,0,NULL
      .if eax;判断镜像是否合法
        mov @hMapFile,eax
        invoke MapViewOfFile,eax,\  ;获得文件在内存的映象起始位置
               FILE_MAP_READ,0,0,0
        .if eax;判断起始位置是否合法
          mov @lpMemory,eax;镜像起始地址放入全局变量中
          ;-----------------------------异常处理准备工作
          assume fs:nothing
          push ebp
          push offset _ErrFormat
          push offset _Handler
          push fs:[0]
          mov fs:[0],esp
          ;-----------------------------异常处理准备工作

          ;检测PE文件是否有效
          mov esi,@lpMemory
          assume esi:ptr IMAGE_DOS_HEADER;假设esi为指针并指向一个DOS头的结构
          .if [esi].e_magic!=IMAGE_DOS_SIGNATURE  ;判断是否有MZ字样
            jmp _ErrFormat
          .endif
          add esi,[esi].e_lfanew    ;调整ESI指针指向PE文件头
          assume esi:ptr IMAGE_NT_HEADERS;假设esi为指针并指向NT头的结构
          .if [esi].Signature!=IMAGE_NT_SIGNATURE ;判断是否有PE字样
            jmp _ErrFormat
          .endif
        .endif
      .endif
    .endif
  .endif

  ; 处理文件2，过程与处理文件1完全一样
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

  ;到此为止，两个内存文件的指针已经获取到了。
  ;@lpMemory和@lpMemory1分别指向两个文件头
  ;下面是从这个文件头开始，找出各数据结构的字段值，进行比较。

  ;调整ESI,EDI指向DOS头
  mov esi,@lpMemory
  assume esi:ptr IMAGE_DOS_HEADER;假设esi为指向IMAG_DOS_HEADER结构体类型的指针
  mov edi,@lpMemory1
  assume edi:ptr IMAGE_DOS_HEADER;假设edi为指向IMAG_DOS_HEADER结构体类型的指针
  ; 输出DOS头信息
  invoke _Header1

  ;调整ESI,EDI指针指向PE文件头
  add esi,[esi].e_lfanew    
  assume esi:ptr IMAGE_NT_HEADERS;假设esi为指向NT头结构体类型的指针
  add edi,[edi].e_lfanew    
  assume edi:ptr IMAGE_NT_HEADERS;假设edi为指向NT头结构体类型的指针
  ;输出PE头信息
  invoke _Header2

  ;esi+6z找到节数量
  movzx ecx,word ptr [esi+6]
  movzx eax,word ptr [edi+6]

  ;以较多节数用来计数
  .if eax>ecx
     mov ecx,eax
  .endif

  ;调整ESI,EDI指针指向节表
  add esi,sizeof IMAGE_NT_HEADERS
  add edi,sizeof IMAGE_NT_HEADERS
  mov eax,1
  .repeat
    invoke _Header3
    dec ecx
    inc eax
    .break .if ecx==0
    ;调整ESI,EDI指针指向下一个节表项
    add esi,sizeof IMAGE_SECTION_HEADER
    add edi,sizeof IMAGE_SECTION_HEADER
  .until FALSE

  
  jmp _ErrorExit  ;正常退出

_ErrFormat:
          invoke MessageBox,hWinMain,offset szErrFormat,NULL,MB_OK
_ErrorExit:
          pop fs:[0]
          add esp,0ch
          invoke UnmapViewOfFile,@lpMemory;卸载镜像
          invoke CloseHandle,@hMapFile;关闭镜像句柄
          invoke CloseHandle,@hFile;关闭文件句柄
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

;-----------------------
; 弹出PE对比窗口回调函数
;-----------------------
_resultProcMain   proc  uses ebx edi esi hProcessModuleDlg:HWND,wMsg,wParam,lParam
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
             
             ;定义表格外观
             invoke SendMessage,hProcessModuleTable,LVM_SETEXTENDEDLISTVIEWSTYLE,\
                    0,LVS_EX_GRIDLINES or LVS_EX_FULLROWSELECT
             invoke ShowWindow,hProcessModuleTable,SW_SHOW
             ;清空表格内容
             invoke _clearResultView

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
                     invoke SetWindowLong,hProcessModuleDlg,DWL_MSGRESULT,\
                                                               CDRF_NOTIFYITEMDRAW
                     mov eax,TRUE
                  .elseif [ebx].nmcd.dwDrawStage==CDDS_ITEMPREPAINT

                     ;当每一单元格内容预画时，判断
                     ;两列的值是否一致
                     invoke _GetListViewItem,hProcessModuleTable,\
                                         [ebx].nmcd.dwItemSpec,1,addr bufTemp1
                     invoke _GetListViewItem,hProcessModuleTable,\
                                         [ebx].nmcd.dwItemSpec,2,addr bufTemp2
                     invoke lstrlen,addr bufTemp1
                     invoke _MemCmp,addr bufTemp1,addr bufTemp2,eax

                     ;如果一致，则将文本的背景色设置为浅红色，否则黑色
                     .if eax==1
                        mov [ebx].clrTextBk,0a0a0ffh
                     .else
                        mov [ebx].clrTextBk,0ffffffh
                     .endif
                     invoke SetWindowLong,hProcessModuleDlg,DWL_MSGRESULT,\
                                                                CDRF_DODEFAULT
                     mov eax,TRUE
                   .endif
                .elseif [ebx+NMHDR.code]==NM_CLICK
                    assume ebx:ptr NMLISTVIEW
                .endif
            .endif
          .elseif eax==WM_COMMAND
             mov eax,wParam
             .if ax==IDC_OK  ;刷新
                invoke _openFile
             .elseif ax==IDC_BROWSE1
                invoke _OpenFile1    ;用户选择第一个文件
             .elseif ax==IDC_BROWSE2
                invoke _OpenFile2    ;用户选择第二个文件
             .endif
         .else
             mov eax,FALSE
             ret
         .endif
         mov eax,TRUE
         ret
_resultProcMain    endp


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
    .elseif eax==IDM_OPEN   ;打开PE对比对话框
         invoke DialogBoxParam,hInstance,RESULT_MODULE,hWnd,\
               offset _resultProcMain,0
         invoke InvalidateRect,hWnd,NULL,TRUE
         invoke UpdateWindow,hWnd
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



