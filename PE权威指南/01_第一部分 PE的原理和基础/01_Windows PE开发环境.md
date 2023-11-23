[toc]

本章首先要为大家详细介绍学习Windows PE所需要的软件开发环境，以及相关辅助软件的使用方法。然后利用我们搭建的开发环境开发第一个基于MASM32的汇编程序，并通过字节码阅读器初步认识本书中的主人公——PE文件。

通过本章，大家将熟悉汇编程序从编写到编译、链接、执行的整个过程，并掌握汇编程序的调试方法，会对PE文件有一个初步的了解。为了能更有效地帮助读者学习PE文件结构，第2章还会开发三个比较实用的程序，依次为：

==PEInfo.asm（PE文件结构查看器）==

==PEComp.asm（PE文件比较器）==

==PEDump.asm（PE文件字节码查看器）==

本书需要的软件环境如下：

> 开发语言：MASM32 V10.0
>
> 工作环境：Windows XP SP3操作系统
>
> 源程序的编辑器：记事本（notepad.exe），主要用来编写汇编源程序
>
> 动态调试器：OllyDBG软件
>
> 静态调试器：W32DASM
>
> 字节码的阅读器和编辑器：FlexHex

相关软件的安装文件大家可以从互联网上获取。

下面以一个简单的汇编程序为例，详细介绍从汇编编码到编译链接生成PE文件，再到调试PE文件的整个过程。

# 1.1　开发语言MASM32

MASM32是Steve Hutchessond在微软的不同产品基础上集成开发出来的汇编开发工具包，适合Win32编程环境的汇编语言，它主要用于基于Windows平台的32位汇编语言开发，是现在最流行的Win32汇编开发包。与VC++和VB等高级语言相比，Win32汇编具有得天独厚的优势，这些优势主要体现在：

1）它摒弃了对系统细节的封装，更接近于系统的底层，从而使得编码更加灵活，能完成许多高级语言无法做到的事情（如代码重定位和特殊寄存器赋值等）。

2）它生成的可执行PE文件体积小，执行速度快。

3）它可用于软件的核心程序段设计，以提高软件的性能。

4）它能够直接接触系统的底层，所以使用它要远比使用VC++和VB等高级语言更适合开发与系统安全相关的程序。比如，与计算机硬件密切相关的驱动程序的开发、计算机病毒的分析与防治、软件加密与解密、软件调试、Windows PE研究等。

因此，学习Win32汇编对学习信息安全而言很有必要。MASM32是我们研究Windows PE的首选语言。

MASM32是一个免费的软件包，该软件包中包含了汇编编译器ml.exe、资源编译器rc.exe、32位的链接器link.exe和一个简单的集成开发环境（Intergrated Development Environment，IDE）QEditor.exe。为什么说MASM32是从其他产品集成出来的呢？这是因为软件包中的ml.exe来自Microsoft的MASM软件包，rc.exe和link.exe则来自Microsoft的Visual Studio。MASM32软件包还包括了详尽的头文件、导入库文件、例子文件、帮助文档和一些工具程序，如lib.exe和dumpbin.exe等，后者被大家公认为最好的显示PE文件结构的工具。大家可以从网站http://www.masm32.com/上获得MASM32 SDK的最新版本，并可以在论坛里与来自世界各地的汇编爱好者交流技术和思想。

## 1.1.1　设置开发环境

下载到本地的压缩文件经解压后只有一个安装程序install.exe。下载了安装程序之后，我们首先要做的是在系统中设置Win32开发环境，设置主要分为以下四步：

### 步骤1　运行安装程序install.exe，安装汇编环境。

首先选择安装路径，此处我们选择的路径为D:\(backup)，然后单击"Start"按钮，如图1-1所示。

