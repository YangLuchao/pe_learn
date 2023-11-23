;------------------------
; 测试异常处理
; 戚利
; 2011.1.19
;------------------------
    .386
    .model flat,stdcall
    option casemap:none;大小写不敏感

include    windows.inc
include    user32.inc
includelib user32.lib
include    kernel32.inc
includelib kernel32.lib

;数据段
    .data
szText     db  'HelloWorldPE',0;正常提示
szErr      db  'SEH Error',0;错误提示
;代码段
    .code
;异常处理过程
;_lpException:引发异常的代码信息指针
;_lpSEH：SEH指针
;_lpContext：当前线程的上下文信息指针
;_lpDispatcherContext：调度器上下文指针，通常用于高级的异常处理逻辑
_handler proc _lpException,_lpSEH,\
             _lpContext,_lpDispatcherContext
  nop
  pushad
  mov esi,_lpException;引发异常代码信息指针
  mov edi,_lpContext;当前线程上下文指针
   
  assume edi:ptr CONTEXT;假设为CONTEXT类型

  invoke MessageBox,NULL,addr szErr,NULL,MB_OK;弹出messagebox框

  mov [edi].regEip,offset _safePlace;拿到安全点标号，设置为当前线程上下文IP寄存器的值
  assume edi:nothing

  popad  

  ;测试一
  ;发生的异常已被该函数接管
  mov eax,ExceptionContinueExecution;返回指定枚举，告诉系统当前异常已被接管

  ;测试二
  ;发生的异常未被该函数接管
  ;mov eax,ExceptionContinueSearch;返回指定枚举，告诉系统当前异常未被接管，需要继续处理
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
    mov dword ptr [eax],eax;触发异常

_safePlace:
    
    pop fs:[0]
    pop eax

    invoke MessageBox,NULL,addr szText,NULL,MB_OK
    invoke ExitProcess,NULL
    end start