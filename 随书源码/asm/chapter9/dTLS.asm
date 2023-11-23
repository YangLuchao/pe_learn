;------------------------
; 动态TLS演示,使用了TLS的线程运行时间统计程序
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
dwThreadID dd  ?;指向接收线程标识符的变量的指针
hThreadID  dd  MAX_THREAD_COUNT dup(0)

dwCount    dd  ?

szBuffer   db  500 dup(0)
szOut1     db  '线程%d终止，用时：%d毫秒。',0
szErr1     db  '读取TLS槽数据时失败！',0
szErr2     db  '写入TLS槽数据时失败！',0



;代码段
    .code

;----------
; 初始化时间
;----------
_initTime  proc  
   local @dwStart;局部变量

   pushad

   ;获得当前时间，
   ;将线程的创建时间与线程对象相关联
   invoke GetTickCount;检索自系统启动以来经过的毫秒数
   mov @dwStart,eax;检索的时间放入到局部变量中
   invoke TlsSetValue,hTlsIndex,@dwStart;将存储的时间变量放到tls槽中
   .if eax==0;入如果放入成功，返回值为非0值，放入失败为0
     invoke MessageBox,NULL,addr szErr2,\;弹出对话框，提示放入tls失败
                                NULL,MB_OK
   .endif
   popad
   ret;放入成功，函数执行完成
_initTime endp

;----------
; 获取用时
;----------
_getLostTime  proc  
   local @dwTemp
   pushad

   ;获得当前时间，
   ;返回当前时间和线程创建时间的差值
   invoke GetTickCount
   mov @dwTemp,eax
   invoke TlsGetValue,hTlsIndex;获取槽中当前线程的数据
   .if eax==0;如果获取失败，则弹出消息框提示
     invoke MessageBox,NULL,addr szErr2,\
                                NULL,MB_OK
   .endif
   sub @dwTemp,eax;当前时间减去槽中的时间
   popad
   mov eax,@dwTemp;返回耗时
   ret
_getLostTime endp


;----------
;子线程函数
;uses ebx ecx edx esi edi:会使用ebx ecx edx esi edi这几个寄存器，让框架做好处理
;lParam,参数
;----------
_tFun   proc  uses ebx ecx edx esi edi,lParam
   local @dwCount;本地变量
   local @tID;本地变量
   pushad

   invoke _initTime;初始化时间后，把获取的时间放到线程局部变量槽中

   ;模拟耗时操作
   mov @dwCount,1000*10000;做一个大数循环，模拟耗时操作
   mov ecx,@dwCount
   .while ecx>0
     dec @dwCount
     dec ecx
   .endw 
   ;获取当前线程的id
   invoke GetCurrentThreadId
   mov @tID,eax;将当前线程的id放入到局部变量中
   invoke _getLostTime;获取执行当前线程执行大数循环的用时
   invoke wsprintf,addr szBuffer,\;将耗时写到模板中
                    addr szOut1,@tID,eax
   invoke MessageBox,NULL,addr szBuffer,\;弹出提示
                               NULL,MB_OK

   popad
   ret;执行完成，返回
_tFun   endp


start:


  invoke TlsAlloc;主程序首先调用函数`TlsAlloc`向进程申请一个索引，以便为每个线程预留保存全局变量`hTlsIndex`不同值的空间
  mov hTlsIndex,eax

  mov dwCount,MAX_THREAD_COUNT;预定义的4个线程
  mov edi,offset hThreadID;预留的线程id存储数组首地址
  .while  dwCount>0
     invoke  CreateThread,NULL,0,\;创建一个新线程，返回线程号
                offset _tFun,NULL,\;新线程要执行_tFun函数
                NULL,addr dwThreadID
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
     invoke WaitForSingleObject,eax,\;WaitForSingleObject: 等待指定的对象处于信号状态或超时间隔已过
                              INFINITE;如果 dwMilliseconds 为 INFINITE，则函数仅在发出对象信号时返回
     invoke CloseHandle,dwThreadID;关闭打开的对象句柄
     pop edi

     add edi,4
     dec dwCount
  .endw

  ;通过释放线程局部存储索引，
  ;释放时间记录系统占用的资源
  invoke TlsFree,hTlsIndex

  end start