![image](https://github.com/YangLuchao/img_host/raw/master/20230725/image.148tdkrf9u74.webp)

图　1-1　汇编语言安装开始界面

此后，中间过程所有的按钮均选择默认的设置，即可完成软件安装。安装结束后，会显示IDE汇编集成环境QEditor的界面，图1-2是该环境加载了intro.txt文档后的界面。

![image](https://github.com/YangLuchao/img_host/raw/master/20230725/image.m4zfolonfa8.webp)

图　1-2　汇编语言自带的IDE——QEditor

尽管MASM32为我们提供了一个集成开发环境，但我个人还是喜欢脱离系统提供的开发环境，自己设置相关的环境变量。这样有利于掌握汇编语言的文件部署情况，便于深入了解诸如库在哪里、包含文件在哪里、执行程序在哪里等问题。

### 步骤2　建立自己的工作区。

笔者选择将软件安装到非系统盘（D盘），建议大家也这样做。为了能存放自己编写的汇编代码，笔者在D:\masm32中新建立了一个文件夹source。所有要做的准备工作都已经完成，不过现在还不能开始编写汇编程序，因为还没有告诉电脑汇编程序所依赖的环境，以及要调用的API函数库都在哪里。

### 步骤3　设置系统环境变量。

在“我的电脑”上点鼠标右键，选择“属性”，然后在打开的对话框上选择“高级”选项卡，如图1-3所示。

![image](https://github.com/YangLuchao/img_host/raw/master/20230725/image.1phon045c17k.webp)

图　1-3　系统属性高级选项卡界面

在选项卡上单击“环境变量”按钮，在用户的环境变量中增加以下三个环境变量：

include=d:\masm32\include

lib=d:\masm32\lib

path=d:\masm32\bin

改变环境变量后的窗口如图1-4所示。

![image](https://github.com/YangLuchao/img_host/raw/master/20230725/image.c9bypobnk1c.webp)

图　1-4　改变环境变量后的窗口界面

如果系统中已经存在相同名字的环境变量（如path变量），则在该变量的值的最后加上一个分号，然后加上上面列出的值即可。例如，假设未操作前系统存在路径变量path，且值为：

path=.;C:\Program Files\Java\jdk1.6.0_11\bin;%PATH%

修改以后的值为：

path=.;C:\Program Files\Java\jdk1.6.0_11\bin;%PATH%;d:\masm32\bin

特别提示　加粗部分要用英文输入，且不要忘记最前面的分号。

步骤4　测试环境变量设置是否成功。

单击桌面上的“开始”菜单，选择“运行”，输入"cmd"后回车，弹出一个黑色窗口（即通常所说的命令提示符窗口），如图1-5所示。

![image](https://github.com/YangLuchao/img_host/raw/master/20230725/image.7bc4pruefvg0.webp)

图　1-5　命令提示符窗口

在该窗口中输入以下命令：

------

```bash
C:\Documents and Settings\Administrator＞d:

D:\＞cd masm32\source

D:\masm32\source＞ml
```



------

如果窗口显示以下提示，则表示环境设置成功。

------

```bash
Microsoft(R)Macro Assembler Version 6.14.8444

Copyright(C)Microsoft Corp 1981-1997.All rights reserved.

usage:ML [options]filelist [/link linkoptions]

Run "ML/help "or "ML/?"for more info
```



------

通过以上几步，我们就完成了汇编语言环境的安装与设置。

## 1.1.2　开发第一个源程序HelloWorld.asm

上一小节，详细介绍了汇编语言环境的安装与设置。本小节将利用上面建立的环境开发一个简单的汇编语言程序HelloWorld.asm，程序运行后会在屏幕上弹出一个提示窗口并显示"HelloWorld"，具体步骤如下。

首先，打开记事本程序，在其中输入以下内容，如代码清单1-1所示（行号去掉）。

代码清单1-1　第一个汇编源程序（chapter1\HelloWorld.asm）

------

```asm
;------------------------
; 我的第一个基于WIN32的汇编程序
; 戚利
; 2006.2.28
;------------------------
    .386
    .model flat,stdcall
    option casemap:none

include    windows.inc
include    user32.inc
includelib user32.lib
include    kernel32.inc
includelib kernel32.lib

;数据段
    .data
szText     db  'HelloWorld',0
;代码段
    .code
start:
    invoke MessageBox,NULL,offset szText,NULL,MB_OK
    invoke ExitProcess,NULL
    end start

```



------

输入完毕后，在文件菜单中单击“保存”，选择保存位置为"D:\masm32\source\chapter1"，在文件名处输入"HelloWorld.asm"，如图1-6所示。

![image](https://github.com/YangLuchao/img_host/raw/master/20230725/image.55cq402qtnw0.webp)

图　1-6　保存源文件

注意　chapter1是D:\masm32\source下的子目录，需要事先建立。文件名前后的英文双引号不要遗漏。

这是一个最简单的图形用户界面（Graphical User Guide，GUI）程序。

注意　笔者尽量遵循开发商业程序的原则，使每个程序更容易让别人看懂，所以你可能会在一个不大的程序里看到很多的注释。

1～6行是程序的注释；7～10行定义了该汇编程序支持的基本特性；11～16行引入了外部的动态链接库，在这些动态链接库里有程序需要的函数调用，这种调用方式符合程序代码重用的原则；17～19行定义了这个程序中用到的数据；20～25行则是程序的代码段，25行的伪指令"end start"告诉操作系统代码入口；最有用的代码行只有23行和24行，分别调用了user32.dll动态链接库中的MessageBoxA函数和kernel32.dll动态链接库中的ExitProcess函数。

> 扩展阅读
>
> 在描述代码的语句中，使用了MessageBoxA函数，但在源代码里出现的却是MessageBox，两个函数相差了一个字母"A"。谈到这里，不能不说一说Win32 API函数的命名问题了。
>
> Win32 API中有名字的函数一般都有两个版本，其后缀分别以"A"和"W"结束，如创建文件的函数CreateFileA和CreateFileW（当然也有例外，如前面的ExitProcess函数）。A和W表示这个函数使用的字符集，A代表ANSI字符集，W表示宽字符，即Unicode字符集，在Windows中的Unicode字符一般是使用UCS2的UTF16-LE编码。查看user32.dll的导出表，你会发现user32.dll中存在MessageBoxA和MessageBoxW两个函数，代码清单1-1中的MessageBox为什么没有添加任何后缀呢？答案可以在MASM32提供的包含文件里找到，如下所示：
>
> ------
>
> MessageBoxA PROTO :DWORD,:DWORD,:DWORD,:DWORD
>
> MessageBox equ＜MessageBoxA＞
>
> ------
>
> 以上定义来自user32.inc文件（在文件夹D:\masm32\include中），通过equ伪指令符把MessageBox等价成了MessageBoxA。所以，如果以后大家再看到代码中出现MessageBox，就知道指的是MessageBoxA函数了。

汇编语言的基本语法本书将不做讲解，我们假设你已经掌握了MASM32编程的基本知识。

## 1.1.3　运行HelloWorld.exe

接下来，就需要对该源程序进行编译、链接以及运行和测试了。

首先，在Windows的命令提示符窗口中执行以下3个操作。

### 步骤1　进入工作区。

通过转换磁盘命令和CD命令进入存放源文件HelloWorld.asm的目录中，命令如下：

------

C:\Documents and Settings\administrator＞d:

D:\＞cd masm32\source\chapter1

------

### 步骤2　编译源文件。

在当前工作区中输入命令"`ml -c -coff HelloWorld.asm`"，然后回车。

参数-c表示独立编译，不进行链接；参数-coff表示编译后生成标准的COFF目标文件。编译以后会在源文件所在目录生成一个与源文件同名的obj目标文件。

ml.exe是汇编语言的编译程序，它负责将汇编源程序编译成目标文件。该程序可接受的各参数的解释和描述如下所示：

------

```cpp
Microsoft(R)Macro Assembler Version 6.14.8444

Copyright(C)Microsoft Corp 1981-1997.All rights reserved.

ML [/options]filelist [/link linkoptions]

/AT 允许支持微型内存模式　/nologo 不输出编译LOGO信息

/Bl＜linker＞ 使用其他的链接器　/Sa 打开所有可用信息列表

/c 只编译不链接　/Sc 在列表中增加指令执行时间信息

/Cp 保留所有用户定义标识符的大小写　/Sf 在列表中增加第一次编译后的信息

/Cu 将所有标识符转换为大写　/Sl＜width＞ 设置行宽

/Cx 保留公共和外部符号的大小写　/Sn 生成列表文件时关闭符号表

/coff 编译成符合公共目标文件格式的目标文件　/Sp＜length＞ 设置列表文件每页长度

/D＜name＞[=text] 定义给定名字的文本宏　/Ss＜string＞ 为列表文件设置子标题

/EP 生成一个预处理后的列表文件　/St＜string＞ 为列表文件设置标题

/F＜hex＞ 设置栈大小　/Sx 允许在列表中列出条件为假的代码清单

/Fe＜file＞ 指定可执行文件名　/Ta＜file＞ 编译不以.asm结尾的源文件

/Fl [file] 生成汇编代码列表文件　/w 同参数/WX

/Fm [file] 生成一个链接映像文件　/WX 将警告视为错误

/Fo＜file＞ 指定目标文件名　/W ＜number＞设置警告级别

/FPi 为浮点运算生成模拟代码　/X 忽略INCLUDE环境变量

/Fr [file] 生成.sbr源浏览文件　/Zd 增加行号调试信息

/FR [file] 生成扩展形式的.sbr源浏览文件　/Zf 使所有符号变成公共符号

/G＜c|d|z＞ 指定使用不同语言格式的函数调用约定和命名约定　/Zi 增加符号调试信息

/H＜number＞ 外部名字有效长度　/Zm 设置为与MASM 5.10兼容的模式

/I＜name＞ 指定包含文件路径　/Zp [n]设置结构对齐

/link＜linker options and libraries＞ 包含链接　/Zs 只进行参数检查
```



------

### 步骤3　链接目标文件与动态链接库。

链接是为了将源文件中调用到的动态链接库中的函数的相关信息附加到可执行文件中。链接命令是：

------

`link -subsystem:windows HelloWorld.obj`

------

参数-subsystem表示允许该代码运行的子系统。如果没有错误，执行以上命令后会在源文件所在目录下生成最终的可执行文件HelloWorld.exe。链接程序的参数解释如下：

------

```cpp
Microsoft(R)Incremental Linker Version 6.00.8168

Copyright(C)Microsoft Corp 1992-1998.All rights reserved.

usage:LINK [options] [files] [@commandfile]

options:

/ALIGN:#　节区对齐尺寸

/BASE:{address|@filename,key}　设置映像基地址

/COMMENT:comment　在头部插入一个注释字符串

/DEBUG　创建调试信息

/DEBUGTYPE:{CV|COFF}　创建特定格式（CV/COFF）的调试信息

/DEF:filename　指定链接库导出函数声明文件

/DEFAULTLIB:library　指定处理外部引用时使用的特定库

/DLL　生成目标为DLL文件

/DRIVER [:{UPONLY|WDM}]　创建Windows NT核心启动程序

/ENTRY:symbol　设定目标PE入口点

/EXETYPE:DYNAMIC　生成动态加载的虚拟设备驱动程序

/EXPORT:symbol　导出一个函数

/FIXED [:NO]　创建的目标PE只加载到首选基地址处

/FORCE [:{MULTIPLE|UNRESOLVED}]　针对那些UNRESOLVED或MULTIPLE定义的符号实施强制链接

/GPSIZE:#　在MIPS和Alpha平台上指定公有变量的尺寸

/HEAP:reserve [,commit]　设定保留或提交的堆的大小

/IMPLIB:filename　覆盖默认的引入链接库名

/INCLUDE:symbol　指定包含INC文件

/INCREMENTAL:{YES|NO}　是否控制增量连接

/LARGEADDRESSAWARE [:NO]　通知编译器应用程序是否支持大于2GB的地址

/LIBPATH:dir LIB　文件所在路径，允许用户重写该环境变量

/MACHINE:{ALPHA|ARM|IX86|MIPS|MIPS16|MIPSR41XX|PPC|SH3|SH4}　指定目标平台

/MAP [:filename]　创建一个MAP文件

/MAPINFO:{EXPORTS|FIXUPS|LINES}　在MAP文件中包含指定的信息（如导出信息、行等）

/MERGE:from=to　合并节

/NODEFAULTLIB [:library]　在处理引入符号时忽略所有的默认库

/NOENTRY　创建纯资源DLL文件

/NOLOGO　无LOGO

/OPT:{ICF [,iterations]|NOICF|NOREF|NOWIN98|REF|WIN98}　控制LINK优化

/ORDER:@filename　按预定顺序将COMDATs放置到映像文件中

/OUT:filename　指定输出文件名

/PDB:{filename|NONE}　创建PDB文件

/PDBTYPE:{CON [SOLIDATE]|SEPT [YPES]}　指定在哪里存储PDB调试类型信息

/PROFILE　创建一个MAP文件

/RELEASE　在文件头部设置校验和

/SECTION:name,[E] [R] [W] [S] [D] [K] [L] [P] [X]　设置指定节区的属性

/STACK:reserve [,commit]　设置保留或提交堆栈的大小

/STUB:filename　指定DOS STUB块从文件中获取

/SUBSYSTEM:{NATIVE|WINDOWS|CONSOLE|WINDOWSCE|POSIX}[,#[.##]]　指定子系统

/SWAPRUN:{CD|NET}　告诉操作系统在运行映像前首先将链接器的输出复制到交换文件中

/VERBOSE [:LIB]　输出链接过程的信息

/VERSION:#[.#]　指定主次版本号

/VXD　创建一个虚拟设备驱动器

/WARN [:warninglevel]　链接时打开警告级别

/WINDOWSCE:{CONVERT|EMULATION}　创建基于Windows CE的目标映像文件

/WS:AGGRESSIVE　修剪进程内存
```



------

注意　此处列举的参数并非link.exe程序支持的所有参数，例如，此处没有出现的-DelayLoad参数在后面的章节中会用到。

编译链接过程用到的操作指令如图1-7所示。

![image](https://github.com/YangLuchao/img_host/raw/master/20230725/image.7j4cxzcna900.webp)

图　1-7　编译链接过程用到的操作命令

在命令提示符下输入"HelloWorld"即可执行程序，执行结果如图1-8所示。

![image](https://github.com/YangLuchao/img_host/raw/master/20230725/image.2f84rde9v1wk.webp)

图　1-8　"HelloWorld"程序的执行结果

以上就是在汇编语言开发环境中开发、编译、链接和执行汇编程序的简单过程。

接下来要介绍的是对生成的HelloWorld.exe文件（也就是本书要重点研究的PE文件）进行调试，通过调试我们可以深入了解汇编源代码被最终分解为机器指令码并执行的细节。

## 1.2　调试软件OllyDBG

大家可能对OllyDBG（简称OD）并不是很熟悉，但在软件破解领域，它却是与TRW2000和SoftICE等齐名的跟踪破解利器。熟练掌握OD的用法对我们以后研究EXE文件内部指令跳转、病毒分析、逆向工程与反病毒设计等有很大的帮助。那么，就让我们从调试HelloWorld.exe开始学习吧。

### 1.2.1　调试HelloWorld.exe

调试可以帮助我们很容易地找到程序设计中的错误，如果这个程序不是我们开发的，我们还可以通过调试过程了解到开发该改程序的基本思路，调试是逆向工程必须掌握的一门技术。

为了能帮助读者尽快熟悉使用OD软件来调试PE文件的方法，下面以HelloWorld.exe为例，为大家详细讲解调试该PE文件的全过程。

#### 1.认识OD界面的构成

打开OD，选择文件菜单中的“打开”选项，让OD加载前面生成的HelloWorld.exe程序，界面如图1-9所示。通过这个图让大家认识一下这个大名鼎鼎的破解杀手吧。

![image](https://github.com/YangLuchao/img_host/raw/master/20230725/image.4ql0pijlowm0.webp)

图　1-9　OD加载HelloWorld.exe后的界面

==注：①指令及指令解释区；②寄存器及运行状态区；③代码和数据字节码区；④栈区==

如上图所示，菜单栏和工具栏大家都非常熟悉，这里不需要介绍了。在加载HelloWorld.exe以后，状态栏显示：

正在分析HelloWor：1个启发式函数，2个调用关联已知函数

这里的“关联已知函数”是指程序中调用的两个函数：User32.MessageBoxA和Kernel32.ExitProcess。

如图1-9所示，==OD工作区包括四大部分：==

==①指令及指令解释区（以下称①区）该区域位于整个界面的左上角，共包含四列。分别为指令所在的内存地址、指令字节码、反汇编后的指令语句，以及指令相关的注释。==OD的强大之处在于，它将许多难懂的指令字节码反解释成了汇编指令，并附以形象的说明。

例如，在内存地址0x0040101E处的指令字节码FF25 00204000，其对应的汇编指令是一个远跳转指令：

------

JMP DWORD PTR DS:[＜＆kernel32.ExitProcess＞]

------

而该位置处的数据则是一个内存地址。该地址指向了kernel32.dll动态链接库中函数ExitProcess的起始位置。

==②寄存器及运行状态区（以下称②区）该区域位于整个界面的右上角，包含了所有的32位寄存器，如eax、ebx、ecx、esi、edi、esp、ebp等==。大家要特别关注以下几个寄存器：

==ebp（栈基地址指针）==

==esp（栈顶指针）==

==eip（指向下一条要执行的指令的位置）==

除了寄存器的值外，该区还显示所有段寄存器的值及标志位的值，如FS段，这个段在后面讲到异常的时候会用到。

==③代码和数据字节码区（以下称③区）==该区域位于整个界面的左下角，它包含了指定内存范围的字节码，我们可以通过菜单命令随时查看当前内存中的数据。

==④栈区（以下称④区）该区域位于整个界面的右下角==，它反映了当前栈的分配情况及栈在程序运行过程中的变化情况。

#### 2.HelloWorld.exe的跟踪执行

跟踪一个程序的执行不仅可以帮助我们判断程序是否在按照自己预先设计的思路运行，还可以使我们了解某个时刻计算机的寄存器、栈、全局变量、内存等的状态，便于我们理解和更好地把握程序运行过程，优化程序设计，提高编程水平。

对HelloWorld.exe的跟踪执行主要是通过OD调试菜单下的两个主要选项进行的，它们分别是：

==F7：单步步入==

==F8：单步步过==

这两个选项是跟踪HelloWorld.exe执行时使用频率最高的两个选项。单步步入表示按照指令顺序一个一个地执行。如果遇到跳转指令，则执行跳转；如果遇到调用子程序语句的call指令，则跳转到子程序内部执行。单步步过和单步步入的原理基本一致，唯一不同之处就是如果遇到子程序调用，则将该调用当成一条指令执行，并不进入子程序内部。以下是调试HelloWorld.exe的全过程，分两部分来分析：从开始到调用MessageBox部分，ExitProcess部分。

##### （1）从开始到源代码第23行的调用指令invoke MessageBox

按一次F7键，你会发现程序开始执行虚拟内存地址0x00401000处的指令，并将执行后的结果显示到相应的区域，EIP指针移动到0x00401002处。由于0x00401000处的指令为压栈操作，仔细观察栈区，图1-10是指令执行前后的栈区数据对比。

![image](https://github.com/YangLuchao/img_host/raw/master/20230725/image.3sleo4ny6540.webp)

图　1-10　指令执行前后栈区的变化

可以看出，执行后，栈顶指针向低地址移动了4个字节，在移动后多出的空间中存放了0x00000000这个值。该操作翻译成汇编指令即为：push 0。再按一次F7键，执行的汇编指令为：push 0；再按一次F7键，执行的汇编指令为：push HelloWor.00403000。

其中，HelloWor是HelloWorld.exe进程的缩写，其后的值0x00403000为虚拟内存地址。该地址位于操作系统分配给进程的数据地址空间，从图1-9的③区中即可看到完整的内容。这次推入栈的是一个内存地址，通过查看字节码可以获知该地址正是指向在程序数据段中声明的变量szText。从另一个侧面，我们也知道了操作系统在运行HelloWorld.exe进程时，为该进程的数据段.data分配了1000h个字节，其内存起始位置与代码段的起始位置（0x00401000）相差0x2000个字节。

再按一次F7键，执行的汇编指令为：push 0；再按一次F7键，执行的汇编指令为：call＜JMP.＆user32.MessageBoxA＞。这条指令是一个子程序调用指令。执行到此，源代码第23行（见代码清单1-1)的调用才算结束。

------

23 invoke MessageBox,NULL,offset szText,NULL,MB_OK

------

在汇编语言中，汇编指令中函数调用参数的书写顺序与执行时的压栈顺序刚好相反。如前所述，四个压栈动作对应的参数关系如下：

![image](https://github.com/YangLuchao/img_host/raw/master/20230725/image.30xxpluavmq0.webp)

call调用指令在遇到ret指令后会完成调用，并返回到该指令的下一条指令继续执行，而这条指令紧跟着的下一条指令是函数ExitProcess的参数压栈指令push 0。

为了查看执行顺序是否与我们判断的一致，在第一个call指令处使用F8键，不再跟踪函数＆user32.MessageBoxA内部单步执行。结果和我们预想的一致，程序执行完显示窗口的操作后（此时屏幕上将弹出提示窗口）将eip定位到push 0处，即：

![image](https://github.com/YangLuchao/img_host/raw/master/20230725/image.2fe1fxlamjvo.webp)

注意　此时该压栈指令并未执行。当我们在屏幕提示窗口上单击“确定”后，将会促使eip指令指针继续顺序执行。

##### （2）源代码第24行的调用指令invoke ExitProcess

按F7键，压栈指令执行，将下一个调用的参数入栈：push 0。再按一次F7键，执行的汇编指令为：call＜JMP.＆kernel32.ExitProcess＞。这一次我们通过步入操作来执行该调用。由于该处是一个近跳转指令，所以按F7键以后，eip定位到的下一条指令是：

------

0040101E.-FF25 00204000 JMP DWORD PTR DS:[＜＆kernel32.ExitProcess＞]

------

> 注意　观察这条指令，这是一个双字跳转，跳转到相对于进程空间的绝对内存地址0x00402000处。这个位置的数据是个什么样子呢？我们可以借助③区（图1-9）来查看。

选择查看菜单的“内存”选项，OD将此时操作系统为HelloWorld.exe进程分配的内存空间大致显示出来，见图1-11。建议大家仔细研究一下这个内存分配图，这将为以后我们研究Windows执行EXE程序的内幕打好基础。

![image](https://github.com/YangLuchao/img_host/raw/master/20230725/image.6tcc3v32kfk0.webp)

图　1-11　进程内存分配

==需要特别注意的是，内存地址0x00402000开始的1000h个字节被操作系统分配给HelloWorld.exe进程的.rdata区段。该区段被注释为“输入表”（即“导入表”）==，这个概念在第4章专门介绍。如果想知道这个位置的详细数据，在.rdata行上单击鼠标右键，在弹出的菜单中选择“数据”，将弹出从该位置开始的1000h个字节内容，见图1-12。

![image](https://github.com/YangLuchao/img_host/raw/master/20230725/image.5k38z6dlpys0.webp)

图　1-12　输入表的内存数据

从0x00402000处取出的值为0x7c81cb12。这个值正是ExitProcess函数在HelloWorld.exe进程地址空间的绝对内存地址！返回到①区按一次F7键跟进，会发现指令区刚好跳转到0x7c81cb12处，以下是顺序执行的指令序列：

![image](https://github.com/YangLuchao/img_host/raw/master/20230725/image.616ju02ds500.webp)

如果大家有兴趣，最好使用步入技术跟踪执行到程序返回HelloWorld.exe进程的ret指令；可以完整地看到函数＆kernel32.ExitProcess在用户层都调用了哪些动态链接库的哪些函数，以及在结束进程时都执行了哪些操作，这对于间接了解操作系统对进程的管理方式有很大帮助。

在这次跟踪分析的过程中，我们获得了这样的一些信息：==汇编语言编译链接的程序的可执行代码在被装入操作系统后，代码的执行入口点被设置在进程地址空间的0x00401000处，大小为1000h；紧跟着是输入表，也占1000h字节；最后是数据段，大小为1000h。以下是EXE文件被加载到内存后的部分结构==，如图1-13所示。

![image](https://github.com/YangLuchao/img_host/raw/master/20230725/image.6oud2hf3tgw0.webp)

图　1-13　EXE文件被装载到内存后的部分结构

## 1.2.2　修改EXE文件字节码

OD不仅可以让我们对EXE文件进行反汇编和单步执行调试，还可以对目标EXE文件进行修改，后面的许多章节都会涉及这一操作。下面我们对HelloWorld.exe文件中的部分字节码进行更改，将显示信息"HelloWorld"更改为"HelloWorld-modified by OD"。这种修改要成功，要求更改后的字符串长度不能超出EXE中数据段的范围。幸运的是，由于==链接器在进行链接时是以200h字节对齐段长度，即数据段的长度要大于等于200h字节==，所以这次修改一定可以成功。

==在③区的“HEX数据”列中的第一个字节位置单击鼠标右键，选择“复制到可执行文件”，弹出的内容已不再是内存的数据了，因为窗口中第一列显示的地址明显不是内存地址，而是文件的偏移量==，如图1-14所示。

![image](https://github.com/YangLuchao/img_host/raw/master/20230725/image.6t8hv3kezgw0.webp)

图　1-14　OD中内存地址与文件地址的互换

==选中足够数量的字节，在选中区域单击鼠标右键，依次选择“二进制”→“编辑”，在弹出的对话框的ASCⅡ文本框中输入"HelloWorld-modified by OD"。注意，“保持大小”一项要处在勾选状态。完成后单击“确定”按钮==，如图1-15所示。

![image](https://github.com/YangLuchao/img_host/raw/master/20230725/image.4dllzxm7zeg0.webp)

图　1-15　保存修改

此时，数据尚未被保存到相应的EXE文件中，再次单击鼠标右键，选择“保存文件”，系统会有一些提示让你选择要保存的文件并提示是否覆盖，均选择确认按钮。至此，EXE文件字节码修改成功。运行HelloWorld.exe，会发现提示信息已经被修改。

在这个例子中，我们只是给大家演示如何使用OD更改EXE文件字节码，而真正修改EXE文件字符串常量的方法很复杂，不能用以上方法替代。

如果说OD是一个擅长动态分析的软件，那么W32DASM则是一个擅长静态分析的软件。后者可以标识整个EXE文件中指令间的调用关系，对于跟踪和识别指令之间的承前启后的关系有很大的帮助，该软件在随书文件 [[1\]](file:///Applications/Koodo Reader.app/Contents/Resources/app.asar/build/text00013.html#ch1-back) 中可以找到。

以下是使用W32DASM打开HelloWorld.exe后的输出：

![image](https://github.com/YangLuchao/img_host/raw/master/20230725/image.17po28d3ako0.webp)

![image](https://github.com/YangLuchao/img_host/raw/master/20230725/image.66nksb673740.webp)

==静态分析最大的好处是：能从当前指令反查调用此处的指令所在==。例如，地址0x00401018处的指令是谁调用了呢（加粗部分）？请分析如下代码行：

------

```cpp
*Referenced by a CALL at Address:

|:0040100B

|
```



------

哦，知道了，原来是0x0040100B处的指令调用了它。

目前，大家可能感觉不到有什么用处，等学到后面就会知道了。

> ==提示　由于静态分析和动态分析均正确地模拟了Windows操作系统的进程装载机制，所以二者的指令地址是一致的。==

# 1.3　十六进制编辑软件FlexHex

目前，有很多优秀的十六进制编辑器，如FlexHex、WinHex、UltraEdit、HEdit等。本书选用FlexHex，因为这个编辑器操作起来很容易。只要掌握了简单的查找和编辑操作，对于阅读本书来讲就已经足够了。图1-16是打开了HelloWorld.exe文件后的主界面。与所有的十六进制编辑器一样，内容区包含了偏移量、16个字节的十六进制值、ASCⅡ码和Unicode码，最后一列可以在查看资源表中资源的Unicode字符串时使用。如果想修改某个字节的值，直接将光标定位到该字节处，然后输入修改后的值即可，修改后的值将以红色字符显示。要想使所有的修改生效，只需要保存文件即可。

![image](https://github.com/YangLuchao/img_host/raw/master/20230725/image.6rvr8gzmsb00.webp)

图　1-16　FlexHEX主界面

它的导出功能很实用，可以将界面显示的内容复制到剪贴板。比如，选中字节码后，单击鼠标右键，选择“复制格式”，会弹出如图1-17所示对话框。在该对话框中，可以灵活地选择导出方式。

![image](https://github.com/YangLuchao/img_host/raw/master/20230725/image.656lqhb93tg0.webp)

图　1-17　FlexHEX导出格式定义

导出的内容会以如下格式出现在剪贴板中：

![image](https://github.com/YangLuchao/img_host/raw/master/20230725/image.7lcpf7n09hw0.webp)

# 1.4　破解实例：U盘监控器

略

# 1.5　初识PE文件

==PE（Portable Executeable File Format，可移植的执行体文件格式），使用该格式的目标是使链接生成的EXE文件能在不同的CPU工作指令下工作。==

可执行文件的格式是操作系统工作方式的真实写照。Windows操作系统中可执行程序有好多种，比如COM、PIF、SCR、EXE等，这些文件的格式大部分都继承自PE。其中，EXE是最常见的PE文件，动态链接库（大部分以dll为扩展名的文件）也是PE文件，本书只涉及这两种类型的PE文件。

我们首先以HelloWorld.exe为例，简单地了解一下PE格式文件的字节码编排。如果你手头没有合适的软件，还想获取像FlexHEX那样的十六进制格式字节码内容，可以使用以下步骤。

**步骤1　生成1.txt文件，输入的内容如下：**

------

```cpp
d
d
......
d
d
q
```



------

其中d字符个数的计算公式为：

==$$d字符的个数 = 文件大小/（16×8）= 2560/（16×8）= 20$$==

**步骤2　将HelloWorld.exe更改为123。注意，不要加扩展名。**

**步骤3　在命令提示符下运行以下命令：**

------

D:\masm32\source\chapter1＞Debug 123＜1.txt＞2.txt

------

这样，就可以生成规则排列的十六进制字节码并存储在文件2.txt中，如代码清单1-2所示。是不是和FlexHEX显示的结果差不多呢？

代码清单1-2　HelloWorld.exe文件的字节码（chapter1\2.txt）

![image](https://github.com/YangLuchao/img_host/raw/master/20230725/image.y26su6z0ai8.webp)

![image](https://github.com/YangLuchao/img_host/raw/master/20230725/image.22j28rtx13kw.webp)

特别注意　此处节选的PE文件字节码是从地址13B7:0100开始的，而非从13B7:0000开始！

==仔细观察上面列出的字节码清单，大家可以看到，笔者有意识地将这些字节码以每200h大小作为一组分隔开。原因是在PE格式中，每一个大的部分的对齐方式就是按照200h大小对齐的。这样，分出的每一部分都会有一个名称==，图1-24是以程序视角看到的HelloWorld.exe的各组成部分。

如图所示，从文件开始到0x03ff偏移处为PE的头部信息，其中记录了整个PE文件的头结构。关于它的数据组织与数据结构在第3章会有详细描述。从偏移地址0x0400开始的200h字节为指令字节码即代码段部分。从偏移0x0600处开始的200h字节为程序中引入的函数描述部分，这些描述主要是为了让操作系统能在装载PE文件的同时，将相关的动态链接库也装入进程地址空间，实现代码的重用。从偏移0x0800处开始的200h个字节则是程序中数据段.data定义的数据空间，其中包含了关于全局变量的定义。

![image](https://github.com/YangLuchao/img_host/raw/master/20230725/image.5ebhng82s440.webp)

图　1-24　程序视角下的PE结构

提示　以后的大部分内容都将围绕这个简单的PE文件来介绍。所以，建议读者把电子版的代码清单1-2重新排版并打印出来，以便能随时看到它。
