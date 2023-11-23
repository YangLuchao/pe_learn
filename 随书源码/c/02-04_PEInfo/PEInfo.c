#include <Windows.h>
#include<Richedit.h>
#include "resource.h"


HINSTANCE hInstance;
HWND hWinEdit;

DWORD dwFlag = 0xffffffff;


/*
初始化窗口程序
*/
void _Init(HWND hWinMain)
{
	
	HICON hIcon;
	CHARFORMAT stCf;
	TCHAR szFont[] = TEXT("宋体");


	hWinEdit = GetDlgItem(hWinMain, IDC_INFO);
	hIcon = LoadIcon(hInstance, MAKEINTRESOURCE(ICO_MAIN));
	SendMessage(hWinMain, WM_SETICON, ICON_BIG, (LPARAM)hIcon);	//为窗口设置图标
	SendMessage(hWinEdit, EM_SETTEXTMODE, TM_PLAINTEXT, 0);		//设置编辑控件

	RtlZeroMemory(&stCf, sizeof(stCf));
	stCf.cbSize = sizeof(stCf);
	stCf.yHeight = 9 * 20;
	stCf.dwMask = CFM_FACE | CFM_SIZE | CFM_BOLD;
	lstrcpy(stCf.szFaceName, szFont);
	SendMessage(hWinEdit, EM_SETCHARFORMAT, 0, (LPARAM)&stCf);

	SendMessage(hWinEdit, EM_EXLIMITTEXT, 0, -1);
}


/*
往文本框中追加文本
*/
void _appendInfo(PTCHAR _lpsz)
{
	CHARRANGE stCR;
	int iTextLength;

	iTextLength = GetWindowTextLength(hWinEdit);
	stCR.cpMin = iTextLength;
	stCR.cpMax = iTextLength;

	SendMessage(hWinEdit, EM_EXSETSEL, 0, (LPARAM)&stCR);
	SendMessage(hWinEdit, EM_REPLACESEL, FALSE, (LPARAM)_lpsz);

}



/*
* 从内存中获取PE文件的主要信息
* NT头和节表项信息
* _lpPeHead： pe头起始偏移地址
* szFileName： 文件名起始偏移地址
*/
void _getMainInfo(PTCHAR  _lpPeHead, PTCHAR szFileName)
{
	// NT头结构
	PIMAGE_NT_HEADERS pImageNtHeaders;
	// 节表项结构
	PIMAGE_SECTION_HEADER pImageSectionHeader;
	TCHAR szBuffer[1024];
	TCHAR szSecName[16];
	WORD dNumberOfSections;
	TCHAR szMsg[] = TEXT("文件名：%s\n"
						 "-----------------------------------------\n\n\n"
						 "运行平台：      0x%04x  (014c:Intel 386   014dh:Intel 486  014eh:Intel 586)\n"
						 "节的数量：      %d\n"
						 "文件属性：      0x%04x  (大尾-禁止多处理器-DLL-系统文件-禁止网络运行-禁止优盘运行-无调试-32位-小尾-X-X-X-无符号-无行-可执行-无重定位)\n"
						 "建议装入基地址：  0x%08x\n"
						 "文件执行入口(RVA地址)：  0x%04x\n\n");

	TCHAR szMsgSec[] = TEXT("---------------------------------------------------------------------------------\n"
							"节的属性参考：\n"
							"  00000020h  包含代码\n"
							"  00000040h  包含已经初始化的数据，如.const\n"
							"  00000080h  包含未初始化数据，如 .data?\n"
							"  02000000h  数据在进程开始以后被丢弃，如.reloc\n"
							"  04000000h  节中数据不经过缓存\n"
							"  08000000h  节中数据不会被交换到磁盘\n"
							"  10000000h  数据将被不同进程共享\n"
							"  20000000h  可执行\n"
							"  40000000h  可读\n"
							"  80000000h  可写\n"
							"常见的代码节一般为：60000020h,数据节一般为：c0000040h，常量节一般为：40000040h\n"
							"---------------------------------------------------------------------------------\n\n\n"
							"节的名称  未对齐前真实长度  内存中的偏移(对齐后的) 文件中对齐后的长度 文件中的偏移  节的属性\n"
							"---------------------------------------------------------------------------------------------\n");

	TCHAR szFmtSec[] = TEXT("%s     %08x         %08x              %08x           %08x     %08x\n\n\n");

	pImageNtHeaders = (PIMAGE_NT_HEADERS)_lpPeHead;
	//文件名,运行平台,节的数量,文件的属性,建议装入的地址,入口点
	wsprintf(szBuffer, szMsg, szFileName, 
		// 运行平台
		pImageNtHeaders->FileHeader.Machine,
		// 中节的数量
		pImageNtHeaders->FileHeader.NumberOfSections, 
		// 文件的属性
		pImageNtHeaders->FileHeader.Characteristics,
		// 程序的建议装载地址
		pImageNtHeaders->OptionalHeader.ImageBase, 
		// 程序执行入口
		pImageNtHeaders->OptionalHeader.AddressOfEntryPoint);

	SetWindowText(hWinEdit, szBuffer);//添加到编辑框中

	// 显示每个节的主要信息
	_appendInfo(szMsgSec);

	// 节的数量
	dNumberOfSections = pImageNtHeaders->FileHeader.NumberOfSections;
	// NT头结构对象+1，偏移挪到了节表项起始地址，将该地址强转为节表项结构
	pImageSectionHeader = (PIMAGE_SECTION_HEADER)(pImageNtHeaders + 1);

	while (dNumberOfSections--)
	{
		// 获取节的名称，注意长度为8的名称并不以0结尾
		RtlZeroMemory(szSecName, sizeof(szSecName));
		for (int i = 0; i < 8; ++i)
		{
			if (pImageSectionHeader->Name[i])
			{
				// 节名
				szSecName[i] = pImageSectionHeader->Name[i];
			}
			else
			{
				szSecName[i] = ' ';//如果名称为0，则显示为空格
			}
		}

		// 获取节的主要信息
		wsprintf(szBuffer, szFmtSec, szSecName, 
			// 节大小
			pImageSectionHeader->Misc.VirtualSize,
			// 节RVA
			pImageSectionHeader->VirtualAddress, 
			// 节在文件中对齐后的大小
			pImageSectionHeader->SizeOfRawData,
			// 在文件中的偏移
			pImageSectionHeader->PointerToRawData,
			// 节属性
			pImageSectionHeader->Characteristics);
		_appendInfo(szBuffer);

		++pImageSectionHeader;//指向下一个节表项
	}
}



