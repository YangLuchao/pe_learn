//补丁升级程序
//
//禁止优化 已禁用 (/Od)


#include <Windows.h>


//主进程释放时会修改此处的三个值，这里初始化成这个形式是方便查找他们的文件偏移
DWORD hProcessID=0x11111111;	//主程序进程号
DWORD oldMajor=0x22222222;		//主旧版本的值
DWORD oldMinor=0x33333333;		//次旧版本的值

int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	DWORD newMajor;// 主版本号
	DWORD newMinor;// 新版本号
	HANDLE hProcess;// 进程句柄

	STARTUPINFO stStartUp;// 指定创建时进程的窗口工作站、桌面、标准句柄和main窗口的外观
	PROCESS_INFORMATION stProcInfo;// 进程信息

	TCHAR szDataBuffer[256];
	TCHAR szBuffer[256];


	TCHAR szINI[] = TEXT("下载配置文件");
	TCHAR szINIURL[] = TEXT("http://127.0.0.1/version.ini");
	TCHAR szLINI[] = TEXT(".\\_tmp.ini"); 
	TCHAR szSectionName[] = TEXT("13-01_DPatchPEInfo.exe"); //针对不同的程序修改此处的值
	TCHAR szKeyName1[] = TEXT("majorImageVersion");
	TCHAR szKeyName2[] = TEXT("minorImageVersion");
	TCHAR szKeyName3[] = TEXT("downloadfile");
	TCHAR szIsNewVesion[] = TEXT("程序已经是最新版本");
 	TCHAR szOut2[] = TEXT("下载补丁文件");
	TCHAR szPROCURL[] = TEXT("http://127.0.0.1/%s"); //要下载的EXE文件

	// 弹出对话框
	MessageBox(NULL, szINIURL, szINI, MB_OK);
	//下载ini文件,需要直接在本地搭建个web服务器，把ini文件放在网站根目录
/*
URLDownloadToFile 用于从指定的URL下载文件并将其保存到本地文件系统的指定位置

pCaller: 这是一个指向调用者(IUnknown)的指针，通常可以设置为NULL。
szURL: 这是一个指向包含要下载文件的URL的字符串的指针。
szFileName: 这是一个指向本地文件名的字符串的指针，用于指定下载后文件的保存位置。
dwReserved: 这个参数保留，通常设置为0。
lpfnCB: 这是一个回调函数的指针，用于接收下载进度的通知。可以设置为NULL，如果不需要下载进度通知。
*/
	URLDownloadToFile(0, szINIURL, szLINI, 0, 0);
	// GetPrivateProfileInt: 检索与初始化文件的指定节中的键关联的整数
	newMajor = GetPrivateProfileInt(szSectionName, szKeyName1, 0, szLINI);
	newMinor = GetPrivateProfileInt(szSectionName, szKeyName2, 0, szLINI);

	//判断是否是新版本PE
	if (newMajor == oldMajor && newMinor == oldMinor)
	{
		// 显示已经是最新版本 
		MessageBox(NULL, szIsNewVesion, NULL, MB_OK);
	}
	else
	{
		// 不是新版本，则下载该PE，并实施替换
		// 清空缓冲区
		RtlZeroMemory(szDataBuffer, 256);
		// 取文件名
		GetPrivateProfileString(szSectionName, szKeyName3, NULL, szDataBuffer, sizeof(szDataBuffer), szLINI); 
		wsprintf(szBuffer, szPROCURL, szDataBuffer);
		MessageBox(NULL, szBuffer, szOut2, MB_OK);
		// 下载exe文件，需要直接在本地搭建个web服务器，把exe文件放在网站根目录
		URLDownloadToFile(0, szBuffer, szDataBuffer, 0, 0);
		// 结束当前主进程
		hProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, hProcessID);
		Sleep(1000);
		// 中断进程
		TerminateProcess(hProcess, 0);
		CloseHandle(hProcess);
		Sleep(1000);

		//将下载的文件替换为PE文件
		DeleteFile(szSectionName);
		CopyFile(szDataBuffer, szSectionName, TRUE);
		Sleep(1000);

		// 重启PE程序
		// GetStartupInfo: 检索创建调用进程时指定的 STARTUPINFO 结构的内容
		GetStartupInfo(&stStartUp);
		CreateProcess(NULL, szSectionName, NULL, NULL, FALSE, NORMAL_PRIORITY_CLASS, 
			NULL, NULL, &stStartUp, &stProcInfo);

	}

	return 0;
}