//�ӳټ���ʵ��
//
//��08-01_MyDll.dllɾ�����޸����֣����г���


#include <Windows.h>
#include"..//08-01_MyDll//MyDll.h"



int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR szCmdLine, int iCmdShow)
{
	DWORD dwFlag = 1;

	if (dwFlag == 0)
	{
		sayHello();
	}
	MessageBox(NULL, TEXT("HelloWorldPE"), NULL, MB_OK);
	return 0;
}