/*
将内存偏移量RVA转换为文件偏移
	RVA切换值FOA
	lp_FileHead 文件头的起始地址
	_dwRVA		给定的需要映射成FOA的RVA
*/
DWORD  _RVAToOffset(PTCHAR _lpFileHead, DWORD _dwRVA)
{
	// NT头结构
	PIMAGE_NT_HEADERS pImageNtHeaders;
	// 节表项结构
	PIMAGE_SECTION_HEADER pImageSectionHeader;
	// 节的数量
	WORD dNumberOfSections;
	
	// 指针挪到PE头开头处，构建号NT头结构
	pImageNtHeaders = (PIMAGE_NT_HEADERS)(_lpFileHead + ((PIMAGE_DOS_HEADER)_lpFileHead)->e_lfanew);
	// NT头+1地址挪到节表项，构造好节表项结构
	pImageSectionHeader = (PIMAGE_SECTION_HEADER)(pImageNtHeaders + 1);
	// 有多少个节
	dNumberOfSections = pImageNtHeaders->FileHeader.NumberOfSections;

	//遍历节表
	while (dNumberOfSections--)
	{
		
		if (_dwRVA >= pImageSectionHeader->VirtualAddress && // 给定的地址需要大于节的起始地址
			// 给定地址需要小于该节的结束地址
			_dwRVA < pImageSectionHeader->VirtualAddress + pImageSectionHeader->SizeOfRawData)//计算该节结束RVA，不用Misc的主要原因是有些段的Misc值是错误的！
		{
			// 给定地址 减去节起始地址 再加上节区数据在文件中的偏移 就得到FOA
			return _dwRVA - pImageSectionHeader->VirtualAddress + pImageSectionHeader->PointerToRawData;
		}
		++pImageSectionHeader;
	}
	return -1;
}


