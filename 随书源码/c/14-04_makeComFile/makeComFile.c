//����comset.bin�ļ��������ֽڶ�Ӧ��ָ��
//
//
//



#include<windows.h>



int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR szCmdLine, int iCmdShow)
{
	HANDLE hFile;
	DWORD dwSize;
	DWORD dwWritten;

	TCHAR szText[] = TEXT("Sucess!");
	TCHAR szFile[] = TEXT("comset.bin");//���ɵ��ļ�
	TCHAR szBinary[] = { 00, 00, 00, 00, 00, 0x90, 0x90 };
	
	
	hFile = CreateFile(szFile, GENERIC_WRITE, FILE_SHARE_READ, 0,
		CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
	
	dwSize = 0xff;
	do
	{
		*(PDWORD)szBinary = dwSize;
		WriteFile(hFile, szBinary, 7, &dwWritten, NULL);
	} while (dwSize--);
	CloseHandle(hFile);


	MessageBox(NULL, szText, NULL, MB_OK);
	return 0;
}