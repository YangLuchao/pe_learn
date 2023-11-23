//测试异常处理
//与exception4相比，该程序中调用了未注册的异常处理函数_handler2
//
//
//Release版
//基址0x00400000
//保留从未引用的函数和/或数据
//关闭SafeSEH
//
//vs编译会生成配置信息，所以不用构造IMAGE_LOAD_CONFIG_STRUCT，直接修改就行了，在文件偏移为0x1158处
//在节的末尾找一个空的位置，存放 已注册的异常回调函数 的偏移地址
//文件偏移0x1640处即为本节尾部，转换为内存地址为0x00402640
//所以把0x1198处改为 40 26 40 00 后面紧接着填函数个数  01 00 00 00
//函数在内存中地址为0x00401000，所以文件偏移0x1640修改为函数的内存偏移 00 10 00 00
//
//


#include <Windows.h>


/*
已注册的异常回调函数
*/
EXCEPTION_DISPOSITION __cdecl _handler1(PEXCEPTION_RECORD _lpException, PVOID _lpSEH,
	PCONTEXT _lpContext, PVOID _lpDispatcherContext)
{
	MessageBox(NULL, TEXT("safeHandler!"), NULL, MB_OK);

	_lpContext->Eip += 10;//*(PDWORD)0 = 0翻译成指令为mov dword ptr ds:[0],0x0，占10个字节，eip+10即跳过该指令

	return ExceptionContinueExecution;
}



/*
未注册的异常回调函数
*/
EXCEPTION_DISPOSITION __cdecl _handler2(PEXCEPTION_RECORD _lpException, PVOID _lpSEH,
	PCONTEXT _lpContext, PVOID _lpDispatcherContext)
{
	MessageBox(NULL, TEXT("nosafeHandler!"), NULL, MB_OK);

	_lpContext->Eip += 10;//*(PDWORD)0 = 0翻译成指令为mov dword ptr ds:[0],0x0，占10个字节，eip+10即跳过该指令

	return ExceptionContinueExecution;
}




int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{



	__asm
	{
		push _handler2// 指定哪个函数就用哪个函数处理
			push fs : [0]
			mov fs : [0], esp
	}

	*(PDWORD)0 = 0;//引发越界异常

_safePlace:
	__asm
	{
		pop dword ptr fs : [0]
			pop eax
	}

	MessageBox(NULL, TEXT("HelloWorldPE"), NULL, MB_OK);
	return 0;



}