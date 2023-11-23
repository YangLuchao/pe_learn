;------------------------
; PE文件头中的定位
; 戚利
; 2006.2.28
;------------------------
    .386
    .model flat,stdcall
    option casemap:none

include    windows.inc
include    user32.inc
includelib user32.lib

include    kernel32.inc
includelib kernel32.lib

include    imagehlp.inc
includelib imagehlp.lib

;数据段
    .data
szText     db  'HelloWorld',0
szOut      db  '地址为:%08x',0
szBuffer   db  256 dup(0)

szExeFile  db  'c:\windows\system32\kernel32.dll',0
szOut1     db  'kernel32.dll的校验和为：%08x',0
dwCheckSum dd ?


;代码段
    .code
;---------------------
; 将内存偏移量RVA转换为文件偏移
; lp_FileHead为文件头的起始地址
; _dwRVA为给定的RVA地址
; eax返回值，包含FOA地址
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
  movzx ecx,[esi].FileHeader.NumberOfSections;movzx高位补0
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
      jmp @F;跳到下一个@@处
    .endif
    add edx,sizeof IMAGE_SECTION_HEADER;没有找到寄存器指向下一个节表项
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

;-------------------
; 通过调用API函数计算校验和
; kernel32.dll的校验和为：0011e97e
;-------------------
_checkSum1 proc _lpExeFile 
   local @cSum,@hSum
   local @ret

   pushad
   invoke MapFileAndCheckSum,_lpExeFile,\
                 addr @hSum,addr @cSum
   mov eax,@cSum
   mov @ret,eax 

   popad  
   mov eax,@ret
   ret
_checkSum1 endp

;-------------------
; 自己编写程序计算校验和
;-------------------
_checkSum2 proc _lpExeFile
   local hFile,dwSize,hBase
   local @size
   local @ret

   pushad
   ;打开文件
   invoke CreateFile,_lpExeFile,GENERIC_READ,\
                  FILE_SHARE_READ,NULL,OPEN_EXISTING,\
                  FILE_ATTRIBUTE_NORMAL,0
   mov hFile,eax
   invoke GetFileSize,hFile,NULL
   mov dwSize,eax
   ;为文件分配内存，并读入
   invoke VirtualAlloc,NULL,dwSize,\
                  MEM_COMMIT,PAGE_READWRITE
   mov hBase,eax
   invoke ReadFile,hFile,hBase,dwSize,addr @size,NULL
   ;关闭文件
   invoke CloseHandle,hFile

   ;第一步，将CheckSum清零   
   mov ebx,hBase
   assume ebx:ptr IMAGE_DOS_HEADER
   mov ebx,[ebx].e_lfanew
   add ebx,hBase
   assume ebx:ptr IMAGE_NT_HEADERS
   mov [ebx].OptionalHeader.CheckSum,0
   assume ebx:ptr nothing

   
   mov ecx,dwSize
   mov esi,hBase
   
   ;第二步，按字进位加，溢出忽略
   push ecx
   inc ecx
   shr ecx,1
   xor ebx,ebx
   clc
loc1:
   lodsw
   adc bx,ax
   loop loc1
   
   invoke VirtualFree,hBase,dwSize,MEM_DECOMMIT
 
   ;第三步，加文件长度   
   pop eax
   add eax,ebx   
   mov @ret,eax
@exit:
   popad  
   mov eax,@ret
   ret
_checkSum2 endp


start:
    ;PEHeader.exe导入表数据所在VA
    invoke _rDDEntry,00400000h,01h,0,0 
    invoke wsprintf,addr szBuffer,addr szOut,eax
    invoke MessageBox,NULL,offset szBuffer,NULL,MB_OK

    ;PEHeader.exe导入表数据在文件地址FOA
    invoke _rDDEntry,00400000h,01h,0,3 
    invoke wsprintf,addr szBuffer,addr szOut,eax
    invoke MessageBox,NULL,offset szBuffer,NULL,MB_OK

    ;PEHeader.exe第2个节表项在内存的VA地址
    invoke _rSection,00400000h,01h,0,0 
    invoke wsprintf,addr szBuffer,addr szOut,eax
    invoke MessageBox,NULL,offset szBuffer,NULL,MB_OK

    ;PEHeader.exe第2个节表项在文件的偏移
    invoke _rSection,00400000h,01h,0,3 
    invoke wsprintf,addr szBuffer,addr szOut,eax
    invoke MessageBox,NULL,offset szBuffer,NULL,MB_OK

    ;计算校验和
    invoke _checkSum1,addr szExeFile
    mov dwCheckSum,eax
    invoke _checkSum2,addr szExeFile
    .if eax==dwCheckSum
      invoke wsprintf,addr szBuffer,addr szOut1,eax
      invoke MessageBox,NULL,offset szBuffer,NULL,MB_OK
    .endif


    invoke ExitProcess,NULL
    end start
