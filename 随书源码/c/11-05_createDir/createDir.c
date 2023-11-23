//一个简单的测试API入口函数动态获得的小程序
//本例将使用动态方法获得hDllKernel32的基址，
//并从基址处查找相对应的函数，以及偏移
//实现创建目录的方法、对话框显示方法调用
//
//
//
//将数据执行保护(DEP)关闭，
//


#include<Windows.h>

#pragma pack(1)

typedef struct 
{
	DWORD CreateDir;	//CreateDirectoryA函数的真实地址
	DWORD lpCreateDir;	//未用
	WORD jmpCreateDir;	// 0x25ff 这是一个跳转指令，即段内跳转jmp
	DWORD jmpCDOffset;	// 这里紧跟着要跳转到的偏移，该偏移指向CreateDir，;
}MyStruct, *PMyStruct;

       



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



	pImageDosHeader = (PIMAGE_DOS_HEADER)_hModule;
	pImageNtHeaders = (PIMAGE_NT_HEADERS)(_hModule + pImageDosHeader->e_lfanew);
	dwVirtualAddress = pImageNtHeaders->OptionalHeader.DataDirectory[0].VirtualAddress;//导出表偏移 
	pImageExportDirectory = (PIMAGE_EXPORT_DIRECTORY)(_hModule + dwVirtualAddress);//导出表地址
	lpAddressOfNames = (TCHAR **)(_hModule + pImageExportDirectory->AddressOfNames);//按名字导出函数列表
	for (i = 0; _hModule + lpAddressOfNames[i]; ++i)
	{
		if (strlen(_hModule + lpAddressOfNames[i]) == dwLen &&
			!strcmp(_hModule + lpAddressOfNames[i], _lpApi))//判断是否为_lpApi
		{
			lpAddressOfNameOrdinals = (PWORD)(_hModule + pImageExportDirectory->AddressOfNameOrdinals);//按名字导出函数索引列表

			return _hModule + ((PDWORD)(_hModule + pImageExportDirectory->AddressOfFunctions))
				[lpAddressOfNameOrdinals[i]];//根据函数索引找到函数地址

		}
	}
	return 0;
}



int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR szCmdLine, int iCmdShow)
{
	MyStruct stMyStruct;
	
	DWORD hDllKernel32 = 0;
	PROC _GetProcAddress = NULL;
	PROC _LoadLibrary = NULL;
	HMODULE hDllUser32;
	PROC _MessageBox = NULL;


	TCHAR szGetProcAddress[] = TEXT("GetProcAddress");
	TCHAR szLoadLib[] = TEXT("LoadLibraryA");
	TCHAR szCreateDir[] = TEXT("CreateDirectoryA");//该方法在kernel32.dll中
	TCHAR szDir[] = TEXT("c:\\BBBN");
	TCHAR szLoadLibrary[] = TEXT("LoadLibraryA");
	TCHAR szUser32[] = TEXT("user32.dll");
	TCHAR szMessageBox[] = TEXT("MessageBoxA"); //该方法在user32.dll中
	TCHAR szText[] = TEXT("请检查一下c盘根目录下，看是否有目录BBBN的出现？");
	TCHAR szCaption[] = TEXT("动态调用API函数示例");



	stMyStruct.jmpCDOffset = (DWORD)&stMyStruct.CreateDir;
	stMyStruct.jmpCreateDir = 0x25ff;//这是一个跳转指令，即段内跳转jmp
	

	if (hDllKernel32 = _getKernelBase())
	{
		if (_GetProcAddress = (PROC)_getApi(hDllKernel32, szGetProcAddress));//获取GetProcAddress函数的内存地址
		{
			stMyStruct.CreateDir = _GetProcAddress(hDllKernel32, szCreateDir); //获取创建目录函数的内存地址并调用
			((PROC)&stMyStruct.jmpCreateDir)(szDir, NULL);
		
			if (_LoadLibrary = (PROC)_GetProcAddress(hDllKernel32, szLoadLibrary)) //获取LoadLibrary函数的内存地址
			{
				hDllUser32 = (HMODULE)_LoadLibrary(szUser32);//装载user32.dll
				if (_MessageBox = (PROC)_GetProcAddress(hDllUser32, szMessageBox))//获得MessageBox函数的内存地址并调用
				{
					_MessageBox(NULL, szText, szCaption, MB_OK);
				}
			}
		}
	}
	return 0;
}