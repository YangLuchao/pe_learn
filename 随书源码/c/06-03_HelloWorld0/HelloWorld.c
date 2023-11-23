//�޵�����HelloWorld,
//
//HelloWorld0��HelloWorld1������һ������
//������д�ɾֲ��������Ͷ�����Ҫ�ض�λ��
//
//��Ϊvc����main����֮ǰ����ϵͳ������ʼ����
//���Գ����е����
//���ǲ����������õ���Щ
//
//release��
//��ֹ�Ż�
//���ð�ȫ���



#include <Windows.h>


/*
��ȡkernel32.dll�Ļ���ַ
��Ϊvc����main����֮ǰ���г�ʼ�������Բ���ͨ����ջջ��ֵ��ȡkernel32.dll�еĵ�ַ
���ͨ�� PEB �ṹ��ȡKernel32.dll��ַ
*/
DWORD _getKernelBase()
{
	DWORD dwPEB;//PED��ַ��������kernel32�׵�ַ
	DWORD dwLDR;//LDRָ�룬������kernel32�׵�ַ
	DWORD dwInitList;
	DWORD dwDllBase;//��ǰ��ַ
	PIMAGE_DOS_HEADER pImageDosHeader;//ָ��DOSͷ��ָ��
	PIMAGE_NT_HEADERS pImageNtHeaders;//ָ��NTͷ��ָ��
	DWORD dwVirtualAddress;//������ƫ�Ƶ�ַ
	PIMAGE_EXPORT_DIRECTORY pImageExportDirectory;//ָ�򵼳����ָ��
	PTCHAR lpName;//ָ��dll���ֵ�ָ��
	TCHAR szkernel32[] = { 'K', 'E', 'R', 'N', 'E', 'L', '3', '2', '.', 'd', 'l', 'l', 0 };

	__asm
	{
		mov eax, FS:[0x30]//fs:[30h]ָ��PEB
		mov dwPEB, eax
	}

	dwLDR = *(PDWORD)(dwPEB + 0xc);//PEBƫ��0xc��LDRָ��
	dwInitList = *(PDWORD)(dwLDR + 0x1c);//LDRƫ��0x1c��ָ�� ���ճ�ʼ��˳������ �ĵ�һ��ģ��Ľṹ ��ָ��

	

	for (; 
		dwDllBase = *(PDWORD)(dwInitList + 8);//�ṹƫ��0x8�����ģ���ַ
		dwInitList = *(PDWORD)dwInitList//�ṹƫ��0�������һģ��ṹ��ָ��
		)
	{
		pImageDosHeader = (PIMAGE_DOS_HEADER)dwDllBase;
		pImageNtHeaders = (PIMAGE_NT_HEADERS)(dwDllBase + pImageDosHeader->e_lfanew);
		dwVirtualAddress = pImageNtHeaders->OptionalHeader.DataDirectory[0].VirtualAddress;//������ƫ�� 
		pImageExportDirectory = (PIMAGE_EXPORT_DIRECTORY)(dwDllBase + dwVirtualAddress);//�������ַ
		lpName = (PTCHAR)(dwDllBase + pImageExportDirectory->Name);//dll����

		for (int i = 0; 1; ++i)//�ж��Ƿ�Ϊ��KERNEL32.dll��
		{
			if (lpName[i] != szkernel32[i])
			{
				break;
			}

			if (lpName[i] == 0)
			{
				return dwDllBase;
			}
		}
	}
	return 0;
}


