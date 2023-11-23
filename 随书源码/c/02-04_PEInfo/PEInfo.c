#include <Windows.h>
#include<Richedit.h>
#include "resource.h"


HINSTANCE hInstance;
HWND hWinEdit;

DWORD dwFlag = 0xffffffff;


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
* ���ڴ��л�ȡPE�ļ�����Ҫ��Ϣ
* NTͷ�ͽڱ�����Ϣ
* _lpPeHead�� peͷ��ʼƫ�Ƶ�ַ
* szFileName�� �ļ�����ʼƫ�Ƶ�ַ
*/
void _getMainInfo(PTCHAR  _lpPeHead, PTCHAR szFileName)
{
	// NTͷ�ṹ
	PIMAGE_NT_HEADERS pImageNtHeaders;
	// �ڱ���ṹ
	PIMAGE_SECTION_HEADER pImageSectionHeader;
	TCHAR szBuffer[1024];
	TCHAR szSecName[16];
	WORD dNumberOfSections;
	TCHAR szMsg[] = TEXT("�ļ�����%s\n"
						 "-----------------------------------------\n\n\n"
						 "����ƽ̨��      0x%04x  (014c:Intel 386   014dh:Intel 486  014eh:Intel 586)\n"
						 "�ڵ�������      %d\n"
						 "�ļ����ԣ�      0x%04x  (��β-��ֹ�ദ����-DLL-ϵͳ�ļ�-��ֹ��������-��ֹ��������-�޵���-32λ-Сβ-X-X-X-�޷���-����-��ִ��-���ض�λ)\n"
						 "����װ�����ַ��  0x%08x\n"
						 "�ļ�ִ�����(RVA��ַ)��  0x%04x\n\n");

	TCHAR szMsgSec[] = TEXT("---------------------------------------------------------------------------------\n"
							"�ڵ����Բο���\n"
							"  00000020h  ��������\n"
							"  00000040h  �����Ѿ���ʼ�������ݣ���.const\n"
							"  00000080h  ����δ��ʼ�����ݣ��� .data?\n"
							"  02000000h  �����ڽ��̿�ʼ�Ժ󱻶�������.reloc\n"
							"  04000000h  �������ݲ���������\n"
							"  08000000h  �������ݲ��ᱻ����������\n"
							"  10000000h  ���ݽ�����ͬ���̹���\n"
							"  20000000h  ��ִ��\n"
							"  40000000h  �ɶ�\n"
							"  80000000h  ��д\n"
							"�����Ĵ����һ��Ϊ��60000020h,���ݽ�һ��Ϊ��c0000040h��������һ��Ϊ��40000040h\n"
							"---------------------------------------------------------------------------------\n\n\n"
							"�ڵ�����  δ����ǰ��ʵ����  �ڴ��е�ƫ��(������) �ļ��ж����ĳ��� �ļ��е�ƫ��  �ڵ�����\n"
							"---------------------------------------------------------------------------------------------\n");

	TCHAR szFmtSec[] = TEXT("%s     %08x         %08x              %08x           %08x     %08x\n\n\n");

	pImageNtHeaders = (PIMAGE_NT_HEADERS)_lpPeHead;
	//�ļ���,����ƽ̨,�ڵ�����,�ļ�������,����װ��ĵ�ַ,��ڵ�
	wsprintf(szBuffer, szMsg, szFileName, 
		// ����ƽ̨
		pImageNtHeaders->FileHeader.Machine,
		// �нڵ�����
		pImageNtHeaders->FileHeader.NumberOfSections, 
		// �ļ�������
		pImageNtHeaders->FileHeader.Characteristics,
		// ����Ľ���װ�ص�ַ
		pImageNtHeaders->OptionalHeader.ImageBase, 
		// ����ִ�����
		pImageNtHeaders->OptionalHeader.AddressOfEntryPoint);

	SetWindowText(hWinEdit, szBuffer);//��ӵ��༭����

	// ��ʾÿ���ڵ���Ҫ��Ϣ
	_appendInfo(szMsgSec);

	// �ڵ�����
	dNumberOfSections = pImageNtHeaders->FileHeader.NumberOfSections;
	// NTͷ�ṹ����+1��ƫ��Ų���˽ڱ�����ʼ��ַ�����õ�ַǿתΪ�ڱ���ṹ
	pImageSectionHeader = (PIMAGE_SECTION_HEADER)(pImageNtHeaders + 1);

	while (dNumberOfSections--)
	{
		// ��ȡ�ڵ����ƣ�ע�ⳤ��Ϊ8�����Ʋ�����0��β
		RtlZeroMemory(szSecName, sizeof(szSecName));
		for (int i = 0; i < 8; ++i)
		{
			if (pImageSectionHeader->Name[i])
			{
				// ����
				szSecName[i] = pImageSectionHeader->Name[i];
			}
			else
			{
				szSecName[i] = ' ';//�������Ϊ0������ʾΪ�ո�
			}
		}

		// ��ȡ�ڵ���Ҫ��Ϣ
		wsprintf(szBuffer, szFmtSec, szSecName, 
			// �ڴ�С
			pImageSectionHeader->Misc.VirtualSize,
			// ��RVA
			pImageSectionHeader->VirtualAddress, 
			// �����ļ��ж����Ĵ�С
			pImageSectionHeader->SizeOfRawData,
			// ���ļ��е�ƫ��
			pImageSectionHeader->PointerToRawData,
			// ������
			pImageSectionHeader->Characteristics);
		_appendInfo(szBuffer);

		++pImageSectionHeader;//ָ����һ���ڱ���
	}
}



