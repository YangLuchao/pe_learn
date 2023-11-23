#include <windows.h>
#include <Richedit.h>
#include <Commctrl.h>
#include "resource.h"


HINSTANCE hInstance;
DWORD dwCount;

HWND hWinEdit;	//富文本框句柄


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
	SendMessage(hWinMain, WM_SETICON, ICON_BIG, (LPARAM)hIcon);//为窗口设置图标
	SendMessage(hWinEdit, EM_SETTEXTMODE, TM_PLAINTEXT, 0);//设置编辑控件

	RtlZeroMemory(&stCf, sizeof(stCf));
	stCf.cbSize = sizeof(stCf);
	stCf.yHeight = 10 * 20;
	stCf.dwMask = CFM_FACE | CFM_SIZE | CFM_BOLD;
	lstrcpy(stCf.szFaceName, szFont);
	SendMessage(hWinEdit, EM_SETCHARFORMAT, 0, (LPARAM)&stCf);
	SendMessage(hWinEdit, EM_EXLIMITTEXT, 0, -1);
}

/*
 清除ListView中的内容
 删除所有的行和所有的列
*/
void _ListViewClear(HWND _hWinView)
{
	SendMessage(_hWinView, LVM_DELETEALLITEMS, 0, 0);

	while (SendMessage(_hWinView, LVM_DELETECOLUMN, 0, 0)) {}
}


/*
在ListView中增加一个列
输入：_dwColumn = 增加的列编号
_dwWidth = 列的宽度
_lpszHead = 列的标题字符串
*/
void _ListViewAddColumn(HWND _hWinView, DWORD _dwColumn, DWORD _dwWidth, PTCHAR _lpszHead)
{
	LV_COLUMN stLVC;

	RtlZeroMemory(&stLVC, sizeof(LV_COLUMN));
	stLVC.mask = LVCF_TEXT | LVCF_WIDTH | LVCF_FMT;
	stLVC.fmt = LVCFMT_LEFT;
	stLVC.pszText = _lpszHead;
	stLVC.cx = _dwWidth;
	stLVC.iSubItem = _dwColumn;
	SendMessage(_hWinView, LVM_INSERTCOLUMN, _dwColumn, (LPARAM)&stLVC);
}

/*
初始化结果表格
*/
void _clearResultView(HWND hProcessModuleTable)
{
	_ListViewClear(hProcessModuleTable);

	//添加表头
	_ListViewAddColumn(hProcessModuleTable, 1, 200, TEXT("PE数据结构相关字段"));
	_ListViewAddColumn(hProcessModuleTable, 2, 222, TEXT("文件1的值(H)"));
	_ListViewAddColumn(hProcessModuleTable, 3, 222, TEXT("文件2的值(H)"));

	dwCount = 0;
}


void _GetListViewItem(HWND _hWinView, DWORD _dwLine, DWORD  _dwCol, PTCHAR _lpszText)
{
	LV_ITEM stLVI;


	RtlZeroMemory(&stLVI, sizeof(LV_ITEM));
	RtlZeroMemory(_lpszText, 512);

	stLVI.cchTextMax = 512;
	stLVI.mask = LVIF_TEXT;
	stLVI.pszText = _lpszText;
	stLVI.iSubItem = _dwCol;
	SendMessage(_hWinView, LVM_GETITEMTEXT, _dwLine, (LPARAM)&stLVI);
}


int _MemCmp(PTCHAR _lp1, PTCHAR _lp2, int  _size)
{
	DWORD dwResult = 0;

	for (int i = 0; i < _size; ++i)
	{
		if (_lp1[i] != _lp2[i])
		{
			dwResult = 1;
			break;
		}
	}
	return dwResult;
}



