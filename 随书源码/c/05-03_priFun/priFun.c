//导出表导出私有函数测试
//
//
//需要把05-01_winResult.dll4重命名为05-01_winResult.dll

#include <Windows.h>




/*
私有函数模拟
*/
DWORD NTopXY(DWORD wDim, DWORD sDim)
{
	sDim >>= 1;
	wDim >>= 1;
	sDim -= wDim;

	return sDim;
}



int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR szCmdLine, int iCmdShow)
{
	TCHAR szBuffer[200];
	TCHAR szOut[] = TEXT("(400:600) eax=%d");
	// 声明函数指针类型，指针类型位MYPROC
	typedef DWORD(__cdecl *MYPROC)();
	// 定义函数
	MYPROC pSLWA;

	
	wsprintf(szBuffer, szOut, NTopXY(400, 600));
	MessageBox(NULL, szBuffer, NULL, MB_OK);



	// LoadLibrary：加载动态链接库
	// GetProcAddress：获取函数调用地址
	pSLWA = (MYPROC)GetProcAddress(LoadLibrary(TEXT("05-01_winResult.dll")), TEXT("TopXY"));
	wsprintf(szBuffer, szOut, pSLWA(400, 600));// 动态调用函数
	MessageBox(NULL, szBuffer, NULL, MB_OK);
}