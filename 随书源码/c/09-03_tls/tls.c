//静态TLS演示
//
//编译时关闭随机基址
//基址0x00400000
//
//将1b0处修改为0c 80 01 00   18 00 00 00  


#include <Windows.h>



DWORD Tls1 = 0;
DWORD Tls2 = 0;
DWORD Tls3 = 0;
DWORD TlsCallBack[] = { 0x00411b1c,//TLS地址
						0,
						0 };



//构造IMAGE_TLS_DIRECTORY
DWORD TLS_DIR[] = { (DWORD)&Tls1, (DWORD)&Tls2, (DWORD)&Tls3, (DWORD)&TlsCallBack, 0, 0 };



DWORD TLSCalled;//重进标志


int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	MessageBox(NULL, TEXT("MAIN"), NULL, MB_OK);
	return 0;

	//以下代码将会在.code之前执行一次
TLS:
	//变量TLSCalled是一个防重进标志。正常情况下该部分代码
	//会被执行两次，但使用了该标识后，该代码只在开始运行前
	//执行一次
	if (TLSCalled == 0)
	{
		TLSCalled = 1;
		MessageBox(NULL, TEXT("TLS"), NULL, MB_OK);
	}

	return 0;
}