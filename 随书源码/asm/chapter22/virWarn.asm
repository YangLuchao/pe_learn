;------------------------
; 功能：文件型病毒 提示器
;       关键代码将嵌入到notepad.exe文件节的间隙中
; 作者：戚利
; 开发日期：2010.7.1
;------------------------
    .386
    .model flat,stdcall
    option casemap:none

include    windows.inc
include    kernel32.inc
includelib kernel32.lib
include    ADVAPI32.inc
includelib ADVAPI32.lib



    .code
_ProtoRegCreateKey            typedef proto :dword,:dword,:dword
_ProtoRegSetValueEx           typedef proto :dword,:dword,:dword,:dword,:dword,:dword
_ProtoMessageBox              typedef proto :dword,:dword,:dword,:dword
_ProtoGetWindowsDirectory     typedef proto :dword,:dword
_ProtoGetModuleFileName       typedef proto :dword,:dword,:dword
_ProtoCopyFile                typedef proto :dword,:dword,:dword
_ProtoCreateFile              typedef proto :dword,:dword,:dword,:dword,:dword,:dword,:dword
_ProtoGetFileSize             typedef proto :dword,:dword
_ProtoCreateFileMapping       typedef proto :dword,:dword,:dword,:dword,:dword,:dword
_ProtoDeleteFile              typedef proto :dword


_ApiRegCreateKey              typedef ptr _ProtoRegCreateKey
_ApiRegSetValueEx             typedef ptr _ProtoRegSetValueEx
_ApiMessageBox                typedef ptr _ProtoMessageBox
_ApiGetWindowsDirectory       typedef ptr _ProtoGetWindowsDirectory
_ApiGetModuleFileName         typedef ptr _ProtoGetModuleFileName
_ApiCopyFile                  typedef ptr _ProtoCopyFile
_ApiCreateFile                typedef ptr _ProtoCreateFile
_ApiGetFileSize               typedef ptr _ProtoGetFileSize
_ApiCreateFileMapping         typedef ptr _ProtoCreateFileMapping
_ApiDeleteFile                typedef ptr _ProtoDeleteFile


lpszKey             db   'SOFTWARE\MICROSOFT\WINDOWS\CURRENTVERSION\Run',0  
lpszValueName       db   'note',0  
lpszValue           db   'virNote.exe',0  
hKey                dd   ?
hFile               dd   ?
hMapFile            dd   ?
lpMemory            dd   ?   ;内存中文件指针

hDllADVAPI32        dd   ?   ;存放advapi32.dll句柄
hDllUser32          dd   ?   ;存放user32.dll句柄
hDllKernel32        dd   ?   ;存放kernel32.dll句柄


@destFile           db   50h dup(0)
szBuffer            db   50h dup(0)
dwFileSize          dd   ?   ;存放文件大小
_dwSize             dd   ?

_RegCreateKey             _ApiRegCreateKey           ?
_RegSetValueEx            _ApiRegSetValueEx          ?
_MessageBox               _ApiMessageBox             ?
_GetWindowsDirectory      _ApiGetWindowsDirectory    ?
_GetModuleFileName        _ApiGetModuleFileName      ?
_CopyFile                 _ApiCopyFile               ?
_CreateFile               _ApiCreateFile             ?
_GetFileSize              _ApiGetFileSize            ?
_CreateFileMapping        _ApiCreateFileMapping      ?
_DeleteFile               _ApiDeleteFile             ?


szADVAPI32               db  'ADVAPI32.dll',0
szUser32                 db  'USER32.dll',0
szKernel32               db  'KERNEL32.dll',0
szRegCreateKey           db  'RegCreateKeyA',0        ;该方法在ADVAPI32.dll中
szRegSetValueEx          db  'RegSetValueExA',0       ;该方法在ADVAPI32.dll中
szMessageBox             db  'MessageBoxA',0          ;该方法在USER32.dll中
szGetWindowsDirectory    db  'GetWindowsDirectoryA',0 ;以下方法在KERNEL32.dll中
szGetModuleFileName      db  'GetModuleFileNameA',0
szCopyFile               db  'CopyFileA',0
szCreateFile             db  'CreateFileA',0
szGetFileSize            db  'GetFileSize',0
szCreateFileMapping      db  'CreateFileMappingA',0
szDeleteFile             db  'DeleteFileA',0

