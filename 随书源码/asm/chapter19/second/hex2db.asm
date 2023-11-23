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
dwNewFileCount dd ?
lpDstMemory    dd ?


dwNewFileSize     dd  ?     ;新文件大小=目标文件大小+补丁代码大小

szFileName           db MAX_PATH dup(?)
szDstFile            db 'c:\1.txt',0
szFileNameOpen1      db 'd:\masm32\source\chapter16\second\MessageFactory.exe',MAX_PATH dup(0)
szFileNameOpen2      db 'c:\notepad.exe',MAX_PATH dup(0)

                     ;d:\masm32\source\chapter12\HelloWorld.exe

szBuffer         db  256 dup(0),0
bufTemp1         db  200 dup(0),0
bufTemp2         db  200 dup(0),0
szFilter1        db  'Excutable Files',0,'*.exe;*.com',0
                 db  0

.const

lpszHexArr  db  '0123456789ABCDEF',0


.code

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



  ;到此为止，内存文件的指针已经获取到了。@lpMemory指向连个文件头


  ;求新文件大小
  mov eax,@dwFileSize
  shl eax,3
  mov dwNewFileSize,eax

  ;申请内存空间
  invoke GlobalAlloc,GHND,dwNewFileSize
  mov @hDstFile,eax
  invoke GlobalLock,@hDstFile
  mov lpDstMemory,eax   ;将指针给@lpDst

  mov dwCount,0
  mov esi,@lpMemory
  mov edi,lpDstMemory

  mov @dwTemp,0

  mov al,20h
  mov ecx,4
  rep stosb
  mov al,'d'
  stosb
  mov al,'b'
  stosb
  mov al,20h
  stosb
  add dwNewFileCount,7

  ;开始处理每一个字节
  .repeat
    xor eax,eax
    mov al,byte ptr [esi]
    inc esi

    ;先看是否为16的整数倍
    .if @dwTemp==16
       push eax
       mov @dwTemp,0
       dec edi
       dec dwNewFileCount
       mov al,0dh
       stosb
       mov al,0ah
       stosb
       mov al,20h
       mov ecx,4
       rep stosb
       mov al,'d'
       stosb
       mov al,'b'
       stosb
       mov al,20h
       stosb
       add dwNewFileCount,9
       pop eax

       ;处理字节
       xor edx,edx
       mov ecx,16
       div ecx
       mov ebx,eax
       ;处理高位

       .if al>9
         mov bl,'0'
         mov byte ptr [edi],bl
         inc edi
         inc dwNewFileCount
         mov al,[eax+lpszHexArr]
         stosb
       .else
         mov al,[eax+lpszHexArr]
         stosb
       .endif
       inc dwNewFileCount

       ;处理低位
       mov ebx,edx
       mov al,[ebx+lpszHexArr]
       stosb
       mov al,'h'
       stosb
       mov al,','
       stosb
       add dwNewFileCount,3
    .else
      ;处理字节
      xor edx,edx
      mov ecx,16
      div ecx
      mov ebx,eax
      ;处理高位

      .if al>9
        mov bl,'0'
        mov byte ptr [edi],bl
        inc edi
        inc dwNewFileCount
        mov al,[eax+lpszHexArr]
        stosb
      .else
        mov al,[eax+lpszHexArr]
        stosb
      .endif
      inc dwNewFileCount

      ;处理低位
      mov ebx,edx
      mov al,[ebx+lpszHexArr]
      stosb
      mov al,'h'
      stosb
      mov al,','
      stosb
      add dwNewFileCount,3
    .endif
    sub @dwFileSize,1
    inc @dwTemp
    .break .if @dwFileSize==0
  .until FALSE


  ;将新文件内容写入到c:\1.txt
  invoke writeToFile,lpDstMemory,dwNewFileCount
 
  jmp _ErrorExit  ;正常退出

_ErrFormat:
          
_ErrorExit:
          pop fs:[0]
          add esp,0ch
          invoke UnmapViewOfFile,@lpMemory
          invoke CloseHandle,@hMapFile
          invoke CloseHandle,@hFile
          jmp @F
_ErrFormat1:
         
_ErrorExit1:
          pop fs:[0]
          add esp,0ch
          invoke UnmapViewOfFile,@lpMemory1
          invoke CloseHandle,@hMapFile1
          invoke CloseHandle,@hFile1
@@:        
  ret
_openFile endp

start:

  invoke _openFile
  invoke ExitProcess,NULL
  end start



