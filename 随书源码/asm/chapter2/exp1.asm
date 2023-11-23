.386 
.model   flat,stdcall 
option   casemap:none 

include c:\masm32\include\windows.inc 
include c:\masm32\include\user32.inc 
includelib c:\masm32\lib\user32.lib 
include c:\masm32\include\kernel32.inc 
includelib c:\masm32\lib\kernel32.lib 
include c:\masm32\include\Comctl32.inc 
includelib c:\masm32\lib\Comctl32.lib 

dlg_main equ 1000 
lv_main equ 1001 

.const 
szname0 db 'Name0 ',0 
szname1 db 'Name1 ',0 
szitem0 db 'item0 ',0 
szitem1 db 'item1 ',0 
szitem2 db 'item2 ',0 
szitem3 db 'item3 ',0 

.data? 
hInstance dd ? 

.code 
_ProcDlgMain proc uses   ebx   edi   esi   hWnd,wMsg,wParam,lParam 
local hlist 
local item:LVITEM 
local lvcol:LV_COLUMN 

mov eax,wMsg 
.if eax   ==   WM_CLOSE 
invoke EndDialog,hWnd,NULL 
.elseif eax   ==   WM_INITDIALOG 
invoke GetDlgItem,hWnd,lv_main 
mov hlist,eax 

mov   lvcol.imask,LVCF_FMT   or   LVCF_WIDTH   or   \ 
        LVCF_TEXT   or   LVCF_SUBITEM 
mov lvcol.fmt,LVCFMT_CENTER 
mov lvcol.lx,100 
mov lvcol.pszText,offset   szname0 
invoke SendMessage,hlist,LVM_INSERTCOLUMN,0,\ 
addr   lvcol 

mov   lvcol.imask,LVCF_FMT   or   LVCF_WIDTH   or   \ 
LVCF_TEXT   or   LVCF_SUBITEM 
mov lvcol.fmt,LVCFMT_CENTER 
mov lvcol.lx,100 
mov lvcol.pszText,offset   szname1 
invoke SendMessage,hlist,LVM_INSERTCOLUMN,1,\ 
addr   lvcol 

            mov   item.imask,LVIF_TEXT       
            mov   item.iSubItem,0   
            mov   item.iItem,0 
            mov   item.stateMask,0 
            mov   item.pszText,offset   szitem0 
            invoke   SendMessage,hlist,LVM_INSERTITEM,0,\ 
addr   item 
mov   item.iSubItem,1 
mov   item.pszText,offset   szitem1 
INVOKE           SendMessage,   hlist,   LVM_SETITEM,   1,   \ 
addr   item 

mov   item.imask,LVIF_TEXT       
            mov   item.iSubItem,0   
            mov   item.iItem,1 
            mov   item.stateMask,0 
            mov   item.pszText,offset   szitem2 
            invoke   SendMessage,hlist,LVM_INSERTITEM,0,\ 
addr   item 
mov   item.iSubItem,1 
mov   item.pszText,offset   szitem3 
INVOKE           SendMessage,   hlist,   LVM_SETITEM,   1,   \ 
addr   item 

invoke   SendMessage,hlist,LVM_SETEXTENDEDLISTVIEWSTYLE,\ 
  LVS_EX_FULLROWSELECT   or   LVS_EX_GRIDLINES,\ 
  LVS_EX_FULLROWSELECT   or   LVS_EX_GRIDLINES 

.elseif eax   ==   WM_COMMAND 

.else 
mov eax,FALSE 
ret 
.endif 
mov eax,TRUE 
ret 

_ProcDlgMain endp 

start: 
invoke GetModuleHandle,NULL 
mov hInstance,eax 

invoke InitCommonControls 
invoke DialogBoxParam,hInstance,dlg_main,NULL,\ 
addr   _ProcDlgMain,NULL 
invoke ExitProcess,NULL 
end start