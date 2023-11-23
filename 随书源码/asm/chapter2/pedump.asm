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

.data
hInstance   dd ?   ; 进程句柄
hRichEdit   dd ?
hWinMain    dd ?   ; 弹出窗口句柄
hWinEdit    dd ?   ; 富文本框句柄
totalSize   dd ?   ; 文件大小
lpMemory    dd ?   ; 内存映像文件在内存的起始位置
szFileName  db MAX_PATH dup(? ); 要打开的文件路径及名称名

lpServicesBuffer         db 100 dup(0); 所有内容
bufDisplay               db 50 dup(0); 第三列ASCII码字符显示
szBuffer                 db 200 dup(0); 临时缓冲区
lpszFilterFmt4           db  '%08x  ', 0
lpszManyBlanks           db  '  ', 0
lpszBlank                db  ' ', 0
lpszSplit                db  '-', 0
lpszScanFmt              db  '%02x', 0
lpszHexArr               db  '0123456789ABCDEF', 0
lpszReturn               db  0dh, 0ah, 0
lpszDoubleReturn         db  0dh, 0ah, 0dh, 0ah, 0
lpszOut1                 db  '文件大小：%d', 0
dwStop                   dd  0
.const
szDllEdit   db 'RichEd20.dll', 0
szClassEdit db 'RichEdit20A', 0
szFont      db '宋体', 0
szExtPe     db 'PE File', 0, '*.exe;*.dll;*.scr;*.fon;*.drv', 0
db 'All Files(*.*)', 0, '*.*', 0, 0
szErr       db '文件格式错误!', 0
szErrFormat db '操作文件时出现错误!', 0


.code

; ----------------
; 初始化窗口程序
; ----------------
_init proc
local @stCf:CHARFORMAT

invoke GetDlgItem, hWinMain, IDC_INFO
mov hWinEdit, eax
invoke LoadIcon, hInstance, ICO_MAIN
invoke SendMessage, hWinMain, WM_SETICON, ICON_BIG, eax; 为窗口设置图标
invoke SendMessage, hWinEdit, EM_SETTEXTMODE, TM_PLAINTEXT, 0; 设置编辑控件
invoke RtlZeroMemory, addr @stCf, sizeof @stCf
mov @stCf.cbSize, sizeof @stCf
mov @stCf.yHeight, 14 * 1440 / 96
mov @stCf.dwMask, CFM_FACE or CFM_SIZE or CFM_BOLD
invoke lstrcpy, addr @stCf.szFaceName, addr szFont
invoke SendMessage, hWinEdit, EM_SETCHARFORMAT, 0, addr @stCf
invoke SendMessage, hWinEdit, EM_EXLIMITTEXT, 0, -1
ret
_init endp

; ------------------
; 错误Handler，固定格式
; ------------------
_Handler proc _lpExceptionRecord, _lpSEH, \
_lpContext, _lpDispathcerContext

  pushad
  mov esi, _lpExceptionRecord
  mov edi, _lpContext
  assume esi : ptr EXCEPTION_RECORD, edi : ptr CONTEXT
  mov eax, _lpSEH
  push[eax + 0ch]
  pop[edi].regEbp
  push[eax + 8]
  pop[edi].regEip
  push eax
  pop[edi].regEsp
  assume esi : nothing, edi : nothing
  popad
  mov eax, ExceptionContinueExecution
  ret
_Handler endp

; -------------------- -
; 往文本框中追加文本
; -------------------- -
_appendInfo proc _lpsz
local @stCR:CHARRANGE

pushad
invoke GetWindowTextLength, hWinEdit
mov @stCR.cpMin, eax; 将插入点移动到最后
mov @stCR.cpMax, eax
invoke SendMessage, hWinEdit, EM_EXSETSEL, 0, addr @stCR
invoke SendMessage, hWinEdit, EM_REPLACESEL, FALSE, _lpsz
popad
ret
_appendInfo endp


; --------------------
; 打开PE文件并处理
; --------------------
_openFile proc
local @stOF:OPENFILENAME
local @hFile, @hMapFile
local @bufTemp1; 十六进制字节码
local @bufTemp2; 第一列
local @dwCount; 计数，逢16则重新计
local @dwCount1; 地址顺号
local @dwBlanks; 最后一行空格数