/*
在ListView中新增一行，或修改一行中某个字段的内容
输入：_dwItem = 要修改的行的编号
_dwSubItem = 要修改的字段的编号，-1表示插入新的行，>=1表示字段的编号
*/
DWORD _ListViewSetItem(HWND _hWinView, DWORD _dwItem, DWORD _dwSubItem, PTCHAR _lpszText)
{
	LV_ITEM stLVI;


	RtlZeroMemory(&stLVI, sizeof(LV_ITEM));
	stLVI.cchTextMax = lstrlen(_lpszText);
	stLVI.mask = LVIF_TEXT;
	stLVI.pszText = _lpszText;
	stLVI.iItem = _dwItem;
	stLVI.iSubItem = _dwSubItem;

	if (_dwSubItem == -1)
	{
		stLVI.iSubItem = 0;
		return SendMessage(_hWinView, LVM_INSERTITEM, 0, (LPARAM)&stLVI);
	}
	else
	{
		return SendMessage(_hWinView, LVM_SETITEM, 0, (LPARAM)&stLVI);
	}
}



/*
* 将_lpSZ位置处_Size个字节转换为16进制的字符串
* szBuffer处为转换后的字符串
*/
void _Byte2Hex(PTCHAR _lpSZ, PTCHAR szBuffer, int _Size)
{
	TCHAR szBuf[4];

	for (int i = 0; i < _Size; ++i)
	{
		wsprintf(szBuf, TEXT("%02X "), (TBYTE)_lpSZ[i]);
		lstrcat(szBuffer, szBuf);
	}
}

// 添加一行展示
void _addLine(HWND hProcessModuleTable, PTCHAR _lpSZ, PTCHAR _lpSP1, PTCHAR _lpSP2, int _Size)
{
	TCHAR szBuffer[256];
	// 在表格中添加一行
	dwCount = _ListViewSetItem(hProcessModuleTable, dwCount, -1, _lpSZ); // 在表格中新增加一行
	_ListViewSetItem(hProcessModuleTable, dwCount, 0, _lpSZ);//显示字段名

	//将指定字段按照十六进制显示，格式：一个字节+一个空格
	RtlZeroMemory(szBuffer, 256);
	// 将字节转换为16进制
	_Byte2Hex(_lpSP1, szBuffer, _Size);
	_ListViewSetItem(hProcessModuleTable, dwCount, 1, szBuffer);//第一个文件中的值

	RtlZeroMemory(szBuffer, 256);
	_Byte2Hex(_lpSP2, szBuffer, _Size);
	_ListViewSetItem(hProcessModuleTable, dwCount, 2, szBuffer);//第二个文件中的值
}


/*
* 出来dos头信息
* IMAGE_DOS_HEADER头信息
*/
void _Header1(HWND hProcessModuleTable, PTCHAR lpMemory, PTCHAR lpMemory1)
{
	// dos头结构每个属性所占字节数
	int offbuf[19] = { 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 8, 2, 2, 20, 4 };
	// dos头每个属性的名称
	TCHAR szRec[19][30] = { TEXT("IMAGE_DOS_HEADER.e_magic"),	// DOS头标识
						   TEXT("IMAGE_DOS_HEADER.e_cblp"),		// 
						   TEXT("IMAGE_DOS_HEADER.e_cp"),
						   TEXT("IMAGE_DOS_HEADER.e_crlc"),
						   TEXT("IMAGE_DOS_HEADER.e_cparhdr"),
						   TEXT("IMAGE_DOS_HEADER.e_minalloc"),
						   TEXT("IMAGE_DOS_HEADER.e_maxalloc"),
						   TEXT("IMAGE_DOS_HEADER.e_ss"),
						   TEXT("IMAGE_DOS_HEADER.e_sp"),
						   TEXT("IMAGE_DOS_HEADER.e_csum"),
						   TEXT("IMAGE_DOS_HEADER.e_ip"),
						   TEXT("IMAGE_DOS_HEADER.e_cs"),
						   TEXT("IMAGE_DOS_HEADER.e_lfarlc"),
						   TEXT("IMAGE_DOS_HEADER.e_ovno"),
						   TEXT("IMAGE_DOS_HEADER.e_res"),
						   TEXT("IMAGE_DOS_HEADER.e_oemid"),
						   TEXT("IMAGE_DOS_HEADER.e_oeminfo"),
						   TEXT("IMAGE_DOS_HEADER.e_res2"),
						   TEXT("IMAGE_DOS_HEADER.e_lfanew"),// PE头相对偏移
	};

	for (int i = 0, off = 0; i < 19; ++i)
	{
		// 添加一行展示
		// 拿到对应属性后添加到组件中
		_addLine(hProcessModuleTable, szRec[i], lpMemory + off, lpMemory1 + off, offbuf[i]);
		// 偏移+1
		off += offbuf[i];
	}
}


