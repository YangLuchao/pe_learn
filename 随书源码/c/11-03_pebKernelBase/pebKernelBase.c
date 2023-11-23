//获取kernel32.dll的基址
//从PEB结构中搜索kernel32.dll的基地址
//
//
//xp下KERNEL32为第二个，
//win7下KERNEL32为第三个
//为了实用，采用遍历链表，比较导出表中dll名字的方式



#include<Windows.h>


int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR szCmdLine, int iCmdShow)
{
	DWORD dwPEB;//PEB地址
	DWORD dwLDR;//LEDR地址
	DWORD dwInitList;
	DWORD dwDllBase;//当前地址
	PIMAGE_DOS_HEADER pImageDosHeader;//指向DOS头的指针
	PIMAGE_NT_HEADERS pImageNtHeaders;//指向NT头的指针
	DWORD dwVirtualAddress;//导出表偏移地址
	PIMAGE_EXPORT_DIRECTORY pImageExportDirectory;//指向导出表的指针
	PTCHAR lpName;//指向dll名字的指针
	TCHAR szKernel32[] = TEXT("KERNEL32.dll");
	TCHAR szBuffer[256];


	__asm
	{
		mov eax, FS:[0x30]	//获取PEB所在地址
		mov dwPEB, eax
	}

	//获取PEB_LDR_DATA 结构指针
	dwLDR = *(PDWORD)(dwPEB + 0xc);
	//获取InInitializationOrderModuleList 链表头
	//第一个LDR_MODULE节点InInitializationOrderModuleList成员的指针
	dwInitList = *(PDWORD)(dwLDR + 0x1c);


	for (;
		dwDllBase = *(PDWORD)(dwInitList + 8);	//结构偏移0x8处存放模块基址
		dwInitList = *(PDWORD)dwInitList		//结构偏移0处存放下一模块结构的指针
		)
	{
		// 转DOS头
		pImageDosHeader = (PIMAGE_DOS_HEADER)dwDllBase;
		// 转NT头
		pImageNtHeaders = (PIMAGE_NT_HEADERS)(dwDllBase + pImageDosHeader->e_lfanew);
		// 导出表偏移
		dwVirtualAddress = pImageNtHeaders->OptionalHeader.DataDirectory[0].VirtualAddress; 
		// 导出表地址
		pImageExportDirectory = (PIMAGE_EXPORT_DIRECTORY)(dwDllBase + dwVirtualAddress);
		// dll名字
		lpName = (PTCHAR)(dwDllBase + pImageExportDirectory->Name);
		// 判断是否为“KERNEL32.dll”
		if (strlen(lpName) == 0xc && !strcmp(lpName, szKernel32))
		{
			//输出模块基地址
			wsprintf(szBuffer, TEXT("kernel32.dll的基地址为%08x"), dwDllBase);
			MessageBox(NULL, szBuffer, NULL, MB_OK);
			break;
		}
	}
	return 0;
}
