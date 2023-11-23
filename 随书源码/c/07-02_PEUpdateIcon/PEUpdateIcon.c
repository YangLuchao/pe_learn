#include <Windows.h>
#include<Richedit.h>
#include "resource.h"

#pragma pack(1)

typedef struct
{
	TBYTE bWidth;
	TBYTE bHeight;
	TBYTE bColorCount;
	TBYTE bReserved;
	WORD wPlanes;
	WORD wBitCount;
	DWORD dwBytesInRes;
	DWORD dwImageOffset;
}ICON_DIR_ENTRY, *PICON_DIR_ENTRY;

typedef struct
{
	WORD idReserved;
	WORD idType;
	WORD idCount;
	ICON_DIR_ENTRY idEntries;
}ICON_DIR, *PICON_DIR;

typedef struct
{
	TBYTE bWidth;
	TBYTE bHeight;
	TBYTE bColorCount;
	TBYTE bReserved;
	WORD wPlanes;
	WORD wBitCount;
	DWORD dwBytesInRes;
	WORD nID;
}PE_ICON_DIR_ENTRY, *PPE_ICON_DIR_ENTRY;

typedef struct
{
	WORD idReserved;
	WORD idType;
	WORD idCount;
	PE_ICON_DIR_ENTRY idEntries;
}PE_ICON_DIR, *PPE_ICON_DIR;



HINSTANCE hInstance;
HWND hWinEdit;


/*
初始化窗口程序
*/
void _Init(HWND hWinMain)
{

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
往文本框中追加文本
*/
void _appendInfo(PTCHAR _lpsz)
{
	CHARRANGE stCR;
	int iTextLength;

	iTextLength = GetWindowTextLength(hWinEdit);
	stCR.cpMin = iTextLength;
	stCR.cpMax = iTextLength;

	SendMessage(hWinEdit, EM_EXSETSEL, 0, (LPARAM)&stCR);
	SendMessage(hWinEdit, EM_REPLACESEL, FALSE, (LPARAM)_lpsz);

}


/*
将boy.ico图标替换指定PE程序的图标
使用win32 api函数UpdateResource实现此功能
*/
BOOL _doUpdate(PTCHAR _lpszFile, PTCHAR _lpszExeFile)
{
	BOOL ret = FALSE;
	HANDLE hFile;
	DWORD dwReserved;
	ICON_DIR stIconDir;
	DWORD nSize;
	PVOID pIcon;
	PE_ICON_DIR stPeIconDir;
	HANDLE hUpdate;



	hFile = CreateFile(_lpszFile, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
	if (hFile == INVALID_HANDLE_VALUE)
	{
		return ret;
	}

	RtlZeroMemory(&stIconDir, sizeof(stIconDir));
	ReadFile(hFile, &stIconDir, sizeof(stIconDir), &dwReserved, NULL);

	nSize = stIconDir.idEntries.dwBytesInRes;
	pIcon = GlobalAlloc(GPTR, nSize);

	SetFilePointer(hFile, stIconDir.idEntries.dwImageOffset, NULL, FILE_BEGIN);
	if (ReadFile(hFile, pIcon, nSize, &dwReserved, NULL))
	{
		RtlZeroMemory(&stPeIconDir, sizeof(stPeIconDir));
		stPeIconDir = *(PPE_ICON_DIR)&stIconDir;
		stPeIconDir.idEntries.nID = 1;

		//开始修改
		hUpdate = BeginUpdateResource(_lpszExeFile, FALSE);
		if (UpdateResource(hUpdate, RT_GROUP_ICON, MAKEINTRESOURCE(101), 2052, (LPVOID)&stPeIconDir, sizeof(stPeIconDir)))
		{
			ret = TRUE;
		}

		if (!UpdateResource(hUpdate, RT_ICON, MAKEINTRESOURCE(1), 2052, pIcon, nSize))
		{
			ret = FALSE;
		}
		EndUpdateResource(hUpdate, FALSE);
	}
	GlobalFree(pIcon);
	CloseHandle(hFile);
	return ret;
}



/*
选择PE文件并处理
*/
void _openFile(HWND hWinMain)
{
	OPENFILENAME stOF;

	TCHAR szFileName[MAX_PATH] = { 0 };	//要打开的文件路径及名称名
	TCHAR szExtPe[] = TEXT("PE Files\0*.exe;*.dll;*.scr;*.fon;*.drv\0All Files(*.*)\0*.*\0\0");



	RtlZeroMemory(&stOF, sizeof(stOF));
	stOF.lStructSize = sizeof(stOF);
	stOF.hwndOwner = hWinMain;
	stOF.lpstrFilter = szExtPe;
	stOF.lpstrFile = szFileName;
	stOF.nMaxFile = MAX_PATH;
	stOF.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST;




	if (GetOpenFileName(&stOF))		//让用户选择打开的文件
	{
		//将boy.ico的图标数据写入PE文件
		if (_doUpdate(TEXT("boy.ico"), szFileName))
		{
			_appendInfo(TEXT("恭喜你，图标修改成功。\n"));
		}
		else
		{
			_appendInfo(TEXT("执行图标修改失败。\n"));
		}
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

		case IDM_OPEN:			//打开文件
			_openFile(hWnd);
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