/*
* IMAGE_DOS_HEADER头信息
* 处理PE头
*/
void _Header2(HWND hProcessModuleTable, PTCHAR lpMemory, PTCHAR lpMemory1)
{
	// pe头每个属性位置及所占字节数
	int offbuf[70] = { 4, 2, 2, 4, 4, 4, 2, 2, 2, 1, 1, 4, 4, 4, 4, 4, 4, 4, 4, 4, 2, 2, 2, 2, 2, 2,
		4, 4, 4, 4, 2, 2, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
		4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4 };
	// pe头每个属性的名字
	TCHAR szRec[70][60] = { TEXT("IMAGE_NT_HEADERS.Signature"),	// PE头标识 50 45 00 00 
							// 文件头
							TEXT("IMAGE_FILE_HEADER.Machine"),	// 运行平台
							TEXT("IMAGE_FILE_HEADER.NumberOfSections"),//pe中节的数量
							TEXT("IMAGE_FILE_HEADER.TimeDateStamp"),// 文件创建日期和时间
							TEXT("IMAGE_FILE_HEADER.PointerToSymbolTable"),//指向符号表
							TEXT("IMAGE_FILE_HEADER.NumberOfSymbols"),// 符号表中符号数量
							TEXT("IMAGE_FILE_HEADER.SizeOfOptionalHeader"),//扩展头的长度
							TEXT("IMAGE_FILE_HEADER.Characteristics"),// 文件的属性
							// 扩展头
							TEXT("IMAGE_OPTIONAL_HEADER32.Magic"),	// 魔术字
							TEXT("IMAGE_OPTIONAL_HEADER32.MajorLinkerVersion"),//链接器大版本
							TEXT("IMAGE_OPTIONAL_HEADER32.MinorLinkerVersion"),//链接器小版本
							TEXT("IMAGE_OPTIONAL_HEADER32.SizeOfCode"),	// 代码节总大小
							TEXT("IMAGE_OPTIONAL_HEADER32.SizeOfInitializedData"),//已初始化节大小
							TEXT("IMAGE_OPTIONAL_HEADER32.SizeOfUninitializedData"),//未初始化节大小
							TEXT("IMAGE_OPTIONAL_HEADER32.AddressOfEntryPoint"),//程序执行入口RAV
							TEXT("IMAGE_OPTIONAL_HEADER32.BaseOfCode"),//代码节起始RVA
							TEXT("IMAGE_OPTIONAL_HEADER32.BaseOfData"),//数据节起始RVA
							TEXT("IMAGE_OPTIONAL_HEADER32.ImageBase"),//程序的建议装载地址，exe:0040 0000 dll:0010 0000
							TEXT("IMAGE_OPTIONAL_HEADER32.SectionAlignment"),//内存中对齐粒度
							TEXT("IMAGE_OPTIONAL_HEADER32.FileAlignment"),// 文件中对齐粒度
							TEXT("IMAGE_OPTIONAL_HEADER32.MajorOperatingSystemVersion"),//操作系统大版本号
							TEXT("IMAGE_OPTIONAL_HEADER32.MinorOperatingSystemVersion"),//操作系统小版本好
							TEXT("IMAGE_OPTIONAL_HEADER32.MajorImageVersion"),//该PE的大版本号
							TEXT("IMAGE_OPTIONAL_HEADER32.MinorImageVersion"),//该PE的小版本号
							TEXT("IMAGE_OPTIONAL_HEADER32.MajorSubsystemVersion"),//所需子系统的大版本号,
							TEXT("IMAGE_OPTIONAL_HEADER32.MinorSubsystemVersion"),// 所需子系统的小版本号
							TEXT("IMAGE_OPTIONAL_HEADER32.Win32VersionValue"),// 未用，忽略
							TEXT("IMAGE_OPTIONAL_HEADER32.SizeOfImage"),// 内存中整个PE镜像的大小
							TEXT("IMAGE_OPTIONAL_HEADER32.SizeOfHeaders"),// 所有头+节表的大小
							TEXT("IMAGE_OPTIONAL_HEADER32.CheckSum"),//校验和
							TEXT("IMAGE_OPTIONAL_HEADER32.Subsystem"),// 文件的子系统
							TEXT("IMAGE_OPTIONAL_HEADER32.DllCharacteristics"),// dll的文件特性
							TEXT("IMAGE_OPTIONAL_HEADER32.SizeOfStackReserve"),//初始化时的栈大小
							TEXT("IMAGE_OPTIONAL_HEADER32.SizeOfStackCommit"),// 初始化时实际提交的栈大小
							TEXT("IMAGE_OPTIONAL_HEADER32.SizeOfHeapReserve"),// 初始化时保留的堆大小
							TEXT("IMAGE_OPTIONAL_HEADER32.SizeOfHeapCommit"),// 初始化时实际提交的堆大小
							TEXT("IMAGE_OPTIONAL_HEADER32.LoaderFlags"),// 忽略
							TEXT("IMAGE_OPTIONAL_HEADER32.NumberOfRvaAndSizes"),// 数据目录项个数，一般都是16个
							// 数据目录项
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(Export)"),// 导出表RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(Export)"),// 导出表大小
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(Import)"),// 导入白RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(Import)"),// 导入表大小
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(Resource)"),// 资源表RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(Resource)"),// 资源表大小
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(Exception)"),// 异常表RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(Exception)"),// 异常表大小
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(Security)"),// 安全表RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(Security)"),// 安全表大小
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(BaseReloc)"),// 重定向表RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(BaseReloc)"),// 重定向表大小
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(Debug)"),// 调试表RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(Debug)"),// 调试表大小
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(Architecture)"),//版权表RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(Architecture)"),// 版权表大小
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(GlobalPTR)"),// 全局指针表RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(GlobalPTR)"),// 全局指针表大小
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(TLS)"),// 线程本地存储表RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(TLS)"),// 线程本地存储表大小
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(Load_Config)"),// 加载配置表RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(Load_Config)"),// 加载配置表大小
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(Bound_Import)"),// 绑定导入表RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(Bound_Import)"),// 绑定导入表大小
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(IAT)"),// IAT（导入地址表）表RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(IAT)"),// IAT(导入地址表)大小
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(Delay_Import)"),// 延迟导入表RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(Delay_Import)"),// 延迟导入表大小
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(Com_Descriptor)"),// CLR表RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(Com_Descriptor)"),// CLR表大小
							TEXT("IMAGE_DATA_DIRECTORY.VirtualAddress(Reserved)"),// 预留表RVA
							TEXT("IMAGE_DATA_DIRECTORY.isize(Reserved)") };// 预留表大小

	for (int i = 0, off = 0; i < 70; ++i)
	{
		// 读取每项的结果并转成16进制输出到控件
		_addLine(hProcessModuleTable, szRec[i], lpMemory + off, lpMemory1 + off, offbuf[i]);
		// 偏移+1
		off += offbuf[i];
	}
}


