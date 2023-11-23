// 简单DLL动态链接库

#include<Windows.h>
#include"MyDll.h"


int WINAPI DllmMain(HINSTANCE hInstance, DWORD fdwReason, PVOID pvReserved)
{
	return TRUE;
}



/*
输出
*/
void sayHello(DWORD wDim, DWORD sDim)
{
	MessageBox(NULL, TEXT("DLL Hello"), NULL, MB_OK);
}