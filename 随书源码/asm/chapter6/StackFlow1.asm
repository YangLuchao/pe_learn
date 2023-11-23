;------------------------
; 堆栈溢出程序测试
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

;数据段
    .data
szText       db 'HelloWorldPE',0
szText2      db 'OverFlow me!',0
szShellCode  dd 0ffffffffh,0ddddddddh,0040103ah,0

;代码段
    .code

;---------------------------
; 未检查长度的字符串拷贝函数
;---------------------------
_memCopy proc _lpSrc
    local @buf[4]:byte
    pushad
    mov al,1
    mov esi,_lpSrc
    lea edi,@buf
    .while al!=0
      mov al,byte ptr [esi]
      mov byte ptr [edi],al

      inc esi
      inc edi
    .endw
    popad
    ret
_memCopy endp


start:
    invoke _memCopy,addr szShellCode

    invoke MessageBox,NULL,offset szText,NULL,MB_OK
    invoke MessageBox,NULL,offset szText2,NULL,MB_OK

    invoke ExitProcess,NULL
    end start