/*
* 处理节表
*/
void _Header3(HWND hProcessModuleTable, PTCHAR lpMemory, PTCHAR lpMemory1, DWORD _dwValue)
{
	int offbuf[10] = { 8, 4, 4, 4, 4, 4, 4, 2, 2, 4 };
	TCHAR szBuffer[256];
	TCHAR szRec[10][50] = { TEXT("IMAGE_SECTION_HEADER%d.Name1"),// 节区名称
							TEXT("IMAGE_SECTION_HEADER%d.VirtualSize"),// 节区尺寸
							TEXT("IMAGE_SECTION_HEADER%d.VirtualAddress"),// 节区RVA地址
							TEXT("IMAGE_SECTION_HEADER%d.SizeOfRawData"),//在文件中对齐后的大小
							TEXT("IMAGE_SECTION_HEADER%d.PointerToRawData"),//在文件中的偏移
							TEXT("IMAGE_SECTION_HEADER%d.PointerToRelocations"),//在OBJ中使用
							TEXT("IMAGE_SECTION_HEADER%d.PointerToLinenumbers"),// 行号表位置(调试用)
							TEXT("IMAGE_SECTION_HEADER%d.NumberOfRelocations"),// 在OBJ中使用
							TEXT("IMAGE_SECTION_HEADER%d.NumberOfLinenumbers"),// 行号表中行号数量
							TEXT("IMAGE_SECTION_HEADER%d.Characteristics") };// 节属性


	for (int i = 0, off = 0; i < 10; ++i)
	{
		wsprintf(szBuffer, szRec[i], _dwValue);
		_addLine(hProcessModuleTable, szBuffer, lpMemory + off, lpMemory1 + off, offbuf[i]);
		off += offbuf[i];
	}
}




