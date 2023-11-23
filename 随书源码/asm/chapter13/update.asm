;------------------------
; 补丁升级程序
; 戚利
; 2010.11.28
;------------------------
    .386
    .model flat,stdcall
    option casemap:none

include    windows.inc
include    user32.inc
includelib user32.lib
include    kernel32.inc
includelib kernel32.lib
include    urlmon.inc
includelib urlmon.lib

;数据段
    .data
szINI          db '下载配置文件：http://10.112.132.100/version.ini',0
szIsNewVesion  db '程序已经是最新版本',0
szLINI         db '.\_tmp.ini',0

hProcessID   dd ?  ;主进程释放时会修改此处的三个值  
oldMajor     dw 0  ; 分别是：主程序进程号，主次旧版本的值
oldMinor     dw 0

hProcess     dd ?
newMajor     dw 0
newMinor     dw 0

szOut1     db '%s_%d_%d.exe',0
szOut2     db '下载补丁文件:http://10.112.132.100/soft/%s',0 ;要下载的EXE文件
szFailRead db 256 dup(0)
szSectionName   db  'DPatchPEInfo.exe',0  ;针对不同的程序修改此处的值
szKeyName1    db  'majorImageVersion',0
szKeyName2    db  'minorImageVersion',0
szKeyName3    db  'downloadfile',0


stStartUp	STARTUPINFO		<?>
stProcInfo	PROCESS_INFORMATION	<?> 

szExeFile     db  256 dup(0)
szBuffer      db  256 dup(0)
szDataBuffer  db  256 dup(0)
;代码段
    .code


start:
    invoke MessageBox,NULL,offset szINI,NULL,MB_OK
    ;下载ini文件
    invoke URLDownloadToFile,0, \
                      addr szINI,
                      addr szLINI,0,0
    ;打开分析ini文件
    invoke GetPrivateProfileInt,addr szSectionName,\
                                addr szKeyName1,\
                                0,\
                                addr szLINI
    mov newMajor,ax
    invoke GetPrivateProfileInt,addr szSectionName,\
                                addr szKeyName2,\
                                0,\
                                addr szLINI
    mov newMinor,ax

    ;判断是否是新版本PE

    mov ax,newMajor
    mov bx,newMinor

    .if ax==oldMajor && bx==oldMinor

      ;显示已经是最新版本 
      invoke MessageBox,NULL,offset szIsNewVesion,NULL,MB_OK

    .else
       ;是新版本，则下载该PE，并实施替换

       ;取文件名DPatchPEInfo.exe_1_0.exe

       invoke RtlZeroMemory,addr szDataBuffer,256
       invoke GetPrivateProfileString,addr szSectionName,\
                                   addr szKeyName3,\
                                   NULL,\
                                   addr szDataBuffer,\
                                   sizeof szDataBuffer,\
                                   addr szLINI  ;取文件名

       invoke wsprintf,addr szBuffer,addr szOut2,\
                                   addr szDataBuffer

       invoke MessageBox,NULL,addr szBuffer,NULL,MB_OK

       ;下载exe文件
       invoke URLDownloadToFile,0, \
                      addr szBuffer,
                      addr szDataBuffer,0,0


       ;结束当前主进程
       invoke OpenProcess,PROCESS_ALL_ACCESS,\
                     FALSE,hProcessID
       mov hProcess,eax
       invoke Sleep,1000

       invoke TerminateProcess,hProcess,0
       invoke CloseHandle,hProcess

       invoke Sleep,1000
       ;将下载的文件替换为PE文件
       invoke DeleteFile,addr szSectionName
       invoke CopyFile,addr szDataBuffer,addr szSectionName,\
                                                  TRUE
       invoke Sleep,1000
       ;重启PE程序
       invoke GetStartupInfo,addr stStartUp
       invoke CreateProcess,NULL,addr szSectionName,NULL,NULL,\
                      NULL,NORMAL_PRIORITY_CLASS,NULL,NULL,\
                      offset stStartUp,offset stProcInfo 
    .endif

    invoke ExitProcess,NULL
    end start
