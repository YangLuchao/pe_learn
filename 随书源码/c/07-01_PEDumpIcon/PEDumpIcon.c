#include <Windows.h>
#include<Richedit.h>
#include "resource.h"


#pragma pack(1)

//文件中的ICO头部
typedef struct
{
	TBYTE bWidth;			//宽度
	TBYTE bHeight;			//高度
	TBYTE bColorCount;		//颜色数
	TBYTE bReserved;		//保留字，必须为0
	WORD  wPlanes;			//调色板
	WORD  wBitCount;		//每个像素的位数
	DWORD dwBytesInRes ;	//资源长度
	DWORD dwImageOffset;	//资源在文件偏移
}ICON_DIR_ENTRY, *PICON_DIR_ENTRY;

//PE中ICO头部
typedef struct
{
	TBYTE bWidth;			//宽度
	TBYTE bHeight;			//高度
	TBYTE bColorCount;		//颜色数
	TBYTE bReserved;		//保留字，必须为0
	WORD  wPlanes;			//调色板
	WORD  wBitCount;		//每个像素的位数
	DWORD dwBytesInRes;		//资源长度
	WORD  nID;	//图标索引
}PE_ICON_DIR_ENTRY, *PPE_ICON_DIR_ENTRY;





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
将内存偏移量RVA转换为文件偏移
lp_FileHead为文件头的起始地址
_dwRVA为给定的RVA地址
*/
DWORD  _RVAToOffset(PTCHAR _lpFileHead, DWORD _dwRVA)
{
	PIMAGE_NT_HEADERS pImageNtHeaders;
	PIMAGE_SECTION_HEADER pImageSectionHeader;
	WORD dNumberOfSections;


	pImageNtHeaders = (PIMAGE_NT_HEADERS)(_lpFileHead + ((PIMAGE_DOS_HEADER)_lpFileHead)->e_lfanew);
	pImageSectionHeader = (PIMAGE_SECTION_HEADER)(pImageNtHeaders + 1);
	dNumberOfSections = pImageNtHeaders->FileHeader.NumberOfSections;

	//遍历节表
	while (dNumberOfSections--)
	{
		if (_dwRVA >= pImageSectionHeader->VirtualAddress &&
			_dwRVA < pImageSectionHeader->VirtualAddress + pImageSectionHeader->SizeOfRawData)//计算该节结束RVA，不用Misc的主要原因是有些段的Misc值是错误的！
		{
			return _dwRVA - pImageSectionHeader->VirtualAddress + pImageSectionHeader->PointerToRawData;
		}
		++pImageSectionHeader;
	}
	return -1;
}




/*
将图标数据写入文件

参数：_lpFile 文件内存起始地址
参数: _lpRes 资源表起始地址
参数: _hFile为文件句柄
参数：_nubmer为图标顺号
*/
 