/*
* 获取RVA所在节的名称
* _lpFileHead		镜像偏移地址
* _dwRVA			需要映射为FOA的RAV
*/
PTCHAR _getRVASectionName(PTCHAR _lpFileHead, DWORD _dwRVA)
{
	// NT头结构
	PIMAGE_NT_HEADERS pImageNtHeaders;
	// 节表项结构
	PIMAGE_SECTION_HEADER pImageSectionHeader;
	// 节的个数
	WORD dNumberOfSections;
	// 构建NT头结构
	pImageNtHeaders = (PIMAGE_NT_HEADERS)(_lpFileHead + ((PIMAGE_DOS_HEADER)_lpFileHead)->e_lfanew);
	// 构建节表项结构
	pImageSectionHeader = (PIMAGE_SECTION_HEADER)(pImageNtHeaders + 1);
	// 获取节的个数
	dNumberOfSections = pImageNtHeaders->FileHeader.NumberOfSections;

	while (dNumberOfSections--)
	{
		if (_dwRVA >= pImageSectionHeader->VirtualAddress && // 给定地址需大于节的起始偏移地址
			// 给定地址需小于节的结束地址
			_dwRVA < pImageSectionHeader->VirtualAddress + pImageSectionHeader->SizeOfRawData)//计算该节结束RVA，不用Misc的主要原因是有些段的Misc值是错误的！
		{
			// 返回节的名称
			return pImageSectionHeader->Name;
		}
		// 在下一个节查找
		++pImageSectionHeader;
	}
	return TEXT("无法查找");
}


/*
* 获取PE文件的导入表
* 解析导入表信息
* _lpFile： 镜像偏移地址
* _lpPeHead：pe头偏移地址
*/
void _getImportInfo(PTCHAR _lpFile, PTCHAR  _lpPeHead)
{
	// NT头结构
	PIMAGE_NT_HEADERS pImagenNtHeaders;
	DWORD dwVirtualAddress;
	// 导入表结构
	PIMAGE_IMPORT_DESCRIPTOR pImageImportDescriptor;
	TCHAR szBuffer[1024];
	// 桥1指向的函数名称地址结构
	PIMAGE_THUNK_DATA pImageThunkData;
	// 桥1指向的函数名称结构 函数编号和函数名称信息
	PIMAGE_IMPORT_BY_NAME pImageImportByName;


	TCHAR szMsg1[] = TEXT("\n\n\n---------------------------------------------------------------------------------------------\n"
							"导入表所处的节：%s\n"
							"---------------------------------------------------------------------------------------------\n");

	TCHAR szMsgImport[] = TEXT("\n\n导入库：%s\n"
								"-----------------------------\n\n"
								"OriginalFirstThunk  %08x\n"
								"TimeDateStamp       %08x\n"
								"ForwarderChain      %08x\n"
								"FirstThunk          %08x\n"
								"-----------------------------\n\n");


	pImagenNtHeaders = (PIMAGE_NT_HEADERS)_lpPeHead;

	// 导入表RVA
	dwVirtualAddress = pImagenNtHeaders->OptionalHeader.DataDirectory[1].VirtualAddress;
	if (dwVirtualAddress)// 有导入表
	{
		// 计算导入表所在文件偏移位置
		pImageImportDescriptor = (PIMAGE_IMPORT_DESCRIPTOR)(_lpFile +
			// 获取导入表在文件中的偏移
			_RVAToOffset(_lpFile, dwVirtualAddress));
		
		// 获取给定地址所在节的节名
		wsprintf(szBuffer, szMsg1, _getRVASectionName(_lpFile, 
			pImageImportDescriptor->OriginalFirstThunk)); 
		_appendInfo(szBuffer);

		// 判断导入表的各个属性是否有值，所有的导入表处理完成退出循环
		while (pImageImportDescriptor->OriginalFirstThunk ||	// 桥1
			pImageImportDescriptor->TimeDateStamp ||			// 时间戳
			pImageImportDescriptor->ForwarderChain ||			// 省略
			pImageImportDescriptor->Name ||						// 动态链接库名RVA
			pImageImportDescriptor->FirstThunk)					// 桥2
		{
			// _lpFile + _RVAToOffset(_lpFile, pImageImportDescriptor->Name ： 导入库的名字
			wsprintf(szBuffer, szMsgImport, 
				_lpFile + _RVAToOffset(_lpFile, pImageImportDescriptor->Name),  // 动态链接库名RVA
				pImageImportDescriptor->OriginalFirstThunk,						// 桥1
				pImageImportDescriptor->TimeDateStamp,							// 时间戳
				pImageImportDescriptor->ForwarderChain,							// 省略
				pImageImportDescriptor->FirstThunk);							// 桥2
			_appendInfo(szBuffer);

			// 获取IMAGE_THUNK_DATA列表
			// 桥1偏移合法，因为存在桥1被替换失效的场景
			if (pImageImportDescriptor->OriginalFirstThunk)
			{
				// 通过桥1获取thunk数据列表
				pImageThunkData = (PIMAGE_THUNK_DATA)(_lpFile + 
					_RVAToOffset(_lpFile, pImageImportDescriptor->OriginalFirstThunk));
			}
			else
			{
				// 通过桥2获取thunk数据列表
				pImageThunkData = (PIMAGE_THUNK_DATA)(_lpFile +
					_RVAToOffset(_lpFile, pImageImportDescriptor->FirstThunk));
			}
			// *(PDWORD)pImageThunkData 解指针，获取thunk的地址
			// 直到pImageThunkData为00 00 00 00 为止
			while (*(PDWORD)pImageThunkData && dwFlag != 1)//加入一个永远成立的条件dwFlag != 1,
			{											   //该标志会由其他进程修改！！
														   //会在第十三章用到
				// 按序号导入
				if (*(PDWORD)pImageThunkData & IMAGE_ORDINAL_FLAG32)
				{
					wsprintf(szBuffer, TEXT("%08u(无函数名，按序号导入)\n"), 
						*(PDWORD)pImageThunkData & 0xffff);
				}
				else//按名称导入
				{
					// 通过thunk映射到函数编号和name结构
					pImageImportByName = (PIMAGE_IMPORT_BY_NAME)
						// 通过trunk地址转换为文件中地址后转为函数编号和name结构
						(_lpFile + _RVAToOffset(_lpFile, *(PDWORD)pImageThunkData));
					wsprintf(szBuffer, TEXT("%08u         %s\n"), pImageImportByName->Hint,
						pImageImportByName->Name);
				}
				_appendInfo(szBuffer);
				// 解析下一个函数
				++pImageThunkData;
			}
			// 解析下一个导入表
			++pImageImportDescriptor;
		}
	}
	else
	{
		_appendInfo(TEXT("\n\n未发现该文件有导入函数\n\n"));
	}
}



