//测试异常处理
//
//Release版
//关闭SafeSEH
#include <Windows.h>
 


/*
这是一个异常处理函数的定义，下面我将解释其中的各个部分：

1. EXCEPTION_DISPOSITION: 这是一个枚举类型，通常用于指示异常处理函数的返回值，指示了异常处理的结果。
	它有三个可能的值：
   - `ExceptionContinueExecution`: 表示异常已被处理，程序可以继续执行。
   - `ExceptionContinueSearch`: 表示异常处理函数不处理异常，继续搜索其他的异常处理函数。
   - `ExceptionNestedException`: 当在异常处理过程中发生了另一个异常，该值指示嵌套异常的处理。

2. __cdecl: 这是一个调用约定（calling convention）的声明，用于指定函数的参数传递和堆栈清理方式。
	`__cdecl` 是 C/C++ 中最常见的调用约定，它指定函数的参数从右往左依次入栈，由调用者负责清理堆栈。
	这种调用约定常用于标准 C 函数。

3. PEXCEPTION_RECORD: 这是一个结构体类型，通常用于描述异常的详细信息。
	`PEXCEPTION_RECORD` 包含了异常代码、异常地址、异常参数等信息，用于异常处理函数获取异常的各种属性。

4. PVOID: 这是一个通用指针类型，用于表示指向未知类型数据的指针。
	它是一个泛型指针，通常用于指向各种不同类型的数据。
	在上述函数定义中，`PVOID` 用于表示指向 `_lpSEH` 和 `_lpDispatcherContext` 的指针，
	而不需要了解具体的数据类型。

5. PCONTEXT: 这是一个结构体类型，通常用于表示线程的上下文信息，包括寄存器值、指令指针等。
	在异常处理函数中，`PCONTEXT` 通常用于获取和修改线程的上下文信息，以实现异常处理。

在上述函数定义中，`__cdecl` 指示这是一个使用 C 调用约定的函数。`_handler` 函数接受四个参数：
- `_lpException`（`PEXCEPTION_RECORD`类型）：指向描述异常信息的结构体的指针。
- `_lpSEH`（`PVOID`类型）：指向结构化异常处理（SEH）数据的指针。SEH 是 Windows 操作系统中用于异常处理的机制。
- `_lpContext`（`PCONTEXT`类型）：指向线程上下文信息的指针，它包含有关线程状态的信息，例如寄存器值。
- `_lpDispatcherContext`（`PVOID`类型）：一个指针，通常用于传递上下文信息，以便在异常处理期间执行特定操作。

函数返回类型 `EXCEPTION_DISPOSITION` 表示它将返回一个值，指示异常处理的结果。根据函数的实际实现，它可以返回上述三个值中的一个，以告知操作系统如何继续处理异常。
*/
EXCEPTION_DISPOSITION __cdecl _handler(PEXCEPTION_RECORD _lpException, PVOID _lpSEH, 
	PCONTEXT _lpContext, PVOID _lpDispatcherContext)
{
	// 先弹出messagebox框，证明进入了异常处理函数
	MessageBox(NULL, TEXT("SEH Error"), NULL, MB_OK);

	// *(PDWORD)0 = 0翻译成指令为mov dword ptr ds:[0],0x0，占10个字节，eip+10即跳过该指令
	_lpContext->Eip += 10;

	// 测试一
	// 发生的异常已被该函数接管
	return ExceptionContinueExecution;


	//测试二
	//发生的异常未被该函数接管
	//return ExceptionContinueSearch;
}


int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	// 构建try
	__asm
	{
		push _handler
		push fs : [0]
		mov fs : [0], esp
	}

	*(PDWORD)0 = 0;
	
_safePlace:
	// 构建catch
	__asm
	{
		pop dword ptr fs : [0]
		pop eax
	}

	MessageBox(NULL, TEXT("HelloWorldPE"), NULL, MB_OK);
	return 0;

	

}