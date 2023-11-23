;------------------------
; 简单窗口程序
; 具有窗口的大部分基本特性，其中显示和退出使用了渐入和渐出效果
; 该程序主要演示自己制作的dll的函数调用
; 戚利
; 2010.6.27
;------------------------
    .386
    .model flat,stdcall
    option casemap:none

include    windows.inc
include    gdi32.inc
includelib gdi32.lib
include    user32.inc
includelib user32.lib
include    kernel32.inc
includelib kernel32.lib
include    winResult.inc
includelib winResult.lib

;数据段
    .data?
hInstance  dd  ?
hWinMain   dd  ?
;常量定义
    .const
szClassName    db  'MyClass',0
szCaptionMain  db  '窗口特效演示',0
szText         db  '你好，认识我吗？^_^',0

;代码段
    .code
;------------------
; 窗口消息处理子程序
;------------------
_ProcWinMain proc uses ebx edi esi,hWnd,uMsg,wParam,lParam
      local @stPs:PAINTSTRUCT
      local @stRect:RECT
      local @hDc

      mov eax,uMsg
      
      .if eax==WM_PAINT
          invoke BeginPaint,hWnd,addr @stPs
          mov @hDc,eax
          invoke GetClientRect,hWnd,addr @stRect
          invoke DrawText,@hDc,addr szText,-1,\
                 addr @stRect,\
                 DT_SINGLELINE or DT_CENTER or DT_VCENTER
          invoke EndPaint,hWnd,addr @stPs
      .elseif eax==WM_CLOSE    ;关闭窗口
             invoke FadeOutClose,hWinMain
             invoke DestroyWindow,hWinMain
             invoke PostQuitMessage,NULL
      .else
          invoke DefWindowProc,hWnd,uMsg,wParam,lParam
          ret
      .endif
      
      xor eax,eax
      ret
_ProcWinMain endp

;----------------------
; 主窗口程序
;----------------------
_WinMain  proc
       local @stWndClass:WNDCLASSEX
       local @stMsg:MSG

       invoke GetModuleHandle,NULL
       mov hInstance,eax
       invoke RtlZeroMemory,addr @stWndClass,sizeof @stWndClass
       
       ;注册窗口类
       invoke LoadCursor,0,IDC_ARROW
       mov @stWndClass.hCursor,eax
       push hInstance
       pop @stWndClass.hInstance
       mov @stWndClass.cbSize,sizeof WNDCLASSEX
       mov @stWndClass.style,CS_HREDRAW or CS_VREDRAW
       mov @stWndClass.lpfnWndProc,offset _ProcWinMain
       mov @stWndClass.hbrBackground,COLOR_WINDOW+1
       mov @stWndClass.lpszClassName,offset szClassName
       invoke RegisterClassEx,addr @stWndClass

       ;建立并显示窗口
       invoke CreateWindowEx,WS_EX_CLIENTEDGE,\
              offset szClassName,offset szCaptionMain,\
              WS_OVERLAPPEDWINDOW,\
              100,100,600,400,\
              NULL,NULL,hInstance,NULL
       mov  hWinMain,eax
       invoke FadeInOpen,hWinMain
       ;invoke ShowWindow,hWinMain,SW_SHOWNORMAL
       invoke UpdateWindow,hWinMain ;更新客户区，即发送WM_PAINT消息

   
       ;消息循环
       .while TRUE
          invoke GetMessage,addr @stMsg,NULL,0,0
          .break .if eax==0
          invoke TranslateMessage,addr @stMsg
          invoke DispatchMessage,addr @stMsg
       .endw
       ret
_WinMain endp

start:
       call _WinMain
       invoke ExitProcess,NULL
       end start
