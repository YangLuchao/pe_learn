//基址0x00400000
//release版
//禁止优化
//保留未使用的函数和数据
//禁用安全检查 (/GS-)
//
//把注入代码中的数据写成局部变量，这样就不需要重定位了

#include <Windows.h>
#include<Richedit.h>
#include "resource.h"



HINSTANCE hInstance;


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
执行远程线程
*/
void _remoteThread()
{
	DWORD hKernel32Base;// kernel32.dll基址
	PROC _getProcAddress;// getProcAddress函数地址
	PROC _loadLibrary;// loadLibrary函数地址
	HMODULE hUser32Base;// user32基址
	PROC _messageBox;// messageBox函数地址


	TCHAR szGetProcAddr[] = { 'G', 'e', 't', 'P', 'r', 'o', 'c', 'A', 'd', 'd', 'r', 'e', 's', 's' ,0};
	TCHAR szLoadLib[] = { 'L', 'o', 'a', 'd', 'L', 'i', 'b', 'r', 'a', 'r', 'y', 'A' ,0};
	TCHAR user32_DLL[] = { 'u', 's', 'e', 'r', '3', '2', '.', 'd', 'l', 'l' ,0};
	TCHAR szMessageBox[] = { 'M', 'e', 's', 's', 'a', 'g', 'e', 'B', 'o', 'x', 'A' ,0};
	TCHAR szText[] = { 'H', 'e', 'l', 'l', 'o', 'W', 'o', 'r', 'l', 'd', 'P', 'E' ,0};

	// 获取kernel32.dll的基地址
	hKernel32Base = _getKernelBase();
	// 从基地址出发搜索GetProcAddress函数的首址
	_getProcAddress = (PROC)_getApi(hKernel32Base, szGetProcAddr);
	// 使用GetProcAddress函数的首址
	// 传入两个参数调用GetProcAddress函数，获得LoadLibraryA的首址
	_loadLibrary = (PROC)_getProcAddress(hKernel32Base, szLoadLib);
	// 使用LoadLibrary获取user32.dll的基地址
	hUser32Base = (HMODULE)_loadLibrary(user32_DLL);
	// 使用GetProcAddress函数的首址，获得函数MessageBoxA的首址
	_messageBox = (PROC)_getProcAddress(hUser32Base, szMessageBox);
	// 调用函数MessageBoxA
	_messageBox(NULL, szText, NULL, MB_OK);
}






/*
初始化窗口程序
*/
void _Init(HWND hWinMain)
{
	HWND hWinEdit;

	HICON hIcon;
	CHARFORMAT stCf;
	TCHAR szFont[] = TEXT("宋体");


	hWinEdit = GetDlgItem(hWinMain, IDC_INFO);
	hIcon = LoadIcon(hInstance, MAKEINTRESOURCE(ICO_MAIN));
	SendMessage(hWinMain, WM_SETICON, ICON_BIG, (LPARAM)hIcon);	//为窗口设置图标
	SendMessage(hWinEdit, EM_SETTEXTMODE, TM_PLAINTEXT, 0);		//设置编辑控件

	RtlZeroMemory(&stCf, sizeof(stCf));
	stCf.cbSize = sizeof(stCf);
	stCf.yHeight = 9 * 20;
	stCf.dwMask = CFM_FACE | CFM_SIZE | CFM_BOLD;
	lstrcpy(stCf.szFaceName, szFont);
	SendMessage(hWinEdit, EM_SETCHARFORMAT, 0, (LPARAM)&stCf);

	SendMessage(hWinEdit, EM_EXLIMITTEXT, 0, -1);
}



