[toc]

如果你不想让其他人使用自己的电脑，你可以选择以下三种方法：

1. 通过BIOS加密电脑。
2. 为操作系统的用户设置密码。
3. 将本机重要的可运行程序都设置为密码运行。

虽然电脑中安装的某些软件，其本身已经具备密码登录功能，如QQ、宽带上网拨号软件等，但大部分软件并不具备密码登录的功能。

==这种情况下，就可以选择使用EXE加锁器==。==EXE加锁器是为EXE程序的运行增加权限的一种技术==。==如果用户想运行加锁的程序，首先会弹出密码输入框，正确则可以继续使用，错误则退出程序==。==它本质上是一个补丁，可以改变程序的运行流程==；通过在原始PE流程的最开始处加入代码，使得被加锁的程序运行前首先弹出用户登录对话框。如果用户输入信息认证发生错误，则会提前终止程序。

==结合捆绑器技术，EXE加锁器还可以辅助完成对文件和文件夹的加密==。假设使用第18章开发的EXE捆绑器，将某个待加密的目录完成捆绑操作，被捆绑以后的所有文件和文件夹被存储在一个PE文件中。但是，只要有人执行这个PE文件，所有的文件就会被释放出来。这样，就失去了加密的意义。

最好的解决办法就是，==使用本章介绍的EXE加锁器，将捆绑后生成的PE文件再做一次加锁，这样就实现了对文件和文件夹加密的功能==。

# 20.1　基本思路

因为EXE加锁器是一个补丁程序，所以本章将重点介绍补丁程序的代码。

本节要开发的补丁程序具备以下三个特性：

1. 窗口程序无需资源文件
2. 无需导入表
3. 无需重定位

==弹出的窗口程序需要接收用户的输入，并根据输入信息执行相应的操作判断，是继续执行程序还是退出程序==。

弹出的窗口中会提供几个控件，如文本编辑控件、按钮等，这些控件在前几章里都是定义在以.rc为扩展名的资源文件中。但是，本章将其作为补丁程序，需要将控件合并到目标PE中，因为，如果创造一个无需资源文件的窗口程序，就会省去打补丁时合并资源表的操作。关于免重定位和免导入表的技术请参照本书的第6章和第11章。

==下面将分三步来开发这个加锁器代码，涉及的程序有==：

1. `nores.asm`（免资源文件的窗口程序）
2. `login.asm`（为窗口程序添加免重定位特性）
3. `patch.asm`（最终的补丁程序）

# 20.2　免资源文件的窗口程序nores.asm

==在汇编语言中创建窗口程序，可以使用资源文件，按照资源定义的规则使用脚本语句逐句定义窗口中的控件；也可以不使用资源文件，通过调用函数CreateWindowEx创建每个控件==。要实现窗口程序的免资源文件特性，必须选择使用后者。

## 20.2.1　窗口创建函数`CreateWindowEx`

==该函数可以创建一个具有扩展风格的重叠式窗口、弹出式窗口或子窗口==。所有的控件在系统中都被认为是一个子窗口。该函数原型定义如下：

------

```c
HWND CreateWindowEx(
	DWORD dwExStyle，	//窗口的扩展风格
	LPCTSTR lpClassName,//窗口所属的类
	LPCTSTR lpWindowName,//标题栏文字
	DWORD dwStyle，		//
	int x，				//窗口坐标x的值
	int y,				 //窗口坐标y的值
	int nWidth，			//窗口的宽度
	int nHeight，		//窗口的高度
	HWND hWndParent，	//窗口所属父窗口句柄
	HMENU hMenu，		//窗口菜单句柄
	HANDLE hInstance，	//窗口所处应用程序句柄
	LPVOID lpParam		//
);
```

------

函数参数解释如下：

