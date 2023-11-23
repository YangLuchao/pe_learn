//Ëø¶¨ÈÎÎñÀ¸

#include <Windows.h>



int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	HWND hTray;

	hTray = FindWindow(TEXT("Shell_TrayWnd"), NULL);
	ShowWindow(hTray, SW_HIDE);
	EnableWindow(hTray, FALSE);
	return 0;
}
