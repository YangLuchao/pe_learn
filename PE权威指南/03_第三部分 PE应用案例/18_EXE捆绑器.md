[toc]

从本章开始，将围绕PE文件从不同角度分析几个应用实例。其中除了第20章的EXE加锁器采用了第16章介绍的补丁工具外，其他几个实例均采用第17章介绍的补丁工具，完成对目标PE的静态补丁操作。

本书8.4节介绍了一种通过附加资源文件的方式对文件进行捆绑的例子。本章使用补丁技术编写一个小工具，该工具可以将某个目录中的所有相关文件（含子目录中的文件）捆绑在一起，捆绑前还可以定义要运行的EXE序列。

==EXE捆绑器允许用户将多个可执行文件及相关文件捆绑到一起，通过运行捆绑程序实现多个可执行文件的依次执行==。本章将研究这种应用的编程方法。

# 18.1　基本思路

==EXE捆绑是指将两个或多个可执行文件和非执行文件捆绑到一起的技术==。捆绑的目的有三个：

1. ==减少某个待发布系统的独立文件的个数。==
2. ==隐藏某些特殊用途的文件。==
3. ==实现一些特殊功能，如本案例中通过捆绑实现了多个程序的顺序执行。==

==EXE捆绑器结合EXE加锁器（本书第20章讲述的内容）可以用于加密文件夹或文件==。==因为在捆绑过程中，可以指定被捆绑的文件中哪些需要运行，所以，该捆绑器还可以用于运行多个PE文件的批处理，通过依次运行多个文件（结合本书第19章讲述的软件安装自动化技术）则可以实现多个补丁的自动安装==。

==捆绑的实现方法有很多种，其中最常见有两种方法==：

1. 1）==通过编写一个新的EXE程序，把要捆绑的所有文件以资源的方式进行，或者直接写在文件末尾来进行，运行时只需将文件提取出来依次运行即可==。
2. 2）==通过直接修改第一个PE程序，将其他文件作为资源或直接写在文件末尾，通过在第一个PE程序中设置补丁程序的方式，依次运行多个程序==。

本章将讲解第一种捆绑方法。

以下是本章要用到的几个程序，以及每个程序的相关说明：

`hex2db`：==将字节码转变为汇编语言数据定义语句的小工具==。

`_host.exe`：==调度执行程序的模板，该文件最终嵌入到宿主程序中==。

`host.exe`：==宿主程序。是补丁程序的目标，用于存储`_host.exe`和其他要捆绑的文件==。

`bind.exe`：==捆绑器。负责执行捆绑，类似于进阶部分的补丁工具==。

# 18.2　EXE执行调度机制

大部分情况下，被捆绑的文件集合中只有一个EXE文件是主运行文件。但也有例外，比如，有的用户会将多个程序捆绑起来，然后依次安装这些程序以提高计算机的安全性能，这时候就要用到EXE执行调度。==EXE执行调度就是在捆绑前，指定补丁程序中要安装的程序的运行顺序，当被捆绑的程序被释放出来后，还要有一个进程专门负责调度这些程序按照先后顺序依次运行==。==要实现EXE同步执行，需要使用两个Windows API函数，它们分别是==：

1. ==`CreateProcess`（创建进程函数）==
2. ==`WaitForSingleObject`（等待指定进程结束）==

## 18.2.1　相关API函数

==EXE执行调度过程其实就是一个控制多个进程同步执行的过程==。==Windows API函数中给出了两个与进程控制有关的函数==：

1. ==创建进程函数`CreateProcess`==
2. ==等待进程结束函数`WaitForSingleObject`==

### 1.创建进程函数`CreateProcess`

==该函数用于完成一个进程的创建工作==，函数原型定义如下：

------

```c
BOOL CreateProcess(
	LPCTSTR lpApplicationName,
	LPTSTR lpCommandLine,
	LPSECURITY_ATTRIBUTES lpProcessAttributes。
	LPSECURITY_ATTRIBUTES lpThreadAttributes,
	BOOL bInheritHandles,
	DWORD dwCreationFlags,
	LPVOID lpEnvironment,
	LPCTSTR lpCurrentDirectory,
	LPSTARTUPINFO lpStartupInfo,
	LPPROCESS_INFORMATION lpProcessInformation
);
```

------

函数参数解释如下：

**1）**`lpApplicationName`：==指向一个NULL结尾的、用来指定可执行模块的字符串==。==这个字符串可以是可执行模块的绝对路径，也可以是相对路径==；==在后一种情况下，函数使用当前驱动器和目录建立可执行模块的路径==。==如果该参数被设为NULL，可执行模块的名字必须处于`lpCommandLine`参数的最前面，并由空格符与后面的字符分开==。被指定的模块可以是一个Win32应用程序，如果适当的子系统在当前计算机上可用的话，它也可以是其他类型的模块（如MS-DOS或OS/2）。在Windows NT中，如果可执行模块是一个16位的应用程序，那么这个参数应该设置为NULL，并且应该在lpCommandLine参数中指定可执行模块的名称。

**2）**`lpCommandLine`：==指向一个NULL结尾的、用来指定要运行的程序的命令行==。==如果该参数为空，那么函数将使用参数指定的字符串当做要运行的程序的命令行==。==如果`lpApplicationName`和`lpCommandLine`参数都不为空，那么`lpApplicationName`参数指定将要被运行的模块，`lpCommandLine`参数则指定将被运行的模块的命令行==。==新运行的进程可以使用`GetCommandLine`函数获得整个命令行==。==如果文件名不包含扩展名，那么.exe将被假定为默认的扩展名==。如果文件名以一个点（.）结尾且没有扩展名，或文件名中包含路径，.exe将不会被加到后面。如果文件名中不包含路径，Windows将按照如下顺序寻找这个可执行文件：

1. 当前应用程序的目录。
2. 父进程的目录。
3. Windows系统目录，可以使用GetSystemDirectory函数获得。
4. Windows目录，可以使用GetWindowsDirectory函数获得这个目录。
5. 列在PATH环境变量中的目录。

**3）**`lpProcessAttributes`：==指向一个`SECURITY_ATTRIBUTES`结构体，这个结构体决定是否返回的句柄可以被子进程继承==。==如果`lpProcessAttributes`参数为空（NULL），那么句柄不能被继承==。在Windows NT中，`SECURITY_ATTRIBUTES`结构的`lpSecurityDescriptor`成员指定了新进程的安全描述符，如果参数为空，新进程使用默认的安全描述符。

**4）**`lpThreadAttributes`：==指向一个`SECURITY_ATTRIBUTES`结构体，这个结构体决定是否返回的句柄可以被子进程继承==。==如果`lpThreadAttributes`参数为空（NULL），那么句柄不能被继承==。`SECURITY_ATTRIBUTES`结构的`lpSecurityDescriptor`成员指定了主线程的安全描述符，如果参数为空，主线程使用默认的安全描述符。

**5）**`bInheritHandles`：==指示新进程是否从调用进程处继承了句柄==。如果参数的值为TRUE，调用进程中的每一个可继承的打开句柄都将被子进程继承。被继承的句柄与原进程拥有完全相同的值和访问权限。

**6）**`dwCreationFlags`：==指定附加的、用来控制优先级和进程的创建标志==。该标志可以使用下面列出的方式的任意组合后指定。

