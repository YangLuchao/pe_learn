//�򵥴��ڳ���
//���д��ڵĴ󲿷ֻ������ԣ�������ʾ���˳�ʹ���˽���ͽ���Ч��
//�ó�����Ҫ��ʾ�Լ�������dll�ĺ�������
//
//
//
//��Ҫ��	05-01_winResult.dll1(��ʼdll)
//			05-01_winResult.dll2(�޸ĵ�����)
//			05-01_winResult.dll3(�޸ĵ�������ָ��)
//������Ϊ	05-01_winResult.dll


#include <Windows.h>
#include"..//05-01_winResult//winResult.h"

HWND         hWinMain;

LRESULT CALLBACK _ProcWinMain(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	HDC         hDc;
	PAINTSTRUCT ps;
	RECT        stRect;

	TCHAR szText[] = TEXT("��ã���ʶ����^_^");
	

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
	TCHAR szCaptionMain[] = TEXT("������Ч��ʾ");


	
	MSG          msg;
	// ����һ�����ڿؼ�
	WNDCLASSEX     stWndClass;

	RtlZeroMemory(&stWndClass, sizeof(stWndClass));

	// ���ÿؼ�������
	stWndClass.hCursor = LoadCursor(NULL, IDC_ARROW);
	stWndClass.hInstance = hInstance;
	stWndClass.cbSize = sizeof(WNDCLASSEX);
	stWndClass.style = CS_HREDRAW | CS_VREDRAW;
	stWndClass.lpfnWndProc = _ProcWinMain;
	stWndClass.hbrBackground = COLOR_WINDOW + 1;
	stWndClass.lpszClassName = szClassName;
	// ������ע�ᵽWindows�ں�
	RegisterClassEx(&stWndClass);

	// ��������
	hWinMain = CreateWindowEx(WS_EX_CLIENTEDGE, szClassName, szCaptionMain, WS_OVERLAPPEDWINDOW,
		100, 100, 600, 400, NULL, NULL, hInstance, NULL);
	// ����winResult.dll �е����ĺ���
	FadeInOpen(hWinMain);
	// ˢ�´���
	UpdateWindow(hWinMain);
	// ���߳���������ȡ�ַ���Ϣ
	while (GetMessage(&msg, NULL, 0, 0))
	{
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	}
	return msg.wParam;
}


