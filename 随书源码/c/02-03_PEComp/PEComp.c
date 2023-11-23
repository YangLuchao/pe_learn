#include <windows.h>
#include <Richedit.h>
#include <Commctrl.h>
#include "resource.h"


HINSTANCE hInstance;
DWORD dwCount;

HWND hWinEdit;	//���ı�����


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
	SendMessage(hWinMain, WM_SETICON, ICON_BIG, (LPARAM)hIcon);//Ϊ��������ͼ��
	SendMessage(hWinEdit, EM_SETTEXTMODE, TM_PLAINTEXT, 0);//���ñ༭�ؼ�

	RtlZeroMemory(&stCf, sizeof(stCf));
	stCf.cbSize = sizeof(stCf);
	stCf.yHeight = 10 * 20;
	stCf.dwMask = CFM_FACE | CFM_SIZE | CFM_BOLD;
	lstrcpy(stCf.szFaceName, szFont);
	SendMessage(hWinEdit, EM_SETCHARFORMAT, 0, (LPARAM)&stCf);
	SendMessage(hWinEdit, EM_EXLIMITTEXT, 0, -1);
}

/*
 ���ListView�е�����
 ɾ�����е��к����е���
*/
void _ListViewClear(HWND _hWinView)
{
	SendMessage(_hWinView, LVM_DELETEALLITEMS, 0, 0);

	while (SendMessage(_hWinView, LVM_DELETECOLUMN, 0, 0)) {}
}


/*
��ListView������һ����
���룺_dwColumn = ���ӵ��б��
_dwWidth = �еĿ��
_lpszHead = �еı����ַ���
*/
void _ListViewAddColumn(HWND _hWinView, DWORD _dwColumn, DWORD _dwWidth, PTCHAR _lpszHead)
{
	LV_COLUMN stLVC;

	RtlZeroMemory(&stLVC, sizeof(LV_COLUMN));
	stLVC.mask = LVCF_TEXT | LVCF_WIDTH | LVCF_FMT;
	stLVC.fmt = LVCFMT_LEFT;
	stLVC.pszText = _lpszHead;
	stLVC.cx = _dwWidth;
	stLVC.iSubItem = _dwColumn;
	SendMessage(_hWinView, LVM_INSERTCOLUMN, _dwColumn, (LPARAM)&stLVC);
}

/*
��ʼ��������
*/
void _clearResultView(HWND hProcessModuleTable)
{
	_ListViewClear(hProcessModuleTable);

	//��ӱ�ͷ
	_ListViewAddColumn(hProcessModuleTable, 1, 200, TEXT("PE���ݽṹ����ֶ�"));
	_ListViewAddColumn(hProcessModuleTable, 2, 222, TEXT("�ļ�1��ֵ(H)"));
	_ListViewAddColumn(hProcessModuleTable, 3, 222, TEXT("�ļ�2��ֵ(H)"));

	dwCount = 0;
}


void _GetListViewItem(HWND _hWinView, DWORD _dwLine, DWORD  _dwCol, PTCHAR _lpszText)
{
	LV_ITEM stLVI;


	RtlZeroMemory(&stLVI, sizeof(LV_ITEM));
	RtlZeroMemory(_lpszText, 512);

	stLVI.cchTextMax = 512;
	stLVI.mask = LVIF_TEXT;
	stLVI.pszText = _lpszText;
	stLVI.iSubItem = _dwCol;
	SendMessage(_hWinView, LVM_GETITEMTEXT, _dwLine, (LPARAM)&stLVI);
}


int _MemCmp(PTCHAR _lp1, PTCHAR _lp2, int  _size)
{
	DWORD dwResult = 0;

	for (int i = 0; i < _size; ++i)
	{
		if (_lp1[i] != _lp2[i])
		{
			dwResult = 1;
			break;
		}
	}
	return dwResult;
}



