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
dwCount     dd�Ƕ��� ?
dwColorRed  dd ?
hText1      dd ?
hText2      dd ?
hFile       dd ?  ;������ļ����������ظ�ʹ�ã�ʹ��ǰ���ʼ��


hProcessModuleTable dd ?


szFileName           db MAX_PATH dup(?)
szFileNameOpen1      db MAX_PATH dup(0)
szFileNameOpen2      db MAX_PATH dup(0)


szResultColName1 db  'PE���ݽṹ����ֶ�',0
szResultColName2 db  '�ļ�1��ֵ(H)',0
szResultColName3 db  '�ļ�2��ֵ(H)',0
szBuffer         db  256 dup(0),0
bufTemp1         db  200 dup(0),0
bufTemp2         db  200 dup(0),0
szFilter1        db  'Excutable Files',0,'*.exe;*.com',0;�ļ����͹���
                 db  0

.const
szDllEdit   db 'RichEd20.dll',0
szClassEdit db 'RichEdit20A',0
szFont      db '����',0
szExtPe     db 'PE File',0,'*.exe;*.dll;*.scr;*.fon;*.drv',0
            db 'All Files(*.*)',0,'*.*',0,0
szErr       db '�ļ���ʽ����!',0
szErrFormat db '����ļ�����PE��ʽ���ļ�!',0
szSuccess   db '��ϲ�㣬����ִ�е������ǳɹ��ġ�',0
szNotFound  db '�޷�����',0


szRec1      db 'IMAGE_DOS_HEADER.e_magic',0;dosͷ��ʶ
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
szRec19     db 'IMAGE_DOS_HEADER.e_lfanew',0;peͷ���ƫ��

szRec20     db 'IMAGE_NT_HEADERS.Signature',0;peͷ��ʶ

szRec21     db 'IMAGE_FILE_HEADER.Machine',0;����ƽ̨
szRec22     db 'IMAGE_FILE_HEADER.NumberOfSections',0;pe�нڵ�����
szRec23     db 'IMAGE_FILE_HEADER.TimeDateStamp',0;�ļ��������ں�ʱ��
szRec24     db 'IMAGE_FILE_HEADER.PointerToSymbolTable',0
szRec25     db 'IMAGE_FILE_HEADER.NumberOfSymbols',0
szRec26     db 'IMAGE_FILE_HEADER.SizeOfOptionalHeader',0;��չͷ���ȣ�32Ϊ224�ֽڣ�64Ϊ240�ֽ�
szRec27     db 'IMAGE_FILE_HEADER.Characteristics',0;�ļ�����

szRec28     db 'IMAGE_OPTIONAL_HEADER32.Magic',0;ħ����
szRec29     db 'IMAGE_OPTIONAL_HEADER32.MajorLinkerVersion',0;�������汾
szRec30     db 'IMAGE_OPTIONAL_HEADER32.MinorLinkerVersion',0;������С�汾
szRec31     db 'IMAGE_OPTIONAL_HEADER32.SizeOfCode',0;������ܴ�С
szRec32     db 'IMAGE_OPTIONAL_HEADER32.SizeOfInitializedData',0;�ѳ�ʼ���ڵĴ�С
szRec33     db 'IMAGE_OPTIONAL_HEADER32.SizeOfUninitializedData',0;δ��ʼ���ڵĴ�С
szRec34     db 'IMAGE_OPTIONAL_HEADER32.AddressOfEntryPoint',0;ִ�����rva
szRec35     db 'IMAGE_OPTIONAL_HEADER32.BaseOfCode',0;�������ʼrva
szRec36     db 'IMAGE_OPTIONAL_HEADER32.BaseOfData',;���ݽ���ʼrva
szRec37     db 'IMAGE_OPTIONAL_HEADER32.ImageBase',0;������װ�ص�ַ��exe:0040 0000 dll:0010 0000
szRec38     db 'IMAGE_OPTIONAL_HEADER32.SectionAlignment',0;�ڴ��ж��������
szRec39     db 'IMAGE_OPTIONAL_HEADER32.FileAlignment',0;�ļ��ж��������
szRec40     db 'IMAGE_OPTIONAL_HEADER32.MajorOperatingSystemVersion',0;����ϵͳ��汾��
szRec41     db 'IMAGE_OPTIONAL_HEADER32.MinorOperatingSystemVersion',0;����ϵͳС�汾��
szRec42     db 'IMAGE_OPTIONAL_HEADER32.MajorImageVersion',0;PE����Ĵ�汾��
szRec43     db 'IMAGE_OPTIONAL_HEADER32.MinorImageVersion',0;PE�����С�汾��
szRec44     db 'IMAGE_OPTIONAL_HEADER32.MajorSubsystemVersion',0;������ϵͳ�Ĵ�汾��
szRec45     db 'IMAGE_OPTIONAL_HEADER32.MinorSubsystemVersion',0;������ϵͳ��С�汾��
szRec46     db 'IMAGE_OPTIONAL_HEADER32.Win32VersionValue',0
szRec47     db 'IMAGE_OPTIONAL_HEADER32.SizeOfImage',0;�ڴ�������PE����Ĵ�С
szRec48     db 'IMAGE_OPTIONAL_HEADER32.SizeOfHeaders',0;����ͷ+�ڱ�Ĵ�С
szRec49     db 'IMAGE_OPTIONAL_HEADER32.CheckSum',0;У���
szRec50     db 'IMAGE_OPTIONAL_HEADER32.Subsystem',0;�ļ���ϵͳ
szRec51     db 'IMAGE_OPTIONAL_HEADER32.DllCharacteristics',0;dll�ļ�������
szRec52     db 'IMAGE_OPTIONAL_HEADER32.SizeOfStackReserve',0;��ʼ��ʱջ�Ĵ�С
szRec53     db 'IMAGE_OPTIONAL_HEADER32.SizeOfStackCommit',0;��ʼ��ʱջʵ���ύ�Ĵ�С
szRec54     db 'IMAGE_OPTIONAL_HEADER32.SizeOfHeapReserve',0;��ʼ��ʱ�ѵĴ�С
szRec55     db 'IMAGE_OPTIONAL_HEADER32.SizeOfHeapCommit',0;��ʼ��ʱ��ʵ���ύ�Ĵ�С
szRec56     db 'IMAGE_OPTIONAL_HEADER32.LoaderFlags',0
szRec57     db 'IMAGE_OPTIONAL_HEADER32.NumberOfRvaAndSizes',0;����Ŀ¼�������һ��ʱ16��

szRec58     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(Export)',0;������RVA
szRec59     db 'IMAGE_DATA_DIRECTORY.isize(Export)',0;�������С
szRec60     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(Import)',0;�����rva
szRec61     db 'IMAGE_DATA_DIRECTORY.isize(Import)',0;������С
szRec62     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(Resource)',0;��Դ��RVA
szRec63     db 'IMAGE_DATA_DIRECTORY.isize(Resource)',0;��Դ���С
szRec64     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(Exception)',0;�쳣��RVA
szRec65     db 'IMAGE_DATA_DIRECTORY.isize(Exception)',0;�쳣���С
szRec66     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(Security)',0;��ȫ��RVA
szRec67     db 'IMAGE_DATA_DIRECTORY.isize(Security)',0;��ȫ���С
szRec68     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(BaseReloc)',0;�ض�λ��RVA
szRec69     db 'IMAGE_DATA_DIRECTORY.isize(BaseReloc)',0;�ض�λ���С
szRec70     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(Debug)',0;���Ա�RVA
szRec71     db 'IMAGE_DATA_DIRECTORY.isize(Debug)',0;���Ա��С
szRec72     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(Architecture)',0;��Ȩ��RVA
szRec73     db 'IMAGE_DATA_DIRECTORY.isize(Architecture)',0;��Ȩ���С
szRec74     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(GlobalPTR)',0;ȫ��ָ���RVA
szRec75     db 'IMAGE_DATA_DIRECTORY.isize(GlobalPTR)',0;ȫ��ָ����С
szRec76     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(TLS)',0;�̱߳��ش洢��RVA
szRec77     db 'IMAGE_DATA_DIRECTORY.isize(TLS)',0;�̱߳��ش洢���С
szRec78     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(Load_Config)',0;�������ñ�RVA
szRec79     db 'IMAGE_DATA_DIRECTORY.isize(Load_Config)',0;�������ñ��С
szRec80     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(Bound_Import)',0;�󶨵����RVA
szRec81     db 'IMAGE_DATA_DIRECTORY.isize(Bound_Import)',0;�󶨵�����С
szRec82     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(IAT)',0;IAT�������ַ��RVA
szRec83     db 'IMAGE_DATA_DIRECTORY.isize(IAT)',0;IAT�������ַ����С
szRec84     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(Delay_Import)',0;�ӳٵ����RVA
szRec85     db 'IMAGE_DATA_DIRECTORY.isize(Delay_Import)',0;�ӳٵ�����С
szRec86     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(Com_Descriptor)',0;CLR��RVA
szRec87     db 'IMAGE_DATA_DIRECTORY.isize(Com_Descriptor)',0;CLR���С
szRec88     db 'IMAGE_DATA_DIRECTORY.VirtualAddress(Reserved)',0;Ԥ����RVA
szRec89     db 'IMAGE_DATA_DIRECTORY.isize(Reserved)',0;Ԥ�����С

szRec90     db 'IMAGE_SECTION_HEADER%d.Name1',0;����
szRec91     db 'IMAGE_SECTION_HEADER%d.VirtualSize',0;�ڴ�С
szRec92     db 'IMAGE_SECTION_HEADER%d.VirtualAddress',0;��RVA
szRec93     db 'IMAGE_SECTION_HEADER%d.SizeOfRawData',0;�����ļ��ж����Ĵ�С
szRec94     db 'IMAGE_SECTION_HEADER%d.PointerToRawData',0;�����ļ��е�ƫ��
szRec95     db 'IMAGE_SECTION_HEADER%d.PointerToRelocations',0;
szRec96     db 'IMAGE_SECTION_HEADER%d.PointerToLinenumbers',0;
szRec97     db 'IMAGE_SECTION_HEADER%d.NumberOfRelocations',0;
szRec98     db 'IMAGE_SECTION_HEADER%d.NumberOfLinenumbers',0;
szRec99     db 'IMAGE_SECTION_HEADER%d.Characteristics',0;������


