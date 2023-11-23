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



	pImageDosHeader = (PIMAGE_DOS_HEADER)_hModule;
	pImageNtHeaders = (PIMAGE_NT_HEADERS)(_hModule + pImageDosHeader->e_lfanew);
	dwVirtualAddress = pImageNtHeaders->OptionalHeader.DataDirectory[0].VirtualAddress;//������ƫ�� 
	pImageExportDirectory = (PIMAGE_EXPORT_DIRECTORY)(_hModule + dwVirtualAddress);//�������ַ
	lpAddressOfNames = (TCHAR **)(_hModule + pImageExportDirectory->AddressOfNames);//�����ֵ��������б�
	for (i = 0; _hModule + lpAddressOfNames[i]; ++i)
	{
		if (strlen(_hModule + lpAddressOfNames[i]) == dwLen &&
			!strcmp(_hModule + lpAddressOfNames[i], _lpApi))//�ж��Ƿ�Ϊ_lpApi
		{
			lpAddressOfNameOrdinals = (PWORD)(_hModule + pImageExportDirectory->AddressOfNameOrdinals);//�����ֵ������������б�

			return _hModule + ((PDWORD)(_hModule + pImageExportDirectory->AddressOfFunctions))
				[lpAddressOfNameOrdinals[i]];//���ݺ��������ҵ�������ַ

		}
	}
	return 0;
}



int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR szCmdLine, int iCmdShow)
{
	DWORD hKernel32Base;
	PROC _getProcAddress;
	PROC _loadLibrary;
	DWORD hUser32Base;
	PROC _messageBox;

	TCHAR szText[] = TEXT("HelloWorldPE");
	TCHAR szGetProcAddr[] = TEXT("GetProcAddress");
	TCHAR szLoadLib[] = TEXT("LoadLibraryA");		       
	TCHAR szMessageBox[] = TEXT("MessageBoxA");		
	TCHAR user32_DLL[] = TEXT("user32.dll");		


	//��ȡkernel32.dll�Ļ���ַ
	hKernel32Base = _getKernelBase();
	
	//�ӻ���ַ��������GetProcAddress��������ַ
	_getProcAddress = (PROC)_getApi(hKernel32Base, szGetProcAddr);//Ϊ�������ø�ֵ GetProcAddress

	//ʹ��GetProcAddress��������ַ
	//����������������GetProcAddress����
	//���LoadLibraryA����ַ
	_loadLibrary = (PROC)_getProcAddress(hKernel32Base, szLoadLib);
		
	//ʹ��LoadLibrary��ȡuser32.dll�Ļ���ַ
	hUser32Base = _loadLibrary(user32_DLL);
		
	//ʹ��GetProcAddress��������ַ����ú���MessageBoxA����ַ
	_messageBox = (PROC)_getProcAddress(hUser32Base, szMessageBox);
	_messageBox(NULL, szText, NULL, MB_OK);//���ú���MessageBoxA

	return 0;
}