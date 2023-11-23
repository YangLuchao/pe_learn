//动态TLS演示

#include <Windows.h>


#define MAX_THREAD_COUNT 4


DWORD hTlsIndex;


/*
初始化
*/
void _initTime()
{
	//获得当前时间，
	//将线程的创建时间与线程对象相关联
	if (!TlsSetValue(hTlsIndex, (PVOID)GetTickCount()))
	{
		MessageBox(NULL, TEXT("写入TLS槽数据时失败！"), NULL, MB_OK);
	}
}


/*
获取用时
*/
DWORD _getLostTime()
{
	//获得当前时间，
	//返回当前时间和线程创建时间的差值
	DWORD dwTemp = GetTickCount();
	DWORD dwStart = (DWORD)TlsGetValue(hTlsIndex);
	if (dwStart == 0)
	{
		MessageBox(NULL, TEXT("读取TLS槽数据时失败！"), NULL, MB_OK);
	}

	return dwTemp -= dwStart;
}


/*
线程函数
*/
void WINAPI _tFun(LPVOID lpParam)
{
	TCHAR szBuffer[500];// 字符出缓冲区

	_initTime();// 初始化时间

	//模拟耗时操作
	DWORD dwCount = 1000 * 10000;
	while (--dwCount > 0);
	// 弹出对话框
	wsprintf(szBuffer, TEXT("线程%d终止，用时：%d毫秒。"), GetCurrentThreadId(), _getLostTime());
	MessageBox(NULL, szBuffer, NULL, MB_OK);
}






int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	DWORD dwCount;// 循环计数
	HANDLE hThreadID[MAX_THREAD_COUNT];//线程id数组
	DWORD dwThreadID;// 创建线程传参


	//通过在进程位数组中申请一个索引，
	//初始化线程运行时间记录系统
	hTlsIndex = TlsAlloc();

	dwCount = MAX_THREAD_COUNT;// 设置子线程数
	while (dwCount > 0)
	{
		// LPTHREAD_START_ROUTINE: 指向通知主机线程已开始执行的函数
		// 创建线程，并执行_tFun函数
		hThreadID[MAX_THREAD_COUNT - dwCount] = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)_tFun,
			NULL, 0, &dwThreadID);
		// 线程数-1
		--dwCount;
	}

	//等待结束线程
	dwCount = MAX_THREAD_COUNT;
	while (dwCount > 0)
	{
		// 等待子线程完成返回
		WaitForSingleObject(hThreadID[MAX_THREAD_COUNT - dwCount], INFINITE);
		// 关闭子线程
		CloseHandle(hThreadID[MAX_THREAD_COUNT - dwCount]);
		--dwCount;
	}

	//通过释放线程局部存储索引，
	//释放时间记录系统占用的资源
	TlsFree(hTlsIndex);

	return 0;
}