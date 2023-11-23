;------------------------
; 静态TLS演示
; 戚利
; 2010.2.28
;------------------------
    .386
    .model flat,stdcall
    option casemap:none

include    windows.inc
include    user32.inc
includelib user32.lib
include    kernel32.inc
includelib kernel32.lib

    .data

szText  db 'HelloWorldPE',0,0,0,0  

; -----------------------构造IMAGE_TLS_DIRECTORY
TLS_DIR     dd offset Tls1
            dd offset Tls2
            dd offset Tls3
            dd offset TlsCallBack
            dd 0
            dd 0
; -----------------------构造IMAGE_TLS_DIRECTORY
Tls1        dd 0
Tls2        dd 0
Tls3        dd 0
TlsCallBack dd  offset TLS
            dd     0
            dd     0

    .data?

TLSCalled db ?   ;重进标志

    .code

start:
 
    invoke ExitProcess,NULL
    RET

    ; 以下代码将会在.code之前执行一次
TLS:

    ; 变量TLSCalled是一个防重进标志。正常情况下该部分代码
    ; 会被执行两次，但使用了该标识后，该代码只在开始运行前
    ; 执行一次
    
    cmp byte ptr [TLSCalled],1
    je @exit
    mov byte ptr [TLSCalled],1
    invoke MessageBox,NULL,addr szText,NULL,MB_OK

@exit:

    RET

    end start  