/*
打开PE文件并处理
*/
void _openFile(HWND hWinMain, HWND hProcessModuleTable, PTCHAR szFileNameOpen1, PTCHAR szFileNameOpen2)
{
	HANDLE hFile;
	HANDLE hMapFile = NULL;
	HANDLE hFile1;
	HANDLE hMapFile1 = NULL;
	DWORD dwFileSize, dwFileSize1;
	static LPVOID lpMemory, lpMemory1;



	// 创建文件句柄
	hFile = CreateFile(szFileNameOpen1, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL,
		OPEN_EXISTING, FILE_ATTRIBUTE_ARCHIVE, NULL);
	// 判断是否非法
	if (hFile != INVALID_HANDLE_VALUE)
	{
		// 获取文件大小
		dwFileSize = GetFileSize(hFile, NULL);
		if (dwFileSize)// 判断文件存在
		{
			// 创建文件内存映射
			hMapFile = CreateFileMapping(hFile, NULL, PAGE_READONLY, 0, 0, NULL);// 内存映射文件
			if (hMapFile)
			{
				// 获取文件映射起始偏移
				lpMemory = MapViewOfFile(hMapFile, FILE_MAP_READ, 0, 0, 0);
				// 判断是否为PE文件
				if (((PIMAGE_DOS_HEADER)lpMemory)->e_magic != IMAGE_DOS_SIGNATURE)//判断是否有MZ字样
				{
				_ErrFormat:
					MessageBox(hWinMain, TEXT("这个文件不是PE格式的文件!"), NULL, MB_OK);
					UnmapViewOfFile(lpMemory);
					CloseHandle(hMapFile);
					CloseHandle(hFile);
					return;
				}
				if (((PIMAGE_NT_HEADERS)((PTCHAR)lpMemory +
					((PIMAGE_DOS_HEADER)lpMemory)->e_lfanew))->Signature !=
					IMAGE_NT_SIGNATURE)//判断是否有PE字样
				{
					goto _ErrFormat;
				}
			}
		}
	}


	// 创建文件1
	hFile1 = CreateFile(szFileNameOpen2, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL,
		OPEN_EXISTING, FILE_ATTRIBUTE_ARCHIVE, NULL);
	// 判断文件1是否非法
	if (hFile1 != INVALID_HANDLE_VALUE)
	{
		// 获取文件1大小
		dwFileSize1 = GetFileSize(hFile1, NULL);
		if (dwFileSize1)
		{
			// 创建内存映射
			hMapFile1 = CreateFileMapping(hFile1, NULL, PAGE_READONLY, 0, 0, NULL);// 内存映射文件
			if (hMapFile1)
			{
				// 获取内存映射起始地址
				lpMemory1 = MapViewOfFile(hMapFile1, FILE_MAP_READ, 0, 0, 0);
				// 判断是否为PE文件
				if (((PIMAGE_DOS_HEADER)lpMemory1)->e_magic != IMAGE_DOS_SIGNATURE)//判断是否有MZ字样
				{
				_ErrFormat1:
					MessageBox(hWinMain, TEXT("这个文件不是PE格式的文件!"), NULL, MB_OK);
					UnmapViewOfFile(lpMemory1);
					CloseHandle(hMapFile1);
					CloseHandle(hFile1);
					return;
				}

				if (((PIMAGE_NT_HEADERS)((PTCHAR)lpMemory1 +
					((PIMAGE_DOS_HEADER)lpMemory1)->e_lfanew))->Signature !=
					IMAGE_NT_SIGNATURE)//判断是否有PE字样
				{
					goto _ErrFormat1;
				}
			}
		}
	}

	/*
	到此为止，两个内存文件的指针已经获取到了。
	lpMemory和lpMemory1分别指向两个文件头
	下面是从这个文件头开始，找出各数据结构的字段值，进行比较。
	*/
	// 处理dos头
	_Header1(hProcessModuleTable, (PTCHAR)lpMemory, (PTCHAR)lpMemory1);

	// 调整指针指向PE文件头
	(PTCHAR)lpMemory += ((PIMAGE_DOS_HEADER)lpMemory)->e_lfanew;
	(PTCHAR)lpMemory1 += ((PIMAGE_DOS_HEADER)lpMemory1)->e_lfanew;
	// 处理NT头
	_Header2(hProcessModuleTable, (PTCHAR)lpMemory, (PTCHAR)lpMemory1);


	// 节的数量
	WORD dNum, dNum1, dNum2;
	dNum1 = ((PIMAGE_NT_HEADERS)lpMemory)->FileHeader.NumberOfSections;
	dNum2 = ((PIMAGE_NT_HEADERS)lpMemory1)->FileHeader.NumberOfSections;
	// 哪个应用节多用哪个做阈值
	dNum = dNum1 > dNum2 ? dNum1 : dNum2;

	// 调整指针指向节表
	(PTCHAR)lpMemory += sizeof(IMAGE_NT_HEADERS);
	(PTCHAR)lpMemory1 += sizeof(IMAGE_NT_HEADERS);

	DWORD _dwValue = 1; //节序号
	while (dNum--)
	{
		// 处理节表
		_Header3(hProcessModuleTable, (PTCHAR)lpMemory, (PTCHAR)lpMemory1, _dwValue++);

		// 调整指针指向下一个节表
		(PTCHAR)lpMemory += sizeof(IMAGE_SECTION_HEADER);
		(PTCHAR)lpMemory1 += sizeof(IMAGE_SECTION_HEADER);
	}

	// 卸载镜像
	UnmapViewOfFile(lpMemory);
	// 关闭镜像
	CloseHandle(hMapFile);
	// 关闭文件
	CloseHandle(hFile);

	UnmapViewOfFile(lpMemory1);
	CloseHandle(hMapFile1);
	CloseHandle(hFile1);
}

