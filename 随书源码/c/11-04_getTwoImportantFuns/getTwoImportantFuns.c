#include<Windows.h>




/*
获取kernel32.dll的基地址
因为vc程序main函数之前会有初始化，所以不能通过堆栈栈顶值获取kernel32.dll中的地址
因此通过 PEB 结构获取Kernel32.dll基址
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
	TCHAR szKernel32[] = TEXT("KERNEL32.dll");

	__asm
	{
		mov eax, FS:[0x30]//获取PEB所在地址
			mov dwPEB, eax
	}


	dwLDR = *(PDWORD)(dwPEB + 0xc);//获取PEB_LDR_DATA 结构指针
	dwInitList = *(PDWORD)(dwLDR + 0x1c);//获取InInitializationOrderModuleList 链表头
	//第一个LDR_MODULE节点InInitializationOrderModuleList成员的指针
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

		if (strlen(lpName) == 0xc && !strcmp(lpName, szKernel32))//判断是否为“KERNEL32.dll”
		{
			return dwDllBase;
		}
	}
	return 0;
}



/*
获取指定字符串的API函数的调用地址
入口参数：_hModule为动态链接库的基址
_lpApi为API函数名的首址
出口参数：eax为函数在虚拟地址空间中的真实地址
*/
DWORD _getApi(DWORD _hModule, PTCHAR _lpApi)
{
	DWORD i;// 函数名长度计数
	DWORD dwLen;// 函数名长度计数
	PIMAGE_DOS_HEADER pImageDosHeader;//指向DOS头的指针
	PIMAGE_NT_HEADERS pImageNtHeaders;//指向NT头的指针
	DWORD dwVirtualAddress;//导出表偏移地址
	PIMAGE_EXPORT_DIRECTORY pImageExportDirectory;//指向导出表的指针
	TCHAR ** lpAddressOfNames;
	PWORD lpAddressOfNameOrdinals;

	//计算API字符串的长度
	for (i = 0; _lpApi[i]; ++i);
	dwLen = i;


	// ODS头
	pImageDosHeader = (PIMAGE_DOS_HEADER)_hModule;
	// NT头
	pImageNtHeaders = (PIMAGE_NT_HEADERS)(_hModule + pImageDosHeader->e_lfanew);
	// 导出表偏移 
	dwVirtualAddress = pImageNtHeaders->OptionalHeader.DataDirectory[0].VirtualAddress;
	// 导出表地址
	pImageExportDirectory = (PIMAGE_EXPORT_DIRECTORY)(_hModule + dwVirtualAddress);
	// 按名字导出函数列表
	lpAddressOfNames = (TCHAR **)(_hModule + pImageExportDirectory->AddressOfNames);
	for (i = 0; _hModule + lpAddressOfNames[i]; ++i)
	{
		//判断是否为目标API
		if (strlen(_hModule + lpAddressOfNames[i]) == dwLen &&
			!strcmp(_hModule + lpAddressOfNames[i], _lpApi))
		{
			// 按名字导出函数索引列表
			lpAddressOfNameOrdinals = (PWORD)(_hModule + pImageExportDirectory->AddressOfNameOrdinals);
			// 根据函数索引找到函数地址
			return _hModule + ((PDWORD)(_hModule + pImageExportDirectory->AddressOfFunctions))
				[lpAddressOfNameOrdinals[i]];
		}
	}
	return 0;
}



int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR szCmdLine, int iCmdShow)
{
	DWORD kernel32Base;//kernel32.dll基址
	PROC _getProcAddress;//getProcAddress函数指针
	DWORD lpLoadLib;//loadLib函数地址


	TCHAR szBuffer[256];

	TCHAR szText[] = TEXT("kernel32.dll在本程序地址空间的基地址为：%08x\n");
	TCHAR  szText1[] = TEXT("GetProcAddress代码在本程序地址空间的首址为：%08x\n");
	TCHAR  szText2[] = TEXT("LoadLibraryA代码在本程序地址空间的首址为：%08x\n");

	TCHAR szGetProcAddr[] = TEXT("GetProcAddress");
	TCHAR szLoadLib[] = TEXT("LoadLibraryA");

	// 获取kernel32.dll基址
	kernel32Base = _getKernelBase();
	// 输出
	wsprintf(szBuffer, szText, kernel32Base);
	MessageBox(NULL, szBuffer, NULL, MB_OK);

	// 为函数引用赋值 GetProcAddress
	_getProcAddress = (PROC)_getApi(kernel32Base, szGetProcAddr);
	// 输出
	wsprintf(szBuffer, szText1, _getProcAddress);
	MessageBox(NULL, szBuffer, NULL, MB_OK);

	// 找到loadLib函数的地址
	lpLoadLib = _getProcAddress(kernel32Base, szLoadLib);
	// 输出
	wsprintf(szBuffer, szText2, lpLoadLib);
	MessageBox(NULL, szBuffer, NULL, MB_OK);



	
	return 0;
}