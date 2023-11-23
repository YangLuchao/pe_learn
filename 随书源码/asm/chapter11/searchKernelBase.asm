;------------------------
; 获取kernel32.dll的基址
; 从进程地址空间搜索kernel32.dll的基地址
; 戚利
; 2010.6.27
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

szText  db 'kernel32.dll的基地址为%08x',0
szOut   db '%08x',0dh,0ah,0
szBuffer db 256 dup(0)

;代码段
    .code

start:

   call loc0
   db 'GetProcAddress',0  ;特征函数名

loc0:
   pop edx            ;edx中存放了特征函数名所在地址
   push edx
   mov ebx,7ffe0000h  ;从高地址开始

loc1:
   cmp dword ptr [ebx],905A4Dh
   JE loc2   ;判断是否为MS DOS头标志

loc5:
   sub ebx,00010000h

   pushad         ;保护寄存器1
   invoke IsBadReadPtr,ebx,2
   .if eax
     popad        ;恢复寄存器1
     jmp loc5
   .endif
   popad          ;恢复寄存器1

   jmp loc1



loc2:   ;遍历导出表
   mov esi,dword ptr [ebx+3ch] 
   add esi,ebx ;ESI指向PE头
   mov esi,dword ptr [esi+78h]
   nop
 
   .if esi==0
     jmp loc5
   .endif
   add esi,ebx ;ESI指向数据目录中的导出表
   mov edi,dword ptr [esi+20h] ;指向导出表的AddressOfNames
   add edi,ebx ;EDI为AddressOfNames数组起始位置
   mov ecx,dword ptr [esi+18h] ;指向导出表的NumberOfNames
   push esi


   xor eax,eax
loc3:
   push edi
   push ecx
   mov edi,dword ptr [edi]
   add edi,ebx  ;edi指向了第一个函数的字符串名起始
   mov esi,edx  ;esi指向了特征函数名起始
   xor ecx,ecx
   mov cl,0eh  ;特征函数名的长度
   repe cmpsb  ;比较两个字符串
   pop ecx
   pop edi
   je loc4    ;找到特征函数，转移
   add edi,4  ;edi移动到下一个函数名所在地址
   inc eax    ;eax为计数
   loop loc3

   jmp loc5
loc4:
   ;特征函数匹配成功，输出模块基地址
    
    invoke wsprintf,addr szBuffer,addr szText,ebx
    invoke MessageBox,NULL,addr szBuffer,NULL,MB_OK
    ret
    end start