/*
打开输入文件
*/
void _OpenFile1(HWND hWinMain, HWND hText1, PTCHAR szFileNameOpen1)
{
	OPENFILENAME stOF;


	RtlZeroMemory(&stOF, sizeof(stOF));
	stOF.lStructSize = sizeof(stOF);
	stOF.hwndOwner = hWinMain;
	stOF.hInstance = hInstance;
	stOF.lpstrFilter = TEXT("Excutable Files\0*.exe;*.com\0\0");
	stOF.lpstrFile = szFileNameOpen1;
	stOF.nMaxFile = MAX_PATH;
	stOF.Flags = OFN_FILEMUSTEXIST | OFN_HIDEREADONLY | OFN_PATHMUSTEXIST;
	if (GetOpenFileName(&stOF))//显示“打开文件”对话框
	{
		SetWindowText(hText1, szFileNameOpen1);
	}

}


/*
打开输入文件
*/
void _OpenFile2(HWND hWinMain, HWND hText2, PTCHAR szFileNameOpen2)
{
	OPENFILENAME stOF;


	RtlZeroMemory(&stOF, sizeof(stOF));
	stOF.lStructSize = sizeof(stOF);
	stOF.hwndOwner = hWinMain;
	stOF.hInstance = hInstance;
	stOF.lpstrFilter = TEXT("Excutable Files\0*.exe;*.com\0\0");
	stOF.lpstrFile = szFileNameOpen2;
	stOF.nMaxFile = MAX_PATH;
	stOF.Flags = OFN_FILEMUSTEXIST | OFN_HIDEREADONLY | OFN_PATHMUSTEXIST;
	if (GetOpenFileName(&stOF))//显示“打开文件”对话框
	{
		SetWindowText(hText2, szFileNameOpen2);
	}

}






