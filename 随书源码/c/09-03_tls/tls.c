//��̬TLS��ʾ
//
//����ʱ�ر������ַ
//��ַ0x00400000
//
//��1b0���޸�Ϊ0c 80 01 00   18 00 00 00  


#include <Windows.h>



DWORD Tls1 = 0;
DWORD Tls2 = 0;
DWORD Tls3 = 0;
DWORD TlsCallBack[] = { 0x00411b1c,//TLS��ַ
						0,
						0 };



//����IMAGE_TLS_DIRECTORY
DWORD TLS_DIR[] = { (DWORD)&Tls1, (DWORD)&Tls2, (DWORD)&Tls3, (DWORD)&TlsCallBack, 0, 0 };



DWORD TLSCalled;//�ؽ���־


int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	MessageBox(NULL, TEXT("MAIN"), NULL, MB_OK);
	return 0;

	//���´��뽫����.code֮ǰִ��һ��
TLS:
	//����TLSCalled��һ�����ؽ���־����������¸ò��ִ���
	//�ᱻִ�����Σ���ʹ���˸ñ�ʶ�󣬸ô���ֻ�ڿ�ʼ����ǰ
	//ִ��һ��
	if (TLSCalled == 0)
	{
		TLSCalled = 1;
		MessageBox(NULL, TEXT("TLS"), NULL, MB_OK);
	}

	return 0;
}