//PE文件头中的定位
#include <Windows.h>
#include <Imagehlp.h>


/*
将内存偏移量RVA转换为文件偏移
	_lpFileHead为文件头的起始地址
	_dwRVA为给定的RVA地址
*/
DWORD  _RVAToOffset(PTCHAR _lpFileHead, DWORD _dwRVA)
{
	// NT头结构
	PIMAGE_NT_HEADERS pImageNtHeaders;
	// 节表项结构
	PIMAGE_SECTION_HEADER pImageSectionHeader;
	// 节数量
	WORD dNumberOfSections;

	// 转NT头
	pImageNtHeaders = (PIMAGE_NT_HEADERS)(_lpFileHead + ((PIMAGE_DOS_HEADER)_lpFileHead)->e_lfanew);
	// 转节表项结构
	pImageSectionHeader = (PIMAGE_SECTION_HEADER)(pImageNtHeaders + 1);
	// 节数量
	dNumberOfSections = pImageNtHeaders->FileHeader.NumberOfSections;

	//遍历节表
	while (dNumberOfSections--)
	{
		//计算该节结束RVA，不用Misc的主要原因是有些段的Misc值是错误的！
		if (_dwRVA >= pImageSectionHeader->VirtualAddress &&// 目标地址要大于当前节的起始地址
			_dwRVA < pImageSectionHeader->VirtualAddress + pImageSectionHeader->SizeOfRawData)// 目标地址要小于当前节的结束地址
		{
			// 目标地址FOA = 目标地址RVA - 减去当前节起始地址RVA + 当前节在文件中的偏移
			return _dwRVA - pImageSectionHeader->VirtualAddress + pImageSectionHeader->PointerToRawData;
		}
		// 找下一个节
		++pImageSectionHeader;
	}
	return -1;
}