szOut1      db '%02x',0
szOut2      db '%04x',0
lpszHexArr  db  '0123456789ABCDEF',0

.data?
stLVC         LV_COLUMN <?>
stLVI         LV_ITEM   <?>

.code

;----------------
;��ʼ�����ڳ���
;----------------
_init proc
  local @stCf:CHARFORMAT
  
  invoke GetDlgItem,hWinMain,IDC_INFO
  mov hWinEdit,eax
  invoke LoadIcon,hInstance,ICO_MAIN
  invoke SendMessage,hWinMain,WM_SETICON,ICON_BIG,eax       ;Ϊ��������ͼ��
  invoke SendMessage,hWinEdit,EM_SETTEXTMODE,TM_PLAINTEXT,0 ;���ñ༭�ؼ�
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
; ����Handler
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
; ���ڴ�ƫ����RVAת��Ϊ�ļ�ƫ��
; ��ASM��ʵ���У��ú���û�еĵ�ʹ�ã���Ϊ���ֽڵĲ����ܺܺõ��õ����ݣ�����Ҫ����ת��
; _lpFileHead:�ļ���ʼƫ��
; _dwRVA:��ҪתΪFOA��RVA
;---------------------
_RVAToOffset proc _lpFileHead,_dwRVA
  local @dwReturn
  
  pushad
  mov esi,_lpFileHead;�ļ���ʼƫ��Ų��esi
  assume esi:ptr IMAGE_DOS_HEADER;����esi��ָ��DOSͷ�ṹ��ָ��
  add esi,[esi].e_lfanew;NTͷƫ��Ų��esi ��
  assume esi:ptr IMAGE_NT_HEADERS;����esi��ָ��NTͷ�ṹ��ָ��
  mov edi,_dwRVA;Ŀ��RVAŲ��edi��
  mov edx,esi;esiŲ��edx��
  add edx,sizeof IMAGE_NT_HEADERS;��edx����edxָ��ڱ���ƫ��
  assume edx:ptr IMAGE_SECTION_HEADER;����edx�ǽڱ���Ľṹ��ָ��
  movzx ecx,[esi].FileHeader.NumberOfSections;���ڵ���ĿŲ��ecx��
  ;�����ڱ�
  .repeat
    mov eax,[edx].VirtualAddress  ;����ǰ�ڵ�RVAŲ��EAX��
    add eax,[edx].SizeOfRawData  ;����ýڽ���RVA
    .if (edi>=[edx].VirtualAddress)&&(edi<eax);Ŀ���ַ��Ҫ���ڵ�ǰ�ڵ���ʼ��ַ����ҪС�ڵ�ǰ�ڵĽ�����ַ
      mov eax,[edx].VirtualAddress;�����������ٴν���ǰ�ڵ���ʼ��ַŲ��EAX��
      sub edi,eax                ;Ŀ��RVA-�ڵ���ʼRVA������Ŀ��RVA���ڽ���ʼ��ַ��ƫ��
      mov eax,[edx].PointerToRawData;����ǰ�ڵ���ʼ��ַ���ļ�ƫ��Ų��eax��
      add eax,edi                ;���Ͻ����ļ��еĵ���ʼλ�ü������ƫ��
      jmp @F ;������һ��@@��ִ��
    .endif
    add edx,sizeof IMAGE_SECTION_HEADER;��ǰ�ڲ���������������edxִ����һ���ڱ���ƫ��
  .untilcxz;֪��ecx����0������ѭ��
  assume edx:nothing;��ԭedx
  assume esi:nothing;��ԭesi
  mov eax,-1    ;û���ҵ����ý����ʶΪ-1
@@:
  mov @dwReturn,eax;���������ֲ�������
  popad     ;���������ļĴ���
  mov eax,@dwReturn ;�����������뵽EAX��
  ret   ;�������̵���
_RVAToOffset endp

;------------------------
; ��ȡRVA���ڽڵ�����
; _lpFileHead:����ͷƫ�Ƶ�ַ
; _dwRVA:Ҫ�����RVA
;------------------------
_getRVASectionName  proc _lpFileHead,_dwRVA
  local @dwReturn
  
  pushad;����ȫ���Ĵ���
  mov esi,_lpFileHead;����ƫ��ͷ�ŵ�esi��
  assume esi:ptr IMAGE_DOS_HEADER;����esi��ָ��DOSͷ��ָ��
  add esi,[esi].e_lfanew;����esi��ָ��NTͷ
  assume esi:ptr IMAGE_NT_HEADERS;����esi��ָ��NTͷ��ָ��
  mov edi,_dwRVA;Ҫ�����RVA��ַ���뵽edi��
  mov edx,esi;��ָ��NTͷ��ָ����뵽edx��
  add edx,sizeof IMAGE_NT_HEADERS;����edxָ��ڱ���
  assume edx:ptr IMAGE_SECTION_HEADER;����EDXΪָ��ڱ���ṹ��ָ��
  movzx ecx,[esi].FileHeader.NumberOfSections;���ڱ������������ECX�У����м���
  ;�����ڱ�
  .repeat
    mov eax,[edx].VirtualAddress  ;���ڱ��RVA���뵽EAX��
    add eax,[edx].SizeOfRawData  ;����ýڽ���RVA
    .if (edi>=[edx].VirtualAddress)&&(edi<eax);Ŀ���ַ��Ҫ�������������ڵ��ڵ�ǰ�ڱ���ʼ��ַ��С�ڵ�ǰ�ڱ�Ľ�����ַ
      mov eax,edx;������������ǰ�ڱ������ʼ��ַ���뵽eax��
      jmp @F;ֱ��������һ��@@������ָ��
    .endif
    add edx,sizeof IMAGE_SECTION_HEADER;�����ǰ�ڱ����������������edxָ�룬ָ����һ���ڱ���
  .untilcxz;֪��ecx=0������ѭ��
  assume edx:nothing;��ԭedx
  assume esi:nothing;��ԭesi
  mov eax,offset szNotFound;û���ҵ�����û���ҵ��ı�ʶ���뵽eax��
@@:
  mov @dwReturn,eax;�ҵ��˾ͽ��ҵ��ĵ�ַ���뵽�ֲ��������ݴ�
  popad;�������������мĴ���
  mov eax,@dwReturn;���ֲ�������ֵŲ��eax��
  ret;������ǰ����
_getRVASectionName  endp


;-------------------------
; ��ListView������һ����
; ���룺_dwColumn = ���ӵ��б��
;	_dwWidth = �еĿ��
;	_lpszHead = �еı����ַ��� 
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
; ��ListView������һ�У����޸�һ����ĳ���ֶε�����
; ���룺_dwItem = Ҫ�޸ĵ��еı��
;	_dwSubItem = Ҫ�޸ĵ��ֶεı�ţ�-1��ʾ�����µ��У�>=1��ʾ�ֶεı��
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
; ���ListView�е�����
; ɾ�����е��к����е���
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
; ����ָ�����е�ֵ
; �����szBuffer��
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
; ��ʼ��������
;---------------------
_clearResultView  proc uses ebx ecx
             invoke _ListViewClear,hProcessModuleTable

             ;��ӱ�ͷ
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
; �������ļ�
;------------------------------------------
_OpenFile1	proc
		local	@stOF:OPENFILENAME;�ֲ��������ļ��򿪽ṹ
		local	@stES:EDITSTREAM;��û����

    ;�����֮ǰ�����ļ�������ڣ����ȹر��ٸ�ֵ  
    ;ʹ��ǰ��ʼ��              
    .if hFile
       invoke CloseHandle,hFile
       mov hFile,0
    .endif
    ; ��ʾ�����ļ����Ի���
    ; ����ڴ�
		invoke	RtlZeroMemory,addr @stOF,sizeof @stOF
    ;����@stOF�нṹ���С����
		mov	@stOF.lStructSize,sizeof @stOF
		push	hWinMain
		pop	  @stOF.hwndOwner
    push  hInstance;���ļ������ؼ���ֵ
    pop   @stOF.hInstance
		mov	@stOF.lpstrFilter,offset szFilter1  ;�ļ����͹���
		mov	@stOF.lpstrFile,offset szFileNameOpen1;�ļ����ƻ�����
		mov	@stOF.nMaxFile,MAX_PATH
		mov	@stOF.Flags,OFN_FILEMUSTEXIST or\
                                    OFN_HIDEREADONLY or OFN_PATHMUSTEXIST
    ; ִ�д��ļ�                                
		invoke	GetOpenFileName,addr @stOF
		.if	eax
      ; ���򿪵��ļ�ȫ·��д��ؼ���
      invoke SetWindowText,hText1,addr szFileNameOpen1
		.endif
		ret

_OpenFile1	endp
;------------------------------------------
; �������ļ�
; ��openFile1���һ��
;------------------------------------------
_OpenFile2	proc
		local	@stOF:OPENFILENAME
		local	@stES:EDITSTREAM

                ;�����֮ǰ�����ļ�������ڣ����ȹر��ٸ�ֵ                
                .if hFile
                   invoke CloseHandle,hFile
                   mov hFile,0
                .endif
                ; ��ʾ�����ļ����Ի���
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
; ��_lpPointλ�ô�_dwSize���ֽ�ת��Ϊ16���Ƶ��ַ���
; bufTemp1��Ϊת������ַ���
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
    div cx   ;�����λ��al�У�������dl��


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
; �ڱ��������һ��
; _lpSZΪ��һ��Ҫ��ʾ���ֶ���
; _lpSP1Ϊ��һ���ļ����ֶε�λ��
; _lpSP2Ϊ�ڶ����ļ����ֶε�λ��
; _SizeΪ���ֶε��ֽڳ���
;--------------------------------------------
_addLine proc _lpSZ,_lpSP1,_lpSP2,_Size
  pushad

  invoke _ListViewSetItem,hProcessModuleTable,dwCount,-1,\
               _lpSZ             ;�ڱ����������һ��
  mov dwCount,eax

  xor ebx,ebx
  invoke _ListViewSetItem,hProcessModuleTable,dwCount,ebx,\
         _lpSZ                   ;��ʾ�ֶ���
  
  invoke RtlZeroMemory,addr szBuffer,50
  invoke MemCopy,_lpSP1,addr bufTemp2,_Size
  invoke _Byte2Hex,_Size

  ;��ָ���ֶΰ���ʮ��������ʾ����ʽ��һ���ֽ�+һ���ո�
  invoke lstrcat,addr szBuffer,addr bufTemp1
  inc ebx
  invoke _ListViewSetItem,hProcessModuleTable,dwCount,ebx,\
                   addr szBuffer ;��һ���ļ��е�ֵ

  invoke RtlZeroMemory,addr szBuffer,50
  invoke MemCopy,_lpSP2,addr bufTemp2,_Size
  invoke _Byte2Hex,_Size
  invoke lstrcat,addr szBuffer,addr bufTemp1
  inc ebx
  invoke _ListViewSetItem,hProcessModuleTable,dwCount,ebx,\
                   addr szBuffer ;�ڶ����ļ��е�ֵ

  popad
  ret
