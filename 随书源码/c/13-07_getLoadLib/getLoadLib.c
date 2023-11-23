//万能补丁码
//获取LoadLibraryA的函数地址并调用
//
//
//release版
//保留从未引用的函数和数据    否 (/OPT:NOREF)
//优化 已禁用 (/Od)
//禁用安全检查 (/GS-)
//
//
//
//因为notepad的.text剩余只有0x100左右的空间
//而直接复制之前的函数生成的指令太多，大概有0x300左右
//所以不直接复制之前的函数，而是把那些语句尽量合并，精简，最后生成指令大小为0xe1
//所以这个程序看起来有点不好理解，
//可以不看这个程序，直接用随书代码生成的指令，，
//
//
//如果是win7x64,用SysWOW64下的notepad
//win7的notepad有重定位，需要把重定位去掉(IMAGE_NT_HEADERS32.IMAGE_FILE_HEADER.Characteristics | 1)才能行，
//不然程序加载的时候会把写入的数据修改了，会运行失败
//把入口点(IMAGE_NT_HEADERS32.AddressOfEntryPoint.AddressOfEntryPoint)改为0xb700
//从文件偏移0xab00(0xb700的文件偏移) 处开始写入
//写入的数据来自13-07_getLoadLib.exe
//文件偏移0x400到0x4e1
//
//
//把13-08_winResult.dll名字改为pa.dll
//和打补丁后的notepad放在同一目录，然后运行notepad
//
//


#include <Windows.h>


int  main()
{


	DWORD dwPEB;	//PEB地址
	DWORD dwDllBase;//当前地址
	PIMAGE_EXPORT_DIRECTORY pImageExportDirectory;//指向导出表的指针

	TCHAR ** lpAddressOfNames;// 导出表函数名列表
	PWORD lpAddressOfNameOrdinals;
	DWORD szStr[] = { 0x64616f4c, 0x7262694c, 0x41797261, //"LoadLibraryA"
		0x617000 };//"pa"



	__asm
	{
		mov eax, FS:[0x30]//fs:[30h]指向PEB
		mov dwPEB, eax
	}

	// 模块基址
	// dwPEB + 0xc: //0Ch加载的其他模块信息
	// *(PDWORD)(dwPEB + 0xc): 拿到PEB_LDR_DATA结构
	// (*(PDWORD)(dwPEB + 0xc) + 0x1c):获取InInitializationOrderModuleList 链表头
	// (*(PDWORD)(*(PDWORD)(*(PDWORD)(dwPEB + 0xc) + 0x1c))): 头节点解指针
	// (*(PDWORD)(*(PDWORD)(*(PDWORD)(dwPEB + 0xc) + 0x1c))) + 8：往挪一个节点
	// (*(PDWORD)(*(PDWORD)(*(PDWORD)(*(PDWORD)(dwPEB + 0xc) + 0x1c))) + 8):解指针，获取代表kernel32.dll的_LDR_MODULE
	// *(PDWORD)(*(PDWORD)(*(PDWORD)(*(PDWORD)(*(PDWORD)(dwPEB + 0xc) + 0x1c))) + 8): 解指针，获取kernel32.dll的基址
	dwDllBase = *(PDWORD)(*(PDWORD)(*(PDWORD)(*(PDWORD)(*(PDWORD)(dwPEB + 0xc) + 0x1c))) + 8);

	// 指向导出表的指针
	// *(PDWORD)(dwDllBase + 0x3c): NT头RVA
	// *(PDWORD)(dwDllBase + *(PDWORD)(dwDllBase + 0x3c):NT头VA
	// (dwDllBase + *(PDWORD)(dwDllBase + *(PDWORD)(dwDllBase + 0x3c) + 0x78)):目录项VA，目录项第一项为导出表
	// (PIMAGE_EXPORT_DIRECTORY)(dwDllBase + *(PDWORD)(dwDllBase + *(PDWORD)(dwDllBase + 0x3c) + 0x78))：强转为导出表指针类型
	pImageExportDirectory = (PIMAGE_EXPORT_DIRECTORY)(dwDllBase + *(PDWORD)(dwDllBase + *(PDWORD)(dwDllBase + 0x3c) + 0x78));

	// 按名字导出函数列表
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
					pImageExportDirectory->AddressOfNameOrdinals);//按名字导出函数索引列表

				((PROC)(dwDllBase + ((PDWORD)(dwDllBase + pImageExportDirectory->AddressOfFunctions))
					[lpAddressOfNameOrdinals[i]]))((PTCHAR)szStr + 0xd);//调用LoadLibraryA

				__asm
				{
					leave	// 平衡堆栈
					mov eax, 0x010031C9//原入口点
					jmp eax
				}
			}
		} while (++j);
	} while (++i);

	return 0;
}