/*
��ListView������һ�У����޸�һ����ĳ���ֶε�����
���룺_dwItem = Ҫ�޸ĵ��еı��
_dwSubItem = Ҫ�޸ĵ��ֶεı�ţ�-1��ʾ�����µ��У�>=1��ʾ�ֶεı��
*/
DWORD _ListViewSetItem(HWND _hWinView, DWORD _dwItem, DWORD _dwSubItem, PTCHAR _lpszText)
{
	LV_ITEM stLVI;


	RtlZeroMemory(&stLVI, sizeof(LV_ITEM));
	stLVI.cchTextMax = lstrlen(_lpszText);
	stLVI.mask = LVIF_TEXT;
	stLVI.pszText = _lpszText;
	stLVI.iItem = _dwItem;
	stLVI.iSubItem = _dwSubItem;

	if (_dwSubItem == -1)
	{
		stLVI.iSubItem = 0;
		return SendMessage(_hWinView, LVM_INSERTITEM, 0, (LPARAM)&stLVI);
	}
	else
	{
		return SendMessage(_hWinView, LVM_SETITEM, 0, (LPARAM)&stLVI);
	}
}



/*
* ��_lpSZλ�ô�_Size���ֽ�ת��Ϊ16���Ƶ��ַ���
* szBuffer��Ϊת������ַ���
*/
void _Byte2Hex(PTCHAR _lpSZ, PTCHAR szBuffer, int _Size)
{
	TCHAR szBuf[4];

	for (int i = 0; i < _Size; ++i)
	{
		wsprintf(szBuf, TEXT("%02X "), (TBYTE)_lpSZ[i]);
		lstrcat(szBuffer, szBuf);
	}
}

// ���һ��չʾ
void _addLine(HWND hProcessModuleTable, PTCHAR _lpSZ, PTCHAR _lpSP1, PTCHAR _lpSP2, int _Size)
{
	TCHAR szBuffer[256];
	// �ڱ�������һ��
	dwCount = _ListViewSetItem(hProcessModuleTable, dwCount, -1, _lpSZ); // �ڱ����������һ��
	_ListViewSetItem(hProcessModuleTable, dwCount, 0, _lpSZ);//��ʾ�ֶ���

	//��ָ���ֶΰ���ʮ��������ʾ����ʽ��һ���ֽ�+һ���ո�
	RtlZeroMemory(szBuffer, 256);
	// ���ֽ�ת��Ϊ16����
	_Byte2Hex(_lpSP1, szBuffer, _Size);
	_ListViewSetItem(hProcessModuleTable, dwCount, 1, szBuffer);//��һ���ļ��е�ֵ

	RtlZeroMemory(szBuffer, 256);
	_Byte2Hex(_lpSP2, szBuffer, _Size);
	_ListViewSetItem(hProcessModuleTable, dwCount, 2, szBuffer);//�ڶ����ļ��е�ֵ
}


/*
* ����dosͷ��Ϣ
* IMAGE_DOS_HEADERͷ��Ϣ
*/
void _Header1(HWND hProcessModuleTable, PTCHAR lpMemory, PTCHAR lpMemory1)
{
	// dosͷ�ṹÿ��������ռ�ֽ���
	int offbuf[19] = { 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 8, 2, 2, 20, 4 };
	// dosͷÿ�����Ե�����
	TCHAR szRec[19][30] = { TEXT("IMAGE_DOS_HEADER.e_magic"),	// DOSͷ��ʶ
						   TEXT("IMAGE_DOS_HEADER.e_cblp"),		// 
						   TEXT("IMAGE_DOS_HEADER.e_cp"),
						   TEXT("IMAGE_DOS_HEADER.e_crlc"),
						   TEXT("IMAGE_DOS_HEADER.e_cparhdr"),
						   TEXT("IMAGE_DOS_HEADER.e_minalloc"),
						   TEXT("IMAGE_DOS_HEADER.e_maxalloc"),
						   TEXT("IMAGE_DOS_HEADER.e_ss"),
						   TEXT("IMAGE_DOS_HEADER.e_sp"),
						   TEXT("IMAGE_DOS_HEADER.e_csum"),
						   TEXT("IMAGE_DOS_HEADER.e_ip"),
						   TEXT("IMAGE_DOS_HEADER.e_cs"),
						   TEXT("IMAGE_DOS_HEADER.e_lfarlc"),
						   TEXT("IMAGE_DOS_HEADER.e_ovno"),
						   TEXT("IMAGE_DOS_HEADER.e_res"),
						   TEXT("IMAGE_DOS_HEADER.e_oemid"),
						   TEXT("IMAGE_DOS_HEADER.e_oeminfo"),
						   TEXT("IMAGE_DOS_HEADER.e_res2"),
						   TEXT("IMAGE_DOS_HEADER.e_lfanew"),// PEͷ���ƫ��
	};

	for (int i = 0, off = 0; i < 19; ++i)
	{
		// ���һ��չʾ
		// �õ���Ӧ���Ժ���ӵ������
		_addLine(hProcessModuleTable, szRec[i], lpMemory + off, lpMemory1 + off, offbuf[i]);
		// ƫ��+1
		off += offbuf[i];
	}
}


