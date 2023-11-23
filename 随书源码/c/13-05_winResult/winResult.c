//DLL动态链接库
//提供了几个窗口效果
//
//把05-01_winResult.dll放到C:\Windows目录下
//把13-05_winResult.dll和05-02_FirstWindow.exe放在同目录
//把13-05_winResult.dll名字改为05-01_winResult.dll
//运行05-02_FirstWindow.exe


#include<Windows.h>
#include"winResult.h"



#define MAX_XYSTEPS		50
#define DELAY_VALUE		50
#define X_STEP_SIZE		10
#define Y_STEP_SIZE		9
#define X_START_SIZE	20
#define Y_START_SIZE	10

#define LMA_ALPHA		2
#define LMA_COLORKEY	1

typedef int (cdecl *MYPROC)();

MYPROC _fadeInOpen;





BOOL WINAPI DllMain(HINSTANCE hInstance, DWORD fdwReason, PVOID pvReserved)
{
	HMODULE hDLL;

	// 加载dll
	hDLL = LoadLibrary(TEXT("C:\\Windows\\05-01_winResult.dll"));
	// 劫持函数
	_fadeInOpen = (MYPROC)GetProcAddress(hDLL, TEXT("FadeInOpen"));
	return TRUE;
}



/*
私有函数
*/
DWORD TopXY(DWORD wDim, DWORD sDim)
{
	sDim >>= 1;
	wDim >>= 1;
	sDim -= wDim;

	return sDim;
}



/*
窗口抖动进入效果
*/

void AnimateOpen(HWND hWin)
{
	RECT Rct;
	DWORD Xsize, Ysize;
	DWORD sWth, sHth;
	DWORD Xplace, Yplace;
	DWORD counts;


	GetWindowRect(hWin, &Rct);

	Xsize = X_START_SIZE;
	Ysize = Y_START_SIZE;

	sWth = GetSystemMetrics(SM_CXSCREEN);
	Xplace = TopXY(Xsize, sWth);

	sHth = GetSystemMetrics(SM_CYSCREEN);
	Yplace = TopXY(Ysize, sHth);

	counts = MAX_XYSTEPS;
	while (counts--)
	{
		MoveWindow(hWin, Xplace, Yplace, Xsize, Ysize, FALSE);
		ShowWindow(hWin, SW_SHOWNA);
		Sleep(DELAY_VALUE);
		ShowWindow(hWin, SW_HIDE);
		Xsize += X_STEP_SIZE;
		Ysize += Y_STEP_SIZE;
		Xplace = TopXY(Xsize, sWth);
		Yplace = TopXY(Ysize, sHth);
	}

	Xsize = Rct.right - Rct.left;
	Ysize = Rct.bottom - Rct.top;
	Xplace = TopXY(Xsize, sWth);
	Yplace = TopXY(Ysize, sHth);

	MoveWindow(hWin, Xplace, Yplace, Xsize, Ysize, TRUE);
	ShowWindow(hWin, SW_SHOW);
}


/*
窗口抖动退出效果
*/
void AnimateClose(HWND hWin)
{
	RECT Rct;
	DWORD Xsize, Ysize;
	DWORD sWth, sHth;
	DWORD Xplace, Yplace;
	DWORD counts;



	ShowWindow(hWin, SW_HIDE);
	GetWindowRect(hWin, &Rct);

	Xsize = Rct.right - Rct.left;
	Ysize = Rct.bottom - Rct.top;

	sWth = GetSystemMetrics(SM_CXSCREEN);
	Xplace = TopXY(Xsize, sWth);

	sHth = GetSystemMetrics(SM_CYSCREEN);
	Yplace = TopXY(Ysize, sHth);

	counts = MAX_XYSTEPS;
	while (counts--)
	{
		MoveWindow(hWin, Xplace, Yplace, Xsize, Ysize, FALSE);
		ShowWindow(hWin, SW_SHOWNA);
		Sleep(DELAY_VALUE);
		ShowWindow(hWin, SW_HIDE);
		Xsize -= X_STEP_SIZE;
		Ysize -= Y_STEP_SIZE;
		Xplace = TopXY(Xsize, sWth);
		Yplace = TopXY(Ysize, sHth);
	}

	Xsize = Rct.right - Rct.left;
	Ysize = Rct.bottom - Rct.top;
	Xplace = TopXY(Xsize, sWth);
	Yplace = TopXY(Ysize, sHth);

	MoveWindow(hWin, Xplace, Yplace, Xsize, Ysize, TRUE);
	ShowWindow(hWin, SW_SHOW);
}



/*
窗口淡入效果,被劫持的API函数
*/
void FadeInOpen(HWND hWin)
{
	// 劫持函数，插入补丁
	MessageBox(NULL, TEXT("HelloWorldPE"), NULL, MB_OK);//插入补丁
	_fadeInOpen(hWin);
}




/*
窗口淡出效果
*/
void FadeOutClose(HWND hWin)
{
	LONG style;
	HMODULE hModule;
	FARPROC pSLWA;
	DWORD Value;

	TCHAR User32[] = TEXT("user32.dll");
	TCHAR SLWA[] = TEXT("SetLayeredWindowAttributes");

	style = GetWindowLongA(hWin, GWL_EXSTYLE);
	style |= WS_EX_LAYERED;
	SetWindowLongA(hWin, GWL_EXSTYLE, style);
	hModule = GetModuleHandleA(User32);
	pSLWA = GetProcAddress(hModule, SLWA);
	pSLWA(hWin, 0, 255, LMA_ALPHA);

	Value = 255;
	do
	{
		pSLWA(hWin, Value, Value, LMA_COLORKEY + LMA_ALPHA);
		Sleep(DELAY_VALUE);

		Value -= 15;
	} while (Value);
}
