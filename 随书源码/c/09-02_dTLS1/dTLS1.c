//动态TLS对比演示
//不使用TLS的多线程应用程序

#include <Windows.h>

#define MAX_THREAD_COUNT 4


/*
线程函数
*/
void WINAPI _tFun(LPVOID lpParam)
{
	TCHAR szBuffer[500];


	//获得当前时间，
	//将线程的创建时间与线程对象相关联
	DWORD dwStart = GetTickCount();

	//模拟耗时操作
	DWORD dwCount = 1000 * 10000;
	while (--dwCount > 0);

	DWORD dwEnd = GetTickCount();
	// 弹出消息框
	wsprintf(szBuffer, TEXT("线程%d终止，用时：%d毫秒。"), GetCurrentThreadId(), dwEnd - dwStart);
	MessageBox(NULL, szBuffer, NULL, MB_OK);
}






int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	DWORD dwCount;// 线程计数
	HANDLE hThreadID[MAX_THREAD_COUNT];// 子线程句柄列表
	DWORD dwThreadID;// 创建线程传参


	dwCount = MAX_THREAD_COUNT;// 设置子线程数
	while (dwCount > 0)
	{
		// 创建子线程，并执行_tFun函数
		hThreadID[MAX_THREAD_COUNT - dwCount] = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)_tFun,
			NULL, 0, &dwThreadID);
		--dwCount;
	}

	//等待结束线程
	dwCount = MAX_THREAD_COUNT;
	while (dwCount > 0)
	{
		// 等待线程执行完成
		WaitForSingleObject(hThreadID[MAX_THREAD_COUNT - dwCount], INFINITE);
		// 关闭线程
		CloseHandle(hThreadID[MAX_THREAD_COUNT - dwCount]);
		--dwCount;
	}

	return 0;
}