/*
���ڴ�ƫ����RVAת��Ϊ�ļ�ƫ��
	RVA�л�ֵFOA
	lp_FileHead �ļ�ͷ����ʼ��ַ
	_dwRVA		��������Ҫӳ���FOA��RVA
*/
DWORD  _RVAToOffset(PTCHAR _lpFileHead, DWORD _dwRVA)
{
	// NTͷ�ṹ
	PIMAGE_NT_HEADERS pImageNtHeaders;
	// �ڱ���ṹ
	PIMAGE_SECTION_HEADER pImageSectionHeader;
	// �ڵ�����
	WORD dNumberOfSections;
	
	// ָ��Ų��PEͷ��ͷ����������NTͷ�ṹ
	pImageNtHeaders = (PIMAGE_NT_HEADERS)(_lpFileHead + ((PIMAGE_DOS_HEADER)_lpFileHead)->e_lfanew);
	// NTͷ+1��ַŲ���ڱ������ýڱ���ṹ
	pImageSectionHeader = (PIMAGE_SECTION_HEADER)(pImageNtHeaders + 1);
	// �ж��ٸ���
	dNumberOfSections = pImageNtHeaders->FileHeader.NumberOfSections;

	//�����ڱ�
	while (dNumberOfSections--)
	{
		
		if (_dwRVA >= pImageSectionHeader->VirtualAddress && // �����ĵ�ַ��Ҫ���ڽڵ���ʼ��ַ
			// ������ַ��ҪС�ڸýڵĽ�����ַ
			_dwRVA < pImageSectionHeader->VirtualAddress + pImageSectionHeader->SizeOfRawData)//����ýڽ���RVA������Misc����Ҫԭ������Щ�ε�Miscֵ�Ǵ���ģ�
		{
			// ������ַ ��ȥ����ʼ��ַ �ټ��Ͻ����������ļ��е�ƫ�� �͵õ�FOA
			return _dwRVA - pImageSectionHeader->VirtualAddress + pImageSectionHeader->PointerToRawData;
		}
		++pImageSectionHeader;
	}
	return -1;
}


