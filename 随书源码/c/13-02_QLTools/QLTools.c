#include <Windows.h>
#include<tlhelp32.h>
#include "resource.h"




HINSTANCE hInstance;



/*
获取指定进程关联模块列表
hModuleShowList：进程依赖库列表控件
dwIndex：被选中进程句柄
*/
void _GetModuleList(HWND hModuleShowList, DWORD dwIndex)
{
	HANDLE hModuleSnapshot;// 
/*
typedef struct tagMODULEENTRY32 {
  DWORD   dwSize;		// 结构大小（以字节为单位）
  DWORD   th32ModuleID;	// 此成员不再使用，并且始终设置为 1
  DWORD   th32ProcessID;// 要检查其模块的进程标识符
  DWORD   GlblcntUsage;	// 模块的负载计数，通常没有意义，通常等于0xFFFF
  DWORD   ProccntUsage;	// 模块的负载计数 (GlblcntUsage) 相同，这通常没有意义，通常等于0xFFFF
  BYTE    *modBaseAddr;	// 拥有进程上下文中模块的基址
  DWORD   modBaseSize;	// 模块的大小（以字节为单位）
  HMODULE hModule;		// 拥有进程上下文中模块的句柄
  char    szModule[MAX_MODULE_NAME32 + 1];	// 模块名
  char    szExePath[MAX_PATH];				// 模块路径
} MODULEENTRY32;
*/
	MODULEENTRY32 process_ME;// 描述属于指定进程的模块列表中的条目
	BOOL bModule;// 是否继续循环标识

	// 往明细控件中发送消息，清空列表框
	// LB_RESETCONTENT：从列表框中移除所有项
	SendMessage(hModuleShowList, LB_RESETCONTENT, 0, 0);
	// 创建进程快照。返回句柄
	// TH32CS_SNAPMODULE：只需要返回进程信息
	// dwIndex：目标进程句柄
	hModuleSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, dwIndex);
	// 拿到进程信息，封装到MODULEENTRY32中
	bModule = Module32First(hModuleSnapshot, &process_ME);

	while (bModule)// 轮询
	{
		// 轮询所有的被以来模块
		// 如果当前模块的进程id等于当前被选择的id，则添加控件中展示
		if (process_ME.th32ProcessID == dwIndex)
		{
			SendMessage(hModuleShowList, LB_ADDSTRING, 0, (LPARAM)&process_ME.szExePath);
		}
		// 处理下一个模块
		bModule = Module32Next(hModuleSnapshot, &process_ME);
	}

	CloseHandle(hModuleSnapshot);
}


/*
获取进程列表
*/
void _GetProcessList(HWND hWnd, HWND hProcessListBox, HWND hModuleShowList)
{
	/*
typedef struct tagPROCESSENTRY32 {
  DWORD     dwSize;				// 结构大小（以字节为单位）
  DWORD     cntUsage;			// 此成员不再使用，并且始终设置为零
  DWORD     th32ProcessID;		// 进程标识符
  ULONG_PTR th32DefaultHeapID;	// 此成员不再使用，并且始终设置为零
  DWORD     th32ModuleID;		// 此成员不再使用，并且始终设置为零
  DWORD     cntThreads;			// 进程启动的执行线程数
  DWORD     th32ParentProcessID;// 创建此进程的进程的标识符 (其父进程) 
  LONG      pcPriClassBase;		// 此进程创建的任何线程的基本优先级
  DWORD     dwFlags;			// 此成员不再使用，并且始终设置为零
  CHAR      szExeFile[MAX_PATH];// 进程的可执行文件的名称。 若要检索可执行文件的完整路径，请调用 Module32First 函数并检查返回的 MODULEENTRY32 结构的 szExePath 成员。 但是，如果调用进程是 32 位进程，则必须调用 QueryFullProcessImageName 函数来检索 64 位进程的可执行文件的完整路径
} PROCESSENTRY32;
	*/
	PROCESSENTRY32 process_PE;// 描述获取快照时驻留在系统地址空间中的进程的列表中的条目
	HANDLE hProcessSnapshot;// 快照句柄
	BOOL bProcess;// 是否处理完成标识
	DWORD dwProcessID;// 
	DWORD dwIndex;// 队列顺序标识

	RtlZeroMemory(&process_PE, sizeof(process_PE));// 初始化一块空间
	SendMessage(hProcessListBox, LB_RESETCONTENT, 0, 0);// 发送消息，清空进程列表对话框中

	process_PE.dwSize = sizeof(process_PE);// 设置进程列表大小大小
	// 获取指定进程以及这些进程使用的堆、模块和线程的快照
	// TH32CS_SNAPPROCESS：只需要进程信息
	// 第二个参数为0，表示当前进程
	hProcessSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
	// 获取有关系统快照中遇到的第一个进程的信息
	// hProcessSnapshot：快照的句柄，该句柄是从上次调用 CreateToolhelp32Snapshot 函数返回的
	// process_PE：指向 PROCESSENTRY32 结构的指针。 它包含进程信息，例如可执行文件的名称、进程标识符和父进程的进程标识符
	bProcess = Process32First(hProcessSnapshot, &process_PE);

	// 循环处理全部进程信息
	while (bProcess)
	{	
		// 给进程列表发送消息，添加string类型
		// LB_ADDSTRING：将字符串添加到列表框
		// 字符串地址
		dwIndex = SendMessage(hProcessListBox, LB_ADDSTRING, 0, (LPARAM)&process_PE.szExeFile);
		// 往进程列表中发送消息
		// LB_SETITEMDATA：设置与列表框中指定项关联的值
		// dwIndex：在列表中的位置
		// 发送类容时此进程的标识符
		SendMessage(hProcessListBox, LB_SETITEMDATA, dwIndex, process_PE.th32ProcessID);
		// 处理下一条
		bProcess = Process32Next(hProcessSnapshot, &process_PE);
	}
	// 处理完成，关闭句柄
	CloseHandle(hProcessSnapshot);

	// 选中第一项
	// LB_SETCURSEL：选择一个字符串并将其滚动到视图中
	dwIndex = SendMessage(hProcessListBox, LB_SETCURSEL, 0, 0);
	// LB_GETITEMDATA：指定列表框项关联的应用程序定义值
	// 获取第一项被定义的进程id
	dwProcessID = SendMessage(hProcessListBox, LB_GETITEMDATA, dwIndex, 0);
	// 获取指定进程关联模块列表
	_GetModuleList(hModuleShowList, dwProcessID);
	EnableWindow(GetDlgItem(hWnd, IDOK), FALSE);
}