- `CREATE_DEFAULT_ERROR_MODE`。新的进程不继承调用进程的错误模式，而使用当前默认的错误模式。应用程序可以调用SetErrorMode函数设置当前的默认错误模式。这个标志对于那些运行在没有硬件错误环境下的多线程外壳程序是十分有用的。对于CreateProcess函数，默认的行为是让新进程继承调用者的错误模式。
- `CREATE_NEW_CONSOLE`。新的进程将使用一个新的控制台，而不是继承父进程的控制台。这个标志不能与DETACHED_PROCESS标志一起使用。
- `CREATE_NEW_PROCESS_GROUP`。新进程将使一个进程树的根进程，进程树中的全部进程都是根进程的子进程。新进程树的用户标识符与这个进程的标识符是相同的，由lpProcessInformation参数返回。进程树经常使用GenerateConsoleCtrlEvent函数允许发送CTRL+C或CTRL+BREAK信号到一组控制台进程。
- `CREATE_SEPARATE_WOW_VDM`。这个标志只有当运行一个16位的Windows应用程序时才是有效的（只适用于Windows NT）。如果被设置，新进程将会在一个私有的虚拟DOS机（VDM）中运行。另外，默认情况下，所有的16位Windows应用程序都会在同一个共享的VDM中以线程的方式运行。单独运行一个16位程序的优点是：一个应用程序的崩溃只会结束这一个VDM的运行，其他那些在不同VDM中运行的程序会继续正常地运行。同样，在不同VDM中运行的16位Windows应用程序拥有不同的输入队列，这意味着，如果一个程序暂时失去响应，在独立的VDM中的应用程序能够继续获得输入。
- `CREATE_SHARED_WOW_VDM`。这个标志只有当运行一个16位的Windows应用程序时才是有效的（只适用于Windows NT）。如果win.ini中的Windows段的DefaultSeparateVDM选项被设置为真，这个标志使得CreateProcess函数越过这个选项，并在共享的虚拟DOS机中运行新进程。
- `CREATE_SUSPENDED`。新进程的主线程会以暂停的状态被创建，直到调用ResumeThread函数才被唤醒得以继续运行。
- `CREATE_UNICODE_ENVIRONMENT`。如果被设置，由lpEnvironment参数指定的环境块使用Unicode字符；如果为空，环境块使用ANSI字符。
- `DEBUG_PROCESS`。如果被设置，调用进程将被当做一个调试程序，并且新进程会被当做被调试的进程。系统把被调试程序发生的所有调试事件通知给调试器。如果你使用这个标志创建进程，只有调用进程（调用CreateProcess函数的进程）可以调用WaitForDebugEvent函数，动态补丁技术中经常会使用该标志打开一个调试进程。
- `DEBUG_ONLY_THIS_PROCESS`。如果此标志没有被设置，且调用进程正在被调试，新进程将成为调试调用进程的调试器的另一个调试对象。如果调用进程没有被调试，有关调试的行为就不会产生。
- `DETACHED_PROCESS`。对于控制台进程，新进程没有访问父进程控制台的权限。新进程可以通过AllocConsole函数自己创建一个新的控制台。这个标志不可以与CREATE_NEW_CONSOLE标志一起使用。

`dwCreationFlags`参数还用来控制新进程的优先级等级。常用的优先级标志有四个：

- `IDLE_PRIORITY_CLASS`只有在CPU时间将被浪费掉时（空闲时间）才执行，适合于系统监视软件、屏保等。
- `NORMAL_PRIORITY_CLASS`默认等级。当进程变成前台进程时，线程优先级提升为9，进程变成后台时，降为7。
- `HIGH_PRIORITY_CLASS`为了满足立即反应需要，例如，当使用者按下Ctrl+Esc时立即把工作管理器调出。
- `REALTIME_PRIORITY_CLASS`几乎不会被一般的应用程序使用。这种等级只有在“如果不在某个时间范围内执行数据就要遗失”的情况下使用。因此，使用要慎重。如果把这样的等级指定给一般的线程，那么多任务环境可能会瘫痪，因为这个线程有如此高的优先级，其他进程再没有机会执行。

如果上面的优先级标志都没有被指定，那么默认的优先级是`NORMAL_PRIORITY_CLASS`，除非被创建的进程是`IDLE_PRIORITY_CLASS`。在这种情况下，子进程的默认优先级是`IDLE_PRIORITY_CLASS`。

**7）**`lpEnvironment`：==指向一个新进程的环境块==。==如果此参数为空，新进程使用调用进程的环境==。一个环境块存在于一个以NULL结尾的字符串组成的块中，这个块也是以NULL结尾的。每个字符串都是name=value的形式。因为相等标志被当做分隔符，所以它不能被环境变量当做变量名。与其使用应用程序提供的环境块，不如直接把这个参数设为空，系统驱动器上的当前目录信息不会被自动传递给新创建的进程。环境块可以包含Unicode或ANSI字符。如果`lpEnvironment`指向的环境块包含`Unicode`字符，那么dwCreationFlags字段的`CREATE_UNICODE_ENVIRONMENT`标志将被设置；如果块包含ANSI字符，该标志将被清空。

> 注意　==一个ANSI环境块是由两个0字节结束的：一个是字符串的结尾，另一个用来结束这个块==。==一个Unicode环境块是则由四个0字节结束的：两个代表字符串结束，另外两个用来结束块==。

**8）**`lpCurrentDirectory`：==指向一个以NULL结尾的字符串，这个字符串用来指定子进程的工作路径，并且必须是一个包含驱动器名的绝对路径==。==如果这个参数为空，新进程将使用与调用进程相同的驱动器和目录==。

**9）**`lpStartupInfo`：==指向一个用于决定新进程的主窗体如何显示的`STARTUPINFO`结构体==。

**10）**`lpProcessInformation`：==指向一个用来接收新进程的识别信息的`PROCESS_INFORMATION`结构体==。

==`CreateProcess`函数用来运行一个新程序==；==`WinExec`和`LoadModule`函数也可以实现相同的功能，但是它们最终还是通过调用`CreateProcess`函数实现的==。==另外`CreateProcess`函数除了创建一个进程，还创建一个线程对象==。==这个线程将连同一个已初始化了的栈一起被创建，栈的大小由可执行文件的文件头中的描述决定，线程由文件头指定的入口地址处开始执行==。

==新进程和新线程的句柄是被当成全局变量创建的，对于这两个句柄中的任意一个，如果没有安全描述符，那么这个句柄就可以在任何需要句柄类型作为参数的函数中使用==。==当提供安全描述符时，在接下来当句柄被使用时，总是会先进行访问权限的检查==；==如果访问权限检查拒绝访问，请求的进程将不能使用这个句柄访问这个进程==。

### 2.等待进程结束函数`WaitForSingleObject`

==`WaitForSingleObject`函数用来检测`hHandle`事件的信号状态==。==当函数的执行时间超过`dwMilliseconds`就返回==；==但如果参数`dwMilliseconds`为`INFINITE`，将在相应时间事件变成有信号状态时函数才返回，否则就一直等待下去，直到`WaitForSingleObject`有返回值才执行后面的代码==。函数原型定义如下：

------

```c
DWORD WaitForSingleObject(
	HANDLE hHandle,
	DWORD dwMilliseconds
);
```

------

函数参数解释如下：

**1）**`hHandle`：一个对象的句柄。这些对象包括：Change notification、Console input、Event、Job、Memory resource notification、Mutex、Process、Semaphore、Thread、Waitable timer。

**2）**`dwMilliseconds`：==时间间隔==。如果时间是有信号状态，返回`WAIT_OBJECT_0`；如果时间超过`dwMilliseconds`值，但时间事件还是无信号状态，则返回`WAIT_TIMEOUT`。

## 18.2.2　控制进程同步运行实例分析

本节根据对操作系统进程管理的理解，介绍使用Windows API函数实现控制进程同步运行的实例，==以帮助大家更加深入地理解多个应用程序依次被执行调度的过程==。

代码清单18-1 简单地模拟了捆绑被释放以后，各个程序的同步运行效果。

代码清单18-1 ==测试多个进程同步运行的实例==（chapter18\multiProcess.asm）

------

```assembly
;------------------------------------
; 测试执行多个进程的文件
; multiProcess.asm
;-------------------------------------

.386
.model flat,stdcall
option casemap:none

include    windows.inc
include    user32.inc
include    kernel32.inc
include    winResult.inc
includelib user32.lib
includelib kernel32.lib
includelib winResult.lib



TOTAL_FILE_COUNT  equ   100        ;本程序所绑定文件的最大数
BinderFileStruct  STRUCT
  inExeSequence   byte   ?         ;为0表示非执行文件，为1表示加入执行序列
  dwFileOff       dword   ?        ;在宿主中的起始偏移
  dwFileSize      dword    ?       ;文件大小
  name            db   256 dup(0)  ;文件名，含子目录
BinderFileStruct  ENDS


.data
hRunThread  dd ?
stStartUp	STARTUPINFO		<?>
stProcInfo	PROCESS_INFORMATION	<?> 

dwTotalFile     dd  TOTAL_FILE_COUNT    ;文件总数
bindFileList    BinderFileStruct TOTAL_FILE_COUNT dup(<?>)

.const
szExeFile   db 'd:\masm32\source\chapter15\notepad.exe',0
szExeFile1  db 'd:\masm32\source\chapter15\mspaint.exe',0


.code

;------------------------------------------
; 执行程序用的线程
; 1. 用 CreateProcess 建立进程
; 2. 用 WaitForSingleOject 等待进程结束
;-------------------------------------------
_RunThread	proc	uses ebx ecx edx esi edi,\
		dwParam:DWORD
   pushad
   invoke GetStartupInfo,addr stStartUp
   invoke CreateProcess,NULL,addr szExeFile,NULL,NULL,\
            NULL,NORMAL_PRIORITY_CLASS,NULL,NULL,offset stStartUp,offset stProcInfo
   .if eax!=0
     invoke WaitForSingleObject,stProcInfo.hProcess,INFINITE
     invoke CloseHandle,stProcInfo.hProcess
     invoke CloseHandle,stProcInfo.hThread
   .endif
   invoke GetStartupInfo,addr stStartUp
   invoke CreateProcess,NULL,addr szExeFile1,NULL,NULL,\
            NULL,NORMAL_PRIORITY_CLASS,NULL,NULL,offset stStartUp,offset stProcInfo
   .if eax!=0
     invoke WaitForSingleObject,stProcInfo.hProcess,INFINITE
     invoke CloseHandle,stProcInfo.hProcess
     invoke CloseHandle,stProcInfo.hThread
   .endif
   popad
   ret
_RunThread	endp

start:
  invoke  CreateThread,NULL,NULL,offset _RunThread,\
                  NULL,NULL,offset hRunThread
  end start
```

