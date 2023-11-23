;------------------------
; �����쳣����
; ����
; 2011.1.19
;------------------------
    .386
    .model flat,stdcall
    option casemap:none;��Сд������

include    windows.inc
include    user32.inc
includelib user32.lib
include    kernel32.inc
includelib kernel32.lib

;���ݶ�
    .data
szText     db  'HelloWorldPE',0;������ʾ
szErr      db  'SEH Error',0;������ʾ
;�����
    .code
;�쳣�������
;_lpException:�����쳣�Ĵ�����Ϣָ��
;_lpSEH��SEHָ��
;_lpContext����ǰ�̵߳���������Ϣָ��
;_lpDispatcherContext��������������ָ�룬ͨ�����ڸ߼����쳣�����߼�
_handler proc _lpException,_lpSEH,\
             _lpContext,_lpDispatcherContext
  nop
  pushad
  mov esi,_lpException;�����쳣������Ϣָ��
  mov edi,_lpContext;��ǰ�߳�������ָ��
   
  assume edi:ptr CONTEXT;����ΪCONTEXT����

  invoke MessageBox,NULL,addr szErr,NULL,MB_OK;����messagebox��

  mov [edi].regEip,offset _safePlace;�õ���ȫ���ţ�����Ϊ��ǰ�߳�������IP�Ĵ�����ֵ
  assume edi:nothing

  popad  

  ;����һ
  ;�������쳣�ѱ��ú����ӹ�
  mov eax,ExceptionContinueExecution;����ָ��ö�٣�����ϵͳ��ǰ�쳣�ѱ��ӹ�

  ;���Զ�
  ;�������쳣δ���ú����ӹ�
  ;mov eax,ExceptionContinueSearch;����ָ��ö�٣�����ϵͳ��ǰ�쳣δ���ӹܣ���Ҫ��������
  ret
_handler endp

start:
    ;���� try catch
    assume fs:nothing
    push offset _handler
    push fs:[0]
    mov fs:[0],esp
    ;���� try catch

    xor eax,eax
    mov dword ptr [eax],eax;�����쳣

_safePlace:
    
    pop fs:[0]
    pop eax

    invoke MessageBox,NULL,addr szText,NULL,MB_OK
    invoke ExitProcess,NULL
    end start