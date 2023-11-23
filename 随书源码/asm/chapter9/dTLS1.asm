;------------------------
; 动态TLS对比演示
; 不使用TLS的多线程应用程序
; 没有使用TLS的线程运行时间统计程序
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

MAX_THREAD_COUNT equ 4

;数据段
    .data
hTlsIndex  dd  ?
dwThreadID dd  ?
hThreadID  dd  MAX_THREAD_COUNT dup(0)

dwCount    dd  ?

szBuffer   db  500 dup(0)
szOut1     db  '线程%d终止，用时：%d毫秒。',0

;代码段
    .code

;----------
; 线程函数
; 要使用ebx ecx edx esi edi寄存器，框架做好处理准备
; lParam一个参数
;----------
_tFun   proc  uses ebx ecx edx esi edi,lParam
   local @dwCount
   local @dwStart
   local @dwEnd
   local @tID
   pushad

   ;获得当前时间，
   ;将线程的创建时间与线程对象相关联
   invoke GetTickCount;获取当前线程时间
   mov @dwStart,eax;放入局部变量

   ;大数循环模拟耗时操作
   mov @dwCount,1000*10000
   mov ecx,@dwCount
   .while ecx>0
     dec @dwCount
     dec ecx
   .endw 

   invoke GetCurrentThreadId;获取当前线程的线程id
   mov @tID,eax;线程id放入到局部变量中

   invoke GetTickCount;再次获取当前线程时间
   mov @dwEnd,eax;放入局部变量
   mov eax,@dwStart
   sub @dwEnd,eax;计算耗时
   invoke wsprintf,addr szBuffer,\;拼装字符串
                    addr szOut1,@tID,@dwEnd
   invoke MessageBox,NULL,addr szBuffer,\;弹出消息框
                               NULL,MB_OK

   popad
   ret
_tFun   endp


start:

  mov dwCount,MAX_THREAD_COUNT
  mov edi,offset hThreadID
  .while  dwCount>0
     invoke  CreateThread,NULL,0,\;创建子线程，并执行_tFun函数
                offset _tFun,NULL,\
                NULL,addr dwThreadID;指向一个变量的指针，该变量接收新创建线程的线程标识符
     mov dword ptr [edi],eax
     add edi,4

     dec dwCount
  .endw
  
  ;等待结束线程
  mov dwCount,MAX_THREAD_COUNT
  mov edi,offset hThreadID
  .while  dwCount>0
     mov eax,dword ptr [edi]
     mov dwThreadID,eax
     push edi
     invoke WaitForSingleObject,dwThreadID,\;等待线程结束
                              INFINITE
     invoke CloseHandle,dwThreadID;关闭线程
     pop edi

     add edi,4
     dec dwCount
  .endw

  end start