/*
* IMAGE_DOS_HEADERͷ��Ϣ
* ����PEͷ
*/
void _Header2(HWND hProcessModuleTable, PTCHAR lpMemory, PTCHAR lpMemory1)
{
	// peͷÿ������λ�ü���ռ�ֽ���
	int offbuf[70] = { 4, 2, 2, 4, 4, 4, 2, 2, 2, 1, 1, 4, 4, 4, 4, 4, 4, 4, 4, 4, 2, 2, 2, 2, 2, 2,
		4, 4, 4, 4, 2, 2, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
		4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4 };
	// peͷÿ�����Ե�����
	TCHAR szRec[70][60] = { TEXT("IMAGE_NT_HEADERS.Signature"),	// PEͷ��ʶ 50 45 00 00 
							// �ļ�ͷ
							TEXT("IMAGE_FILE_HEADER.Machine"),	// ����ƽ̨
							TEXT("IMAGE_FILE_HEADER.NumberOfSections"),//pe�нڵ�����
							TEXT("IMAGE_FILE_HEADER.TimeDateStamp"),// �ļ��������ں�ʱ��
							TEXT("IMAGE_FILE_HEADER.PointerToSymbolTable"),//ָ����ű�
							TEXT("IMAGE_FILE_HEADER.NumberOfSymbols"),// ���ű��з�������
							TEXT("IMAGE_FILE_HEADER.SizeOfOptionalHeader"),//��չͷ�ĳ���
							TEXT("IMAGE_FILE_HEADER.Characteristics"),// �ļ�������
							// ��չͷ
							TEXT("IMAGE_OPTIONAL_HEADER32.Magic"),	// ħ����
							TEXT("IMAGE_OPTIONAL_HEADER32.MajorLinkerVersion"),//��������汾
							TEXT("IMAGE_OPTIONAL_HEADER32.MinorLinkerVersion"),//������С�汾
							TEXT("IMAGE_OPTIONAL_HEADER32.SizeOfCode"),	// ������ܴ�С
							TEXT("IMAGE_OPTIONAL_HEADER32.SizeOfInitializedData"),//�ѳ�ʼ���ڴ�С
							TEXT("IMAGE_OPTIONAL_HEADER32.SizeOfUninitializedData"),//δ��ʼ���ڴ�С
							TEXT("IMAGE_OPTIONAL_HEADER32.AddressOfEntryPoint"),//����ִ�����RAV
							TEXT("IMAGE_OPTIONAL_HEADER32.BaseOfCode"),//�������ʼRVA
							TEXT("IMAGE_OPTIONAL_HEADER32.BaseOfData"),//���ݽ���ʼRVA
							TEXT("IMAGE_OPTIONAL_HEADER32.ImageBase"),//����Ľ���װ�ص�ַ��exe:0040 0000 dll:0010 0000
							TEXT("IMAGE_OPTIONAL_HEADER32.SectionAlignment"),//�ڴ��ж�������
							TEXT("IMAGE_OPTIONAL_HEADER32.FileAlignment"),// �ļ��ж�������
							TEXT("IMAGE_OPTIONAL_HEADER32.MajorOperatingSystemVersion"),//����ϵͳ��汾��
							TEXT("IMAGE_OPTIONAL_HEADER32.MinorOperatingSystemVersion"),//����ϵͳС�汾��
							TEXT("IMAGE_OPTIONAL_HEADER32.MajorImageVersion"),//��PE�Ĵ�汾��
							TEXT("IMAGE_OPTIONAL_HEADER32.MinorImageVersion"),//��PE��С�汾��
							TEXT("IMAGE_OPTIONAL_HEADER32.MajorSubsystemVersion"),//������ϵͳ�Ĵ�汾��,
							TEXT("IMAGE_OPTIONAL_HEADER32.MinorSubsystemVersion"),// ������ϵͳ��С�汾��
							TEXT("IMAGE_OPTIONAL_HEADER32.Win32VersionValue"),// δ�ã�����
							TEXT("IMAGE_OPTIONAL_HEADER32.SizeOfImage"),// �ڴ�������PE����Ĵ�С
							TEXT("IMAGE_OPTIONAL_HEADER32.SizeOfHeaders"),// ����ͷ+�ڱ�Ĵ�С
							TEXT("IMAGE_OPTIONAL_HEADER32.CheckSum"),//У���
							TEXT("IMAGE_OPTIONAL_HEADER32.Subsystem"),// �ļ�����ϵͳ
							TEXT("IMAGE_OPTIONAL_HEADER32.DllCharacteristics"),// dll���ļ�����
							TEXT("IMAGE_OPTIONAL_HEADER32.SizeOfStackReserve"),//��ʼ��ʱ��ջ��С
							TEXT("IMAGE_OPTIONAL_HEADER32.SizeOfStackCommit"),// ��ʼ��ʱʵ���ύ��ջ��С
							TEXT("IMAGE_OPTIONAL_HEADER32.SizeOfHeapReserve"),// ��ʼ��ʱ�����ĶѴ�С
							TEXT("IMAGE_OPTIONAL_HEADER32.SizeOfHeapCommit"),// ��ʼ��ʱʵ���ύ�ĶѴ�С
							TEXT("IMAGE_OPTIONAL_HEADER32.LoaderFlags"),// ����
							TEXT("IMAGE_OPTIONAL_HEADER32.NumberOfRvaAndSizes"),// ����Ŀ¼�������һ�㶼��16��
							// ����Ŀ¼��
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(Export)"),// ������RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(Export)"),// �������С
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(Import)"),// �����RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(Import)"),// ������С
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(Resource)"),// ��Դ��RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(Resource)"),// ��Դ���С
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(Exception)"),// �쳣��RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(Exception)"),// �쳣���С
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(Security)"),// ��ȫ��RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(Security)"),// ��ȫ���С
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(BaseReloc)"),// �ض����RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(BaseReloc)"),// �ض�����С
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(Debug)"),// ���Ա�RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(Debug)"),// ���Ա��С
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(Architecture)"),//��Ȩ��RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(Architecture)"),// ��Ȩ���С
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(GlobalPTR)"),// ȫ��ָ���RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(GlobalPTR)"),// ȫ��ָ����С
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(TLS)"),// �̱߳��ش洢��RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(TLS)"),// �̱߳��ش洢���С
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(Load_Config)"),// �������ñ�RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(Load_Config)"),// �������ñ��С
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(Bound_Import)"),// �󶨵����RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(Bound_Import)"),// �󶨵�����С
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(IAT)"),// IAT�������ַ����RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(IAT)"),// IAT(�����ַ��)��С
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(Delay_Import)"),// �ӳٵ����RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(Delay_Import)"),// �ӳٵ�����С
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(Com_Descriptor)"),// CLR��RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(Com_Descriptor)"),// CLR���С
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(Reserved)"),// Ԥ����RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(Reserved)") };// Ԥ�����С

	for (int i = 0, off = 0; i < 70; ++i)
	{
		// ��ȡÿ��Ľ����ת��16����������ؼ�
		_addLine(hProcessModuleTable, szRec[i], lpMemory + off, lpMemory1 + off, offbuf[i]);
		// ƫ��+1
		off += offbuf[i];
	}
}


