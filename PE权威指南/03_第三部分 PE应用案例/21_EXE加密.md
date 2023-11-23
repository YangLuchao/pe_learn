[toc]

==EXE加密是软件保护范畴的一种技术，通过对指定的PE文件进行加密，可以增加逆向分析代码的难度，在一定程度上保护软件代码的安全==。

==EXE加密技术经常用于对软件的加壳处理，通过PE分析软件对加密后的PE文件进行分析，只能看到与补丁代码有关的信息，原始的PE文件相关信息被隐藏==；==同时，如果在EXE补丁代码中使用一些技巧，也能有效地增加PE反调试的难度，达到保护软件的目的==。

# 21.1　基本思路

加密一个PE文件的基本思路如下：

1. **步骤1**　==由补丁工具完成对目标PE文件数据目录表的修改，并将原始数据目录表的内容转移到补丁代码中==。
2. **步骤2**　==由补丁工具完成对目标PE文件节区数据的加密。==
3. **步骤3**　==由补丁工具设置目标PE文件入口地址指向补丁代码==。
4. **步骤4**　==由补丁代码完成对目标PE文件数据目录表的还原==。
5. **步骤5**　==由补丁代码完成对目标PE文件节区数据的解密==。
6. **步骤6**　==由补丁代码完成对目标PE文件导入表中动态链接库的动态加载==。
7. **步骤7**　==由补丁代码完成对目标PE文件IAT的修正==。

加密以后的目标文件结构如图21-1所示。

