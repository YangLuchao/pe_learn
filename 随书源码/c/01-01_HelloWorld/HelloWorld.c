#include<Windows.h>
 
TCHAR szText[] = TEXT("HelloWorld");

int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, PSTR szCmdLine, int iCmdShow)
{
	
	MessageBox(NULL, szText, NULL, MB_OK);
	return 0;
}