/*
* ��ȡRVA���ڽڵ�����
* _lpFileHead		����ƫ�Ƶ�ַ
* _dwRVA			��Ҫӳ��ΪFOA��RAV
*/
PTCHAR _getRVASectionName(PTCHAR _lpFileHead, DWORD _dwRVA)
{
	// NTͷ�ṹ
	PIMAGE_NT_HEADERS pImageNtHeaders;
	// �ڱ���ṹ
	PIMAGE_SECTION_HEADER pImageSectionHeader;
	// �ڵĸ���
	WORD dNumberOfSections;
	// ����NTͷ�ṹ
	pImageNtHeaders = (PIMAGE_NT_HEADERS)(_lpFileHead + ((PIMAGE_DOS_HEADER)_lpFileHead)->e_lfanew);
	// �����ڱ���ṹ
	pImageSectionHeader = (PIMAGE_SECTION_HEADER)(pImageNtHeaders + 1);
	// ��ȡ�ڵĸ���
	dNumberOfSections = pImageNtHeaders->FileHeader.NumberOfSections;

	while (dNumberOfSections--)
	{
		if (_dwRVA >= pImageSectionHeader->VirtualAddress && // ������ַ����ڽڵ���ʼƫ�Ƶ�ַ
			// ������ַ��С�ڽڵĽ�����ַ
			_dwRVA < pImageSectionHeader->VirtualAddress + pImageSectionHeader->SizeOfRawData)//����ýڽ���RVA������Misc����Ҫԭ������Щ�ε�Miscֵ�Ǵ���ģ�
		{
			// ���ؽڵ�����
			return pImageSectionHeader->Name;
		}
		// ����һ���ڲ���
		++pImageSectionHeader;
	}
	return TEXT("�޷�����");
}


/*
* ��ȡPE�ļ��ĵ����
* �����������Ϣ
* _lpFile�� ����ƫ�Ƶ�ַ
* _lpPeHead��peͷƫ�Ƶ�ַ
*/
void _getImportInfo(PTCHAR _lpFile, PTCHAR  _lpPeHead)
{
	// NTͷ�ṹ
	PIMAGE_NT_HEADERS pImagenNtHeaders;
	DWORD dwVirtualAddress;
	// �����ṹ
	PIMAGE_IMPORT_DESCRIPTOR pImageImportDescriptor;
	TCHAR szBuffer[1024];
	// ��1ָ��ĺ������Ƶ�ַ�ṹ
	PIMAGE_THUNK_DATA pImageThunkData;
	// ��1ָ��ĺ������ƽṹ ������źͺ���������Ϣ
	PIMAGE_IMPORT_BY_NAME pImageImportByName;


	TCHAR szMsg1[] = TEXT("\n\n\n---------------------------------------------------------------------------------------------\n"
							"����������Ľڣ�%s\n"
							"---------------------------------------------------------------------------------------------\n");

	TCHAR szMsgImport[] = TEXT("\n\n����⣺%s\n"
								"-----------------------------\n\n"
								"OriginalFirstThunk  %08x\n"
								"TimeDateStamp       %08x\n"
								"ForwarderChain      %08x\n"
								"FirstThunk          %08x\n"
								"-----------------------------\n\n");


	pImagenNtHeaders = (PIMAGE_NT_HEADERS)_lpPeHead;

	// �����RVA
	dwVirtualAddress = pImagenNtHeaders->OptionalHeader.DataDirectory[1].VirtualAddress;
	if (dwVirtualAddress)// �е����
	{
		// ���㵼��������ļ�ƫ��λ��
		pImageImportDescriptor = (PIMAGE_IMPORT_DESCRIPTOR)(_lpFile +
			// ��ȡ��������ļ��е�ƫ��
			_RVAToOffset(_lpFile, dwVirtualAddress));
		
		// ��ȡ������ַ���ڽڵĽ���
		wsprintf(szBuffer, szMsg1, _getRVASectionName(_lpFile, 
			pImageImportDescriptor->OriginalFirstThunk)); 
		_appendInfo(szBuffer);

		// �жϵ����ĸ��������Ƿ���ֵ�����еĵ����������˳�ѭ��
		while (pImageImportDescriptor->OriginalFirstThunk ||	// ��1
			pImageImportDescriptor->TimeDateStamp ||			// ʱ���
			pImageImportDescriptor->ForwarderChain ||			// ʡ��
			pImageImportDescriptor->Name ||						// ��̬���ӿ���RVA
			pImageImportDescriptor->FirstThunk)					// ��2
		{
			// _lpFile + _RVAToOffset(_lpFile, pImageImportDescriptor->Name �� ����������
			wsprintf(szBuffer, szMsgImport, 
				_lpFile + _RVAToOffset(_lpFile, pImageImportDescriptor->Name),  // ��̬���ӿ���RVA
				pImageImportDescriptor->OriginalFirstThunk,						// ��1
				pImageImportDescriptor->TimeDateStamp,							// ʱ���
				pImageImportDescriptor->ForwarderChain,							// ʡ��
				pImageImportDescriptor->FirstThunk);							// ��2
			_appendInfo(szBuffer);

			// ��ȡIMAGE_THUNK_DATA�б�
			// ��1ƫ�ƺϷ�����Ϊ������1���滻ʧЧ�ĳ���
			if (pImageImportDescriptor->OriginalFirstThunk)
			{
				// ͨ����1��ȡthunk�����б�
				pImageThunkData = (PIMAGE_THUNK_DATA)(_lpFile + 
					_RVAToOffset(_lpFile, pImageImportDescriptor->OriginalFirstThunk));
			}
			else
			{
				// ͨ����2��ȡthunk�����б�
				pImageThunkData = (PIMAGE_THUNK_DATA)(_lpFile +
					_RVAToOffset(_lpFile, pImageImportDescriptor->FirstThunk));
			}
			// *(PDWORD)pImageThunkData ��ָ�룬��ȡthunk�ĵ�ַ
			// ֱ��pImageThunkDataΪ00 00 00 00 Ϊֹ
			while (*(PDWORD)pImageThunkData && dwFlag != 1)//����һ����Զ����������dwFlag != 1,
			{											   //�ñ�־�������������޸ģ���
														   //���ڵ�ʮ�����õ�
				// ����ŵ���
				if (*(PDWORD)pImageThunkData & IMAGE_ORDINAL_FLAG32)
				{
					wsprintf(szBuffer, TEXT("%08u(�޺�����������ŵ���)\n"), 
						*(PDWORD)pImageThunkData & 0xffff);
				}
				else//�����Ƶ���
				{
					// ͨ��thunkӳ�䵽������ź�name�ṹ
					pImageImportByName = (PIMAGE_IMPORT_BY_NAME)
						// ͨ��trunk��ַת��Ϊ�ļ��е�ַ��תΪ������ź�name�ṹ
						(_lpFile + _RVAToOffset(_lpFile, *(PDWORD)pImageThunkData));
					wsprintf(szBuffer, TEXT("%08u         %s\n"), pImageImportByName->Hint,
						pImageImportByName->Name);
				}
				_appendInfo(szBuffer);
				// ������һ������
				++pImageThunkData;
			}
			// ������һ�������
			++pImageImportDescriptor;
		}
	}
	else
	{
		_appendInfo(TEXT("\n\nδ���ָ��ļ��е��뺯��\n\n"));
	}
}