_addLine  endp

;-----------------------
; IMAGE_DOS_HEADERͷ��Ϣ
; ����DOSͷ
;-----------------------
_Header1 proc 
  pushad

  invoke _addLine,addr szRec1,esi,edi,2 ;DOSͷ��ʶMZ
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
  invoke _addLine,addr szRec19,esi,edi,4;PEͷƫ�Ƶ�ַ
  popad
  ret
_Header1 endp

;-----------------------
; IMAGE_DOS_HEADERͷ��Ϣ
;-----------------------
_Header2 proc 
  pushad

  invoke _addLine,addr szRec20,esi,edi,4;PEͷ��ʶ
  add esi,4
  add edi,4
  invoke _addLine,addr szRec21,esi,edi,2;����ƽ̨
  add esi,2
  add edi,2
  invoke _addLine,addr szRec22,esi,edi,2;PE�нڵ�����
  add esi,2
  add edi,2
  invoke _addLine,addr szRec23,esi,edi,4;�ļ��������ں�ʱ��
  add esi,4
  add edi,4
  invoke _addLine,addr szRec24,esi,edi,4;
  add esi,4
  add edi,4
  invoke _addLine,addr szRec25,esi,edi,4;
  add esi,4
  add edi,4
  invoke _addLine,addr szRec26,esi,edi,2;��չͷ��С��32λ224λ��64λ240λ
  add esi,2
  add edi,2
  invoke _addLine,addr szRec27,esi,edi,2;�ļ�����
  add esi,2
  add edi,2
  invoke _addLine,addr szRec28,esi,edi,2;ħ����
  add esi,2
  add edi,2
  invoke _addLine,addr szRec29,esi,edi,1;��������汾
  add esi,1
  add edi,1
  invoke _addLine,addr szRec30,esi,edi,1;������С�汾
  add esi,1
  add edi,1
  invoke _addLine,addr szRec31,esi,edi,4;������ܴ�С
  add esi,4
  add edi,4
  invoke _addLine,addr szRec32,esi,edi,4;�ѳ�ʼ���ڵĴ�С
  add esi,4
  add edi,4
  invoke _addLine,addr szRec33,esi,edi,4;δ��ʼ���ڵĴ�С
  add esi,4
  add edi,4
  invoke _addLine,addr szRec34,esi,edi,4;ִ�����RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec35,esi,edi,4;�������ʼRVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec36,esi,edi,4;���ݽ���ʼRVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec37,esi,edi,4;������װ�ص�ַ��EXE��0040 0000 DLL��1000 0000
  add esi,4
  add edi,4
  invoke _addLine,addr szRec38,esi,edi,4;�ڴ��ж��������
  add esi,4
  add edi,4
  invoke _addLine,addr szRec39,esi,edi,4;�ļ��ж��������
  add esi,4
  add edi,4
  invoke _addLine,addr szRec40,esi,edi,2;����ϵͳ��汾��
  add esi,2
  add edi,2
  invoke _addLine,addr szRec41,esi,edi,2;����ϵͳС�汾��
  add esi,2
  add edi,2
  invoke _addLine,addr szRec42,esi,edi,2;PE�����汾��
  add esi,2
  add edi,2
  invoke _addLine,addr szRec43,esi,edi,2;PE����С�汾��
  add esi,2
  add edi,2
  invoke _addLine,addr szRec44,esi,edi,2;������ϵͳ�Ĵ�汾
  add esi,2
  add edi,2
  invoke _addLine,addr szRec45,esi,edi,2;������ϵͳ��С�汾
  add esi,2
  add edi,2
  invoke _addLine,addr szRec46,esi,edi,4;//
  add esi,4
  add edi,4
  invoke _addLine,addr szRec47,esi,edi,4;�ڴ�������PE����Ĵ�С
  add esi,4
  add edi,4
  invoke _addLine,addr szRec48,esi,edi,4;����ͷ�ӽڱ�Ĵ�С
  add esi,4
  add edi,4
  invoke _addLine,addr szRec49,esi,edi,4;У���
  add esi,4
  add edi,4
  invoke _addLine,addr szRec50,esi,edi,2;�ļ���ϵͳ
  add esi,2
  add edi,2
  invoke _addLine,addr szRec51,esi,edi,2;DLL�ļ�����
  add esi,2
  add edi,2
  invoke _addLine,addr szRec52,esi,edi,4;��ʼ��ʱջ�Ĵ�С
  add esi,4
  add edi,4
  invoke _addLine,addr szRec53,esi,edi,4;��ʼ��ʱջʵ���ύ�Ĵ�С
  add esi,4
  add edi,4
  invoke _addLine,addr szRec54,esi,edi,4;��ʼ��ʱ�ѵĴ�С
  add esi,4
  add edi,4
  invoke _addLine,addr szRec55,esi,edi,4;��ʼ��ʱ��ʵ�ʵĴ�С
  add esi,4
  add edi,4
  invoke _addLine,addr szRec56,esi,edi,4;
  add esi,4
  add edi,4
  invoke _addLine,addr szRec57,esi,edi,4;����Ŀ¼�������һ��16��

  ;IMAGE_DATA_DIRECTORY

  add esi,4
  add edi,4
  invoke _addLine,addr szRec58,esi,edi,4;������RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec59,esi,edi,4;�������С
  add esi,4
  add edi,4
  invoke _addLine,addr szRec60,esi,edi,4;�����RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec61,esi,edi,4;������С
  add esi,4
  add edi,4
  invoke _addLine,addr szRec62,esi,edi,4;��Դ��RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec63,esi,edi,4;��Դ���С
  add esi,4
  add edi,4
  invoke _addLine,addr szRec64,esi,edi,4;�쳣��RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec65,esi,edi,4;�쳣���С
  add esi,4
  add edi,4
  invoke _addLine,addr szRec66,esi,edi,4;��ȫ��RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec67,esi,edi,4;��ȫ���С
  add esi,4
  add edi,4
  invoke _addLine,addr szRec68,esi,edi,4;�ض�λ��RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec69,esi,edi,4;�ض�λ���С
  add esi,4
  add edi,4
  invoke _addLine,addr szRec70,esi,edi,4;���Ա�RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec71,esi,edi,4;���Ա��С
  add esi,4
  add edi,4
  invoke _addLine,addr szRec72,esi,edi,4;��Ȩ��RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec73,esi,edi,4;��Ȩ���С
  add esi,4
  add edi,4
  invoke _addLine,addr szRec74,esi,edi,4;��Ȩ��RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec75,esi,edi,4;��Ȩ���С
  add esi,4
  add edi,4
  invoke _addLine,addr szRec76,esi,edi,4;ȫ��ָ���RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec77,esi,edi,4;ȫ��ָ����С
  add esi,4
  add edi,4
  invoke _addLine,addr szRec78,esi,edi,4;�̱߳��ش洢RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec79,esi,edi,4;�̱߳��ش洢��С
  add esi,4
  add edi,4
  invoke _addLine,addr szRec80,esi,edi,4;�������ñ�RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec81,esi,edi,4;�������ñ��С
  add esi,4
  add edi,4
  invoke _addLine,addr szRec82,esi,edi,4;�󶨵����RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec83,esi,edi,4;�󶨵�����С
  add esi,4
  add edi,4
  invoke _addLine,addr szRec84,esi,edi,4;IAT�������ַ��RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec85,esi,edi,4;IAT�������ַ����С
  add esi,4
  add edi,4
  invoke _addLine,addr szRec86,esi,edi,4;CLR��RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec87,esi,edi,4;CLR���С
  add esi,4
  add edi,4
  invoke _addLine,addr szRec88,esi,edi,4;Ԥ����RVA
  add esi,4
  add edi,4
  invoke _addLine,addr szRec89,esi,edi,4;Ԥ�����С


  popad
  ret
