//运行时动态创建dll
//
//编译前
//把		 05-01_winResult.dll1(初始dll)
//重命名为	 05-01_winResult.dll
//放在当前目录
//在延迟加载的dll中添加05-01_winResult.dll
//
//运行前
//把05-01_winResult.dll删除或修改名字，仍然能运行

#include <Windows.h>
#include <Richedit.h>
#include "resource.h"
#include"..//05-01_winResult//winResult.h"





HINSTANCE hInstance;

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
		AnimateOpen(hWnd);
		_Init(hWnd);
		break;

	case WM_COMMAND:			//菜单
		switch (LOWORD(wParam))
		{
		case IDM_EXIT:			//退出
			EndDialog(hWnd, 0);
			break;

		case IDM_OPEN:			//打开文件
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



//动态创建winResult.dll
void _createDll(HINSTANCE  _hInstance)
{
	HRSRC hRes;// 指定资源的信息块的句柄
	DWORD dwResSize;// 资源大小
	HGLOBAL hGlobal;// 如果函数成功，则返回值是与资源关联的数据的句柄
	PVOID lpRes;	// 如果加载的资源可用，则返回值是指向资源第一个字节的指针
	HANDLE hFile;	// 如果函数成功，则返回值是指定文件、设备、命名管道或邮件槽的打开句柄
	DWORD dwWritten;


	// 寻找资源
	// FindResource: 确定指定模块中具有指定类型和名称的资源的位置
	if (hRes = FindResource(_hInstance, TEXT("IDB_WINRESULT"), TEXT("DLLTYPE")))
	{
		// 获取资源尺寸 
		// SizeofResource: 检索指定资源的大小（以字节为单位）
		dwResSize = SizeofResource(_hInstance, hRes); 
		// 装入资源
		// LoadResource: 检索可用于获取指向内存中指定资源第一个字节的指针的句柄
		if (hGlobal = LoadResource(_hInstance, hRes))
		{
			// LockResource: 检索指向内存中指定资源的指针
			if (lpRes = LockResource(hGlobal)) //锁定资源
			{
				// 打开文件写入
				// 创建或者打开文件或 I/O 设备
				hFile = CreateFile(TEXT("05-01_winResult.dll"), GENERIC_WRITE, FILE_SHARE_READ,
					0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
				// 将数据写入指定的文件或输入/输出 (I/O) 设备
				// dwWritten: 指向变量的指针，该变量接收使用同步 hFile 参数时写入的字节数
				WriteFile(hFile, lpRes, dwResSize, &dwWritten, NULL);
				// 关闭打开的对象句柄
				CloseHandle(hFile);
			}
		}
	}
}




int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	HMODULE hRichEdit;

	hInstance = hInst;
	hRichEdit = LoadLibrary(TEXT("RichEd20.dll"));
	_createDll(hInstance);//在未调用DLL函数前先释放该DLL文件
	DialogBoxParam(hInstance, MAKEINTRESOURCE(DLG_MAIN), NULL, _ProcDlgMain, (LPARAM)NULL);
	FreeLibrary(hRichEdit);
	return 0;
}