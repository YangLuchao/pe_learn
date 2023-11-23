//简单窗口程序
//具有窗口的大部分基本特性，其中显示和退出使用了渐入和渐出效果
//该程序主要演示自己制作的dll的函数调用
//
//
//
//需要把	05-01_winResult.dll1(初始dll)
//			05-01_winResult.dll2(修改导出表)
//			05-01_winResult.dll3(修改导出函数指令)
//重命名为	05-01_winResult.dll


#include <Windows.h>
#include"..//05-01_winResult//winResult.h"

HWND         hWinMain;

LRESULT CALLBACK _ProcWinMain(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	HDC         hDc;
	PAINTSTRUCT ps;
	RECT        stRect;

	TCHAR szText[] = TEXT("你好，认识我吗？^_^");
	

	switch (message)
	{
	case WM_PAINT:
		hDc = BeginPaint(hWnd, &ps);

		GetClientRect(hWnd, &stRect);
		DrawText(hDc, szText, -1, &stRect, DT_SINGLELINE | DT_CENTER | DT_VCENTER);

		EndPaint(hWnd, &ps);
		return 0;

	case WM_CLOSE:
		FadeOutClose(hWinMain);
		DestroyWindow(hWinMain);
		PostQuitMessage(0);
		return 0;
	}
	return DefWindowProc(hWnd, message, wParam, lParam);
}






int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
	PSTR szCmdLine, int iCmdShow)
{
	TCHAR szClassName[] = TEXT("MyClass");
	TCHAR szCaptionMain[] = TEXT("窗口特效演示");


	
	MSG          msg;
	// 定义一个窗口控件
	WNDCLASSEX     stWndClass;

	RtlZeroMemory(&stWndClass, sizeof(stWndClass));

	// 设置控件的属性
	stWndClass.hCursor = LoadCursor(NULL, IDC_ARROW);
	stWndClass.hInstance = hInstance;
	stWndClass.cbSize = sizeof(WNDCLASSEX);
	stWndClass.style = CS_HREDRAW | CS_VREDRAW;
	stWndClass.lpfnWndProc = _ProcWinMain;
	stWndClass.hbrBackground = COLOR_WINDOW + 1;
	stWndClass.lpszClassName = szClassName;
	// 将窗口注册到Windows内核
	RegisterClassEx(&stWndClass);

	// 创建窗口
	hWinMain = CreateWindowEx(WS_EX_CLIENTEDGE, szClassName, szCaptionMain, WS_OVERLAPPEDWINDOW,
		100, 100, 600, 400, NULL, NULL, hInstance, NULL);
	// 调用winResult.dll 中导出的函数
	FadeInOpen(hWinMain);
	// 刷新窗口
	UpdateWindow(hWinMain);
	// 主线程阻塞，获取分发消息
	while (GetMessage(&msg, NULL, 0, 0))
	{
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	}
	return msg.wParam;
}


