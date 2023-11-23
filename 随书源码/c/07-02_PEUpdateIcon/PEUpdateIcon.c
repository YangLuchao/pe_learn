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
��ʼ�����ڳ���
*/
void _Init(HWND hWinMain)
{

	HICON hIcon;
	CHARFORMAT stCf;
	TCHAR szFont[] = TEXT("����");


	hWinEdit = GetDlgItem(hWinMain, IDC_INFO);
	hIcon = LoadIcon(hInstance, MAKEINTRESOURCE(ICO_MAIN));
	SendMessage(hWinMain, WM_SETICON, ICON_BIG, (LPARAM)hIcon);	//Ϊ��������ͼ��
	SendMessage(hWinEdit, EM_SETTEXTMODE, TM_PLAINTEXT, 0);		//���ñ༭�ؼ�

	RtlZeroMemory(&stCf, sizeof(stCf));
	stCf.cbSize = sizeof(stCf);
	stCf.yHeight = 9 * 20;
	stCf.dwMask = CFM_FACE | CFM_SIZE | CFM_BOLD;
	lstrcpy(stCf.szFaceName, szFont);
	SendMessage(hWinEdit, EM_SETCHARFORMAT, 0, (LPARAM)&stCf);

	SendMessage(hWinEdit, EM_EXLIMITTEXT, 0, -1);
}


/*
���ı�����׷���ı�
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
��boy.icoͼ���滻ָ��PE�����ͼ��
ʹ��win32 api����UpdateResourceʵ�ִ˹���
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

		//��ʼ�޸�
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
ѡ��PE�ļ�������
*/
void _openFile(HWND hWinMain)
{
	OPENFILENAME stOF;

	TCHAR szFileName[MAX_PATH] = { 0 };	//Ҫ�򿪵��ļ�·����������
	TCHAR szExtPe[] = TEXT("PE Files\0*.exe;*.dll;*.scr;*.fon;*.drv\0All Files(*.*)\0*.*\0\0");



	RtlZeroMemory(&stOF, sizeof(stOF));
	stOF.lStructSize = sizeof(stOF);
	stOF.hwndOwner = hWinMain;
	stOF.lpstrFilter = szExtPe;
	stOF.lpstrFile = szFileName;
	stOF.nMaxFile = MAX_PATH;
	stOF.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST;




	if (GetOpenFileName(&stOF))		//���û�ѡ��򿪵��ļ�
	{
		//��boy.ico��ͼ������д��PE�ļ�
		if (_doUpdate(TEXT("boy.ico"), szFileName))
		{
			_appendInfo(TEXT("��ϲ�㣬ͼ���޸ĳɹ���\n"));
		}
		else
		{
			_appendInfo(TEXT("ִ��ͼ���޸�ʧ�ܡ�\n"));
		}
	}
}



/*
���ڳ���
*/
INT_PTR CALLBACK _ProcDlgMain(HWND hWnd, UINT wMsg, WPARAM wParam, LPARAM lParam)
{
	switch (wMsg)
	{
	case WM_CLOSE:
		EndDialog(hWnd, 0);
		break;

	case WM_INITDIALOG:			//��ʼ��
		_Init(hWnd);
		break;

	case WM_COMMAND:			//�˵�
		switch (LOWORD(wParam))
		{
		case IDM_EXIT:			//�˳�
			EndDialog(hWnd, 0);
			break;

		case IDM_OPEN:			//���ļ�
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