/*
* 获取PE文件的导出表
* _lpFile:		镜像起始偏移地址
* _lpPeHead:	pe头起始偏移地址
*/
void _getExportInfo(PTCHAR _lpFile, PTCHAR  _lpPeHead)
{
	// NT头结构
	PIMAGE_NT_HEADERS pImageNtHeaders;
	DWORD dwVirtualAddress;
	// 导出表结构
	PIMAGE_EXPORT_DIRECTORY pImageExportDirectory;
	TCHAR szBuffer[1024];
	TCHAR ** lpAddressOfNames;// TCHAR类型二级索引，目标是字符串数组时可以用
	PWORD lpAddressOfNameOrdinals; // PWORD是字类型的指针，目标是字类型的数组时可以用
	PDWORD lpAddressOfFunctions;//PDWORD时双字类型的指针，目标是双字类型的数组时可以用
	WORD wIndex;
	DWORD dwNumberOfFunctions, dwNumberOfNames;// 有名字的函数的个数
	PTCHAR dwFunRaw;// 函数名字符串指针

	TCHAR szMsgExport[] = TEXT("\n\n\n---------------------------------------------------------------------------------------------\n"
							   "导出表所处的节：%s\n"
							   "---------------------------------------------------------------------------------------------\n"
							   "原始文件名：%s\n"
							   "nBase               %08x\n"
							   "NumberOfFunctions   %08x\n"
							   "NuberOfNames        %08x\n"
							   "AddressOfFunctions  %08x\n"
							   "AddressOfNames      %08x\n"
							   "AddressOfNameOrd    %08x\n"
							   "-------------------------------------\n\n"
							   "导出序号    虚拟地址    导出函数名称\n"
							   "-------------------------------------\n");

	// 转为NT头
	pImageNtHeaders = (PIMAGE_NT_HEADERS)_lpPeHead;
	// 导出表RVA
	dwVirtualAddress = pImageNtHeaders->OptionalHeader.DataDirectory[0].VirtualAddress;
	if (dwVirtualAddress)// 导出表位置合法
	{
		// 计算导出表所在文件偏移位置
		pImageExportDirectory = (PIMAGE_EXPORT_DIRECTORY)(_lpFile +
			_RVAToOffset(_lpFile, dwVirtualAddress));

		wsprintf(szBuffer, szMsgExport, 
			_getRVASectionName(_lpFile, pImageExportDirectory->Name),// 节名
			_lpFile + _RVAToOffset(_lpFile, pImageExportDirectory->Name),// dll名称
			pImageExportDirectory->Base, // 导出函数的起始序号
			pImageExportDirectory->NumberOfFunctions,// 导出函数的总数
			pImageExportDirectory->NumberOfNames, // 导出有名字的函数的总数
			pImageExportDirectory->AddressOfFunctions,// 函数的地址表
			pImageExportDirectory->AddressOfNames, // 函数名字符串地址
			pImageExportDirectory->AddressOfNameOrdinals);// 对人来说，无意义，用函数名定位就行
		_appendInfo(szBuffer);

		// 函数名字的地址表
		lpAddressOfNames = (TCHAR **)(_lpFile + _RVAToOffset(_lpFile,
			pImageExportDirectory->AddressOfNames));
		
		// 函数编号的地址表
		lpAddressOfNameOrdinals = (PWORD)(_lpFile + _RVAToOffset(_lpFile,
			pImageExportDirectory->AddressOfNameOrdinals));
		
		// 函数的地址表
		lpAddressOfFunctions = (PDWORD)(_lpFile + _RVAToOffset(_lpFile,
			pImageExportDirectory->AddressOfFunctions));

		// 导出函数的个数
		dwNumberOfFunctions = pImageExportDirectory->NumberOfFunctions;
		wIndex = 0;
		while (dwNumberOfFunctions--)
		{
			// 有名字的函数个数
			dwNumberOfNames = pImageExportDirectory->NumberOfNames;
			DWORD i;
			for (i = 0; i < dwNumberOfNames; ++i)
			{
				if (lpAddressOfNameOrdinals[i] == wIndex)//找编号
				{
					break;
				}
			}
			//找到函数名称
			if (i < dwNumberOfNames)
			{
				// 找到函数名地址，并转换为FOA，并转换为全局地址
				dwFunRaw = _lpFile + _RVAToOffset(_lpFile, (DWORD)lpAddressOfNames[i]);
			}
			else
			{
				dwFunRaw = TEXT("(按照序号导出)");
			}
			DWORD funcAddr = *lpAddressOfFunctions;
			wsprintf(szBuffer, TEXT("%08x      %08x      %s\n"), 
				pImageExportDirectory->Base+wIndex++,// 函数编号
				funcAddr, // 函数地址
				dwFunRaw);// 函数名
			lpAddressOfFunctions++;// 地址+1
			_appendInfo(szBuffer);
		}
	}
	else
	{
		_appendInfo(TEXT("\n\n未发现该文件有导出函数\n\n"));
	}
}



