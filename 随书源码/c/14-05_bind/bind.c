//还未完成，，，




//将patch.ext补丁程序插入到指定exe文件中首先运行
//主要演示如何使用程序修改PE文件格式，从而完成想
//要实现的功能
//

#include <Windows.h>
#include<Richedit.h>
#include<string.h>
#include "resource.h"


HINSTANCE hInstance;
HWND hWinEdit;


TCHAR szBuffer[1024];

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
取数据段大小
数据段定位方法：
只要节的标识第6,30,31位为1，则表示符合要求
_lpHeader指向内存中PE文件的起始
返回值在eax中
*/
DWORD getDataSize(LPVOID _lpHeader)
{
	PIMAGE_DOS_HEADER pImageDosHeader;
	PIMAGE_NT_HEADERS pImageNtHeaders;
	DWORD dwSectionSize;
	PIMAGE_SECTION_HEADER pImageSectionHeader;




	pImageDosHeader = (PIMAGE_DOS_HEADER)_lpHeader;
	pImageNtHeaders = (PIMAGE_NT_HEADERS)((DWORD)_lpHeader + pImageDosHeader->e_lfanew);
	dwSectionSize = pImageNtHeaders->FileHeader.NumberOfSections;
	pImageSectionHeader = (PIMAGE_SECTION_HEADER)(pImageNtHeaders + 1);

	while (dwSectionSize--)
	{
		if ((pImageSectionHeader->Characteristics & 0xc0000040) == 0xc0000040)
		{
			return pImageSectionHeader->Misc.VirtualSize;
		}
		++pImageSectionHeader;
	}

	return 0;
}



/*
取数据段在文件中的起始位置
数据段定位方法：
只要节的标识第6,30,31位为1，则表示符合要求
_lpHeader指向内存中PE文件的起始
返回值在eax中
*/
DWORD getDataStart(LPVOID _lpHeader)
{
	PIMAGE_DOS_HEADER pImageDosHeader;
	PIMAGE_NT_HEADERS pImageNtHeaders;
	DWORD dwSectionSize;
	PIMAGE_SECTION_HEADER pImageSectionHeader;




	pImageDosHeader = (PIMAGE_DOS_HEADER)_lpHeader;
	pImageNtHeaders = (PIMAGE_NT_HEADERS)((DWORD)_lpHeader + pImageDosHeader->e_lfanew);
	dwSectionSize = pImageNtHeaders->FileHeader.NumberOfSections;
	pImageSectionHeader = (PIMAGE_SECTION_HEADER)(pImageNtHeaders + 1);

	while (dwSectionSize--)
	{
		if ((pImageSectionHeader->Characteristics & 0xc0000040) == 0xc0000040)
		{
			return pImageSectionHeader->PointerToRawData;
		}
		++pImageSectionHeader;
	}

	return 0;
}



/*
取数据段在内存中的起始位置
数据段定位方法：
只要节的标识第6,30,31位为1，则表示符合要求
_lpHeader指向内存中PE文件的起始
返回值在eax中
*/
DWORD getDataStartInMem(LPVOID _lpHeader)
{
	PIMAGE_DOS_HEADER pImageDosHeader;
	PIMAGE_NT_HEADERS pImageNtHeaders;
	DWORD dwSectionSize;
	PIMAGE_SECTION_HEADER pImageSectionHeader;




	pImageDosHeader = (PIMAGE_DOS_HEADER)_lpHeader;
	pImageNtHeaders = (PIMAGE_NT_HEADERS)((DWORD)_lpHeader + pImageDosHeader->e_lfanew);
	dwSectionSize = pImageNtHeaders->FileHeader.NumberOfSections;
	pImageSectionHeader = (PIMAGE_SECTION_HEADER)(pImageNtHeaders + 1);

	while (dwSectionSize--)
	{
		if ((pImageSectionHeader->Characteristics & 0xc0000040) == 0xc0000040)
		{
			return pImageSectionHeader->VirtualAddress;
		}
		++pImageSectionHeader;
	}

	return 0;
}




/*
取数据段在文件中对齐后的大小
数据段定位方法：
只要节的标识第6,30,31位为1，则表示符合要求
_lpHeader指向内存中PE文件的起始
返回值在eax中
*/
DWORD getRawDataSize(LPVOID _lpHeader)
{
	PIMAGE_DOS_HEADER pImageDosHeader;
	PIMAGE_NT_HEADERS pImageNtHeaders;
	DWORD dwSectionSize;
	PIMAGE_SECTION_HEADER pImageSectionHeader;




	pImageDosHeader = (PIMAGE_DOS_HEADER)_lpHeader;
	pImageNtHeaders = (PIMAGE_NT_HEADERS)((DWORD)_lpHeader + pImageDosHeader->e_lfanew);
	dwSectionSize = pImageNtHeaders->FileHeader.NumberOfSections;
	pImageSectionHeader = (PIMAGE_SECTION_HEADER)(pImageNtHeaders + 1);

	while (dwSectionSize--)
	{
		if ((pImageSectionHeader->Characteristics & 0xc0000040) == 0xc0000040)
		{
			return pImageSectionHeader->SizeOfRawData;
		}
		++pImageSectionHeader;
	}

	return 0;
}



/*
获取基地址
*/
DWORD getImageBase(LPVOID _lpHeader)
{
	PIMAGE_DOS_HEADER pImageDosHeader;
	PIMAGE_NT_HEADERS pImageNtHeaders;


	pImageDosHeader = (PIMAGE_DOS_HEADER)_lpHeader;
	pImageNtHeaders = (PIMAGE_NT_HEADERS)((DWORD)_lpHeader + pImageDosHeader->e_lfanew);
	return pImageNtHeaders->OptionalHeader.ImageBase;
}



