//��������˽�к�������
//
//
//��Ҫ��05-01_winResult.dll4������Ϊ05-01_winResult.dll

#include <Windows.h>




/*
˽�к���ģ��
*/
DWORD NTopXY(DWORD wDim, DWORD sDim)
{
	sDim >>= 1;
	wDim >>= 1;
	sDim -= wDim;

	return sDim;
}



int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR szCmdLine, int iCmdShow)
{
	TCHAR szBuffer[200];
	TCHAR szOut[] = TEXT("(400:600) eax=%d");
	// ��������ָ�����ͣ�ָ������λMYPROC
	typedef DWORD(__cdecl *MYPROC)();
	// ���庯��
	MYPROC pSLWA;

	
	wsprintf(szBuffer, szOut, NTopXY(400, 600));
	MessageBox(NULL, szBuffer, NULL, MB_OK);



	// LoadLibrary�����ض�̬���ӿ�
	// GetProcAddress����ȡ�������õ�ַ
	pSLWA = (MYPROC)GetProcAddress(LoadLibrary(TEXT("05-01_winResult.dll")), TEXT("TopXY"));
	wsprintf(szBuffer, szOut, pSLWA(400, 600));// ��̬���ú���
	MessageBox(NULL, szBuffer, NULL, MB_OK);
}