/*
* ����ڱ�
*/
void _Header3(HWND hProcessModuleTable, PTCHAR lpMemory, PTCHAR lpMemory1, DWORD _dwValue)
{
	int offbuf[10] = { 8, 4, 4, 4, 4, 4, 4, 2, 2, 4 };
	TCHAR szBuffer[256];
	TCHAR szRec[10][50] = { TEXT("IMAGE_SECTION_HEADER%d.Name1"),// ��������
							TEXT("IMAGE_SECTION_HEADER%d.VirtualSize"),// �����ߴ�
							TEXT("IMAGE_SECTION_HEADER%d.VirtualAddress"),// ����RVA��ַ
							TEXT("IMAGE_SECTION_HEADER%d.SizeOfRawData"),//���ļ��ж����Ĵ�С
							TEXT("IMAGE_SECTION_HEADER%d.PointerToRawData"),//���ļ��е�ƫ��
							TEXT("IMAGE_SECTION_HEADER%d.PointerToRelocations"),//��OBJ��ʹ��
							TEXT("IMAGE_SECTION_HEADER%d.PointerToLinenumbers"),// �кű�λ��(������)
							TEXT("IMAGE_SECTION_HEADER%d.NumberOfRelocations"),// ��OBJ��ʹ��
							TEXT("IMAGE_SECTION_HEADER%d.NumberOfLinenumbers"),// �кű����к�����
							TEXT("IMAGE_SECTION_HEADER%d.Characteristics") };// ������


	for (int i = 0, off = 0; i < 10; ++i)
	{
		wsprintf(szBuffer, szRec[i], _dwValue);
		_addLine(hProcessModuleTable, szBuffer, lpMemory + off, lpMemory1 + off, offbuf[i]);
		off += offbuf[i];
	}
}




