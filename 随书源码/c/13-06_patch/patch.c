//补丁代码
//本段代码使用了API函数地址动态获取以及重定位技术
//程序功能：弹出对话框
//
//release版
//保留从未引用的函数和数据    否 (/OPT:NOREF)
//优化 已禁用 (/Od)
//禁用安全检查 (/GS-)
//
//
//
//02-04_PEInfo.exe release版 基址0x00400000 
//从文件偏移0x1f15(入口点)处开始写入  
//
//写入的数据来自13-06_patch.exe
//文件偏移0x403(函数_jmpStart的call CallPopAdd语句的地址)
//到0x796(main函数的结尾)
//
//
//
//如果是win7x64,用SysWOW64下的notepad
//win7的notepad有重定位，需要把重定位去掉(IMAGE_NT_HEADERS32.IMAGE_FILE_HEADER.Characteristics | 1)才能行，
//不然程序加载的时候会把写入的数据修改了，会运行失败
//从文件偏移0x25c9(入口点)处开始写入
//写入的数据一样
//

#include <Windows.h>



void _jmpStart()
{
	__asm
	{
		call CallPopAdd
CallPopAdd:
		pop eax
		add eax, 0x37b //0x37b为CallPopAdd标签到main函数中_start()语句的距离
		jmp eax
	}
}


/*
获取kernel32.dll的基地址
xp下KERNEL32为第二个，
win7下KERNEL32为第三个
为了实用，采用遍历链表，比较导出表中dll名字的方式
*/
DWORD _getKernelBase()
{
	DWORD dwPEB;
	DWORD dwLDR;
	DWORD dwInitList;
	DWORD dwDllBase;//当前地址
	PIMAGE_DOS_HEADER pImageDosHeader;//指向DOS头的指针
	PIMAGE_NT_HEADERS pImageNtHeaders;//指向NT头的指针
	DWORD dwVirtualAddress;//导出表偏移地址
	PIMAGE_EXPORT_DIRECTORY pImageExportDirectory;//指向导出表的指针
	PTCHAR lpName;//指向dll名字的指针
	TCHAR szkernel32[] = { 'K', 'E', 'R', 'N', 'E', 'L', '3', '2', '.', 'd', 'l', 'l', 0 };

	__asm
	{
		mov eax, FS:[0x30]//fs:[30h]指向PEB
			mov dwPEB, eax
	}

	dwLDR = *(PDWORD)(dwPEB + 0xc);//PEB偏移0xc是LDR指针
	dwInitList = *(PDWORD)(dwLDR + 0x1c);//LDR偏移0x1c是指向 按照初始化顺序排序 的第一个模块的结构 的指针



	for (;
		dwDllBase = *(PDWORD)(dwInitList + 8);//结构偏移0x8处存放模块基址
		dwInitList = *(PDWORD)dwInitList//结构偏移0处存放下一模块结构的指针
		)
	{
		pImageDosHeader = (PIMAGE_DOS_HEADER)dwDllBase;
		pImageNtHeaders = (PIMAGE_NT_HEADERS)(dwDllBase + pImageDosHeader->e_lfanew);
		dwVirtualAddress = pImageNtHeaders->OptionalHeader.DataDirectory[0].VirtualAddress;//导出表偏移 
		pImageExportDirectory = (PIMAGE_EXPORT_DIRECTORY)(dwDllBase + dwVirtualAddress);//导出表地址
		lpName = (PTCHAR)(dwDllBase + pImageExportDirectory->Name);//dll名字

		for (int i = 0; 1; ++i)//判断是否为“KERNEL32.dll”
		{
			if (lpName[i] != szkernel32[i])
			{
				break;
			}

			if (lpName[i] == 0)
			{
				return dwDllBase;
			}
		}
	}
	return 0;

}