/*
将文件偏移转换为内存偏移量RVA
lp_FileHead为文件头的起始地址
_dwOff为给定的文件偏移地址
*/
DWORD _OffsetToRVA(LPVOID _lpFileHead, DWORD _dwOffset)
{
	PIMAGE_DOS_HEADER pImageDosHeader;
	PIMAGE_NT_HEADERS pImageNtHeaders;
	DWORD dwSectionSize;
	PIMAGE_SECTION_HEADER pImageSectionHeader;




	pImageDosHeader = (PIMAGE_DOS_HEADER)_lpFileHead;
	pImageNtHeaders = (PIMAGE_NT_HEADERS)((DWORD)_lpFileHead + pImageDosHeader->e_lfanew);
	dwSectionSize = pImageNtHeaders->FileHeader.NumberOfSections;
	pImageSectionHeader = (PIMAGE_SECTION_HEADER)(pImageNtHeaders + 1);

	while (dwSectionSize--)
	{
		if (pImageSectionHeader->PointerToRawData <= _dwOffset &&
			_dwOffset < pImageSectionHeader->PointerToRawData + pImageSectionHeader->SizeOfRawData)//计算该节结束RVA
		{
			return _dwOffset - pImageSectionHeader->PointerToRawData + pImageSectionHeader->VirtualAddress;
		}
		++pImageSectionHeader;
	}

	return 0;


}



/*
数据段
*/
void _dealData(LPVOID _lpFile1, LPVOID _lpFile2, LPVOID _lpDstMemory)
{
	DWORD dwPatchDataSize;
	DWORD dwPatchDataStart;
	DWORD dwPatchMemDataStart;
	DWORD dwDstDataSize;
	DWORD dwDstDataStart;
	DWORD dwDstRawDataSize;
	DWORD dwDstMemDataStart;
	DWORD dwNum;
	DWORD dwTemp1;
	DWORD dwDstImageBase;
	DWORD dwDataInMemStart;


	
	TCHAR szOut11[] = TEXT("补丁数据段的有效数据大小为：%08x\n");
	TCHAR szErr110[] = TEXT(">> 未找到可存放数据的节！\n");
	TCHAR szOut12[] = TEXT("补丁数据段在文件中的起始位置：%08x\n");
	TCHAR szOut2217[] = TEXT("补丁数据段在内存中的起始地址：%08x\n");
	TCHAR szOut13[] = TEXT("目标数据段的有效数据大小为：%08x\n");
	TCHAR szOut14[] = TEXT("目标数据段在文件中的起始位置：%08x\n");
	TCHAR szOut15[] = TEXT("目标数据段在文件中对齐后的大小：%08x\n");
	TCHAR szOut17[] = TEXT("目标数据段在内存中的起始地址：%08x\n");
	TCHAR szErr11[] = TEXT(">> 目标数据段空间不够，不足以容纳补丁程序的数据！\n");
	TCHAR szoutLine[] = TEXT("----------------------------------------------------------------------------------------\n");
	TCHAR szOut16[] = TEXT("目标文件的数据段中有空间，剩余空间大小为： %08x, 需要大小： %08x。\n"
		"补丁数据段在目标文件中存放的起始位置： %08x\n");
	TCHAR szOut19[] = TEXT("数据在新文件的内存中的起始地址：%08x\n");
	

	
	//到此为止，两个内存文件的指针已经获取到了。_lpFile1和_lpFile2分别指向两个文件头
	//下面是从这个文件头开始，找出各数据结构的字段值，进行比较。


	//获取补丁文件数据段的大小
	if (dwPatchDataSize = getDataSize(_lpFile1))
	{
		wsprintf(szBuffer, szOut11, dwPatchDataSize);
		_appendInfo(szBuffer);
	}
	else//未找到存放数据的节
	{
		_appendInfo(szErr110);
	}
		

	//获取补丁文件数据段在文件中的起始位置RVA
	dwPatchDataStart = getDataStart(_lpFile1);
	wsprintf(szBuffer, szOut12, dwPatchDataStart);
	_appendInfo(szBuffer);

	//获取补丁数据段在内存中的起始位置
	dwPatchMemDataStart = getDataStartInMem(_lpFile1);
	wsprintf(szBuffer, szOut2217, dwPatchMemDataStart);
	_appendInfo(szBuffer);



	//获取目标文件数据段的大小
	dwDstDataSize = getDataSize(_lpFile2);
	wsprintf(szBuffer, szOut13, dwDstDataSize);
	_appendInfo(szBuffer);

	//获取目标文件数据段在内存中的起始位置RVA
	dwDstDataStart = getDataStart(_lpFile2);
	wsprintf(szBuffer, szOut14, dwDstDataStart);
	_appendInfo(szBuffer);


	//获取目标文件数据段在文件中对齐后的大小
	dwDstRawDataSize = getRawDataSize(_lpFile2);
	wsprintf(szBuffer, szOut15, dwDstRawDataSize);
	_appendInfo(szBuffer);



	//获取目标数据段在内存中的起始位置
	dwDstMemDataStart = getDataStartInMem(_lpFile2);
	wsprintf(szBuffer, szOut17, dwDstMemDataStart);
	_appendInfo(szBuffer);

	//从本节的最后一个位置起往前查找连续的全0字符
	dwNum = 0;
	while (!((PTCHAR)_lpFile2)[dwDstDataStart + dwDstRawDataSize - ++dwNum]);
	--dwNum;

	if (dwNum >= dwPatchDataSize)//表示找到了连续可用的空间
	{
		dwTemp1 = dwDstDataStart + dwDstRawDataSize - dwPatchDataSize;
		wsprintf(szBuffer, szOut16, dwNum, dwPatchDataSize, dwTemp1);
		_appendInfo(szBuffer);

		//将补丁数据拷贝到目标文件指定位置处
		memcpy((PTCHAR)_lpDstMemory + dwTemp1, (PTCHAR)_lpFile1 + dwPatchDataStart, dwPatchDataSize);
		
		//记录新文件中数据段起始位置在内存中的地址
		
		dwDstImageBase = getImageBase(_lpFile2);
		dwDataInMemStart = dwDstImageBase + _OffsetToRVA(_lpFile2, dwTemp1);
		wsprintf(szBuffer, szOut19, dwDataInMemStart);
		_appendInfo(szBuffer);
	}
	else//数据段空间不够
	{
		_appendInfo(szErr11);
	}

	_appendInfo(szoutLine);
}


