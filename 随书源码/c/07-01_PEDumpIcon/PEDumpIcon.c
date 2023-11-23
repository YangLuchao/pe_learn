#include <Windows.h>
#include<Richedit.h>
#include "resource.h"


#pragma pack(1)

//�ļ��е�ICOͷ��
typedef struct
{
	TBYTE bWidth;			//���
	TBYTE bHeight;			//�߶�
	TBYTE bColorCount;		//��ɫ��
	TBYTE bReserved;		//�����֣�����Ϊ0
	WORD  wPlanes;			//��ɫ��
	WORD  wBitCount;		//ÿ�����ص�λ��
	DWORD dwBytesInRes ;	//��Դ����
	DWORD dwImageOffset;	//��Դ���ļ�ƫ��
}ICON_DIR_ENTRY, *PICON_DIR_ENTRY;

//PE��ICOͷ��
typedef struct
{
	TBYTE bWidth;			//���
	TBYTE bHeight;			//�߶�
	TBYTE bColorCount;		//��ɫ��
	TBYTE bReserved;		//�����֣�����Ϊ0
	WORD  wPlanes;			//��ɫ��
	WORD  wBitCount;		//ÿ�����ص�λ��
	DWORD dwBytesInRes;		//��Դ����
	WORD  nID;	//ͼ������
}PE_ICON_DIR_ENTRY, *PPE_ICON_DIR_ENTRY;





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
���ڴ�ƫ����RVAת��Ϊ�ļ�ƫ��
lp_FileHeadΪ�ļ�ͷ����ʼ��ַ
_dwRVAΪ������RVA��ַ
*/
DWORD  _RVAToOffset(PTCHAR _lpFileHead, DWORD _dwRVA)
{
	PIMAGE_NT_HEADERS pImageNtHeaders;
	PIMAGE_SECTION_HEADER pImageSectionHeader;
	WORD dNumberOfSections;


	pImageNtHeaders = (PIMAGE_NT_HEADERS)(_lpFileHead + ((PIMAGE_DOS_HEADER)_lpFileHead)->e_lfanew);
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
��ͼ������д���ļ�

������_lpFile �ļ��ڴ���ʼ��ַ
����: _lpRes ��Դ����ʼ��ַ
����: _hFileΪ�ļ����
������_nubmerΪͼ��˳��
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
	TCHAR szLevel31[] = TEXT("  >> ͼ��%4d�����ļ�λ�ã�0x%08x  ��Դ���ȣ�%d\n");


	pResourceDirectory = (PIMAGE_RESOURCE_DIRECTORY)_lpRes;//ָ���һ��Ŀ¼��
	dwNumber = pResourceDirectory->NumberOfIdEntries + pResourceDirectory->NumberOfNamedEntries;//����Ŀ¼��ĸ���
	pResourceDirectoryEntry = (PIMAGE_RESOURCE_DIRECTORY_ENTRY)(pResourceDirectory + 1);//����Ŀ¼ͷ��λ��Ŀ¼��


	while (dwNumber > 0)
	{
		dwOffsetToData = pResourceDirectoryEntry->OffsetToData;//�鿴IMAGE_RESOURCE_DIRECTORY_ENTRY.OffsetToData
		if (dwOffsetToData & 0x80000000)//������λΪ1
		{
			dwOffsetToData = (dwOffsetToData & 0x7fffffff) + (DWORD)_lpRes;//������Ŀ¼
			dwName = pResourceDirectoryEntry->Name;
			if (!(dwName & 0x80000000))//����ǰ����ƶ������Դ����,����
			{
				//��һ�㣬dwNameָ������Դ���
				if (dwName == 0x3)// �жϱ���Ƿ�Ϊͼ��
				{
					//�ƶ����ڶ���Ŀ¼
					pResourceDirectory = (PIMAGE_RESOURCE_DIRECTORY)dwOffsetToData;
					//����Ŀ¼��ĸ���
					dwNumber = pResourceDirectory->NumberOfIdEntries + pResourceDirectory->NumberOfNamedEntries;
					//�����ڶ���Ŀ¼ͷ��λ���ڶ���Ŀ¼��
					pResourceDirectoryEntry = (PIMAGE_RESOURCE_DIRECTORY_ENTRY)(pResourceDirectory + 1);
					
					while (dwNumber > 0)
					{
						
						dwTemp1 = pResourceDirectoryEntry->Name;

						//�ж�����Ƿ��ָ����һ��
						if (dwTemp1 == _number)//���һ�£��������������
						{	
							dwOffsetToData = pResourceDirectoryEntry->OffsetToData;
							if (dwOffsetToData & 0x80000000)//���λΪ1
							{
								dwOffsetToData = (dwOffsetToData & 0x7fffffff) + (DWORD)_lpRes;//������

								//�ƶ���������Ŀ¼������Ŀ¼��������Ϊ1

								//��ַָ��������
								pImageResourceDataEntry = (PIMAGE_RESOURCE_DATA_ENTRY)
									(((PIMAGE_RESOURCE_DIRECTORY_ENTRY)
									(((PIMAGE_RESOURCE_DIRECTORY)
									dwOffsetToData) + 1))->OffsetToData + (DWORD)_lpRes);
								dwTemp2 = _RVAToOffset(_lpFile, pImageResourceDataEntry->OffsetToData);
								dwTemp3 = pImageResourceDataEntry->Size;
								wsprintf(szBuffer, szLevel31, dwTemp1, dwTemp2, dwTemp3);
								_appendInfo(szBuffer);


								lpMem = _lpFile + dwTemp2;
								//��@dwTemp2��ʼ��@dwTemp3���ֽ�д���ļ�
								WriteFile(_hFile, lpMem, dwTemp3, &dwTemp, NULL);
								_appendInfo(TEXT("  >> ���д�롣\n"));
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
ͨ��PE ICOͷ��ȡICO����
����1���ļ���ʼ
����2����Դ��ʼ
����3����ţ��ɴ˹�������ļ���g12.ico��
����4��PE ICOͷ��ʼ
����5��PE ICOͷ��С
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
	TCHAR szFile[] = TEXT("  >>�½��ļ�%s\n");
	TCHAR szOut13[] = TEXT("  >>ͼ����%4d�й���ͼ�꣺%d����\n");

	wsprintf(szFileName1, szOut11, _number);
	wsprintf(szBuffer, szFile, szFileName1);
	_appendInfo(szBuffer);

	//����д���ļ�
	hFile = CreateFile(szFileName1, GENERIC_WRITE, FILE_SHARE_READ, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
	
	//��λ�ļ�ָ��
	lpMemory = (PVOID)(_lpFile + _off);
	//д��6���ֽ��ļ�ͷ
	WriteFile(hFile, lpMemory, 6, &dwTemp, NULL);

	//���ͼ�������ͼ��ĸ���
	dwCount = *(PWORD)((PTCHAR)lpMemory + 4);
	wsprintf(szBuffer, szOut13, _number, dwCount);
	_appendInfo(szBuffer);

	//���һ��ͼ���������ļ��е�ƫ��
	dwForward = _size + dwCount * 2;//ÿһ����¼��2���ֽ�

	//��λ��ICOͼ������ʼ

	pPeIconDirEntry = (PPE_ICON_DIR_ENTRY)((PTCHAR)lpMemory + 6);
	dwIcoDataSize = 0;
	dwTemp1 = dwCount;
	while (dwTemp1-- > 0)
	{
		//��PE�еĽṹ�帴��
		stIconDirEntry = *(PICON_DIR_ENTRY)pPeIconDirEntry;

		//����ͼ���������ļ�ƫ�ơ�
		//��һ��ͼ��ĸ�ֵ���ļ�ICOͷ��С
		//�Ժ��ͼ��ĸ�ֵ����һ���������ݳ���
		dwForward += dwIcoDataSize;
		stIconDirEntry.dwImageOffset = dwForward;

		WriteFile(hFile, &stIconDirEntry, sizeof(ICON_DIR_ENTRY), &dwTemp, NULL);
		dwIcoDataSize = stIconDirEntry.dwBytesInRes;//Ϊ��һ�μ����ַ��׼��
		++pPeIconDirEntry;
	}
	//��ѭ�����������е�ͷ����Ϣ�Ѿ����
	_appendInfo(TEXT("  >> ���ICOͷ����Ϣ\n"));


	//��ʼ��һ��ѭ����������ͼ������д���ļ�
	pPeIconDirEntry = (PPE_ICON_DIR_ENTRY)((PTCHAR)lpMemory + 6);
	dwTemp1 = dwCount;
	while (dwTemp1-- > 0)
	{
		//д���ļ�ͼ������
		//����ͼ�����ݴ�С
		_getFinnalData(_lpFile, _lpRes, hFile, pPeIconDirEntry->nID);
		++pPeIconDirEntry;
	}
	//��ѭ�����������е���Ϣ�Ѿ����
	CloseHandle(hFile);
}







/*
������Դ�����ͼ������Դ
_lpFile���ļ���ַ
_lpRes����Դ���ַ
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


	TCHAR  szOut10[] = TEXT("��Դ������ͼ����%d����\n"
							"----------------------------------------------------------------\n\n");
	TCHAR szLevel3[] = TEXT("ͼ����%4d�����ļ�λ�ã�0x%08x  ��Դ���ȣ�%d\n");
	TCHAR szNoIconArray[] = TEXT("��Դ����û�з���ͼ���飡\n");



	pResourceDirectory = (PIMAGE_RESOURCE_DIRECTORY)_lpRes;//ָ��Ŀ¼��
	dwNumber = pResourceDirectory->NumberOfIdEntries + pResourceDirectory->NumberOfNamedEntries;//����Ŀ¼��ĸ���
	pResourceDirectoryEntry = (PIMAGE_RESOURCE_DIRECTORY_ENTRY)(pResourceDirectory + 1);//����Ŀ¼ͷ��λ��Ŀ¼��


	while (dwNumber > 0)
	{
		dwOffsetToData = pResourceDirectoryEntry->OffsetToData;//�鿴IMAGE_RESOURCE_DIRECTORY_ENTRY.OffsetToData
		if (dwOffsetToData & 0x80000000)//������λΪ1
		{
			dwOffsetToData = (dwOffsetToData & 0x7fffffff) + (DWORD)_lpRes;//������Ŀ¼
			dwName = pResourceDirectoryEntry->Name;
			if (!(dwName & 0x80000000))//����ǰ����ƶ������Դ����,����
			{
				//��һ�㣬dwNameָ������Դ���
				if (dwName == 0xe)// �жϱ���Ƿ�Ϊͼ����
				{
					//�ƶ����ڶ���Ŀ¼
					pResourceDirectory = (PIMAGE_RESOURCE_DIRECTORY)dwOffsetToData;
					//����Ŀ¼��ĸ���
					dwNumber = pResourceDirectory->NumberOfIdEntries + pResourceDirectory->NumberOfNamedEntries;//����Ŀ¼��ĸ���
					dwICO = dwNumber;
					
					wsprintf(szBuffer, szOut10, dwICO);
					_appendInfo(szBuffer);

					pResourceDirectoryEntry = (PIMAGE_RESOURCE_DIRECTORY_ENTRY)(pResourceDirectory + 1);//�����ڶ���Ŀ¼ͷ��λ���ڶ���Ŀ¼��
					dwTemp1 = 0;
					while (dwNumber > 0)
					{
						//ֱ�ӷ��ʵ����ݣ���ȡ�������ļ���ƫ�Ƽ���С
						++dwTemp1;
						dwOffsetToData = pResourceDirectoryEntry->OffsetToData;
						if (dwOffsetToData & 0x80000000)//���λΪ1
						{
							dwOffsetToData = (dwOffsetToData & 0x7fffffff) + (DWORD)_lpRes;//������
						
							//�ƶ���������Ŀ¼������Ŀ¼��������Ϊ1
							
							//��ַָ��������
							pImageResourceDataEntry = (PIMAGE_RESOURCE_DATA_ENTRY)
								(((PIMAGE_RESOURCE_DIRECTORY_ENTRY)
								(((PIMAGE_RESOURCE_DIRECTORY)
								dwOffsetToData) + 1))->OffsetToData + (DWORD)_lpRes);
							dwTemp2 = _RVAToOffset(_lpFile, pImageResourceDataEntry->OffsetToData);
							dwTemp3 = pImageResourceDataEntry->Size;
							wsprintf(szBuffer, szLevel3, dwTemp1, dwTemp2, dwTemp3);
							_appendInfo(szBuffer);

							//������ICO�ļ�
							//����1���ļ���ʼ
							//����2����Դ��ʼ
							//����3��PE ICOͷ��ʼ
							//����4�����
							//����5��PE ICOͷ��С
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
��ȡPE�ļ�����Դ��Ϣ
*/
void _getResource(PTCHAR _lpFile, PTCHAR  _lpPeHead)
{
	PIMAGE_NT_HEADERS pNtHeaders;
	DWORD dwVirtualAddress;
	PTCHAR lpRes;

	pNtHeaders = (PIMAGE_NT_HEADERS)_lpPeHead;
	if (dwVirtualAddress = (pNtHeaders->OptionalHeader.DataDirectory)[2].VirtualAddress)
	{
		//����Դ�����ļ���ƫ��
		lpRes = _lpFile + _RVAToOffset(_lpFile, dwVirtualAddress);

		//��������������ֱ��ʾ
		//1���ļ�ͷλ��
		//2����Դ��λ��
		_processRes(_lpFile, lpRes);
	}
	else
	{
		_appendInfo(TEXT("\nδ���ָ��ļ�����Դ��\n"));
		return;
	}
}




/*
��PE�ļ�������
*/
void _openFile(HWND hWinMain)
{
	OPENFILENAME stOF;
	HANDLE hFile, hMapFile;
	DWORD dwFileSize;		//�ļ���С
	PTCHAR lpMemory;		//�ڴ�ӳ���ļ����ڴ����ʼλ��
	PTCHAR lpMem;

	TCHAR szBuffer[200];
	TCHAR szFileName[MAX_PATH] = { 0 };	//Ҫ�򿪵��ļ�·����������
	TCHAR szExtPe[] = TEXT("PE Files\0*.exe;*.dll;*.scr;*.fon;*.drv\0All Files(*.*)\0*.*\0\0");
	TCHAR szOut1[] = TEXT("-----------------------------------------------------------------\n"
						  "�������PE�ļ���%s");


	RtlZeroMemory(&stOF, sizeof(stOF));
	stOF.lStructSize = sizeof(stOF);
	stOF.hwndOwner = hWinMain;
	stOF.lpstrFilter = szExtPe;
	stOF.lpstrFile = szFileName;
	stOF.nMaxFile = MAX_PATH;
	stOF.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST;




	if (GetOpenFileName(&stOF))		//���û�ѡ��򿪵��ļ�
	{
		hFile = CreateFile(szFileName, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE,
			NULL, OPEN_EXISTING, FILE_ATTRIBUTE_ARCHIVE, NULL);
		if (hFile != INVALID_HANDLE_VALUE)
		{
			dwFileSize = GetFileSize(hFile, NULL);//��ȡ�ļ���С
			if (dwFileSize)
			{
				hMapFile = CreateFileMapping(hFile, NULL, PAGE_READONLY, 0, 0, NULL);//�ڴ�ӳ���ļ�
				if (hMapFile)
				{
					lpMemory = (PTCHAR)MapViewOfFile(hMapFile, FILE_MAP_READ, 0, 0, 0);//����ļ����ڴ��ӳ����ʼλ��
					if (lpMemory)
					{
						if (((PIMAGE_DOS_HEADER)lpMemory)->e_magic == IMAGE_DOS_SIGNATURE)//�ж��Ƿ���MZ����
						{
							lpMem = lpMemory + ((PIMAGE_DOS_HEADER)lpMemory)->e_lfanew;
							if (((PIMAGE_NT_HEADERS)lpMem)->Signature == IMAGE_NT_SIGNATURE)//�ж��Ƿ���PE����
							{
								//����Ϊֹ�����ļ�����֤�Ѿ���ɡ�ΪPE�ṹ�ļ�
								
								wsprintf(szBuffer, szOut1, szFileName);
								_appendInfo(szBuffer);

								//��ʾ��Դ����Ϣ
								_getResource(lpMemory, lpMem);
							}
							else
							{
								MessageBox(hWinMain, TEXT("����ļ�����PE��ʽ���ļ�!"), NULL, MB_OK);
							}
						}
						else
						{
							MessageBox(hWinMain, TEXT("����ļ�����PE��ʽ���ļ�!"), NULL, MB_OK);
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