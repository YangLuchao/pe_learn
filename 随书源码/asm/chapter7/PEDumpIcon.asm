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

;文件中的ICO头部
ICON_DIR_ENTRY STRUCT  
    bWidth     db   ?   ; 宽度
    bHeight     db   ?   ; 高度
    bColorCount  db  ?   ; 颜色数
    bReserved    db  ?   ; 保留字，必须为0
    wPlanes      dw  ?  ; 调色板
    wBitCount    dw  ?  ;每个像素的位数
    dwBytesInRes  dd  ?  ;资源长度
    dwImageOffset  dd  ?  ;资源在文件偏移
ICON_DIR_ENTRY ENDS

;PE中ICO头部
PE_ICON_DIR_ENTRY STRUCT
    bWidth     db   ?   ; 宽度
    bHeight     db   ?   ; 高度
    bColorCount  db  ?   ; 颜色数
    bReserved    db  ?   ; 保留字，必须为0
    wPlanes      dw  ?  ; 调色板
    wBitCount    dw  ?  ;每个像素的位数
    dwBytesInRes  dd  ?  ;资源长度
    dwImageOffset  dw  ?  ;资源在文件偏移
PE_ICON_DIR_ENTRY ENDS

.data
hInstance   dd ?
hRichEdit   dd ?
hWinMain    dd ?
hWinEdit    dd ?
hFile       dd ? ;文件句柄
szFileName  db MAX_PATH dup(?)
szFileName1 db MAX_PATH dup(?)
szBuffer    db  200 dup(0)
dwICO       dd ?   ;ICO文件的个数
lpMemory    dd ?   ;指向文件的指针
dwIcoDataSize dd ?  ;图标数据的大小


lpPEIconDE    PE_ICON_DIR_ENTRY  <?>
lpIconDE      ICON_DIR_ENTRY     <?>

lpszOffsetArray  dd  500 dup(0)  ;图标数据的偏移地址
                                 ;从第二个图标地址开始

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

szOut1         db '-----------------------------------------------------------------',0dh,0ah
               db '待处理的PE文件：%s',0dh,0ah,0

szFile         db '  >>新建文件%s',0dh,0ah,0
szLevel3       db '图标组%4d所在文件位置：0x%08x  资源长度：%d',0dh,0ah,0
szLevel31      db '  >> 图标%4d所在文件位置：0x%08x  资源长度：%d',0dh,0ah,0
szFinished     db '  >> 完成写入。',0dh,0ah,0dh,0ah,0
szICOHeader    db '  >> 完成ICO头部信息',0dh,0ah,0

szNoResource   db '未发现资源表!',0
szNoIconArray  db '资源表中没有发现图标组！',0
szOut10        db '资源表中有图标组%d个。',0dh,0ah
               db '----------------------------------------------------------------',0dh,0ah,0dh,0ah,0 
szOut11        db 'g%d.ico',0
szOut12        db '%d',0
szOut13        db '  >>图标组%4d中共有图标：%d个。',0dh,0ah,0


     
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

