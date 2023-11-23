;UniversalkernelBase.asm
;获取kerne132.du的基址的通用方法，支持XP/Vista/WIN7以及X86/X64
;从PEB结构中搜索kerne132.dll的基地址
;编程达人
;2010.6.27

	.386
	.model flat,stdcall
	option casemap:none

include
windows.inc
include
user32.inc
includelib user32.lib
include
kernel32.inc
includelib kernel32. lib

;CPUX64=1;X64 masm32无法编译
CPUX86=1;X86

	;数据段
	.data
szText db'kernel32.d11的基地址为%08x',0
szout db'%08x', odh, oah, 0
szBuffer db 256 dup(0)

;代码段
	.code
start :
	assume fs:nothing
	IFDEF CPUX64
		mov rax,gs:[60h]
		mov rax,[rax+18h]
		mov rax,[rax+30h]
		mov rax, [rax]
		mov rax,[rax]
		mov rax, [rax + 10h]
	ELSE
		assume fs:nothing
		mov eax,fs:[30h]
		mov eax,[eax+0ch]
		mov eax,[eax+Och]
		mov eax,[eax]
		mov eax,[eax]
		mov eax,[eax+18h]
	ENDIF
	;输出模块基地址
	invoke wsprintf,addr szBuffer,addr szText,eax
	invoke MessageBox,NULL,addr szBuffer,NULL,MB_OK
	ret
end start