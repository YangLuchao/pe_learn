//获取kernel32.dll的基址
//从SEH框架空间中搜索kernel32.dll的基地址
//
//win7下_except_handler地在ntdll
//xp下_except_handler在kernel32


#include<windows.h>


// SEH链表
typedef struct _EXCEPTION_REGISTRATION
{
	struct _EXCEPTION_REGISTRATION * prev;
	DWORD handler;
}EXCEPTION_REGISTRATION, *PEXCEPTION_REGISTRATION;




int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	PEXCEPTION_REGISTRATION pExceptionRegistration;//SEH链表指针
	DWORD dwAddress;// dll首地址
	TCHAR szBuffer[256];// 字符串缓冲区

	// 定义try，首地址即为pExceptionRegistration
	__asm
	{
		mov eax, fs:[0] 
		mov pExceptionRegistration,eax 
	}

	
	do
	{
		dwAddress = pExceptionRegistration->handler;// handler为指定的异常处理函数地址
		pExceptionRegistration = pExceptionRegistration->prev;// prev为下一个处理节点地址
	}while ((DWORD)pExceptionRegistration != 0xffffffff);// 找到异常处理链的最后一个节点
	
	// dwAddress = dwAddress / 0x10000 * 0x10000: 向下取整
	// *(PWORD)dwAddress != 0x5A4D：找到DOS头,否则继续循环
	// dwAddress -= 0x10000：-10000h继续循环，直到找到DOS头
	for (dwAddress = dwAddress / 0x10000 * 0x10000; *(PWORD)dwAddress != 0x5A4D; dwAddress -= 0x10000);

	// 输出模块基地址
	wsprintf(szBuffer, TEXT("kernel32.dll的基地址为%08x"), dwAddress);
	MessageBox(NULL, szBuffer, NULL, MB_OK);
}

