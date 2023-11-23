;------------------------
; �޵���������ݶΡ����ض�λ��Ϣ��HelloWorld
; ����
; 2010.6.27
;------------------------
    .386
    .model flat,stdcall
    option casemap:none

include    windows.inc

;�����������������ͣ���������
_QLGetProcAddress typedef proto :dword,:dword   
;�����������ã�ָ�룩�� _QLGetProcAddress���ͣ�_ApiGetProcAddress����
_ApiGetProcAddress  typedef ptr _QLGetProcAddress  
;�����������������ͣ�һ������
_QLLoadLib        typedef proto :dword
;�����������ã�ָ�룩��_QLLoadLib���ͣ�_ApiLoadLibָ������
_ApiLoadLib       typedef ptr _QLLoadLib
;�����������������ͣ�һ���ĸ�����
_QLMessageBoxA    typedef proto :dword,:dword,:dword,:dword
;������������(ָ��)��_QLMessageBoxA���ͣ�_ApiMessageBoxA����
_ApiMessageBoxA   typedef ptr _QLMessageBoxA


;�����
    .code

szText         db  'HelloWorldPE',0
szGetProcAddr  db  'GetProcAddress',0
szLoadLib      db  'LoadLibraryA',0
szMessageBox   db  'MessageBoxA',0

user32_DLL     db  'user32.dll',0,0

;���庯��
;�����ȡ������ַ����ָ��
_getProcAddress _ApiGetProcAddress  ?     
;������ض�̬���ӿ⺯��ָ��        
_loadLibrary    _ApiLoadLib         ?
;����messageBox����ָ��
_messageBox     _ApiMessageBoxA     ?

;kernel32.dll��̬���ӿ��ַ
hKernel32Base   dd  ?
;user32.dll��̬���ӿ��ַ
hUser32Base     dd  ?
;��ȡ������ַ������ַ
lpGetProcAddr   dd  ?
;���ض�̬���ӿ⺯����ַ
lpLoadLib       dd  ?


;------------------------------------
; ����kernel32.dll�е�һ����ַ��ȡ���Ļ���ַ
; _dwKernelRetAddress:��ǰ�����Ķ�ջջ��ֵ
;------------------------------------
_getKernelBase  proc _dwKernelRetAddress
   local @dwRet

   pushad

   mov @dwRet,0
   
   mov edi,_dwKernelRetAddress
   and edi,0ffff0000h  ;����ָ������ҳ�ı߽磬��1000h����

   .repeat
     ;�ҵ�kernel32.dll��dosͷ
     .if word ptr [edi]==IMAGE_DOS_SIGNATURE  
        mov esi,edi
        add esi,[esi+003ch]
        ;�ҵ�kernel32.dll��PEͷ��ʶ
        .if word ptr [esi]==IMAGE_NT_SIGNATURE 
          mov @dwRet,edi
          .break
        .endif
     .endif
     sub edi,010000h
     .break .if edi<070000000h
   .until FALSE
   popad
   mov eax,@dwRet
   ret
_getKernelBase  endp   

;-------------------------------
; �����������Ҫ��ͨ�����������ҵ�������ַ
; ��ȡָ���ַ�����API�����ĵ��õ�ַ
; ��ڲ�����_hModuleΪ��̬���ӿ�Ļ�ַ
;           _lpApiΪAPI����������ַ
; ���ڲ�����eaxΪ�����������ַ�ռ��е���ʵ��ַ
;-------------------------------
_getApi proc _hModule,_lpApi
   local @ret
   local @dwLen

   pushad
   mov @ret,0
   ;����API�ַ����ĳ��ȣ���������
   mov edi,_lpApi
   mov ecx,-1
   xor al,al
   cld
   repnz scasb
   mov ecx,edi
   sub ecx,_lpApi
   mov @dwLen,ecx

   ;��pe�ļ�ͷ������Ŀ¼��ȡ�������ַ
   mov esi,_hModule
   add esi,[esi+3ch]
   assume esi:ptr IMAGE_NT_HEADERS
   mov esi,[esi].OptionalHeader.DataDirectory.VirtualAddress
   add esi,_hModule
   assume esi:ptr IMAGE_EXPORT_DIRECTORY

   ;���ҷ������Ƶĵ���������
   mov ebx,[esi].AddressOfNames
   add ebx,_hModule
   xor edx,edx
   .repeat
     push esi
     mov edi,[ebx]
     add edi,_hModule
     mov esi,_lpApi
     mov ecx,@dwLen
     repz cmpsb
     .if ZERO?
       pop esi
       jmp @F
     .endif
     pop esi
     add ebx,4
     inc edx
   .until edx>=[esi].NumberOfNames
   jmp _ret