/*
将远程线程打到进程PEInfo.exe中
测试方法：首先运行PEInfo.exe
启动该程序,单击第一个菜单的第一项
会发现桌面上弹出HelloWorldPE对话框
*/
void _patchPEInfo()
{
	HWND phwnd;
	DWORD parent = 0;
	DWORD hProcessID;
	HANDLE hProcess;
	DWORD dwPatchDD = 1;
	LPVOID lpRemote;
	DWORD dwTemp;


	TCHAR strTitle[256];
	TCHAR szTitle[] = TEXT("PEInfo");
	TCHAR szErr1[] = TEXT("Error happend when openning.");
	TCHAR szErr2[] = TEXT("Error happend when virtualing.");



	//通过标题获得进程的handle	
	phwnd = GetWindow(GetWindow(GetDesktopWindow(), GW_CHILD), GW_HWNDFIRST);
	if (!GetParent(phwnd))
	{
		parent = 1;
	}

	while (phwnd)
	{
		if (parent)
		{
			parent = 0;//复位标志
			GetWindowText(phwnd, strTitle, sizeof(strTitle));//得到窗口标题文字
			if (!lstrcmp(strTitle, szTitle))
			{
				break;
			}
		}

		//寻找这个窗口的下一个兄弟窗口
		phwnd = GetWindow(phwnd, GW_HWNDNEXT);
		if (!GetParent(phwnd) && IsWindowVisible(phwnd))
		{
			parent = 1;
		}
	}


	GetWindowThreadProcessId(phwnd, &hProcessID);	//根据窗口句柄获取进程ID
/*
HANDLE OpenProcess(
	DWORD dwDesiredAccess,	//访问权限
	BOOL bInheritHandle,	//继承标志，若句柄能由子进程继承，则设置为TRUE
	DWORD dwProcessId		//进程号
);
*/
	if (hProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, hProcessID))//找到的进程句柄在hProcess中
	{
/*
LPVOID VirtualAllocEx(
	HANDLE hProcess,		//申请内存所在的进程句柄
	LPVOID lpAddress,		//保留页面的内存地址，NULL表示自动分配
	SIZE_T dwSize,			//欲分配的内存大小
	DWORD flAllocationType, //内存分配属性
	DWORD flProtect			//分配区页面属性,PAGE_EXECUTE_READWRITE 分配可执行的读/写内存
);
*/
		if (lpRemote = VirtualAllocEx(hProcess, NULL, ((DWORD)_Init - (DWORD)_getKernelBase),
			MEM_COMMIT, PAGE_EXECUTE_READWRITE))//分配空间
		{
/*
BOOL WriteProcessMemory(
	HANDLE hProcess,		//远程进程句柄
	PVOID pvAddressRemote,	//远程进程地址VA值
	PVOID pvBufferLocal,	//存放数据的缓冲区
	DWORD dwSize,			//缓冲区大小
	PDWORD pdwNumBytesRead	//读写的字节数，是返回值
);
*/
			WriteProcessMemory(hProcess, lpRemote, _getKernelBase,
				((DWORD)_Init - (DWORD)_getKernelBase), &dwTemp);//写入线程代码
			
/*
HANDLE CreateRemoteThread(
	HANDLE hProcess,							//目标进程句柄
	LPSECURITY_ATTRIBUTES lpThreadAttributes,	//安全属性
	SIZE_T dwStackSize,							//线程栈大小
	LPTHREAD_START_ROUTINE lpStartAddress,		//线程起始地址
	LPVOID lpParameter,							//传入参数
	DWORD dwCreationFlags,						//创建标志字
	LPDWORD lpThreadId							//（输出）线程句柄
);
*/
			CreateRemoteThread(hProcess, NULL, 0, 
				// VA地址，开启远程线程后直接开始执行
				(LPTHREAD_START_ROUTINE)((DWORD)lpRemote + (DWORD)_remoteThread - (DWORD)_getKernelBase),
				0, 0, NULL);
		}
		else
		{
			MessageBox(NULL, szErr2, NULL, MB_OK);
		}
		CloseHandle(hProcess);
	}
	else
	{
		MessageBox(NULL, szErr1, NULL, MB_OK);
	}
}



/*
窗口程序
*/
INT_PTR CALLBACK _ProcDlgMain(HWND hWnd, UINT wMsg, WPARAM wParam, LPARAM lParam)
{
	switch (wMsg)
	{
	case WM_CLOSE:
		EndDialog(hWnd, 0);
		break;

	case WM_INITDIALOG:			//初始化
		_Init(hWnd);
		break;

	case WM_COMMAND:			//菜单
		switch (LOWORD(wParam))
		{
		case IDM_EXIT:			//退出
			EndDialog(hWnd, 0);
			break;

		case IDM_OPEN:			
			_patchPEInfo();
			break;

		case IDM_1:
		case IDM_2:
		case IDM_3:
		default:
			break;
		}
		break;

	default:
		return FALSE;
	}

	return TRUE;
}




int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	HMODULE hRichEdit;

	hInstance = hInst;
	hRichEdit = LoadLibrary(TEXT("RichEd20.dll"));
	DialogBoxParam(hInstance, MAKEINTRESOURCE(DLG_MAIN), NULL, _ProcDlgMain, (LPARAM)NULL);
	FreeLibrary(hRichEdit);
	return 0;
}