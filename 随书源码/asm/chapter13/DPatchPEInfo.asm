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
IDB_UPDATE equ 5000
UPDATE     equ 6000

STOP_FLAG_POSITION=00404115h
MAJOR_IMAGE_VERSION=1
MINOR_IMAGE_VERSION=0

_QLSuspend typedef proto :dword      ;声明函数
_QLResume  typedef proto :dword      ;声明函数

_ApiSuspend  typedef ptr _QLSuspend  ;声明函数引用
_ApiResume  typedef ptr _QLResume  ;声明函数引用

.data
hInstance   dd ?
hProcess    dd 0
hProcessID  dd 0
phwnd       dd ?
hRichEdit   dd ?
hWinMain    dd ?
hWinEdit    dd ?
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

hNtdll      dd   ?
_suspendProcess _ApiSuspend ?
_resumeProcess  _ApiResume ?

stStartUp	STARTUPINFO		<?>
stProcInfo	PROCESS_INFORMATION	<?> 
hRes        dd ?
hFile       dd ?
dwResSize   dd ?
lpRes       dd ?

.const
szErr1       db 'Error happend when openning.',0
szErr2       db 'Error happend when reading.',0
szErr3       db 'Error happend when getting address.',0

szDllEdit   db 'RichEd20.dll',0
szClassEdit db 'RichEdit20A',0
szFont      db '宋体',0
szTitle     db 'PEInfo by qixiaorui',0

szNtdll     db 'ntdll.dll',0
;`ZwResumeProcess` 和 `ZwSuspendProcess` 是 Windows 操作系统内部的一组函数，通常不是公开的 Win32 API 函数。它们用于控制和管理进程的暂停和继续执行。这些函数通常在操作系统内核模式的代码中使用，而不是普通的应用程序中。
;- `ZwSuspendProcess` 函数的作用是将指定的进程挂起（暂停）其执行。这将导致目标进程的所有线程都被挂起，暂停其运行。这个函数通常用于调试器等工具，以便在调试过程中停止目标进程的执行以进行调试操作。
;- `ZwResumeProcess` 函数的作用是恢复一个先前被挂起的进程的执行。当一个进程被挂起后，可以使用这个函数来继续执行该进程的线程，使其再次运行。
;这两个函数通常用于系统级编程，例如内核模式驱动程序、调试器或操作系统自身的组件。一般的用户应用程序无法直接调用这些函数。用户级应用程序通常使用 `SuspendThread` 和 `ResumeThread` 这样的 Win32 API 函数来挂起和恢复线程的执行，而不是直接操作整个进程。这些 API 函数提供了更高级别的线程控制，适用于一般用户应用程序的需求。
szSuspend   db 'ZwSuspendProcess',0
szResume    db 'ZwResumeProcess',0

szSrcName   db 'update.exe',0


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

;--------------------
; 写内存示例
; 测试方法：首先运行PEInfo.exe
;           显示Kernel32.dll的信息
; 启动该程序,在kernel32.dll显示重定位时单击菜单第一项
; 会发现PEInfo.exe的遍历重定位信息被终止
;--------------------
_writeToPEInfo  proc
  pushad

  ;通过标题获得进程的handle
  ;查询桌面窗口的句柄
  invoke GetDesktopWindow
  invoke GetWindow,eax,GW_CHILD
  invoke GetWindow,eax,GW_HWNDFIRST
  mov phwnd,eax
  invoke GetParent,eax
  .if !eax
    mov parent,1
  .endif

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

  mov eax,phwnd  
  invoke wsprintf,addr szBuffer,addr szOut1,eax
  invoke MessageBox,NULL,addr szBuffer,NULL,MB_OK

  ;根据窗口句柄获取进程ID
  invoke GetWindowThreadProcessId,phwnd,addr hProcessID

  mov eax,hProcessID
  invoke wsprintf,addr szBuffer,addr szOut2,eax
  invoke MessageBox,NULL,addr szBuffer,NULL,MB_OK

  invoke OpenProcess,PROCESS_ALL_ACCESS,\
                     FALSE,hProcessID
  .if !eax
    invoke MessageBox,NULL,addr szErr1,NULL,MB_OK
    jmp @ret
  .endif
  mov hProcess,eax  ;找到的进程句柄在hProcess中


  invoke wsprintf,addr szBuffer,addr szOut3,eax
  invoke MessageBox,NULL,addr szBuffer,NULL,MB_OK


  ;将进程挂起
  invoke _suspendProcess,hProcess

  ;读内存
  ;ReadProcessMemory 将指定地址范围中的数据从指定进程的地址空间复制到当前进程的指定缓冲区中
  invoke ReadProcessMemory,hProcess,STOP_FLAG_POSITION,\
                       addr dwFlag,4,NULL
  .if eax
    mov eax,dwFlag  
    invoke wsprintf,addr szBuffer,addr szOut,eax
    invoke MessageBox,NULL,addr szBuffer,NULL,MB_OK

    ;写内存，将标志位赋值
    ;WriteProcessMemory 将数据写入到指定进程中的内存区域。 要写入的整个区域必须可访问
    invoke WriteProcessMemory,hProcess,\
                       STOP_FLAG_POSITION,\
                       addr dwPatchDD,4,NULL
  .else
    invoke MessageBox,NULL,addr szErr2,NULL,MB_OK
    jmp @ret
  .endif

  ;继续进程的运行
  invoke _resumeProcess,hProcess
  invoke CloseHandle,hProcess