invoke RtlZeroMemory, addr @stOF, sizeof @stOF; 清空缓存，为加载文件做准备
  mov @stOF.lStructSize,sizeof @stOF
  push hWinMain
  pop @stOF.hwndOwner   ;设置文件所属空间句柄
  mov @stOF.lpstrFilter,offset szExtPe  ;文件名过滤
  mov @stOF.lpstrFile,offset szFileName ;文件名缓冲区
  mov @stOF.nMaxFile,MAX_PATH
  mov @stOF.Flags,OFN_PATHMUSTEXIST or OFN_FILEMUSTEXIST
  invoke GetOpenFileName,addr @stOF  ;让用户选择打开的文件
  .if !eax
    jmp @F
  .endif
  ; 在内存中创建文件
  invoke CreateFile,addr szFileName,GENERIC_READ,\ 
         FILE_SHARE_READ or FILE_SHARE_WRITE,NULL,\
         OPEN_EXISTING,FILE_ATTRIBUTE_ARCHIVE,NULL 
  .if eax!=INVALID_HANDLE_VALUE
    mov @hFile,eax
    invoke GetFileSize,eax,NULL     ;获取文件大小
    mov totalSize,eax

    .if eax
      invoke CreateFileMapping,@hFile,\  ;内存映射文件
             NULL,PAGE_READONLY,0,0,NULL
      .if eax
        mov @hMapFile,eax
        invoke MapViewOfFile,eax,\
               FILE_MAP_READ,0,0,0
        .if eax
          mov lpMemory,eax              ;获得文件在内存的映象起始位置
          ; ---------------------------从这里开始是异常处理
          assume fs:nothing
          push ebp
          push offset _ErrFormat
          push offset _Handler
          push fs:[0]
          mov fs:[0],esp
          ; ---------------------------从这里结束是异常处理
          ;开始处理文件

          ;缓冲区初始化
          invoke RtlZeroMemory,addr @bufTemp1,10
          invoke RtlZeroMemory,addr @bufTemp2,20
          invoke RtlZeroMemory,addr lpServicesBuffer,100
          invoke RtlZeroMemory,addr bufDisplay,50

          mov @dwCount,1
          mov esi,lpMemory;esi指向文件起始偏移处，一直往后移动
          mov edi,offset bufDisplay, ;edi指向第三列ASCII区域，往后移动，当满16个字符时，回退到0
 
          ; 将第一列写入lpServicesBuffer
          mov @dwCount1,0
          invoke wsprintf,addr @bufTemp2,addr lpszFilterFmt4,@dwCount1
          invoke lstrcat,addr lpServicesBuffer,addr @bufTemp2

          ;求最后一行的空格数（16－长度％16）*3
          xor edx,edx
          mov eax,totalSize
          mov ecx,16
          div ecx
          mov eax,16
          sub eax,edx
          xor edx,edx
          mov ecx,3
          mul ecx
          mov @dwBlanks,eax

          ;invoke wsprintf,addr szBuffer,addr lpszOut1,totalSize
          ;invoke MessageBox,NULL,addr szBuffer,NULL,MB_OK

          .while TRUE ;死循环，执行完成jmp出
             .if totalSize==0  ;最后一行
                ;填充空格
                 .while TRUE
                     .break .if @dwBlanks==0
                     invoke lstrcat,addr lpServicesBuffer,addr lpszBlank
                     dec @dwBlanks
                 .endw
                 ;第二列与第三列中间的空格
                 invoke lstrcat,addr lpServicesBuffer,addr lpszManyBlanks  
                 ;第三列内容
                 invoke lstrcat,addr lpServicesBuffer,addr bufDisplay
                 ;回车换行符号
                 invoke lstrcat,addr lpServicesBuffer,addr lpszReturn
                 .break
             .endif
             ;将al翻译成可以显示的ascii码字符,注意不能破坏al的值
             ;翻译过后的值暂存到ah中
             mov al,byte ptr [esi]
             .if al>20h && al<7eh
                mov ah,al
             .else        ;如果不是ASCII码值，则显示“.”
                mov ah,2Eh
             .endif
             ;写入第三列的值
             ;当前edi指向bufDisplay中，所以将ah中的值写入到bufDisplay中
             mov byte ptr [edi],ah

            ;win2k不支持al字节级别，经常导致程序无故结束，
            ;因此用以下方法替代
            ;invoke wsprintf,addr @bufTemp1,addr lpszFilterFmt3,al
                         
             ;----------组合字节的十六进制字符串到@bufTemp1中，类似于：“7F \0”
             mov bl,al
             xor edx,edx;edx清空
             xor eax,eax;eax清空
             mov al,bl
             mov cx,16
             div cx   ;结果高位在al中，余数在dl中

             push edi
             xor bx,bx
             mov bl,al
             movzx edi,bx
             mov bl,byte ptr lpszHexArr[edi];转16进制
             mov byte ptr @bufTemp1[0],bl

             xor bx,bx
             mov bl,dl
             movzx edi,bx
             mov bl,byte ptr lpszHexArr[edi];转16进制
             mov byte ptr @bufTemp1[1],bl
             mov bl,20h
             mov byte ptr @bufTemp1[2],bl
             mov bl,0
             mov byte ptr @bufTemp1[3],bl
             pop edi
            ;----------组合字节的十六进制字符串到@bufTemp1中，类似于：“7F \0”

             ; 将第二列写入lpServicesBuffer
             invoke lstrcat,addr lpServicesBuffer,addr @bufTemp1

             .if @dwCount==16   ;已到16个字节，
                ;第二列与第三列中间的空格
                invoke lstrcat,addr lpServicesBuffer,addr lpszManyBlanks
                ;显示第三列字符 
                invoke lstrcat,addr lpServicesBuffer,addr bufDisplay        
                ;回车换行
                invoke lstrcat,addr lpServicesBuffer,addr lpszReturn 

                ;写入内容
                invoke _appendInfo,addr lpServicesBuffer
                ;清空缓存区的值，为下一行准备
                invoke RtlZeroMemory,addr lpServicesBuffer,100           

                ;如果手动设置停止，则停止加载文件
                .break .if dwStop==1

                ;显示下一行的地址
                ;地址+1，当前只是为了展示地址所以+1，后面还要减回来
                inc @dwCount1
                invoke wsprintf,addr @bufTemp2,addr lpszFilterFmt4,\
                                                            @dwCount1
                invoke lstrcat,addr lpServicesBuffer,addr @bufTemp2
                dec @dwCount1;地址-1

                mov @dwCount,0
                ;清空第三列空间
                invoke RtlZeroMemory,addr bufDisplay,50
                ;将edi的指针挪到第三列缓冲区开头
                mov edi,offset bufDisplay
                ;为了能和后面的inc edi配合使edi正确定位到bufDisplay处
                dec edi 
             .endif

             dec totalSize
             inc @dwCount;计数标识+1
             inc esi
             inc edi
             inc @dwCount1;地址标识+1
          .endw

          ;添加最后一行
          invoke _appendInfo,addr lpServicesBuffer

          
          ;处理文件结束
          ;跳至正常执行完成的结束位置处
          jmp _ErrorExit
 ;---------------------这里是异常处理