/*
��PE�ļ�������
*/
void _openFile(HWND hWinMain, HWND hProcessModuleTable, PTCHAR szFileNameOpen1, PTCHAR szFileNameOpen2)
{
	HANDLE hFile;
	HANDLE hMapFile = NULL;
	HANDLE hFile1;
	HANDLE hMapFile1 = NULL;
	DWORD dwFileSize, dwFileSize1;
	static LPVOID lpMemory, lpMemory1;



	// �����ļ����
	hFile = CreateFile(szFileNameOpen1, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL,
		OPEN_EXISTING, FILE_ATTRIBUTE_ARCHIVE, NULL);
	// �ж��Ƿ�Ƿ�
	if (hFile != INVALID_HANDLE_VALUE)
	{
		// ��ȡ�ļ���С
		dwFileSize = GetFileSize(hFile, NULL);
		if (dwFileSize)// �ж��ļ�����
		{
			// �����ļ��ڴ�ӳ��
			hMapFile = CreateFileMapping(hFile, NULL, PAGE_READONLY, 0, 0, NULL);// �ڴ�ӳ���ļ�
			if (hMapFile)
			{
				// ��ȡ�ļ�ӳ����ʼƫ��
				lpMemory = MapViewOfFile(hMapFile, FILE_MAP_READ, 0, 0, 0);
				// �ж��Ƿ�ΪPE�ļ�
				if (((PIMAGE_DOS_HEADER)lpMemory)->e_magic != IMAGE_DOS_SIGNATURE)//�ж��Ƿ���MZ����
				{
				_ErrFormat:
					MessageBox(hWinMain, TEXT("����ļ�����PE��ʽ���ļ�!"), NULL, MB_OK);
					UnmapViewOfFile(lpMemory);
					CloseHandle(hMapFile);
					CloseHandle(hFile);
					return;
				}
				if (((PIMAGE_NT_HEADERS)((PTCHAR)lpMemory +
					((PIMAGE_DOS_HEADER)lpMemory)->e_lfanew))->Signature !=
					IMAGE_NT_SIGNATURE)//�ж��Ƿ���PE����
				{
					goto _ErrFormat;
				}
			}
		}
	}


	// �����ļ�1
	hFile1 = CreateFile(szFileNameOpen2, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL,
		OPEN_EXISTING, FILE_ATTRIBUTE_ARCHIVE, NULL);
	// �ж��ļ�1�Ƿ�Ƿ�
	if (hFile1 != INVALID_HANDLE_VALUE)
	{
		// ��ȡ�ļ�1��С
		dwFileSize1 = GetFileSize(hFile1, NULL);
		if (dwFileSize1)
		{
			// �����ڴ�ӳ��
			hMapFile1 = CreateFileMapping(hFile1, NULL, PAGE_READONLY, 0, 0, NULL);// �ڴ�ӳ���ļ�
			if (hMapFile1)
			{
				// ��ȡ�ڴ�ӳ����ʼ��ַ
				lpMemory1 = MapViewOfFile(hMapFile1, FILE_MAP_READ, 0, 0, 0);
				// �ж��Ƿ�ΪPE�ļ�
				if (((PIMAGE_DOS_HEADER)lpMemory1)->e_magic != IMAGE_DOS_SIGNATURE)//�ж��Ƿ���MZ����
				{
				_ErrFormat1:
					MessageBox(hWinMain, TEXT("����ļ�����PE��ʽ���ļ�!"), NULL, MB_OK);
					UnmapViewOfFile(lpMemory1);
					CloseHandle(hMapFile1);
					CloseHandle(hFile1);
					return;
				}

				if (((PIMAGE_NT_HEADERS)((PTCHAR)lpMemory1 +
					((PIMAGE_DOS_HEADER)lpMemory1)->e_lfanew))->Signature !=
					IMAGE_NT_SIGNATURE)//�ж��Ƿ���PE����
				{
					goto _ErrFormat1;
				}
			}
		}
	}

	/*
	����Ϊֹ�������ڴ��ļ���ָ���Ѿ���ȡ���ˡ�
	lpMemory��lpMemory1�ֱ�ָ�������ļ�ͷ
	�����Ǵ�����ļ�ͷ��ʼ���ҳ������ݽṹ���ֶ�ֵ�����бȽϡ�
	*/
	// ����dosͷ
	_Header1(hProcessModuleTable, (PTCHAR)lpMemory, (PTCHAR)lpMemory1);

	// ����ָ��ָ��PE�ļ�ͷ
	(PTCHAR)lpMemory += ((PIMAGE_DOS_HEADER)lpMemory)->e_lfanew;
	(PTCHAR)lpMemory1 += ((PIMAGE_DOS_HEADER)lpMemory1)->e_lfanew;
	// ����NTͷ
	_Header2(hProcessModuleTable, (PTCHAR)lpMemory, (PTCHAR)lpMemory1);


	// �ڵ�����
	WORD dNum, dNum1, dNum2;
	dNum1 = ((PIMAGE_NT_HEADERS)lpMemory)->FileHeader.NumberOfSections;
	dNum2 = ((PIMAGE_NT_HEADERS)lpMemory1)->FileHeader.NumberOfSections;
	// �ĸ�Ӧ�ýڶ����ĸ�����ֵ
	dNum = dNum1 > dNum2 ? dNum1 : dNum2;

	// ����ָ��ָ��ڱ�
	(PTCHAR)lpMemory += sizeof(IMAGE_NT_HEADERS);
	(PTCHAR)lpMemory1 += sizeof(IMAGE_NT_HEADERS);

	DWORD _dwValue = 1; //�����
	while (dNum--)
	{
		// ����ڱ�
		_Header3(hProcessModuleTable, (PTCHAR)lpMemory, (PTCHAR)lpMemory1, _dwValue++);

		// ����ָ��ָ����һ���ڱ�
		(PTCHAR)lpMemory += sizeof(IMAGE_SECTION_HEADER);
		(PTCHAR)lpMemory1 += sizeof(IMAGE_SECTION_HEADER);
	}

	// ж�ؾ���
	UnmapViewOfFile(lpMemory);
	// �رվ���
	CloseHandle(hMapFile);
	// �ر��ļ�
	CloseHandle(hFile);

	UnmapViewOfFile(lpMemory1);
	CloseHandle(hMapFile1);
	CloseHandle(hFile1);
}