;-------------------------------
;将图标数据写入文件
;
;参数：_lpFile 文件内存起始地址
;参数: _lpRes 资源表起始地址
;参数：_nubmer为图标顺号
;-------------------------------
_getFinnalData proc _lpFile,_lpRes,_number
  local @ret,@dwTemp
  local @szBuffer[1024]:byte
  local @szResName[256]:byte
  local @dwTemp1,@dwTemp2,@dwTemp3
  local @lpMem
  
  pushad
  mov @ret,0

  mov dwICO,0
  
  mov esi,_lpRes     ;指向第一级目录表

  ;计算目录项的个数
  assume esi:ptr IMAGE_RESOURCE_DIRECTORY
  mov cx,[esi].NumberOfNamedEntries
  add cx,[esi].NumberOfIdEntries
  movzx ecx,cx
 
  ;跳过目录头定位到目录项
  add esi,sizeof IMAGE_RESOURCE_DIRECTORY
  assume esi:ptr IMAGE_RESOURCE_DIRECTORY_ENTRY
  .while ecx>0

    ;查看IMAGE_RESOURCE_DIRECTORY_ENTRY.OffsetToData
    mov ebx,[esi].OffsetToData
    .if ebx & 80000000h ;如果最高位为1
        and ebx,7fffffffh     ;二级子目录
        add ebx,_lpRes
        mov eax,[esi].Name1 
        ;如果是按名称定义的资源类型，跳过 
        .if eax & 80000000h   
            jmp _next         
        .else        ;如果是按编号定义的资源类型

           ;第一层，eax指向了资源类别
           .if eax==03h  ;判断编号是否为图标

             ;移动到第二级目录
             ;计算目录项的个数
             mov esi,ebx
             assume esi:ptr IMAGE_RESOURCE_DIRECTORY
             mov cx,[esi].NumberOfNamedEntries
             add cx,[esi].NumberOfIdEntries
             movzx ecx,cx
             mov dwICO,ecx

             mov ecx,dwICO

             ;跳过第二级目录头定位到第二级目录项
             add esi,sizeof IMAGE_RESOURCE_DIRECTORY
             assume esi:ptr IMAGE_RESOURCE_DIRECTORY_ENTRY

             mov @dwTemp1,0
             .while ecx>0
               push ecx
               push esi
               
               ;直接访问到数据，获取数据在文件的偏移及大小
               add @dwTemp1,1

               ;判断序号是否和指定的一致
               mov eax,_number
               .if @dwTemp1!=eax
                 jmp _loop
               .endif

               ;如果一致，则继续查找数据
   
               mov ebx,[esi].OffsetToData
               .if ebx & 80000000h ;最高位为1
                  and ebx,7fffffffh
                  add ebx,_lpRes   ;第三级

                  ;移动到第三级目录，假设目录项数量都为1
                  mov esi,ebx
                  assume esi:ptr IMAGE_RESOURCE_DIRECTORY
                  add esi,sizeof IMAGE_RESOURCE_DIRECTORY
                  assume esi:ptr IMAGE_RESOURCE_DIRECTORY_ENTRY  

                  ;地址指向数据项
                  mov ebx,[esi].OffsetToData
                  add ebx,_lpRes
                    
                  assume ebx:ptr IMAGE_RESOURCE_DATA_ENTRY
                  mov eax,[ebx].OffsetToData
                  mov edx,[ebx].Size1
                  mov @dwTemp3,edx
                  invoke _RVAToOffset,_lpFile,eax
                  mov @dwTemp2,eax

                  invoke wsprintf,addr szBuffer,addr szLevel31,\
                              @dwTemp1,@dwTemp2,@dwTemp3
                  invoke _appendInfo,addr szBuffer 

                  mov eax,_lpFile
                  add eax,@dwTemp2
                  mov @lpMem,eax
                    
                  ;将@dwTemp2开始的@dwTemp3个字节写入文件
                  invoke WriteFile,hFile,@lpMem,\
                          @dwTemp3,addr @dwTemp,NULL
                  invoke _appendInfo,addr szFinished 

                  pop esi
                  pop ecx
                  mov @ret,1
                  jmp _ret 
               .endif

_loop:         pop esi
               pop ecx
               add esi,sizeof IMAGE_RESOURCE_DIRECTORY_ENTRY
               dec ecx
             .endw
             jmp _next        
           .else
             jmp _next
           .endif
           
        .endif
    .endif
_next:
    add esi,sizeof IMAGE_RESOURCE_DIRECTORY_ENTRY
    dec ecx
  .endw

  .if dwICO==0
    invoke _appendInfo,addr szNoIconArray
  .endif
_ret:
  assume esi:nothing
  assume ebx:nothing
  popad
  mov eax,@ret
  ret
_getFinnalData endp

