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

;声明函数
_QLGetProcAddress typedef proto :dword,:dword   
;声明函数引用   
_ApiGetProcAddress  typedef ptr _QLGetProcAddress  

_QLLoadLib        typedef proto :dword
_ApiLoadLib       typedef ptr _QLLoadLib

_QLMessageBoxA    typedef proto :dword,:dword,:dword,:dword
_ApiMessageBoxA   typedef ptr _QLMessageBoxA


.data
hInstance   dd ?
hProcess    dd 0
hProcessID  dd 0
phwnd       dd ?
hRichEdit   dd ?
hWinMain    dd ?
hWinEdit    dd ?
lpRemote    dd ?
szFileName  db MAX_PATH dup(?)
strTitle    db  256 dup(0)
parent      dd 0
szBuffer    db  256 dup(0)
dwPatchDD   dd 1
dwFlag      dd 0
szOut1      db '窗口ID=%d',0
szOut2      db '进程号=%d',0
szOut3      db '进程ID=%d',0
szOut       db '从进程PEInfo.exe中取出的标志位的值为：%08x',0

.const
szErr1       db 'Error happend when openning.',0
szErr2       db 'Error happend when reading.',0
szErr3       db 'Error happend when getting address.',0

szDllEdit   db 'RichEd20.dll',0
szClassEdit db 'RichEdit20A',0
szFont      db '宋体',0
szTitle     db 'PEInfo by qixiaorui',0

.code

REMOTE_THREAD_START equ this byte
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

_remoteThread  proc uses ebx edi esi lParam ;远程线程执行开始地址
    
    call @F   ; 免去重定位
@@:
    pop ebx
    sub ebx,offset @B

    ;获取kernel32.dll的基地址
    invoke _getKernelBase
    mov [ebx+offset hKernel32Base],eax

    ;从基地址出发搜索GetProcAddress函数的首址
    mov eax,offset szGetProcAddr
    add eax,ebx

    mov edi,offset hKernel32Base
    mov ecx,[ebx+edi]


    invoke _getApi,ecx,eax
    mov [ebx+offset lpGetProcAddr],eax

    ;为函数引用赋值 GetProcAddress
    mov [ebx+offset _getProcAddress],eax   

    ;使用GetProcAddress函数的首址
    ;传入两个参数调用GetProcAddress函数，获得LoadLibraryA的首址
    mov eax,offset szLoadLib
    add eax,ebx
   
    mov edi,offset hKernel32Base
    mov ecx,[ebx+edi]
    
    mov edx,offset _getProcAddress
    add edx,ebx
    
    ;模仿调用 invoke GetProcAddress,hKernel32Base,addr szLoadLib
    push eax
    push ecx
    call dword ptr [edx]   

    mov [ebx+offset _loadLibrary],eax

    ;使用LoadLibrary获取user32.dll的基地址

    mov eax,offset user32_DLL
    add eax,ebx

    mov edi,offset _loadLibrary
    mov edx,[ebx+edi]
    
    push eax
    call edx   ; invoke LoadLibraryA,addr _loadLibrary

    mov [ebx+offset hUser32Base],eax

    ;使用GetProcAddress函数的首址，获得函数MessageBoxA的首址
    mov eax,offset szMessageBox
    add eax,ebx
   
    mov edi,offset hUser32Base
    mov ecx,[ebx+edi]
    
    mov edx,offset _getProcAddress
    add edx,ebx


    ;模仿调用 invoke GetProcAddress,hUser32Base,addr szMessageBox
    push eax
    push ecx
    call dword ptr [edx]   
    mov [ebx+offset _messageBox],eax

    ;调用函数MessageBoxA
    mov eax,offset szText
    add eax,ebx

    mov edx,offset _messageBox
    add edx,ebx

    ;模仿调用 invoke MessageBoxA,NULL,addr szText,NULL,MB_OK    
    push MB_OK
    push NULL
    push eax
    push NULL
    call dword ptr [edx]   
    ret
_remoteThread endp

;------------------------------------------------
; 远程线程用到的数据
;------------------------------------------------
szText         db  'HelloWorldPE',0
szGetProcAddr  db  'GetProcAddress',0
szLoadLib      db  'LoadLibraryA',0
szMessageBox   db  'MessageBoxA',0

user32_DLL     db  'user32.dll',0,0

;定义函数
_getProcAddress _ApiGetProcAddress  ?             
_loadLibrary    _ApiLoadLib         ?
_messageBox     _ApiMessageBoxA     ?


hKernel32Base   dd  ?
hUser32Base     dd  ?
lpGetProcAddr   dd  ?
lpLoadLib       dd  ?

REMOTE_THREAD_END equ this byte
REMOTE_THREAD_SIZE=offset REMOTE_THREAD_END-offset REMOTE_THREAD_START;写入代码需要的空间大小

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

