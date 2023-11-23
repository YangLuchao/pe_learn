//PE�ļ�ͷ�еĶ�λ
#include <Windows.h>
#include <Imagehlp.h>


/*
���ڴ�ƫ����RVAת��Ϊ�ļ�ƫ��
	_lpFileHeadΪ�ļ�ͷ����ʼ��ַ
	_dwRVAΪ������RVA��ַ
*/
DWORD  _RVAToOffset(PTCHAR _lpFileHead, DWORD _dwRVA)
{
	// NTͷ�ṹ
	PIMAGE_NT_HEADERS pImageNtHeaders;
	// �ڱ���ṹ
	PIMAGE_SECTION_HEADER pImageSectionHeader;
	// ������
	WORD dNumberOfSections;

	// תNTͷ
	pImageNtHeaders = (PIMAGE_NT_HEADERS)(_lpFileHead + ((PIMAGE_DOS_HEADER)_lpFileHead)->e_lfanew);
	// ת�ڱ���ṹ
	pImageSectionHeader = (PIMAGE_SECTION_HEADER)(pImageNtHeaders + 1);
	// ������
	dNumberOfSections = pImageNtHeaders->FileHeader.NumberOfSections;

	//�����ڱ�
	while (dNumberOfSections--)
	{
		//����ýڽ���RVA������Misc����Ҫԭ������Щ�ε�Miscֵ�Ǵ���ģ�
		if (_dwRVA >= pImageSectionHeader->VirtualAddress &&// Ŀ���ַҪ���ڵ�ǰ�ڵ���ʼ��ַ
			_dwRVA < pImageSectionHeader->VirtualAddress + pImageSectionHeader->SizeOfRawData)// Ŀ���ַҪС�ڵ�ǰ�ڵĽ�����ַ
		{
			// Ŀ���ַFOA = Ŀ���ַRVA - ��ȥ��ǰ����ʼ��ַRVA + ��ǰ�����ļ��е�ƫ��
			return _dwRVA - pImageSectionHeader->VirtualAddress + pImageSectionHeader->PointerToRawData;
		}
		// ����һ����
		++pImageSectionHeader;
	}
	return -1;
}




/*
��λ��ָ������������Ŀ¼���������ݵ���ʼ��ַ
	_lpHeader ͷ������ַ
	_index ����Ŀ¼����������0��ʼ
	_dwFlag1
		Ϊ0��ʾ_lpHeader��PEӳ��ͷ
		Ϊ1��ʾ_lpHeader���ڴ�ӳ���ļ�ͷ
	_dwFlag2
		Ϊ0��ʾ����RVA+ģ�����ַ
		Ϊ1��ʾ����FOA+�ļ�����ַ
		Ϊ2��ʾ����RVA
		Ϊ3��ʾ����FOA
	����eax=ָ������������Ŀ¼����������ڵ�ַ
*/
DWORD _rDDEntry(PTCHAR _lpHeader, DWORD _index, DWORD _dwFlag1, DWORD _dwFlag2)
{
	// NTͷ
	PIMAGE_NT_HEADERS pImageNtHeaders;
	//����Ľ���װ�ص�ַ
	DWORD imageBase;
	// ָ����������Ŀ¼���λ��RVA
	DWORD ret1;

	// NTͷ
	pImageNtHeaders = (PIMAGE_NT_HEADERS)(_lpHeader + ((PIMAGE_DOS_HEADER)_lpHeader)->e_lfanew);
	// ����װ�ص�ַ
	imageBase = pImageNtHeaders->OptionalHeader.ImageBase;
	// ȡ��ָ����������Ŀ¼���λ��,��RVA
	ret1 = pImageNtHeaders->OptionalHeader.DataDirectory[_index].VirtualAddress;


	if (_dwFlag1 == 0) //_lpHeader��PEӳ��ͷ 
	{
		if (_dwFlag2 == 0) // RVA+ģ�����ַ
		{
			return  (DWORD)_lpHeader + ret1;
		}
		else if (_dwFlag2 == 1)//�����壬����FOA 
		{
			return _RVAToOffset(_lpHeader, ret1);
		}
		else if (_dwFlag2 == 2)//RVA
		{
			return ret1;
		}
		else if (_dwFlag2 == 3)//FOA 
		{
			return _RVAToOffset(_lpHeader, ret1);
		}
	}
	else//_lpHeader���ڴ�ӳ���ļ�ͷ
	{
		if (_dwFlag2 == 0) //RVA+ģ�����ַ
		{
			return  imageBase + ret1;
		}
		else if (_dwFlag2 == 1) //FOA+�ļ�����ַ
		{
			return (DWORD)_lpHeader + _RVAToOffset(_lpHeader, ret1);
		}
		else if (_dwFlag2 == 2) //RVA
		{
			return ret1;
		}
		else if (_dwFlag2 == 3) //FOA 
		{
			return _RVAToOffset(_lpHeader, ret1);
		}
	}
	return -1;
}