;-------------------------------
;通过PE ICO头获取ICO数据
;
;参数1：文件开始
;参数2：资源表开始
;参数3：PE ICO头开始
;参数4：编号（由此构造磁盘文件名g12.ico）
;参数5：PE ICO头大小
;-------------------------------
_getIcoData proc _lpFile,_lpRes,_number,_off,_size
  local @dwTemp,@dwCount,@dwTemp1
  local @lpMem,@dwForward 

  pushad
  invoke wsprintf,addr szFileName1,addr szOut11,_number
  invoke wsprintf,addr szBuffer,addr szFile,\
                                 addr szFileName1
  invoke _appendInfo,addr szBuffer
  ;将内存写入文件以供检查
  invoke CreateFile,addr szFileName1,GENERIC_WRITE,\
             FILE_SHARE_READ,\
             0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
  mov hFile,eax
  

  ;定位文件指针
  mov eax,_lpFile
  add eax,_off
  mov lpMemory,eax
  mov @lpMem,eax

  ;写入6个字节文件头
  invoke WriteFile,hFile,lpMemory,6,addr @dwTemp,NULL

  ;求出图标组包含图标的个数  
  mov esi,dword ptr [lpMemory]
  add esi,4
  xor ecx,ecx
  mov cx,word ptr [esi]
  mov @dwCount,ecx
  invoke wsprintf,addr szBuffer,addr szOut13,\
                                    _number,@dwCount
  invoke _appendInfo,addr szBuffer

  ;求第一个图标数据在文件中的偏移
  xor edx,edx
  mov eax,@dwCount
  mov cx,2   ;每一个记录多2个字节
  mul cx
  add eax,_size
  mov @dwForward,eax  ;上一个

  ;定位到ICO图标项起始
  mov esi,dword ptr [lpMemory]
  add esi,6
  assume esi:ptr PE_ICON_DIR_ENTRY
  mov dwIcoDataSize,0

  mov eax,@dwCount
  mov @dwTemp1,eax
  .while @dwTemp1>0
     push esi

     ;将PE中的大部分赋值，除最后一个字段外
     mov al,[esi].bWidth
     mov lpIconDE.bWidth,al

     mov al,[esi].bHeight
     mov lpIconDE.bHeight,al

     mov al,[esi].bColorCount
     mov lpIconDE.bColorCount,al

     mov al,[esi].bReserved
     mov lpIconDE.bReserved,al

     mov ax,[esi].wPlanes
     mov lpIconDE.wPlanes,ax

     mov ax,[esi].wBitCount
     mov lpIconDE.wBitCount,ax

     mov eax,[esi].dwBytesInRes
     mov lpIconDE.dwBytesInRes,eax
     

     ;该值需要修正，记录图标数据在文件偏移。
     ;第一个图标的该值是文件ICO头大小
     
     ;以后的图标的该值是上一个加上数据长度
     mov eax,dwIcoDataSize
     add @dwForward,eax
     mov eax,@dwForward
     mov lpIconDE.dwImageOffset,eax

    
     invoke WriteFile,hFile,addr lpIconDE,\
              sizeof ICON_DIR_ENTRY,addr @dwTemp,NULL

     mov eax,[esi].dwBytesInRes ;为下一次计算地址做准备
     mov dwIcoDataSize,eax
     pop esi
     add esi,sizeof PE_ICON_DIR_ENTRY    
     dec @dwTemp1
  .endw ;该循环结束，所有的头部信息已经完毕。

  invoke _appendInfo,addr szICOHeader

  ;开始下一个循环，将所有图标数据写入文件
  mov esi,dword ptr [lpMemory]
  add esi,6
  assume esi:ptr PE_ICON_DIR_ENTRY

  mov eax,@dwCount
  mov @dwTemp1,eax
  .while @dwTemp1>0
     push esi

     xor eax,eax
     mov ax,[esi].dwImageOffset  ;取得图标的顺号

     ;写入文件图标数据
     ;返回eax为图标数据大小
     invoke _getFinnalData,_lpFile,_lpRes,eax

     pop esi
     add esi,sizeof PE_ICON_DIR_ENTRY    
     dec @dwTemp1
  .endw ;该循环结束，所有的头部信息已经完毕，只等修正偏移地址
  
  invoke CloseHandle,hFile

  popad

  ret
_getIcoData endp


