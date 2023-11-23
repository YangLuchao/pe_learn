//��ȡkernel32.dll�Ļ�ַ
//��PEB�ṹ������kernel32.dll�Ļ���ַ
//
//
//xp��KERNEL32Ϊ�ڶ�����
//win7��KERNEL32Ϊ������
//Ϊ��ʵ�ã����ñ��������Ƚϵ�������dll���ֵķ�ʽ



#include<Windows.h>


int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR szCmdLine, int iCmdShow)
{
	DWORD dwPEB;//PEB��ַ
	DWORD dwLDR;//LEDR��ַ
	DWORD dwInitList;
	DWORD dwDllBase;//��ǰ��ַ
	PIMAGE_DOS_HEADER pImageDosHeader;//ָ��DOSͷ��ָ��
	PIMAGE_NT_HEADERS pImageNtHeaders;//ָ��NTͷ��ָ��
	DWORD dwVirtualAddress;//������ƫ�Ƶ�ַ
	PIMAGE_EXPORT_DIRECTORY pImageExportDirectory;//ָ�򵼳����ָ��
	PTCHAR lpName;//ָ��dll���ֵ�ָ��
	TCHAR szKernel32[] = TEXT("KERNEL32.dll");
	TCHAR szBuffer[256];


	__asm
	{
		mov eax, FS:[0x30]	//��ȡPEB���ڵ�ַ
		mov dwPEB, eax
	}

	//��ȡPEB_LDR_DATA �ṹָ��
	dwLDR = *(PDWORD)(dwPEB + 0xc);
	//��ȡInInitializationOrderModuleList ����ͷ
	//��һ��LDR_MODULE�ڵ�InInitializationOrderModuleList��Ա��ָ��
	dwInitList = *(PDWORD)(dwLDR + 0x1c);


	for (;
		dwDllBase = *(PDWORD)(dwInitList + 8);	//�ṹƫ��0x8�����ģ���ַ
		dwInitList = *(PDWORD)dwInitList		//�ṹƫ��0�������һģ��ṹ��ָ��
		)
	{
		// תDOSͷ
		pImageDosHeader = (PIMAGE_DOS_HEADER)dwDllBase;
		// תNTͷ
		pImageNtHeaders = (PIMAGE_NT_HEADERS)(dwDllBase + pImageDosHeader->e_lfanew);
		// ������ƫ��
		dwVirtualAddress = pImageNtHeaders->OptionalHeader.DataDirectory[0].VirtualAddress; 
		// �������ַ
		pImageExportDirectory = (PIMAGE_EXPORT_DIRECTORY)(dwDllBase + dwVirtualAddress);
		// dll����
		lpName = (PTCHAR)(dwDllBase + pImageExportDirectory->Name);
		// �ж��Ƿ�Ϊ��KERNEL32.dll��
		if (strlen(lpName) == 0xc && !strcmp(lpName, szKernel32))
		{
			//���ģ�����ַ
			wsprintf(szBuffer, TEXT("kernel32.dll�Ļ���ַΪ%08x"), dwDllBase);
			MessageBox(NULL, szBuffer, NULL, MB_OK);
			break;
		}
	}
	return 0;
}
