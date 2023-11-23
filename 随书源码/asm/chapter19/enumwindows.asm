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


ICO_MAIN equ 1000
DLG_MAIN equ 1000
IDC_INFO equ 1001
IDM_MAIN equ 2000
IDM_OPEN equ 2001
IDM_EXIT equ 2002
IDM_1    equ 4000
IDM_2    equ 4001
IDM_3    equ 4002
RESULT_MODULE   equ 5000
ID_TEXT1        equ 5001
ID_TEXT2        equ 5002
IDC_MODULETABLE equ 5003
IDC_OK          equ 5004
ID_STATIC       equ 5005
ID_STATIC1      equ 5006
IDC_BROWSE1     equ 5007
IDC_BROWSE2     equ 5008
IDC_THESAME     equ 5009


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


szNewBuffer      db  2048 dup(?)
szClassNameBuf db   512 dup (?)  ;不要更改大小
szWndTextBuf   db   512 dup (?)  ;不要更改大小
szName         db   '安装 - Photo',0

szBuffer       db   1024 dup(0) 
szOut1         db   '窗口句柄：%08x    窗口类名： %s      ',0
szOut2         db   '窗口标题： %s',0dh,0ah,0
szOut3         db   '指定名称窗口的句柄为： %08x  ',0dh,0ah,0


szMainClassNameBuf  db  512 dup(?)
szMainWndTextBuf    db  512 dup(?)
hParentWin          dd  ?   ;父窗口
hWin                dd  ?   ;当前窗口
hSubWin             dd  ?
@stPos             POINT   <?>


szFileName           db MAX_PATH dup(?)
szDstFile            db 'c:\bindC.exe',0
szFileNameOpen1      db 'd:\masm32\source\chapter13\patch.exe',MAX_PATH dup(0)
szFileNameOpen2      db 'c:\notepad.exe',MAX_PATH dup(0)

                     ;d:\masm32\source\chapter12\HelloWorld.exe

szResultColName1 db  'PE数据结构相关字段',0
szResultColName2 db  '文件1的值(H)',0
szResultColName3 db  '文件2的值(H)',0
bufTemp1         db  200 dup(0),0
bufTemp2         db  200 dup(0),0
szFilter1        db  'Excutable Files',0,'*.exe;*.com',0
                 db  0

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
szNewSection db 'PEBindQL',0

szCrLf      db 0dh,0ah,0



.data?
stLVC         LV_COLUMN <?>
stLVI         LV_ITEM   <?>

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
; 返回0表示相同
;---------------------------
_MemComp  proc
   local @dwResult:dword

   pushad
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
_MemComp  endp

;-------------------------------------------
; 窗口枚举函数
;-------------------------------------------
_EnumProc proc hTopWinWnd:DWORD,value:DWORD
      .if hTopWinWnd!=NULL
        invoke GetClassName,hTopWinWnd,addr szClassNameBuf,\  ;类名
            sizeof szClassNameBuf
        invoke GetWindowText,hTopWinWnd,addr szWndTextBuf,\  ;窗口名
            sizeof szWndTextBuf

        invoke wsprintf,addr szBuffer,addr szOut1,hTopWinWnd,addr szClassNameBuf
        invoke _appendInfo,addr szBuffer

        invoke wsprintf,addr szBuffer,addr szOut2,addr szWndTextBuf
        invoke _appendInfo,addr szBuffer
        invoke _appendInfo,addr szCrLf

        pushad
        mov esi,offset szName
        mov edi,offset szWndTextBuf
        mov ecx,10
        repe cmpsb
        jnz  @2
        mov eax,hTopWinWnd
        mov hWin,eax  
@2:
        popad

        inc dwCount
      .endif
      mov eax,hTopWinWnd ;当窗口句柄为空时结束
      ret 
_EnumProc endp

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