/*
* 获取PE文件的重定位信息
* _lpFile:		镜像起始偏移地址
* _lpPeHead:	pe头起始偏移地址
*/
void _getRelocInfo(PTCHAR _lpFile, PTCHAR  _lpPeHead)
{
	PIMAGE_NT_HEADERS pImageNtHeaders;//NT头
	DWORD dwVirtualAddress;//
	PIMAGE_BASE_RELOCATION pImageBaseRelocation;// 重定位表项
	int dwRelNum;// 重定位项数量
	PWORD lpRelAdd;// 重定位基地址
	DWORD dwRelAdd;
	TCHAR szBuffer[1024];

	TCHAR szMsgReloc2[] = TEXT("\n--------------------------------------------------------------------------------------------\n"
								"重定位基地址： %08x\n"
								"重定位项数量： %d\n"
								"--------------------------------------------------------------------------------------------\n"
								"需要重定位的地址列表(ffffffff表示对齐用,不需要重定位)\n"
								"--------------------------------------------------------------------------------------------\n");





	// 转NT头
	pImageNtHeaders = (PIMAGE_NT_HEADERS)_lpPeHead;
	// 第6项数据目录项为重定位表，找到重定位表RVA
	dwVirtualAddress = pImageNtHeaders->OptionalHeader.DataDirectory[5].VirtualAddress;
	if (dwVirtualAddress)// RVA不为空
	{

		wsprintf(szBuffer, TEXT("\n重定位表所处的节：%s\n"),
			// 定位重定位表所在的节
			_getRVASectionName(_lpFile, dwVirtualAddress));
		_appendInfo(szBuffer);
		// 强转为重定位表现项
		pImageBaseRelocation = (PIMAGE_BASE_RELOCATION)(_lpFile + 
			_RVAToOffset(_lpFile, dwVirtualAddress));

		//循环处理每个重定位块
		while (pImageBaseRelocation->VirtualAddress && dwFlag != 1)//加入一个永远成立的条件dwFlag != 1,
		{											 			   //该标志会由其他进
																   //会在第十三章用到，动态补丁中会用到
			// 项数
			dwRelNum = (pImageBaseRelocation->SizeOfBlock - sizeof(IMAGE_BASE_RELOCATION)) / 2;
			wsprintf(szBuffer, szMsgReloc2, pImageBaseRelocation->VirtualAddress, dwRelNum);
			// 追加到控件
			_appendInfo(szBuffer);

			// 指向第一个重定位项
			lpRelAdd = (PWORD)(pImageBaseRelocation + 1);
			for (int i = 0; i < dwRelNum && dwFlag != 1; ++i)//加入一个永远成立的条件dwFlag != 1,
			{								  				 //该标志会由其他进
										 					 //会在第十三章用到，动态补丁中会用到
				// 重定位地址指向的双字的32位都需要修正（高4位为3，都需要修正）
				if ((*lpRelAdd & 0xf000) == 0x3000)// 取出值清空低24位 判断 是否等于3
				{
					// 取出值 重定位后的偏移 = 清空高4位 + 重定位表项起始偏移
					dwRelAdd = (*lpRelAdd & 0x0fff) + pImageBaseRelocation->VirtualAddress;
				}
				else
				{
					dwRelAdd = -1;
				}
				wsprintf(szBuffer, TEXT("%08x  "), dwRelAdd);
				if ((i + 1) % 8 == 0)//每显示8个项目换行
				{
					lstrcat(szBuffer, TEXT("\n"));
				}
				_appendInfo(szBuffer);

				++lpRelAdd;//指向下一个重定位项

			}

			if (dwRelNum % 8)
			{
				_appendInfo(TEXT("\n"));
			}
			// 指向下一个重定位块
			pImageBaseRelocation = (PIMAGE_BASE_RELOCATION)lpRelAdd;

		}

	}
	else
	{
		_appendInfo(TEXT("\n\n未发现该文件有重定位信息.\n\n"));
	}
}




