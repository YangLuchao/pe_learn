//��ջ����������
//
//
//��StackFlow1Ϊͬһ�������޸�szShellCode����
//release��,
//��ַ0x00400000��
//��ֹ�Ż���


#include <Windows.h>

//TCHAR szShellCode[12] = { 0xff, 0xff, 0xff, 0 };
TCHAR szShellCode[12] = { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x61, 0x10, 0x40, 0x00 };
TCHAR szText[] = TEXT("HelloWorld");
TCHAR szText2[] = TEXT("OverFlow me!");
DWORD i = 0;
// û�д��ַ������ȵĲ������ж�ջ����ķ���
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