------

==主程序通过函数`CreateThread`把调度函数`_RunThread`当成一个线程来运行（行76）。调度函数首先通过`CreateProcess`打开一个程序（行54）；然后，调用函数`WaitForSingleObject`等待进程结束（行58）。第一个程序结束后，继续使用`CreateProcess`打开第二个程序，使用`WaitForSingleObject`等待第二个程序的结束，依次类推==。

==执行程序后，首先打开记事本程序，无论你如何操作，均会等待记事本程序退出后（选择菜单“文件”|“退出”选项或者直接选择标题栏最右端的关闭按钮退出记事本），才打开第二个程序“画图”==。

# 18.3　字节码转换工具hex2db

==执行调度的代码会以字节码定义的方式（使用伪指令db语句）嵌入到源码中==。==这些字节码可以通过FlexHex复制获得，但转换起来特别麻烦。为了方便后续的开发，本节编写一个小工具hex2db，该工具实现了将文件中的字节码转换为汇编语言字节定义的方式==。

例如，文件中的以下字节码：

------

```
00 01 02 03 04 A5
```

------

利用小工具hex2db最终转换为：

------

```
db 00h,01h,02h,03h,04h,0A5h
```

------

数据定义该语句包括三部分：

1. 前置空格。本例中有四个空格。
2. 数据定义伪指令db。db和数据之间有一个空格。
3. 数据。以逗号分隔，如果某个字节的高八位超过0ah，则在该字节前添加一个“0”。

下面来看源代码。

## 18.3.1　hex2db源代码

hex2db的编写思路与第2章的小工具PEDump雷同，两者都是以控制输出格式为核心。hex2db的源代码见代码清单18-2。

代码清单18-2　字节码到汇编语言数据定义语句的转换（chapter18\hex2db.asm）

------

```assembly
.386
.model flat,stdcall
option casemap:none

include    windows.inc
include    user32.inc
include    kernel32.inc
include    gdi32.inc
include    comctl32.inc
include    comdlg32.inc
include    advapi32.inc
include    shell32.inc
include    masm32.inc
include    netapi32.inc
include    winmm.inc
include    ws2_32.inc
include    psapi.inc
include    mpr.inc        ;WNetCancelConnection2
include    iphlpapi.inc   ;SendARP
include    winResult.inc
includelib comctl32.lib
includelib comdlg32.lib
includelib gdi32.lib
includelib user32.lib
includelib kernel32.lib
includelib advapi32.lib
includelib shell32.lib
includelib masm32.lib
includelib netapi32.lib
includelib winmm.lib
includelib ws2_32.lib
includelib psapi.lib
includelib mpr.lib
includelib iphlpapi.lib
includelib winResult.lib



.data
hInstance   dd ?
hRichEdit   dd ?
hWinMain    dd ?
hWinEdit    dd ?
dwCount     dd ?
dwColorRed  dd ?
hText1      dd ?
hText2      dd ?
hFile       dd ?
dwNewFileCount dd ?
lpDstMemory    dd ?


dwNewFileSize     dd  ?     ;新文件大小=目标文件大小+补丁代码大小

szFileName           db MAX_PATH dup(?)
szDstFile            db 'c:\1.txt',0
szFileNameOpen1      db '_host.exe',MAX_PATH dup(0)
szFileNameOpen2      db 'c:\notepad.exe',MAX_PATH dup(0)

                     ;d:\masm32\source\chapter12\HelloWorld.exe

szBuffer         db  256 dup(0),0
bufTemp1         db  200 dup(0),0
bufTemp2         db  200 dup(0),0
szFilter1        db  'Excutable Files',0,'*.exe;*.com',0
                 db  0

.const

lpszHexArr  db  '0123456789ABCDEF',0


.code

;------------------
; 错误Handler
;------------------
_Handler proc _lpExceptionRecord,_lpSEH,\
              _lpContext,_lpDispathcerContext

  pushad
  mov esi,_lpExceptionRecord
  mov edi,_lpContext
  assume esi:ptr EXCEPTION_RECORD,edi:ptr CONTEXT
  mov eax,_lpSEH
  push [eax+0ch]
  pop [edi].regEbp
  push [eax+8]
  pop [edi].regEip
  push eax
  pop [edi].regEsp
  assume esi:nothing,edi:nothing
  popad
  mov eax,ExceptionContinueExecution
  ret
_Handler endp

;--------------------------
; 将_lpPoint位置处_dwSize个字节转换为16进制的字符串
; bufTemp1处为转换后的字符串
;--------------------------
_Byte2Hex     proc _dwSize
  local @dwSize:dword

  pushad
  mov esi,offset bufTemp2
  mov edi,offset bufTemp1
  mov @dwSize,0
  .repeat
    mov al,byte ptr [esi]

    mov bl,al
    xor edx,edx
    xor eax,eax
    mov al,bl
    mov cx,16
    div cx   ;结果高位在al中，余数在dl中


    xor bx,bx
    mov bl,al
    movzx edi,bx
    mov bl,byte ptr lpszHexArr[edi]
    mov eax,@dwSize
    mov byte ptr bufTemp1[eax],bl


    inc @dwSize

    xor bx,bx
    mov bl,dl
    movzx edi,bx

    ;invoke wsprintf,addr szBuffer,addr szOut2,edx
    ;invoke MessageBox,NULL,addr szBuffer,NULL,MB_OK

    mov bl,byte ptr lpszHexArr[edi]
    mov eax,@dwSize
    mov byte ptr bufTemp1[eax],bl

    inc @dwSize
    mov bl,20h
    mov eax,@dwSize
    mov byte ptr bufTemp1[eax],bl
    inc @dwSize
    inc esi
    dec _dwSize
    .break .if _dwSize==0
   .until FALSE

   mov bl,0
   mov eax,@dwSize
   mov byte ptr bufTemp1[eax],bl

   popad
   ret
_Byte2Hex    endp

_MemCmp  proc _lp1,_lp2,_size
   local @dwResult:dword

   pushad
   mov esi,_lp1
   mov edi,_lp2
   mov ecx,_size
   .repeat
     mov al,byte ptr [esi]
     mov bl,byte ptr [edi]
     .break .if al!=bl
     inc esi
     inc edi
     dec ecx
     .break .if ecx==0
   .until FALSE
   .if ecx!=0
     mov @dwResult,1
   .else 
     mov @dwResult,0
   .endif
   popad
   mov eax,@dwResult
   ret
_MemCmp  endp

;--------------
;
;--------------------
writeToFile proc _lpFile,_dwSize
  local @dwWritten
  pushad
  invoke CreateFile,addr szDstFile,GENERIC_WRITE,\
            FILE_SHARE_READ,\
                0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
  mov hFile,eax
  invoke WriteFile,hFile,_lpFile,_dwSize,addr @dwWritten,NULL
  invoke CloseHandle,hFile      
  popad
  ret
writeToFile endp


;--------------------
; 打开PE文件并处理
;--------------------
_openFile proc
  local @stOF:OPENFILENAME
  local @hFile,@dwFileSize,@hMapFile,@lpMemory
  local @hFile1,@dwFileSize1,@hMapFile1,@lpMemory1
  local @bufTemp1[10]:byte
  local @dwTemp:dword,@dwTemp1:dword
  local @dwBuffer,@lpDst,@hDstFile
  

  invoke CreateFile,addr szFileNameOpen1,GENERIC_READ,\
         FILE_SHARE_READ or FILE_SHARE_WRITE,NULL,\
         OPEN_EXISTING,FILE_ATTRIBUTE_ARCHIVE,NULL

  .if eax!=INVALID_HANDLE_VALUE
    mov @hFile,eax
    invoke GetFileSize,eax,NULL
    mov @dwFileSize,eax
    .if eax
      invoke CreateFileMapping,@hFile,\  ;内存映射文件
             NULL,PAGE_READONLY,0,0,NULL
      .if eax
        mov @hMapFile,eax
        invoke MapViewOfFile,eax,\
               FILE_MAP_READ,0,0,0
        .if eax
          mov @lpMemory,eax              ;获得文件在内存的映象起始位置
          assume fs:nothing
          push ebp
          push offset _ErrFormat
          push offset _Handler
          push fs:[0]
          mov fs:[0],esp

          ;检测PE文件是否有效
          mov esi,@lpMemory
          assume esi:ptr IMAGE_DOS_HEADER
          .if [esi].e_magic!=IMAGE_DOS_SIGNATURE  ;判断是否有MZ字样
            jmp _ErrFormat
          .endif
          add esi,[esi].e_lfanew    ;调整ESI指针指向PE文件头
          assume esi:ptr IMAGE_NT_HEADERS
          .if [esi].Signature!=IMAGE_NT_SIGNATURE ;判断是否有PE字样
            jmp _ErrFormat
          .endif
        .endif
      .endif
    .endif
  .endif



  ;到此为止，内存文件的指针已经获取到了。@lpMemory指向连个文件头


  ;求新文件大小
  mov eax,@dwFileSize
  shl eax,3
  mov dwNewFileSize,eax

  ;申请内存空间
  invoke GlobalAlloc,GHND,dwNewFileSize
  mov @hDstFile,eax
  invoke GlobalLock,@hDstFile
  mov lpDstMemory,eax   ;将指针给@lpDst

  mov dwCount,0
  mov esi,@lpMemory
  mov edi,lpDstMemory

  mov @dwTemp,0

  mov al,20h
  mov ecx,4
  rep stosb
  mov al,'d'
  stosb
  mov al,'b'
  stosb
  mov al,20h
  stosb
  add dwNewFileCount,7

  ;开始处理每一个字节
  .repeat
    xor eax,eax
    mov al,byte ptr [esi]
    inc esi

    ;先看是否为16的整数倍
    .if @dwTemp==16
       push eax
       mov @dwTemp,0
       dec edi
       dec dwNewFileCount
       mov al,0dh
       stosb
       mov al,0ah
       stosb
       mov al,20h
       mov ecx,4
       rep stosb
       mov al,'d'
       stosb
       mov al,'b'
       stosb
       mov al,20h
       stosb
       add dwNewFileCount,9
       pop eax

       ;处理字节
       xor edx,edx
       mov ecx,16
       div ecx
       mov ebx,eax
       ;处理高位

       .if al>9
         mov bl,'0'
         mov byte ptr [edi],bl
         inc edi
         inc dwNewFileCount
         mov al,[eax+lpszHexArr]
         stosb
       .else
         mov al,[eax+lpszHexArr]
         stosb
       .endif
       inc dwNewFileCount

       ;处理低位
       mov ebx,edx
       mov al,[ebx+lpszHexArr]
       stosb
       mov al,'h'
       stosb
       mov al,','
       stosb
       add dwNewFileCount,3
    .else
      ;处理字节
      xor edx,edx
      mov ecx,16
      div ecx
      mov ebx,eax
      ;处理高位

      .if al>9
        mov bl,'0'
        mov byte ptr [edi],bl
        inc edi
        inc dwNewFileCount
        mov al,[eax+lpszHexArr]
        stosb
      .else
        mov al,[eax+lpszHexArr]
        stosb
      .endif
      inc dwNewFileCount

      ;处理低位
      mov ebx,edx
      mov al,[ebx+lpszHexArr]
      stosb
      mov al,'h'
      stosb
      mov al,','
      stosb
      add dwNewFileCount,3
    .endif
    sub @dwFileSize,1
    inc @dwTemp
    .break .if @dwFileSize==0
  .until FALSE


  ;将新文件内容写入到c:\1.txt
  invoke writeToFile,lpDstMemory,dwNewFileCount
 
  jmp _ErrorExit  ;正常退出

_ErrFormat:
          
_ErrorExit:
          pop fs:[0]
          add esp,0ch
          invoke UnmapViewOfFile,@lpMemory
          invoke CloseHandle,@hMapFile
          invoke CloseHandle,@hFile
          jmp @F
_ErrFormat1:
         
_ErrorExit1:
          pop fs:[0]
          add esp,0ch
          invoke UnmapViewOfFile,@lpMemory1
          invoke CloseHandle,@hMapFile1
          invoke CloseHandle,@hFile1
@@:        
  ret
_openFile endp

start:

  invoke _openFile
  invoke ExitProcess,NULL
  end start

```