/*
获取RVA所在节的原始大小
*/
DWORD _getRVASectionSize(PVOID _lpFileHead, DWORD _dwRVA)
{
	PIMAGE_DOS_HEADER pImageDosHeader;
	PIMAGE_NT_HEADERS pImageNtHeaders;
	DWORD dwSectionSize;
	PIMAGE_SECTION_HEADER pImageSectionHeader;




	pImageDosHeader = (PIMAGE_DOS_HEADER)_lpFileHead;
	pImageNtHeaders = (PIMAGE_NT_HEADERS)((DWORD)_lpFileHead + pImageDosHeader->e_lfanew);
	dwSectionSize = pImageNtHeaders->FileHeader.NumberOfSections;
	pImageSectionHeader = (PIMAGE_SECTION_HEADER)(pImageNtHeaders + 1);

	//遍历节表
	while (dwSectionSize--)
	{
		if (pImageSectionHeader->VirtualAddress <= _dwRVA &&
			_dwRVA < pImageSectionHeader->VirtualAddress + pImageSectionHeader->SizeOfRawData)//计算该节结束RVA
		{
			return pImageSectionHeader->Misc.VirtualSize;
		}
		++pImageSectionHeader;
	}

	return 0;

}



/*
取导入表所在节的大小
*/
DWORD getImportSegSize(PVOID _lpHeader)
{
	PIMAGE_DOS_HEADER pImageDosHeader;
	PIMAGE_NT_HEADERS pImageNtHeaders;
	

	pImageDosHeader = (PIMAGE_DOS_HEADER)_lpHeader;
	pImageNtHeaders = (PIMAGE_NT_HEADERS)((DWORD)_lpHeader + pImageDosHeader->e_lfanew);

	return _getRVASectionSize(_lpHeader, pImageNtHeaders->OptionalHeader.DataDirectory[1].VirtualAddress);
}


/*
获取RVA所在节的文件起始地址
*/
DWORD _getRVASectionStart(PVOID _lpFileHead, DWORD _dwRVA)
{
	PIMAGE_DOS_HEADER pImageDosHeader;
	PIMAGE_NT_HEADERS pImageNtHeaders;
	DWORD dwSectionSize;
	PIMAGE_SECTION_HEADER pImageSectionHeader;




	pImageDosHeader = (PIMAGE_DOS_HEADER)_lpFileHead;
	pImageNtHeaders = (PIMAGE_NT_HEADERS)((DWORD)_lpFileHead + pImageDosHeader->e_lfanew);
	dwSectionSize = pImageNtHeaders->FileHeader.NumberOfSections;
	pImageSectionHeader = (PIMAGE_SECTION_HEADER)(pImageNtHeaders + 1);

	//遍历节表
	while (dwSectionSize--)
	{
		if (pImageSectionHeader->VirtualAddress <= _dwRVA &&
			_dwRVA < pImageSectionHeader->VirtualAddress + pImageSectionHeader->SizeOfRawData)//计算该节结束RVA
		{
			return pImageSectionHeader->PointerToRawData;
		}
		++pImageSectionHeader;
	}

	return 0;
}

/*
取补丁导入表所在节的大小
*/
DWORD getImportSegStart(PVOID _lpHeader)
{
	PIMAGE_DOS_HEADER pImageDosHeader;
	PIMAGE_NT_HEADERS pImageNtHeaders;


	pImageDosHeader = (PIMAGE_DOS_HEADER)_lpHeader;
	pImageNtHeaders = (PIMAGE_NT_HEADERS)((DWORD)_lpHeader + pImageDosHeader->e_lfanew);

	return _getRVASectionStart(_lpHeader, pImageNtHeaders->OptionalHeader.DataDirectory[1].VirtualAddress);
}


