;------------------------
; ��̬TLS��ʾ,ʹ����TLS���߳�����ʱ��ͳ�Ƴ���
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
dwThreadID dd  ?;ָ������̱߳�ʶ���ı�����ָ��
hThreadID  dd  MAX_THREAD_COUNT dup(0)

dwCount    dd  ?

szBuffer   db  500 dup(0)
szOut1     db  '�߳�%d��ֹ����ʱ��%d���롣',0
szErr1     db  '��ȡTLS������ʱʧ�ܣ�',0
szErr2     db  'д��TLS������ʱʧ�ܣ�',0



;�����
    .code

;----------
; ��ʼ��ʱ��
;----------
_initTime  proc  
   local @dwStart;�ֲ�����

   pushad

   ;��õ�ǰʱ�䣬
   ;���̵߳Ĵ���ʱ�����̶߳��������
   invoke GetTickCount;������ϵͳ�������������ĺ�����
   mov @dwStart,eax;������ʱ����뵽�ֲ�������
   invoke TlsSetValue,hTlsIndex,@dwStart;���洢��ʱ������ŵ�tls����
   .if eax==0;���������ɹ�������ֵΪ��0ֵ������ʧ��Ϊ0
     invoke MessageBox,NULL,addr szErr2,\;�����Ի�����ʾ����tlsʧ��
                                NULL,MB_OK
   .endif
   popad
   ret;����ɹ�������ִ�����
_initTime endp

;----------
; ��ȡ��ʱ
;----------
_getLostTime  proc  
   local @dwTemp
   pushad

   ;��õ�ǰʱ�䣬
   ;���ص�ǰʱ����̴߳���ʱ��Ĳ�ֵ
   invoke GetTickCount
   mov @dwTemp,eax
   invoke TlsGetValue,hTlsIndex;��ȡ���е�ǰ�̵߳�����
   .if eax==0;�����ȡʧ�ܣ��򵯳���Ϣ����ʾ
     invoke MessageBox,NULL,addr szErr2,\
                                NULL,MB_OK
   .endif
   sub @dwTemp,eax;��ǰʱ���ȥ���е�ʱ��
   popad
   mov eax,@dwTemp;���غ�ʱ
   ret
_getLostTime endp


;----------
;���̺߳���
;uses ebx ecx edx esi edi:��ʹ��ebx ecx edx esi edi�⼸���Ĵ������ÿ�����ô���
;lParam,����
;----------
_tFun   proc  uses ebx ecx edx esi edi,lParam
   local @dwCount;���ر���
   local @tID;���ر���
   pushad

   invoke _initTime;��ʼ��ʱ��󣬰ѻ�ȡ��ʱ��ŵ��ֲ߳̾���������

   ;ģ���ʱ����
   mov @dwCount,1000*10000;��һ������ѭ����ģ���ʱ����
   mov ecx,@dwCount
   .while ecx>0
     dec @dwCount
     dec ecx
   .endw 
   ;��ȡ��ǰ�̵߳�id
   invoke GetCurrentThreadId
   mov @tID,eax;����ǰ�̵߳�id���뵽�ֲ�������
   invoke _getLostTime;��ȡִ�е�ǰ�߳�ִ�д���ѭ������ʱ
   invoke wsprintf,addr szBuffer,\;����ʱд��ģ����
                    addr szOut1,@tID,eax
   invoke MessageBox,NULL,addr szBuffer,\;������ʾ
                               NULL,MB_OK

   popad
   ret;ִ����ɣ�����
_tFun   endp


start:


  invoke TlsAlloc;���������ȵ��ú���`TlsAlloc`���������һ���������Ա�Ϊÿ���߳�Ԥ������ȫ�ֱ���`hTlsIndex`��ֵͬ�Ŀռ�
  mov hTlsIndex,eax

  mov dwCount,MAX_THREAD_COUNT;Ԥ�����4���߳�
  mov edi,offset hThreadID;Ԥ�����߳�id�洢�����׵�ַ
  .while  dwCount>0
     invoke  CreateThread,NULL,0,\;����һ�����̣߳������̺߳�
                offset _tFun,NULL,\;���߳�Ҫִ��_tFun����
                NULL,addr dwThreadID
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
     invoke WaitForSingleObject,eax,\;WaitForSingleObject: �ȴ�ָ���Ķ������ź�״̬��ʱ����ѹ�
                              INFINITE;��� dwMilliseconds Ϊ INFINITE���������ڷ��������ź�ʱ����
     invoke CloseHandle,dwThreadID;�رմ򿪵Ķ�����
     pop edi

     add edi,4
     dec dwCount
  .endw

  ;ͨ���ͷ��ֲ߳̾��洢������
  ;�ͷ�ʱ���¼ϵͳռ�õ���Դ
  invoke TlsFree,hTlsIndex

  end start