@@:
   ;ͨ��API����������ȡ��������ٻ�ȡ��ַ����
   sub ebx,[esi].AddressOfNames
   sub ebx,_hModule
   shr ebx,1
   add ebx,[esi].AddressOfNameOrdinals
   add ebx,_hModule
   movzx eax,word ptr [ebx]
   shl eax,2
   add eax,[esi].AddressOfFunctions
   add eax,_hModule
   
   ;�ӵ�ַ��õ����������ĵ�ַ
   mov eax,[eax]
   add eax,_hModule
   mov @ret,eax

_ret:
   assume esi:nothing
   popad
   mov eax,@ret
   ret
_getApi endp


start:
    ;----------------------------��ȥ�ض�λ��
    ;ȡ��ǰ�����Ķ�ջջ��ֵ
    mov eax,dword ptr [esp]
    push eax
    call @F   ; ��ȥ�ض�λ
@@:
    pop ebx
    sub ebx,offset @B;�ض�λ����ֵŲ��ebx��
    ;----------------------------��ȥ�ض�λ��

    pop eax
    ;��ȡkernel32.dll�Ļ���ַ
    invoke _getKernelBase,eax;����ֵEAX�洢kernel32��ַ
    ;����hKernel32Baseȫ�ֱ�����ַ�����������kernel32��ַŲ��ȫ�ֱ�����
    mov [ebx + offset hKernel32Base],eax

    ;�ӻ���ַ��������GetProcAddress��������ַ
    mov eax,offset szGetProcAddr
    add eax,ebx;����ȫ�ֱ���

    mov edi,offset hKernel32Base
    mov ecx,[ebx+edi];���еĺ�����ַ,��̬���ӿ��ַ��ȫ�ֱ�����ַ�������ϵ�ַ��


    invoke _getApi,ecx,eax;ecx�洢kernel32��ַ��eax�洢Ŀ�꺯����ƫ�Ƶ�ַ
    mov [ebx+offset lpGetProcAddr],eax;���GetProcAddres�����ĵ�ַ��Ų��ȫ�ֱ�����

    ;Ϊ�������ø�ֵ GetProcAddress
    mov [ebx+offset _getProcAddress],eax   ;ͬʱ��GetProcAddres������ַŲ������ĺ�����

    ;ʹ��GetProcAddress��������ַ
    ;����������������GetProcAddress���������LoadLibraryA����ַ
    mov eax,offset szLoadLib;LoadLibraryA����Ų��eax����Ϊ����
    add eax,ebx;����
   
    mov edi,offset hKernel32Base;kernel32.dll��ַŲ��edi�У���Ϊ����
    mov ecx,[ebx+edi];����
    
    mov edx,offset _getProcAddress;GetProcAddress������ַŲ��edx�У�׼������
    add edx,ebx
    
    ;ģ�µ��� invoke GetProcAddress,hKernel32Base,addr szLoadLib
    ;std����Լ�����������ҵ��󴫵�
    push eax
    push ecx
    call dword ptr [edx]   ;ִ�е���

    mov [ebx+offset _loadLibrary],eax;���LoadLibraryA�����ĵ�ַ���洢��ȫ�ֱ�����

    ;ʹ��LoadLibrary��ȡuser32.dll�Ļ���ַ
    mov eax,offset user32_DLL
    add eax,ebx;����

    mov edi,offset _loadLibrary;LoadLibraryA������ַ
    mov edx,[ebx+edi];����
    
    push eax   ; ����
    call edx   ; invoke LoadLibraryA,addr _loadLibrary

    mov [ebx+offset hUser32Base],eax;user32.dll��ַŲ��ȫ�ֱ�����

    ;ʹ��GetProcAddress��������ַ����ú���MessageBoxA����ַ
    mov eax,offset szMessageBox
    add eax,ebx;����
   
    mov edi,offset hUser32Base;user32.dll��ַ
    mov ecx,[ebx+edi];����
    
    mov edx,offset _getProcAddress;GetProcAddress������ַ
    add edx,ebx;����


    ;ģ�µ��� invoke GetProcAddress,hUser32Base,addr szMessageBox
    push eax
    push ecx
    call dword ptr [edx]   
    mov [ebx+offset _messageBox],eax;MessageBoxA������ַŲ��ȫ�ֱ�����

    ;���ú���MessageBoxA
    mov eax,offset szText
    add eax,ebx

    mov edx,offset _messageBox
    add edx,ebx

    ;ģ�µ��� invoke MessageBoxA,NULL,addr szText,NULL,MB_OK    
    push 0;#define MB_OK 0x00000000L
    push NULL
    push eax
    push NULL
    call dword ptr [edx]   

    ret
    end start