1. 1）`dwExStyle`：==指定窗口的扩展风格==。该参数可以是下列值：
   1. `WS_EX_ACCEPTFILES`：指定以该风格创建的窗口接受一个拖曳文件。
   2. `WS_EX_APPWINDOW`：当窗口可见时，将一个顶层窗口放置到任务条上。
   3. `WS_EX_CLIENTEDGE`：指定窗口有一个带阴影的边界。
   4. `WS_EX_CONTEXTHELP`：在窗口的标题条包含一个问号标志 [[1\]](file:///Applications/Koodo Reader.app/Contents/Resources/app.asar/build/text00308.html#ch1-back) 。
   5. `WS_EX_CONTROLPARENT`：允许用户使用Tab键在窗口的子窗口间跳转。
   6. `WS_EX_DLGMODALFRAME`：创建一个带双边的窗口；该窗口可以在`dwStyle`中指定`WS_CAPTION`风格来创建一个标题栏。
   7. `WS_EX_LEFT`：窗口具有左对齐属性，这是默认设置的。
   8. `WS_EX_LEFTSCROLLBAR`：滚动条在客户区的左部分。该属性只针对部分语言有效，若是其他语言，该风格被忽略并且不作为错误处理。
   9. `WS_EX_LTRREADING`：窗口文本以`LEFT`到`RIGHT`（自左向右）属性的顺序显示。这是默认设置的。
   10. `WS_EX_MDICHILD`：创建一个`MDI`子窗口。
   11. `WS_EX_NOPATARENTNOTIFY`：指明以这个风格创建的窗口在被创建和销毁时不向父窗口发送`WM_PARENTNOTFY`消息。
   12. `WS_EX_OVERLAPPED`：`WS_EX_CLIENTEDGE`和`WS_EX_WINDOWEDGE`的组合。
   13. `WS_EX_PALETTEWINDOW`：为`WS_EX_WINDOWEDGE`、`WS_EX_TOOLWINDOW`和`WS_WX_TOPMOST`风格的组合。
   14. `WS_EX_RIGHT`：窗口具有普通的右对齐属性，该属性只针对特定的语言有效。
   15. `WS_EX_RIGHTSCROLLBAR`：垂直滚动条在窗口的右边界。这是默认设置的。
   16. `WS_EX_RTLREADING`：窗口文本自左向右的顺序读出。该属性只针对特定的语言有效。
   17. `WS_EX_STATICEDGE`：为不接受用户输入的项创建一个三维边界风格。
   18. `WS_EX_TOOLWINDOW`：创建工具窗口，即窗口是一个游动的工具条 [[2\]](file:///Applications/Koodo Reader.app/Contents/Resources/app.asar/build/text00308.html#ch2-back) 。
   19. `WS_EX_TOPMOST`：指明以该风格创建的窗口应放置在所有非最高层窗口的上面。
   20. `WS_EX_TRANSPARENT`：指定以这个风格创建的窗口在其下的同属窗口已重画时，该窗口才跟随着重画以便能显示其下的同属窗口，确保该窗口是透明的。
2. 2）`IpClassName`：==指向一个空结束的字符串或整型数==。==如果`lpClassName`是一个字符串，它指定了窗口的类名==。==这个类名可以是任何用函数`RegisterClassEx`注册的类名，或是任何预定义的控制类名==。
3. 3）`lpWindowName`：==指向一个指定窗口名的空结束的字符串指针==。==如果窗口风格指定了标题条，由`lpWindowName`指向的窗口标题将显示在标题条上==。==当使用`CreateWindow`函数来创建控件（例如按钮、选择框和静态控件）时，可使用`lpWindowName`来指定控件上要显示的文本==。
4. 4）`dwStyle`：指定创建窗口的风格。
5. 5）`x`：窗口x坐标的值。
6. 6）`y`：窗口y坐标的值。
7. 7）`nWidth`：窗口的宽度。
8. 8）`nHeigth`：窗口的高度。
9. 9）`hWndParent`：父窗口句柄。
10. 10）`hMenu`：附加在窗口上的菜单句柄。
11. 11）`hlnstance`：与窗口相关联的模块实例的句柄。
12. 12）`lpParam`：指向一个值的指针，该值传递窗口的`WM_CREATE`消息。
13. 13）返回值：如果函数执行成功，返回值为新窗口的句柄；如果函数失败，返回值为NULL。若想获得更多错误信息，可以调用`GetLastError`函数。

> [[1\]](file:///Applications/Koodo Reader.app/Contents/Resources/app.asar/build/text00308.html#ch1) 注意，`WS_EX_CONTEXTHELP`不能与`WS_MAXIMIZEBOX`和`WS_MINIMIZEBOX`同时使用。并且当窗口具有`WS_EX_CONTEXTHELP`风格时还必须同时指定使其具备`WS_SYSMENU`风格。
>
> [[2\]](file:///Applications/Koodo Reader.app/Contents/Resources/app.asar/build/text00308.html#ch2) 工具窗口的标题条比一般窗口的标题条短，并且窗口标题以小字体显示。工具窗口不在任务栏里显示，当用户按下`Alt+Tab`键时，工具窗口不在对话框里显示。如果工具窗口有一个系统菜单，它的图标也不会显示在标题栏里，但是，可以通过点击鼠标右键或`Alt+Space`来显示菜单。

## 20.2.2　创建用户登录窗口的控件

下面分析要创建的EXE加锁器的窗口程序界面所包含的控件，EXE加锁器用户登录的窗口界面如图20-1所示。

![image](https://github.com/YangLuchao/img_host/raw/master/20231030/image.4u5m3e5bp6a0.jpg)

图　20-1　免资源文件的用户登录窗口界面

如图所示，弹出的用户登录窗口上共有6个控件，包括2个静态文本、2个文本框和2个按钮。这6个控件的相关信息见表20-1。

![image](https://github.com/YangLuchao/img_host/raw/master/20231030/image.3n93v4ycw9k0.jpg)

表中每一个控件都需要使用函数CreateWindowEx创建。

## 20.2.3　窗口程序源代码

代码清单20-1演示了如何创建一个没有资源文件的窗口程序。窗口程序具备窗口消息处理子程序，可以接收用户输入，接收窗口上控件发出的消息。

代码清单20-1　不需要资源文件的登录窗口程序（chapter20\noRes.asm）

------

```assembly
;------------------------
; 该程序演示了一个不需要资源文件的登录窗口示例
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
include    gdi32.inc
includelib gdi32.lib

ID_BUTTON1         equ   1
ID_BUTTON2         equ   2
ID_LABEL1          equ   3
ID_LABEL2          equ   4
ID_EDIT1           equ   5
ID_EDIT2           equ   6

;数据段
.data

szCaption          db  '欢迎您！',0
szText             db  '您是合法用户，请使用该软件！',0
szCaptionMain      db  '系统登录',0
szClassName        db  'Menu Example',0
szButtonClass      db  'button',0
szEditClass        db  'edit',0
szLabelClass       db  'static',0

szButtonText1      db  '登  录',0
szButtonText2      db  '取  消',0
szLabel1           db  '用户名：',0
szLabel2           db  '密   码：',0
lpszUser           db  'admin',0       ;模拟用户名和密码
lpszPass           db  '123456',0

szBuffer           db  256 dup(0)
szBuffer2          db  256 dup(0)

hInstance          dd  ?
hWinMain           dd  ?
hWinEdit           dd  ?
hButton1           dd  ?
hButton2           dd  ?
hLabel1            dd  ?
hLabel2            dd  ?
hEdit1             dd  ?
hEdit2             dd  ?

 ; 代码段
  .code
;----------------
; 退出程序
;----------------
_Quit  proc
       pushad
       invoke DestroyWindow,hWinMain
       invoke PostQuitMessage,NULL
       popad
       ret
_Quit  endp
_Exit proc
       invoke ExitProcess,NULL
_Exit endp
;------------------
; 窗口消息处理子程序
;------------------
_ProcWinMain proc uses ebx edi esi,hWnd,uMsg,wParam,lParam
      local @stPos:POINT

      mov eax,uMsg
      
      .if eax==WM_CREATE
          mov eax,hWnd
          mov hWinMain,eax

          ;标签
          invoke CreateWindowEx,NULL,\
                 addr szLabelClass,addr szLabel1,WS_CHILD or WS_VISIBLE, \
                 10,20,100,30,hWnd,ID_LABEL1,hInstance,NULL
          mov hLabel1,eax

          invoke CreateWindowEx,NULL,\
                 addr szLabelClass,addr szLabel2,WS_CHILD or WS_VISIBLE, \
                 10,50,100,30,hWnd,ID_LABEL2,hInstance,NULL
          mov hLabel2,eax

          ;文本框
          invoke CreateWindowEx,WS_EX_TOPMOST,\
                 addr szEditClass,NULL,WS_CHILD or WS_VISIBLE \
                 or WS_BORDER,\
                 105,19,175,22,hWnd,ID_EDIT1,hInstance,NULL
          mov hEdit1,eax
          invoke CreateWindowEx,WS_EX_TOPMOST,\
                 addr szEditClass,NULL,WS_CHILD or WS_VISIBLE \
                 or WS_BORDER or ES_PASSWORD,\
                 105,49,175,22,hWnd,ID_EDIT2,hInstance,NULL
          mov hEdit2,eax

          ;按钮
          invoke CreateWindowEx,NULL,\
                 addr szButtonClass,addr szButtonText1,WS_CHILD or WS_VISIBLE, \
                 120,100,60,30,hWnd,ID_BUTTON1,hInstance,NULL
          mov hButton1,eax

          invoke CreateWindowEx,NULL,\
                 addr szButtonClass,addr szButtonText2,WS_CHILD or WS_VISIBLE, \
                 200,100,60,30,hWnd,ID_BUTTON2,hInstance,NULL
          mov hButton2,eax
      .elseif eax==WM_COMMAND  ;处理菜单及加速键消息
          mov eax,wParam
          movzx eax,ax
          .if eax==ID_BUTTON1
             invoke GetDlgItemText,hWnd,ID_EDIT1,\
                    addr szBuffer,sizeof szBuffer
             invoke GetDlgItemText,hWnd,ID_EDIT2,\
                    addr szBuffer2,sizeof szBuffer2
             invoke lstrcmp,addr szBuffer,addr lpszUser
             .if eax
                jmp _ret
             .endif
             invoke lstrcmp,addr szBuffer2,addr lpszPass
             .if eax
                jmp _ret
             .endif
             ;invoke MessageBox,NULL,offset szText,offset szCaption,MB_OK
             jmp _ret1
          .elseif eax==ID_BUTTON2
_ret:        call _Exit
_ret1:       call _Quit
          .endif
      .elseif eax==WM_CLOSE
      .else
          invoke DefWindowProc,hWnd,uMsg,wParam,lParam
          ret
      .endif
      
      xor eax,eax
      ret
_ProcWinMain endp


;----------------------
; 主窗口程序
;----------------------
_WinMain  proc

       local @stWndClass:WNDCLASSEX
       local @stMsg:MSG
       local @hAccelerator

       invoke GetModuleHandle,NULL
       mov hInstance,eax

       ;注册窗口类
       invoke RtlZeroMemory,addr @stWndClass,sizeof @stWndClass
       mov @stWndClass.hIcon,NULL
       mov @stWndClass.hIconSm,NULL

       mov @stWndClass.hCursor,NULL
       push hInstance
       pop @stWndClass.hInstance
       mov @stWndClass.cbSize,sizeof WNDCLASSEX
       mov @stWndClass.style,CS_HREDRAW or CS_VREDRAW
       mov @stWndClass.lpfnWndProc,offset _ProcWinMain
       mov @stWndClass.hbrBackground,COLOR_WINDOW
       mov @stWndClass.lpszClassName,offset szClassName
       invoke RegisterClassEx,addr @stWndClass

       ;建立并显示窗口
       invoke CreateWindowEx,WS_EX_CLIENTEDGE,\
              offset szClassName,offset szCaptionMain,\
              WS_OVERLAPPED or WS_CAPTION or \
              WS_MINIMIZEBOX,\
              350,280,300,180,\
              NULL,NULL,hInstance,NULL
       mov  hWinMain,eax
       
       invoke ShowWindow,hWinMain,SW_SHOWNORMAL
       invoke UpdateWindow,hWinMain ;更新客户区，即发送WM_PAINT消息

   
       ;消息循环
       .while TRUE
          invoke GetMessage,addr @stMsg,NULL,0,0
          .break .if eax==0
          invoke TranslateAccelerator,hWinMain,\
                 @hAccelerator,addr @stMsg
          .if eax==0
             invoke TranslateMessage,addr @stMsg
             invoke DispatchMessage,addr @stMsg
          .endif
       .endw
       ret
_WinMain endp


start:
    call _WinMain
    invoke MessageBox,NULL,addr szCaptionMain,NULL,MB_OK
    ret
    end start

```

------

行161～174注册一个窗口类。行171为该窗口类中指定了消息处理子程序为`_ProcWinMain`。

行176～186建立主窗口，并显示。此时窗口上的6个控件尚未被画出。

行189～199是消息循环。通过调用函数`GetMessage`从调用线程的消息队列里取一个消息，并将其放于指定的结构变量`@stMsg`；然后，使用`TranslateMessage`和`DispatchMessage`转发和派发消息到消息处理子程序。

消息处理子程序负责接收用户的输入和鼠标按键消息。用户点击“登录”按钮后，便从用户名文本框和密码文本框取回用户输入的信息，并与数据段中事先定义的字符串进行比对；如果一致，则允许用户继续运行程序，否则退出程序。因为现在尚处在测试阶段，所以根据不同的比对结果分别弹出了具有不同显示信息的对话框。

消息处理子程序还有一项很重要的任务，就是负责将窗体上的6个控件依次画出来。该代码在响应消息`WM_CREATE`的处理流程中，具体见代码行80～115。

测试该程序的重点是要确定程序的转向是否正确。通过调试发现，当提供的用户名和密码正确的时候，程序转向显示信息的代码；不正确的时候则退出程序，测试效果与预先设计的完全一样。接下来就要改造这个源程序，使其符合免重定位特性。

# 20.3　免重定位的窗口程序login.asm

==这是编写补丁程序的第二步，基于上一节已经测试执行正确的`nores.asm`，修改其中的代码，使其符合免重定位、免导入表特性。修改包括：将数据段转移到代码段、所有涉及的直接寻址均采用免重定位技术==。新的程序命名为login.asm，见代码清单20-2。

> 注意　此时，该程序不符合嵌入补丁框架的结构，且所有的函数调用没有使用动态加载技术，因此还不具备补丁程序特性。

代码清单20-2　免重定位信息的用户登录窗口（chapter20\login.asm）

------

```assembly
;------------------------
; 该程序演示了一个不需要资源文件的登录窗口示例
; 免重定位信息，无数据段
; 戚利
; 2010.6.28
;------------------------
    .386
    .model flat,stdcall
    option casemap:none

include    windows.inc
include    user32.inc
includelib user32.lib
include    kernel32.inc
includelib kernel32.lib
include    gdi32.inc
includelib gdi32.lib

ID_BUTTON1         equ   1
ID_BUTTON2         equ   2
ID_LABEL1          equ   3
ID_LABEL2          equ   4
ID_EDIT1           equ   5
ID_EDIT2           equ   6



;代码段
    .code
jmp start

szCaption          db  '欢迎您！',0
szText             db  '您是合法用户，请使用该软件！',0
szCaptionMain      db  '系统登录',0
szClassName        db  'Menu Example',0
szButtonClass      db  'button',0
szEditClass        db  'edit',0
szLabelClass       db  'static',0

szButtonText1      db  '登  录',0
szButtonText2      db  '取  消',0
szLabel1           db  '用户名：',0
szLabel2           db  '密   码：',0
lpszUser           db  'admin',0       ;模拟用户名和密码
lpszPass           db  '123456',0

szBuffer           db  256 dup(0)
szBuffer2          db  256 dup(0)

hInstance          dd  ?
hWinMain           dd  ?
hWinEdit           dd  ?
dwRelocBase        dd  ?

;------------------------------------
; 根据kernel32.dll中的一个地址获取它的基地址
;------------------------------------
_getKernelBase  proc _dwKernelRetAddress
   local @dwRet

   pushad

   mov @dwRet,0
   
   mov edi,_dwKernelRetAddress
   and edi,0ffff0000h  ;查找指令所在页的边界，以1000h对齐

   .repeat
     .if word ptr [edi]==IMAGE_DOS_SIGNATURE  ;找到kernel32.dll的dos头
        mov esi,edi
        add esi,[esi+003ch]
        .if word ptr [esi]==IMAGE_NT_SIGNATURE ;找到kernel32.dll的PE头标识
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
; 获取指定字符串的API函数的调用地址
; 入口参数：_hModule为动态链接库的基址，_lpApi为API函数名的首址
; 出口参数：eax为函数在虚拟地址空间中的真实地址
;-------------------------------
_getApi proc _hModule,_lpApi
   local @ret
   local @dwLen

   pushad
   mov @ret,0
   ;计算API字符串的长度，含最后的零
   mov edi,_lpApi
   mov ecx,-1
   xor al,al
   cld
   repnz scasb
   mov ecx,edi
   sub ecx,_lpApi
   mov @dwLen,ecx

   ;从pe文件头的数据目录获取导出表地址
   mov esi,_hModule
   add esi,[esi+3ch]
   assume esi:ptr IMAGE_NT_HEADERS
   mov esi,[esi].OptionalHeader.DataDirectory.VirtualAddress
   add esi,_hModule
   assume esi:ptr IMAGE_EXPORT_DIRECTORY

   ;查找符合名称的导出函数名
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
   ;通过API名称索引获取序号索引再获取地址索引
   sub ebx,[esi].AddressOfNames
   sub ebx,_hModule
   shr ebx,1
   add ebx,[esi].AddressOfNameOrdinals
   add ebx,_hModule
   movzx eax,word ptr [ebx]
   shl eax,2
   add eax,[esi].AddressOfFunctions
   add eax,_hModule
   
   ;从地址表得到导出函数的地址
   mov eax,[eax]
   add eax,_hModule
   mov @ret,eax

_ret:
   assume esi:nothing
   popad
   mov eax,@ret
   ret
_getApi endp
;----------------
; 退出程序
;----------------
_Quit  proc
       pushad
       call @F   ; 免去重定位
@@:
       pop ebx
       sub ebx,offset @B   ;求定位基地址ebx       
       invoke DestroyWindow,[ebx+offset hWinMain]
       invoke PostQuitMessage,NULL
       popad
       ret
_Quit  endp

_Exit proc
       invoke ExitProcess,NULL
_Exit endp
;------------------
; 窗口消息处理子程序
;------------------
_ProcWinMain proc uses ebx edi esi,hWnd,uMsg,wParam,lParam
      local @stPos:POINT
      local hLabel1:dword
      local hLabel2:dword
      local hEdit1:dword
      local hEdit2:dword
      local hButton1:dword
      local hButton2:dword

      call @F   ; 免去重定位
   @@:
      pop ebx
      sub ebx,offset @B   ;求定位基地址ebx

      mov eax,uMsg
      
      .if eax==WM_CREATE
          mov eax,hWnd
          mov [ebx+offset hWinMain],eax

          ;标签
          mov eax,offset szLabelClass
          add eax,ebx
          mov ecx,offset szLabel1
          add ecx,ebx
      
          mov edx,[ebx+offset hInstance]

          push ebx
          invoke CreateWindowEx,NULL,\
                 eax,ecx,WS_CHILD or WS_VISIBLE, \
                 10,20,100,30,hWnd,ID_LABEL1,edx,NULL
          mov hLabel1,eax
          pop ebx

          mov eax,offset szLabelClass
          add eax,ebx
          mov ecx,offset szLabel2
          add ecx,ebx
      
          mov edx,[ebx+offset hInstance]

          push ebx
          invoke CreateWindowEx,NULL,\
                 eax,ecx,WS_CHILD or WS_VISIBLE, \
                 10,50,100,30,hWnd,ID_LABEL2,edx,NULL
          mov hLabel2,eax
          pop ebx

          ;文本框
          mov eax,offset szEditClass
          add eax,ebx
     
          mov edx,[ebx+offset hInstance]

          push ebx
          invoke CreateWindowEx,WS_EX_TOPMOST,\
                 eax,NULL,WS_CHILD or WS_VISIBLE \
                 or WS_BORDER,\
                 105,19,175,22,hWnd,ID_EDIT1,edx,NULL
          mov hEdit1,eax
          pop ebx

          mov eax,offset szEditClass
          add eax,ebx
     
          mov edx,[ebx+offset hInstance]
          push ebx
          invoke CreateWindowEx,WS_EX_TOPMOST,\
                 eax,NULL,WS_CHILD or WS_VISIBLE \
                 or WS_BORDER or ES_PASSWORD,\
                 105,49,175,22,hWnd,ID_EDIT2,edx,NULL
          mov hEdit2,eax
          pop ebx

          ;按钮
          mov eax,offset szButtonClass
          add eax,ebx
          mov ecx,offset szButtonText1
          add ecx,ebx
     
          mov edx,[ebx+offset hInstance]
          push ebx
          invoke CreateWindowEx,NULL,\
                 eax,ecx,WS_CHILD or WS_VISIBLE, \
                 120,100,60,30,hWnd,ID_BUTTON1,edx,NULL
          mov hButton1,eax
          pop ebx

          mov eax,offset szButtonClass
          add eax,ebx
          mov ecx,offset szButtonText2
          add ecx,ebx
     
          mov edx,[ebx+offset hInstance]
          push ebx 
          invoke CreateWindowEx,NULL,\
                 eax,ecx,WS_CHILD or WS_VISIBLE, \
                 200,100,60,30,hWnd,ID_BUTTON2,edx,NULL
          mov hButton2,eax
          pop ebx
      .elseif eax==WM_COMMAND  ;处理菜单及加速键消息
          mov eax,wParam
          movzx eax,ax
          .if eax==ID_BUTTON1
             mov eax,offset szBuffer
             add eax,ebx
             push ebx
             invoke GetDlgItemText,hWnd,ID_EDIT1,\
                    eax,sizeof szBuffer
             pop ebx

             mov eax,offset szBuffer2
             add eax,ebx
             push ebx
             invoke GetDlgItemText,hWnd,ID_EDIT2,\
                    eax,sizeof szBuffer2
             pop ebx
             mov eax,offset szBuffer
             add eax,ebx
             mov ecx,offset lpszUser
             add ecx,ebx
             push ebx
             invoke lstrcmp,eax,ecx
             pop ebx
             .if eax
                jmp _ret
             .endif
             mov eax,offset szBuffer2
             add eax,ebx
             mov ecx,offset lpszPass
             add ecx,ebx
             push ebx
             invoke lstrcmp,eax,ecx
             pop ebx
             .if eax
                jmp _ret
             .endif

             ;invoke MessageBox,NULL,offset szText,offset szCaption,MB_OK
             jmp _ret1
          .elseif eax==ID_BUTTON2
_ret:        call _Exit
_ret1:       call _Quit
          .endif
      .elseif eax==WM_CLOSE
      .else
          invoke DefWindowProc,hWnd,uMsg,wParam,lParam
          ret
      .endif
      
      xor eax,eax
      ret
_ProcWinMain endp


;----------------------
; 主窗口程序
;----------------------
_WinMain  proc _base

       local @stWndClass:WNDCLASSEX
       local @stMsg:MSG
       local @hAccelerator

       mov ebx,_base
       push ebx
       invoke GetModuleHandle,NULL
       pop ebx
       mov [ebx+offset hInstance],eax

       push ebx
       ;注册窗口类
       invoke RtlZeroMemory,addr @stWndClass,sizeof @stWndClass
       mov @stWndClass.hIcon,NULL
       mov @stWndClass.hIconSm,NULL

       mov @stWndClass.hCursor,NULL

       pop ebx

       mov edx,offset _ProcWinMain
       add edx,ebx
       mov ecx,offset szClassName
       add ecx,ebx

       push [ebx+offset hInstance]
       pop @stWndClass.hInstance
       mov @stWndClass.cbSize,sizeof WNDCLASSEX
       mov @stWndClass.style,CS_HREDRAW or CS_VREDRAW
       mov @stWndClass.lpfnWndProc,edx
       mov @stWndClass.hbrBackground,COLOR_WINDOW
       mov @stWndClass.lpszClassName,ecx
       push ebx
       invoke RegisterClassEx,addr @stWndClass
       pop ebx

       mov edx,offset szClassName
       add edx,ebx
       mov ecx,offset szCaptionMain
       add ecx,ebx

       mov eax,offset hInstance
       add eax,ebx
       push ebx
       ;建立并显示窗口
       invoke CreateWindowEx,WS_EX_CLIENTEDGE,\
              edx,ecx,\
              WS_OVERLAPPED or WS_CAPTION or \
              WS_MINIMIZEBOX,\
              350,280,300,180,\
              NULL,NULL,[eax],NULL
       pop ebx
       mov  [ebx+offset hWinMain],eax
       
       mov edx,offset hWinMain
       add edx,ebx

       push ebx
       push edx
       invoke ShowWindow,[edx],SW_SHOWNORMAL
       pop edx
       invoke UpdateWindow,[edx] ;更新客户区，即发送WM_PAINT消息
       pop ebx
   
       ;消息循环
       .while TRUE
          push ebx
          invoke GetMessage,addr @stMsg,NULL,0,0
          pop ebx
          .break .if eax==0
          mov edx,offset hWinMain
          add edx,ebx

          push ebx
          invoke TranslateAccelerator,[edx],\
                 @hAccelerator,addr @stMsg
          pop ebx
          .if eax==0
             invoke TranslateMessage,addr @stMsg
             invoke DispatchMessage,addr @stMsg
          .endif
       .endw
       ret
_WinMain endp


start:
    ;取当前函数的堆栈栈顶值
    mov eax,dword ptr [esp]
    push eax
    call @F   ; 免去重定位
@@:
    pop ebx
    sub ebx,offset @B
    pop eax
    push ebx
    invoke _WinMain,ebx
    pop ebx
    mov eax,offset szCaptionMain
    add eax,ebx
    invoke MessageBox,NULL,eax,NULL,MB_OK
    jmpToStart   db 0E9h,0F0h,0FFh,0FFh,0FFh
    ret
    end start


```

------

如代码清单所示，在代码行162～165、行187～190、行429～432均使用了重定位技术，定义控件句柄的变量全部变成了函数的局部变量。

使用编译链接执行步骤来测试生成的login.exe程序，测试结果运行正常。

> ==注意　因为将数据段中定义的变量全部移到代码段，所以运行前需要在PE文件头部修改.text节的Characteristic属性为0E0000060h，否则会出现错误。==

# 20.4　补丁程序patch.asm

本节是编写补丁程序的最后一步。这一步将在第二步的基础上对login.asm进行修改，主要是完善login.asm的结构，使之符合本书13.3.1节定义的嵌入补丁框架的结构；最后，使用动态加载技术完成所有要调用的外部函数。

## 20.4.1　获取导入库及函数

为了完成一个免导入表的补丁程序，首先通过查找`login.asm`源代码，将代码中引入的所有动态链接库及调用的所有外部函数记录到表20-1中。

![image](https://github.com/YangLuchao/img_host/raw/master/20231030/image.3kvcfe6ykda0.jpg)

获取以上信息有三种办法：

1. 自己从源代码中查找这些函数，通过网络获取函数与动态链接库的关系。
2. 删除代码中的`include`和`includelib`后编译程序，会出现错误提示，每一行错误提示的最后就是程序中调用的函数名。
3. 使用FlexHex找到login.exe的导入表，因为链接程序已经对函数进行了分类，所以从login.exe的字节码中就能获取这些函数，以及它们与动态链接库的关系。

第一种方法太慢；第二种方法会显示许多重名的函数，效率也不高；因此，建议大家采用第三种方法。以下是利用第三种方式获取的login.exe导入表的部分内容：

![image](https://github.com/YangLuchao/img_host/raw/master/20231030/image.18ygwjx3v14w.jpg)

如上所示，导入表字符串首先列出被调用的各个函数名，然后才列出这些函数所处的动态链接库的名字。根据这些字节码信息，就很容易得到表20-1的内容。

## 20.4.2　按照补丁框架修改login.asm

==依据嵌入补丁框架编写规则（详见13.3.2节）对原始的login.asm进行修改，这些修改包括：修改函数定义、分解函数调用语句、修改程序结构。首先来看如何修改函数，使其由静态调用变为动态调用==。

### 1.修改函数

按照嵌入补丁框架中对调用外部函数的编写规则，对程序login.asm中调用的每个函数实施改造，步骤如下（以函数GetProcAddress为例）：

#### （1）声明函数

------

```assembly
_QLGetProcAddress typedef proto :dword,:dword
```

------

#### （2）引用函数声明

------

```assembly
_ApiGetProcAddress typedef ptr _QLGetProcAddress ;声明函数引用
```

------

#### （3）定义函数变量（全局变量）

------

```assembly
_GetProcAddress _ApiGetProcAddress ? ;定义函数
```

------

对函数的声明也不需要去网络或者书籍上查找。找到D:\masm32\include\user32.inc，使用记事本程序打开，选择菜单“编辑”|“查找”；在弹出的对话框中，输入要查找的函数名后，单击“查找下一个”按钮，即可查找到user32.dll中的指定函数的声明。

### 2.分解函数调用语句

由于函数地址为全局变量，所以在调用时不能采用以下代码：

------

```assembly
invoke _GetProcAddrss
```

------

这样在生成指令字节码时还是会用到直接寻址，因此，invoke指令的操作数需要重新定位。为了解决这个问题，通常用以下代码来代替：

------

```assembly
mov edx,[ebx+offset _GetProcAddress]
call edx
```

------

看一个实际的例子：

------

```assembly
mov eax,offset szLoadLibraryA
add eax,ebx
push eax
push [ebx+offset hKernel32Base]
mov edx,[ebx+offset _GetProcAddress]
call edx
mov [ebx+offset _LoadLibraryA],eax
```

------

上述的代码等价于：

------

```assembly
invoke GetProcAddress,hKernel32Base,addr szLoadLibraryA
mov _LoadLibraryA,eax
```

------

虽然比原来的代码复杂了些，但由于使用了重定位技术和动态加载技术，所以能获得更好的可移植性。

### 3.修改程序结构

按照嵌入补丁框架的要求对login.asm的程序结构进行调整，主要涉及以下两个位置：

#### 1）在代码段开始位置加入跳转指令代码，如下所示：

------

```assembly
;代码段
.code
jmp start
szCaption db '欢迎您！',0
szText db '您是合法用户，请使用该软件！',0
szCaptionMain db '系统登录',0
┇
```

------

#### 2）在返回指令前加入跳转指令代码，如下所示：

------

```assembly
jmpToStart db 0E9h,0F0h,0FFh,0FFh,0FFh
ret
end start
```

------

## 20.4.3　补丁程序主要代码

通过以上几步的修改，补丁程序基本成型，代码清单20-3为补丁程序的主要代码，完整代码请参见随书文件chapter20\patch.asm。

代码清单20-3　EXE加锁器补丁程序主要代码（chapter20\patch.asm）

------

```assembly
start:
    ;取当前函数的堆栈栈顶值
    mov eax,dword ptr [esp]
    push eax
    call @F   ; 免去重定位
@@:
    pop ebx
    sub ebx,offset @B
    pop eax
    ;获取kernel32.dll的基地址
    invoke _getKernelBase,eax
    mov [ebx+offset hKernel32Base],eax

    ;从基地址出发搜索GetProcAddress函数的首址
    mov eax,offset szGetProcAddress
    add eax,ebx
    mov ecx,[ebx+offset hKernel32Base]
    invoke _getApi,ecx,eax
    mov [ebx+offset _GetProcAddress],eax   ;为函数引用赋值 GetProcAddress

    ;使用GetProcAddress函数的首址，传入两个参数调用GetProcAddress函数，获得LoadLibraryA的首址
    mov eax,offset szLoadLibraryA
    add eax,ebx
    
    push eax
    push [ebx+offset hKernel32Base]
    mov edx,[ebx+offset _GetProcAddress]
    call edx
    mov [ebx+offset _LoadLibraryA],eax

    invoke _getDllBase      ;获取所有用到的dll的基地址，kernel32除外
    invoke _getFuns         ;获取所有用到的函数的入口地址，GetProcAddress和LoadLibraryA除外
    invoke _WinMain,ebx

    jmpToStart   db 0E9h,0F0h,0FFh,0FFh,0FFh
    ret
    end start
```

------

1. ==以上代码首先调用函数`_getKernelBase`得到`kernel32.dll`的基地址；==
2. ==然后，调用函数`_getApi`获得`GetProcAddress`的地址；==
3. ==进一步调用刚获取的函数`GetProcAddress`得到`LoadLibraryA`的地址。==
4. ==有了这两个地址以后，通过调用函数`_getDllBase`得到除`kernel32.dll`外的其他所有链接库的基地址，通过调用函数`_getFuns`获得本程序中用到的其他所有外部函数的地址。==
5. ==最后，执行主窗口创建函数`_WinMain`。==

### 20.5　附加补丁运行

因为本实例的补丁代码比较长，共0B2Ch个字节，所以，这里使用第16章介绍的方法将代码添加到目标PE文件新的节中。以下是将patch.exe附加到WinWord的运行结果：

![image](https://github.com/YangLuchao/img_host/raw/master/20231030/image.5tbrg0moq280.png)

运行界面如图20-2所示。

![image](https://github.com/YangLuchao/img_host/raw/master/20231030/image.27rmcqru3ssg.jpg)

图　20-2　EXE加锁器打补丁运行界面截图

==运行以后，会在C盘根目录生成bindB.exe。打开bindB.exe，首先出现的就是权限认证窗口。输入正确的值以后（用户名：admin，密码：123456），才可以运行Word程序。==

至此，EXE加锁器设计成功！

# 20.6　小结

本章实现了一个EXE加锁器。==首先，编写了一个无需资源文件的窗口程序，通过在PE中创建一个新节，并通过将代码附加到新节的方法对目标PE实施补丁；当用户想运行目标PE时，需要先输入密码==。

本章的重点是无资源文件补丁程序的编写。