/*
�������ļ�
*/
void _OpenFile1(HWND hWinMain, HWND hText1, PTCHAR szFileNameOpen1)
{
	OPENFILENAME stOF;


	RtlZeroMemory(&stOF, sizeof(stOF));
	stOF.lStructSize = sizeof(stOF);
	stOF.hwndOwner = hWinMain;
	stOF.hInstance = hInstance;
	stOF.lpstrFilter = TEXT("Excutable Files\0*.exe;*.com\0\0");
	stOF.lpstrFile = szFileNameOpen1;
	stOF.nMaxFile = MAX_PATH;
	stOF.Flags = OFN_FILEMUSTEXIST | OFN_HIDEREADONLY | OFN_PATHMUSTEXIST;
	if (GetOpenFileName(&stOF))//��ʾ�����ļ����Ի���
	{
		SetWindowText(hText1, szFileNameOpen1);
	}

}


/*
�������ļ�
*/
void _OpenFile2(HWND hWinMain, HWND hText2, PTCHAR szFileNameOpen2)
{
	OPENFILENAME stOF;


	RtlZeroMemory(&stOF, sizeof(stOF));
	stOF.lStructSize = sizeof(stOF);
	stOF.hwndOwner = hWinMain;
	stOF.hInstance = hInstance;
	stOF.lpstrFilter = TEXT("Excutable Files\0*.exe;*.com\0\0");
	stOF.lpstrFile = szFileNameOpen2;
	stOF.nMaxFile = MAX_PATH;
	stOF.Flags = OFN_FILEMUSTEXIST | OFN_HIDEREADONLY | OFN_PATHMUSTEXIST;
	if (GetOpenFileName(&stOF))//��ʾ�����ļ����Ի���
	{
		SetWindowText(hText2, szFileNameOpen2);
	}

}






