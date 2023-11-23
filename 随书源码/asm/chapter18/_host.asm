;------------------------------------
; 调度程序
;-------------------------------------

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



TOTAL_FILE_COUNT  equ   100        ;本程序所绑定文件的最大数
BinderFileStruct  STRUCT
  inExeSequence   byte   ?         ;为0表示非执行文件，为1表示加入执行序列
  dwFileOff       dword   ?        ;在宿主中的起始偏移
  dwFileSize      dword    ?       ;文件大小
  name1           db   256 dup(0)  ;文件名，含子目录
BinderFileStruct  ENDS


.data
hRunThread  dd ?
dwFileSizeHigh dd ?
dwFileSizeLow dd ?
dwFileCount dd ?
dwFolderCount dd ?
dwFileSize    dd ?
dwFileOff     dd ?

szFilter   db '*.*',0
szXie      db '\',0
szPath     db 'c:\ql',256 dup(0)
szBuffer   db 1024 dup(0)
szHost     db 'host.exe',0    ;宿主程序
szHost_    db '_host.exe',0   ;释放出来的文件

szTemp     db 'a\b\c\abc.exe',0

stStartUp	STARTUPINFO		<?>
stProcInfo	PROCESS_INFORMATION	<?> 

;以下为捆绑列表数据结构，一个文件总数的双字和多个BinderFileStruct结构
dwFlag          dd  0ffffffffh,0ffffffffh,0ffffffffh,0ffffffffh
dwTotalFile     dd  TOTAL_FILE_COUNT    ;文件总数
lpFileList      BinderFileStruct TOTAL_FILE_COUNT dup(<?>)
szBuffer1       db  256 dup(0)

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

;---------------------
; 处理找到的文件
;---------------------
_ProcessFile proc _lpszFile
  local @hFile

  invoke lstrlen,addr szPath
  mov esi,eax
  add esi,_lpszFile
  mov al,byte ptr [esi]
  .if al==5ch
    inc esi
  .endif
  inc dwFileCount
  invoke CreateFile,_lpszFile,GENERIC_READ,FILE_SHARE_READ,0,\
   OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
  .if eax != INVALID_HANDLE_VALUE
   mov @hFile,eax
   invoke GetFileSize,eax,NULL

   add dwFileSizeLow,eax
   adc dwFileSizeHigh,0
   invoke CloseHandle,@hFile
  .endif
  ret

_ProcessFile endp

;----------------------------
; 遍历指定目录szPath下
;  (含子目录)的所有文件
;------------------------------
_FindFile proc _lpszPath
  local @stFindFile:WIN32_FIND_DATA
  local @hFindFile
  local @szPath[MAX_PATH]:byte     ;用来存放“路径\”
  local @szSearch[MAX_PATH]:byte   ;用来存放“路径\*.*”
  local @szFindFile[MAX_PATH]:byte ;用来存放“路径\文件”

  pushad
  invoke lstrcpy,addr @szPath,_lpszPath
  ;在路径后面加上\*.*
@@:
  invoke lstrlen,addr @szPath
  lea esi,@szPath
  add esi,eax
  xor eax,eax
  mov al,'\'
  .if byte ptr [esi-1] != al
   mov word ptr [esi],ax
  .endif
  invoke lstrcpy,addr @szSearch,addr @szPath
  invoke lstrcat,addr @szSearch,addr szFilter
  ;寻找文件
  invoke FindFirstFile,addr @szSearch,addr @stFindFile
  .if eax != INVALID_HANDLE_VALUE
   mov @hFindFile,eax
   .repeat
    invoke lstrcpy,addr @szFindFile,addr @szPath
    invoke lstrcat,addr @szFindFile,addr @stFindFile.cFileName
    .if @stFindFile.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY
     .if @stFindFile.cFileName != '.'
      inc dwFolderCount
      invoke _FindFile,addr @szFindFile
     .endif
    .else
     invoke _ProcessFile,addr @szFindFile
    .endif
    invoke FindNextFile,@hFindFile,addr @stFindFile
   .until eax==FALSE
   invoke FindClose,@hFindFile
  .endif
  popad
  ret
_FindFile endp
;------------------------------------------
; 执行程序用的线程
; 1. 用 CreateProcess 建立进程
; 2. 用 WaitForSingleOject 等待进程结束
;-------------------------------------------
_RunThread	proc	uses ebx ecx edx esi edi,\
		dwParam:DWORD
   pushad
   mov ecx,dwTotalFile;文件总数
   mov esi,offset lpFileList;指向捆绑文件列表起始位置
   .repeat
      assume esi:ptr BinderFileStruct;假设为捆绑文件结构
      mov al,byte ptr [esi];是否为可执行文件
      push esi
      .if al==1    ;文件在执行序列
        push esi
        invoke GetStartupInfo,addr stStartUp;获取进程窗口信息
        pop esi
        invoke CreateProcess,NULL,addr [esi].name1,NULL,NULL,\;创建进程
              NULL,NORMAL_PRIORITY_CLASS,NULL,NULL,offset stStartUp,offset stProcInfo
        .if eax!=0;创建成功
          invoke WaitForSingleObject,stProcInfo.hProcess,INFINITE;等待执行完成
          invoke CloseHandle,stProcInfo.hProcess
          invoke CloseHandle,stProcInfo.hThread
        .endif
      .endif
      invoke Sleep,1000
      pop esi
      add esi,sizeof BinderFileStruct;处理下一个文件
      dec dwTotalFile
      .break .if dwTotalFile==0
   .until FALSE
   popad
   ret
_RunThread	endp

start:
  ;获取当前目录
  invoke GetCurrentDirectory,256,addr szPath  
  invoke  CreateThread,NULL,NULL,offset _RunThread,\;开启新线程，执行_RunThread函数
                  NULL,NULL,offset hRunThread
  end start