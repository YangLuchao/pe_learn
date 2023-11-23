;---------------------------------
; miniPE程序(133字节)
;
; 该程序使用Borland公司的Tasm编译器和链接器
; Tasm /m minipe.asm
; Tlink /t /3 minipe, minipe.exe       
; 2011.2.19
;--------------------------------

          .386



;标号    代码        字段名               字段类型与值定义      解释                                   字节码               
;-------------------------------------------------------------------------------------------------------------------------------------------

IBase    equ 400000h                                            ;常量，minipe.exe的基地址

             
HEADER   SEGMENT                                                ;定义一个段
         ASSUME CS:HEADER,FS:NOTHING,ES:HEADER,DS:HEADER

CodeBase:

               ;************** PE DOS 头 *****************

                DosSignature                dw 5a4dh            ;MZ标志                                 4D 5A
                                            dw 0ffffh           ;                                       FF FF

               ;************** PE 标准头 *****************

                WinSignature                dd 4550h            ;PE标志                                 50 45 00 00
                Machine                     dw 014ch            ;Intel 80386                            4C 01       
                NumberOfSections            dw 1                ;节的个数                               01 01                
                  ;TimeDateStamp            dd 0                ;任意数值 
                  ;PointerToSymbolTable     dd 0                ;任意数值
                  ;NumberOfSymbols          dd 0                ;任意数值
    user32                                  db "user32.dll",0   ;                                       75 73 65 72 33 32 2E 64 6C 6C 00
                                            db 0ffh             ;                                       FF
                SizeOfOptionalHeader        dw OptHeaderSize    ;可选头部大小                           40 01                           
                Characteristics             dw 010fh            ;机器标志                               0F 01

               ;************** PE 可选头 ****************

                Magic                       dw 10bh             ;                                       0B 01
                LinkerVersion               dw 0ffffh           ;任意数值                               FF FF
                ;SizeOfCode                 dd 0                ;任意数值                               
                ;SizeOfInitializedData      dd 0                ;任意数值                                
                ;SizeOfUninitializedData    dd 0                ;任意数值
                MessageBoxA                 db "MessageBoxA",0  ;                                       4D 65 73 73 61 67 65 42 6F 78 41 00                          
                AddressOfEntryPoint         dd start            ;初始代码地址                           44 00 00 00

;---------------------
; 程序在这里最终使用了
; 跳转指令jmp 00400018
; 执行MessageBoxA函数
;---------------------
next3:
                ;BaseOfCode                  dd 0               ;任意数值
                ;BaseOfData                  dd 0               ;任意数值   两个双字用以下代码代替
  dw  15ffh                                                     ;该指令为跳转指令                       FF 15
  dd  IBase+IAT1                                                ;                                       7C 00 40 00
  ret                                                           ;该指令为1个字节                        C3




                                             db 0ffh            ;                                       FF
                 ImageBase                   dd IBase           ;映象起始地址                           00 00 40 00
                 SectionAlignment            dd 4               ;PE标志(3ch位置=从4开始)                04 00 00 00
                 FileAlignment               dd 4               ;                                       04 00 00 00


;------------------
; 程序执行入口：
;------------------
start:
                 ;OperatingSystemVersion      dd 0ffffffffh     ;任意值
                 ;ImageVersion                dd 0ffffffffh     ;任意数值    两个双字用以下代码代替

  mov eax,offset IBase+MessageBoxA                              ;该指令为5个字节                        B8 20 00 40 00
  jmp short next1                                               ;该指令为2个字节                        EB 03
                                              db 0ffh                                                   FF
                                              dw 4                                                      04 00
next1:
  push 0                                                        ;两个指令字节,入口参数4                 6A 00            
  push eax                                                      ;一个指令字节,入口参数3                 50
  push eax                                                      ;一个指令字节,入口参数2                 50    
  jmp short next2                                               ;两个指令字节                           EB 20


                 ;SubsystemVersion           dd 0ffff0004h      ;Win32 4.0
                 ;Win32VersionValue          dd 0ffffffffh      ;任意数值
                 SizeOfImage                 dd IMAGE_SIZE      ;任意数值,要求大于SizeOfHeaders         89 00 00 00
                 SizeOfHeaders               dd PE_HEADER_SIZE  ;文件头大小                             85 00 00 00
                 OptHeaderSize=$-Magic
IAT:
                 CheckSum                    dd 0               ;任意数值,  OriginalFirstThunk          00 00 00 00
                 Subsystem                   dw 2               ;           TimeDateStamp               02 00
                 DllCharacteristics          dw 0ffh            ;                                       FF 00
                 SizeOfStackReserve          dd IAT1            ;(Virtual Size),   ForwarderChain       7C 00 00 00
                 SizeOfStackCommit           dd user32          ;(Virtual Address),Name1                0C 00 00 00
                 SizeOfHeapReserve           dd IAT1            ;(Raw Data Size),  FirstThunk           7C 00 00 00
                 SizeOfHeapCommit            dd user32          ;(Raw Data Offset)                      0C 00 00 00
next2:
                 ;LoaderFlags                dd 0ffffffffh      ;任意数值   一个双字用以下代码代替

  push 0                                                        ;两个指令字节,入口参数1                 6A 00 
  jmp short next3                                               ;两个指令字节,jmp _MessageBoxA          EB B8  

                 NumberOfRvaAndSizes         dd 2h              ;                                       02 00 00 00     

                ;************** 数据目录表 ****************

IAT1:
                 IDE_Export                  dd MessageBoxA-2,0 ;数据目录第一项，导出表                 1E 00 00 00 00 00 00 00
                 IDE_Import                  db IAT-CodeBase    ;数据目录第二项，导入表                 5C

                ;************ 数据目录表结束 **************
                ;************ PE文件头结束 ****************
                ;************ 整个PE文件结束 **************

                 PE_HEADER_SIZE=$                               ;取该符号偏移为PE文件头大小
                 IMAGE_SIZE=PE_HEADER_SIZE+4                    ;映像大小=PE文件头大小+文件对齐粒度

HEADER           ENDS
                 END 
                            
