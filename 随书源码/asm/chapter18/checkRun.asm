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
stStartUp	STARTUPINFO		<?>
stProcInfo	PROCESS_INFORMATION	<?> 

;以下为捆绑列表数据结构，一个文件总数的双字和多个BinderFileStruct结构
dwFlag          dd  0ffffffffh,0ffffffffh,0ffffffffh,0ffffffffh
dwTotalFile     dd  TOTAL_FILE_COUNT    ;文件总数
lpFileList      BinderFileStruct TOTAL_FILE_COUNT dup(<?>)

.const
szExeFile   db 'notepad.exe',0
szExeFile1  db 'mspaint.exe',0
szExeFile2  db 'config.ini',0



.code

;------------------------------------------
; 执行程序用的线程
; 1. 用 CreateProcess 建立进程
; 2. 用 WaitForSingleOject 等待进程结束
;-------------------------------------------
_RunThread	proc	uses ebx ecx edx esi edi,\
		dwParam:DWORD
   pushad
   mov ecx,dwTotalFile
   mov esi,offset lpFileList
   .repeat
      assume esi:ptr BinderFileStruct
      mov al,byte ptr [esi]
      push esi
      .if al==1
        push esi
        invoke GetStartupInfo,addr stStartUp
        pop esi
        lea eax,[esi].name1
        nop
        invoke CreateProcess,NULL,eax,NULL,NULL,\
              NULL,NORMAL_PRIORITY_CLASS,NULL,NULL,offset stStartUp,offset stProcInfo
        .if eax!=0
          invoke WaitForSingleObject,stProcInfo.hProcess,INFINITE
          invoke CloseHandle,stProcInfo.hProcess
          invoke CloseHandle,stProcInfo.hThread
        .endif
      .endif
      pop esi
      add esi,sizeof BinderFileStruct
      dec dwTotalFile
      .break .if dwTotalFile==0
   .until FALSE
   popad
   ret
_RunThread	endp

start:

  useless_start  equ this byte

  ;初始化捆绑列表，模拟捆绑行为，为捆绑列表赋值
  mov eax,3    ;执行两个文件，一个为配置文件
  mov dwTotalFile,eax
  mov esi,offset lpFileList   ;初始化捆绑列表，主要是为名字赋值
  assume esi:ptr BinderFileStruct
  mov byte ptr [esi].inExeSequence,1
  pushad
  invoke lstrlen,addr szExeFile
  invoke MemCopy,addr szExeFile,addr [esi].name1,eax
  popad

  add esi,sizeof BinderFileStruct   ;第二个文件
  assume esi:ptr BinderFileStruct
  mov byte ptr [esi].inExeSequence,1

  pushad
  invoke lstrlen,addr szExeFile1
  invoke MemCopy,addr szExeFile1,addr [esi].name1,eax
  popad

  add esi,sizeof BinderFileStruct   ;第三个文件，为配置文件
  assume esi:ptr BinderFileStruct
  mov byte ptr [esi].inExeSequence,1

  pushad
  invoke lstrlen,addr szExeFile2
  invoke MemCopy,addr szExeFile2,addr [esi].name1,eax
  popad
  unuseless_end equ this byte  
  invoke  CreateThread,NULL,NULL,offset _RunThread,\
                  NULL,NULL,offset hRunThread
  end start