/*
递归函数，遍历资源表项
_lpFile：文件地址
_lpRes：资源表地址
_lpResDir：目录地址
_dwLevel：目录级别
*/
void _processRes(PTCHAR _lpFile, PTCHAR _lpRes, PTCHAR _lpResDir, DWORD _dwLevel)
{
	PIMAGE_RESOURCE_DIRECTORY pResourceDirectory;
	DWORD dwNumber;
	PIMAGE_RESOURCE_DIRECTORY_ENTRY pResourceDirectoryEntry;
	DWORD OffsetToData;
	DWORD dwName;
	TCHAR szResName[256];
	PTCHAR lpResName;
	TCHAR szBuffer[1024];



	TCHAR szType[][16] = {TEXT("1-光标         "),
						  TEXT("2-位图         "),
						  TEXT("3-图标         "),
						  TEXT("4-菜单         "),
						  TEXT("5-对话框       "),
						  TEXT("6-字符串       "),
						  TEXT("7-字体目录     "),
						  TEXT("8-字体         "),
						  TEXT("9-加速键       "),
						  TEXT("10-未格式化资源"),
						  TEXT("11-消息表      "),
						  TEXT("12-光标组      "),
						  TEXT("13-未知类型    "),
						  TEXT("14-图标组      "),
						  TEXT("15-未知类型    "),
						  TEXT("16-版本信息    ") };

	TCHAR szOut5[] = TEXT("%d(自定义编号)");
	TCHAR szLevel1[] = TEXT("|-- %s\n"
							"|   |\n");
	TCHAR szLevel2[] = TEXT("|   |-- %s\n"
							"|   |     |\n");
	TCHAR szOut6[] = TEXT("|   |-- ID %d\n"
						  "|   |     |\n");
	TCHAR szLevel3[] = TEXT("|   |     |-- 代码页：%d   资源所在文件位置：0x%08x  资源长度：%d\n");


	pResourceDirectory = (PIMAGE_RESOURCE_DIRECTORY)_lpResDir;//指向目录表
	dwNumber = pResourceDirectory->NumberOfIdEntries + pResourceDirectory->NumberOfNamedEntries;//计算目录项的个数
	pResourceDirectoryEntry = (PIMAGE_RESOURCE_DIRECTORY_ENTRY)(pResourceDirectory + 1);//跳过目录头定位到目录项



	while (dwNumber > 0 && dwFlag != 1)//加入一个永远成立的条件dwFlag != 1,
	{					 			  //该标志会由其他进
									 //会在第十三章用到
		OffsetToData = pResourceDirectoryEntry->OffsetToData;//查看IMAGE_RESOURCE_DIRECTORY_ENTRY.OffsetToData
		if (OffsetToData & 0x80000000)//如果最高位为1
		{
			OffsetToData = (OffsetToData & 0x7fffffff) + (DWORD)_lpRes;//为下一次递归准备第三个参数,偏移是基于资源表起始地址的
			if (_dwLevel == 1)//如果是第一级资源类别
			{
				dwName = pResourceDirectoryEntry->Name;
				if (dwName & 0x80000000)//如果是按名称定义的资源类型
				{
					dwName = (dwName & 0x7fffffff) + (DWORD)_lpRes;//指向了名称字符串结构IMAGE_RESOURCE_DIR_STRING_U
					WideCharToMultiByte(CP_ACP, WC_COMPOSITECHECK,//将UNICODE字符转换为多字节字符
						((PIMAGE_RESOURCE_DIR_STRING_U)dwName)->NameString,//名字地址
						((PIMAGE_RESOURCE_DIR_STRING_U)dwName)->Length, //名字长度
						szResName, sizeof szResName, NULL, NULL);
					szResName[((PIMAGE_RESOURCE_DIR_STRING_U)dwName)->Length] = 0;//结束符
					lpResName = szResName;//指向了名称字符串
				}
				else//如果是按编号定义的资源类型
				{
					if (dwName <= 0x10)//系统内定的资源编号
					{
						lpResName = szType[dwName - 1];//定位编号所在字符串
					}
					else//自定义资源类型
					{
						wsprintf(szResName, szOut5, dwName);
						lpResName = szResName;
					}
				}
				wsprintf(szBuffer, szLevel1, lpResName);
			}
			else if (_dwLevel == 2)//如果是第二级资源ID
			{
				dwName = pResourceDirectoryEntry->Name;
				if (dwName & 0x80000000) //如果是按字符串定义的资源ID
				{
					dwName = (dwName & 0x7fffffff) + (DWORD)_lpRes;
					WideCharToMultiByte(CP_ACP, WC_COMPOSITECHECK,//将UNICODE字符转换为多字节字符
						((PIMAGE_RESOURCE_DIR_STRING_U)dwName)->NameString,
						((PIMAGE_RESOURCE_DIR_STRING_U)dwName)->Length,
						szResName, sizeof szResName, NULL, NULL);
					szResName[((PIMAGE_RESOURCE_DIR_STRING_U)dwName)->Length] = 0;//结束符
					wsprintf(szBuffer, szLevel2, szResName);
				}
				else//如果是按编号定义的资源类型
				{
					wsprintf(szBuffer, szOut6, dwName);
				}
			}
			else
			{//跳出递归
				break;
			}

			_appendInfo(szBuffer);
			_processRes(_lpFile, _lpRes, (PTCHAR)OffsetToData, _dwLevel + 1);
		}
		//如果IMAGE_RESOURCE_DIRECTORY_ENTRY.OffsetToData最高位为0
		else//第三级目录 
		{
			OffsetToData += (DWORD)_lpRes;

			wsprintf(szBuffer, szLevel3,pResourceDirectoryEntry->Name,//代码页
				_RVAToOffset(_lpFile, ((PIMAGE_RESOURCE_DATA_ENTRY)OffsetToData)->OffsetToData),
				 ((PIMAGE_RESOURCE_DATA_ENTRY)OffsetToData)->Size);

			_appendInfo(szBuffer);
		}

		++pResourceDirectoryEntry;
		--dwNumber;
	}
}



