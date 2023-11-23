#include <windows.h>
#include <Richedit.h>
#include "resource.h"


HINSTANCE hInstance;

DWORD dwStop;
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
往文本框中追加文本
*/
void _appendInfo(TCHAR * _lpsz)
{
	CHARRANGE stCR;

	stCR.cpMin = GetWindowTextLength(hWinEdit);
	stCR.cpMax = GetWindowTextLength(hWinEdit);
	SendMessage(hWinEdit, EM_EXSETSEL, 0, (LPARAM)&stCR); //将插入点移动到最后
	SendMessage(hWinEdit, EM_REPLACESEL, FALSE, (LPARAM)_lpsz);
}



/*
打开PE文件并处理
*/
void _openFile(HWND hWinMain)
{
	OPENFILENAME stOF;
	HANDLE hFile, hMapFile;
	DWORD totalSize;		//文件大小
	LPVOID lpMemory;		//内存映像文件在内存的起始位置

	TCHAR szFileName[MAX_PATH] = {0};	//要打开的文件路径及名称名
	TCHAR bufTemp1[10];					//每个字符的十六进制字节码
	TCHAR bufTemp2[20];					//第一列
	TCHAR lpServicesBuffer[100];		//一行的所有内容
	TCHAR bufDisplay[50];				//第三列ASCII码字符
	DWORD dwCount;						//计数，逢16则重新计
	DWORD dwCount1;						//地址顺号
	DWORD dwBlanks;						//最后一行空格数

	TCHAR szExtPe[] = TEXT("PE Files\0*.exe;*.dll;*.scr;*.fon;*.drv\0All Files(*.*)\0*.*\0\0"); 
	
	// 清空所需内存
	RtlZeroMemory(&stOF, sizeof(stOF));
	stOF.lStructSize = sizeof(stOF);
	stOF.hwndOwner = hWinMain;
	stOF.lpstrFilter = szExtPe;
	stOF.lpstrFile = szFileName;
	stOF.nMaxFile = MAX_PATH;
	stOF.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST;
	if (GetOpenFileName(&stOF))		//让用户选择打开的文件
	{
		// 创建文件句柄
		hFile = CreateFile(szFileName, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE,
			NULL, OPEN_EXISTING, FILE_ATTRIBUTE_ARCHIVE, NULL);
		// 判断文件是否非法
		if (hFile != INVALID_HANDLE_VALUE)
		{
			totalSize = GetFileSize(hFile, NULL);//获取文件大小
			if (totalSize)
			{
				// 创建内存映射
				hMapFile = CreateFileMapping(hFile, NULL, PAGE_READONLY, 0, 0, NULL);//内存映射文件
				if (hMapFile)
				{
					// 获取映射起始位置
					lpMemory = MapViewOfFile(hMapFile, FILE_MAP_READ, 0, 0, 0);//获得文件在内存的映象起始位置
					if (lpMemory)
					{
						//开始处理文件

						//缓冲区初始化
						RtlZeroMemory(bufTemp1, 10);
						RtlZeroMemory(bufTemp2, 20);
						RtlZeroMemory(lpServicesBuffer, 100);
						RtlZeroMemory(bufDisplay, 50);

						dwCount = 1;

						//将第一列写入lpServicesBuffer
						dwCount1 = 0;
						wsprintf(bufTemp2, TEXT("%08x  "), dwCount1);
						lstrcat(lpServicesBuffer, bufTemp2);
					
						dwBlanks = (16 - totalSize % 16) * 3;//求最后一行的空格数

						while (TRUE)
						{
							if (totalSize == 0)//最后一行
							{
								while (dwBlanks)//填充空格
								{
									lstrcat(lpServicesBuffer, TEXT(" "));
									--dwBlanks;
								}
							
								lstrcat(lpServicesBuffer, TEXT("  "));//第二列与第三列中间的空格							
								lstrcat(lpServicesBuffer, bufDisplay);//第三列内容							
								lstrcat(lpServicesBuffer, TEXT("\n"));//回车换行符号
								break;
							}

							//翻译成可以显示的ascii码字,写入第三列的值
							if (*(TCHAR *)lpMemory > 0x20 && *(TCHAR *)lpMemory < 0x7e)
							{
								bufDisplay[dwCount-1] = *(TCHAR *)lpMemory;
							}
							else
							{
								bufDisplay[dwCount-1] = 0x2e;//如果不是ASCII码值，则显示“.”
							}
							
							wsprintf(bufTemp1, TEXT("%02X "), *(TBYTE *)lpMemory);//字节的十六进制字符串到@bufTemp1中							
							lstrcat(lpServicesBuffer, bufTemp1);//将第二列写入lpServicesBuffer

							if (dwCount == 16)//已到16个字节，
							{
								lstrcat(lpServicesBuffer, TEXT("  "));//第二列与第三列中间的空格
								lstrcat(lpServicesBuffer, bufDisplay);//显示第三列字符 
								lstrcat(lpServicesBuffer, TEXT("\n"));//回车换行

								_appendInfo(lpServicesBuffer);//写入内容
								RtlZeroMemory(lpServicesBuffer, 100);

								if (dwStop == 1)
								{
									break;
								}

								wsprintf(bufTemp2, TEXT("%08X  "), (++dwCount1) * 16); // 显示下一行的地址
								lstrcat(lpServicesBuffer, bufTemp2);

								dwCount = 0;
								RtlZeroMemory(bufDisplay, 50);
							}
							--totalSize;
							++dwCount;
							++(TCHAR *)lpMemory;

						}

						_appendInfo(lpServicesBuffer); //添加最后一行
						// 卸载镜像
						UnmapViewOfFile(lpMemory);
					}
					// 关闭镜像
					CloseHandle(hMapFile);
				}
			}
			// 关闭文件
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
			dwStop = 0;
			// 创建线程，执行openfile函数
			CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)_openFile, hWnd, 0, NULL);
			break;
		
		case IDM_1:
			dwStop = 1;
			break;

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
	// 加载富文本工具
	hRichEdit = LoadLibrary(TEXT("RichEd20.dll"));
	// 调用窗口函数展示窗口
	DialogBoxParam(hInstance, MAKEINTRESOURCE(DLG_MAIN), NULL, _ProcDlgMain, (LPARAM)NULL);
	FreeLibrary(hRichEdit);
	return 0;
}