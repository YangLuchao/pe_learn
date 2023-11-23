#include<Windows.h>




/*
��ȡkernel32.dll�Ļ���ַ
��Ϊvc����main����֮ǰ���г�ʼ�������Բ���ͨ����ջջ��ֵ��ȡkernel32.dll�еĵ�ַ
���ͨ�� PEB �ṹ��ȡKernel32.dll��ַ
*/
DWORD _getKernelBase()
{
	DWORD dwPEB;
	DWORD dwLDR;
	DWORD dwInitList;
	DWORD dwDllBase;//��ǰ��ַ
	PIMAGE_DOS_HEADER pImageDosHeader;//ָ��DOSͷ��ָ��
	PIMAGE_NT_HEADERS pImageNtHeaders;//ָ��NTͷ��ָ��
	DWORD dwVirtualAddress;//������ƫ�Ƶ�ַ
	PIMAGE_EXPORT_DIRECTORY pImageExportDirectory;//ָ�򵼳����ָ��
	PTCHAR lpName;//ָ��dll���ֵ�ָ��
	TCHAR szKernel32[] = TEXT("KERNEL32.dll");

	__asm
	{
		mov eax, FS:[0x30]//��ȡPEB���ڵ�ַ
			mov dwPEB, eax
	}


	dwLDR = *(PDWORD)(dwPEB + 0xc);//��ȡPEB_LDR_DATA �ṹָ��
	dwInitList = *(PDWORD)(dwLDR + 0x1c);//��ȡInInitializationOrderModuleList ����ͷ
	//��һ��LDR_MODULE�ڵ�InInitializationOrderModuleList��Ա��ָ��
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

		if (strlen(lpName) == 0xc && !strcmp(lpName, szKernel32))//�ж��Ƿ�Ϊ��KERNEL32.dll��
		{
			return dwDllBase;
		}
	}
	return 0;
}



/*
��ȡָ���ַ�����API�����ĵ��õ�ַ
��ڲ�����_hModuleΪ��̬���ӿ�Ļ�ַ
_lpApiΪAPI����������ַ
���ڲ�����eaxΪ�����������ַ�ռ��е���ʵ��ַ
*/
DWORD _getApi(DWORD _hModule, PTCHAR _lpApi)
{
	DWORD i;// ���������ȼ���
	DWORD dwLen;// ���������ȼ���
	PIMAGE_DOS_HEADER pImageDosHeader;//ָ��DOSͷ��ָ��
	PIMAGE_NT_HEADERS pImageNtHeaders;//ָ��NTͷ��ָ��
	DWORD dwVirtualAddress;//������ƫ�Ƶ�ַ
	PIMAGE_EXPORT_DIRECTORY pImageExportDirectory;//ָ�򵼳����ָ��
	TCHAR ** lpAddressOfNames;
	PWORD lpAddressOfNameOrdinals;

	//����API�ַ����ĳ���
	for (i = 0; _lpApi[i]; ++i);
	dwLen = i;


	// ODSͷ
	pImageDosHeader = (PIMAGE_DOS_HEADER)_hModule;
	// NTͷ
	pImageNtHeaders = (PIMAGE_NT_HEADERS)(_hModule + pImageDosHeader->e_lfanew);
	// ������ƫ�� 
	dwVirtualAddress = pImageNtHeaders->OptionalHeader.DataDirectory[0].VirtualAddress;
	// �������ַ
	pImageExportDirectory = (PIMAGE_EXPORT_DIRECTORY)(_hModule + dwVirtualAddress);
	// �����ֵ��������б�
	lpAddressOfNames = (TCHAR **)(_hModule + pImageExportDirectory->AddressOfNames);
	for (i = 0; _hModule + lpAddressOfNames[i]; ++i)
	{
		//�ж��Ƿ�ΪĿ��API
		if (strlen(_hModule + lpAddressOfNames[i]) == dwLen &&
			!strcmp(_hModule + lpAddressOfNames[i], _lpApi))
		{
			// �����ֵ������������б�
			lpAddressOfNameOrdinals = (PWORD)(_hModule + pImageExportDirectory->AddressOfNameOrdinals);
			// ���ݺ��������ҵ�������ַ
			return _hModule + ((PDWORD)(_hModule + pImageExportDirectory->AddressOfFunctions))
				[lpAddressOfNameOrdinals[i]];
		}
	}
	return 0;
}



int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR szCmdLine, int iCmdShow)
{
	DWORD kernel32Base;//kernel32.dll��ַ
	PROC _getProcAddress;//getProcAddress����ָ��
	DWORD lpLoadLib;//loadLib������ַ


	TCHAR szBuffer[256];

	TCHAR szText[] = TEXT("kernel32.dll�ڱ������ַ�ռ�Ļ���ַΪ��%08x\n");
	TCHAR  szText1[] = TEXT("GetProcAddress�����ڱ������ַ�ռ����ַΪ��%08x\n");
	TCHAR  szText2[] = TEXT("LoadLibraryA�����ڱ������ַ�ռ����ַΪ��%08x\n");

	TCHAR szGetProcAddr[] = TEXT("GetProcAddress");
	TCHAR szLoadLib[] = TEXT("LoadLibraryA");

	// ��ȡkernel32.dll��ַ
	kernel32Base = _getKernelBase();
	// ���
	wsprintf(szBuffer, szText, kernel32Base);
	MessageBox(NULL, szBuffer, NULL, MB_OK);

	// Ϊ�������ø�ֵ GetProcAddress
	_getProcAddress = (PROC)_getApi(kernel32Base, szGetProcAddr);
	// ���
	wsprintf(szBuffer, szText1, _getProcAddress);
	MessageBox(NULL, szBuffer, NULL, MB_OK);

	// �ҵ�loadLib�����ĵ�ַ
	lpLoadLib = _getProcAddress(kernel32Base, szLoadLib);
	// ���
	wsprintf(szBuffer, szText2, lpLoadLib);
	MessageBox(NULL, szBuffer, NULL, MB_OK);



	
	return 0;
}