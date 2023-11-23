;------------------------
; 反调试技术测试
; 戚利
; 2006.2.28
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
szText        db  "HelloWorldPE", 0  
szDebugged    db  "我正在被调试!", 0  
szNoDebugged  db  "没有被调试!", 0  

     .code
start:
  assume fs:nothing
  ;指向 PDB(Process Database)  
  mov eax,fs:[30h]  ;EAX为TEB.ProcessEnvironmentBlock

  mov eax, [eax+68h]
  and eax, 070h     ;NtGlobalFlags
  test eax, eax
  jne @isDebugged

  invoke MessageBox,NULL,addr szNoDebugged,\
                                      NULL,MB_OK
  jmp @ret

@isDebugged:
  invoke MessageBox,NULL,addr szDebugged,\
                                      NULL,MB_OK
@ret:
  invoke ExitProcess,NULL 

              end start 