lpszTitle         db  '文件病毒提示器-by qixiaorui',0
lpszMessage       db  '请注意！您的机器在上一次使用时可能已经感染了文件型病毒！',0
lpszNewName       db  '\virNote_Bak.exe',0


start:
    call @F
@@: 
    pop ebp
    sub ebp,offset @B
    
    ;首先获取ADVAPI32.dll、kernel32.dll和user32.dll的基址

    lea eax,[ebp+szADVAPI32]
    push eax
    call LoadLibrary              ;！！！！！！！！！需要修正
    mov [ebp+hDllADVAPI32],eax

    lea eax,[ebp+szUser32]
    push eax
    call LoadLibrary              ;！！！！！！！！！需要修正
    mov [ebp+hDllUser32],eax

    lea eax,[ebp+szKernel32]
    push eax
    call LoadLibrary              ;！！！！！！！！！需要修正
    mov [ebp+hDllKernel32],eax
    
    ;获得几个函数的内存地址
    lea eax,[ebp+szRegCreateKey]
    push eax
    mov eax,[ebp+hDllADVAPI32]
    push eax
    call GetProcAddress           ;！！！！！！！！！需要修正
    mov [ebp+_RegCreateKey],eax

    lea eax,[ebp+szRegSetValueEx]
    push eax
    mov eax,[ebp+hDllADVAPI32]
    push eax
    call GetProcAddress           ;！！！！！！！！！需要修正
    mov [ebp+_RegSetValueEx],eax
   
    lea eax,[ebp+szMessageBox]
    push eax
    mov eax,[ebp+hDllUser32]
    push eax
    call GetProcAddress           ;！！！！！！！！！需要修正
    mov [ebp+_MessageBox],eax

    lea eax,[ebp+szGetWindowsDirectory]
    push eax
    mov eax,[ebp+hDllKernel32]
    push eax
    call GetProcAddress           ;！！！！！！！！！需要修正
    mov [ebp+_GetWindowsDirectory],eax

    lea eax,[ebp+szGetModuleFileName]
    push eax
    mov eax,[ebp+hDllKernel32]
    push eax
    call GetProcAddress           ;！！！！！！！！！需要修正
    mov [ebp+_GetModuleFileName],eax
   
    lea eax,[ebp+szCopyFile]
    push eax
    mov eax,[ebp+hDllKernel32]
    push eax
    call GetProcAddress           ;！！！！！！！！！需要修正
    mov [ebp+_CopyFile],eax

    lea eax,[ebp+szCreateFile]
    push eax
    mov eax,[ebp+hDllKernel32]
    push eax
    call GetProcAddress           ;！！！！！！！！！需要修正
    mov [ebp+_CreateFile],eax

    lea eax,[ebp+szGetFileSize]
    push eax
    mov eax,[ebp+hDllKernel32]
    push eax
    call GetProcAddress           ;！！！！！！！！！需要修正
    mov [ebp+_GetFileSize],eax

    lea eax,[ebp+szCreateFileMapping]
    push eax
    mov eax,[ebp+hDllKernel32]
    push eax
    call GetProcAddress           ;！！！！！！！！！需要修正
    mov [ebp+_CreateFileMapping],eax

    lea eax,[ebp+szDeleteFile]
    push eax
    mov eax,[ebp+hDllKernel32]
    push eax
    call GetProcAddress           ;！！！！！！！！！需要修正
    mov [ebp+_DeleteFile],eax


    ;将值写入注册表   
    lea eax,[ebp+hKey]
    push eax
    lea eax,[ebp+lpszKey]
    push eax
    push HKEY_LOCAL_MACHINE
    call [ebp+_RegCreateKey]
    mov eax,0Ch
    push eax
    lea eax,[ebp+lpszValue]
    push eax
    mov eax,REG_SZ
    push eax
    xor eax,eax
    push eax
    lea eax,[ebp+lpszValueName]
    push eax
    mov eax,[ebp+hKey]
    push eax
    call [ebp+_RegSetValueEx]
    mov eax,[ebp+hKey]
    push eax
    call RegCloseKey             ;！！！！！！！！！需要修正

    ;获取进程所在的目录
    mov eax,50h
    push eax
    lea eax,[ebp+szBuffer]
    push eax
    call [ebp+_GetWindowsDirectory]

    mov esi,0
    mov edi,0
    .while TRUE
        mov al,byte ptr [ebp+szBuffer+esi]
        .break .if al==0
        mov byte ptr [ebp+@destFile+edi],al
        inc esi
        inc edi
    .endw
    mov esi,0
    .while TRUE
        mov al,byte ptr [ebp+lpszNewName+esi]
        .break .if al==0
        mov byte ptr [ebp+@destFile+edi],al
        inc esi
        inc edi
    .endw
    mov byte ptr [ebp+@destFile+edi],0

    ;取当前程序运行路径c:\winnt\virNote.exe
    mov eax,50h
    push eax
    lea eax,[ebp+szBuffer]
    push eax
    xor eax,eax
    push eax
    call [ebp+_GetModuleFileName]

    ;将当前程序运行文件szBuffer拷贝到系统目录@destFile
    mov eax,FALSE
    push eax
    lea eax,[ebp+@destFile]
    push eax
    lea eax,[ebp+szBuffer]
    push eax
    call [ebp+_CopyFile]

    ;打开命名后的新文件@destFile
    push NULL
    mov eax,FILE_ATTRIBUTE_ARCHIVE
    push eax
    mov eax,OPEN_EXISTING
    push eax
    push NULL
    mov eax,FILE_SHARE_READ or FILE_SHARE_WRITE
    push eax
    mov eax,GENERIC_READ
    push eax
    lea eax,[ebp+@destFile]
    push eax
    call [ebp+_CreateFile]

    mov [ebp+hFile],eax   ;将文件句柄送入相应变量

    push NULL
    push eax
    call [ebp+_GetFileSize]
    mov [ebp+dwFileSize],eax

    ;建立内存映射
    xor eax,eax
    push eax
    push eax
    push eax
    mov eax,PAGE_READONLY
    push eax
    xor eax,eax
    push eax
    mov eax,[ebp+hFile]
    push eax
    call [ebp+_CreateFileMapping]
    mov [ebp+hMapFile],eax

    ;将文件映射到内存
    xor eax,eax
    push eax
    push eax
    push eax
    mov eax,FILE_MAP_READ
    push eax
    mov eax,[ebp+hMapFile]
    push eax
    call MapViewOfFile         ;！！！！！！！！！需要修正
    mov [ebp+lpMemory],eax     ;获得文件在内存映象的起始位置

    mov esi,[ebp+lpMemory]
    add esi,3ch  
    mov esi,dword ptr [esi]
    add esi,[ebp+lpMemory]     
    push esi
    pop edi                    ;esi和edi都指向PE头

    movzx ecx,word ptr [esi+6h] ;获取节的数量  
    mov eax,sizeof IMAGE_NT_HEADERS
    add edi,eax                ;edi指向节目录
    
    ;计算节目录数据的总长度
    mov eax,sizeof IMAGE_SECTION_HEADER
    xor edx,edx
    mul ecx
    xchg eax,ecx               ;ecx中为节目录数据的总长度
    
    ;计算从edi指向的ecx个长度的字节的校验和