DWORD _getFinnalData(PTCHAR _lpFile, PTCHAR _lpRes, HANDLE _hFile, DWORD _number)
{
	DWORD dwICO = 0;
	PIMAGE_RESOURCE_DIRECTORY pResourceDirectory;
	DWORD dwNumber;
	PIMAGE_RESOURCE_DIRECTORY_ENTRY pResourceDirectoryEntry;
	DWORD dwOffsetToData;
	DWORD dwName;
	DWORD dwTemp1;
	DWORD dwTemp2;
	DWORD dwTemp3;
	PIMAGE_RESOURCE_DATA_ENTRY pImageResourceDataEntry;
	PTCHAR lpMem;
	DWORD dwTemp;


	TCHAR szBuffer[1024];
	TCHAR szLevel31[] = TEXT("  >> 图标%4d所在文件位置：0x%08x  资源长度：%d\n");


	pResourceDirectory = (PIMAGE_RESOURCE_DIRECTORY)_lpRes;//指向第一级目录表
	dwNumber = pResourceDirectory->NumberOfIdEntries + pResourceDirectory->NumberOfNamedEntries;//计算目录项的个数
	pResourceDirectoryEntry = (PIMAGE_RESOURCE_DIRECTORY_ENTRY)(pResourceDirectory + 1);//跳过目录头定位到目录项


	while (dwNumber > 0)
	{
		dwOffsetToData = pResourceDirectoryEntry->OffsetToData;//查看IMAGE_RESOURCE_DIRECTORY_ENTRY.OffsetToData
		if (dwOffsetToData & 0x80000000)//如果最高位为1
		{
			dwOffsetToData = (dwOffsetToData & 0x7fffffff) + (DWORD)_lpRes;//二级子目录
			dwName = pResourceDirectoryEntry->Name;
			if (!(dwName & 0x80000000))//如果是按名称定义的资源类型,跳过
			{
				//第一层，dwName指向了资源类别
				if (dwName == 0x3)// 判断编号是否为图标
				{
					//移动到第二级目录
					pResourceDirectory = (PIMAGE_RESOURCE_DIRECTORY)dwOffsetToData;
					//计算目录项的个数
					dwNumber = pResourceDirectory->NumberOfIdEntries + pResourceDirectory->NumberOfNamedEntries;
					//跳过第二级目录头定位到第二级目录项
					pResourceDirectoryEntry = (PIMAGE_RESOURCE_DIRECTORY_ENTRY)(pResourceDirectory + 1);
					
					while (dwNumber > 0)
					{
						
						dwTemp1 = pResourceDirectoryEntry->Name;

						//判断序号是否和指定的一致
						if (dwTemp1 == _number)//如果一致，则继续查找数据
						{	
							dwOffsetToData = pResourceDirectoryEntry->OffsetToData;
							if (dwOffsetToData & 0x80000000)//最高位为1
							{
								dwOffsetToData = (dwOffsetToData & 0x7fffffff) + (DWORD)_lpRes;//第三级

								//移动到第三级目录，假设目录项数量都为1

								//地址指向数据项
								pImageResourceDataEntry = (PIMAGE_RESOURCE_DATA_ENTRY)
									(((PIMAGE_RESOURCE_DIRECTORY_ENTRY)
									(((PIMAGE_RESOURCE_DIRECTORY)
									dwOffsetToData) + 1))->OffsetToData + (DWORD)_lpRes);
								dwTemp2 = _RVAToOffset(_lpFile, pImageResourceDataEntry->OffsetToData);
								dwTemp3 = pImageResourceDataEntry->Size;
								wsprintf(szBuffer, szLevel31, dwTemp1, dwTemp2, dwTemp3);
								_appendInfo(szBuffer);


								lpMem = _lpFile + dwTemp2;
								//将@dwTemp2开始的@dwTemp3个字节写入文件
								WriteFile(_hFile, lpMem, dwTemp3, &dwTemp, NULL);
								_appendInfo(TEXT("  >> 完成写入。\n"));
								return dwTemp;
							}					
						}
						++pResourceDirectoryEntry;
						--dwNumber;
					}
					break;
				}
			}
		}
		++pResourceDirectoryEntry;
		--dwNumber;
	}
	return 0;
}




