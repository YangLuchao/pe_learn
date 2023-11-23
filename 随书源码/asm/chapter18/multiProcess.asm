;------------------------------------
; 测试执行多个进程的文件
; multiProcess.asm
;-------------------------------------

.386
.model flat,stdcall
option casemap:none

include    windows.inc
include    user32.inc
include    kernel32.inc
include    winResult.inc
includelib user32.lib
includelib kernel32.lib
includelib winResult.lib



TOTAL_FILE_COUNT  equ   100        ;本程序所绑定文件的最大数
BinderFileStruct  STRUCT
  inExeSequence   byte   ?         ;为0表示非执行文件，为1表示加入执行序列
  dwFileOff       dword   ?        ;在宿主中的起始偏移
  dwFileSize      dword    ?       ;文件大小
  name            db   256 dup(0)  ;文件名，含子目录
BinderFileStruct  ENDS


.data
hRunThread  dd ?
stStartUp	STARTUPINFO		<?>
stProcInfo	PROCESS_INFORMATION	<?> 

dwTotalFile     dd  TOTAL_FILE_COUNT    ;文件总数
bindFileList    BinderFileStruct TOTAL_FILE_COUNT dup(<?>)

.const
szExeFile   db 'd:\masm32\source\chapter15\notepad.exe',0
szExeFile1  db 'd:\masm32\source\chapter15\mspaint.exe',0


.code

;------------------------------------------
; 执行程序用的线程
; 1. 用 CreateProcess 建立进程
; 2. 用 WaitForSingleOject 等待进程结束
;-------------------------------------------
_RunThread	proc	uses ebx ecx edx esi edi,\
		dwParam:DWORD
   pushad
   invoke GetStartupInfo,addr stStartUp;获取当前进程信息
   invoke CreateProcess,NULL,addr szExeFile,NULL,NULL,\;创建进程
            NULL,NORMAL_PRIORITY_CLASS,NULL,NULL,offset stStartUp,offset stProcInfo
   .if eax!=0;
     invoke WaitForSingleObject,stProcInfo.hProcess,INFINITE;等待进程结束，INFINITE：一直等待
     invoke CloseHandle,stProcInfo.hProcess;关闭进程
     invoke CloseHandle,stProcInfo.hThread;关闭线程
   .endif
   invoke GetStartupInfo,addr stStartUp;;获取当前进程信息
   invoke CreateProcess,NULL,addr szExeFile1,NULL,NULL,\;创建进程
            NULL,NORMAL_PRIORITY_CLASS,NULL,NULL,offset stStartUp,offset stProcInfo
   .if eax!=0
     invoke WaitForSingleObject,stProcInfo.hProcess,INFINITE;等待进程结束，INFINITE：一直等待
     invoke CloseHandle,stProcInfo.hProcess;关闭进程
     invoke CloseHandle,stProcInfo.hThread;关闭线程
   .endif
   popad
   ret
_RunThread	endp

start:
  invoke  CreateThread,NULL,NULL,offset _RunThread,\;创建线程，执行_RunThread函数
                  NULL,NULL,offset hRunThread
  end start