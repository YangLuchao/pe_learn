//��δ��ɣ�����




//��patch.ext����������뵽ָ��exe�ļ�����������
//��Ҫ��ʾ���ʹ�ó����޸�PE�ļ���ʽ���Ӷ������
//Ҫʵ�ֵĹ���
//

#include <Windows.h>
#include<Richedit.h>
#include<string.h>
#include "resource.h"


HINSTANCE hInstance;
HWND hWinEdit;


TCHAR szBuffer[1024];

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
ȡ���ݶδ�С
���ݶζ�λ������
ֻҪ�ڵı�ʶ��6,30,31λΪ1�����ʾ����Ҫ��
_lpHeaderָ���ڴ���PE�ļ�����ʼ
����ֵ��eax��
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
ȡ���ݶ����ļ��е���ʼλ��
���ݶζ�λ������
ֻҪ�ڵı�ʶ��6,30,31λΪ1�����ʾ����Ҫ��
_lpHeaderָ���ڴ���PE�ļ�����ʼ
����ֵ��eax��
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
ȡ���ݶ����ڴ��е���ʼλ��
���ݶζ�λ������
ֻҪ�ڵı�ʶ��6,30,31λΪ1�����ʾ����Ҫ��
_lpHeaderָ���ڴ���PE�ļ�����ʼ
����ֵ��eax��
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
ȡ���ݶ����ļ��ж����Ĵ�С
���ݶζ�λ������
ֻҪ�ڵı�ʶ��6,30,31λΪ1�����ʾ����Ҫ��
_lpHeaderָ���ڴ���PE�ļ�����ʼ
����ֵ��eax��
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
��ȡ����ַ
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
���ļ�ƫ��ת��Ϊ�ڴ�ƫ����RVA
lp_FileHeadΪ�ļ�ͷ����ʼ��ַ
_dwOffΪ�������ļ�ƫ�Ƶ�ַ
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
			_dwOffset < pImageSectionHeader->PointerToRawData + pImageSectionHeader->SizeOfRawData)//����ýڽ���RVA
		{
			return _dwOffset - pImageSectionHeader->PointerToRawData + pImageSectionHeader->VirtualAddress;
		}
		++pImageSectionHeader;
	}

	return 0;


}



