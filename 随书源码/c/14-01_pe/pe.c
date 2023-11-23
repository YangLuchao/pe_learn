//debug�汾�ĳ����ڱ���ʱĬ�Ͽ������������ӣ��������ļ�ƫ��Ϊ0�Ľڣ�
//��˱���ʱ��Ҫ���������ӹرգ���Ȼ�ô˳���鿴�����
//
//

#include <Windows.h>
#include<Richedit.h>
#include "resource.h"


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
��λ��ָ�������Ľڱ���
_lpHeader ͷ������ַ
_index ��ʾ�ڼ����ڱ����0��ʼ
_dwFlag1
Ϊ0��ʾ_lpHeader��PEӳ��ͷ
Ϊ1��ʾ_lpHeader���ڴ�ӳ���ļ�ͷ
_dwFlag2
Ϊ0��ʾ����RVA+ģ�����ַ
Ϊ1��ʾ����FOA+�ļ�����ַ
Ϊ2��ʾ����RVA
Ϊ3��ʾ����FOA
����eax=ָ�������Ľڱ������ڵ�ַ
*/
DWORD _rSection(PVOID _lpHeader, DWORD _index, DWORD _dwFlag1, DWORD _dwFlag2)
{
	PIMAGE_NT_HEADERS pImageNtHeaders;
	PIMAGE_SECTION_HEADER pImageSectionHeader;
	DWORD dwImageBase;


	pImageNtHeaders = (PIMAGE_NT_HEADERS)((DWORD)_lpHeader + ((PIMAGE_DOS_HEADER)_lpHeader)->e_lfanew);
	dwImageBase = pImageNtHeaders->OptionalHeader.ImageBase;//����Ľ���װ�ص�ַ
	pImageSectionHeader = (PIMAGE_SECTION_HEADER)(pImageNtHeaders + 1);//ָ��ڱ�ʼ

	if (_dwFlag1 == 0)//_lpHeader��PEӳ��ͷ
	{
		if (_dwFlag2 == 0)//RVA + ģ�����ַ
		{
			return (DWORD)(pImageSectionHeader + _index);
		}
		else
		{
			return (DWORD)(pImageSectionHeader + _index) - (DWORD)_lpHeader;
		}
	}
	else//_lpHeader���ڴ�ӳ���ļ�ͷ
	{
		if (_dwFlag2 == 0)//RVA + ģ�����ַ
		{
			return (DWORD)(pImageSectionHeader + _index) - (DWORD)_lpHeader + dwImageBase;
		}
		else if (_dwFlag2 == 1) //FOA + �ļ�����ַ
		{
			return (DWORD)(pImageSectionHeader + _index);
		}
		else
		{
			return (DWORD)(pImageSectionHeader + _index) - (DWORD)_lpHeader;
		}
	}
}