_ErrFormat:
          invoke MessageBox,hWinMain,offset szErrFormat,NULL,MB_OK
           ;---------------------这里是异常处理
_ErrorExit:
；--------------------结束异常处理
          pop fs:[0]
          add esp,0ch
          ；--------------------这里做两个异常处理的收尾动作
          ；卸载内存文件镜像
          invoke UnmapViewOfFile,lpMemory
        .endif
        ；关闭内存中的文件镜像
        invoke CloseHandle,@hMapFile
      .endif
      ；关闭内存中的文件
      invoke CloseHandle,@hFile
    .endif
  .endif
@@:        
  ret
_openFile endp
;-------------------
; 窗口程序
;-------------------
_ProcDlgMain proc uses ebx edi esi hWnd,wMsg,wParam,lParam
  local @sClient

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
    .elseif eax==IDM_OPEN   ;打开文件
      mov dwStop,0
      invoke CreateThread,NULL,0,addr _openFile,addr @sClient,0,NULL
      ;invoke _openFile
    .elseif eax==IDM_1 
      mov dwStop,1 
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
  mov hRichEdit,eax
  invoke GetModuleHandle,NULL
  mov hInstance,eax
  invoke DialogBoxParam,hInstance,\
         DLG_MAIN,NULL,offset _ProcDlgMain,NULL
  invoke FreeLibrary,hRichEdit
  invoke ExitProcess,NULL
  end start
