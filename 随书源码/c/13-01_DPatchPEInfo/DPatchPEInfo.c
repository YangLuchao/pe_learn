// 02-04_PEInfo基址0x00400000
// 此程序基址0x00400000
// 资源节设为可读写
#include <Windows.h>
#include<Richedit.h>
#include "resource.h"


#define STOP_FLAG_POSITION  0x0041c000  //02-04_PEInfo中dwFlag在内存中的地址

#define MAJOR_IMAGE_VERSION  1//当前程序的主版本号
#define MINOR_IMAGE_VERSION  0//当前程序的次版本号

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
写内存示例
测试方法：首先运行PEInfo.exe
          显示Kernel32.dll的信息
启动该程序,在kernel32.dll显示重定位时单击菜单第一项
会发现PEInfo.exe的遍历重定位信息被终止
*/
void _writeToPEInfo()
{
	HWND phwnd;// 窗口句柄
	DWORD parent = 0;
	DWORD hProcessID;
	HANDLE hProcess;
	DWORD dwFlag;
	DWORD dwPatchDD = 1;


	TCHAR strTitle[256];
	TCHAR szTitle[] = TEXT("PEInfo");
	TCHAR szErr1[] = TEXT("Error happend when openning.");
	TCHAR szErr2[] = TEXT("Error happend when reading.");

	//通过标题获得进程的handle	
	// GetDesktopWindow： 获取桌面窗口句柄
	// GetWindow： 获取指定窗口句柄
	// GW_CHILD：如果指定的窗口是父窗口，则检索到的句柄标识 Z 顺序顶部的子窗口
	// GW_HWNDFIRST:检索的句柄标识 Z 顺序中最高类型的窗口
	phwnd = GetWindow(GetWindow(GetDesktopWindow(), GW_CHILD), GW_HWNDFIRST);
	// 判断是否为顶层窗口
	if (!GetParent(phwnd))
	{
		parent = 1;
	}
	// ----------------------------------------------这一坨就是找目标窗口的句柄
	while (phwnd)
	{
		if (parent)
		{
			parent = 0; //复位标志
			GetWindowText(phwnd, strTitle, sizeof(strTitle));//得到窗口标题文字
			if (!lstrcmp(strTitle, szTitle))
			{
				break;
			}
		}

		// 寻找这个窗口的下一个兄弟窗口
		phwnd = GetWindow(phwnd, GW_HWNDNEXT);
		if (!GetParent(phwnd) && IsWindowVisible(phwnd))
		{
			parent = 1;
		}
	}
	// ----------------------------------------------这一坨就是找目标窗口的句柄

	//根据窗口句柄获取进程ID
	GetWindowThreadProcessId(phwnd, &hProcessID);	
	if (hProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, hProcessID))//找到的进程句柄在hProcess中
	{
		if (ReadProcessMemory(hProcess, (LPCVOID)STOP_FLAG_POSITION, &dwFlag, 4, NULL))//读内存
		{
			WriteProcessMemory(hProcess,(LPVOID)STOP_FLAG_POSITION, &dwPatchDD,	4, NULL);//写内存，将标志位赋值
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
释放资源
*/
void _createDll()
{
	HRSRC hRes;
	DWORD dwResSize;
	HGLOBAL hGlobal;
	PVOID lpRes;
	HANDLE hFile;
	DWORD dwWritten;

	if (hRes = FindResource(hInstance, MAKEINTRESOURCE(IDB_UPDATE), "UPDATE"))
	{
		dwResSize = SizeofResource(hInstance, hRes); //获取资源尺寸
		if (hGlobal = LoadResource(hInstance, hRes))//装入资源
		{
			lpRes = LockResource(hGlobal); //锁定资源,将资源内存地址给lpRes
				
			//打开文件写入
			hFile = CreateFile(TEXT("update.exe"), GENERIC_WRITE, FILE_SHARE_READ, 0,
				CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
			WriteFile(hFile, lpRes, dwResSize, &dwWritten, NULL);
			CloseHandle(hFile);
		}
	}
}


/*
窗口程序
*/
INT_PTR CALLBACK _ProcDlgMain(HWND hWnd, UINT wMsg, WPARAM wParam, LPARAM lParam)
{
	STARTUPINFO	stStartUp;// 创建上下文时的信息结构
	PROCESS_INFORMATION stProcInfo;// 资源信息指针


	DWORD value;
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

		case IDM_OPEN:			//停止
			_writeToPEInfo();
			break;

		case IDM_1:				//升级
			GetWindowThreadProcessId(hWnd, &value);
			*(PDWORD)0x00406484 = value;//0x0040647c处为update中的hProcessID
			*(PDWORD)0x0040648c = MAJOR_IMAGE_VERSION;//0x00406484处为update中的oldMajor
			*(PDWORD)0x00406488 = MINOR_IMAGE_VERSION;//0x00406480处为update中的oldMinor

			_createDll();//释放update.exe程序

			//运行update.exe程序
			GetStartupInfo(&stStartUp);
			CreateProcess(NULL, TEXT("update.exe"), NULL, NULL, FALSE, NORMAL_PRIORITY_CLASS, 
				NULL, NULL, &stStartUp, &stProcInfo);



			break;
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
	HMODULE hRichEdit;// 文本控件句柄

	hInstance = hInst;//当前进程句柄
	hRichEdit = LoadLibrary(TEXT("RichEd20.dll"));//加载文本控件
	DialogBoxParam(hInstance, MAKEINTRESOURCE(DLG_MAIN), NULL, _ProcDlgMain, (LPARAM)NULL);// 执行_ProcDlgMain函数，并打开对话框
	FreeLibrary(hRichEdit);// 释放文本控件
	return 0;
}