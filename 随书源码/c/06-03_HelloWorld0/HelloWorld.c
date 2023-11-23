//无导入表的HelloWorld,
//
//HelloWorld0和HelloWorld1都是这一个程序，
//把数据写成局部变量，就都不需要重定位了
//
//因为vc程序main函数之前调用系统函数初始化，
//所以程序含有导入表，
//但是不包括我们用的这些
//
//release版
//禁止优化
//禁用安全检查



#include <Windows.h>


/*
获取kernel32.dll的基地址
因为vc程序main函数之前会有初始化，所以不能通过堆栈栈顶值获取kernel32.dll中的地址
因此通过 PEB 结构获取Kernel32.dll基址
*/
DWORD _getKernelBase()
{
	DWORD dwPEB;//PED地址，用来找kernel32首地址
	DWORD dwLDR;//LDR指针，用来找kernel32首地址
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
入口参数：	_hModule 为动态链接库的基址
			_lpApi 为API函数名的首址
出口参数：	eax为函数在虚拟地址空间中的真实地址
*/
DWORD _getApi(DWORD _hModule, PTCHAR _lpApi)
{
	DWORD i;
	DWORD dwLen;
	PIMAGE_DOS_HEADER pImageDosHeader;//指向DOS头的指针
	PIMAGE_NT_HEADERS pImageNtHeaders;//指向NT头的指针
	DWORD dwVirtualAddress;//导出表偏移地址
	PIMAGE_EXPORT_DIRECTORY pImageExportDirectory;//指向导出表的指针
	TCHAR ** lpAddressOfNames;
	PWORD lpAddressOfNameOrdinals;

	//计算API字符串的长度
	for (i = 0; _lpApi[i]; ++i);
	dwLen = i;



	pImageDosHeader = (PIMAGE_DOS_HEADER)_hModule;//DOS头
	pImageNtHeaders = (PIMAGE_NT_HEADERS)(_hModule + pImageDosHeader->e_lfanew);//NT头
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
				//按名字导出函数索引列表
				lpAddressOfNameOrdinals = (PWORD)(_hModule + pImageExportDirectory->AddressOfNameOrdinals);
				
				return _hModule + ((PDWORD)(_hModule + pImageExportDirectory->AddressOfFunctions))
					[lpAddressOfNameOrdinals[i]];//根据函数索引找到函数地址
			}
		}
	}
	return 0;
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR szCmdLine, int iCmdShow)
{
	DWORD hKernel32Base;// kernel32首地址
	DWORD hUser32Base;//user32首地址
	// PROC为声明式的函数指针
	PROC _getProcAddress;//getProcAddress函数地址
	PROC _loadLibrary;// loadLibrary函数地址
	PROC _messageBox;//messageBox地址

	TCHAR szGetProcAddr[] =	{ 'G', 'e', 't', 'P', 'r', 'o', 'c', 'A', 'd', 'd', 'r', 'e', 's', 's', 0 };
	TCHAR szLoadLib[] =		{ 'L', 'o', 'a', 'd', 'L', 'i', 'b', 'r', 'a', 'r', 'y', 'A', 0 };
	TCHAR szMessageBox[] =	{ 'M', 'e', 's', 's', 'a', 'g', 'e', 'B', 'o', 'x', 'A', 0 };
	TCHAR szText[] =		{ 'H', 'e', 'l', 'l', 'o', 'W', 'o', 'r', 'l', 'd', 'P', 'E', 0 };
	TCHAR user32_DLL[] =	{ 'u', 's', 'e', 'r', '3', '2', '.', 'd', 'l', 'l', 0 };
	

	
			
		  
		 
	hKernel32Base = _getKernelBase();//获取kernel32.dll的基地址
	_getProcAddress = (PROC)_getApi(hKernel32Base, szGetProcAddr);//搜索GetProcAddress函数的首址
	_loadLibrary = (PROC)_getProcAddress(hKernel32Base, szLoadLib);//调用GetProcAddress函数，获得LoadLibraryA的首址
	hUser32Base = _loadLibrary(user32_DLL);//使用LoadLibrary获取user32.dll的基地址
	_messageBox = (PROC)_getProcAddress(hUser32Base, szMessageBox);//获得函数MessageBoxA的首址
	_messageBox(NULL, szText, NULL, MB_OK);//调用函数MessageBoxA
	return 0;
}