_Header2 endp

;---------------------------------------
; �ڱ�
;  eax=�����
;---------------------------------------
_Header3 proc 
  local _dwValue:dword
  pushad
  mov _dwValue,eax

  invoke wsprintf,addr szBuffer,addr szRec90,_dwValue   
  invoke _addLine,addr szBuffer,esi,edi,8;
  add esi,8
  add edi,8
  invoke wsprintf,addr szBuffer,addr szRec91,_dwValue  ; ��������
  invoke _addLine,addr szBuffer,esi,edi,4
  add esi,4
  add edi,4
  invoke wsprintf,addr szBuffer,addr szRec92,_dwValue   ;�����ߴ�
  invoke _addLine,addr szBuffer,esi,edi,4
  add esi,4
  add edi,4
  invoke wsprintf,addr szBuffer,addr szRec93,_dwValue   ;����RVA��ַ
  invoke _addLine,addr szBuffer,esi,edi,4
  add esi,4
  add edi,4
  invoke wsprintf,addr szBuffer,addr szRec94,_dwValue   ;���ļ��ж����Ĵ�С
  invoke _addLine,addr szBuffer,esi,edi,4
  add esi,4
  add edi,4
  invoke wsprintf,addr szBuffer,addr szRec95,_dwValue   ;���ļ��е�ƫ��
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
  invoke wsprintf,addr szBuffer,addr szRec99,_dwValue   ;������
  invoke _addLine,addr szBuffer,esi,edi,4

  popad
  ret
