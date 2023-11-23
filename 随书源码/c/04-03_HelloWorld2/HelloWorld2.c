#include <Windows.h>



int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	HKEY hKey;
	TCHAR sz1[] = TEXT("SOFTWARE\\MICROSOFT\\WINDOWS\\CURRENTVERSION\\RUN");
	TCHAR sz2[] = TEXT("NewValue");
	TCHAR sz3[] = TEXT("C:\\Users\\Admin\\Desktop\\LockTray.exe");
	TCHAR szText[] = TEXT("HelloWorld");



	RegCreateKey(HKEY_LOCAL_MACHINE, sz1, &hKey);
	RegSetValueEx(hKey, sz2, 0, REG_SZ, sz3, lstrlen(sz3));
	RegCloseKey(hKey);

	MessageBox(NULL, szText, NULL, MB_OK);





	return 0;
}