/*
��λ��ָ�������Ľڱ���
	_lpHeader ͷ������ַ
	_index ��ʾ�ڼ����ڱ����0��ʼ
	_dwFlag1
		Ϊ0��ʾ_lpHeader��PEӳ��ͷ
		Ϊ1��ʾ_lpHeader���ڴ�ӳ���ļ�ͷ
	_dwFlag2
		Ϊ0��ʾ����RVA+ģ�����ַ
		Ϊ1��ʾ����FOA+�ļ�����ַ
		Ϊ2��ʾ����RVA
		Ϊ3��ʾ����FOA
	����eax=ָ�������Ľڱ������ڵ�ַ
*/
DWORD _rSection(PTCHAR _lpHeader, DWORD _index, DWORD _dwFlag1, DWORD _dwFlag2)
{
	// NTͷ
	PIMAGE_NT_HEADERS pImageNtHeaders;
	// ����װ�ص�ַ
	DWORD imageBase;
	// �ڱ���ṹ
	PIMAGE_SECTION_HEADER pImageSectionHeader;


	// NTͷ
	pImageNtHeaders = (PIMAGE_NT_HEADERS)(_lpHeader + ((PIMAGE_DOS_HEADER)_lpHeader)->e_lfanew);
	//����Ľ���װ�ص�ַ
	imageBase = pImageNtHeaders->OptionalHeader.ImageBase;
	//��һ���ڱ������ڵ�ַ
	pImageSectionHeader = (PIMAGE_SECTION_HEADER)(pImageNtHeaders + 1);
	//���������ڵ�ַ
	pImageSectionHeader += _index;


	if (_dwFlag1 == 0)//_lpHeader��Eӳ��ͷ
	{
		if (_dwFlag2 == 0)//RVA+ģ�����ַ
		{
			return (DWORD)pImageSectionHeader;
		}
		else
		{
			return (DWORD)pImageSectionHeader - (DWORD)_lpHeader;
		}
	}
	else//_lpHeader���ڴ�ӳ���ļ�ͷ
	{
		if (_dwFlag2 == 0)//RVA+ģ�����ַ
		{
			return (DWORD)pImageSectionHeader - (DWORD)_lpHeader + imageBase;
		}
		else if (_dwFlag2 == 1)//FOA+�ļ�����ַ
		{
			return (DWORD)pImageSectionHeader;
		}
		else
		{
			return (DWORD)pImageSectionHeader - (DWORD)_lpHeader;
		}
	}
	return -1;
}

/*
ͨ������API��������У���
kernel32.dll��У���Ϊ��116a1b
*/
DWORD _checkSum1(PTCHAR _lpExeFile)
{
	DWORD hSum, cSum;
	MapFileAndCheckSum(_lpExeFile, &hSum, &cSum);
	return cSum;
}





/*
�Լ���д�������У���
*/
DWORD _checkSum2(PTCHAR _lpExeFile)
{
	HANDLE hFile;
	DWORD dwSize,size;
	LPVOID hBase;
	PIMAGE_NT_HEADERS pImageNtHeaders;
	WORD dwSum = 0, wCFlag1 = 0, wCFlag2 = 0;

	hFile = CreateFile(_lpExeFile, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING,
		FILE_ATTRIBUTE_NORMAL, 0);//���ļ�
	dwSize = GetFileSize(hFile, NULL);
	hBase = VirtualAlloc(NULL, dwSize, MEM_COMMIT, PAGE_READWRITE);//Ϊ�ļ������ڴ�
	ReadFile(hFile, hBase, dwSize, &size, NULL);//����
	CloseHandle(hFile);//�ر��ļ�


	//��һ������CheckSum����
	pImageNtHeaders = (PIMAGE_NT_HEADERS)((PTCHAR)hBase + ((PIMAGE_DOS_HEADER)hBase)->e_lfanew);
	pImageNtHeaders->OptionalHeader.CheckSum = 0;

	//�ڶ��������ֽ�λ��
	for (DWORD i = 0; i < (dwSize + 1) / 2; ++i)
	{
		if (dwSum + ((PWORD)hBase)[i] + wCFlag1 > 0xffff)//�ж��Ƿ������λ
		{
			wCFlag2 = 1;
		}
		else
		{
			wCFlag2 = 0;
		}
		dwSum += ((PWORD)hBase)[i]  + wCFlag1;//adc

		wCFlag1 = wCFlag2;//cf��λ
	}

	VirtualFree(hBase, dwSize, MEM_DECOMMIT);
	return dwSum + dwSize;
}





int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	TCHAR szBuffer[256];
	TCHAR szOut[] = TEXT("��ַΪ:%08x");
	TCHAR szExeFile[] = TEXT("c:\\windows\\system32\\kernel32.dll");
	TCHAR szOut1[] = TEXT("kernel32.dll��У���Ϊ��%08x");
	PTCHAR lpModulAdd;

	lpModulAdd = (PTCHAR)GetModuleHandle(TEXT("03-01_PEHeader.exe"));//ģ����ʵ��Ϊģ���ַ,Ҳ����ɾ����䣬����ʱѡ��̶���ַ
	

	// PEHeader.exe�������������VA
	wsprintf(szBuffer, szOut, _rDDEntry(lpModulAdd, 0x01, 0, 0));
	MessageBox(NULL, szBuffer, NULL, MB_OK);

	// PEHeader.exe�������������FOA
	wsprintf(szBuffer, szOut, _rDDEntry(lpModulAdd, 0x01, 0, 3));
	MessageBox(NULL, szBuffer, NULL, MB_OK);

	// PEHeader.exe��2���ڱ������ڴ��VA��ַ
	wsprintf(szBuffer, szOut, _rSection(lpModulAdd, 0x01, 0, 0));
	MessageBox(NULL, szBuffer, NULL, MB_OK);

	// PEHeader.exe��2���ڱ������ڴ��VA��ַ
	wsprintf(szBuffer, szOut, _rSection(lpModulAdd, 0x01, 0, 3));
	MessageBox(NULL, szBuffer, NULL, MB_OK);

	//����У���
	if (_checkSum1(szExeFile) == _checkSum2(szExeFile))
	{
		wsprintf(szBuffer, szOut1, _checkSum2(szExeFile));
		MessageBox(NULL, szBuffer, NULL, MB_OK);
	}
	return 0;
}