![image](https://github.com/YangLuchao/img_host/raw/master/20231030/image.3ghlt7sj6pg0.jpg)

图　21-1　加密以后的目标PE文件结构

如图所示，由于加密以后的数据目录表被清零，通过结构分析工具（如PEInfo）查看目标PE文件时，数据目录表中注册的数据类型都不会显示，原始数据目录表会被补丁工具转移到补丁代码中。除数据目录表、SizeOfImage、最后一节的SizeOfRawData、函数入口地址AddressOfEntryPoint外，目标PE文件的头部数据基本保持不变。目标PE文件的节区数据全部被加密保存，但节区数据的长度不变，补丁代码被选择附加到目标PE文件的最后一节中。

# 21.2　加密算法

==加密算法是EXE加密的核心==。==本节首先介绍了常用的两类加密算法，然后介绍了自行设计的可逆加密算法，并给出了加密代码==。

## 21.2.1　加密算法的分类

按照加密后的信息是否可以被还原，常用的加密算法分为两大类：

1. 不可逆加密算法
2. 可逆加密算法

下面分别来介绍。

### 1.不可逆加密算法

==不可逆加密算法的特征是，加密过程中不需要使用密钥，输入明文后由系统直接经过加密算法处理成密文==。==这种加密后的数据是无法被解密的，只有重新输入明文，并再次经过同样不可逆的加密算法处理，得到相同的加密密文并被系统重新识别后，才能真正解密==。

==为了避免有人通过可逆算法得到加密前的信息，在用户权限认证的系统中，通常会使用一张不可逆加密的表，表中存放着经过加密以后的用户密码==。==这个密码是任何人也破解不了的，除非被他有幸猜中，虽然不能还原最初的密码，但可以通过对用户密码的再一次加密实现用户密码的验证==。

举个最简单的例子：假设用户最初输入的密码是“123456”，使用的不可逆加密算法是将每一位当成一个数字，然后与3相除，取余数作为每一位加密后的结果，最终用户密码被加密成“120120”。很显然，你无法正确地还原回去，因为许多原始密码经过这种加密算法得到的值都是“120120”，如原始密码为“789123”、“456123”等。但是，这种加密算法却可以用在对用户的验证上，即用户只要输入“123456”，其加密以后的值一定是表中存储的值。

==很明显，在这类加密过程中，加密是自己，解密还得是自己；而所谓解密，实际上就是重新加一次密，所应用的“密码”也就是输入的明文==。

不可逆加密算法不存在密钥保管和分发问题，非常适合在分布式网络系统上使用，但因加密计算复杂，工作量相当繁重，通常只在数据量有限的情形下使用，例如，广泛应用在计算机系统中的口令加密，利用的就是不可逆加密算法。

近年来，随着计算机系统性能的不断提高，不可逆加密的应用领域正在逐渐增大。在计算机网络中应用较多不可逆加密算法的有许多，例如RSA公司发明的MD5算法，以及由美国国家标准局建议的不可逆加密标准SHS（Secure Hash Standard，安全散列信息标准）等。

### 2.可逆加密算法

==可逆加密算法又分为两大类：“对称式”和“非对称式”==。

==对称式加密　加密和解密使用同一个密钥，通常称之为`Session Key`==。这种加密技术目前被广泛采用，如美国政府所采用的DES加密标准就是一种典型的“对称式”加密法，它的`Session Key`长度为56Bits。

==非对称式加密　加密和解密所使用的不是同一个密钥，而是两个密钥：一个称为“公钥”，另一个称为“私钥”；它们两个必须配对使用，否则不能打开加密文件==。这里的“公钥”是指可以对外公布的，“私钥”则只能由持有人本人知道。它的优越性就在这里，因为如果是在网络上传输加密文件，对称式的加密方法就很难把密钥告诉对方，不管用什么方法都有可能被别人窃听到。而非对称式的加密方法有两个密钥，且其中的“公钥”是可以公开的，不怕别人知道，收件人解密时只要用自己的私钥即可以，这样就很好地避免了密钥的传输安全性问题。

==最典型的可逆加密算法是异或运算。大家都知道，对一个值连续异或两次，其结果还是原值；于是，第一次异或被看成是加密，第二次异或被看成是解密==。

==对EXE进行加密必须使用一些可逆的加密算法，即不仅能加密数据，还要能还原数据==。下面我们就自行开发一种简单的可逆加密算法。

## 21.2.2　自定义可逆加密算法实例

本节自行定义了一种可逆的加密算法，基本思路是：

==首先，构造一个256字节的加密用基表，该基表中的每一项的值都不重复，这就意味着该基表中拥有了00h～0ffh所有的字节值。有了这个基表以后，再对PE中的每一个字节进行加密==。==加密方法非常简单，将要加密的字节当做是基表的索引，查找索引处的字节值，该值即为加密后的值==。加密算法示意见图21-2。

![image](https://github.com/YangLuchao/img_host/raw/master/20231031/image.2g4tlqshrhus.png)

图　21-2　字节加密算法流程

如图所示，==加密基表共有256项，其中存储着256个不同的值，并且这些值不是按顺序排列的==。例如，待加密的字节为50h，将这个值当成是基表的索引，查找该表50h处的字节是98h，找到的这个值即为加密以后的值。

==解密的过程刚好相反，根据要解密的字节98h遍历基表，如果找到与之相等的值，则记录此处的索引值，该索引值50h即为解密后的字节==。

> 特别注意　基表的最后一个字节固定为00h。这个值的设置与基表的构造方式有关，详见下一节。

## 21.2.3　构造加密基表

==基表的组成包括255个随机数（均不重复）和最后一个00h字节==。其中随机数的构造方法如下：

------

```assembly
;生成加密基表
mov @dwCount,0
mov edi,offset EncryptionTable
.while TRUE
	invoke _getAByte
	mov byte ptr [edi],al
	inc edi
	inc @dwCount
	.break.if @dwCount == 0ffh
.endw
```

------

==开始时，加密基表所有表项值均被初始化为00h，函数`_getAByte`得到一个与当前表项中已存在的所有值均不重复的字节，并将其添加到表项==。以下是函数`_getAByte`的定义：

------

```assembly
_getAByte proc
	local @ret
	pushad
loc1:
	;取随机数
	invoke _getRandom,1,255
	mov @ret,eax
	;判断随机数是否在基表中
	invoke _isExists,eax
	.if eax ;如果在，则重新获取随机数
		jmp loc1
	.endif
	popad
	mov eax,@ret ;如果不在基表，则返回
	ret
_getAByte endp
```

------

==函数`_getAByte`首先取一个1～255之间的数（注意，这里舍弃了0，因为0被设置为基表索引255处，这样做主要是为了方便函数`_isExists`的运行）==。取指定范围随机数的方法如下：

------

```assembly
_getRandom proc _dwMin:dword,_dwMax:dword
	local @dwRet:dword
	pushad
	;取得随机数种子，当然，可用别的方法代替
	invoke GetTickCount
	mov ecx,19 ;X=ecx=19
	mul ecx ;eax=eax*X
	add eax,37 ;eax=eax+Y（Y=37）
	mov ecx,_dwMax ;ecx=上限
	sub ecx,_dwMin ;ecx=上限-下限
	inc ecx ;Z=ecx+1（得到了范围）
	xor edx,edx ;edx=0
	div ecx ;eax=eax mod Z（余数在edx里面）
	add edx,_dwMin
	mov @dwRet,edx
	popad
	mov eax,@dwRet ;eax=Rand _Number
	ret
_getRandom endp
```

------

获取随机数的基本算法为：
$$
随机数=下限+（随机数*19+37）mod（上限-下限+1）
$$
==随机数（1～255之间）获取以后，首先通过函数`_isExists`判断该值是否在基表中已经存在==。以下是函数`_isExists`的详细代码：

------

```assembly
_isExists proc _byte
	local @ret
	pushad
	mov esi,offset EncryptionTable
	mov ecx,0
	.while TRUE
		mov al,byte ptr [esi]
		.if al == 0
			mov @ret,FALSE
			.break
		.endif
			mov ebx,_byte
		.if al == bl
			mov @ret,TRUE
			.break
		.endif
			inc esi
			inc ecx
		.if ecx == 0ffh
			mov @ret,FALSE
			.break
		.endif
	.endw
	popad
	mov eax,@ret
	ret
_isExists endp
```

------

==函数`_isExists`将循环检测基表，结束条件有两个：一是当函数在基表中找到了相同的值，则返回TRUE；另一个条件是函数已经完全遍历完基表，未发现相同的值，返回FALSE，如果在基表中碰到00h，则表示已经到了基表末尾，返回FALSE==。这里解释了上一节最后提出的问题，即为什么要在基表的最后一个位置存放固定的字节00h。

通过以上方法，由计算机自动完成填充一个基表，以下字节码是代码chapter21\HelloWorld.exe运行期获取的一个基表内容。可以看到，基表中任何一项的值都是介于00h～0FFh的，每个值都不相等，且基表的最后一个字节是00h。

![image](https://github.com/YangLuchao/img_host/raw/master/20231031/image.5nyywwtrpmc0.jpg)

构造加密基表的完整代码可以从随书文件chapter21\HelloWorld.asm中获得。

## 21.2.4　利用基表测试加密数据

==接下来，我们就用上节生成的基表进行数据加密的测试==。==首先，在数据段中定义两部分数据，一部分为加密前的数据`szSrc`，另一部分为加密后的数据`szDst`==。为了测试，只定义了8个字节，加密前的数据随便取一些值，加密后的数据全部初始化为00h。加密数据的代码见代码清单21-1。

代码清单21-1　加密数据的函数`_encrptIt`（chapter21\HelloWorld.asm）

------

```assembly
;-------------------------------
; 加密算法，可逆算法，字节数不变
; 入口参数：
;   _src:要加密的字节码起始地址
;   _dst:生成加密后的字节码起始地址
;   _size:要加密的字节码的数量
;-------------------------------
_encrptIt  proc _src,_dst,_size
  local @ret
  
  pushad
  ;开始按照基表对字节进行加密
  mov esi,_src
  mov edi,_dst
  .while TRUE
   mov al,byte ptr [esi]
   xor ebx,ebx
   mov bl,al
   mov al,byte ptr EncryptionTable[ebx]
   mov byte ptr [edi],al

   inc esi
   inc edi
   dec _size
   .break .if _size==0
  .endw
  popad
  ret
_encrptIt endp
```

------

==开始加密前，`esi`指向要加密的数据，`edi`指向存储加密结果的缓冲区，行152～163是一个循环，循环次数为要加密数据的字节个数。行153～155将获取的值当成一个索引存储在`ebx`寄存器中；行156～157按照该索引值从基表中取出加密后的值，存储到结果缓冲区==。

以下是运行函数后的数据加密结果：

![image](https://github.com/YangLuchao/img_host/raw/master/20231031/image.15r6207dwvkw.jpg)

从列出的字节码可以看出加密前后数据的对应关系，请对比以下所列自行查看基表，看这些值是否真正符合我们的加密算法。

![image](https://github.com/YangLuchao/img_host/raw/master/20231031/image.fplds39gzrs.jpg)

# 21.3　开发补丁工具

==补丁工具主要完成的操作包括==：

1. ==处理目标PE文件的数据目录表，向补丁代码传递原始数据目录表。==
2. ==生成加密基表，向补丁代码传递加密基表及其他要传递给补丁代码的参数。==
3. ==加密节区数据==。

将补丁代码附加到目标PE文件的最后一节。

本节相关文件在随书文件的目录chapter21\b中，下面分别介绍。

## 21.3.1　转移数据目录

==由于导入表的数据全部存储在节区，而补丁工具会对这些数据进行加密处理，破坏原有的导入表结构，造成PE加载器加载目标PE文件失败，因此，必须事先将目标程序的数据目录表的导入表项设置为0，即告诉加载器：凡是目标PE中涉及的所有动态链接库不需要操作系统加载器来处理==。==不仅导入表的数据这样处理，数据目录表中的其他数据也需要这样处理==。

==修改数据目录表的方法是将所有项的RVA均设置为0==。下面来看一个例子，通过第17章介绍的方法，将一个最简单的HelloWorld补丁打到记事本程序中，打补丁的过程输出如下信息：

------

```
补丁程序：D:\masm32\source\chapter21\patch.exe
目标PE程序：C:\notepad.exe
补丁代码段大小：00000196
PE文件大小：00010400
对齐以后的大小：00010400
目标文件最后一节在文件中的起始偏移：00008400
目标文件最后一节对齐后的大小：00008200
新文件大小：00010600
补丁代码中的E9指令后的操作数修正为：ffff4208
```

------

最终生成的补丁程序为chapter21\patch_notepad.exe，由于对原始notepad.exe程序的节数据没有进行加密处理，所以，使用OD加载该程序后内存空间分配情况见表21-1。

![image](https://github.com/YangLuchao/img_host/raw/master/20231031/image.64t0kgh638s0.jpg)

如表所示，==第17行为进程的PE文件头部分，18～20行为进程的其他节所在的起始地址和结束地址==。下面，==将文件头部数据目录表项全部清零，重新使用OD加载程序测试内存布局==，以下是清零以后的记事本的数据目录表字节码：

![image](https://github.com/YangLuchao/img_host/raw/master/20231031/image.7crtor0046c0.jpg)

从字节码可以看出，记事本程序数据目录中的以下数据类别项被定义：==导入表、资源表、调试信息、加载配置、绑定引入和IAT。现在把以上加黑部分全部清零，然后用OD加载==，此时的内存空间分配见表21-2。

![image](https://github.com/YangLuchao/img_host/raw/master/20231031/image.cd2nxpt1n8g.jpg)

从表21-1和表21-2的对比来看，如果把数据目录中所有的内容全部清零，目标程序patch_notepad.exe自身（不含导入的其他动态链接库）加载进内存后的空间分配是一致的，如两个表的黑体部分所示。这就意味着，对数据目录表清零的操作不影响进程自身模块最终加载进内存的空间分配。

==被加密的目标PE最终还是要运行的，所以，在运行前必须将数据目录表的内容恢复原样，这就要求必须首先保存目标PE文件的数据目录表的原始内容，保存的首选位置是嵌入到目标PE文件的补丁程序==。代码清单21-2（该代码使用了随书文件chapter17\bind.asm）为补丁工具中模拟清除数据目录内容及备份内容到补丁程序的代码：

代码清单21-2　==补丁工具中转移目标PE文件原始数据目录表内容的函数`_openFile`==（chapter21\b\bind.asm）

------

```assembly
  ;---------------------------到此为止，数据拷贝完毕 

  ;清空目标文件中的数据目录表的内容
  ;并把该内容填充到补丁代码处
  ; 该部分内容在（补丁代码起始+5个字节）处，共16个目录项
  ;该部分操作全部在lpDstMemory中完成

  mov esi,lpDstMemory
  assume esi:ptr IMAGE_DOS_HEADER
  add esi,[esi].e_lfanew
  assume esi:ptr IMAGE_NT_HEADERS

  ;复制数据目录表内容到补丁字节码处
  mov eax,[esi].OptionalHeader.NumberOfRvaAndSizes
  sal eax,3
  mov ecx,eax
  mov dwDDSize,ecx
  add esi,78h
  mov dwDDStart,esi

  mov edi,lpDstMemory
  add edi,dwNewFileAlignSize
  add edi,5  ;跳转指令长度，定位到补丁程序中保存数据目录表的位置
  rep movsb

  ;清空目标文件数据目录表内容
  mov edi,dwDDStart
  mov ecx,dwDDSize
  mov al,0
  rep stosb  
```

------

如上所示，==行1277～1288负责将目标PE文件的原始目录表的数据（共78h个字节）复制到补丁代码指定的位置。行1290～1294则将目标PE文件的数据目录表的内容全部置0==。

==实现该功能的相关测试文件请参照随书文件目录chapter21\b。其中`bind.asm`是补丁工具，`patch.asm`为补丁程序，`patch _notepad.exe`是生成的打了补丁的记事本程序。使用FlexHex查看补丁后的记事本程序，会发现记事本数据目录中的所有内容均被移动到了补丁代码中==。

## 21.3.2　传递程序参数

==要传给补丁程序的参数包括解密用的基表，以及补丁前最后一节在文件中的大小==。==基表用于补丁程序解密使用，补丁前最后一节在文件中的大小需要事先传递给补丁程序，因为一旦补丁被打上，该值会发生变化==。向补丁程序传递参数的相关代码见代码清单21-3。

代码清单21-3　补丁工具向补丁程序传递参数（chapter21\b\bind.asm）

------

```assembly
  ;初始化加密基表
  invoke _encrptAlg

  ;将基表复制到补丁代码中
  mov esi,offset EncryptionTable
  mov edi,lpDstMemory
  add edi,dwNewFileAlignSize
  add edi,5     ;5个字节的跳转指令
  add edi,16*8  ;16*8个数据目录表长度
  mov ecx,256
  rep movsb

  ;加密节区数据
  ;------------------------------
  ;首先，计算加密范围
  ;取第一个节的文件起始偏移

  mov edi,lpDstMemory
  assume edi:ptr IMAGE_DOS_HEADER
  add edi,[edi].e_lfanew
  add edi,sizeof IMAGE_NT_HEADERS

  assume edi:ptr IMAGE_SECTION_HEADER
  mov eax,[edi].PointerToRawData

  mov ecx,@dwFileSize1
  sub ecx,eax
  add eax,lpDstMemory   ;起始偏移
  mov esi,eax
  
  invoke _encrptIt,esi,esi,ecx

  ;将最后一节在文件中对齐后的大小存储到补丁代码位置

  mov edi,lpDstMemory
  assume edi:ptr IMAGE_DOS_HEADER
  add edi,[edi].e_lfanew
  assume edi:ptr IMAGE_NT_HEADERS
  ;获取节的个数
  movzx eax,[edi].FileHeader.NumberOfSections
  mov dwSections,eax
  add edi,sizeof IMAGE_NT_HEADERS

  dec eax
  mov ecx,sizeof IMAGE_SECTION_HEADER   ;定位到最后一个节
  mul ecx
  add edi,eax   
  assume edi:ptr IMAGE_SECTION_HEADER
  mov ecx,[edi].SizeOfRawData
  
  mov edi,lpDstMemory
  add edi,dwNewFileAlignSize
  add edi,5     ;5个字节的跳转指令
  add edi,16*8  ;16*8个数据目录表长度
  add edi,257   ;基表
  mov dword ptr [edi],ecx

```

------

如上所示，==行1297调用函数`_encrptAlg`创建加密用的基表。行1299～1306将获得的基表内容复制到补丁程序的指定位置，共256个字节。行1328～1344得到目标PE文件最后一节的`SizeOfRawData`，行1346～1351将该参数传递给补丁程序==。

==补丁程序（chapter21\b\patch.asm）中存放加密基表和目标PE文件最后一节的`SizeOfRawData`两个参数定义如下==：

------

```assembly
jmp start ;补丁程序起始代码，该指令占了5个字节+0000h
;保存目标程序的相关信息：
dstDataDirectory dd 32 dup(0) ;原始目标程序的数据目录表+0005h
EncryptionTable db 256 dup(0),0 ;加密基表+0085h
dwLastSectionSize dd ? ;最后一节的尺寸（以字节计）
```

------

如上所示，==补丁程序中保存的与目标PE有关的信息主要包括三个==：`原始数据目录表`、`解密用的基表`和`目标PE文件最后一节的尺寸`。以下节选了运行期该位置显示的数据内容：

![image](https://github.com/YangLuchao/img_host/raw/master/20231031/image.60synz9dvv40.jpg)

如上所示，==第一个【】包含了目标程序的数据目录表，第二个【】是解密用基表内容，第三个【】是目标程序最后一节的实际字节码长度==。

## 21.3.3　加密节区内容

==补丁工具负责对目标PE文件节区数据的加密工作==。==首先，计算出要加密数据的范围，从第一个节开始到文件末尾的数据，全部要进行加密==。==由于加密采用不变长度算法，能保证PE加载器在加载数据到内存以后所有的字节码位置保持相对不变，在进行解密以后不需要重新计算代码中与定位有关的数据，所以比较方便==。对节区数据进行加密的代码见代码清单21-4。

代码清单21-4　加密节区数据（chapter21\b\bind.asm）

------

```assembly
  ;加密节区数据
  ;------------------------------
  ;首先，计算加密范围
  ;取第一个节的文件起始偏移

  mov edi,lpDstMemory
  assume edi:ptr IMAGE_DOS_HEADER
  add edi,[edi].e_lfanew
  add edi,sizeof IMAGE_NT_HEADERS

  assume edi:ptr IMAGE_SECTION_HEADER
  mov eax,[edi].PointerToRawData

  mov ecx,@dwFileSize1
  sub ecx,eax
  add eax,lpDstMemory   ;起始偏移
  mov esi,eax
  
  invoke _encrptIt,esi,esi,ecx

```

------

==函数`_encrptIt`在21.2.4节已经讲解过了，传入参数`esi`为第一个节在文件中的起始地址，`ecx`为从该位置到文件尾的长度。程序运行到此，目标文件中的指定范围的数据均被加密==。

==经过同一个加密算法生成的目标程序使用了相同的补丁程序，所以，使用一些PE分析工具得到的结果除了文件头部描述不相同外，其他地方的描述基本是相同的==。使用PEInfo小工具分析加密以后的记事本程序结果显示如下：

![image](https://github.com/YangLuchao/img_host/raw/master/20231031/image.20f1qf7c73z4.jpg)

==从分析结果来看，这里显示的内容根本不是原始的记事本程序，用FlexHex查看字节码，也只是看到一堆乱码而已==。

==补丁工具还有最后一个功能，即负责将补丁代码嵌入到目标PE文件的最后一节==。由于这部分功能在第17章中有详细描述，在此略过，具体代码请参照随书文件chapter21\b\bind.asm。

# 21.4　处理补丁程序

==前几章讲过的补丁程序实现的功能都与目标PE无关，而这次补丁程序的代码针对的对象是目标程序本身，所以需要额外对目标程序的数据进行如下处理==：

1. 对目标PE数据目录进行还原。
2. 对目标PE加密的节区的数据进行解密。
3. 对目标PE导入表中的动态链接库实施动态加载。
4. 对目标PE的IAT中的值进行修正。

以下将对这四项处理进行逐一介绍。

## 21.4.1　还原数据目录表

==对EXE加密必须保证加密以后的PE文件可以正常运行，但补丁工具却将其数据目录表全部清零，所以在运行目标程序前补丁程序要做的第一件事情，就是依据事先保存在补丁程序中的目标PE文件的原始数据目录表信息恢复目标PE文件的数据目录表==。代码清单21-5演示了还原目标PE文件数据目录表的整个过程：

代码清单21-5　还原数据目录表（chapter21\b\patch.asm）

------

```assembly
    ;获取目标进程的基地址
    mov eax,offset dwImageBase
    add eax,ebx

    push eax
    lea edx,_getImageBase
    add edx,ebx
    call edx
    mov dwImageBase[ebx],eax


    ;还原目标进程的数据目录表
    mov esi,dwImageBase[ebx]
    add esi,[esi+3ch]
    add esi,78h
    push esi

    assume fs:nothing
    mov eax,fs:[20h]
    mov hProcessID[ebx],eax


    push hProcessID[ebx]
    push FALSE
    push PROCESS_ALL_ACCESS
    call _openProcess
    mov hProcess[ebx],eax  ;找到的进程句柄在hProcess中

    

    ;设置文件头部分为可读可写可执行
    lea edx,hOldPageValue
    add edx,ebx
    push edx
    push PAGE_EXECUTE_READWRITE
    ;获取SizeOfImage大小
    push esi
    mov esi,dwImageBase[ebx]
    add esi,[esi+3ch]
    assume esi:ptr IMAGE_NT_HEADERS
    mov edx,[esi].OptionalHeader.SizeOfImage
    pop esi
    push edx   ;设置页面大小
    push dwImageBase[ebx]
    push hProcess[ebx]
    call _virtualProtectEx  

    pop esi
    push NULL
    push 16*8
    mov edx,offset dstDataDirectory
    add edx,ebx
    push edx
    push esi
    push hProcess[ebx]
    call _writeProcessMemory 
```

------

==大致思路是，通过`OpenProcess`函数传递`PROCESS_ALL_ACCESS`参数，打开目标进程==。==然后，使用`WriteProcessMemory`将补丁代码中保存的数据目录表项全部写回到目标进程头部数据目录表位置==。==代码行447～455获取目标PE的基地址，存储到变量`dwImageBase`中==。==行464～466从fs:[20h]位置处取出进程的ID号，存储到变量`hProcessID`中==。==行469～473调用`OpenProcess`函数打开目标进程==。==行477～492调用函数`VirtualProtectEx`将目标进程文件头部内存页设置为可读可写==。行494～502调用==函数`WriteProcessMemory`，将esi指向的数据写入变量`dstDataDirectory`指向的位置，即还原目标进程的数据目录表==。

==数据目录表被还原以后，程序还无法正常运行，因为此时数据目录表中的数据项指向的位置都是经过加密以后的数据，对正常的目标进程而言，这些数据根本无法识别==。接下来要做的就是将节区对应的数据进行解密。

## 21.4.2　解密节区内容

==加密的EXE程序运行前，需要先将补丁工具加密的节区数据解密==。==由于加密使用了不变长度的算法，解密后的节区数据大小和解密前一样；所以，解密时不需要额外构造解密用的缓冲区，相对比较简单==。首先来看解密函数。

### 1.解密函数`_UnEncrptIt`

==解密函数的运行依赖于加密时创建的基表==。==解密以字节为单位进行，每个字节的解密与其他字节没有关系，解密后的数据大小与解密前大小一致==。解密函数见代码清单21-6。

代码清单21-6　解密函数`_UnEncrptIt`（chapter21\b\patch.asm）

------

```assembly
;-------------------------------
; 解密算法，可逆算法，字节数不变
; 入口参数：
;   _src:要解密的字节码起始地址
;   _size:要加密的字节码的数量
;-------------------------------
_UnEncrptIt  proc _src,_size,_writeProcessMemory
  local @ret
  local @dwTemp

  pushad
  ;开始按照基表对字节进行加密
  mov esi,_src
  .while TRUE
    mov al,byte ptr [esi]
    mov edi,offset EncryptionTable
    add edi,ebx
    mov @dwTemp,0
    .while TRUE  ;查找基表，索引在@dwTemp中
      mov cl,byte ptr [edi]
      .break .if al==cl ;如果找到，则退出
      inc @dwTemp
      inc edi
    .endw
    
    ;用解密后的字节更新字节码
    mov ecx,@dwTemp
    mov byte ptr dbEncrptValue[ebx],cl

    ;使用远程写入
    push NULL
    push 1
    mov edx,offset dbEncrptValue
    add edx,ebx
    push edx
    push esi   ;??
    push hProcess[ebx]
    call _writeProcessMemory 

    inc esi
    dec _size
    .break .if _size==0
  .endw
  popad
  ret
_UnEncrptIt endp
```

------

==解密算法其实很简单，查找加密基表，如果在基表中找到指定字节码，则记录该位置在基表中的索引，这个索引值即为解密后的字节码，然后用这个字节码替换原来位置的字节值==。

### 2.解密过程

==程序将所有节的数据均进行一遍解密，还原目标程序为原始内容，然后才启动其他诸如动态加载DLL、修正IAT等操作==。代码清单21-7是解密数据的代码。

代码清单21-7　解密节区数据过程（chapter21\b\patch.asm）

------

```assembly
    ;解密数据
    mov edi,dwImageBase[ebx]
    assume edi:ptr IMAGE_DOS_HEADER
    add edi,[edi].e_lfanew
    assume edi:ptr IMAGE_NT_HEADERS
    ;获取节的个数
    movzx eax,[edi].FileHeader.NumberOfSections
    mov dwSections[ebx],eax
    add edi,sizeof IMAGE_NT_HEADERS

    dec eax
    mov ecx,sizeof IMAGE_SECTION_HEADER   ;定位到最后一个节
    mul ecx
    add edi,eax   
    assume edi:ptr IMAGE_SECTION_HEADER

    mov @first,1

    .while TRUE
       mov esi,[edi].VirtualAddress
       add esi,dwImageBase[ebx]     ;要解密的起始地址

       .if @first  ;如果是最后一节，补丁工具更改了此处的大小，
                   ;必须使用由补丁工具传入的原始值
         mov ecx,dwLastSectionSize[ebx]
         mov @first,0
       .else       ;如果是其他节，则使用SizeOfRawData
         mov ecx,[edi].SizeOfRawData
       .endif

       push _writeProcessMemory
       push ecx
       push esi
       mov edx,offset _UnEncrptIt
       add edx,ebx
       call edx

       dec dwSections[ebx]
       sub edi,sizeof IMAGE_SECTION_HEADER
       .break .if dwSections[ebx]==0
    .endw
```

------

如上所示，==代码行505～518通过文件头部描述获取节的数量，并存储在变量`dwSections`中，然后将指针定位到最后一节==。==由于此时CPU的控制权尚处于补丁程序手里，所以最后一节的`SizeOfRawData`是被补丁工具修改以后的大小==。==如果用这个大小来解密数据，势必会越界，导致后面的补丁代码被修改，所以，最后一个节要解密的数据大小由补丁工具传进来的变量`dwLastSectionSize`决定，其他的节要解密的数据大小则直接通过每个节的`SizeOfRawData`来决定==。

==行522～544是解密目标进程所有节的一个循环。其中，变量`@first`如果为1，表示当前处理的是最后一节；否则，从最后一节向前处理，直到循环次数达到节的总数为止==。

==节区的数据解密完成，是否就可以跳转到目标进程的入口地址处运行了呢==？==答案是否定的==。==因为加密的目标PE文件在最初被操作系统加载器加载进内存时，是误认为该文件没有导入表的（导入表项被设置为0）==。==所以，记事本代码中用到的所有动态链接库在记事本进程地址空间中还不存在==。==如果补丁代码只还原完数据目录表，将加密的节区解密就直接转移到原始入口地址处运行，还不会成功；补丁代码需要继续完成对记事本导入表中登记的各模块的动态载入，以及IAT的修正后才会成功==。

## 21.4.3　加载目标DLL

==加密的目标PE文件被加载进内存后，其原始的导入信息丢失==。==加载器不会将其导入表中的动态链接库加载进进程的地址空间，这个操作必须由补丁程序代为完成==。

首先，利用小工具程序PEInfo查看notepad.exe导入表中都引入了哪些动态链接库，这些链接库包括`comdlg32.dll`、`SHELL32.dll`、`WINSPOOL.DRV`、`COMCTL32.dll`、`msvcrt.dll`、`ADVAPI32.dll`、`KERNEL32.dll`、`GDI32.dll`和`USER32.dll`。但是，从OD加载的记事本进程地址空间中看到的链接库`SECUR32.DLL`、`USP10.DLL`、`SHLWAPI.DLL`、`RPCRT4.DLL`、`LPK.DLL`、`IMM32.DLL`并未出现在NOTEPAD.EXE的导入表定义中。==这说明，这些动态链接库的导入应该是包含在其他动态链接库中==的，例如：

- WINSPOOL.DRV→RPCRT4.DLL
- COMDLG32.DLL→SHLWAPI.DLL
- LPK.DLL→USP10.DLL

==接下来，要为补丁代码增加动态加载DLL功能==。==通过遍历目标程序的导入表，调用`LoadLibraryA`函数，将导入表中列出的所有模块加载到内存中，并记录各模块的基地址==。详细代码见代码清单21-8。

代码清单21-8　动态加载目标进程导入表中登记的DLL（chapter21\patch2.asm）

------

```assembly
    ;获取目标进程的基地址
    mov eax,offset dwImageBase
    add eax,ebx

    push eax
    lea edx,_getImageBase
    add edx,ebx
    call edx
    mov dwImageBase[ebx],eax

    ;遍历目标进程导入表
    mov edi,offset dstDataDirectory
    add edi,ebx
    add edi,8  ;定位到导入表项

    mov eax,dword ptr [edi] ;获取VirtualAddress
    ;未做判断，假设处理的PE文件均有导入表
    add eax,dwImageBase[ebx] ;所在内存偏移

    mov edi,eax     ;计算引入表所在文件偏移位置
    assume edi:ptr IMAGE_IMPORT_DESCRIPTOR
    
    mov eax,dword ptr [edi].Name1 ;取第一个动态链接库名字字符串所在的RVA值
    add eax,dwImageBase[ebx]  ;在内存定位只需加上基地址即可
    ;invoke _messageBox,NULL,eax,NULL,MB_OK

    ;动态加载该dll
    invoke _loadLibrary,eax
    mov dwModuleBase[ebx],eax    

```

------

只加载一个DLL（`comdlg32.dll`）的示例可以调试chapter21\bindC.exe文件。在OD环境下对比动态加载前后的内存分配，可以看到，`comdlg32.dll`被正确地加入到地址0x76320000起始处。以下是加载所有的动态链接库代码（chapter21\a\patch.asm）：

------

```assembly
    mov edi,eax     ;计算引入表所在文件偏移位置
    assume edi:ptr IMAGE_IMPORT_DESCRIPTOR
    .while [edi].Name1
       push edi
       mov eax,dword ptr [edi].Name1 ;取第一个动态链接库名字字符串所在的RVA值
       add eax,dwImageBase[ebx]      ;在内存定位只需加上基地址即可

       ;动态加载该dll
       invoke _loadLibrary,eax
       mov dwModuleBase[ebx],eax    

       ;修正从该链接库引入的函数IAT项
       ;-----------------------------
       lea edx,offset _updateIAT
       add edx,ebx
       push _writeProcessMemory
       push edi
       call edx
       pop edi
       add edi,sizeof IMAGE_IMPORT_DESCRIPTOR
    .endw
```

------

离最终可运行的目标越来越近了，最后一步是修正目标文件的IAT。

## 21.4.4　修正目标IAT

==引入的动态链接库被动态加载到内存以后，接下来要做的就是修正目标进程中的IAT内容。从导入表中得到每个函数的名称字符串，然后，从加载的模块基地址获取该函数在内存的VA值，并填到对应的IAT位置==。

下面开始IAT修复工作，具体代码见代码清单21-9。

代码清单21-9　修正目标进程IAT的`_updateIAT`函数（chapter21\a\patch.asm）

------

```assembly
;------------------
; 修正IAT表
; 传入全局变量参数
;   dwModuleBase  模块的地址
;   dwImageBase   进程基地址
;------------------
_updateIAT  proc _lpIID,_writeProcessMemory
   local @dwCount

   pushad
   mov @dwCount,0

   mov edi,_lpIID
   assume edi:ptr IMAGE_IMPORT_DESCRIPTOR

   ;获取函数名字字符串
   mov esi,[edi].OriginalFirstThunk
   add esi,dwImageBase[ebx]
   .while TRUE
     mov eax,[esi]
     .break .if !eax
     add eax,dwImageBase[ebx]
     add eax,2  ;跳过hint/name中的hint

     ;此时eax指向了函数字符串
     lea edx,_getApi   ;获取函数地址
     add edx,ebx
     push eax
     push dwModuleBase[ebx]
     call edx
     ;add eax,dwImageBase[ebx]  ;获取函数VA值

     ;将函数地址覆盖IAT对应位置
     push esi
     push eax
     mov esi,[edi].FirstThunk
     add esi,dwImageBase[ebx]  ;ESI指向IAT表开始

     mov eax,@dwCount  ;求索引对应偏移
     sal eax,2
     add esi,eax
     pop eax


     mov dwIATValue[ebx],eax
     ;使用远程写入
     push NULL
     push 4     ; 写入长度
     mov edx,offset dwIATValue
     add edx,ebx
     push edx   ; 写入的值所在缓冲区
     push esi   ; 写入起始地址
     push hProcess[ebx]
     call _writeProcessMemory 

     ;mov dword ptr [esi],eax   ;将函数VA值写入IAT
     pop esi

     inc @dwCount
     add esi,4
   .endw

   popad
   ret
_updateIAT endp

```

------

==调用函数`_updateIAT`前，目标程序的数据目录表数据已经得到恢复==。==`dwModuleBase`中存放了当前动态加载的模块的基地址，`dwImageBase`中存放了目标进程的基地址==。==`hProcess`为打开的目标进程（为内存写作准备的）句柄==。==函数传入两个参数：参数1是`_lpIID`，该参数指向当前导入描述`IMAGE_IMPORT_DESCRIPTOR`结构；参数2为`WriteProcessMemory`的函数`VA`==。

==函数首先通过`IMAGE_IMPORT_DESCRIPTOR.OriginalFirstThunk`找到函数名字字符串（注意，要跳过Hint/Name前的2个字节值）==；==然后，通过调用`_getApi`函数获取该函数指令字节码所在内存的地址，并将该地址保存到IAT的相关项位置==。

通过以上几步，对EXE加密、解密、运行的任务就完成了。运行补丁后的chapter21\b\path _notepad.exe程序，先出现补丁代码中的对话框提示，然后出现记事本程序。通过PEInfo小工具查看该程序显示的信息中大部分与记事本程序无关。

# 21.5　小结

本章以记事本为例，向大家==介绍了一种加密EXE文件的思路。方法是对目标PE文件的节区进行加密==；==运行时由补丁代码接管控制权，实施解密，并重新组织原程序的运行==。本章用到了第17章中介绍的补丁工具。

本实例的加密方法很简单，==大家可以根据实际需要对加密算法进行改进，以满足一些特殊需要==。==注意，本章介绍的代码只适合存在导入表，且导入函数均为名称导入的目标PE程序，如果大家想让其适应更多的程序，请根据所学知识自行修改==。