/*
* ��ȡPE�ļ��ĵ�����
* _lpFile:		������ʼƫ�Ƶ�ַ
* _lpPeHead:	peͷ��ʼƫ�Ƶ�ַ
*/
void _getExportInfo(PTCHAR _lpFile, PTCHAR  _lpPeHead)
{
	// NTͷ�ṹ
	PIMAGE_NT_HEADERS pImageNtHeaders;
	DWORD dwVirtualAddress;
	// ������ṹ
	PIMAGE_EXPORT_DIRECTORY pImageExportDirectory;
	TCHAR szBuffer[1024];
	TCHAR ** lpAddressOfNames;// TCHAR���Ͷ���������Ŀ�����ַ�������ʱ������
	PWORD lpAddressOfNameOrdinals; // PWORD�������͵�ָ�룬Ŀ���������͵�����ʱ������
	PDWORD lpAddressOfFunctions;//PDWORDʱ˫�����͵�ָ�룬Ŀ����˫�����͵�����ʱ������
	WORD wIndex;
	DWORD dwNumberOfFunctions, dwNumberOfNames;// �����ֵĺ����ĸ���
	PTCHAR dwFunRaw;// �������ַ���ָ��

	TCHAR szMsgExport[] = TEXT("\n\n\n---------------------------------------------------------------------------------------------\n"
							   "�����������Ľڣ�%s\n"
							   "---------------------------------------------------------------------------------------------\n"
							   "ԭʼ�ļ�����%s\n"
							   "nBase               %08x\n"
							   "NumberOfFunctions   %08x\n"
							   "NuberOfNames        %08x\n"
							   "AddressOfFunctions  %08x\n"
							   "AddressOfNames      %08x\n"
							   "AddressOfNameOrd    %08x\n"
							   "-------------------------------------\n\n"
							   "�������    �����ַ    ������������\n"
							   "-------------------------------------\n");

	// תΪNTͷ
	pImageNtHeaders = (PIMAGE_NT_HEADERS)_lpPeHead;
	// ������RVA
	dwVirtualAddress = pImageNtHeaders->OptionalHeader.DataDirectory[0].VirtualAddress;
	if (dwVirtualAddress)// ������λ�úϷ�
	{
		// ���㵼���������ļ�ƫ��λ��
		pImageExportDirectory = (PIMAGE_EXPORT_DIRECTORY)(_lpFile +
			_RVAToOffset(_lpFile, dwVirtualAddress));

		wsprintf(szBuffer, szMsgExport, 
			_getRVASectionName(_lpFile, pImageExportDirectory->Name),// ����
			_lpFile + _RVAToOffset(_lpFile, pImageExportDirectory->Name),// dll����
			pImageExportDirectory->Base, // ������������ʼ���
			pImageExportDirectory->NumberOfFunctions,// ��������������
			pImageExportDirectory->NumberOfNames, // ���������ֵĺ���������
			pImageExportDirectory->AddressOfFunctions,// �����ĵ�ַ��
			pImageExportDirectory->AddressOfNames, // �������ַ�����ַ
			pImageExportDirectory->AddressOfNameOrdinals);// ������˵�������壬�ú�������λ����
		_appendInfo(szBuffer);

		// �������ֵĵ�ַ��
		lpAddressOfNames = (TCHAR **)(_lpFile + _RVAToOffset(_lpFile,
			pImageExportDirectory->AddressOfNames));
		
		// ������ŵĵ�ַ��
		lpAddressOfNameOrdinals = (PWORD)(_lpFile + _RVAToOffset(_lpFile,
			pImageExportDirectory->AddressOfNameOrdinals));
		
		// �����ĵ�ַ��
		lpAddressOfFunctions = (PDWORD)(_lpFile + _RVAToOffset(_lpFile,
			pImageExportDirectory->AddressOfFunctions));

		// ���������ĸ���
		dwNumberOfFunctions = pImageExportDirectory->NumberOfFunctions;
		wIndex = 0;
		while (dwNumberOfFunctions--)
		{
			// �����ֵĺ�������
			dwNumberOfNames = pImageExportDirectory->NumberOfNames;
			DWORD i;
			for (i = 0; i < dwNumberOfNames; ++i)
			{
				if (lpAddressOfNameOrdinals[i] == wIndex)//�ұ��
				{
					break;
				}
			}
			//�ҵ���������
			if (i < dwNumberOfNames)
			{
				// �ҵ���������ַ����ת��ΪFOA����ת��Ϊȫ�ֵ�ַ
				dwFunRaw = _lpFile + _RVAToOffset(_lpFile, (DWORD)lpAddressOfNames[i]);
			}
			else
			{
				dwFunRaw = TEXT("(������ŵ���)");
			}
			DWORD funcAddr = *lpAddressOfFunctions;
			wsprintf(szBuffer, TEXT("%08x      %08x      %s\n"), 
				pImageExportDirectory->Base+wIndex++,// �������
				funcAddr, // ������ַ
				dwFunRaw);// ������
			lpAddressOfFunctions++;// ��ַ+1
			_appendInfo(szBuffer);
		}
	}
	else
	{
		_appendInfo(TEXT("\n\nδ���ָ��ļ��е�������\n\n"));
	}
}



