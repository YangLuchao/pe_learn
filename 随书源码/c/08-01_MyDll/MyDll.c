// ��DLL��̬���ӿ�

#include<Windows.h>
#include"MyDll.h"


int WINAPI DllmMain(HINSTANCE hInstance, DWORD fdwReason, PVOID pvReserved)
{
	return TRUE;
}



/*
���
*/
void sayHello(DWORD wDim, DWORD sDim)
{
	MessageBox(NULL, TEXT("DLL Hello"), NULL, MB_OK);
}