/*
���ݶ�
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


	
	TCHAR szOut11[] = TEXT("�������ݶε���Ч���ݴ�СΪ��%08x\n");
	TCHAR szErr110[] = TEXT(">> δ�ҵ��ɴ�����ݵĽڣ�\n");
	TCHAR szOut12[] = TEXT("�������ݶ����ļ��е���ʼλ�ã�%08x\n");
	TCHAR szOut2217[] = TEXT("�������ݶ����ڴ��е���ʼ��ַ��%08x\n");
	TCHAR szOut13[] = TEXT("Ŀ�����ݶε���Ч���ݴ�СΪ��%08x\n");
	TCHAR szOut14[] = TEXT("Ŀ�����ݶ����ļ��е���ʼλ�ã�%08x\n");
	TCHAR szOut15[] = TEXT("Ŀ�����ݶ����ļ��ж����Ĵ�С��%08x\n");
	TCHAR szOut17[] = TEXT("Ŀ�����ݶ����ڴ��е���ʼ��ַ��%08x\n");
	TCHAR szErr11[] = TEXT(">> Ŀ�����ݶοռ䲻�������������ɲ�����������ݣ�\n");
	TCHAR szoutLine[] = TEXT("----------------------------------------------------------------------------------------\n");
	TCHAR szOut16[] = TEXT("Ŀ���ļ������ݶ����пռ䣬ʣ��ռ��СΪ�� %08x, ��Ҫ��С�� %08x��\n"
		"�������ݶ���Ŀ���ļ��д�ŵ���ʼλ�ã� %08x\n");
	TCHAR szOut19[] = TEXT("���������ļ����ڴ��е���ʼ��ַ��%08x\n");
	

	
	//����Ϊֹ�������ڴ��ļ���ָ���Ѿ���ȡ���ˡ�_lpFile1��_lpFile2�ֱ�ָ�������ļ�ͷ
	//�����Ǵ�����ļ�ͷ��ʼ���ҳ������ݽṹ���ֶ�ֵ�����бȽϡ�


	//��ȡ�����ļ����ݶεĴ�С
	if (dwPatchDataSize = getDataSize(_lpFile1))
	{
		wsprintf(szBuffer, szOut11, dwPatchDataSize);
		_appendInfo(szBuffer);
	}
	else//δ�ҵ�������ݵĽ�
	{
		_appendInfo(szErr110);
	}
		

	//��ȡ�����ļ����ݶ����ļ��е���ʼλ��RVA
	dwPatchDataStart = getDataStart(_lpFile1);
	wsprintf(szBuffer, szOut12, dwPatchDataStart);
	_appendInfo(szBuffer);

	//��ȡ�������ݶ����ڴ��е���ʼλ��
	dwPatchMemDataStart = getDataStartInMem(_lpFile1);
	wsprintf(szBuffer, szOut2217, dwPatchMemDataStart);
	_appendInfo(szBuffer);



	//��ȡĿ���ļ����ݶεĴ�С
	dwDstDataSize = getDataSize(_lpFile2);
	wsprintf(szBuffer, szOut13, dwDstDataSize);
	_appendInfo(szBuffer);

	//��ȡĿ���ļ����ݶ����ڴ��е���ʼλ��RVA
	dwDstDataStart = getDataStart(_lpFile2);
	wsprintf(szBuffer, szOut14, dwDstDataStart);
	_appendInfo(szBuffer);


	//��ȡĿ���ļ����ݶ����ļ��ж����Ĵ�С
	dwDstRawDataSize = getRawDataSize(_lpFile2);
	wsprintf(szBuffer, szOut15, dwDstRawDataSize);
	_appendInfo(szBuffer);



	//��ȡĿ�����ݶ����ڴ��е���ʼλ��
	dwDstMemDataStart = getDataStartInMem(_lpFile2);
	wsprintf(szBuffer, szOut17, dwDstMemDataStart);
	_appendInfo(szBuffer);

	//�ӱ��ڵ����һ��λ������ǰ����������ȫ0�ַ�
	dwNum = 0;
	while (!((PTCHAR)_lpFile2)[dwDstDataStart + dwDstRawDataSize - ++dwNum]);
	--dwNum;

	if (dwNum >= dwPatchDataSize)//��ʾ�ҵ����������õĿռ�
	{
		dwTemp1 = dwDstDataStart + dwDstRawDataSize - dwPatchDataSize;
		wsprintf(szBuffer, szOut16, dwNum, dwPatchDataSize, dwTemp1);
		_appendInfo(szBuffer);

		//���������ݿ�����Ŀ���ļ�ָ��λ�ô�
		memcpy((PTCHAR)_lpDstMemory + dwTemp1, (PTCHAR)_lpFile1 + dwPatchDataStart, dwPatchDataSize);
		
		//��¼���ļ������ݶ���ʼλ�����ڴ��еĵ�ַ
		
		dwDstImageBase = getImageBase(_lpFile2);
		dwDataInMemStart = dwDstImageBase + _OffsetToRVA(_lpFile2, dwTemp1);
		wsprintf(szBuffer, szOut19, dwDataInMemStart);
		_appendInfo(szBuffer);
	}
	else//���ݶοռ䲻��
	{
		_appendInfo(szErr11);
	}

	_appendInfo(szoutLine);
}


/*
��ȡRVA���ڽڵ�ԭʼ��С
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

	//�����ڱ�
	while (dwSectionSize--)
	{
		if (pImageSectionHeader->VirtualAddress <= _dwRVA &&
			_dwRVA < pImageSectionHeader->VirtualAddress + pImageSectionHeader->SizeOfRawData)//����ýڽ���RVA
		{
			return pImageSectionHeader->Misc.VirtualSize;
		}
		++pImageSectionHeader;
	}

	return 0;

}



/*
ȡ��������ڽڵĴ�С
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
��ȡRVA���ڽڵ��ļ���ʼ��ַ
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

	//�����ڱ�
	while (dwSectionSize--)
	{
		if (pImageSectionHeader->VirtualAddress <= _dwRVA &&
			_dwRVA < pImageSectionHeader->VirtualAddress + pImageSectionHeader->SizeOfRawData)//����ýڽ���RVA
		{
			return pImageSectionHeader->PointerToRawData;
		}
		++pImageSectionHeader;
	}

	return 0;
}

/*
ȡ������������ڽڵĴ�С
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
���ڴ�ƫ����RVAת��Ϊ�ļ�ƫ��
lp_FileHeadΪ�ļ�ͷ����ʼ��ַ
_dwRVAΪ������RVA��ַ
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

	//�����ڱ�
	while (dNumberOfSections--)
	{
		if (_dwRVA >= pImageSectionHeader->VirtualAddress &&
			_dwRVA < pImageSectionHeader->VirtualAddress + pImageSectionHeader->SizeOfRawData)//����ýڽ���RVA������Misc����Ҫԭ������Щ�ε�Miscֵ�Ǵ���ģ�
		{
			return _dwRVA - pImageSectionHeader->VirtualAddress + pImageSectionHeader->PointerToRawData;
		}
		++pImageSectionHeader;
	}
	return -1;
}


/*
ȡ����������ļ���ƫ��
_lpHeaderָ���ڴ���PE�ļ�����ʼ
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
��ȡRVA���ڽ����ļ��ж����Ժ�Ĵ�С
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

	//�����ڱ�
	while (dNumberOfSections--)
	{
		if (_dwRVA >= pImageSectionHeader->VirtualAddress &&
			_dwRVA < pImageSectionHeader->VirtualAddress + pImageSectionHeader->SizeOfRawData)//����ýڽ���RVA������Misc����Ҫԭ������Щ�ε�Miscֵ�Ǵ���ģ�
		{
			return pImageSectionHeader->SizeOfRawData;
		}
		++pImageSectionHeader;
	}
	return -1;
}



/*
ȡ��������ڽ����ļ��ж����Ժ�Ĵ�С
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
��ȡPE�ļ��ĵ������õĺ�������
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
��bufTemp2λ�ô�_dwSize���ֽ�ת��Ϊ16���Ƶ��ַ���
bufTemp1��Ϊת������ַ���
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
��ȡPE�ļ��ĵ������õĺ�����
�붯̬���ӿ���ַ���������С
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
				
				if (!(pImageThunkData->u1.AddressOfData & IMAGE_ORDINAL_FLAG32))//�����Ƶ���
				{
					dwSize += 2;//�������
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
������������������뼰��������
_offΪ���ļ��д�Ų������������λ��
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
	TCHAR szOut1911[] = TEXT("�ϲ��Ժ�ĵ��������\n");
	TCHAR szOut1912[] = TEXT("   DLL����%s      Name1ԭʼֵ��%08x      Name1����ֵ��%08x\n");
	TCHAR szOut1917[] = TEXT("����Ŀ¼���жԵ�����ֵ��޸�\n");
	TCHAR szOut1918[] = TEXT("   �������ʼλ��   ԭʼֵ��%08x   ����ֵ��%08x   \n");
	TCHAR szOut1919[] = TEXT("   ������С       ԭʼֵ��%08x   ����ֵ��%08x   \n");


	    

	pImageDosHeader = (PIMAGE_DOS_HEADER)_lpFile;
	pImageNtHeaders = (PIMAGE_NT_HEADERS)((DWORD)_lpFile + pImageDosHeader->e_lfanew);
	if (dwVirtualAddress = pImageNtHeaders->OptionalHeader.DataDirectory[1].VirtualAddress)
	{
		pImageImportDescriptor = (PIMAGE_IMPORT_DESCRIPTOR)((DWORD)_lpFile +
			_RVAToOffset(_lpFile, dwVirtualAddress));
		while (pImageImportDescriptor->OriginalFirstThunk || pImageImportDescriptor->TimeDateStamp ||
			pImageImportDescriptor->ForwarderChain || pImageImportDescriptor->Name ||
			pImageImportDescriptor->FirstThunk)
		{	//DLL����
			lpName = (PTCHAR)((DWORD)_lpFile + _RVAToOffset(_lpFile, pImageImportDescriptor->Name));
			lstrcpy((PTCHAR)(_off + dwSize), lpName);
			dwSize += lstrlen(lpName);
			dwSize += dwSize % 2 ? 1 : 2;
			++pImageImportDescriptor;
		}
		_lpCurrent = _off + dwSize;

		//�����������ָ��̬���ӿⳣ���ַ�����RVAֵ
		pImageImportDescriptor = (PIMAGE_IMPORT_DESCRIPTOR)((DWORD)lpDstMemory +
			(DWORD)lpPImportInNewFile);
		dwSize = 0;
		while (dwPatchDLLCount--)
		{
			dwTemp = pImageImportDescriptor->Name;//ԭƫ����
			dwTemp1 = _OffsetToRVA(_lpFile1, _off + dwSize - (DWORD)lpDstMemory);//���ĺ��ƫ����
			//��ʾ�������ǰ��.Name1ֵ����ĺ��.Name1ֵ     
			_appendInfo(szCrLf);
			_appendInfo(szOut1911);
			_appendInfo(szCrLf);
			wsprintf(szBuffer, szOut1912, _off + dwSize, dwTemp, dwTemp1);
			_appendInfo(szBuffer);

			//����.Name1��ֵ
			pImageImportDescriptor->Name = dwTemp1;

			++pImageImportDescriptor;

			//��һ��DLL�ַ�����ʼ
			dwSize += lstrlen(_off + dwSize);
			dwSize += dwSize % 2 ? 1 : 2;
		}
		
		//�����������������ò���
		pasteImport_fun(_lpFile, _lpFile1, _lpCurrent);



		//��������Ŀ¼���жԵ���������(RVA��ַ�ʹ�С)
		pImageDosHeader = (PIMAGE_DOS_HEADER)lpDstMemory;
		pImageNtHeaders = (PIMAGE_NT_HEADERS)((DWORD)lpDstMemory + pImageDosHeader->e_lfanew);

		dwOldVirtualAddress = pImageNtHeaders->OptionalHeader.DataDirectory[1].VirtualAddress;
		dwOldSize = pImageNtHeaders->OptionalHeader.DataDirectory[1].Size;

		dwNewVirtualAddress = _OffsetToRVA(_lpFile1, lpNewImport);
		pImageNtHeaders->OptionalHeader.DataDirectory[1].VirtualAddress = dwNewVirtualAddress;
		pImageNtHeaders->OptionalHeader.DataDirectory[1].Size = dwNewImportSize;


		//���
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
�����
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


	TCHAR szOut221[] = TEXT("������������ڶε���Ч���ݴ�СΪ��%08x\n");
	TCHAR szOut22[] = TEXT("������������ڶ����ļ��е���ʼλ�ã�%08x\n");
	TCHAR szOut2912[] = TEXT("������������ļ��е���ʼ��ַ��%08x\n");	
	TCHAR szOut23[] = TEXT("Ŀ�굼������ڶε���Ч���ݴ�СΪ��%08x\n");
	TCHAR szOut24[] = TEXT("Ŀ�굼������ڶ����ļ��е���ʼλ�ã�%08x\n");
	TCHAR szOut2911[] = TEXT("Ŀ�굼������ļ��е���ʼ��ַ��%08x\n");
	TCHAR szOut25[] = TEXT("Ŀ�굼������ڶ����ļ��ж����Ĵ�С��%08x\n");
	TCHAR szOut27[] = TEXT("��������������ӿ������%08x\n");
	TCHAR szOut28[] = TEXT("����������ú���������%08x\n");
	TCHAR szOut29[] = TEXT("����������ö�̬���ӿ⼰ÿ����̬���ӿ���ú���������ϸ��\n");
	TCHAR szCrLf[] = TEXT("\n");
	TCHAR szOut2210[] = TEXT("Ŀ�����������ӿ������%08x\n");
	TCHAR szOut2211[] = TEXT("Ŀ�������ú���������%08x\n");
	TCHAR szOut2212[] = TEXT("Ŀ�������ö�̬���ӿ⼰ÿ����̬���ӿ���ú���������ϸ��\n");
	TCHAR szOut2213[] = TEXT("�����ļ����뺯�����Ͷ�̬���ӿ����ַ��������Ĵ�С��%08x\n");
	TCHAR szOut2214[] = TEXT("Ŀ���ļ���ԭ�е����ռ䣺%08x�����������е��뺯�������������Ĵ�С��%08x  ǰ�������ں��ߣ���bind�ɼ�������\n");
	TCHAR szOut2216[] = TEXT("�ϲ��Ժ��ļ�������С������ṹ����%08x\n");
	TCHAR szOut26[] = TEXT("Ŀ���ļ��ĵ���������Ķ����пռ䡣ʣ��ռ��СΪ:%08x,��Ҫ��С��%08x��"
		"�ϲ��Ժ�ĵ������Ŀ���ļ��д�ŵ���ʼλ��Ϊ��%08x\n");
	TCHAR szoutLine[] = TEXT("----------------------------------------------------------------------------------------\n");
	TCHAR szErr21[] = TEXT(">> Ŀ��οռ䲻�������������ɲ��������������ݣ�\n");

	     

	

	//��ȡ������������ڽڵĴ�С
	dwPatchImportSegSize = getImportSegSize(_lpFile1);
	wsprintf(szBuffer, szOut221, dwPatchImportSegSize);
	_appendInfo(szBuffer);


	//��ȡ������������ڽ����ļ��е���ʼλ��
	dwPatchImportSegStart = getImportSegStart(_lpFile1);
	wsprintf(szBuffer, szOut22, dwPatchImportSegStart);
	_appendInfo(szBuffer);


	//��ȡ������������ļ��е���ʼλ��
	dwPatchImportInFileStart = getImportInFileStart(_lpFile1);
	wsprintf(szBuffer, szOut2912, dwPatchImportInFileStart);
	_appendInfo(szBuffer);



	//��ȡĿ�굼������ڽڵĴ�С
	dwDstImportSegSize = getImportSegSize(_lpFile2);
	wsprintf, (szBuffer, szOut23, dwDstImportSegSize);
	_appendInfo(szBuffer);


	//��ȡĿ�굼������ڽ����ļ��е���ʼλ��
	dwDstImportSegStart = getImportSegStart(_lpFile2);
	wsprintf(szBuffer, szOut24, dwDstImportSegStart);
	_appendInfo(szBuffer);


	//��ȡĿ�굼������ļ��е���ʼλ��
	dwDstImportInFileStart = getImportInFileStart(_lpFile2);
	wsprintf(szBuffer, szOut2911, dwDstImportInFileStart);
	_appendInfo(szBuffer);


	//��ȡĿ�굼������ڽڵĴ�С
	dwDstImportSegRawSize = getImportSegRawSize(_lpFile2);
	wsprintf(szBuffer, szOut25, dwDstImportSegRawSize);
	_appendInfo(szBuffer);


	//��ȡ���������dll�������functions����
	_getImportFunctions(_lpFile1, &dwPatchDLLCount, &dwPatchFunCount, dwFunctions);
	wsprintf(szBuffer, szOut27, dwPatchDLLCount);
	_appendInfo(szBuffer);
	wsprintf(szBuffer, szOut28, dwPatchFunCount);
	_appendInfo(szBuffer);


	//��ʾÿ����̬���ӿ�ĺ���������
	_appendInfo(szOut29);
	memcpy(bufTemp2, dwFunctions, 40);
	_Byte2Hex(bufTemp1, bufTemp2, 40);
	_appendInfo(bufTemp1);
	_appendInfo(szCrLf);


	//��ȡĿ�굼���dll�������functions����
	_getImportFunctions(_lpFile2, &dwDstDLLCount, &dwDstFunCount, dwFunctions);
	wsprintf(szBuffer, szOut2210, dwDstDLLCount);
	_appendInfo(szBuffer);
	wsprintf(szBuffer, szOut2211, dwDstFunCount);
	_appendInfo(szBuffer);


	//��ʾÿ����̬���ӿ�ĺ���������
	_appendInfo(szOut2212);
	memcpy(bufTemp2, dwFunctions, 40);
	_Byte2Hex(bufTemp1, bufTemp2, 40);
	_appendInfo(bufTemp1);
	_appendInfo(szCrLf);

	
	//���������ɵ����ļ��ĵ�����С
	dwNewImportSize = (dwDstDLLCount + dwPatchDLLCount + 1) * 0x14;

	//�������Ͷ�̬���ӿ����ĳ�����С
	dwFunDllConstSize = _getFunDllSize(_lpFile1);

	dwImportSpace2 = dwFunDllConstSize + dwNewImportSize; //Ŀ���ļ���������ڽڱ�����ڵĿ��пռ��С
		

	//Ŀ�굼����С����0�ṹ
	dwDstImportSize = (dwDstDLLCount + 1) * 0x14;
	
	//����������С����0�ṹ
	dwPatchImportSize = (dwPatchDLLCount + 1) * 0x14;

	//���㲹������IAT���originalFirstThunkָ������Ĵ�С֮��
	dwThunkSize = (dwPatchFunCount + dwPatchDLLCount) * 8;

	wsprintf(szBuffer, szOut2214, dwDstImportSize, dwThunkSize);
	_appendInfo(szBuffer);


	wsprintf(szBuffer, szOut2213, dwFunDllConstSize);
	_appendInfo(szBuffer);

	wsprintf(szBuffer, szOut2216, dwNewImportSize);
	_appendInfo(szBuffer);

	//��Ŀ�굼������ڽڵ����һ��λ������ǰ����������ȫ0�ַ�
	dwNum = 0;
	while (!((PTCHAR)_lpFile2)[dwDstImportSegStart + dwDstImportSegRawSize - ++dwNum]);
	--dwNum;

	if (dwNum >= dwImportSpace2)//��ʾ�ҵ����������õĿռ�
	{
		dwTemp1 = dwDstImportSegStart + dwDstImportSegRawSize - dwImportSpace2;
		lpNewImport =(LPVOID) dwTemp1;
		wsprintf(szBuffer, szOut26, dwNum, dwImportSpace2, dwTemp1);
		_appendInfo(szBuffer);

		//��Ŀ���ļ��ĵ�����Ƶ�ָ��λ��
		memcpy((PTCHAR)_lpDstMemory + dwTemp1, (PTCHAR)_lpFile2 + dwDstImportInFileStart, dwDstImportSize);
		lpPImportInNewFile = (LPVOID)(dwTemp1 + dwDstImportSize - 0x14);//���㲹������������ļ���ƫ��
		//������������Ƶ�����������λ��
		memcpy((PTCHAR)_lpDstMemory + dwTemp1 + dwDstImportSize - 0x14,
			(PTCHAR)_lpFile1 + dwPatchImportInFileStart, dwPatchImportSize);

		//�����������������
		//�Ӳ���������ö�̬���ӿⳣ�����ݣ���ӵ����ļ�
		pasteImport(_lpFile1, _lpFile2, (PTCHAR)_lpDstMemory + dwTemp1 + dwNewImportSize);

		_appendInfo(szoutLine);
	}
	else//�����οռ䲻��
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
��PE�ļ�������
*/
void  _openFile(HWND hWinMain)
{

	HANDLE hFile, hMapFile = NULL;
	DWORD dwFileSize;
	LPVOID lpMemory = NULL;		//�ڴ�ӳ���ļ����ڴ����ʼλ��
	PIMAGE_NT_HEADERS pImageNtHeaders;


	HANDLE hFile1, hMapFile1 = NULL;
	DWORD dwFileSize1;
	LPVOID lpMemory1 = NULL;		//�ڴ�ӳ���ļ����ڴ����ʼλ��

	HGLOBAL hDstFile;
	PVOID lpDstMemory = NULL;



	TCHAR szOut001[] = TEXT("�����ļ���%s");
	TCHAR szFile1[] = TEXT("C:\\Users\\Admin\\Desktop\\patch.exe");
	TCHAR szCrLf[] = TEXT("\n");
	TCHAR szOut002[] = TEXT("Ŀ���ļ���%s");
	TCHAR szFile2[] = TEXT("C:\\Users\\Admin\\Desktop\\HelloWorld.exe");
	TCHAR szErrFormat[] = TEXT("ִ���з����˴���!�������");
	





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
		if (dwFileSize = GetFileSize(hFile, NULL))//��ȡ�ļ���С
		{
			if (hMapFile = CreateFileMapping(hFile, NULL, PAGE_READONLY, 0, 0, NULL))//�ڴ�ӳ���ļ�
			{
				if (lpMemory = MapViewOfFile(hMapFile, FILE_MAP_READ, 0, 0, 0))//����ļ����ڴ��ӳ����ʼλ��
				{

					if (((PIMAGE_DOS_HEADER)lpMemory)->e_magic != IMAGE_DOS_SIGNATURE)//���PE�ļ��Ƿ���Ч
					{
						MessageBox(hWinMain, szErrFormat, NULL, MB_OK);
						goto _ErrFormat;
					}
					
					pImageNtHeaders = (PIMAGE_NT_HEADERS)((DWORD)lpMemory +
						((PIMAGE_DOS_HEADER)lpMemory)->e_lfanew);
					if (pImageNtHeaders->Signature != IMAGE_NT_SIGNATURE)//�ж��Ƿ���PE����
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
		if (dwFileSize1 = GetFileSize(hFile1, NULL))//��ȡ�ļ���С
		{
			if (hMapFile1 = CreateFileMapping(hFile1, NULL, PAGE_READONLY, 0, 0, NULL))//�ڴ�ӳ���ļ�
			{
				if (lpMemory1 = MapViewOfFile(hMapFile1, FILE_MAP_READ, 0, 0, 0))//����ļ����ڴ��ӳ����ʼλ��
				{

					if (((PIMAGE_DOS_HEADER)lpMemory1)->e_magic != IMAGE_DOS_SIGNATURE)//���PE�ļ��Ƿ���Ч
					{
						MessageBox(hWinMain, szErrFormat, NULL, MB_OK);
						goto _ErrFormat1;
					}

					pImageNtHeaders = (PIMAGE_NT_HEADERS)((DWORD)lpMemory1 +
						((PIMAGE_DOS_HEADER)lpMemory1)->e_lfanew);
					if (pImageNtHeaders->Signature != IMAGE_NT_SIGNATURE)//�ж��Ƿ���PE����
					{
						MessageBox(hWinMain, szErrFormat, NULL, MB_OK);
						goto _ErrFormat1;
					}

				}
			}
		}
	}


	//��ȡĿ���ļ���С

	//ΪĿ���ļ������ڴ�
	hDstFile = GlobalAlloc(GHND, dwFileSize1);
	lpDstMemory = GlobalLock(hDstFile);


	//��Ŀ���ļ��������ڴ�����
	memcpy(lpDstMemory, lpMemory1, dwFileSize1);

	_dealData(lpMemory, lpMemory1, lpDstMemory);
	_dealImport(lpMemory, lpMemory1, lpDstMemory);
	//_dealCode(lpMemory, lpMemory1);
	//writeToFile(lpDstMemory, dwFileSize1);

	//�����˳�


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