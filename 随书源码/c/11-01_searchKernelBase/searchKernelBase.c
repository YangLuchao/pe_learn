// 获取kernel32.dll的基址
// 从进程地址空间搜索kernel32.dll的基地址
//
//
// kernelbase.dll导出函数也有GetProcAddress
//
#include<windows.h>


int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	TCHAR szGetProcAddress[] = TEXT("GetProcAddress");// 需要查找的函数名
	DWORD dwAddress;// 遍历内存块的起始地址
	PIMAGE_NT_HEADERS pImageNtHeaders;//NT头基址
	DWORD dwVirtualAddress;// VA
	DWORD dwSize;// 
	PIMAGE_EXPORT_DIRECTORY pImageExportDirectory;//导出表结构体
	TCHAR ** lpAddressOfNames;// 函数名地址
	DWORD dwNumberOfNames;
	TCHAR szBuffer[256];


	//从高地址开始
	for (dwAddress = 0x7ffe0000; TRUE; dwAddress -= 0x10000)
	{
		// IsBadReadPtr：验证调用进程是否具有对指定内存范围的读取访问权限
		// 第一个参数：指向内存块的第一个字节的指针
		// 第二个参数：内存块大小
		if (IsBadReadPtr((PVOID)dwAddress, 2))
		{ 
			// 没有权限-10页
			continue;
		}

		if (*(PWORD)dwAddress == 0x5A4D)//判断是否为MS DOS头标志
		{
			// NT头
			pImageNtHeaders = (PIMAGE_NT_HEADERS)(dwAddress +
				((PIMAGE_DOS_HEADER)dwAddress)->e_lfanew);
			// 导出表RVA
			dwVirtualAddress = pImageNtHeaders->OptionalHeader.DataDirectory[0].VirtualAddress;
			// 导出表大小
			dwSize = pImageNtHeaders->OptionalHeader.DataDirectory[0].Size;
			if (dwVirtualAddress && dwSize)// RVA 和 导出表大小都不为0
			{
				// 指向数据目录中的导出表
				pImageExportDirectory = (PIMAGE_EXPORT_DIRECTORY)(dwAddress + dwVirtualAddress);
				// 指向导出表的导出函数名字数组
				lpAddressOfNames = (TCHAR **)(dwAddress + pImageExportDirectory->AddressOfNames);
				// 指向导出表的导出函数个数
				dwNumberOfNames = pImageExportDirectory->NumberOfNames;
				
				for (DWORD i = 0; i < dwNumberOfNames; ++i)
				{
					if (strlen(dwAddress + lpAddressOfNames[i]) == 0xe && // 长度要相等,
						!strcmp(dwAddress + lpAddressOfNames[i], szGetProcAddress))// 两个名字要完全一样
					{
						// 找到特征函数,输出模块基地址
						wsprintf(szBuffer, TEXT("kernel32.dll的基地址为%08x"), dwAddress);
						// messagebox输出
						MessageBox(NULL, szBuffer, NULL, MB_OK);

						return 0;
					}
				}	
			}
		}
	}

}

