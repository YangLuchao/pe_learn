//��������
//���δ���ʹ����API������ַ��̬��ȡ�Լ��ض�λ����
//�����ܣ������Ի���
//
//release��
//������δ���õĺ���������    �� (/OPT:NOREF)
//�Ż� �ѽ��� (/Od)
//���ð�ȫ��� (/GS-)
//
//
//
//02-04_PEInfo.exe release�� ��ַ0x00400000 
//���ļ�ƫ��0x1f15(��ڵ�)����ʼд��  
//
//д�����������13-06_patch.exe
//�ļ�ƫ��0x403(����_jmpStart��call CallPopAdd���ĵ�ַ)
//��0x796(main�����Ľ�β)
//
//
//
//�����win7x64,��SysWOW64�µ�notepad
//win7��notepad���ض�λ����Ҫ���ض�λȥ��(IMAGE_NT_HEADERS32.IMAGE_FILE_HEADER.Characteristics | 1)�����У�
//��Ȼ������ص�ʱ����д��������޸��ˣ�������ʧ��
//���ļ�ƫ��0x25c9(��ڵ�)����ʼд��
//д�������һ��
//

#include <Windows.h>



void _jmpStart()
{
	__asm
	{
		call CallPopAdd
CallPopAdd:
		pop eax
		add eax, 0x37b //0x37bΪCallPopAdd��ǩ��main������_start()���ľ���
		jmp eax
	}
}


/*
��ȡkernel32.dll�Ļ���ַ
xp��KERNEL32Ϊ�ڶ�����
win7��KERNEL32Ϊ������
Ϊ��ʵ�ã����ñ��������Ƚϵ�������dll���ֵķ�ʽ
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
��ڲ�����_hModuleΪ��̬���ӿ�Ļ�ַ
_lpApiΪAPI����������ַ
���ڲ����������������ַ�ռ��е���ʵ��ַ
*/
DWORD _getApi(DWORD _hModule, PTCHAR _lpApi)
{
	DWORD i;
	PIMAGE_DOS_HEADER pImageDosHeader;//ָ��DOSͷ��ָ��
	PIMAGE_NT_HEADERS pImageNtHeaders;//ָ��NTͷ��ָ��
	DWORD dwVirtualAddress;//������ƫ�Ƶ�ַ
	PIMAGE_EXPORT_DIRECTORY pImageExportDirectory;//ָ�򵼳����ָ��
	TCHAR ** lpAddressOfNames;
	PWORD lpAddressOfNameOrdinals;


	pImageDosHeader = (PIMAGE_DOS_HEADER)_hModule;
	pImageNtHeaders = (PIMAGE_NT_HEADERS)(_hModule + pImageDosHeader->e_lfanew);
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
				lpAddressOfNameOrdinals = (PWORD)(_hModule +
					pImageExportDirectory->AddressOfNameOrdinals);//�����ֵ������������б�

				return _hModule + ((PDWORD)(_hModule + pImageExportDirectory->AddressOfFunctions))
					[lpAddressOfNameOrdinals[i]];//���ݺ��������ҵ�������ַ
			}
		}
	}





	return 0;
}



/*
�������ܲ���
��������������
_kernel:kernel32.dll�Ļ���ַ
_getAddr:����GetProcAddress��ַ
_loadLib:����LoadLibraryA��ַ
*/
void _patchFun(DWORD _kernel, PROC _getAddr, PROC _loadLib)
{
	//�������ܴ���ֲ���������
	DWORD hUser32Base;//user32.dll��ַ
	PROC _messageBox;// messagebox������ַ
	TCHAR szUser32Dll[] = { 'u', 's', 'e', 'r', '3', '2', '.', 'd', 'l', 'l', 0 };
	TCHAR szMessageBox[] = { 'M', 'e', 's', 's', 'a', 'g', 'e', 'B', 'o', 'x', 'A', 0 };
	TCHAR szHello[] = { 'H', 'e', 'l', 'l', 'o', 'W', 'o', 'r', 'l', 'd', 'P', 'E', 0 };


	//�������ܴ��룬����ֻ��һ������������Ϊ�����Ի���
	hUser32Base = _loadLib(szUser32Dll);//��ȡuser32.dll�Ļ���ַ

	//ʹ��GetProcAddress��������ַ��
	//����������������GetProcAddress������
	//���MessageBoxA����ַ
	_messageBox = (PROC)_getAddr(hUser32Base, szMessageBox);

	//���ú���MessageBox !!
	_messageBox(NULL, szHello, NULL, MB_OK);


}





void _start()
{
	DWORD hKernel32Base;//���kernel32.dll��ַ
	PROC _getProcAddress;// getProcAddress������ַ
	PROC _loadLibrary;// loadLibrary������ַ


	TCHAR szGetProcAddr[] = { 'G', 'e', 't', 'P', 'r', 'o', 'c', 'A', 'd', 'd', 'r', 'e', 's', 's', 0 };
	TCHAR szLoadLib[] = { 'L', 'o', 'a', 'd', 'L', 'i', 'b', 'r', 'a', 'r', 'y', 'A', 0 };


	hKernel32Base = _getKernelBase();//��ȡkernel32.dll�Ļ���ַ
	_getProcAddress = (PROC)_getApi(hKernel32Base, szGetProcAddr);//�ӻ���ַ��������GetProcAddress��������ַ
	_loadLibrary = (PROC)_getApi(hKernel32Base, szLoadLib);//�ӻ���ַ��������LoadLibraryA��������ַ
	_patchFun(hKernel32Base, _getProcAddress, _loadLibrary);//���ò�������
}



/*
EXE�ļ��µ���ڵ�ַ
*/
int  main()
{
	// ִ�в�������
	_start();

	__asm
	{
		call CallPopSub
CallPopSub:
		pop eax
		sub eax,0xa
		jmp eax
	}

	return 0;
}

