//release°æ,
//½ûÖ¹ÓÅ»¯£¬


#include <Windows.h>


TCHAR szText[] = TEXT("HelloWorld");


DWORD fun1(PTCHAR _p1, DWORD _p2)
{
	DWORD dwTemp;
	DWORD dwCount;

	dwTemp = 0;
	dwCount = _p2;

	return dwCount;
}


int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR szCmdLine, int iCmdShow)
{


	fun1(szText, 2);
	MessageBox(NULL, szText, NULL, MB_OK);

	return 0;
}