/*
��ȡָ���ַ�����API�����ĵ��õ�ַ
��ڲ�����	_hModule Ϊ��̬���ӿ�Ļ�ַ
			_lpApi ΪAPI����������ַ
���ڲ�����	eaxΪ�����������ַ�ռ��е���ʵ��ַ
*/
DWORD _getApi(DWORD _hModule, PTCHAR _lpApi)
{
	DWORD i;
	DWORD dwLen;
	PIMAGE_DOS_HEADER pImageDosHeader;//ָ��DOSͷ��ָ��
	PIMAGE_NT_HEADERS pImageNtHeaders;//ָ��NTͷ��ָ��
	DWORD dwVirtualAddress;//������ƫ�Ƶ�ַ
	PIMAGE_EXPORT_DIRECTORY pImageExportDirectory;//ָ�򵼳����ָ��
	TCHAR ** lpAddressOfNames;
	PWORD lpAddressOfNameOrdinals;

	//����API�ַ����ĳ���
	for (i = 0; _lpApi[i]; ++i);
	dwLen = i;



	pImageDosHeader = (PIMAGE_DOS_HEADER)_hModule;//DOSͷ
	pImageNtHeaders = (PIMAGE_NT_HEADERS)(_hModule + pImageDosHeader->e_lfanew);//NTͷ
	dwVirtualAddress = pImageNtHeaders->OptionalHeader.DataDirectory[0].VirtualAddress;//������ƫ�� 
	pImageExportDirectory = (PIMAGE_EXPORT_DIRECTORY)(_hModule + dwVirtualAddress);//�������ַ
	lpAddressOfNames = (TCHAR **)(_hModule + pImageExportDirectory->AddressOfNames);//�����ֵ��������б�
	for (i = 0; _hModule + lpAddressOfNames[i]; ++i)
	{
		for (int j = 0; 1; ++j)//�ж��Ƿ�Ϊ_lpApi
		{
			if (_lpApi[j] != (_hModule + lpAddressOfNames[i])[j])
			{
				break;
			}

			if (_lpApi[j] == 0)
			{
				//�����ֵ������������б�
				lpAddressOfNameOrdinals = (PWORD)(_hModule + pImageExportDirectory->AddressOfNameOrdinals);
				
				return _hModule + ((PDWORD)(_hModule + pImageExportDirectory->AddressOfFunctions))
					[lpAddressOfNameOrdinals[i]];//���ݺ��������ҵ�������ַ
			}
		}
	}
	return 0;
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR szCmdLine, int iCmdShow)
{
	DWORD hKernel32Base;// kernel32�׵�ַ
	DWORD hUser32Base;//user32�׵�ַ
	// PROCΪ����ʽ�ĺ���ָ��
	PROC _getProcAddress;//getProcAddress������ַ
	PROC _loadLibrary;// loadLibrary������ַ
	PROC _messageBox;//messageBox��ַ

	TCHAR szGetProcAddr[] =	{ 'G', 'e', 't', 'P', 'r', 'o', 'c', 'A', 'd', 'd', 'r', 'e', 's', 's', 0 };
	TCHAR szLoadLib[] =		{ 'L', 'o', 'a', 'd', 'L', 'i', 'b', 'r', 'a', 'r', 'y', 'A', 0 };
	TCHAR szMessageBox[] =	{ 'M', 'e', 's', 's', 'a', 'g', 'e', 'B', 'o', 'x', 'A', 0 };
	TCHAR szText[] =		{ 'H', 'e', 'l', 'l', 'o', 'W', 'o', 'r', 'l', 'd', 'P', 'E', 0 };
	TCHAR user32_DLL[] =	{ 'u', 's', 'e', 'r', '3', '2', '.', 'd', 'l', 'l', 0 };
	

	
			
		  
		 
	hKernel32Base = _getKernelBase();//��ȡkernel32.dll�Ļ���ַ
	_getProcAddress = (PROC)_getApi(hKernel32Base, szGetProcAddr);//����GetProcAddress��������ַ
	_loadLibrary = (PROC)_getProcAddress(hKernel32Base, szLoadLib);//����GetProcAddress���������LoadLibraryA����ַ
	hUser32Base = _loadLibrary(user32_DLL);//ʹ��LoadLibrary��ȡuser32.dll�Ļ���ַ
	_messageBox = (PROC)_getProcAddress(hUser32Base, szMessageBox);//��ú���MessageBoxA����ַ
	_messageBox(NULL, szText, NULL, MB_OK);//���ú���MessageBoxA
	return 0;
}