/*
获取PE文件的资源信息
*/
void _getResource(PTCHAR _lpFile, PTCHAR  _lpPeHead)
{
	PIMAGE_NT_HEADERS pNtHeaders;
	DWORD dwVirtualAddress;
	TCHAR szBuffer[1024];
	PTCHAR lpRes;


	TCHAR szOut4[] = TEXT("\n\n\n"
						  "---------------------------------------------------------------------------------------------\n"
						  "资源表所处的节：%s\n"
						  "---------------------------------------------------------------------------------------------\n"
						  "\n\n"
						  "根目录\n"
						  "|\n");


	pNtHeaders = (PIMAGE_NT_HEADERS)_lpPeHead;
	if (dwVirtualAddress = (pNtHeaders->OptionalHeader.DataDirectory)[2].VirtualAddress)
	{
		wsprintf(szBuffer, szOut4, _getRVASectionName(_lpFile, dwVirtualAddress));
		_appendInfo(szBuffer);

		//求资源表在文件的偏移
		lpRes = _lpFile + _RVAToOffset(_lpFile, dwVirtualAddress);

		//传入的四个参数分别表示
		//1、文件头位置
		//2、资源表位置
		//3、目录位置
		//4、目录级别
		_processRes(_lpFile, lpRes, lpRes, 1);
	}
	else
	{
		_appendInfo(TEXT("\n未发现该文件有资源表\n"));
		return;
	}


}





