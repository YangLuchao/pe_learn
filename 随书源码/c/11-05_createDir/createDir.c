//һ���򵥵Ĳ���API��ں�����̬��õ�С����
//������ʹ�ö�̬�������hDllKernel32�Ļ�ַ��
//���ӻ�ַ���������Ӧ�ĺ������Լ�ƫ��
//ʵ�ִ���Ŀ¼�ķ������Ի�����ʾ��������
//
//
//
//������ִ�б���(DEP)�رգ�
//


#include<Windows.h>

#pragma pack(1)

typedef struct 
{
	DWORD CreateDir;	//CreateDirectoryA��������ʵ��ַ
	DWORD lpCreateDir;	//δ��
	WORD jmpCreateDir;	// 0x25ff ����һ����תָ���������תjmp
	DWORD jmpCDOffset;	// ���������Ҫ��ת����ƫ�ƣ���ƫ��ָ��CreateDir��;
}MyStruct, *PMyStruct;

       



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
	MyStruct stMyStruct;
	
	DWORD hDllKernel32 = 0;
	PROC _GetProcAddress = NULL;
	PROC _LoadLibrary = NULL;
	HMODULE hDllUser32;
	PROC _MessageBox = NULL;


	TCHAR szGetProcAddress[] = TEXT("GetProcAddress");
	TCHAR szLoadLib[] = TEXT("LoadLibraryA");
	TCHAR szCreateDir[] = TEXT("CreateDirectoryA");//�÷�����kernel32.dll��
	TCHAR szDir[] = TEXT("c:\\BBBN");
	TCHAR szLoadLibrary[] = TEXT("LoadLibraryA");
	TCHAR szUser32[] = TEXT("user32.dll");
	TCHAR szMessageBox[] = TEXT("MessageBoxA"); //�÷�����user32.dll��
	TCHAR szText[] = TEXT("����һ��c�̸�Ŀ¼�£����Ƿ���Ŀ¼BBBN�ĳ��֣�");
	TCHAR szCaption[] = TEXT("��̬����API����ʾ��");



	stMyStruct.jmpCDOffset = (DWORD)&stMyStruct.CreateDir;
	stMyStruct.jmpCreateDir = 0x25ff;//����һ����תָ���������תjmp
	

	if (hDllKernel32 = _getKernelBase())
	{
		if (_GetProcAddress = (PROC)_getApi(hDllKernel32, szGetProcAddress));//��ȡGetProcAddress�������ڴ��ַ
		{
			stMyStruct.CreateDir = _GetProcAddress(hDllKernel32, szCreateDir); //��ȡ����Ŀ¼�������ڴ��ַ������
			((PROC)&stMyStruct.jmpCreateDir)(szDir, NULL);
		
			if (_LoadLibrary = (PROC)_GetProcAddress(hDllKernel32, szLoadLibrary)) //��ȡLoadLibrary�������ڴ��ַ
			{
				hDllUser32 = (HMODULE)_LoadLibrary(szUser32);//װ��user32.dll
				if (_MessageBox = (PROC)_GetProcAddress(hDllUser32, szMessageBox))//���MessageBox�������ڴ��ַ������
				{
					_MessageBox(NULL, szText, szCaption, MB_OK);
				}
			}
		}
	}
	return 0;
}