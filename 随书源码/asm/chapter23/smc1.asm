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
dwEncrptSize  dd  ? 


     .code

;----------------------
; 加密解密使用同一个函数
;----------------------
_encrptIt proc  _lpSrc,_size
  pushad
  mov esi,_lpSrc
  mov edi,_lpSrc
  mov ecx,_size
loc1:
  mov al,byte ptr [esi]
  xor al,74h  ;算法很简单，异或
  mov byte ptr [edi],al

  inc esi
  inc edi
  dec ecx
  .if ecx!=0
    jmp loc1
  .endif
 
  popad
  ret
_encrptIt endp

start:

  mov eax,offset _encrptEnd
  sub eax,offset _encrptStart
  mov dwEncrptSize,eax

  lea eax,_encrptStart
  invoke _encrptIt,eax,dwEncrptSize

_encrptStart:
  db 1eh,74h,1eh,74h,1ch,74h,44h,34h
  db 74h,1eh,74h,9ch,73h,74h,74h,74h
_encrptEnd:

  invoke ExitProcess,NULL 

              end start 
