//补丁程序
//
//
//release版 
//禁用安全检查 (/GS-)
//基址0x00400000
//
//


#include<windows.h>

//TCHAR szText[] = ;

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR szCmdLine, int iCmdShow)
{
	MessageBox(NULL, TEXT("HelloWorld"), NULL, MB_OK);
	return 0;
}