/*
通过PE ICO头获取ICO数据
参数1：文件开始
参数2：资源表开始
参数3：编号（由此构造磁盘文件名g12.ico）
参数4：PE ICO头开始
参数5：PE ICO头大小
*/
void _getIcoData(PTCHAR _lpFile, PTCHAR _lpRes, DWORD _number, DWORD _off, DWORD _size)
{
	HANDLE hFile;
	DWORD dwTemp;
	PVOID lpMemory;
	WORD dwCount;
	DWORD dwForward;
	ICON_DIR_ENTRY stIconDirEntry;
	PPE_ICON_DIR_ENTRY pPeIconDirEntry;
	DWORD dwIcoDataSize;
	DWORD dwTemp1;


	TCHAR szFileName1[MAX_PATH];
	TCHAR szBuffer[1024];

	TCHAR szOut11[] = TEXT("g%d.ico");
	TCHAR szFile[] = TEXT("  >>新建文件%s\n");
	TCHAR szOut13[] = TEXT("  >>图标组%4d中共有图标：%d个。\n");

	wsprintf(szFileName1, szOut11, _number);
	wsprintf(szBuffer, szFile, szFileName1);
	_appendInfo(szBuffer);

	//创建写入文件
	hFile = CreateFile(szFileName1, GENERIC_WRITE, FILE_SHARE_READ, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
	
	//定位文件指针
	lpMemory = (PVOID)(_lpFile + _off);
	//写入6个字节文件头
	WriteFile(hFile, lpMemory, 6, &dwTemp, NULL);

	//求出图标组包含图标的个数
	dwCount = *(PWORD)((PTCHAR)lpMemory + 4);
	wsprintf(szBuffer, szOut13, _number, dwCount);
	_appendInfo(szBuffer);

	//求第一个图标数据在文件中的偏移
	dwForward = _size + dwCount * 2;//每一个记录多2个字节

	//定位到ICO图标项起始

	pPeIconDirEntry = (PPE_ICON_DIR_ENTRY)((PTCHAR)lpMemory + 6);
	dwIcoDataSize = 0;
	dwTemp1 = dwCount;
	while (dwTemp1-- > 0)
	{
		//将PE中的结构体复制
		stIconDirEntry = *(PICON_DIR_ENTRY)pPeIconDirEntry;

		//修正图标数据在文件偏移。
		//第一个图标的该值是文件ICO头大小
		//以后的图标的该值是上一个加上数据长度
		dwForward += dwIcoDataSize;
		stIconDirEntry.dwImageOffset = dwForward;

		WriteFile(hFile, &stIconDirEntry, sizeof(ICON_DIR_ENTRY), &dwTemp, NULL);
		dwIcoDataSize = stIconDirEntry.dwBytesInRes;//为下一次计算地址做准备
		++pPeIconDirEntry;
	}
	//该循环结束，所有的头部信息已经完毕
	_appendInfo(TEXT("  >> 完成ICO头部信息\n"));


	//开始下一个循环，将所有图标数据写入文件
	pPeIconDirEntry = (PPE_ICON_DIR_ENTRY)((PTCHAR)lpMemory + 6);
	dwTemp1 = dwCount;
	while (dwTemp1-- > 0)
	{
		//写入文件图标数据
		//返回图标数据大小
		_getFinnalData(_lpFile, _lpRes, hFile, pPeIconDirEntry->nID);
		++pPeIconDirEntry;
	}
	//该循环结束，所有的信息已经完毕
	CloseHandle(hFile);
}







/*
遍历资源表项的图标组资源
_lpFile：文件地址
_lpRes：资源表地址
*/
void _processRes(PTCHAR _lpFile, PTCHAR _lpRes)
{
	PIMAGE_RESOURCE_DIRECTORY pResourceDirectory;
	DWORD dwNumber;
	PIMAGE_RESOURCE_DIRECTORY_ENTRY pResourceDirectoryEntry;
	DWORD dwOffsetToData;
	DWORD dwName;
	DWORD dwICO = 0;
	DWORD dwTemp1, dwTemp2, dwTemp3;
	TCHAR szBuffer[1024];
	PIMAGE_RESOURCE_DATA_ENTRY pImageResourceDataEntry;


	TCHAR  szOut10[] = TEXT("资源表中有图标组%d个。\n"
							"----------------------------------------------------------------\n\n");
	TCHAR szLevel3[] = TEXT("图标组%4d所在文件位置：0x%08x  资源长度：%d\n");
	TCHAR szNoIconArray[] = TEXT("资源表中没有发现图标组！\n");



	pResourceDirectory = (PIMAGE_RESOURCE_DIRECTORY)_lpRes;//指向目录表
	dwNumber = pResourceDirectory->NumberOfIdEntries + pResourceDirectory->NumberOfNamedEntries;//计算目录项的个数
	pResourceDirectoryEntry = (PIMAGE_RESOURCE_DIRECTORY_ENTRY)(pResourceDirectory + 1);//跳过目录头定位到目录项


	while (dwNumber > 0)
	{
		dwOffsetToData = pResourceDirectoryEntry->OffsetToData;//查看IMAGE_RESOURCE_DIRECTORY_ENTRY.OffsetToData
		if (dwOffsetToData & 0x80000000)//如果最高位为1
		{
			dwOffsetToData = (dwOffsetToData & 0x7fffffff) + (DWORD)_lpRes;//二级子目录
			dwName = pResourceDirectoryEntry->Name;
			if (!(dwName & 0x80000000))//如果是按名称定义的资源类型,跳过
			{
				//第一层，dwName指向了资源类别
				if (dwName == 0xe)// 判断编号是否为图标组
				{
					//移动到第二级目录
					pResourceDirectory = (PIMAGE_RESOURCE_DIRECTORY)dwOffsetToData;
					//计算目录项的个数
					dwNumber = pResourceDirectory->NumberOfIdEntries + pResourceDirectory->NumberOfNamedEntries;//计算目录项的个数
					dwICO = dwNumber;
					
					wsprintf(szBuffer, szOut10, dwICO);
					_appendInfo(szBuffer);

					pResourceDirectoryEntry = (PIMAGE_RESOURCE_DIRECTORY_ENTRY)(pResourceDirectory + 1);//跳过第二级目录头定位到第二级目录项
					dwTemp1 = 0;
					while (dwNumber > 0)
					{
						//直接访问到数据，获取数据在文件的偏移及大小
						++dwTemp1;
						dwOffsetToData = pResourceDirectoryEntry->OffsetToData;
						if (dwOffsetToData & 0x80000000)//最高位为1
						{
							dwOffsetToData = (dwOffsetToData & 0x7fffffff) + (DWORD)_lpRes;//第三级
						
							//移动到第三级目录，假设目录项数量都为1
							
							//地址指向数据项
							pImageResourceDataEntry = (PIMAGE_RESOURCE_DATA_ENTRY)
								(((PIMAGE_RESOURCE_DIRECTORY_ENTRY)
								(((PIMAGE_RESOURCE_DIRECTORY)
								dwOffsetToData) + 1))->OffsetToData + (DWORD)_lpRes);
							dwTemp2 = _RVAToOffset(_lpFile, pImageResourceDataEntry->OffsetToData);
							dwTemp3 = pImageResourceDataEntry->Size;
							wsprintf(szBuffer, szLevel3, dwTemp1, dwTemp2, dwTemp3);
							_appendInfo(szBuffer);

							//处理单个ICO文件
							//参数1：文件开始
							//参数2：资源表开始
							//参数3：PE ICO头开始
							//参数4：编号
							//参数5：PE ICO头大小
							_getIcoData(_lpFile, _lpRes, dwTemp1, dwTemp2, dwTemp3);
						}
						++pResourceDirectoryEntry;
						--dwNumber;
					}
					break;
				}
			}
		}
		++pResourceDirectoryEntry;
		--dwNumber;
	}

	if (dwICO == 0)
	{
		_appendInfo(szNoIconArray);
	}
}



/*
获取PE文件的资源信息
*/
void _getResource(PTCHAR _lpFile, PTCHAR  _lpPeHead)
{
	PIMAGE_NT_HEADERS pNtHeaders;
	DWORD dwVirtualAddress;
	PTCHAR lpRes;

	pNtHeaders = (PIMAGE_NT_HEADERS)_lpPeHead;
	if (dwVirtualAddress = (pNtHeaders->OptionalHeader.DataDirectory)[2].VirtualAddress)
	{
		//求资源表在文件的偏移
		lpRes = _lpFile + _RVAToOffset(_lpFile, dwVirtualAddress);

		//传入的两个参数分别表示
		//1、文件头位置
		//2、资源表位置
		_processRes(_lpFile, lpRes);
	}
	else
	{
		_appendInfo(TEXT("\n未发现该文件有资源表\n"));
		return;
	}
}




/*
打开PE文件并处理
*/
void _openFile(HWND hWinMain)
{
	OPENFILENAME stOF;
	HANDLE hFile, hMapFile;
	DWORD dwFileSize;		//文件大小
	PTCHAR lpMemory;		//内存映像文件在内存的起始位置
	PTCHAR lpMem;

	TCHAR szBuffer[200];
	TCHAR szFileName[MAX_PATH] = { 0 };	//要打开的文件路径及名称名
	TCHAR szExtPe[] = TEXT("PE Files\0*.exe;*.dll;*.scr;*.fon;*.drv\0All Files(*.*)\0*.*\0\0");
	TCHAR szOut1[] = TEXT("-----------------------------------------------------------------\n"
						  "待处理的PE文件：%s");


	RtlZeroMemory(&stOF, sizeof(stOF));
	stOF.lStructSize = sizeof(stOF);
	stOF.hwndOwner = hWinMain;
	stOF.lpstrFilter = szExtPe;
	stOF.lpstrFile = szFileName;
	stOF.nMaxFile = MAX_PATH;
	stOF.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST;




	if (GetOpenFileName(&stOF))		//让用户选择打开的文件
	{
		hFile = CreateFile(szFileName, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE,
			NULL, OPEN_EXISTING, FILE_ATTRIBUTE_ARCHIVE, NULL);
		if (hFile != INVALID_HANDLE_VALUE)
		{
			dwFileSize = GetFileSize(hFile, NULL);//获取文件大小
			if (dwFileSize)
			{
				hMapFile = CreateFileMapping(hFile, NULL, PAGE_READONLY, 0, 0, NULL);//内存映射文件
				if (hMapFile)
				{
					lpMemory = (PTCHAR)MapViewOfFile(hMapFile, FILE_MAP_READ, 0, 0, 0);//获得文件在内存的映象起始位置
					if (lpMemory)
					{
						if (((PIMAGE_DOS_HEADER)lpMemory)->e_magic == IMAGE_DOS_SIGNATURE)//判断是否有MZ字样
						{
							lpMem = lpMemory + ((PIMAGE_DOS_HEADER)lpMemory)->e_lfanew;
							if (((PIMAGE_NT_HEADERS)lpMem)->Signature == IMAGE_NT_SIGNATURE)//判断是否有PE字样
							{
								//到此为止，该文件的验证已经完成。为PE结构文件
								
								wsprintf(szBuffer, szOut1, szFileName);
								_appendInfo(szBuffer);

								//显示资源表信息
								_getResource(lpMemory, lpMem);
							}
							else
							{
								MessageBox(hWinMain, TEXT("这个文件不是PE格式的文件!"), NULL, MB_OK);
							}
						}
						else
						{
							MessageBox(hWinMain, TEXT("这个文件不是PE格式的文件!"), NULL, MB_OK);
						}
						UnmapViewOfFile(lpMemory);
					}
					CloseHandle(hMapFile);
				}
			}
			CloseHandle(hFile);
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