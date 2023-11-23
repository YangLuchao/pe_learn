;------------------------------------
; 输出当前目录的所有文件名（含子目录）
;-------------------------------------

.386
.model flat,stdcall
option casemap:none

include    windows.inc
include    user32.inc
include    kernel32.inc
include    shell32.inc
include    winResult.inc
include    comdlg32.inc

includelib user32.lib
includelib kernel32.lib
includelib shell32.lib
includelib winResult.lib
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

.data
szPath     db    'c:\ql',256 dup(0)
szBuffer   db    1024 dup(0)
szExeFileName   db  'c:\ql\txt\123456.txt',0

hInstance   dd ?
hRichEdit   dd ?
hWinMain    dd ?
hWinEdit    dd ?
dwOption    db ?
dwFileSizeHigh dd ?
dwFileSizeLow dd ?
dwFileCount dd ?
dwFolderCount dd ?

F_SEARCHING equ 0001h
F_STOP  equ 0002h

szFileName  db MAX_PATH dup(?)

szOut1      db '文件名称为：%s',0dh,0ah,0
szOut2      db '文件大小等于 %d 字节',0dh,0ah,0
szOut3      db '目录下所有文件的总大小为%08x%08x。',0dh,0ah,0
szOut4      db '要搜索的目录：%s',0dh,0ah,0dh,0ah,0
szStart  db '开始(&S)',0
szStop  db '停止(&S)',0
szFilter db '*.*',0
szSearchInfo db '共找到 %d 个文件夹，%d 个文件，共 %luK 字节',0

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
szCrLf      db 0dh,0ah,0


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

;---------------------------
; 判断文件是否为EXE文件，根据后缀
;---------------------------
_isExeFile  proc  _lpFileName
  local @szFile[20]:byte
  local @ret

  pushad
  lea edi,@szFile
  mov al,'.'
  stosb
  mov al,'e'
  stosb
  mov al,'x'
  stosb
  mov al,'e'
  stosb
  mov al,0
  stosb

  invoke lstrlen,_lpFileName
  sub eax,4
  mov esi,_lpFileName
  add esi,eax

  lea edi,@szFile
  invoke lstrcmp,esi,edi
  .if !eax  ;相等
     mov @ret,1    
  .else
     mov @ret,0
  .endif   
  popad
  mov eax,@ret
  ret
_isExeFile  endp

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
  invoke wsprintf,addr szBuffer,addr szOut1,esi
  invoke _appendInfo,addr szBuffer
  inc dwFileCount
  invoke CreateFile,_lpszFile,GENERIC_READ,FILE_SHARE_READ,0,\
   OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
  .if eax != INVALID_HANDLE_VALUE
   mov @hFile,eax
   invoke GetFileSize,eax,NULL
   pushad
   invoke wsprintf,addr szBuffer,addr szOut2,eax
   invoke _appendInfo,addr szBuffer
   invoke _appendInfo,addr szCrLf
   popad

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
      invoke wsprintf,addr szBuffer,addr szOut4,addr szPath
      invoke _appendInfo,addr szBuffer
      invoke _FindFile,addr szPath
      invoke _appendInfo,addr szCrLf
      invoke wsprintf,addr szBuffer,addr szOut3,dwFileSizeHigh,dwFileSizeLow
      invoke _appendInfo,addr szBuffer
    .elseif eax==IDM_1  ;以下三个菜单是7岁的儿子完成的！！
      invoke MessageBox,NULL,offset szErrFormat,offset szErr,MB_ICONWARNING
    .elseif eax==IDM_2
      invoke MessageBox,NULL,offset szErrFormat,offset szErr,MB_ICONQUESTION	
    .elseif eax==IDM_3
      nop
      invoke _isExeFile,addr szExeFileName
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