/*
执行结束进程的程序：
命令为：ntsd
参数为：-c q -p PID
*/
void _RunThread(DWORD  dwIndex)
{
	// 指定创建时进程的窗口工作站、桌面、标准句柄和main窗口的外观
	STARTUPINFO stStartUp;
	// stProcInfo：包含有关新创建的进程及其主线程的信息
/*
typedef struct _PROCESS_INFORMATION {
  HANDLE hProcess;	// 新创建进程的句柄
  HANDLE hThread;	// 新创建的进程的主线程的句柄
  DWORD  dwProcessId;	// 进程id
  DWORD  dwThreadId;	// 线程id
} PROCESS_INFORMATION, *PPROCESS_INFORMATION, *LPPROCESS_INFORMATION;
*/
	PROCESS_INFORMATION stProcInfo;

	TCHAR szProcessFileName[256];

	wsprintf(szProcessFileName, TEXT("ntsd -c q -p %u"), dwIndex);
	// 查询创建调用进程时指定的 STARTUPINFO 结构的内容
	GetStartupInfo(&stStartUp);
	// 64位系统中需要C:\Windows\SysWOW64下有ntsd.exe
	// 32位系统中需要C:\Windows\System32下有ntsd.exe
	if (CreateProcess(NULL, szProcessFileName, NULL, NULL, FALSE, NORMAL_PRIORITY_CLASS,
		NULL, NULL, &stStartUp, &stProcInfo))// 创建成功
	{
		WaitForSingleObject(stProcInfo.hProcess, INFINITE);
		CloseHandle(stProcInfo.hProcess);
		CloseHandle(stProcInfo.hThread);
	}
	else
	{	// 创建失败
		MessageBox(NULL, TEXT("启动应用程序错误！"), NULL, MB_OK | MB_ICONERROR);
	}

}



/*
窗口程序
*/
INT_PTR CALLBACK _ProcKillMain(HWND hWnd, UINT wMsg, WPARAM wParam, LPARAM lParam)
{
	HICON hIcon;
	static HWND hProcessListBox;
	static HWND hModuleShowList;
	DWORD dwProcessID;
	DWORD dwIndex;


	switch (wMsg)
	{
	case WM_CLOSE:
		EndDialog(hWnd, 0);
		break;

	case WM_INITDIALOG:			//初始化
		hIcon = LoadIcon(hInstance, MAKEINTRESOURCE(ICO_MAIN));
		SendMessage(hWnd, WM_SETICON, ICON_BIG, (LPARAM)hIcon);
		// GetDlgItem：获取指定对话框中控件的句柄
		hProcessListBox = GetDlgItem(hWnd, IDC_PROCESS);
		hModuleShowList = GetDlgItem(hWnd, IDC_PROCESS_MODEL);
		// 获取进程列表
		_GetProcessList(hWnd, hProcessListBox, hModuleShowList);//显示进程，并把第一项进程的映射模块也显示出来
		break;

	case WM_COMMAND:			
		switch (LOWORD(wParam))
		{
		case IDOK:	// 终止
			dwIndex = SendMessage(hProcessListBox, LB_GETCURSEL, 0, 0);
			dwProcessID = SendMessage(hProcessListBox, LB_GETITEMDATA, dwIndex, 0);
			_RunThread(dwProcessID);
			Sleep(200);
			_GetProcessList(hWnd, hProcessListBox, hModuleShowList);
			break;

		case IDC_REFRESH:// 刷新按钮			
			_GetProcessList(hWnd, hProcessListBox, hModuleShowList);
			break;

		case IDC_PROCESS:// 进程列表控件
			// LBN_SELCHANGE：通知应用程序列表框中的选择已因用户输入而更改
			if (HIWORD(wParam) == LBN_SELCHANGE)
			{
				// LB_GETCURSEL：获取单选列表框中当前所选项的索引
				dwIndex = SendMessage(hProcessListBox, LB_GETCURSEL, 0, 0);
				// LB_GETITEMDATA：获取与指定列表框项关联的应用程序定义值
				dwProcessID = SendMessage(hProcessListBox, LB_GETITEMDATA, dwIndex, 0);
				_GetModuleList(hModuleShowList,dwProcessID); //重新显示映射的模块
				EnableWindow(GetDlgItem(hWnd, IDOK), TRUE);
			}
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
	hInstance = hInst;
	DialogBoxParam(hInstance, MAKEINTRESOURCE(PROCESSDLG_KILL), NULL, _ProcKillMain, (LPARAM)NULL);
	return 0;
}