_calcCheckSum:
 
    mov [ebp+_dwSize],ecx
    push esi
    shr ecx,1
    xor ebx,ebx
    mov esi,edi

    cld
@@:
    lodsw
    movzx eax,ax
    add ebx,eax
    loop @B
    test [ebp+_dwSize],1
    jz @F
    lodsb
    movzx eax,al
    add ebx,eax
@@:
    mov eax,ebx
    and eax,0ffffh
    shr ebx,16
    add eax,ebx
    not ax
    pop esi


    mov bx,word ptr [esi+4ch]   ;此处存放着原始的校验和
    sub ax,bx
    jz _ret
    
    ;显示提示信息
    xor eax,eax
    push eax
    lea eax,[ebp+lpszTitle]
    push eax
    lea eax,[ebp+lpszMessage]
    push eax
    push NULL
    call [ebp+_MessageBox]

_ret:
    ;关闭文件
    mov eax,[ebp+lpMemory]   
    push eax
    call UnmapViewOfFile       ;！！！！！！！！！需要修正
 
    mov eax,[ebp+hMapFile]
    push eax
    call CloseHandle           ;！！！！！！！！！需要修正

    mov eax,[ebp+hFile]
    push eax
    call CloseHandle           ;！！！！！！！！！需要修正

    ;删除文件
    lea eax,[ebp+@destFile]
    push eax
    call [ebp+_DeleteFile]

    ret
    ;此处已无用，不需要程序
    mov eax,12345678h
    org $-4
OldEIP  dd  00001000h
    add eax,12345678h
    org $-4
ModBase dd  00400000h
    jmp eax
    end start