/*
获取指定字符串的API函数的调用地址
入口参数：_hModule为动态链接库的基址
_lpApi为API函数名的首址
出口参数：函数在虚拟地址空间中的真实地址
*/
DWORD _getApi(DWORD _hModule, PTCHAR _lpApi)
{
	DWORD i;
	PIMAGE_DOS_HEADER pImageDosHeader;//指向DOS头的指针
	PIMAGE_NT_HEADERS pImageNtHeaders;//指向NT头的指针
	DWORD dwVirtualAddress;//导出表偏移地址
	PIMAGE_EXPORT_DIRECTORY pImageExportDirectory;//指向导出表的指针
	TCHAR ** lpAddressOfNames;
	PWORD lpAddressOfNameOrdinals;


	pImageDosHeader = (PIMAGE_DOS_HEADER)_hModule;
	pImageNtHeaders = (PIMAGE_NT_HEADERS)(_hModule + pImageDosHeader->e_lfanew);
	dwVirtualAddress = pImageNtHeaders->OptionalHeader.DataDirectory[0].VirtualAddress;//导出表偏移 
	pImageExportDirectory = (PIMAGE_EXPORT_DIRECTORY)(_hModule + dwVirtualAddress);//导出表地址
	lpAddressOfNames = (TCHAR **)(_hModule + pImageExportDirectory->AddressOfNames);//按名字导出函数列表
	for (i = 0; _hModule + lpAddressOfNames[i]; ++i)
	{
		for (int j = 0; 1; ++j)//判断是否为_lpApi
		{
			if (_lpApi[j] != (_hModule + lpAddressOfNames[i])[j])
			{
				break;
			}

			if (_lpApi[j] == 0)
			{
				lpAddressOfNameOrdinals = (PWORD)(_hModule +
					pImageExportDirectory->AddressOfNameOrdinals);//按名字导出函数索引列表

				return _hModule + ((PDWORD)(_hModule + pImageExportDirectory->AddressOfFunctions))
					[lpAddressOfNameOrdinals[i]];//根据函数索引找到函数地址
			}
		}
	}





	return 0;
}



/*
补丁功能部分
传入三个参数：
_kernel:kernel32.dll的基地址
_getAddr:函数GetProcAddress地址
_loadLib:函数LoadLibraryA地址
*/
void _patchFun(DWORD _kernel, PROC _getAddr, PROC _loadLib)
{
	//补丁功能代码局部变量定义
	DWORD hUser32Base;//user32.dll基址
	PROC _messageBox;// messagebox函数地址
	TCHAR szUser32Dll[] = { 'u', 's', 'e', 'r', '3', '2', '.', 'd', 'l', 'l', 0 };
	TCHAR szMessageBox[] = { 'M', 'e', 's', 's', 'a', 'g', 'e', 'B', 'o', 'x', 'A', 0 };
	TCHAR szHello[] = { 'H', 'e', 'l', 'l', 'o', 'W', 'o', 'r', 'l', 'd', 'P', 'E', 0 };


	//补丁功能代码，以下只是一个范例，功能为弹出对话框
	hUser32Base = _loadLib(szUser32Dll);//获取user32.dll的基地址

	//使用GetProcAddress函数的首址，
	//传入两个参数调用GetProcAddress函数，
	//获得MessageBoxA的首址
	_messageBox = (PROC)_getAddr(hUser32Base, szMessageBox);

	//调用函数MessageBox !!
	_messageBox(NULL, szHello, NULL, MB_OK);


}





void _start()
{
	DWORD hKernel32Base;//存放kernel32.dll基址
	PROC _getProcAddress;// getProcAddress函数地址
	PROC _loadLibrary;// loadLibrary函数地址


	TCHAR szGetProcAddr[] = { 'G', 'e', 't', 'P', 'r', 'o', 'c', 'A', 'd', 'd', 'r', 'e', 's', 's', 0 };
	TCHAR szLoadLib[] = { 'L', 'o', 'a', 'd', 'L', 'i', 'b', 'r', 'a', 'r', 'y', 'A', 0 };


	hKernel32Base = _getKernelBase();//获取kernel32.dll的基地址
	_getProcAddress = (PROC)_getApi(hKernel32Base, szGetProcAddr);//从基地址出发搜索GetProcAddress函数的首址
	_loadLibrary = (PROC)_getApi(hKernel32Base, szLoadLib);//从基地址出发搜索LoadLibraryA函数的首址
	_patchFun(hKernel32Base, _getProcAddress, _loadLibrary);//调用补丁代码
}



/*
EXE文件新的入口地址
*/
int  main()
{
	// 执行补丁代码
	_start();

	__asm
	{
		call CallPopSub
CallPopSub:
		pop eax
		sub eax,0xa
		jmp eax
	}

	return 0;
}