/*
将内存偏移量RVA转换为文件偏移
lp_FileHead为文件头的起始地址
_dwRVA为给定的RVA地址
*/
DWORD  _RVAToOffset(PVOID _lpFileHead, DWORD _dwRVA)
{
	PIMAGE_DOS_HEADER pImageDosHeader;
	PIMAGE_NT_HEADERS pImageNtHeaders;
	PIMAGE_SECTION_HEADER pImageSectionHeader;
	WORD dNumberOfSections;

	pImageDosHeader = (PIMAGE_DOS_HEADER)_lpFileHead;
	pImageNtHeaders = (PIMAGE_NT_HEADERS)((DWORD)_lpFileHead + pImageDosHeader->e_lfanew);
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
取导入表所在文件的偏移
_lpHeader指向内存中PE文件的起始
*/
DWORD getImportInFileStart(PVOID _lpHeader)
{
	PIMAGE_DOS_HEADER pImageDosHeader;
	PIMAGE_NT_HEADERS pImageNtHeaders;


	pImageDosHeader = (PIMAGE_DOS_HEADER)_lpHeader;
	pImageNtHeaders = (PIMAGE_NT_HEADERS)((DWORD)_lpHeader + pImageDosHeader->e_lfanew);

	return _RVAToOffset(_lpHeader, pImageNtHeaders->OptionalHeader.DataDirectory[1].VirtualAddress);
}


/*
获取RVA所在节在文件中对齐以后的大小
*/
DWORD  _getRVASectionRawSize(PVOID _lpFileHead, DWORD _dwRVA)
{
	PIMAGE_DOS_HEADER pImageDosHeader;
	PIMAGE_NT_HEADERS pImageNtHeaders;
	PIMAGE_SECTION_HEADER pImageSectionHeader;
	WORD dNumberOfSections;

	pImageDosHeader = (PIMAGE_DOS_HEADER)_lpFileHead;
	pImageNtHeaders = (PIMAGE_NT_HEADERS)((DWORD)_lpFileHead + pImageDosHeader->e_lfanew);
	pImageSectionHeader = (PIMAGE_SECTION_HEADER)(pImageNtHeaders + 1);
	dNumberOfSections = pImageNtHeaders->FileHeader.NumberOfSections;

	//遍历节表
	while (dNumberOfSections--)
	{
		if (_dwRVA >= pImageSectionHeader->VirtualAddress &&
			_dwRVA < pImageSectionHeader->VirtualAddress + pImageSectionHeader->SizeOfRawData)//计算该节结束RVA，不用Misc的主要原因是有些段的Misc值是错误的！
		{
			return pImageSectionHeader->SizeOfRawData;
		}
		++pImageSectionHeader;
	}
	return -1;
}



/*
取导入表所在节在文件中对齐以后的大小
*/
DWORD getImportSegRawSize(PVOID _lpHeader)
{
	PIMAGE_DOS_HEADER pImageDosHeader;
	PIMAGE_NT_HEADERS pImageNtHeaders;


	pImageDosHeader = (PIMAGE_DOS_HEADER)_lpHeader;
	pImageNtHeaders = (PIMAGE_NT_HEADERS)((DWORD)_lpHeader + pImageDosHeader->e_lfanew);

	return _getRVASectionRawSize(_lpHeader, pImageNtHeaders->OptionalHeader.DataDirectory[1].VirtualAddress);
}


/*
获取PE文件的导入表调用的函数个数
*/
void _getImportFunctions(PVOID _lpFile, PDWORD dwDlls,
	PDWORD dwFunctions, PDWORD _dwFunctions)
{
	PIMAGE_DOS_HEADER pImageDosHeader;
	PIMAGE_NT_HEADERS pImageNtHeaders;
	DWORD dwVirtualAddress;
	PIMAGE_IMPORT_DESCRIPTOR pImageImportDescriptor;
	DWORD dwFuns;
	PIMAGE_THUNK_DATA pImageThunkData;


	*dwFunctions = 0;
	*dwDlls = 0;

	pImageDosHeader = (PIMAGE_DOS_HEADER)_lpFile;
	pImageNtHeaders = (PIMAGE_NT_HEADERS)((DWORD)_lpFile + pImageDosHeader->e_lfanew);
	if (dwVirtualAddress = pImageNtHeaders->OptionalHeader.DataDirectory[1].VirtualAddress)
	{
		pImageImportDescriptor = (PIMAGE_IMPORT_DESCRIPTOR)((DWORD)_lpFile +
			_RVAToOffset(_lpFile, dwVirtualAddress));
	
		while (pImageImportDescriptor->OriginalFirstThunk || pImageImportDescriptor->TimeDateStamp ||
			pImageImportDescriptor->ForwarderChain || pImageImportDescriptor->Name ||
			pImageImportDescriptor->FirstThunk)
		{
			dwFuns = 0;

			if (pImageImportDescriptor->OriginalFirstThunk)
			{
				pImageThunkData = (PIMAGE_THUNK_DATA)((DWORD)_lpFile + 
					_RVAToOffset(_lpFile, pImageImportDescriptor->OriginalFirstThunk));
			}
			else
			{
				pImageThunkData = (PIMAGE_THUNK_DATA)((DWORD)_lpFile +
					_RVAToOffset(_lpFile, pImageImportDescriptor->FirstThunk));
			}

			while (pImageThunkData->u1.AddressOfData)
			{
				++dwFuns;
				++dwFunctions;
				++pImageThunkData;
			}
			_dwFunctions[*dwDlls++] = dwFuns;
			++pImageImportDescriptor;
		}
	}
	_dwFunctions[*dwDlls] = 0;
}


/*
将bufTemp2位置处_dwSize个字节转换为16进制的字符串
bufTemp1处为转换后的字符串
*/
void _Byte2Hex(PTCHAR bufTemp1, PTCHAR bufTemp2, DWORD _dwSize)
{
	DWORD dwSize = 0;
	TCHAR lpszHexArr[] = TEXT("0123456789ABCDEF");


	while (_dwSize--)
	{
		bufTemp1[dwSize++] = lpszHexArr[*bufTemp2 / 16];
		bufTemp1[dwSize++] = lpszHexArr[*bufTemp2 % 16];
		bufTemp1[dwSize++] = ' ';
		++bufTemp2;
	}
	bufTemp1[dwSize] = 0;
}



/*
获取PE文件的导入表调用的函数名
与动态链接库的字符串常量大小
*/
DWORD _getFunDllSize(PVOID _lpFile)
{
	PIMAGE_DOS_HEADER pImageDosHeader;
	PIMAGE_NT_HEADERS pImageNtHeaders;
	DWORD dwVirtualAddress;
	PIMAGE_IMPORT_DESCRIPTOR pImageImportDescriptor;
	DWORD dwSize = 0;
	PTCHAR lpName;
	PIMAGE_THUNK_DATA pImageThunkData;



	pImageDosHeader = (PIMAGE_DOS_HEADER)_lpFile;
	pImageNtHeaders = (PIMAGE_NT_HEADERS)((DWORD)_lpFile + pImageDosHeader->e_lfanew);
	if (dwVirtualAddress = pImageNtHeaders->OptionalHeader.DataDirectory[1].VirtualAddress)
	{
		pImageImportDescriptor = (PIMAGE_IMPORT_DESCRIPTOR)((DWORD)_lpFile +
			_RVAToOffset(_lpFile, dwVirtualAddress));


		while (pImageImportDescriptor->OriginalFirstThunk || pImageImportDescriptor->TimeDateStamp ||
			pImageImportDescriptor->ForwarderChain || pImageImportDescriptor->Name ||
			pImageImportDescriptor->FirstThunk)
		{
			lpName = (PTCHAR)((DWORD)_lpFile + _RVAToOffset(_lpFile, pImageImportDescriptor->Name));
			dwSize += lstrlen(lpName);
			dwSize += dwSize % 2 ? 1 : 2;

			if (pImageImportDescriptor->OriginalFirstThunk)
			{
				pImageThunkData = (PIMAGE_THUNK_DATA)((DWORD)_lpFile +
					_RVAToOffset(_lpFile, pImageImportDescriptor->OriginalFirstThunk));
			}
			else
			{
				pImageThunkData = (PIMAGE_THUNK_DATA)((DWORD)_lpFile +
					_RVAToOffset(_lpFile, pImageImportDescriptor->FirstThunk));
			}

			while (pImageThunkData->u1.AddressOfData)
			{
				
				if (!(pImageThunkData->u1.AddressOfData & IMAGE_ORDINAL_FLAG32))//按名称导入
				{
					dwSize += 2;//函数编号
					lpName = (PTCHAR)((DWORD)_lpFile +
						_RVAToOffset(_lpFile, pImageThunkData->u1.AddressOfData) + 2);
					dwSize += lstrlen(lpName);
					dwSize += dwSize % 2 ? 1 : 2;
				}
				++pImageThunkData;
			}
			++pImageImportDescriptor;
		}
	}

	return dwSize;
}




void pasteImport_fun(_lpFile, _lpFile1, _lpCurrent)
{


}



/*
补丁导入表常量数据引入及参数修正
_off为新文件中存放补丁导入表常量的位置
*/
void pasteImport(PVOID _lpFile, PVOID _lpFile1, PVOID lpDstMemory, PVOID lpNewImport,
	PVOID lpPImportInNewFile, DWORD _off, DWORD dwPatchDLLCount, DWORD dwNewImportSize)
{
	PIMAGE_DOS_HEADER pImageDosHeader;
	PIMAGE_NT_HEADERS pImageNtHeaders;
	DWORD dwVirtualAddress;
	PIMAGE_IMPORT_DESCRIPTOR pImageImportDescriptor;
	DWORD dwSize = 0;
	PTCHAR lpName;
	PIMAGE_THUNK_DATA pImageThunkData;
	DWORD _lpCurrent;
	DWORD dwTemp;
	DWORD dwTemp1;
	DWORD dwOldVirtualAddress;
	DWORD dwNewVirtualAddress;
	DWORD dwOldSize;




	TCHAR szCrLf[] = TEXT("\n");
	TCHAR szOut1911[] = TEXT("合并以后的导入表修正\n");
	TCHAR szOut1912[] = TEXT("   DLL名：%s      Name1原始值：%08x      Name1修正值：%08x\n");
	TCHAR szOut1917[] = TEXT("数据目录表中对导入表部分的修改\n");
	TCHAR szOut1918[] = TEXT("   导入表起始位置   原始值：%08x   修正值：%08x   \n");
	TCHAR szOut1919[] = TEXT("   导入表大小       原始值：%08x   修正值：%08x   \n");


	    

	pImageDosHeader = (PIMAGE_DOS_HEADER)_lpFile;
	pImageNtHeaders = (PIMAGE_NT_HEADERS)((DWORD)_lpFile + pImageDosHeader->e_lfanew);
	if (dwVirtualAddress = pImageNtHeaders->OptionalHeader.DataDirectory[1].VirtualAddress)
	{
		pImageImportDescriptor = (PIMAGE_IMPORT_DESCRIPTOR)((DWORD)_lpFile +
			_RVAToOffset(_lpFile, dwVirtualAddress));
		while (pImageImportDescriptor->OriginalFirstThunk || pImageImportDescriptor->TimeDateStamp ||
			pImageImportDescriptor->ForwarderChain || pImageImportDescriptor->Name ||
			pImageImportDescriptor->FirstThunk)
		{	//DLL名称
			lpName = (PTCHAR)((DWORD)_lpFile + _RVAToOffset(_lpFile, pImageImportDescriptor->Name));
			lstrcpy((PTCHAR)(_off + dwSize), lpName);
			dwSize += lstrlen(lpName);
			dwSize += dwSize % 2 ? 1 : 2;
			++pImageImportDescriptor;
		}
		_lpCurrent = _off + dwSize;

		//修正导入表中指向动态链接库常量字符串的RVA值
		pImageImportDescriptor = (PIMAGE_IMPORT_DESCRIPTOR)((DWORD)lpDstMemory +
			(DWORD)lpPImportInNewFile);
		dwSize = 0;
		while (dwPatchDLLCount--)
		{
			dwTemp = pImageImportDescriptor->Name;//原偏移量
			dwTemp1 = _OffsetToRVA(_lpFile1, _off + dwSize - (DWORD)lpDstMemory);//更改后的偏移量
			//显示输出更改前的.Name1值与更改后的.Name1值     
			_appendInfo(szCrLf);
			_appendInfo(szOut1911);
			_appendInfo(szCrLf);
			wsprintf(szBuffer, szOut1912, _off + dwSize, dwTemp, dwTemp1);
			_appendInfo(szBuffer);

			//修正.Name1的值
			pImageImportDescriptor->Name = dwTemp1;

			++pImageImportDescriptor;

			//下一个DLL字符串起始
			dwSize += lstrlen(_off + dwSize);
			dwSize += dwSize % 2 ? 1 : 2;
		}
		
		//紧接着修正函数调用部分
		pasteImport_fun(_lpFile, _lpFile1, _lpCurrent);



		//修正数据目录表中对导入表的描述(RVA地址和大小)
		pImageDosHeader = (PIMAGE_DOS_HEADER)lpDstMemory;
		pImageNtHeaders = (PIMAGE_NT_HEADERS)((DWORD)lpDstMemory + pImageDosHeader->e_lfanew);

		dwOldVirtualAddress = pImageNtHeaders->OptionalHeader.DataDirectory[1].VirtualAddress;
		dwOldSize = pImageNtHeaders->OptionalHeader.DataDirectory[1].Size;

		dwNewVirtualAddress = _OffsetToRVA(_lpFile1, lpNewImport);
		pImageNtHeaders->OptionalHeader.DataDirectory[1].VirtualAddress = dwNewVirtualAddress;
		pImageNtHeaders->OptionalHeader.DataDirectory[1].Size = dwNewImportSize;


		//输出
		_appendInfo(szCrLf);
		_appendInfo(szOut1917);
		_appendInfo(szCrLf);

		wsprintf(szBuffer, szOut1918, dwOldVirtualAddress, dwNewVirtualAddress);
		_appendInfo(szBuffer);
		
		wsprintf(szBuffer, szOut1919, dwOldSize, dwNewImportSize);
		_appendInfo(szBuffer);
		_appendInfo(szCrLf);
	}
}



/*
导入表
*/
void _dealImport(PVOID _lpFile1, PVOID _lpFile2, LPVOID _lpDstMemory)
{
	DWORD dwPatchImportSegSize;
	DWORD dwPatchImportSegStart;
	DWORD dwPatchImportInFileStart;
	DWORD dwDstImportSegSize;
	DWORD dwDstImportSegStart;
	DWORD dwDstImportInFileStart;
	DWORD dwDstImportSegRawSize;
	DWORD dwPatchDLLCount;
	DWORD dwPatchFunCount;
	DWORD dwFunctions[20];
	DWORD dwDstDLLCount;
	DWORD dwDstFunCount;
	DWORD dwNewImportSize;
	DWORD dwFunDllConstSize;
	DWORD dwImportSpace2;
	DWORD dwDstImportSize;
	DWORD dwPatchImportSize;
	DWORD dwThunkSize;
	DWORD dwNum;
	DWORD dwTemp1;
	LPVOID lpNewImport;
	LPVOID lpPImportInNewFile;



	TCHAR bufTemp1[124];
	TCHAR bufTemp2[44];


	TCHAR szOut221[] = TEXT("补丁导入表所在段的有效数据大小为：%08x\n");
	TCHAR szOut22[] = TEXT("补丁导入表所在段在文件中的起始位置：%08x\n");
	TCHAR szOut2912[] = TEXT("补丁导入表在文件中的起始地址：%08x\n");	
	TCHAR szOut23[] = TEXT("目标导入表所在段的有效数据大小为：%08x\n");
	TCHAR szOut24[] = TEXT("目标导入表所在段在文件中的起始位置：%08x\n");
	TCHAR szOut2911[] = TEXT("目标导入表在文件中的起始地址：%08x\n");
	TCHAR szOut25[] = TEXT("目标导入表所在段在文件中对齐后的大小：%08x\n");
	TCHAR szOut27[] = TEXT("补丁程序调用链接库个数：%08x\n");
	TCHAR szOut28[] = TEXT("补丁程序调用函数个数：%08x\n");
	TCHAR szOut29[] = TEXT("补丁程序调用动态链接库及每个动态链接库调用函数个数明细：\n");
	TCHAR szCrLf[] = TEXT("\n");
	TCHAR szOut2210[] = TEXT("目标程序调用链接库个数：%08x\n");
	TCHAR szOut2211[] = TEXT("目标程序调用函数个数：%08x\n");
	TCHAR szOut2212[] = TEXT("目标程序调用动态链接库及每个动态链接库调用函数个数明细：\n");
	TCHAR szOut2213[] = TEXT("补丁文件导入函数名和动态链接库名字符串常量的大小：%08x\n");
	TCHAR szOut2214[] = TEXT("目标文件中原有导入表空间：%08x，补丁程序中导入函数两个相关数组的大小：%08x  前者若大于后者，则bind可继续进行\n");
	TCHAR szOut2216[] = TEXT("合并以后文件导入表大小（含零结构）：%08x\n");
	TCHAR szOut26[] = TEXT("目标文件的导入表所处的段中有空间。剩余空间大小为:%08x,需要大小：%08x。"
		"合并以后的导入表在目标文件中存放的起始位置为：%08x\n");
	TCHAR szoutLine[] = TEXT("----------------------------------------------------------------------------------------\n");
	TCHAR szErr21[] = TEXT(">> 目标段空间不够，不足以容纳补丁导入表及相关数据！\n");

	     

	

	//获取补丁导入表所在节的大小
	dwPatchImportSegSize = getImportSegSize(_lpFile1);
	wsprintf(szBuffer, szOut221, dwPatchImportSegSize);
	_appendInfo(szBuffer);


	//获取补丁导入表所在节在文件中的起始位置
	dwPatchImportSegStart = getImportSegStart(_lpFile1);
	wsprintf(szBuffer, szOut22, dwPatchImportSegStart);
	_appendInfo(szBuffer);


	//获取补丁导入表在文件中的起始位置
	dwPatchImportInFileStart = getImportInFileStart(_lpFile1);
	wsprintf(szBuffer, szOut2912, dwPatchImportInFileStart);
	_appendInfo(szBuffer);



	//获取目标导入表所在节的大小
	dwDstImportSegSize = getImportSegSize(_lpFile2);
	wsprintf, (szBuffer, szOut23, dwDstImportSegSize);
	_appendInfo(szBuffer);


	//获取目标导入表所在节在文件中的起始位置
	dwDstImportSegStart = getImportSegStart(_lpFile2);
	wsprintf(szBuffer, szOut24, dwDstImportSegStart);
	_appendInfo(szBuffer);


	//获取目标导入表在文件中的起始位置
	dwDstImportInFileStart = getImportInFileStart(_lpFile2);
	wsprintf(szBuffer, szOut2911, dwDstImportInFileStart);
	_appendInfo(szBuffer);


	//获取目标导入表所在节的大小
	dwDstImportSegRawSize = getImportSegRawSize(_lpFile2);
	wsprintf(szBuffer, szOut25, dwDstImportSegRawSize);
	_appendInfo(szBuffer);


	//获取补丁导入表dll库个数和functions个数
	_getImportFunctions(_lpFile1, &dwPatchDLLCount, &dwPatchFunCount, dwFunctions);
	wsprintf(szBuffer, szOut27, dwPatchDLLCount);
	_appendInfo(szBuffer);
	wsprintf(szBuffer, szOut28, dwPatchFunCount);
	_appendInfo(szBuffer);


	//显示每个动态链接库的函数个数：
	_appendInfo(szOut29);
	memcpy(bufTemp2, dwFunctions, 40);
	_Byte2Hex(bufTemp1, bufTemp2, 40);
	_appendInfo(bufTemp1);
	_appendInfo(szCrLf);


	//获取目标导入表dll库个数和functions个数
	_getImportFunctions(_lpFile2, &dwDstDLLCount, &dwDstFunCount, dwFunctions);
	wsprintf(szBuffer, szOut2210, dwDstDLLCount);
	_appendInfo(szBuffer);
	wsprintf(szBuffer, szOut2211, dwDstFunCount);
	_appendInfo(szBuffer);


	//显示每个动态链接库的函数个数：
	_appendInfo(szOut2212);
	memcpy(bufTemp2, dwFunctions, 40);
	_Byte2Hex(bufTemp1, bufTemp2, 40);
	_appendInfo(bufTemp1);
	_appendInfo(szCrLf);

	
	//求连接生成的新文件的导入表大小
	dwNewImportSize = (dwDstDLLCount + dwPatchDLLCount + 1) * 0x14;

	//求函数名和动态链接库名的常量大小
	dwFunDllConstSize = _getFunDllSize(_lpFile1);

	dwImportSpace2 = dwFunDllConstSize + dwNewImportSize; //目标文件导入表所在节必须存在的空闲空间大小
		

	//目标导入表大小，含0结构
	dwDstImportSize = (dwDstDLLCount + 1) * 0x14;
	
	//补丁导入表大小，含0结构
	dwPatchImportSize = (dwPatchDLLCount + 1) * 0x14;

	//计算补丁程序IAT表和originalFirstThunk指向数组的大小之和
	dwThunkSize = (dwPatchFunCount + dwPatchDLLCount) * 8;

	wsprintf(szBuffer, szOut2214, dwDstImportSize, dwThunkSize);
	_appendInfo(szBuffer);


	wsprintf(szBuffer, szOut2213, dwFunDllConstSize);
	_appendInfo(szBuffer);

	wsprintf(szBuffer, szOut2216, dwNewImportSize);
	_appendInfo(szBuffer);

	//从目标导入表所在节的最后一个位置起往前查找连续的全0字符
	dwNum = 0;
	while (!((PTCHAR)_lpFile2)[dwDstImportSegStart + dwDstImportSegRawSize - ++dwNum]);
	--dwNum;

	if (dwNum >= dwImportSpace2)//表示找到了连续可用的空间
	{
		dwTemp1 = dwDstImportSegStart + dwDstImportSegRawSize - dwImportSpace2;
		lpNewImport =(LPVOID) dwTemp1;
		wsprintf(szBuffer, szOut26, dwNum, dwImportSpace2, dwTemp1);
		_appendInfo(szBuffer);

		//将目标文件的导入表复制到指定位置
		memcpy((PTCHAR)_lpDstMemory + dwTemp1, (PTCHAR)_lpFile2 + dwDstImportInFileStart, dwDstImportSize);
		lpPImportInNewFile = (LPVOID)(dwTemp1 + dwDstImportSize - 0x14);//计算补丁导入表在新文件的偏移
		//将补丁导入表复制到紧接下来的位置
		memcpy((PTCHAR)_lpDstMemory + dwTemp1 + dwDstImportSize - 0x14,
			(PTCHAR)_lpFile1 + dwPatchImportInFileStart, dwPatchImportSize);

		//分析补丁导入表内容
		//从补丁导入表获得动态链接库常量内容，添加到新文件
		pasteImport(_lpFile1, _lpFile2, (PTCHAR)_lpDstMemory + dwTemp1 + dwNewImportSize);

		_appendInfo(szoutLine);
	}
	else//导入表段空间不够
	{
		_appendInfo(szErr21);
	}
}



void _dealCode(lpMemory, lpMemory1)
{

}



void writeToFile(lpDstMemory, dwFileSize1)
{

}






/*
打开PE文件并处理
*/
void  _openFile(HWND hWinMain)
{

	HANDLE hFile, hMapFile = NULL;
	DWORD dwFileSize;
	LPVOID lpMemory = NULL;		//内存映像文件在内存的起始位置
	PIMAGE_NT_HEADERS pImageNtHeaders;


	HANDLE hFile1, hMapFile1 = NULL;
	DWORD dwFileSize1;
	LPVOID lpMemory1 = NULL;		//内存映像文件在内存的起始位置

	HGLOBAL hDstFile;
	PVOID lpDstMemory = NULL;



	TCHAR szOut001[] = TEXT("补丁文件：%s");
	TCHAR szFile1[] = TEXT("C:\\Users\\Admin\\Desktop\\patch.exe");
	TCHAR szCrLf[] = TEXT("\n");
	TCHAR szOut002[] = TEXT("目标文件：%s");
	TCHAR szFile2[] = TEXT("C:\\Users\\Admin\\Desktop\\HelloWorld.exe");
	TCHAR szErrFormat[] = TEXT("执行中发生了错误!请检查程序");
	





	wsprintf(szBuffer, szOut001, szFile1);
	_appendInfo(szBuffer);
	_appendInfo(szCrLf);


	wsprintf(szBuffer, szOut002, szFile2);
	_appendInfo(szBuffer);
	_appendInfo(szCrLf);
	_appendInfo(szCrLf);

	if ((hFile = CreateFile(szFile1, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE,
		NULL, OPEN_EXISTING, FILE_ATTRIBUTE_ARCHIVE, NULL)) != INVALID_HANDLE_VALUE)
	{
		if (dwFileSize = GetFileSize(hFile, NULL))//获取文件大小
		{
			if (hMapFile = CreateFileMapping(hFile, NULL, PAGE_READONLY, 0, 0, NULL))//内存映射文件
			{
				if (lpMemory = MapViewOfFile(hMapFile, FILE_MAP_READ, 0, 0, 0))//获得文件在内存的映象起始位置
				{

					if (((PIMAGE_DOS_HEADER)lpMemory)->e_magic != IMAGE_DOS_SIGNATURE)//检测PE文件是否有效
					{
						MessageBox(hWinMain, szErrFormat, NULL, MB_OK);
						goto _ErrFormat;
					}
					
					pImageNtHeaders = (PIMAGE_NT_HEADERS)((DWORD)lpMemory +
						((PIMAGE_DOS_HEADER)lpMemory)->e_lfanew);
					if (pImageNtHeaders->Signature != IMAGE_NT_SIGNATURE)//判断是否有PE字样
					{
						MessageBox(hWinMain, szErrFormat, NULL, MB_OK);
						goto _ErrFormat;
					}
						
				}
			}
		}
	}


	if ((hFile1 = CreateFile(szFile2, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE,
		NULL, OPEN_EXISTING, FILE_ATTRIBUTE_ARCHIVE, NULL)) != INVALID_HANDLE_VALUE)
	{
		if (dwFileSize1 = GetFileSize(hFile1, NULL))//获取文件大小
		{
			if (hMapFile1 = CreateFileMapping(hFile1, NULL, PAGE_READONLY, 0, 0, NULL))//内存映射文件
			{
				if (lpMemory1 = MapViewOfFile(hMapFile1, FILE_MAP_READ, 0, 0, 0))//获得文件在内存的映象起始位置
				{

					if (((PIMAGE_DOS_HEADER)lpMemory1)->e_magic != IMAGE_DOS_SIGNATURE)//检测PE文件是否有效
					{
						MessageBox(hWinMain, szErrFormat, NULL, MB_OK);
						goto _ErrFormat1;
					}

					pImageNtHeaders = (PIMAGE_NT_HEADERS)((DWORD)lpMemory1 +
						((PIMAGE_DOS_HEADER)lpMemory1)->e_lfanew);
					if (pImageNtHeaders->Signature != IMAGE_NT_SIGNATURE)//判断是否有PE字样
					{
						MessageBox(hWinMain, szErrFormat, NULL, MB_OK);
						goto _ErrFormat1;
					}

				}
			}
		}
	}


	//获取目标文件大小

	//为目标文件分配内存
	hDstFile = GlobalAlloc(GHND, dwFileSize1);
	lpDstMemory = GlobalLock(hDstFile);


	//将目标文件拷贝到内存区域
	memcpy(lpDstMemory, lpMemory1, dwFileSize1);

	_dealData(lpMemory, lpMemory1, lpDstMemory);
	_dealImport(lpMemory, lpMemory1, lpDstMemory);
	//_dealCode(lpMemory, lpMemory1);
	//writeToFile(lpDstMemory, dwFileSize1);

	//正常退出


_ErrFormat1:
	//MessageBox(hWinMain, szErrFormat, NULL, MB_OK);
	UnmapViewOfFile(lpMemory1);
	CloseHandle(hMapFile1);
	CloseHandle(hFile1);
	//return;

_ErrFormat:
	//MessageBox(hWinMain, szErrFormat, NULL, MB_OK);
	UnmapViewOfFile(lpMemory);
	CloseHandle(hMapFile);
	CloseHandle(hFile);
	return;



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