/*
��PE�ļ�������
*/
void  _openFile(HWND hWinMain)
{
	OPENFILENAME stOF;// ���ļ��ṹ
	HANDLE hFile, hMapFile;// �ļ�������ļ�ӳ����
	DWORD dwFileSize;
	LPVOID lpMemory;		//�ڴ�ӳ���ļ����ڴ����ʼλ��
	PIMAGE_NT_HEADERS pImageNtHeaders;// NTͷ�ṹָ��
	DWORD dwSections;// �ڱ����
	DWORD dwTemp;
	DWORD dwOff;
	DWORD dwFOA;
	PIMAGE_SECTION_HEADER pImageSectionHeader;// �ڱ�ͷ
	DWORD dwNumber;
	DWORD dwAvailable;
	DWORD dwTotalSize;




	TCHAR szFileName[MAX_PATH] = { 0 };	//Ҫ�򿪵��ļ�·����������
	TCHAR szBuffer[1024];
	TCHAR szSection[10];



	TCHAR szExtPe[] = TEXT("PE File\0*.exe;*.dll;*.scr;*.fon;*.drv\0All Files(*.*)\0*.*\0\0");
	TCHAR szTitle[] = TEXT("����        FOA        �ܴ�С            ���ÿռ�       ���ÿռ�FOA\n"
						   "-----------------------------------------------------------------------\n");	
	TCHAR szOut[] = TEXT("%-8s    %08x   %4d(%4xh)      %4d(%4xh)     %08x\n");
	TCHAR szHeader[] = TEXT(".head");

	RtlZeroMemory(&stOF, sizeof(stOF));
	stOF.lStructSize = sizeof(stOF);
	stOF.hwndOwner = hWinMain;
	stOF.lpstrFilter = szExtPe;
	stOF.lpstrFile = szFileName;
	stOF.nMaxFile = MAX_PATH;
	stOF.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST;
	if (GetOpenFileName(&stOF))//���û�ѡ��򿪵��ļ�
	{
		// �����ļ�
		if ((hFile = CreateFile(szFileName, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE,
			NULL, OPEN_EXISTING, FILE_ATTRIBUTE_ARCHIVE, NULL)) != INVALID_HANDLE_VALUE)
		{
			if (dwFileSize = GetFileSize(hFile, NULL))//��ȡ�ļ���С
			{
				if (hMapFile = CreateFileMapping(hFile, NULL, PAGE_READONLY, 0, 0, NULL))//�ڴ�ӳ���ļ�
				{
					if (lpMemory = MapViewOfFile(hMapFile, FILE_MAP_READ, 0, 0, 0))//����ļ����ڴ��ӳ����ʼλ��
					{
						if (((PIMAGE_DOS_HEADER)lpMemory)->e_magic == IMAGE_DOS_SIGNATURE)//���PE�ļ��Ƿ���Ч
						{
							// NTͷ
							pImageNtHeaders = (PIMAGE_NT_HEADERS)((DWORD)lpMemory + ((PIMAGE_DOS_HEADER)lpMemory)->e_lfanew);
							// �ж��Ƿ���PE����
							if (pImageNtHeaders->Signature == IMAGE_NT_SIGNATURE)
							{
								// �ڱ����
								dwSections = pImageNtHeaders->FileHeader.NumberOfSections;

								wsprintf(szBuffer, TEXT("\n�򿪵��ļ���%s\n\n"), szFileName);
								_appendInfo(szBuffer);
								_appendInfo(szTitle);



								//��ȡ���ڵ�����
								dwTemp = dwSections;
								while (--dwTemp != 0xFFFFFFFF)
								{
									if (dwSections - 1 == dwTemp)//��ʾ���һ����
									{
										dwOff = dwFileSize;//�ļ���С
									}
									else
									{
										dwOff = dwFOA;//��һ���ڵ���ʼ
									}

									pImageSectionHeader = (PIMAGE_SECTION_HEADER)((DWORD)lpMemory + _rSection(lpMemory, dwTemp, 1, 3));
									dwFOA = pImageSectionHeader->PointerToRawData;

									//��ȡ�ڵ�����
									RtlZeroMemory(szSection, 10);
									strncpy_s(szSection, 8, pImageSectionHeader->Name, 10);
									
									dwNumber = 0;
									while (!((PTCHAR)lpMemory)[dwOff - ++dwNumber]);
									--dwNumber;

									//��������ߴ�
									dwTotalSize = dwOff - dwFOA;
									dwAvailable = dwOff - dwNumber;

									wsprintf(szBuffer, szOut, szSection, dwFOA, dwTotalSize,
										dwTotalSize, dwNumber, dwNumber, dwAvailable);
									_appendInfo(szBuffer);
								}

								//��ȡ�ļ�ͷ�����ÿռ�
								//��λ����һ���ڱ���
								pImageSectionHeader = (PIMAGE_SECTION_HEADER)((DWORD)lpMemory + _rSection(lpMemory, 0, 1, 3));
								dwTotalSize = pImageSectionHeader->PointerToRawData;
								dwNumber = 0;
								while (!((PTCHAR)lpMemory)[dwTotalSize - ++dwNumber]);
								--dwNumber;
								dwFOA = 0;
								dwAvailable = dwTotalSize - dwNumber;
								wsprintf(szBuffer, szOut, szHeader, dwFOA, dwTotalSize,
									dwTotalSize, dwNumber, dwNumber, dwAvailable);
								_appendInfo(szBuffer);


							}
							else
							{
								goto _ErrFormat;
							}
						}
						else
						{
_ErrFormat:
							MessageBox(hWinMain, TEXT("����ļ�����PE��ʽ���ļ�!"), NULL, MB_OK);
						}
						UnmapViewOfFile(lpMemory);//ж�ؾ���
					}
					CloseHandle(hMapFile);// �ر��ļ�ӳ����
				}
			}
			CloseHandle(hFile);// �ر��ļ����
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