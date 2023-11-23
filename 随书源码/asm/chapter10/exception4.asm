;------------------------
; 测试异常处理
; 指定了一个safe SEH Handler
; 并测试该异常处理函数，运行后会显示两个提示信息
; 一个是异常处理函数的提示信息，
; 另外一个是异常被处理后主程序的提示信息
; 戚利
; 2011.2.15
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
szText1     db  'safeHandler!',0
szText2     db  'nosafeHandler!',0
szText      db  'HelloWorldPE',0

;代码段
    .code

;IMAGE_LOAD_CONFIG_STRUCT STRUCT
    Characteristics dd                  00000048h
    TimeDateStamp dd                    0
    MajorVersion dw                     0
    MinorVersion dw                     0
    GlobalFlagsClear dd                 0
    GlobalFlagsSet dd                   0
    CriticalSectionDefaultTimeout dd    0
    DeCommitFreeBlockThreshold dd       0
    DeCommitTotalFreeThreshold dd       0
    LockPrefixTable dd                  0
    MaximumAllocationSize dd            0
    VirtualMemoryThreshold dd           0
    ProcessHeapFlags dd                 0
    ProcessAffinityMask dd              0
    CSDVersion dw                       0
    Reserved1 dw                        0
    EditList dd                         0
    SecurityCookie dd                  00000000h
    SEHandlerTable dd                  offset safeHandler ;(VA地址)
    SEHandlerCount  dd                 00000001h
;IMAGE_LOAD_CONFIG_STRUCT ENDS

;构造RVA
safeHandler      dd    offset _handler1-00400000h
                 dd    0


;-------------------------------------------
; 已注册的异常回调函数
;-------------------------------------------
_handler1 proc _lpException,_lpSEH,\
             _lpContext,_lpDispatcherContext
  nop
  pushad
  mov esi,_lpException
  mov edi,_lpContext
   
  assume edi:ptr CONTEXT

  invoke MessageBox,NULL,addr szText1,NULL,MB_OK

  mov [edi].regEip,offset _safePlace
  assume edi:nothing

  popad  

  mov eax,ExceptionContinueExecution
  ret
_handler1 endp

;-------------------------------------------
; 未注册的异常回调函数
;-------------------------------------------
_handler2 proc _lpException,_lpSEH,\
             _lpContext,_lpDispatcherContext
  nop
  pushad
  mov esi,_lpException
  mov edi,_lpContext
   
  assume edi:ptr CONTEXT

  invoke MessageBox,NULL,addr szText2,NULL,MB_OK

  mov [edi].regEip,offset _safePlace
  assume edi:nothing

  popad  
  mov eax,ExceptionContinueExecution
  ret
_handler2 endp

start:
    assume fs:nothing
    push offset _handler1
    push fs:[0]
    mov fs:[0],esp

    xor eax,eax  ;引发越界异常
    mov dword ptr [eax],eax

_safePlace:

    pop fs:[0]
    pop eax

    invoke MessageBox,NULL,addr szText,NULL,MB_OK
    invoke ExitProcess,NULL
    end start