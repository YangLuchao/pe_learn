;------------------------
; ��̬TLS�Ա���ʾ
; ��ʹ��TLS�Ķ��߳�Ӧ�ó���
; û��ʹ��TLS���߳�����ʱ��ͳ�Ƴ���
; ����
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

;���ݶ�
    .data
hTlsIndex  dd  ?
dwThreadID dd  ?
hThreadID  dd  MAX_THREAD_COUNT dup(0)

dwCount    dd  ?

szBuffer   db  500 dup(0)
szOut1     db  '�߳�%d��ֹ����ʱ��%d���롣',0

;�����
    .code

;----------
; �̺߳���
; Ҫʹ��ebx ecx edx esi edi�Ĵ�����������ô���׼��
; lParamһ������
;----------
_tFun   proc  uses ebx ecx edx esi edi,lParam
   local @dwCount
   local @dwStart
   local @dwEnd
   local @tID
   pushad

   ;��õ�ǰʱ�䣬
   ;���̵߳Ĵ���ʱ�����̶߳��������
   invoke GetTickCount;��ȡ��ǰ�߳�ʱ��
   mov @dwStart,eax;����ֲ�����

   ;����ѭ��ģ���ʱ����
   mov @dwCount,1000*10000
   mov ecx,@dwCount
   .while ecx>0
     dec @dwCount
     dec ecx
   .endw 

   invoke GetCurrentThreadId;��ȡ��ǰ�̵߳��߳�id
   mov @tID,eax;�߳�id���뵽�ֲ�������

   invoke GetTickCount;�ٴλ�ȡ��ǰ�߳�ʱ��
   mov @dwEnd,eax;����ֲ�����
   mov eax,@dwStart
   sub @dwEnd,eax;�����ʱ
   invoke wsprintf,addr szBuffer,\;ƴװ�ַ���
                    addr szOut1,@tID,@dwEnd
   invoke MessageBox,NULL,addr szBuffer,\;������Ϣ��
                               NULL,MB_OK

   popad
   ret
_tFun   endp


start:

  mov dwCount,MAX_THREAD_COUNT
  mov edi,offset hThreadID
  .while  dwCount>0
     invoke  CreateThread,NULL,0,\;�������̣߳���ִ��_tFun����
                offset _tFun,NULL,\
                NULL,addr dwThreadID;ָ��һ��������ָ�룬�ñ��������´����̵߳��̱߳�ʶ��
     mov dword ptr [edi],eax
     add edi,4

     dec dwCount
  .endw
  
  ;�ȴ������߳�
  mov dwCount,MAX_THREAD_COUNT
  mov edi,offset hThreadID
  .while  dwCount>0
     mov eax,dword ptr [edi]
     mov dwThreadID,eax
     push edi
     invoke WaitForSingleObject,dwThreadID,\;�ȴ��߳̽���
                              INFINITE
     invoke CloseHandle,dwThreadID;�ر��߳�
     pop edi

     add edi,4
     dec dwCount
  .endw

  end start