/*
* ��ȡPE�ļ����ض�λ��Ϣ
* _lpFile:		������ʼƫ�Ƶ�ַ
* _lpPeHead:	peͷ��ʼƫ�Ƶ�ַ
*/
void _getRelocInfo(PTCHAR _lpFile, PTCHAR  _lpPeHead)
{
	PIMAGE_NT_HEADERS pImageNtHeaders;//NTͷ
	DWORD dwVirtualAddress;//
	PIMAGE_BASE_RELOCATION pImageBaseRelocation;// �ض�λ����
	int dwRelNum;// �ض�λ������
	PWORD lpRelAdd;// �ض�λ����ַ
	DWORD dwRelAdd;
	TCHAR szBuffer[1024];

	TCHAR szMsgReloc2[] = TEXT("\n--------------------------------------------------------------------------------------------\n"
								"�ض�λ����ַ�� %08x\n"
								"�ض�λ�������� %d\n"
								"--------------------------------------------------------------------------------------------\n"
								"��Ҫ�ض�λ�ĵ�ַ�б�(ffffffff��ʾ������,����Ҫ�ض�λ)\n"
								"--------------------------------------------------------------------------------------------\n");





	// תNTͷ
	pImageNtHeaders = (PIMAGE_NT_HEADERS)_lpPeHead;
	// ��6������Ŀ¼��Ϊ�ض�λ���ҵ��ض�λ��RVA
	dwVirtualAddress = pImageNtHeaders->OptionalHeader.DataDirectory[5].VirtualAddress;
	if (dwVirtualAddress)// RVA��Ϊ��
	{

		wsprintf(szBuffer, TEXT("\n�ض�λ�������Ľڣ�%s\n"),
			// ��λ�ض�λ�����ڵĽ�
			_getRVASectionName(_lpFile, dwVirtualAddress));
		_appendInfo(szBuffer);
		// ǿתΪ�ض�λ������
		pImageBaseRelocation = (PIMAGE_BASE_RELOCATION)(_lpFile + 
			_RVAToOffset(_lpFile, dwVirtualAddress));

		//ѭ������ÿ���ض�λ��
		while (pImageBaseRelocation->VirtualAddress && dwFlag != 1)//����һ����Զ����������dwFlag != 1,
		{											 			   //�ñ�־����������
																   //���ڵ�ʮ�����õ�����̬�����л��õ�
			// ����
			dwRelNum = (pImageBaseRelocation->SizeOfBlock - sizeof(IMAGE_BASE_RELOCATION)) / 2;
			wsprintf(szBuffer, szMsgReloc2, pImageBaseRelocation->VirtualAddress, dwRelNum);
			// ׷�ӵ��ؼ�
			_appendInfo(szBuffer);

			// ָ���һ���ض�λ��
			lpRelAdd = (PWORD)(pImageBaseRelocation + 1);
			for (int i = 0; i < dwRelNum && dwFlag != 1; ++i)//����һ����Զ����������dwFlag != 1,
			{								  				 //�ñ�־����������
										 					 //���ڵ�ʮ�����õ�����̬�����л��õ�
				// �ض�λ��ַָ���˫�ֵ�32λ����Ҫ��������4λΪ3������Ҫ������
				if ((*lpRelAdd & 0xf000) == 0x3000)// ȡ��ֵ��յ�24λ �ж� �Ƿ����3
				{
					// ȡ��ֵ �ض�λ���ƫ�� = ��ո�4λ + �ض�λ������ʼƫ��
					dwRelAdd = (*lpRelAdd & 0x0fff) + pImageBaseRelocation->VirtualAddress;
				}
				else
				{
					dwRelAdd = -1;
				}
				wsprintf(szBuffer, TEXT("%08x  "), dwRelAdd);
				if ((i + 1) % 8 == 0)//ÿ��ʾ8����Ŀ����
				{
					lstrcat(szBuffer, TEXT("\n"));
				}
				_appendInfo(szBuffer);

				++lpRelAdd;//ָ����һ���ض�λ��

			}

			if (dwRelNum % 8)
			{
				_appendInfo(TEXT("\n"));
			}
			// ָ����һ���ض�λ��
			pImageBaseRelocation = (PIMAGE_BASE_RELOCATION)lpRelAdd;

		}

	}
	else
	{
		_appendInfo(TEXT("\n\nδ���ָ��ļ����ض�λ��Ϣ.\n\n"));
	}
}