------

==行271为寄存器esi赋值，使其指向要处理的文件的内存映射文件的起始地址==；==行272为寄存器edi赋值，使其指向申请内存块（目标缓冲区）的起始，该位置存放最终转换后的数据定义语句==。

行276～278==向目标缓冲区写入数据定义语句的前置空格==。

行279～284==向目标缓冲区写入数据定义的伪指令`db`==。

行288～378==是一个循环，循环次数为要处理文件的大小`@dwFileSize`。变量`@dwTemp`记录了处理的字节的序数==。

行294～343==是当该序数到达16的整数倍时要做的操作，包括向目标缓冲区写入一个回车换行符号和下一行的数据定义的伪指令符号==。==如果序数`@dwTemp`不是16的整数倍，则执行行345～373的操作。即分别处理字节的高位和低位，并将处理后的字节合成写入目标缓冲区==。

==行382将处理完毕的目标缓冲区中的字节码写入文件C:\1.txt，完成转换==。

## 18.3.2　运行测试

编译链接执行文件，打开文件C:\1.txt，查看对PE文件_host.exe的执行结果（节选）如下：

------

```
db 4Dh,5Ah,90h,00h,03h,00h,00h,00h,04h,00h,00h,00h,0FFh,0FFh,00h,00h
db 00h,00h,00h,00h,00h,00h,00h,40h,00h,00h,00h,00h,00h,00h,00h,00h
db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
db 00h,00h,00h,00h,00h,00h,00h,00h,00h,0C0h,00h,00h,00h,0Eh,1Fh,0BAh
db 00h,0B4h,09h,0CDh,21h,0B8h,01h,4Ch,0CDh,21h,54h,68h,69h,73h,20h,70h
db 6Fh,67h,72h,61h,6Dh,20h,63h,61h,6Eh,6Eh,6Fh,74h,20h,62h,65h,20h
db 75h,6Eh,20h,69h,6Eh,20h,44h,4Fh,53h,20h,6Dh,6Fh,64h,65h,2Eh,0Dh
db 0Ah,24h,00h,00h,00h,00h,00h,00h,00h,66h,17h,54h,4Bh,22h,76h,3Ah
db 22h,76h,3Ah,18h,22h,76h,3Ah,18h,0ACh,69h,29h,18h,2Dh,76h,3Ah,18h
db 56h,28h,18h,23h,76h,3Ah,18h,52h,69h,63h,68h,22h,76h,3Ah,18h,00h
db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
db 00h,00h,00h,00h,00h,50h,45h,00h,00h,4Ch,01h,03h,00h,6Dh,96h,35h
db 00h,00h,00h,00h,00h,00h,00h,00h,0E0h,00h,0Fh,01h,0Bh,01h,05h,0Ch
db 0CCh,00h,00h,00h,18h,00h,00h,00h,00h,00h,00h,0B4h,0DBh,00h,00h,00h
db 00h,00h,00h,0E0h,00h,00h,00h,00h,40h,00h,00h,10h,00h,00h,00h,02h
db 00h,04h,00h,00h,00h,00h,00h,00h,00h,04h,00h,00h,00h,00h,00h,00h
db 00h,10h,01h,00h,00h,04h,00h,00h,00h,00h,00h,00h,02h,00h,00h,00h,
```

------

> 注意　使用小工具`hex2db`生成的数据定义语句的最后一行末尾有一个逗号，在将结果引入汇编代码时，必须将该逗号去掉，否则编译源文件时会出现错误。

# 18.4　执行调度程序_host.exe

18.2.2小节通过一个程序模拟了多个应用程序的执行调度过程。接下来就要编写本章==通用的执行调度程序`_host.exe`==。==该程序可以对同步运行更多的应用程序，且定义上会更灵活==。

## 18.4.1　主要代码

主要代码见代码清单18-3。

代码清单18-3　执行调度程序`_host.asm`（chapter18\_host.asm）

------