/*
打开PE文件并处理
*/
void _openFile(HWND hWinMain)
{
	OPENFILENAME stOF;
	HANDLE hFile, hMapFile;
	DWORD dwFileSize;		//文件大小
	PTCHAR lpMemory;		//内存映像文件在内存的起始位置
	PTCHAR lpMem;


	TCHAR szFileName[MAX_PATH] = { 0 };	//要打开的文件路径及名称名
	TCHAR szExtPe[] = TEXT("PE Files\0*.exe;*.dll;*.scr;*.fon;*.drv\0All Files(*.*)\0*.*\0\0");



	RtlZeroMemory(&stOF, sizeof(stOF));
	stOF.lStructSize = sizeof(stOF);
	stOF.hwndOwner = hWinMain;
	stOF.lpstrFilter = szExtPe;
	stOF.lpstrFile = szFileName;
	stOF.nMaxFile = MAX_PATH;
	stOF.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST;

	if (GetOpenFileName(&stOF))		//让用户选择打开的文件
	{
		hFile = CreateFile(szFileName, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE,
			NULL, OPEN_EXISTING, FILE_ATTRIBUTE_ARCHIVE, NULL);
		if (hFile != INVALID_HANDLE_VALUE)
		{
			dwFileSize = GetFileSize(hFile, NULL);//获取文件大小
			if (dwFileSize)
			{
				hMapFile = CreateFileMapping(hFile, NULL, PAGE_READONLY, 0, 0, NULL);//内存映射文件
				if (hMapFile)
				{
					lpMemory = (PTCHAR)MapViewOfFile(hMapFile, FILE_MAP_READ, 0, 0, 0);//获得文件在内存的映象起始位置
					if (lpMemory)
					{
						if (((PIMAGE_DOS_HEADER)lpMemory)->e_magic == IMAGE_DOS_SIGNATURE)//判断是否有MZ字样
						{
							// 镜像起始地址+PE文件偏移，拿到PE起始地址
							lpMem = lpMemory + ((PIMAGE_DOS_HEADER)lpMemory)->e_lfanew;
							if (((PIMAGE_NT_HEADERS)lpMem)->Signature == IMAGE_NT_SIGNATURE)//判断是否有PE字样
							{
								// 到此为止，该文件的验证已经完成。为PE结构文件
								// 接下来分析分件映射到内存中的数据，并显示主要参数
								_getMainInfo(lpMem, szFileName);

								//显示导入表
								_getImportInfo(lpMemory, lpMem);

								//显示导出表
								_getExportInfo(lpMemory, lpMem);

								//显示重定位信息
								_getRelocInfo(lpMemory, lpMem);

								//显示资源表信息
								_getResource(lpMemory, lpMem);

							}
							else
							{
								MessageBox(hWinMain, TEXT("这个文件不是PE格式的文件!"), NULL, MB_OK);
							}
						}
						else
						{
							MessageBox(hWinMain, TEXT("这个文件不是PE格式的文件!"), NULL, MB_OK);
						}
						UnmapViewOfFile(lpMemory);
					}
					CloseHandle(hMapFile);
				}
			}
			CloseHandle(hFile);
		}
	}
}





/*
窗口程序
*/
INT_PTR CALLBACK _ProcDlgMain(HWND hWnd, UINT wMsg, WPARAM wParam, LPARAM lParam)
{
	switch (wMsg)
	{
	case WM_CLOSE:
		EndDialog(hWnd, 0);
		break;

	case WM_INITDIALOG:			//初始化
		_Init(hWnd);
		break;

	case WM_COMMAND:			//菜单
		switch (LOWORD(wParam))
		{
		case IDM_EXIT:			//退出
			EndDialog(hWnd, 0);
			break;

		case IDM_OPEN:			//打开文件
			_openFile(hWnd);
			break;

		case IDM_1:
		case IDM_2:
		case IDM_3:
		default:
			break;
		}
		break;

	default:
		return FALSE;
	}

	return TRUE;
}



int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	HMODULE hRichEdit;

	hInstance = hInst;
	hRichEdit = LoadLibrary(TEXT("RichEd20.dll"));
	DialogBoxParam(hInstance, MAKEINTRESOURCE(DLG_MAIN), NULL, _ProcDlgMain, (LPARAM)NULL);
	FreeLibrary(hRichEdit);
	return 0;
}