/*
�ݹ麯����������Դ����
_lpFile���ļ���ַ
_lpRes����Դ���ַ
_lpResDir��Ŀ¼��ַ
_dwLevel��Ŀ¼����
*/
void _processRes(PTCHAR _lpFile, PTCHAR _lpRes, PTCHAR _lpResDir, DWORD _dwLevel)
{
	PIMAGE_RESOURCE_DIRECTORY pResourceDirectory;
	DWORD dwNumber;
	PIMAGE_RESOURCE_DIRECTORY_ENTRY pResourceDirectoryEntry;
	DWORD OffsetToData;
	DWORD dwName;
	TCHAR szResName[256];
	PTCHAR lpResName;
	TCHAR szBuffer[1024];



	TCHAR szType[][16] = {TEXT("1-���         "),
						  TEXT("2-λͼ         "),
						  TEXT("3-ͼ��         "),
						  TEXT("4-�˵�         "),
						  TEXT("5-�Ի���       "),
						  TEXT("6-�ַ���       "),
						  TEXT("7-����Ŀ¼     "),
						  TEXT("8-����         "),
						  TEXT("9-���ټ�       "),
						  TEXT("10-δ��ʽ����Դ"),
						  TEXT("11-��Ϣ��      "),
						  TEXT("12-�����      "),
						  TEXT("13-δ֪����    "),
						  TEXT("14-ͼ����      "),
						  TEXT("15-δ֪����    "),
						  TEXT("16-�汾��Ϣ    ") };

	TCHAR szOut5[] = TEXT("%d(�Զ�����)");
	TCHAR szLevel1[] = TEXT("|-- %s\n"
							"|   |\n");
	TCHAR szLevel2[] = TEXT("|   |-- %s\n"
							"|   |     |\n");
	TCHAR szOut6[] = TEXT("|   |-- ID %d\n"
						  "|   |     |\n");
	TCHAR szLevel3[] = TEXT("|   |     |-- ����ҳ��%d   ��Դ�����ļ�λ�ã�0x%08x  ��Դ���ȣ�%d\n");


	pResourceDirectory = (PIMAGE_RESOURCE_DIRECTORY)_lpResDir;//ָ��Ŀ¼��
	dwNumber = pResourceDirectory->NumberOfIdEntries + pResourceDirectory->NumberOfNamedEntries;//����Ŀ¼��ĸ���
	pResourceDirectoryEntry = (PIMAGE_RESOURCE_DIRECTORY_ENTRY)(pResourceDirectory + 1);//����Ŀ¼ͷ��λ��Ŀ¼��



	while (dwNumber > 0 && dwFlag != 1)//����һ����Զ����������dwFlag != 1,
	{					 			  //�ñ�־����������
									 //���ڵ�ʮ�����õ�
		OffsetToData = pResourceDirectoryEntry->OffsetToData;//�鿴IMAGE_RESOURCE_DIRECTORY_ENTRY.OffsetToData
		if (OffsetToData & 0x80000000)//������λΪ1
		{
			OffsetToData = (OffsetToData & 0x7fffffff) + (DWORD)_lpRes;//Ϊ��һ�εݹ�׼������������,ƫ���ǻ�����Դ����ʼ��ַ��
			if (_dwLevel == 1)//����ǵ�һ����Դ���
			{
				dwName = pResourceDirectoryEntry->Name;
				if (dwName & 0x80000000)//����ǰ����ƶ������Դ����
				{
					dwName = (dwName & 0x7fffffff) + (DWORD)_lpRes;//ָ���������ַ����ṹIMAGE_RESOURCE_DIR_STRING_U
					WideCharToMultiByte(CP_ACP, WC_COMPOSITECHECK,//��UNICODE�ַ�ת��Ϊ���ֽ��ַ�
						((PIMAGE_RESOURCE_DIR_STRING_U)dwName)->NameString,//���ֵ�ַ
						((PIMAGE_RESOURCE_DIR_STRING_U)dwName)->Length, //���ֳ���
						szResName, sizeof szResName, NULL, NULL);
					szResName[((PIMAGE_RESOURCE_DIR_STRING_U)dwName)->Length] = 0;//������
					lpResName = szResName;//ָ���������ַ���
				}
				else//����ǰ���Ŷ������Դ����
				{
					if (dwName <= 0x10)//ϵͳ�ڶ�����Դ���
					{
						lpResName = szType[dwName - 1];//��λ��������ַ���
					}
					else//�Զ�����Դ����
					{
						wsprintf(szResName, szOut5, dwName);
						lpResName = szResName;
					}
				}
				wsprintf(szBuffer, szLevel1, lpResName);
			}
			else if (_dwLevel == 2)//����ǵڶ�����ԴID
			{
				dwName = pResourceDirectoryEntry->Name;
				if (dwName & 0x80000000) //����ǰ��ַ����������ԴID
				{
					dwName = (dwName & 0x7fffffff) + (DWORD)_lpRes;
					WideCharToMultiByte(CP_ACP, WC_COMPOSITECHECK,//��UNICODE�ַ�ת��Ϊ���ֽ��ַ�
						((PIMAGE_RESOURCE_DIR_STRING_U)dwName)->NameString,
						((PIMAGE_RESOURCE_DIR_STRING_U)dwName)->Length,
						szResName, sizeof szResName, NULL, NULL);
					szResName[((PIMAGE_RESOURCE_DIR_STRING_U)dwName)->Length] = 0;//������
					wsprintf(szBuffer, szLevel2, szResName);
				}
				else//����ǰ���Ŷ������Դ����
				{
					wsprintf(szBuffer, szOut6, dwName);
				}
			}
			else
			{//�����ݹ�
				break;
			}

			_appendInfo(szBuffer);
			_processRes(_lpFile, _lpRes, (PTCHAR)OffsetToData, _dwLevel + 1);
		}
		//���IMAGE_RESOURCE_DIRECTORY_ENTRY.OffsetToData���λΪ0
		else//������Ŀ¼ 
		{
			OffsetToData += (DWORD)_lpRes;

			wsprintf(szBuffer, szLevel3,pResourceDirectoryEntry->Name,//����ҳ
				_RVAToOffset(_lpFile, ((PIMAGE_RESOURCE_DATA_ENTRY)OffsetToData)->OffsetToData),
				 ((PIMAGE_RESOURCE_DATA_ENTRY)OffsetToData)->Size);

			_appendInfo(szBuffer);
		}

		++pResourceDirectoryEntry;
		--dwNumber;
	}
}



