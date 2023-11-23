//堆栈溢出程序测试
//
//
//和StackFlow1为同一个程序，修改szShellCode即可
//release版,
//基址0x00400000，
//禁止优化，


#include <Windows.h>

//TCHAR szShellCode[12] = { 0xff, 0xff, 0xff, 0 };
TCHAR szShellCode[12] = { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x61, 0x10, 0x40, 0x00 };
TCHAR szText[] = TEXT("HelloWorld");
TCHAR szText2[] = TEXT("OverFlow me!");
DWORD i = 0;
// 没有传字符串长度的参数，有堆栈溢出的风险
void _memCopy(PTCHAR _lpSrc)
{
	TCHAR buf[4];
	
	
	while (_lpSrc[i])
	{
		buf[i++] = _lpSrc[i];
	}
}


int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR szCmdLine, int iCmdShow)
{
	
	
	_memCopy(szShellCode);

	MessageBox(NULL, szText, NULL, MB_OK);
	MessageBox(NULL, szText2, NULL, MB_OK);
	return 0;
}