@ret:
  popad
  ret
_writeToPEInfo  endp

;--------------------------
; 释放资源
; _hInstance:进程句柄
;--------------------------
_createDll proc _hInstance
  local @dwWritten

  pushad

  ;寻找资源
  ;_hInstance 进程ID
  ;资源名称
  ;资源类型
  invoke FindResource,_hInstance,IDB_UPDATE,UPDATE
  .if eax
    mov hRes,eax;找到了，资源句柄放到全局变量中
    invoke SizeofResource,_hInstance,eax ;获取资源尺寸
    mov dwResSize,eax;资源大小放入到全局变量中
    invoke LoadResource,_hInstance,hRes ;装入资源
    .if eax;装载成功
         invoke LockResource,eax ;锁定资源
         .if eax;锁定成功
             mov lpRes,eax  ;将资源内存地址给lpRes

             ;打开文件写入
             invoke CreateFile,addr szSrcName,GENERIC_WRITE,\
                                            FILE_SHARE_READ,\
                          0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
             mov hFile,eax
             invoke WriteFile,hFile,lpRes,dwResSize,\;输出文件，文件落地
                                        addr @dwWritten,NULL
             invoke CloseHandle,hFile ;关闭文件句柄     
         .endif
    .endif
  .endif
  popad
  ret
_createDll endp
;-------------------
; 窗口程序
;-------------------
_ProcDlgMain proc uses ebx edi esi hWnd,wMsg,wParam,lParam
  local @value

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
      invoke _writeToPEInfo
    .elseif eax==IDM_1      ;升级
      ;写入三个变量
      ;根据窗口句柄获取进程ID,id存入到@value中
      invoke GetWindowThreadProcessId,hWnd,addr @value
      mov eax,@value

      mov ebx,0040528eh
      mov dword ptr [ebx],eax
    
      mov ax,MAJOR_IMAGE_VERSION
      mov word ptr [ebx+4],ax;设置主版本号
      mov ax,MINOR_IMAGE_VERSION
      mov word ptr [ebx+6],ax;设置次版本号

      ;释放update.exe程序
      ;将update.exe释放出来
      invoke _createDll,hInstance

      ;GetStartupInfo查询创建该进程的时候上下文，结果存到stStartUp中
      invoke GetStartupInfo,addr stStartUp
      ;运行update.exe程序
      invoke CreateProcess,NULL,addr szSrcName,NULL,NULL,\
                      NULL,NORMAL_PRIORITY_CLASS,NULL,NULL,\
                      offset stStartUp,offset stProcInfo 

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
  invoke LoadLibrary,offset szDllEdit;加载文本控件
  mov hRichEdit,eax;句柄放到全局变量中

  invoke LoadLibrary,offset szNtdll;加载NTdll.dll
  mov hNtdll,eax;句柄放到ntdll中
  invoke GetProcAddress,hNtdll,addr szSuspend;获取ZwSuspendProcess函数地址
  mov _suspendProcess,eax;将ZwSuspendProcess函数的地址放入到全局变量中

  .if !eax
    invoke MessageBox,NULL,addr szErr3,NULL,MB_OK;查询失败，弹出对话框
  .endif

  invoke GetProcAddress,hNtdll,addr szResume;获取ZwResumeProcess函数的地址
  mov _resumeProcess,eax;将地址放入到全局变量中

  .if !eax
    invoke MessageBox,NULL,addr szErr3,NULL,MB_OK;没有找到，弹出对话框
  .endif

  ;GetModuleHandle:检索指定模块的模块句柄。 模块必须已由调用进程加载
  ;参数为NULL，返回当前进程的句柄
  invoke GetModuleHandle,NULL;
  mov hInstance,eax;将句柄放入到全局变量中
  invoke DialogBoxParam,hInstance,\
         DLG_MAIN,NULL,offset _ProcDlgMain,NULL;打开对话框
  invoke FreeLibrary,hRichEdit
  invoke ExitProcess,NULL
  end start