/*
��ȡPE�ļ�����Դ��Ϣ
*/
void _getResource(PTCHAR _lpFile, PTCHAR  _lpPeHead)
{
	PIMAGE_NT_HEADERS pNtHeaders;
	DWORD dwVirtualAddress;
	TCHAR szBuffer[1024];
	PTCHAR lpRes;


	TCHAR szOut4[] = TEXT("\n\n\n"
						  "---------------------------------------------------------------------------------------------\n"
						  "��Դ�������Ľڣ�%s\n"
						  "---------------------------------------------------------------------------------------------\n"
						  "\n\n"
						  "��Ŀ¼\n"
						  "|\n");


	pNtHeaders = (PIMAGE_NT_HEADERS)_lpPeHead;
	if (dwVirtualAddress = (pNtHeaders->OptionalHeader.DataDirectory)[2].VirtualAddress)
	{
		wsprintf(szBuffer, szOut4, _getRVASectionName(_lpFile, dwVirtualAddress));
		_appendInfo(szBuffer);

		//����Դ�����ļ���ƫ��
		lpRes = _lpFile + _RVAToOffset(_lpFile, dwVirtualAddress);

		//������ĸ������ֱ��ʾ
		//1���ļ�ͷλ��
		//2����Դ��λ��
		//3��Ŀ¼λ��
		//4��Ŀ¼����
		_processRes(_lpFile, lpRes, lpRes, 1);
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
							// ������ʼ��ַ+PE�ļ�ƫ�ƣ��õ�PE��ʼ��ַ
							lpMem = lpMemory + ((PIMAGE_DOS_HEADER)lpMemory)->e_lfanew;
							if (((PIMAGE_NT_HEADERS)lpMem)->Signature == IMAGE_NT_SIGNATURE)//�ж��Ƿ���PE����
							{
								// ����Ϊֹ�����ļ�����֤�Ѿ���ɡ�ΪPE�ṹ�ļ�
								// �����������ּ�ӳ�䵽�ڴ��е����ݣ�����ʾ��Ҫ����
								_getMainInfo(lpMem, szFileName);

								//��ʾ�����
								_getImportInfo(lpMemory, lpMem);

								//��ʾ������
								_getExportInfo(lpMemory, lpMem);

								//��ʾ�ض�λ��Ϣ
								_getRelocInfo(lpMemory, lpMem);

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