;-------------------------
;遍历资源表项的图标组资源  
;_lpFile：文件地址
;_lpRes：资源表地址
;-------------------------
_processRes  proc _lpFile,_lpRes
  local @szBuffer[1024]:byte
  local @szResName[256]:byte
  local @dwTemp1,@dwTemp2,@dwTemp3
  

  pushad

  mov dwICO,0
  
  mov esi,_lpRes     ;指向目录表

  ;计算目录项的个数
  assume esi:ptr IMAGE_RESOURCE_DIRECTORY
  mov cx,[esi].NumberOfNamedEntries
  add cx,[esi].NumberOfIdEntries
  movzx ecx,cx
 
  ;跳过目录头定位到目录项
  add esi,sizeof IMAGE_RESOURCE_DIRECTORY
  assume esi:ptr IMAGE_RESOURCE_DIRECTORY_ENTRY
  .while ecx>0

    ;查看IMAGE_RESOURCE_DIRECTORY_ENTRY.OffsetToData
    mov ebx,[esi].OffsetToData
    .if ebx & 80000000h ;如果最高位为1
        and ebx,7fffffffh     ;二级子目录
        add ebx,_lpRes
        mov eax,[esi].Name1 
        ;如果是按名称定义的资源类型，跳过 
        .if eax & 80000000h   
            jmp _next         
        .else        ;如果是按编号定义的资源类型

           ;第一层，eax指向了资源类别
           .if eax==0eh  ;判断编号是否为图标组

             ;移动到第二级目录
             ;计算目录项的个数
             mov esi,ebx
             assume esi:ptr IMAGE_RESOURCE_DIRECTORY
             mov cx,[esi].NumberOfNamedEntries
             add cx,[esi].NumberOfIdEntries
             movzx ecx,cx
             mov dwICO,ecx

             invoke wsprintf,addr szBuffer,addr szOut10,\
                                             dwICO
             invoke _appendInfo,addr szBuffer   
             mov ecx,dwICO

             ;跳过第二级目录头定位到第二级目录项
             add esi,sizeof IMAGE_RESOURCE_DIRECTORY
             assume esi:ptr IMAGE_RESOURCE_DIRECTORY_ENTRY
             mov @dwTemp1,0
             .while ecx>0
               push ecx
               push esi
               
               ;直接访问到数据，获取数据在文件的偏移及大小
               add @dwTemp1,1
               mov ebx,[esi].OffsetToData
               .if ebx & 80000000h ;最高位为1
                  and ebx,7fffffffh
                  add ebx,_lpRes   ;第三级

                  ;移动到第三级目录，假设目录项数量都为1
                  mov esi,ebx
                  assume esi:ptr IMAGE_RESOURCE_DIRECTORY
                  add esi,sizeof IMAGE_RESOURCE_DIRECTORY
                  assume esi:ptr IMAGE_RESOURCE_DIRECTORY_ENTRY  

                  ;地址指向数据项
                  mov ebx,[esi].OffsetToData
                  add ebx,_lpRes
                    
                  assume ebx:ptr IMAGE_RESOURCE_DATA_ENTRY
                  mov eax,[ebx].OffsetToData
                  mov edx,[ebx].Size1
                  mov @dwTemp3,edx
                  invoke _RVAToOffset,_lpFile,eax
                  mov @dwTemp2,eax
                  invoke wsprintf,addr szBuffer,addr szLevel3,\
                              @dwTemp1,@dwTemp2,@dwTemp3
                  invoke _appendInfo,addr szBuffer 
  
                  ;处理单个ICO文件
                  ;参数1：文件开始
                  ;参数2：资源表开始
                  ;参数3：PE ICO头开始
                  ;参数4：编号
                  ;参数5：PE ICO头大小
                  invoke _getIcoData,_lpFile,_lpRes,\
                                   @dwTemp1,@dwTemp2,@dwTemp3
                              
               .endif

               pop esi
               pop ecx
               add esi,sizeof IMAGE_RESOURCE_DIRECTORY_ENTRY
               dec ecx
             .endw
             jmp _next        
           .else
             jmp _next
           .endif
           
        .endif
    .endif
_next:
    add esi,sizeof IMAGE_RESOURCE_DIRECTORY_ENTRY
    dec ecx
  .endw

  .if dwICO==0
    invoke _appendInfo,addr szNoIconArray
  .endif
  assume esi:nothing
  assume ebx:nothing
  popad
  ret
_processRes endp


;--------------------
; 获取PE文件的资源信息
;--------------------
_getResource proc  _lpFile,_lpPeHead,_dwSize
  local @szBuffer[1024]:byte
  pushad
  ;通过PE头定位资源表所在RVA
  mov esi,_lpPeHead
  assume esi:ptr IMAGE_NT_HEADERS
  mov eax,[esi].OptionalHeader.DataDirectory[8*2].VirtualAddress
  .if !eax
     invoke _appendInfo,addr szNoResource
     jmp _ret
  .endif
  push eax
  ;求资源表在文件的偏移
  invoke _RVAToOffset,_lpFile,eax
  add eax,_lpFile
  mov esi,eax
  pop eax

  ;传入的两个参数分别表示
  ;1、文件头位置
  ;2、资源表位置
  invoke _processRes,_lpFile,esi
_ret:
  assume esi:nothing
  popad
  ret
_getResource endp

;--------------------
; 打开PE文件并处理
;--------------------
_openFile proc
  local @stOF:OPENFILENAME
  local @hFile,@dwFileSize,@hMapFile,@lpMemory

  invoke SendMessage,hWinEdit,WM_SETTEXT,NULL,0
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

          ;到此为止，该文件的验证已经完成。为PE结构文件

          invoke wsprintf,addr szBuffer,addr szOut1,\
                          addr szFileName
          invoke _appendInfo,addr szBuffer

          ;显示资源表信息
          invoke _getResource,@lpMemory,esi,@dwFileSize

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