_Header3 endp


;_goHere


;--------------------
; ��PE�ļ�������
; ���������ļ������жԱ�
;--------------------
_openFile proc
  local @stOF:OPENFILENAME;���ļ��ṹ
  local @hFile,@dwFileSize,@hMapFile,@lpMemory;�ļ�������ļ���С���ļ��ڴ澵�����������ڴ���ʼƫ��
  local @hFile1,@dwFileSize1,@hMapFile1,@lpMemory1
  local @bufTemp1[10]:byte
  local @dwTemp:dword


  ; �����ļ�1
  ; �����ļ�1
  invoke CreateFile,addr szFileNameOpen1,GENERIC_READ,\
         FILE_SHARE_READ or FILE_SHARE_WRITE,NULL,\
         OPEN_EXISTING,FILE_ATTRIBUTE_ARCHIVE,NULL

  .if eax!=INVALID_HANDLE_VALUE;�ж��ļ�1�Ƿ�Ϸ�
    mov @hFile,eax;�ļ�1���
    invoke GetFileSize,eax,NULL;��ȡ�ļ�1�Ĵ�С
    mov @dwFileSize,eax;��ֵ�ź�
    .if eax;�ж��ļ������Ƿ�Ϸ�
      invoke CreateFileMapping,@hFile,\  ;�����ļ�����
             NULL,PAGE_READONLY,0,0,NULL
      .if eax;�жϾ����Ƿ�Ϸ�
        mov @hMapFile,eax
        invoke MapViewOfFile,eax,\  ;����ļ����ڴ��ӳ����ʼλ��
               FILE_MAP_READ,0,0,0
        .if eax;�ж���ʼλ���Ƿ�Ϸ�
          mov @lpMemory,eax;������ʼ��ַ����ȫ�ֱ�����
          ;-----------------------------�쳣����׼������
          assume fs:nothing
          push ebp
          push offset _ErrFormat
          push offset _Handler
          push fs:[0]
          mov fs:[0],esp
          ;-----------------------------�쳣����׼������

          ;���PE�ļ��Ƿ���Ч
          mov esi,@lpMemory
          assume esi:ptr IMAGE_DOS_HEADER;����esiΪָ�벢ָ��һ��DOSͷ�Ľṹ
          .if [esi].e_magic!=IMAGE_DOS_SIGNATURE  ;�ж��Ƿ���MZ����
            jmp _ErrFormat
          .endif
          add esi,[esi].e_lfanew    ;����ESIָ��ָ��PE�ļ�ͷ
          assume esi:ptr IMAGE_NT_HEADERS;����esiΪָ�벢ָ��NTͷ�Ľṹ
          .if [esi].Signature!=IMAGE_NT_SIGNATURE ;�ж��Ƿ���PE����
            jmp _ErrFormat
          .endif
        .endif
      .endif
    .endif
  .endif

  ; �����ļ�2�������봦���ļ�1��ȫһ��
  invoke CreateFile,addr szFileNameOpen2,GENERIC_READ,\
         FILE_SHARE_READ or FILE_SHARE_WRITE,NULL,\
         OPEN_EXISTING,FILE_ATTRIBUTE_ARCHIVE,NULL

  .if eax!=INVALID_HANDLE_VALUE
    mov @hFile1,eax
    invoke GetFileSize,eax,NULL
    mov @dwFileSize1,eax
    .if eax
      invoke CreateFileMapping,@hFile1,\  ;�ڴ�ӳ���ļ�
             NULL,PAGE_READONLY,0,0,NULL
      .if eax
        mov @hMapFile1,eax
        invoke MapViewOfFile,eax,\
               FILE_MAP_READ,0,0,0
        .if eax
          mov @lpMemory1,eax              ;����ļ����ڴ��ӳ����ʼλ��
          assume fs:nothing
          push ebp
          push offset _ErrFormat1
          push offset _Handler
          push fs:[0]
          mov fs:[0],esp

          ;���PE�ļ��Ƿ���Ч
          mov esi,@lpMemory1
          assume esi:ptr IMAGE_DOS_HEADER
          .if [esi].e_magic!=IMAGE_DOS_SIGNATURE  ;�ж��Ƿ���MZ����
            jmp _ErrFormat1
          .endif
          add esi,[esi].e_lfanew    ;����ESIָ��ָ��PE�ļ�ͷ
          assume esi:ptr IMAGE_NT_HEADERS
          .if [esi].Signature!=IMAGE_NT_SIGNATURE ;�ж��Ƿ���PE����
            jmp _ErrFormat1
          .endif
        .endif
      .endif
    .endif
  .endif

  ;����Ϊֹ�������ڴ��ļ���ָ���Ѿ���ȡ���ˡ�
  ;@lpMemory��@lpMemory1�ֱ�ָ�������ļ�ͷ
  ;�����Ǵ�����ļ�ͷ��ʼ���ҳ������ݽṹ���ֶ�ֵ�����бȽϡ�

  ;����ESI,EDIָ��DOSͷ
  mov esi,@lpMemory
  assume esi:ptr IMAGE_DOS_HEADER;����esiΪָ��IMAG_DOS_HEADER�ṹ�����͵�ָ��
  mov edi,@lpMemory1
  assume edi:ptr IMAGE_DOS_HEADER;����ediΪָ��IMAG_DOS_HEADER�ṹ�����͵�ָ��
  ; ���DOSͷ��Ϣ
  invoke _Header1

  ;����ESI,EDIָ��ָ��PE�ļ�ͷ
  add esi,[esi].e_lfanew    
  assume esi:ptr IMAGE_NT_HEADERS;����esiΪָ��NTͷ�ṹ�����͵�ָ��
  add edi,[edi].e_lfanew    
  assume edi:ptr IMAGE_NT_HEADERS;����ediΪָ��NTͷ�ṹ�����͵�ָ��
  ;���PEͷ��Ϣ
  invoke _Header2

  ;esi+6z�ҵ�������
  movzx ecx,word ptr [esi+6]
  movzx eax,word ptr [edi+6]

  ;�Խ϶������������
  .if eax>ecx
     mov ecx,eax
  .endif

  ;����ESI,EDIָ��ָ��ڱ�
  add esi,sizeof IMAGE_NT_HEADERS
  add edi,sizeof IMAGE_NT_HEADERS
  mov eax,1
  .repeat
    invoke _Header3
    dec ecx
    inc eax
    .break .if ecx==0
    ;����ESI,EDIָ��ָ����һ���ڱ���
    add esi,sizeof IMAGE_SECTION_HEADER
    add edi,sizeof IMAGE_SECTION_HEADER
  .until FALSE

  
  jmp _ErrorExit  ;�����˳�

_ErrFormat:
          invoke MessageBox,hWinMain,offset szErrFormat,NULL,MB_OK
_ErrorExit:
          pop fs:[0]
          add esp,0ch
          invoke UnmapViewOfFile,@lpMemory;ж�ؾ���
          invoke CloseHandle,@hMapFile;�رվ�����
          invoke CloseHandle,@hFile;�ر��ļ����
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
; ����PE�Աȴ��ڻص�����
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
             
             ;���������
             invoke SendMessage,hProcessModuleTable,LVM_SETEXTENDEDLISTVIEWSTYLE,\
                    0,LVS_EX_GRIDLINES or LVS_EX_FULLROWSELECT
             invoke ShowWindow,hProcessModuleTable,SW_SHOW
             ;��ձ������
             invoke _clearResultView

          .elseif eax==WM_NOTIFY
            mov eax,lParam
            mov ebx,lParam
            ;���ĸ��ؼ�״̬
            mov eax,[eax+NMHDR.hwndFrom]
            .if eax==hProcessModuleTable
                mov ebx,lParam
                .if [ebx+NMHDR.code]==NM_CUSTOMDRAW  ;�滭ʱ
                  mov ebx,lParam
                  assume ebx:ptr NMLVCUSTOMDRAW  
                  .if [ebx].nmcd.dwDrawStage==CDDS_PREPAINT
                     invoke SetWindowLong,hProcessModuleDlg,DWL_MSGRESULT,\
                                                               CDRF_NOTIFYITEMDRAW
                     mov eax,TRUE
                  .elseif [ebx].nmcd.dwDrawStage==CDDS_ITEMPREPAINT

                     ;��ÿһ��Ԫ������Ԥ��ʱ���ж�
                     ;���е�ֵ�Ƿ�һ��
                     invoke _GetListViewItem,hProcessModuleTable,\
                                         [ebx].nmcd.dwItemSpec,1,addr bufTemp1
                     invoke _GetListViewItem,hProcessModuleTable,\
                                         [ebx].nmcd.dwItemSpec,2,addr bufTemp2
                     invoke lstrlen,addr bufTemp1
                     invoke _MemCmp,addr bufTemp1,addr bufTemp2,eax

                     ;���һ�£����ı��ı���ɫ����Ϊǳ��ɫ�������ɫ
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
             .if ax==IDC_OK  ;ˢ��
                invoke _openFile
             .elseif ax==IDC_BROWSE1
                invoke _OpenFile1    ;�û�ѡ���һ���ļ�
             .elseif ax==IDC_BROWSE2
                invoke _OpenFile2    ;�û�ѡ��ڶ����ļ�
             .endif
         .else
             mov eax,FALSE
             ret
         .endif
         mov eax,TRUE
         ret
_resultProcMain    endp


;-------------------
; ���ڳ���
;-------------------
_ProcDlgMain proc uses ebx edi esi hWnd,wMsg,wParam,lParam
  mov eax,wMsg
  .if eax==WM_CLOSE
    invoke EndDialog,hWnd,NULL
  .elseif eax==WM_INITDIALOG  ;��ʼ��
    push hWnd
    pop hWinMain
    call _init
  .elseif eax==WM_COMMAND     ;�˵�
    mov eax,wParam
    .if eax==IDM_EXIT       ;�˳�
      invoke EndDialog,hWnd,NULL 
    .elseif eax==IDM_OPEN   ;��PE�ԱȶԻ���
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