```assembly
;------------------------------------
; 宿主程序
;-------------------------------------

.386
.model flat,stdcall
option casemap:none

...

TOTAL_FILE_COUNT  equ   100        ;本程序所绑定文件的最大数
BinderFileStruct  STRUCT
  inExeSequence   byte   ?         ;为0表示非执行文件，为1表示加入执行序列
  dwFileOff       dword   ?        ;在宿主中的起始偏移
  dwFileSize      dword    ?       ;文件大小
  name1           db   256 dup(0)  ;文件名，含子目录
BinderFileStruct  ENDS


.data
hRunThread  dd ?
dwFileSizeHigh dd ?
dwFileSizeLow dd ?
dwFileCount dd ?
dwFolderCount dd ?
dwFileSize    dd ?
dwFileOff     dd ?

szFilter   db '*.*',0
szXie      db '\',0
szPath     db 'c:\ql',256 dup(0)
szBuffer   db 1024 dup(0)
szHost     db 'host.exe',0    ;宿主程序
szHost_    db '_host.exe',0   ;释放出来的文件

szTemp     db 'a\b\c\abc.exe',0

stStartUp	STARTUPINFO		<?>
stProcInfo	PROCESS_INFORMATION	<?> 

;以下为捆绑列表数据结构，一个文件总数的双字和多个BinderFileStruct结构
dwFlag          dd  0ffffffffh,0ffffffffh,0ffffffffh,0ffffffffh
dwTotalFile     dd  TOTAL_FILE_COUNT    ;文件总数
lpFileList      BinderFileStruct TOTAL_FILE_COUNT dup(<?>)
szBuffer1       db  256 dup(0)

.code
;------------------
; 错误Handler
;------------------
_Handler proc _lpExceptionRecord,_lpSEH,\
              _lpContext,_lpDispathcerContext

  pushad
  mov esi,_lpExceptionRecord
  mov edi,_lpContext
  assume esi:ptr EXCEPTION_RECORD,edi:ptr CONTEXT
  mov eax,_lpSEH
  push [eax+0ch]
  pop [edi].regEbp
  push [eax+8]
  pop [edi].regEip
  push eax
  pop [edi].regEsp
  assume esi:nothing,edi:nothing
  popad
  mov eax,ExceptionContinueExecution
  ret
_Handler endp

;---------------------
; 处理找到的文件
;---------------------
_ProcessFile proc _lpszFile
  local @hFile

  invoke lstrlen,addr szPath
  mov esi,eax
  add esi,_lpszFile
  mov al,byte ptr [esi]
  .if al==5ch
    inc esi
  .endif
  inc dwFileCount
  invoke CreateFile,_lpszFile,GENERIC_READ,FILE_SHARE_READ,0,\
   OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
  .if eax != INVALID_HANDLE_VALUE
   mov @hFile,eax
   invoke GetFileSize,eax,NULL

   add dwFileSizeLow,eax
   adc dwFileSizeHigh,0
   invoke CloseHandle,@hFile
  .endif
  ret

_ProcessFile endp

;----------------------------
; 遍历指定目录szPath下
;  (含子目录)的所有文件
;------------------------------
_FindFile proc _lpszPath
  local @stFindFile:WIN32_FIND_DATA
  local @hFindFile
  local @szPath[MAX_PATH]:byte     ;用来存放“路径\”
  local @szSearch[MAX_PATH]:byte   ;用来存放“路径\*.*”
  local @szFindFile[MAX_PATH]:byte ;用来存放“路径\文件”

  pushad
  invoke lstrcpy,addr @szPath,_lpszPath
  ;在路径后面加上\*.*
@@:
  invoke lstrlen,addr @szPath
  lea esi,@szPath
  add esi,eax
  xor eax,eax
  mov al,'\'
  .if byte ptr [esi-1] != al
   mov word ptr [esi],ax
  .endif
  invoke lstrcpy,addr @szSearch,addr @szPath
  invoke lstrcat,addr @szSearch,addr szFilter
  ;寻找文件
  invoke FindFirstFile,addr @szSearch,addr @stFindFile
  .if eax != INVALID_HANDLE_VALUE
   mov @hFindFile,eax
   .repeat
    invoke lstrcpy,addr @szFindFile,addr @szPath
    invoke lstrcat,addr @szFindFile,addr @stFindFile.cFileName
    .if @stFindFile.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY
     .if @stFindFile.cFileName != '.'
      inc dwFolderCount
      invoke _FindFile,addr @szFindFile
     .endif
    .else
     invoke _ProcessFile,addr @szFindFile
    .endif
    invoke FindNextFile,@hFindFile,addr @stFindFile
   .until eax==FALSE
   invoke FindClose,@hFindFile
  .endif
  popad
  ret
_FindFile endp
;------------------------------------------
; 执行程序用的线程
; 1. 用 CreateProcess 建立进程
; 2. 用 WaitForSingleOject 等待进程结束
;-------------------------------------------
_RunThread	proc	uses ebx ecx edx esi edi,\
		dwParam:DWORD
   pushad
   mov ecx,dwTotalFile
   mov esi,offset lpFileList
   .repeat
      assume esi:ptr BinderFileStruct
      mov al,byte ptr [esi]
      push esi
      .if al==1    ;文件在执行序列
        push esi
        invoke GetStartupInfo,addr stStartUp
        pop esi
        invoke CreateProcess,NULL,addr [esi].name1,NULL,NULL,\
              NULL,NORMAL_PRIORITY_CLASS,NULL,NULL,offset stStartUp,offset stProcInfo
        .if eax!=0
          invoke WaitForSingleObject,stProcInfo.hProcess,INFINITE
          invoke CloseHandle,stProcInfo.hProcess
          invoke CloseHandle,stProcInfo.hThread
        .endif
      .endif
      invoke Sleep,1000
      pop esi
      add esi,sizeof BinderFileStruct
      dec dwTotalFile
      .break .if dwTotalFile==0
   .until FALSE
   popad
   ret
_RunThread	endp

start:
  ;获取当前目录
  invoke GetCurrentDirectory,256,addr szPath  
  invoke  CreateThread,NULL,NULL,offset _RunThread,\
                  NULL,NULL,offset hRunThread
  end start
```

------

## 18.4.2　数据结构分析

本章开发的EXE捆绑器最大能捆绑100个文件，由常量`TOTAL_FILE_COUNT`定义。==每个捆绑文件都对应一个结构，用来说明`文件的名称`、`所处的位置`、`是否加入到最终的可执行序列标志`等==。该结构的详细定义如下：

------

```assembly
BinderFileStruct STRUCT
	inExeSequence byte ? 	;为0表示非执行文件	为1表示加入执行序列
	dwFileOff dword ? 		;在宿主中的起始偏移
	dwFileSize dword ? 		;文件大小
	name db 256 dup(0) 		;文件名，含子目录
BinderFileStruct ENDS
```

------

函数参数的解释如下：

**1）**`inExeSequence`：==标志字节==。==如果是0，则表示该捆绑文件是一般文件，不参与释放后的执行调度过程==；==如果是1，则表示该文件为PE文件，且参与释放后的执行调度过程==。

**2）**`dwFileOff`：==该文件字节码在宿主程序中的偏移==。==指出了文件在宿主程序中的位置==。

**3）**`dwFileSize`：==文件的大小==。

**4）**`name`：==要绑定的文件的名字，含子目录==。

> 特别提示　==`BinderFileStruct.name`不是绝对路径，而是当前路径下的相对路径==。该路径中包含子目录，可能的表达形式如pic\background.gif，指当前目录下的pic子目录中的background.gif图片文件，子目录允许嵌套。

行39～42==定义了绑定列表的相关数据变量的定义==。==`dwTotalFile`为捆绑文件总数，`lpFileList`为绑定列表。`dwFlag`定义了三个双字，值均为0xffffffff==。设置这个标志的目的是从文件中定位该结构所处的位置。

与18.2.2小节的例子不同，==在线程函数`_RunThread`中，要调度的程序不再是固定的某个PE文件，而是通过遍历绑定列表数据结构得到的由用户定义的程序==。

行57～78构造了一个循环，==循环的次数为变量`dwTotalFile`的值。每执行一次循环，就从绑定列表中取一条记录，通过判断标志`inExeSequence`确定是否执行该文件==。

==将_host.asm编译，链接以后，生成可执行文件==。==使用上一节开发的小工具hex2db.exe，将可执行代码`_host.exe`转换为汇编语言里的字节码定义语句，保存放在C:\1.txt中，以便在后面想整体将可执行代码嵌入到汇编源代码时使用==。

# 18.5　宿主程序host.exe

下面将开发==宿主程序，即EXE捆绑器最终生成的携带了捆绑文件的可执行程序==。以下分别==从宿主程序的功能、宿主程序捆绑前后状态==，==以及主要代码（含遍历文件、释放文件和主函数三部分）==三个方面进行介绍。

## 18.5.1　宿主程序的功能

宿主程序host.exe是EXE捆绑器的核心PE文件，它具备以下三个功能：

**1）**==存储所有要捆绑的文件，包括可运行的文件和不可运行的文件，这些文件将通过程序补丁的方式存储到宿主程序的最后一节==。

**2）**==按原目录结构释放所有文件==。

**3）**==具备调度程序执行的功能==。==该部分功能由释放的\_host.exe来完成。而\_host.exe的添加方法则是直接将指令字节码添加到宿主程序的源程序中==。

==和\_host.exe程序一样，宿主程序host.exe中也定义了一套绑定列表的数据结构。这两个程序维护了同样的数据实例，\_host.exe的绑定列表中每个字段的值都来自于宿主程序。==

举个简单例子，如果文件夹中有以下5个文件待绑定：

1. A1.exe
2. A2.exe
3. Config.ini
4. dat\abc.dat（注意含子目录）
5. db\abc.mdb（注意含子目录）

其中A1、A2为可执行程序，要求绑定后的程序在运行时先执行A1，然后执行A2。以下数字模拟了宿主程序的绑定列表可能的数据排列方式：