;--------------------
; 将远程线程打到进程PEInfo.exe中
; 测试方法：首先运行PEInfo.exe
; 启动该程序,单击第一个菜单的第一项
; 会发现桌面上弹出HelloWorldPE对话框
;--------------------
_patchPEInfo  proc
  local @dwTemp

  pushad

  ;通过标题获得进程的handle
  invoke GetDesktopWindow
  invoke GetWindow,eax,GW_CHILD
  invoke GetWindow,eax,GW_HWNDFIRST
  mov phwnd,eax
  invoke GetParent,eax
  .if !eax
    mov parent,1
  .endif

  ;---------------------------筛选目标窗口
  mov eax,phwnd
  .while eax
     .if parent
         mov parent,0   ;复位标志
         ;得到窗口标题文字
         invoke GetWindowText,phwnd,addr strTitle,\
                               sizeof strTitle
         nop
         invoke lstrcmp,addr strTitle,addr szTitle
         .if  !eax
           mov eax,phwnd
           .break
         .endif
     .endif

     ;寻找这个窗口的下一个兄弟窗口
     invoke GetWindow,phwnd,GW_HWNDNEXT 
     mov phwnd,eax
     invoke GetParent,eax
     .if !eax
       invoke IsWindowVisible,phwnd
       .if eax
          mov parent,1
       .endif
     .endif
     mov eax,phwnd
  .endw
  ;---------------------------筛选目标窗口

  ;mov eax,phwnd  
  ;invoke wsprintf,addr szBuffer,addr szOut1,eax
  ;invoke MessageBox,NULL,addr szBuffer,NULL,MB_OK

  ;根据窗口句柄获取进程ID
  invoke GetWindowThreadProcessId,phwnd,addr hProcessID

  ;mov eax,hProcessID
  ;invoke wsprintf,addr szBuffer,addr szOut2,eax
  ;invoke MessageBox,NULL,addr szBuffer,NULL,MB_OK
  ;打开进程
  ;PROCESS_ALL_ACCESS:权限相关
  invoke OpenProcess,PROCESS_ALL_ACCESS,\
                     FALSE,hProcessID
  .if !eax
    invoke MessageBox,NULL,addr szErr1,NULL,MB_OK
    jmp @ret
  .endif
  mov hProcess,eax  ;找到的进程句柄在hProcess中


  ;invoke wsprintf,addr szBuffer,addr szOut3,eax
  ;invoke MessageBox,NULL,addr szBuffer,NULL,MB_OK

  ;分配空间
  ;REMOTE_THREAD_SIZE，所需空间大小
  ;MEM_COMMIT:提交内存
  ;PAGE_EXECUTE_READWRITE：可读可写可执行权限
  invoke VirtualAllocEx,hProcess,NULL,\
               REMOTE_THREAD_SIZE,MEM_COMMIT,\
               PAGE_EXECUTE_READWRITE
  .if eax
      mov lpRemote,eax
      ;写入线程代码
      ;REMOTE_THREAD_START：存放代码的缓冲区
      ;REMOTE_THREAD_SIZE：线程大小
      ;@dwTemp：返回参数，写入字节数大小
      invoke WriteProcessMemory,hProcess,\
                       lpRemote,\
                       offset REMOTE_THREAD_START,\
                       REMOTE_THREAD_SIZE,\
                       addr @dwTemp
      mov eax,lpRemote
      ;eax：线程开始执行的地址
      add eax,offset _remoteThread-offset REMOTE_THREAD_START
      invoke CreateRemoteThread,hProcess,NULL,0,eax,0,0,NULL;创建进程并运行线程
  .endif

  invoke CloseHandle,hProcess

@ret:
  popad
  ret
_patchPEInfo  endp


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
  .elseif eax==WM_COMMAND  ;菜单
    mov eax,wParam
    .if eax==IDM_EXIT       ;退出
      invoke EndDialog,hWnd,NULL 
    .elseif eax==IDM_OPEN   ;停止
      invoke _patchPEInfo
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
  invoke LoadLibrary,offset szDllEdit
  mov hRichEdit,eax;加载文本框控件

  invoke LoadLibrary,offset szNtdll
  mov hNtdll,eax;加载ntdll.dll
  invoke GetProcAddress,hNtdll,addr szSuspend
  mov _suspendProcess,eax;挂起线程函数地址

  .if !eax;弹出异常
    invoke MessageBox,NULL,addr szErr3,NULL,MB_OK
  .endif

  invoke GetProcAddress,hNtdll,addr szResume
  mov _resumeProcess,eax;恢复线程函数地址

  .if !eax
    invoke MessageBox,NULL,addr szErr3,NULL,MB_OK
  .endif


  invoke GetModuleHandle,NULL
  mov hInstance,eax
  invoke DialogBoxParam,hInstance,\
         DLG_MAIN,NULL,offset _ProcDlgMain,NULL;打开对话框
  invoke FreeLibrary,hRichEdit;卸载控件dll
  invoke ExitProcess,NULL
  end start
