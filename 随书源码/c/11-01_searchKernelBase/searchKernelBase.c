// ��ȡkernel32.dll�Ļ�ַ
// �ӽ��̵�ַ�ռ�����kernel32.dll�Ļ���ַ
//
//
// kernelbase.dll��������Ҳ��GetProcAddress
//
#include<windows.h>


int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	TCHAR szGetProcAddress[] = TEXT("GetProcAddress");// ��Ҫ���ҵĺ�����
	DWORD dwAddress;// �����ڴ�����ʼ��ַ
	PIMAGE_NT_HEADERS pImageNtHeaders;//NTͷ��ַ
	DWORD dwVirtualAddress;// VA
	DWORD dwSize;// 
	PIMAGE_EXPORT_DIRECTORY pImageExportDirectory;//������ṹ��
	TCHAR ** lpAddressOfNames;// ��������ַ
	DWORD dwNumberOfNames;
	TCHAR szBuffer[256];


	//�Ӹߵ�ַ��ʼ
	for (dwAddress = 0x7ffe0000; TRUE; dwAddress -= 0x10000)
	{
		// IsBadReadPtr����֤���ý����Ƿ���ж�ָ���ڴ淶Χ�Ķ�ȡ����Ȩ��
		// ��һ��������ָ���ڴ��ĵ�һ���ֽڵ�ָ��
		// �ڶ����������ڴ���С
		if (IsBadReadPtr((PVOID)dwAddress, 2))
		{ 
			// û��Ȩ��-10ҳ
			continue;
		}

		if (*(PWORD)dwAddress == 0x5A4D)//�ж��Ƿ�ΪMS DOSͷ��־
		{
			// NTͷ
			pImageNtHeaders = (PIMAGE_NT_HEADERS)(dwAddress +
				((PIMAGE_DOS_HEADER)dwAddress)->e_lfanew);
			// ������RVA
			dwVirtualAddress = pImageNtHeaders->OptionalHeader.DataDirectory[0].VirtualAddress;
			// �������С
			dwSize = pImageNtHeaders->OptionalHeader.DataDirectory[0].Size;
			if (dwVirtualAddress && dwSize)// RVA �� �������С����Ϊ0
			{
				// ָ������Ŀ¼�еĵ�����
				pImageExportDirectory = (PIMAGE_EXPORT_DIRECTORY)(dwAddress + dwVirtualAddress);
				// ָ�򵼳���ĵ���������������
				lpAddressOfNames = (TCHAR **)(dwAddress + pImageExportDirectory->AddressOfNames);
				// ָ�򵼳���ĵ�����������
				dwNumberOfNames = pImageExportDirectory->NumberOfNames;
				
				for (DWORD i = 0; i < dwNumberOfNames; ++i)
				{
					if (strlen(dwAddress + lpAddressOfNames[i]) == 0xe && // ����Ҫ���,
						!strcmp(dwAddress + lpAddressOfNames[i], szGetProcAddress))// ��������Ҫ��ȫһ��
					{
						// �ҵ���������,���ģ�����ַ
						wsprintf(szBuffer, TEXT("kernel32.dll�Ļ���ַΪ%08x"), dwAddress);
						// messagebox���
						MessageBox(NULL, szBuffer, NULL, MB_OK);

						return 0;
					}
				}	
			}
		}
	}

}

