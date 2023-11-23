;------------------------
; 测试异常处理
; 戚利
; 2011.1.19
;------------------------
    .386
    .model flat,stdcall
    option casemap:none

include    windows.inc
include    user32.inc
includelib user32.lib
include    kernel32.inc
includelib kernel32.lib

;数据段
    .data
szText     db  'HelloWorldPE',0
szErr      db  'SEH Error',0
;代码段
    .code
;定义异常处理函数
_handler proc _lpException,_lpSEH,\
             _lpContext,_lpDispatcherContext
  nop
  pushad
  mov esi,_lpException
  mov edi,_lpContext
   
  assume edi:ptr CONTEXT

  invoke MessageBox,NULL,addr szErr,NULL,MB_OK

  mov [edi].regEip,offset _safePlace
  assume edi:nothing

  popad  

  ;测试一
  ;发生的异常已被该函数接管
  ;mov eax,ExceptionContinueExecution

  ;测试二
  ;发生的异常未被该函数接管
  mov eax,ExceptionContinueSearch
  ret
_handler endp

start:
    ;构建 try catch
    assume fs:nothing
    push offset _handler
    push fs:[0]
    mov fs:[0],esp
    ;构建 try catch

    xor eax,eax
    mov dword ptr [eax],eax

_safePlace:

    pop fs:[0]
    pop eax

    invoke MessageBox,NULL,addr szText,NULL,MB_OK
    invoke ExitProcess,NULL
    end start