/*
定位到指定索引的数据目录项所在数据的起始地址
	_lpHeader 头部基地址
	_index 数据目录表索引，从0开始
	_dwFlag1
		为0表示_lpHeader是PE映像头
		为1表示_lpHeader是内存映射文件头
	_dwFlag2
		为0表示返回RVA+模块基地址
		为1表示返回FOA+文件基地址
		为2表示返回RVA
		为3表示返回FOA
	返回eax=指定索引的数据目录项的数据所在地址
*/
DWORD _rDDEntry(PTCHAR _lpHeader, DWORD _index, DWORD _dwFlag1, DWORD _dwFlag2)
{
	// NT头
	PIMAGE_NT_HEADERS pImageNtHeaders;
	//程序的建议装载地址
	DWORD imageBase;
	// 指定索引数据目录项的位置RVA
	DWORD ret1;

	// NT头
	pImageNtHeaders = (PIMAGE_NT_HEADERS)(_lpHeader + ((PIMAGE_DOS_HEADER)_lpHeader)->e_lfanew);
	// 程序装载地址
	imageBase = pImageNtHeaders->OptionalHeader.ImageBase;
	// 取出指定索引数据目录项的位置,是RVA
	ret1 = pImageNtHeaders->OptionalHeader.DataDirectory[_index].VirtualAddress;


	if (_dwFlag1 == 0) //_lpHeader是PE映像头 
	{
		if (_dwFlag2 == 0) // RVA+模块基地址
		{
			return  (DWORD)_lpHeader + ret1;
		}
		else if (_dwFlag2 == 1)//无意义，返回FOA 
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
	else//_lpHeader是内存映射文件头
	{
		if (_dwFlag2 == 0) //RVA+模块基地址
		{
			return  imageBase + ret1;
		}
		else if (_dwFlag2 == 1) //FOA+文件基地址
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
定位到指定索引的节表项
	_lpHeader 头部基地址
	_index 表示第几个节表项，从0开始
	_dwFlag1
		为0表示_lpHeader是PE映像头
		为1表示_lpHeader是内存映射文件头
	_dwFlag2
		为0表示返回RVA+模块基地址
		为1表示返回FOA+文件基地址
		为2表示返回RVA
		为3表示返回FOA
	返回eax=指定索引的节表项所在地址
*/
DWORD _rSection(PTCHAR _lpHeader, DWORD _index, DWORD _dwFlag1, DWORD _dwFlag2)
{
	// NT头
	PIMAGE_NT_HEADERS pImageNtHeaders;
	// 程序装载地址
	DWORD imageBase;
	// 节表项结构
	PIMAGE_SECTION_HEADER pImageSectionHeader;


	// NT头
	pImageNtHeaders = (PIMAGE_NT_HEADERS)(_lpHeader + ((PIMAGE_DOS_HEADER)_lpHeader)->e_lfanew);
	//程序的建议装载地址
	imageBase = pImageNtHeaders->OptionalHeader.ImageBase;
	//第一个节表项所在地址
	pImageSectionHeader = (PIMAGE_SECTION_HEADER)(pImageNtHeaders + 1);
	//索引项所在地址
	pImageSectionHeader += _index;


	if (_dwFlag1 == 0)//_lpHeader是E映像头
	{
		if (_dwFlag2 == 0)//RVA+模块基地址
		{
			return (DWORD)pImageSectionHeader;
		}
		else
		{
			return (DWORD)pImageSectionHeader - (DWORD)_lpHeader;
		}
	}
	else//_lpHeader是内存映射文件头
	{
		if (_dwFlag2 == 0)//RVA+模块基地址
		{
			return (DWORD)pImageSectionHeader - (DWORD)_lpHeader + imageBase;
		}
		else if (_dwFlag2 == 1)//FOA+文件基地址
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
通过调用API函数计算校验和
kernel32.dll的校验和为：116a1b
*/
DWORD _checkSum1(PTCHAR _lpExeFile)
{
	DWORD hSum, cSum;
	MapFileAndCheckSum(_lpExeFile, &hSum, &cSum);
	return cSum;
}





/*
自己编写程序计算校验和
*/
DWORD _checkSum2(PTCHAR _lpExeFile)
{
	HANDLE hFile;
	DWORD dwSize,size;
	LPVOID hBase;
	PIMAGE_NT_HEADERS pImageNtHeaders;
	WORD dwSum = 0, wCFlag1 = 0, wCFlag2 = 0;

	hFile = CreateFile(_lpExeFile, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING,
		FILE_ATTRIBUTE_NORMAL, 0);//打开文件
	dwSize = GetFileSize(hFile, NULL);
	hBase = VirtualAlloc(NULL, dwSize, MEM_COMMIT, PAGE_READWRITE);//为文件分配内存
	ReadFile(hFile, hBase, dwSize, &size, NULL);//读入
	CloseHandle(hFile);//关闭文件


	//第一步，将CheckSum清零
	pImageNtHeaders = (PIMAGE_NT_HEADERS)((PTCHAR)hBase + ((PIMAGE_DOS_HEADER)hBase)->e_lfanew);
	pImageNtHeaders->OptionalHeader.CheckSum = 0;

	//第二步，按字进位加
	for (DWORD i = 0; i < (dwSize + 1) / 2; ++i)
	{
		if (dwSum + ((PWORD)hBase)[i] + wCFlag1 > 0xffff)//判断是否产生进位
		{
			wCFlag2 = 1;
		}
		else
		{
			wCFlag2 = 0;
		}
		dwSum += ((PWORD)hBase)[i]  + wCFlag1;//adc

		wCFlag1 = wCFlag2;//cf置位
	}

	VirtualFree(hBase, dwSize, MEM_DECOMMIT);
	return dwSum + dwSize;
}





int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	TCHAR szBuffer[256];
	TCHAR szOut[] = TEXT("地址为:%08x");
	TCHAR szExeFile[] = TEXT("c:\\windows\\system32\\kernel32.dll");
	TCHAR szOut1[] = TEXT("kernel32.dll的校验和为：%08x");
	PTCHAR lpModulAdd;

	lpModulAdd = (PTCHAR)GetModuleHandle(TEXT("03-01_PEHeader.exe"));//模块句柄实际为模块基址,也可以删除这句，编译时选择固定基址
	

	// PEHeader.exe导入表数据所在VA
	wsprintf(szBuffer, szOut, _rDDEntry(lpModulAdd, 0x01, 0, 0));
	MessageBox(NULL, szBuffer, NULL, MB_OK);

	// PEHeader.exe导入表数据所在FOA
	wsprintf(szBuffer, szOut, _rDDEntry(lpModulAdd, 0x01, 0, 3));
	MessageBox(NULL, szBuffer, NULL, MB_OK);

	// PEHeader.exe第2个节表项在内存的VA地址
	wsprintf(szBuffer, szOut, _rSection(lpModulAdd, 0x01, 0, 0));
	MessageBox(NULL, szBuffer, NULL, MB_OK);

	// PEHeader.exe第2个节表项在内存的VA地址
	wsprintf(szBuffer, szOut, _rSection(lpModulAdd, 0x01, 0, 3));
	MessageBox(NULL, szBuffer, NULL, MB_OK);

	//计算校验和
	if (_checkSum1(szExeFile) == _checkSum2(szExeFile))
	{
		wsprintf(szBuffer, szOut1, _checkSum2(szExeFile));
		MessageBox(NULL, szBuffer, NULL, MB_OK);
	}
	return 0;
}