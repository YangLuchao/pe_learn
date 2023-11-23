.386
.model flat,stdcall
option casemap:none

include    windows.inc
include    user32.inc
include    kernel32.inc
include    winResult.inc

includelib user32.lib
includelib kernel32.lib
includelib winResult.lib

.code

;------------------------------------------
; 向窗口发送消息
;------------------------------------------
_doIt	proc

                invoke Sleep,10000   ;先休眠10秒钟

                invoke keybd_event,VK_C,0,0,0
                invoke Sleep,1000

                invoke keybd_event,VK_SHIFT,0,0,0  ;按下shift键
                invoke keybd_event,0BAh,0,0,0      ;冒号
                invoke keybd_event,VK_SHIFT,0,\
                                       KEYEVENTF_KEYUP,0  ;弹起
                invoke Sleep,1000


                invoke keybd_event,220,0,0,0   ;斜线
                invoke Sleep,1000

                invoke keybd_event,VK_W,0,0,0
                invoke Sleep,1000

                invoke keybd_event,VK_I,0,0,0
                invoke Sleep,1000

                invoke keybd_event,VK_N,0,0,0
                invoke Sleep,1000

                invoke keybd_event,VK_R,0,0,0
                invoke Sleep,1000

                invoke keybd_event,VK_A,0,0,0
                invoke Sleep,1000

                invoke keybd_event,VK_R,0,0,0
                invoke Sleep,1000

                invoke keybd_event,VK_TAB,0,0,0
                invoke Sleep,1000

                invoke keybd_event,VK_RETURN,0,0,0
                invoke Sleep,5000


                invoke keybd_event,VK_RETURN,0,0,0
                invoke Sleep,5000

                invoke keybd_event,VK_RETURN,0,0,0
                invoke Sleep,5000

@ret:
		ret

_doIt	endp

start:
  invoke _doIt
  invoke ExitProcess,NULL
  end start