INT_PTR CALLBACK _resultProcMain(HWND hProcessModuleDlg, UINT wMsg, WPARAM wParam, LPARAM lParam)
{
	static HWND hWinMain, hProcessModuleTable, hText1, hText2;
	TCHAR bufTemp1[0x200], bufTemp2[0x200];
	static TCHAR szFileNameOpen1[MAX_PATH], szFileNameOpen2[MAX_PATH];

	switch (wMsg)
	{
	case WM_CLOSE:
		EndDialog(hProcessModuleDlg, 0);
		break;

	case WM_INITDIALOG:			//��ʼ��
		hWinMain = (HWND)lParam;

		hProcessModuleTable = GetDlgItem(hProcessModuleDlg, IDC_MODULETABLE);
		hText1 = GetDlgItem(hProcessModuleDlg, ID_TEXT1);
		hText2 = GetDlgItem(hProcessModuleDlg, ID_TEXT2);

		//���������
		SendMessage(hProcessModuleTable, LVM_SETEXTENDEDLISTVIEWSTYLE, 0,
			LVS_EX_GRIDLINES | LVS_EX_FULLROWSELECT);
		ShowWindow(hProcessModuleTable, SW_SHOW);

		_clearResultView(hProcessModuleTable);//��ձ������
		break;

	case WM_NOTIFY:
		if (((NMHDR*)lParam)->hwndFrom == hProcessModuleTable)//���ĸ��ؼ�״̬
		{
			if (((NMHDR*)lParam)->code == NM_CUSTOMDRAW)//�滭ʱ
			{
				if (((NMLVCUSTOMDRAW*)lParam)->nmcd.dwDrawStage == CDDS_PREPAINT)
				{
					SetWindowLong(hProcessModuleDlg, DWL_MSGRESULT, CDRF_NOTIFYITEMDRAW);
				}
				else if (((NMLVCUSTOMDRAW*)lParam)->nmcd.dwDrawStage == CDDS_ITEMPREPAINT)
				{
					//��ÿһ��Ԫ������Ԥ��ʱ���ж����е�ֵ�Ƿ�һ��
					//���һ�£����ı��ı���ɫ����Ϊǳ��ɫ�������ɫ
					_GetListViewItem(hProcessModuleTable, ((NMLVCUSTOMDRAW*)lParam)->nmcd.dwItemSpec,
						1, bufTemp1);
					_GetListViewItem(hProcessModuleTable, ((NMLVCUSTOMDRAW*)lParam)->nmcd.dwItemSpec,
						2, bufTemp2);
					if (_MemCmp(bufTemp1, bufTemp2, lstrlen(bufTemp1)))
					{
						((NMLVCUSTOMDRAW*)lParam)->clrTextBk = 0xa0a0ff;
					}
					else
					{
						((NMLVCUSTOMDRAW*)lParam)->clrTextBk = 0xffffff;
					}
					SetWindowLong(hProcessModuleDlg, DWL_MSGRESULT, CDRF_DODEFAULT);
				}
			}
		}
		break;

	case WM_COMMAND:			//�˵�
		switch (LOWORD(wParam))
		{
		case IDC_OK:			//ˢ��
			_openFile(hWinMain, hProcessModuleTable, szFileNameOpen1, szFileNameOpen2);
			break;

		case IDC_BROWSE1:			//�û�ѡ���һ���ļ�
			_OpenFile1(hWinMain, hText1, szFileNameOpen1);
			break;
		case IDC_BROWSE2:			//�û�ѡ��ڶ����ļ�
			_OpenFile2(hWinMain, hText2, szFileNameOpen2);
			break;
		}
		break;

	default:
		return FALSE;
	}

	return TRUE;


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

		case IDM_OPEN:			//��PE�ԱȶԻ���
			DialogBoxParam(hInstance, MAKEINTRESOURCE(RESULT_MODULE), hWnd,
				_resultProcMain, (LPARAM)hWnd);
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
	InitCommonControl();
	hRichEdit = LoadLibrary(TEXT("RichEd20.dll"));
	DialogBoxParam(hInstance, MAKEINTRESOURCE(DLG_MAIN), NULL, _ProcDlgMain, (LPARAM)NULL);
	FreeLibrary(hRichEdit);
	return 0;
}