INT_PTR CALLBACK _resultProcMain(HWND hProcessModuleDlg, UINT wMsg, WPARAM wParam, LPARAM lParam)
{
	static HWND hWinMain, hProcessModuleTable, hText1, hText2;
	TCHAR bufTemp1[0x200], bufTemp2[0x200];
	static TCHAR szFileNameOpen1[MAX_PATH], szFileNameOpen2[MAX_PATH];

	switch (wMsg)
	{
	case WM_CLOSE:
		EndDialog(hProcessModuleDlg, 0);
		break;

	case WM_INITDIALOG:			//初始化
		hWinMain = (HWND)lParam;

		hProcessModuleTable = GetDlgItem(hProcessModuleDlg, IDC_MODULETABLE);
		hText1 = GetDlgItem(hProcessModuleDlg, ID_TEXT1);
		hText2 = GetDlgItem(hProcessModuleDlg, ID_TEXT2);

		//定义表格外观
		SendMessage(hProcessModuleTable, LVM_SETEXTENDEDLISTVIEWSTYLE, 0,
			LVS_EX_GRIDLINES | LVS_EX_FULLROWSELECT);
		ShowWindow(hProcessModuleTable, SW_SHOW);

		_clearResultView(hProcessModuleTable);//清空表格内容
		break;

	case WM_NOTIFY:
		if (((NMHDR*)lParam)->hwndFrom == hProcessModuleTable)//更改各控件状态
		{
			if (((NMHDR*)lParam)->code == NM_CUSTOMDRAW)//绘画时
			{
				if (((NMLVCUSTOMDRAW*)lParam)->nmcd.dwDrawStage == CDDS_PREPAINT)
				{
					SetWindowLong(hProcessModuleDlg, DWL_MSGRESULT, CDRF_NOTIFYITEMDRAW);
				}
				else if (((NMLVCUSTOMDRAW*)lParam)->nmcd.dwDrawStage == CDDS_ITEMPREPAINT)
				{
					//当每一单元格内容预画时，判断两列的值是否一致
					//如果一致，则将文本的背景色设置为浅红色，否则黑色
					_GetListViewItem(hProcessModuleTable, ((NMLVCUSTOMDRAW*)lParam)->nmcd.dwItemSpec,
						1, bufTemp1);
					_GetListViewItem(hProcessModuleTable, ((NMLVCUSTOMDRAW*)lParam)->nmcd.dwItemSpec,
						2, bufTemp2);
					if (_MemCmp(bufTemp1, bufTemp2, lstrlen(bufTemp1)))
					{
						((NMLVCUSTOMDRAW*)lParam)->clrTextBk = 0xa0a0ff;
					}
					else
					{
						((NMLVCUSTOMDRAW*)lParam)->clrTextBk = 0xffffff;
					}
					SetWindowLong(hProcessModuleDlg, DWL_MSGRESULT, CDRF_DODEFAULT);
				}
			}
		}
		break;

	case WM_COMMAND:			//菜单
		switch (LOWORD(wParam))
		{
		case IDC_OK:			//刷新
			_openFile(hWinMain, hProcessModuleTable, szFileNameOpen1, szFileNameOpen2);
			break;

		case IDC_BROWSE1:			//用户选择第一个文件
			_OpenFile1(hWinMain, hText1, szFileNameOpen1);
			break;
		case IDC_BROWSE2:			//用户选择第二个文件
			_OpenFile2(hWinMain, hText2, szFileNameOpen2);
			break;
		}
		break;

	default:
		return FALSE;
	}

	return TRUE;


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

		case IDM_OPEN:			//打开PE对比对话框
			DialogBoxParam(hInstance, MAKEINTRESOURCE(RESULT_MODULE), hWnd,
				_resultProcMain, (LPARAM)hWnd);
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
	InitCommonControl();
	hRichEdit = LoadLibrary(TEXT("RichEd20.dll"));
	DialogBoxParam(hInstance, MAKEINTRESOURCE(DLG_MAIN), NULL, _ProcDlgMain, (LPARAM)NULL);
	FreeLibrary(hRichEdit);
	return 0;
}