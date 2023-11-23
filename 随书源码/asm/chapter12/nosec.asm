             .386
            .model flat,stdcall
            option casemap:none
    
            .code
DOSHeader  db 'MZ'
szKernel32_dll db 'kernel32.dll',0
           align 2

PEHeaders  db 'PE',0,0
           dw 14ch
           dw 0
Entry      proc near
           assume fs:nothing
           mov eax,fs:[18h]
           mov eax,[eax+30h]    
           jmp short L1
           align 4
           dw 0DCh
           dw 10Fh
OptionalHeader dw 10Bh

L1:
           mov eax,[eax+8]      ;eax=基地址
           call GetCurrAddr
           jmp short L2

           dd 0
           dd offset Entry      ;AddressOfEntryPoint
           dd 10h               ;
L2:
           jmp short L3
           align 4
           dd 400000h           ;ImageBase
           dd 4                 ;SectionAlignment
           dd 4                 ;FileAlignment
L3:
           mov hInstance[ebx],eax
           jmp short L4

           dw 4
           dw 0
           dd 0
           dd 1A0h
           dd 0
           dd 0
           dw 2
           dw 0
           dd 100h
           dd 100h
           dd 100h
           dd 100h
           dd 0
           dd 0dh                ;NumberOfRvaAndSizes

           
           dd 0         ;IMAGE_DIRECTORY_ENTRY_EXPORT <0>
           dd 0
           dd offset ImportTable
           dd 28h

LoadLibraryAPtr    dd  offset szLoadLibraryA
GetProcAddressPtr  dd  offset szGetProcAddress
                   dd 0
szLoadLibraryA     dw 1E6h                      ;Hint
                   db 'LoadLibraryA',0          ;Name
                   align 4
szGetProcAddress   dw 158h                      ;Hint
                   db 'GetProcAddress',0        ;name
L4:
                   jmp short L5
                   align 4
               
                   dd 0   ;IMAGE_DIRECTORY_ENTRY_GLOBALPTR <0>
                   dd 0
                   dd 0   ;IMAGE_DIRECTORY_ENTRY_TLS <0>
                   dd 0

ImportTable        dd offset LoadLibraryAPtr
                   dd 0
                   dd 0
                   dd offset szKernel32_dll
                   dd offset LoadLibraryA
                   dd 0Ch
LoadLibraryA       dd offset szLoadLibraryA
GetProcAddress     dd offset szGetProcAddress
                  
                   dd 0
                   dd 0
                   dd 0

j_LoadLibraryA:
                   jmp LoadLibraryA
j_GetProcAddress:
                   jmp GetProcAddress



L5:                lea eax,szUser32_dll[ebx]
                   push eax
                   call j_LoadLibraryA
                   mov handle[ebx],eax
                   lea si,szCallMessageBoxA[ebx]
                   jmp short loc2
loc1:              push esi
                   push handle[ebx]
                   call j_GetProcAddress
                   lea edi,handle[ebx]
                   stosd
                   add esi,0ch            
loc2:      
                   cmp dword ptr [esi],0
                   jnz short loc1   
                   push 0
                   push 0
                   lea eax,szText[ebx]
                   push eax
                   push 0    
                   call handle[ebx]
                   retn
;------------------------
; 子程序 GetCurrAddr
; 免重定位
;-------------------------
GetCurrAddr        proc near
                   call $+5
loc3:
                   pop ebx
                   sub ebx,loc3
                   retn
GetCurrAddr        endp

handle             dd 0
hInstance          dd 0
szUser32_dll       db 'user32.dll',0
szCallMessageBoxA  db 'MessageBoxA',0
                   dd 0
szText             db 'HelloWorldPE',0
Entry              endp

                   END  Entry
