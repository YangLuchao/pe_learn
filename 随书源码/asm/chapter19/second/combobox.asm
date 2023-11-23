;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
; FileName: combobox.asm
; Function: Demo the usage of comboxbox
; Author: Purple Endurer
;
; LOG
;----------------------------------------------------------------------------------
; 2005-08-08 Created!
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
.386
.model flat,stdcall
option casemap:none
include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
WinMain proto :DWORD,:DWORD,:DWORD,:DWORD
.data
ClassName db "SimpleWinClass",0
AppName db "Our First Window",0
g_szComboBoxCls db "ComboBox", 0
.data?
hInstance HINSTANCE ?
g_hcbDemo1 HANDLE ?
g_hcbDemo2 HANDLE ?
.code
start:
invoke GetModuleHandle, NULL
mov hInstance,eax
invoke WinMain, hInstance,NULL,NULL, SW_SHOWDEFAULT
invoke ExitProcess,eax
WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
LOCAL wc:WNDCLASSEX
LOCAL msg:MSG
LOCAL hwnd:HWND
mov wc.cbSize,SIZEOF WNDCLASSEX
mov wc.style, CS_HREDRAW or CS_VREDRAW
mov wc.lpfnWndProc, OFFSET WndProc
mov wc.cbClsExtra,NULL
mov wc.cbWndExtra,NULL
push hInstance
pop wc.hInstance
mov wc.hbrBackground,COLOR_WINDOW+1
mov wc.lpszMenuName,NULL
mov wc.lpszClassName,OFFSET ClassName
invoke LoadIcon,NULL,IDI_APPLICATION
mov wc.hIcon,eax
mov wc.hIconSm,eax
invoke LoadCursor,NULL,IDC_ARROW
mov wc.hCursor,eax
invoke RegisterClassEx, addr wc
INVOKE CreateWindowEx,NULL,ADDR ClassName,ADDR AppName, WS_OVERLAPPEDWINDOW,CW_USEDEFAULT, CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,NULL,NULL, hInst,NULL
mov hwnd,eax
invoke ShowWindow, hwnd,SW_SHOWNORMAL
invoke UpdateWindow, hwnd
.WHILE TRUE
 invoke GetMessage, ADDR msg,NULL,0,0
 .BREAK .IF (!eax)
 invoke TranslateMessage, ADDR msg
 invoke DispatchMessage, ADDR msg
.ENDW
mov eax,msg.wParam
ret
WinMain endp
WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
.IF uMsg==WM_DESTROY
 invoke PostQuitMessage,NULL
.ELSEIF uMsg==WM_CREATE
 ;创建正常的COMBOBOX
 INVOKE CreateWindowEx, WS_EX_PALETTEWINDOW or WS_EX_CLIENTEDGE, ADDR g_szComboBoxCls, ADDR AppName, WS_CHILD or WS_VISIBLE or WS_VSCROLL or WS_TABSTOP or CBS_DROPDOWNLIST, 30, 0, 180, 150, hWnd, 400, hInstance, NULL
 mov g_hcbDemo1, eax
 INVOKE SendMessage, g_hcbDemo1, CB_ADDSTRING, 0, ADDR g_szComboBoxCls
 INVOKE SendMessage, g_hcbDemo1, CB_ADDSTRING, 0, ADDR AppName
 INVOKE SendMessage, g_hcbDemo1, CB_SETCURSEL, 0, 0
 ;下面这个combox会因高度设置太低（为10）而无法显示下拉列表
 INVOKE CreateWindowEx, WS_EX_PALETTEWINDOW or WS_EX_CLIENTEDGE, ADDR g_szComboBoxCls, ADDR AppName, WS_CHILD or WS_VISIBLE or WS_VSCROLL or WS_TABSTOP or CBS_DROPDOWNLIST, 30, 40, 180, 10, hWnd, 401, hInstance, NULL
 mov g_hcbDemo2, eax
 INVOKE SendMessage, g_hcbDemo2, CB_ADDSTRING, 0, ADDR g_szComboBoxCls
 INVOKE SendMessage, g_hcbDemo2, CB_ADDSTRING, 0, ADDR AppName
 INVOKE SendMessage, g_hcbDemo2, CB_SETCURSEL, 0, 0
.ELSE
 invoke DefWindowProc,hWnd,uMsg,wParam,lParam 
 ret
.ENDIF
xor eax,eax
ret
WndProc endp
end start