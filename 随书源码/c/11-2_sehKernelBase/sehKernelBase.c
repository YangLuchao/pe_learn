//��ȡkernel32.dll�Ļ�ַ
//��SEH��ܿռ�������kernel32.dll�Ļ���ַ
//
//win7��_except_handler����ntdll
//xp��_except_handler��kernel32


#include<windows.h>


// SEH����
typedef struct _EXCEPTION_REGISTRATION
{
	struct _EXCEPTION_REGISTRATION * prev;
	DWORD handler;
}EXCEPTION_REGISTRATION, *PEXCEPTION_REGISTRATION;




int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	PEXCEPTION_REGISTRATION pExceptionRegistration;//SEH����ָ��
	DWORD dwAddress;// dll�׵�ַ
	TCHAR szBuffer[256];// �ַ���������

	// ����try���׵�ַ��ΪpExceptionRegistration
	__asm
	{
		mov eax, fs:[0] 
		mov pExceptionRegistration,eax 
	}

	
	do
	{
		dwAddress = pExceptionRegistration->handler;// handlerΪָ�����쳣��������ַ
		pExceptionRegistration = pExceptionRegistration->prev;// prevΪ��һ������ڵ��ַ
	}while ((DWORD)pExceptionRegistration != 0xffffffff);// �ҵ��쳣�����������һ���ڵ�
	
	// dwAddress = dwAddress / 0x10000 * 0x10000: ����ȡ��
	// *(PWORD)dwAddress != 0x5A4D���ҵ�DOSͷ,�������ѭ��
	// dwAddress -= 0x10000��-10000h����ѭ����ֱ���ҵ�DOSͷ
	for (dwAddress = dwAddress / 0x10000 * 0x10000; *(PWORD)dwAddress != 0x5A4D; dwAddress -= 0x10000);

	// ���ģ�����ַ
	wsprintf(szBuffer, TEXT("kernel32.dll�Ļ���ַΪ%08x"), dwAddress);
	MessageBox(NULL, szBuffer, NULL, MB_OK);
}