;------------------------------------------
; 打开输入文件
;------------------------------------------
_OpenFile1	proc
                invoke EnumWindows,addr _EnumProc,NULL  ;枚举顶层窗口
                mov eax,hWin
                mov hParentWin,eax
                invoke wsprintf,addr szBuffer,addr szOut3,hWin
                invoke _appendInfo,addr szBuffer     
 

                invoke SetForegroundWindow,hWin
                invoke SetActiveWindow,hWin                
                invoke PostMessage,hWin,WM_KEYDOWN,VK_RETURN,NULL
                invoke Sleep,5000


                mov @stPos.x,500
                mov @stPos.y,400
                invoke WindowFromPoint,@stPos.x,@stPos.y
                mov hWin,eax
                invoke PostMessage,hWin,WM_KEYDOWN,VK_RETURN,NULL
                invoke Sleep,5000

                mov @stPos.x,500
                mov @stPos.y,400
                invoke WindowFromPoint,@stPos.x,@stPos.y
                mov hWin,eax
                invoke PostMessage,hWin,WM_KEYDOWN,VK_RETURN,NULL
                invoke Sleep,5000

                mov @stPos.x,500
                mov @stPos.y,400
                invoke WindowFromPoint,@stPos.x,@stPos.y
                mov hWin,eax
                invoke PostMessage,hWin,WM_KEYDOWN,VK_RETURN,NULL
                invoke Sleep,5000

                mov @stPos.x,500
                mov @stPos.y,400
                invoke WindowFromPoint,@stPos.x,@stPos.y
                mov hWin,eax
                invoke PostMessage,hWin,WM_KEYDOWN,VK_RETURN,NULL
                invoke Sleep,5000

                mov @stPos.x,500
                mov @stPos.y,400
                invoke WindowFromPoint,@stPos.x,@stPos.y
                mov hWin,eax
                invoke PostMessage,hWin,WM_KEYDOWN,VK_RETURN,NULL
                invoke Sleep,5000

                mov @stPos.x,500
                mov @stPos.y,400
                invoke WindowFromPoint,@stPos.x,@stPos.y
                mov hWin,eax
                invoke PostMessage,hWin,WM_KEYDOWN,VK_RETURN,NULL
                invoke Sleep,30000


                mov @stPos.x,500
                mov @stPos.y,400
                invoke WindowFromPoint,@stPos.x,@stPos.y
                mov hWin,eax
                invoke PostMessage,hWin,WM_KEYDOWN,VK_RETURN,NULL
                invoke Sleep,5000


                ;向父窗口发送关闭消息
                mov @stPos.x,500
                mov @stPos.y,400
                invoke WindowFromPoint,@stPos.x,@stPos.y
                mov eax,hParentWin
                mov hWin,eax
                invoke SendMessage,hWin,WM_CLOSE,NULL,NULL 
                invoke Sleep,5000  


                ;invoke GetForegroundWindow
                ;mov hWin,eax       
                ;invoke PostMessage,hWin,WM_KEYDOWN,VK_RETURN,NULL
                ;invoke Sleep,5000

		ret

_OpenFile1	endp
;------------------------------------------
; 打开输入文件
;------------------------------------------
_OpenFile2	proc
		ret

_OpenFile2	endp



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
  
@@:        
  ret
_openFile endp



;-------------------
; 窗口程序
;-------------------
_ProcDlgMain proc uses ebx edi esi hWnd,wMsg,wParam,lParam
  mov eax,wMsg
  .if eax==WM_CLOSE
    invoke FadeOutClose,hWnd
    invoke EndDialog,hWnd,NULL
  .elseif eax==WM_INITDIALOG  ;初始化
    push hWnd
    pop hWinMain
    call _init
    invoke FadeInOpen,hWnd
  .elseif eax==WM_COMMAND     ;菜单
    mov eax,wParam
    .if eax==IDM_EXIT       ;退出
      invoke FadeOutClose,hWnd
      invoke EndDialog,hWnd,NULL 
    .elseif eax==IDM_OPEN   ;打开文件
        invoke _OpenFile1
    .elseif eax==IDM_1  
        invoke _OpenFile2
    .elseif eax==IDM_2
        ;将内存映射文件复制一份，留出间隙一
        invoke _openFile
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
  invoke InitCommonControls
  invoke LoadLibrary,offset szDllEdit
  mov hRichEdit,eax
  invoke GetModuleHandle,NULL
  mov hInstance,eax
  invoke DialogBoxParam,hInstance,\
         DLG_MAIN,NULL,offset _ProcDlgMain,NULL
  invoke FreeLibrary,hRichEdit
  invoke ExitProcess,NULL
  end start



