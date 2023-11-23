//debug版本的程序在编译时默认开启了增量链接，会生成文件偏移为0的节，
//因此编译时需要把增量链接关闭，不然用此程序查看会出错
//
//

#include <Windows.h>
#include<Richedit.h>
#include "resource.h"


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
定位到指定索引的节表项
_lpHeader 头部基地址
_index 表示第几个节表项，从0开始
_dwFlag1
为0表示_lpHeader是PE映像头
为1表示_lpHeader是内存映射文件头
_dwFlag2
为0表示返回RVA+模块基地址
为1表示返回FOA+文件基地址
为2表示返回RVA
为3表示返回FOA
返回eax=指定索引的节表项所在地址
*/
DWORD _rSection(PVOID _lpHeader, DWORD _index, DWORD _dwFlag1, DWORD _dwFlag2)
{
	PIMAGE_NT_HEADERS pImageNtHeaders;
	PIMAGE_SECTION_HEADER pImageSectionHeader;
	DWORD dwImageBase;


	pImageNtHeaders = (PIMAGE_NT_HEADERS)((DWORD)_lpHeader + ((PIMAGE_DOS_HEADER)_lpHeader)->e_lfanew);
	dwImageBase = pImageNtHeaders->OptionalHeader.ImageBase;//程序的建议装载地址
	pImageSectionHeader = (PIMAGE_SECTION_HEADER)(pImageNtHeaders + 1);//指向节表开始

	if (_dwFlag1 == 0)//_lpHeader是PE映像头
	{
		if (_dwFlag2 == 0)//RVA + 模块基地址
		{
			return (DWORD)(pImageSectionHeader + _index);
		}
		else
		{
			return (DWORD)(pImageSectionHeader + _index) - (DWORD)_lpHeader;
		}
	}
	else//_lpHeader是内存映射文件头
	{
		if (_dwFlag2 == 0)//RVA + 模块基地址
		{
			return (DWORD)(pImageSectionHeader + _index) - (DWORD)_lpHeader + dwImageBase;
		}
		else if (_dwFlag2 == 1) //FOA + 文件基地址
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
打开PE文件并处理
*/
void  _openFile(HWND hWinMain)
{
	OPENFILENAME stOF;// 打开文件结构
	HANDLE hFile, hMapFile;// 文件句柄，文件映射句柄
	DWORD dwFileSize;
	LPVOID lpMemory;		//内存映像文件在内存的起始位置
	PIMAGE_NT_HEADERS pImageNtHeaders;// NT头结构指针
	DWORD dwSections;// 节表个数
	DWORD dwTemp;
	DWORD dwOff;
	DWORD dwFOA;
	PIMAGE_SECTION_HEADER pImageSectionHeader;// 节表头
	DWORD dwNumber;
	DWORD dwAvailable;
	DWORD dwTotalSize;




	TCHAR szFileName[MAX_PATH] = { 0 };	//要打开的文件路径及名称名
	TCHAR szBuffer[1024];
	TCHAR szSection[10];



	TCHAR szExtPe[] = TEXT("PE File\0*.exe;*.dll;*.scr;*.fon;*.drv\0All Files(*.*)\0*.*\0\0");
	TCHAR szTitle[] = TEXT("名称        FOA        总大小            可用空间       可用空间FOA\n"
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
	if (GetOpenFileName(&stOF))//让用户选择打开的文件
	{
		// 创建文件
		if ((hFile = CreateFile(szFileName, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE,
			NULL, OPEN_EXISTING, FILE_ATTRIBUTE_ARCHIVE, NULL)) != INVALID_HANDLE_VALUE)
		{
			if (dwFileSize = GetFileSize(hFile, NULL))//获取文件大小
			{
				if (hMapFile = CreateFileMapping(hFile, NULL, PAGE_READONLY, 0, 0, NULL))//内存映射文件
				{
					if (lpMemory = MapViewOfFile(hMapFile, FILE_MAP_READ, 0, 0, 0))//获得文件在内存的映象起始位置
					{
						if (((PIMAGE_DOS_HEADER)lpMemory)->e_magic == IMAGE_DOS_SIGNATURE)//检测PE文件是否有效
						{
							// NT头
							pImageNtHeaders = (PIMAGE_NT_HEADERS)((DWORD)lpMemory + ((PIMAGE_DOS_HEADER)lpMemory)->e_lfanew);
							// 判断是否有PE字样
							if (pImageNtHeaders->Signature == IMAGE_NT_SIGNATURE)
							{
								// 节表个数
								dwSections = pImageNtHeaders->FileHeader.NumberOfSections;

								wsprintf(szBuffer, TEXT("\n打开的文件：%s\n\n"), szFileName);
								_appendInfo(szBuffer);
								_appendInfo(szTitle);



								//获取各节的内容
								dwTemp = dwSections;
								while (--dwTemp != 0xFFFFFFFF)
								{
									if (dwSections - 1 == dwTemp)//表示最后一个节
									{
										dwOff = dwFileSize;//文件大小
									}
									else
									{
										dwOff = dwFOA;//上一个节的起始
									}

									pImageSectionHeader = (PIMAGE_SECTION_HEADER)((DWORD)lpMemory + _rSection(lpMemory, dwTemp, 1, 3));
									dwFOA = pImageSectionHeader->PointerToRawData;

									//获取节的名字
									RtlZeroMemory(szSection, 10);
									strncpy_s(szSection, 8, pImageSectionHeader->Name, 10);
									
									dwNumber = 0;
									while (!((PTCHAR)lpMemory)[dwOff - ++dwNumber]);
									--dwNumber;

									//计算节区尺寸
									dwTotalSize = dwOff - dwFOA;
									dwAvailable = dwOff - dwNumber;

									wsprintf(szBuffer, szOut, szSection, dwFOA, dwTotalSize,
										dwTotalSize, dwNumber, dwNumber, dwAvailable);
									_appendInfo(szBuffer);
								}

								//获取文件头部可用空间
								//定位到第一个节表项
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
							MessageBox(hWinMain, TEXT("这个文件不是PE格式的文件!"), NULL, MB_OK);
						}
						UnmapViewOfFile(lpMemory);//卸载镜像
					}
					CloseHandle(hMapFile);// 关闭文件映射句柄
				}
			}
			CloseHandle(hFile);// 关闭文件句柄
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