------

```
00000005h,＜1,0b10h,0100h,'A1.exe'＞＜1,0c10h,0100h,'A2.exe'＞＜0,0d10h,0100h,'Config.dat'＞＜0,0e10h,0100h,'dat\abc.dat'＞＜0,0f10h,0100h,'db\abc.mdb '＞
```

------

==宿主程序维护了这样的一套数据，用它来释放捆绑文件==；==嵌入到宿主程序源代码中的`_host.exe`字节码中也维护了这样的一套数据，用它来执行调度==。

## 18.5.2　宿主程序的状态

由于宿主程序完成了对捆绑文件的存储，所以，在捆绑文件前后不同时期，宿主程序存在不同的状态，如图18-1所示。

![image](https://github.com/YangLuchao/img_host/raw/master/20231028/image.1eav97x9afsw.jpg)

图　18-1　宿主程序运行状态

如图所示，==捆绑前，宿主程序是轻身的，与捆绑文件没有任何的关联==；==捆绑后（执行前），宿主程序已经包含了所有的捆绑文件数据==；==执行时，宿主程序会释放捆绑的所有文件====。所以，除了宿主程序不发生任何变化外，磁盘上还多出了`_host.exe`和所有绑定的文件==。

==`_host.exe`为进程调度指挥长，释放出的可执行文件就是在它的调度指挥下实现了顺序执行的。该程序包含在捆绑前的宿主程序中==。==那么，对文件的捆绑工作由谁来完成呢？答案是由捆绑器来完成。捆绑器类似于PE进阶部分的补丁工具==。

## 18.5.3　遍历文件

==为了确认当前目录要捆绑的文件，程序需要首先遍历当前目录下的文件和文件夹，获取当前目录下所有的文件名称，以及每个文件的大小==。遍历文件的代码见代码清单18-4。

代码清单18-4　==遍历当前目录下的文件和文件夹函数`_ProcessFile`==（chapter18\host.asm）

------

```assembly
;---------------------
; 处理找到的文件
;---------------------
_ProcessFile proc _lpszFile
  local @hFile

  invoke lstrlen,addr szPath
  mov esi,eax
  add esi,_lpszFile
  mov al,byte ptr [esi]
  .if al==5ch
    inc esi
  .endif
  inc dwFileCount
  invoke CreateFile,_lpszFile,GENERIC_READ,FILE_SHARE_READ,0,\
   OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
  .if eax != INVALID_HANDLE_VALUE
   mov @hFile,eax
   invoke GetFileSize,eax,NULL

   add dwFileSizeLow,eax
   adc dwFileSizeHigh,0
   invoke CloseHandle,@hFile
  .endif
  ret

_ProcessFile endp

;----------------------------
; 遍历指定目录szPath下
;  (含子目录)的所有文件
;------------------------------
_FindFile proc _lpszPath
  local @stFindFile:WIN32_FIND_DATA
  local @hFindFile
  local @szPath[MAX_PATH]:byte     ;用来存放“路径\”
  local @szSearch[MAX_PATH]:byte   ;用来存放“路径\*.*”
  local @szFindFile[MAX_PATH]:byte ;用来存放“路径\文件”

  pushad
  invoke lstrcpy,addr @szPath,_lpszPath
  ;在路径后面加上\*.*
@@:
  invoke lstrlen,addr @szPath
  lea esi,@szPath
  add esi,eax
  xor eax,eax
  mov al,'\'
  .if byte ptr [esi-1] != al
   mov word ptr [esi],ax
  .endif
  invoke lstrcpy,addr @szSearch,addr @szPath
  invoke lstrcat,addr @szSearch,addr szFilter
  ;寻找文件
  invoke FindFirstFile,addr @szSearch,addr @stFindFile
  .if eax != INVALID_HANDLE_VALUE
   mov @hFindFile,eax
   .repeat
    invoke lstrcpy,addr @szFindFile,addr @szPath
    invoke lstrcat,addr @szFindFile,addr @stFindFile.cFileName
    .if @stFindFile.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY
     .if @stFindFile.cFileName != '.'
      inc dwFolderCount
      invoke _FindFile,addr @szFindFile
     .endif
    .else
     invoke _ProcessFile,addr @szFindFile
    .endif
    invoke FindNextFile,@hFindFile,addr @stFindFile
   .until eax==FALSE
   invoke FindClose,@hFindFile
  .endif
  popad
  ret
_FindFile endp
```

------

==函数`_FindFile`是个递归函数，入口参数是目录名==。==行66～78是一个循环，通过调用函数`FindNextFile`获得下一个文件或文件夹==。==行69～73判断：得到的如果是一个子文件夹，则继续调用函数`_FindFile`遍历下一个文件夹的内容==；==如果是文件，则调用函数`_ProcessFile`输出文件名及长度==。

## 18.5.4　释放文件

文件的释放比较容易。==在宿主程序中，根据功能的不同分类，共有两种文件需要释放==：

1. **第一种**，==只有一个文件，它就是进程调度程序_host.exe==。==该文件是事先通过将程序字节码（前面生成的C:\1.txt文件）写入到数据段的方法嵌入宿主程序的==。
2. **第二种**，==是捆绑文件，这些文件是通过后面介绍的打补丁方法，把所有相关文件的数据附加到宿主文件的最后一个节来实现的==。

### 1.释放`_host.exe`

由于进程调度程序所有的字节码均写入到了宿主程序的数据段中，数据定义如下：

------

```
lphostExeFile
db 4Dh,5Ah,90h,00h,03h,00h,00h,00h,04h,00h,00h,00h
db 0FFh,0FFh,00h,00h,0B8h,00h,00h,00h,00h,00h,00h,00h
db 40h,00h,00h,00h,00h,00h,00h,00h 00h,00h,00h,00h,00h
db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
......
```

------

==所以，释放该文件非常容易，只需要将这些字节码原样写回文件即可==，代码如下：

------

```assembly
;释放_host.exe文件
invoke writeToFile,addr szHost_,addr lphostExeFile,dwTotalFileSize
```

------

### 2.释放捆绑文件

==补丁工具在打补丁时，将所有待捆绑的文件的相关信息记录到宿主程序的绑定列表中==。==这些信息包括==：

1. ==每个文件在宿主中的偏移==
2. ==文件大小==
3. ==释放后所在目录位置==
4. ==文件名==

所以，释放捆绑文件时，只需根据绑定列表的描述释放每一个文件即可，具体包括以下四步：

1. **步骤1**　确定捆绑文件在宿主中的偏移。
2. **步骤2**　确定捆绑文件的大小。
3. **步骤3**　确定该文件释放以后的绝对路径。
4. **步骤4**　执行释放操作。

释放捆绑文件的主要代码见代码清单18-5。

代码清单18-5　释放捆绑文件函数`_releaseFiles`（chapter18\host.asm）

------

```assembly
;-----------------
; 释放捆绑的文件
;-----------------
_releaseFiles   proc
  local @stOF:OPENFILENAME
  local @hFile,@dwFileSize,@hMapFile,@lpMemory
  local @hFile1,@dwFileSize1,@hMapFile1,@lpMemory1
  local @bufTemp1[10]:byte
  local @dwTemp:dword,@dwTemp1:dword
  local @dwBuffer,@lpDst,@hDstFile
  
   pushad
   mov eax,dwTotalFile
   push eax

   ;打开文件host.exe，写入szBuffer指定的文件
   invoke CreateFile,addr szHost,GENERIC_READ,\
            FILE_SHARE_READ or FILE_SHARE_WRITE,NULL,\
            OPEN_EXISTING,FILE_ATTRIBUTE_ARCHIVE,NULL

   .if eax!=INVALID_HANDLE_VALUE
         mov @hFile,eax
        invoke GetFileSize,eax,NULL
        mov @dwFileSize,eax
        .if eax
          invoke CreateFileMapping,@hFile,\  ;内存映射文件
                 NULL,PAGE_READONLY,0,0,NULL
          .if eax
            mov @hMapFile,eax
            invoke MapViewOfFile,eax,\
                   FILE_MAP_READ,0,0,0
            .if eax
              mov @lpMemory,eax              ;获得文件在内存的映象起始位置
              assume fs:nothing
              push ebp
              push offset _ErrFormat
              push offset _Handler
              push fs:[0]
              mov fs:[0],esp
            .endif
          .endif
        .endif
   .endif

   mov ecx,dwTotalFile
   mov esi,offset lpFileList
   .repeat
      assume esi:ptr BinderFileStruct
      push esi

      mov eax,[esi].dwFileOff   ;取文件偏移
      mov dwFileOff,eax
      mov eax,[esi].dwFileSize  ;取文件大小
      mov dwFileSize,eax

      ;创建文件名所在的所有子目录
      pushad
      invoke RtlZeroMemory,addr szBuffer,256
      popad
      invoke _createAllDir,addr [esi].name1
   
      ;将指定位置的数据拷贝到文件中
      pushad
      invoke GetCurrentDirectory,256,addr szPath  
      invoke RtlZeroMemory,addr szBuffer,256
      invoke lstrcpy,addr szBuffer,addr szPath    ; c:\ql
      invoke lstrcat,addr szBuffer,addr szXie     ; \
      popad

      push esi
      invoke lstrlen,addr [esi].name1
      pop esi
      push esi    ;清空szBuffer1
      push eax
      invoke RtlZeroMemory,addr szBuffer1,256
      pop eax
      pop esi     ;将a\b\c\abc.dat拷贝到szBuffer1中
      invoke MemCopy,addr [esi].name1,addr szBuffer1,eax

      nop
      lea eax,[esi].name1
      invoke lstrcat,addr szBuffer,addr szBuffer1 ; a\b\abc.dat
      mov eax,@lpMemory
      add eax,dwFileOff

      invoke writeToFile,addr szBuffer,eax,dwFileSize

      pop esi
      add esi,sizeof BinderFileStruct
      dec dwTotalFile
      .break .if dwTotalFile==0
   .until FALSE
   pop eax   
   mov dwTotalFile,eax

  jmp _ErrorExit  ;正常退出

_ErrFormat:

_ErrorExit:
          pop fs:[0]
          add esp,0ch
          invoke UnmapViewOfFile,@lpMemory
          invoke CloseHandle,@hMapFile
          invoke CloseHandle,@hFile
          jmp @F
_ErrFormat1:

_ErrorExit1:
          pop fs:[0]
          add esp,0ch
          invoke UnmapViewOfFile,@lpMemory1
          invoke CloseHandle,@hMapFile1
          invoke CloseHandle,@hFile1
@@:        
   popad
   ret
_releaseFiles   endp
```

------

==行47～94根据绑定列表结构`BinderFileStruct`中定义的值，对每一个文件进行释放处理==。因为文件在宿主程序中的起始地址和大小都有记录，文件内容唾手可得。程序首先根据`BinderFileStruct.name`一次性完成文件所在目录的创建操作（如果目录存在嵌套则循环创建名字中所有嵌套的子目录），然后在目录中用结构指定的名称新建文件，并调用函数`writeToFile`将宿主程序中指定位置、指定大小数据写入，从而完成对捆绑文件的释放工作。

## 18.5.5　宿主程序主函数

宿主程序的主函数只有三个调用，这三个调用很明晰地展示出该函数的三个主要作用，它们依次是：

1. ==`writeToFile`（用以释放_host.exe文件）==
2. ==`_releaseFiles`（用以释放捆绑的文件）==
3. ==`_RunThread`（用以调度执行程序的线程函数）==

主函数代码如下所示：

------

```assembly
;释放_host.exe文件
invoke writeToFile,addr szHost_,addr lphostExeFile,dwTotalFileSize
;释放捆绑的文件
invoke GetCurrentDirectory,256,addr szPath
invoke _releaseFiles
;执行_host.exe文件
invoke CreateThread,NULL,NULL,offset _RunThread,\
NULL,NULL,offset hRunThread
```

------

# 18.6　EXE捆绑器bind.exe

==EXE捆绑器的主要任务是，将要捆绑的文件附加到宿主程序host.exe文件的最后一节==。==这类似于PE进阶部分讲的补丁工具bind.exe==。==除了打补丁，捆绑器还要完成对宿主程序host.exe中的两套绑定列表数据的修正，以便用于后期的释放捆绑文件和调度运行程序==。==要完成对补丁列表数据的修正，首先需要完成对绑定列表数据的定位==。

## 18.6.1　绑定列表定位

绑定列表在host.exe和要释放的_host.exe中均保留了一份，那么这个位置在宿主程序host.exe的哪个偏移处呢？使用十六进制编辑器FlexHex打开host.exe，查找.data中两个0xFFFFFFFFFFFF双字的位置，其后紧跟着的就是绑定列表数据结构。如下所示：

![image](https://github.com/YangLuchao/img_host/raw/master/20231028/image.2d9fnxaf3ixw.jpg)

通过查找可以找到这两套绑定列表数据所在文件的偏移：

1. 由`host.exe`维护的第一套绑定列表起始位置：`13ach`
2. 由`_host.exe`维护的第二套绑定列表起始位置：`8be8h`

最终运行时，绑定列表的数据结构排列看起来类似以下字节码所示：

![image](https://github.com/YangLuchao/img_host/raw/master/20231028/image.6kyqohp4iwg0.jpg)

加框部分是捆绑的文件个数，每个文件都由结构`BinderFileStruct`定义。结构中包含的字段在前面已经进行了介绍，如文件路径、是否可执行、文件长度、所在位置等。

## 18.6.2　捆绑步骤及主要代码

捆绑器使用了本书第17章介绍的，在PE最后一节附加数据的方法；由于不需要调整指令指针的值，所以相对简单，以下是对捆绑步骤的简单描述：

1. **步骤1**　==打开宿主程序，将宿主程序映射到内存文件==。==获取要捆绑目录下所有文件的长度，并按照文件对齐粒度对齐==。==将现有宿主程序的大小加上对齐后的大小，重新映射宿主程序==。
2. **步骤2**　==将宿主程序，要捆绑的文件复制到新映射的内存文件中，记录每个文件的相对位置==；==同时，将这些信息写入宿主程序中的两处捆绑列表所在位置==。
3. **步骤3**　==修改最后一节的相关参数==。

捆绑过程的主要代码见代码清单18-6。

代码清单18-6　执行捆绑函数`_openFile`代码片段（chapter18\bind.asm）

------

```assembly
;--------------------
; 打开PE文件并处理
;--------------------
_openFile proc
  local @stOF:OPENFILENAME
  local @hFile,@dwFileSize,@hMapFile,@lpMemory
  local @hFile1,@dwFileSize1,@hMapFile1,@lpMemory1
  local @bufTemp1[10]:byte
  local @dwTemp:dword,@dwTemp1:dword
  local @dwBuffer,@lpDst,@hDstFile
  local @dwCount,@dwInExe
  

  ;打开宿主程序，并映射到内存文件
  invoke CreateFile,addr szFileNameOpen2,GENERIC_READ,\
         FILE_SHARE_READ or FILE_SHARE_WRITE,NULL,\
         OPEN_EXISTING,FILE_ATTRIBUTE_ARCHIVE,NULL

  .if eax!=INVALID_HANDLE_VALUE
    mov @hFile1,eax
    invoke GetFileSize,eax,NULL
    mov @dwFileSize1,eax
    .if eax
      invoke CreateFileMapping,@hFile1,\  ;内存映射文件
             NULL,PAGE_READONLY,0,0,NULL
      .if eax
        mov @hMapFile1,eax
        invoke MapViewOfFile,eax,\
               FILE_MAP_READ,0,0,0
        .if eax
          mov @lpMemory1,eax              ;获得文件在内存的映象起始位置
          assume fs:nothing
          push ebp
          push offset _ErrFormat1
          push offset _Handler
          push fs:[0]
          mov fs:[0],esp

          ;检测PE文件是否有效
          mov esi,@lpMemory1
          assume esi:ptr IMAGE_DOS_HEADER
          .if [esi].e_magic!=IMAGE_DOS_SIGNATURE  ;判断是否有MZ字样
            jmp _ErrFormat1
          .endif
          add esi,[esi].e_lfanew    ;调整ESI指针指向PE文件头
          assume esi:ptr IMAGE_NT_HEADERS
          .if [esi].Signature!=IMAGE_NT_SIGNATURE ;判断是否有PE字样
            jmp _ErrFormat1
          .endif
        .endif
      .endif
    .endif
  .endif

  ;重新计算文件大小
  invoke _calcFileSize

  mov eax,dwFileSizeLow
  add eax,@dwFileSize1
  adc dwFileSizeHigh,0

  mov eax,dwFileSizeHigh
  .if eax>0  ;附加的字节数太大，程序捆绑失败
    invoke MessageBox,NULL,addr szTooManyFiles,NULL,MB_OK
    jmp _ErrFormat1
  .endif
  mov eax,dwBindFileCount
  .if eax>TOTAL_FILE_COUNT  ;文件太多，程序捆绑失败
    invoke MessageBox,NULL,addr szTooManyFiles,NULL,MB_OK
    jmp _ErrFormat1
  .endif

  ;将文件的大小按照文件对齐粒度对齐 
  invoke getFileAlign,@lpMemory1
  mov dwFileAlign,eax
  xchg eax,ecx
  mov eax,@dwFileSize1
  invoke _align
  mov dwNewFileAlignSize,eax

  invoke wsprintf,addr szBuffer,addr szOut121,@dwFileSize1,dwNewFileAlignSize
  invoke _appendInfo,addr szBuffer 

  ;求最后一节在文件中的偏移
  invoke getLastSectionStart,@lpMemory1
  mov dwLastSectionStart,eax

  invoke wsprintf,addr szBuffer,addr szOut122,eax
  invoke _appendInfo,addr szBuffer 

  ;求最后一节大小
  mov eax,dwNewFileAlignSize
  sub eax,dwLastSectionStart
  add eax,dwFileSizeLow
  ;将该值按照文件对齐粒度对齐
  mov ecx,dwFileAlign
  invoke _align
  mov dwLastSectionAlignSize,eax      ;最后一节附加了捆绑文件的新大小

  invoke wsprintf,addr szBuffer,addr szOut123,eax
  invoke _appendInfo,addr szBuffer 


  ;求新文件大小
  mov eax,dwLastSectionStart
  add eax,dwLastSectionAlignSize
  mov dwNewFileSize,eax

  invoke wsprintf,addr szBuffer,addr szOut124,eax
  invoke _appendInfo,addr szBuffer 
 

  ;申请内存空间
  invoke GlobalAlloc,GHND,dwNewFileSize
  mov @hDstFile,eax
  invoke GlobalLock,@hDstFile
  mov lpDstMemory,eax   ;将指针给@lpDst

  
  ;将目标文件拷贝到内存区域
  mov ecx,@dwFileSize1   
  invoke MemCopy,@lpMemory1,lpDstMemory,ecx


  ;拷贝捆绑文件
  
  ;计算列表中数据的数目
  invoke SendMessage,hProcessModuleTable,\
        LVM_GETITEMCOUNT,0,0
  mov dwBindFileCount,eax
  mov @dwCount,0

  mov edi,lpDstMemory
  add edi,dwNewFileAlignSize

  .repeat
    push edi
    ;获取指定行指定列的信息，即文件路径
    invoke RtlZeroMemory,addr szBuffer,512
    invoke _GetListViewItem,hProcessModuleTable,\
          @dwCount,1,addr szBuffer
    ;invoke MessageBox,NULL,addr szBuffer,NULL,MB_OK    
    

    invoke CreateFile,addr szBuffer,GENERIC_READ,\
           FILE_SHARE_READ or FILE_SHARE_WRITE,NULL,\
           OPEN_EXISTING,FILE_ATTRIBUTE_ARCHIVE,NULL

    .if eax!=INVALID_HANDLE_VALUE
      mov @hFile,eax
      invoke GetFileSize,eax,NULL
      mov @dwFileSize,eax
      .if eax
        invoke CreateFileMapping,@hFile,\  ;内存映射文件
               NULL,PAGE_READONLY,0,0,NULL
        .if eax
          mov @hMapFile,eax
          invoke MapViewOfFile,eax,\
                 FILE_MAP_READ,0,0,0
          .if eax
            mov @lpMemory,eax              ;获得文件在内存的映象起始位置
          .endif
        .endif
      .endif
    .endif    

    
    invoke RtlZeroMemory,addr bufTemp1,512
    invoke _GetListViewItem,hProcessModuleTable,\
          @dwCount,2,addr bufTemp1    
    invoke atodw,addr bufTemp1
    mov @dwInExe,eax         ;是否在EXE执行序列

    ;invoke MessageBox,NULL,addr szBuffer,NULL,MB_OK

    mov eax,lpDstMemory      ;向两处捆绑列表中写入捆绑文件的数量
    add eax,lpBinderList1
    xchg ebx,eax
    mov eax,dwBindFileCount
    mov dword ptr [ebx],eax
   
    mov eax,lpDstMemory
    add eax,lpBinderList2
    xchg ebx,eax
    mov eax,dwBindFileCount
    mov dword ptr [ebx],eax


    pop edi
    mov edx,edi              ;取文件在目标中的偏移值
    sub edx,lpDstMemory
   
    ;将相关值写入捆绑列表    顺号   是否在EXE序列    偏移   文件大小   文件名
    invoke _writeToBinderList,@dwCount,@dwInExe,edx,@dwFileSize,addr szBuffer
    
    mov esi,@lpMemory
    ;将文件内容拷贝到目标文件
    mov ecx,@dwFileSize
    rep movsb
    
    ;取消映射
    push edi
    invoke UnmapViewOfFile,@lpMemory
    invoke CloseHandle,@hMapFile
    invoke CloseHandle,@hFile
    pop edi

    inc @dwCount
    nop
    mov eax,dwBindFileCount
    .break .if @dwCount==eax
  .until FALSE


  ;---------------------------到此为止，数据拷贝完毕  

  ;修正

  ;计算SizeOfRawData
  invoke _getRVACount,lpDstMemory
  xor edx,edx
  dec eax
  mov ecx,sizeof IMAGE_SECTION_HEADER
  mul ecx

  mov edi,lpDstMemory
  assume edi:ptr IMAGE_DOS_HEADER
  add edi,[edi].e_lfanew
  add edi,sizeof IMAGE_NT_HEADERS  
  add edi,eax
  assume edi:ptr IMAGE_SECTION_HEADER
  mov eax,dwLastSectionAlignSize
  mov [edi].SizeOfRawData,eax

  ;计算Misc值
  invoke getSectionAlign,@lpMemory1
  mov dwSectionAlign,eax
  xchg eax,ecx
  mov eax,dwLastSectionAlignSize
  invoke _align
  mov [edi].Misc,eax

  ;计算VirtualAddress

  mov eax,[edi].VirtualAddress  ;取原始RVA值
  mov dwVirtualAddress,eax

  mov edi,lpDstMemory
  assume edi:ptr IMAGE_DOS_HEADER
  add edi,[edi].e_lfanew    
  assume edi:ptr IMAGE_NT_HEADERS
  ;修正SizeOfImage
  mov eax,dwLastSectionAlignSize
  mov ecx,dwSectionAlign
  invoke _align
  ;获取最后一个节的VirtualAddress
  add eax,dwVirtualAddress
  mov [edi].OptionalHeader.SizeOfImage,eax  
  
  
 
  ;将新文件内容写入到c:\host.exe
  invoke writeToFile,lpDstMemory,dwNewFileSize
 
  jmp _ErrorExit  ;正常退出

_ErrFormat:
          invoke MessageBox,hWinMain,offset szErrFormat,NULL,MB_OK
_ErrorExit:
          pop fs:[0]
          add esp,0ch
          invoke UnmapViewOfFile,@lpMemory
          invoke CloseHandle,@hMapFile
          invoke CloseHandle,@hFile
          jmp @F
_ErrFormat1:
          invoke MessageBox,hWinMain,offset szErrFormat,NULL,MB_OK
_ErrorExit1:
          pop fs:[0]
          add esp,0ch
          invoke UnmapViewOfFile,@lpMemory1
          invoke CloseHandle,@hMapFile1
          invoke CloseHandle,@hFile1
@@:        
  ret
_openFile endp
```

------

因大部分代码在第17章已做过介绍，所以这部分代码由读者参照本书第17.2.2节自行分析。

## 18.6.3　测试运行

为了查看程序执行效果，请按照以下步骤进行测试：

1. **步骤1**　==编译\_host.asm，生成\_host.exe可执行代码==。
2. **步骤2**　==编译hex2db.asm，运行hex2db，生成_host.exe的字节码C:\1.txt==。
3. **步骤3**　==编译host.asm，将上一步生成的_host.exe字节码加入到数据段中==。
4. **步骤4**　==通过十六进制查看器查看生成的host.exe字节码，查找两个捆绑表所在位置。记录这个位置并将结果写到bind.asm中==。
5. **步骤5**　==编译bind.asm并运行，生成最终的C:\host.exe程序==。

图18-2是对本节中部分文件进行捆绑的示意图。其中各按钮的解释如下：

![image](https://github.com/YangLuchao/img_host/raw/master/20231028/image.7btr7wumd2s0.jpg)

图　18-2　捆绑文件运行界面

如图所示，“捆绑目录”即用户想要捆绑的目录；“宿主程序”是host.exe程序，因为它具有释放文件和执行文件的功能，所以不能用其他PE文件代替。加入执行序列的EXE文件在表格中用红色背景突出显示。

==单击右下角的“执行捆绑”按钮后，C盘根目录下将生成host.exe程序。这个程序就是携带了捆绑文件的宿主程序，也就是最终所需要的结果==。

# 18.7　小结

本章通过在目标PE文件末尾追加补丁的方式（参见第17章），演示了一种将用户指定目录下的所有文件捆绑在一起的编程方法。==实例中的补丁程序完成了释放宿主程序、释放相关捆绑文件、运行调度程序、实施绑定列表中指定可运行PE文件的批量同步运行==。

==EXE捆绑器可应用于对指定目录或文件进行加密，也可用于对批量EXE文件的执行，特别是在升级多个补丁工具时比较有用==。