//���ܲ�����
//��ȡLoadLibraryA�ĺ�����ַ������
//
//
//release��
//������δ���õĺ���������    �� (/OPT:NOREF)
//�Ż� �ѽ��� (/Od)
//���ð�ȫ��� (/GS-)
//
//
//
//��Ϊnotepad��.textʣ��ֻ��0x100���ҵĿռ�
//��ֱ�Ӹ���֮ǰ�ĺ������ɵ�ָ��̫�࣬�����0x300����
//���Բ�ֱ�Ӹ���֮ǰ�ĺ��������ǰ���Щ��価���ϲ��������������ָ���СΪ0xe1
//����������������е㲻����⣬
//���Բ����������ֱ��������������ɵ�ָ���
//
//
//�����win7x64,��SysWOW64�µ�notepad
//win7��notepad���ض�λ����Ҫ���ض�λȥ��(IMAGE_NT_HEADERS32.IMAGE_FILE_HEADER.Characteristics | 1)�����У�
//��Ȼ������ص�ʱ����д��������޸��ˣ�������ʧ��
//����ڵ�(IMAGE_NT_HEADERS32.AddressOfEntryPoint.AddressOfEntryPoint)��Ϊ0xb700
//���ļ�ƫ��0xab00(0xb700���ļ�ƫ��) ����ʼд��
//д�����������13-07_getLoadLib.exe
//�ļ�ƫ��0x400��0x4e1
//
//
//��13-08_winResult.dll���ָ�Ϊpa.dll
//�ʹ򲹶����notepad����ͬһĿ¼��Ȼ������notepad
//
//


#include <Windows.h>


int  main()
{


	DWORD dwPEB;	//PEB��ַ
	DWORD dwDllBase;//��ǰ��ַ
	PIMAGE_EXPORT_DIRECTORY pImageExportDirectory;//ָ�򵼳����ָ��

	TCHAR ** lpAddressOfNames;// �����������б�
	PWORD lpAddressOfNameOrdinals;
	DWORD szStr[] = { 0x64616f4c, 0x7262694c, 0x41797261, //"LoadLibraryA"
		0x617000 };//"pa"



	__asm
	{
		mov eax, FS:[0x30]//fs:[30h]ָ��PEB
		mov dwPEB, eax
	}

	// ģ���ַ
	// dwPEB + 0xc: //0Ch���ص�����ģ����Ϣ
	// *(PDWORD)(dwPEB + 0xc): �õ�PEB_LDR_DATA�ṹ
	// (*(PDWORD)(dwPEB + 0xc) + 0x1c):��ȡInInitializationOrderModuleList ����ͷ
	// (*(PDWORD)(*(PDWORD)(*(PDWORD)(dwPEB + 0xc) + 0x1c))): ͷ�ڵ��ָ��
	// (*(PDWORD)(*(PDWORD)(*(PDWORD)(dwPEB + 0xc) + 0x1c))) + 8����Ųһ���ڵ�
	// (*(PDWORD)(*(PDWORD)(*(PDWORD)(*(PDWORD)(dwPEB + 0xc) + 0x1c))) + 8):��ָ�룬��ȡ����kernel32.dll��_LDR_MODULE
	// *(PDWORD)(*(PDWORD)(*(PDWORD)(*(PDWORD)(*(PDWORD)(dwPEB + 0xc) + 0x1c))) + 8): ��ָ�룬��ȡkernel32.dll�Ļ�ַ
	dwDllBase = *(PDWORD)(*(PDWORD)(*(PDWORD)(*(PDWORD)(*(PDWORD)(dwPEB + 0xc) + 0x1c))) + 8);

	// ָ�򵼳����ָ��
	// *(PDWORD)(dwDllBase + 0x3c): NTͷRVA
	// *(PDWORD)(dwDllBase + *(PDWORD)(dwDllBase + 0x3c):NTͷVA
	// (dwDllBase + *(PDWORD)(dwDllBase + *(PDWORD)(dwDllBase + 0x3c) + 0x78)):Ŀ¼��VA��Ŀ¼���һ��Ϊ������
	// (PIMAGE_EXPORT_DIRECTORY)(dwDllBase + *(PDWORD)(dwDllBase + *(PDWORD)(dwDllBase + 0x3c) + 0x78))��ǿתΪ������ָ������
	pImageExportDirectory = (PIMAGE_EXPORT_DIRECTORY)(dwDllBase + *(PDWORD)(dwDllBase + *(PDWORD)(dwDllBase + 0x3c) + 0x78));

	// �����ֵ��������б�
	lpAddressOfNames = (TCHAR **)(dwDllBase + pImageExportDirectory->AddressOfNames);
	
	
	int i = 0; 
	do
	{
		int j = 0;
		do
		{
			if (((PTCHAR)szStr)[j] != (dwDllBase + lpAddressOfNames[i])[j])
			{
				break;
			}

			if (((PTCHAR)szStr)[j] == 0)
			{
				lpAddressOfNameOrdinals = (PWORD)(dwDllBase +
					pImageExportDirectory->AddressOfNameOrdinals);//�����ֵ������������б�

				((PROC)(dwDllBase + ((PDWORD)(dwDllBase + pImageExportDirectory->AddressOfFunctions))
					[lpAddressOfNameOrdinals[i]]))((PTCHAR)szStr + 0xd);//����LoadLibraryA

				__asm
				{
					leave	// ƽ���ջ
					mov eax, 0x010031C9//ԭ��ڵ�
					jmp eax
				}
			}
		} while (++j);
	} while (++i);

	return 0;
}

