//�����쳣����
//
//Release��
//�ر�SafeSEH
#include <Windows.h>
 


/*
����һ���쳣�������Ķ��壬�����ҽ��������еĸ������֣�

1. EXCEPTION_DISPOSITION: ����һ��ö�����ͣ�ͨ������ָʾ�쳣�������ķ���ֵ��ָʾ���쳣����Ľ����
	�����������ܵ�ֵ��
   - `ExceptionContinueExecution`: ��ʾ�쳣�ѱ�����������Լ���ִ�С�
   - `ExceptionContinueSearch`: ��ʾ�쳣�������������쳣�����������������쳣��������
   - `ExceptionNestedException`: �����쳣��������з�������һ���쳣����ֵָʾǶ���쳣�Ĵ���

2. __cdecl: ����һ������Լ����calling convention��������������ָ�������Ĳ������ݺͶ�ջ����ʽ��
	`__cdecl` �� C/C++ ������ĵ���Լ������ָ�������Ĳ�����������������ջ���ɵ����߸��������ջ��
	���ֵ���Լ�������ڱ�׼ C ������

3. PEXCEPTION_RECORD: ����һ���ṹ�����ͣ�ͨ�����������쳣����ϸ��Ϣ��
	`PEXCEPTION_RECORD` �������쳣���롢�쳣��ַ���쳣��������Ϣ�������쳣��������ȡ�쳣�ĸ������ԡ�

4. PVOID: ����һ��ͨ��ָ�����ͣ����ڱ�ʾָ��δ֪�������ݵ�ָ�롣
	����һ������ָ�룬ͨ������ָ����ֲ�ͬ���͵����ݡ�
	���������������У�`PVOID` ���ڱ�ʾָ�� `_lpSEH` �� `_lpDispatcherContext` ��ָ�룬
	������Ҫ�˽������������͡�

5. PCONTEXT: ����һ���ṹ�����ͣ�ͨ�����ڱ�ʾ�̵߳���������Ϣ�������Ĵ���ֵ��ָ��ָ��ȡ�
	���쳣�������У�`PCONTEXT` ͨ�����ڻ�ȡ���޸��̵߳���������Ϣ����ʵ���쳣����

���������������У�`__cdecl` ָʾ����һ��ʹ�� C ����Լ���ĺ�����`_handler` ���������ĸ�������
- `_lpException`��`PEXCEPTION_RECORD`���ͣ���ָ�������쳣��Ϣ�Ľṹ���ָ�롣
- `_lpSEH`��`PVOID`���ͣ���ָ��ṹ���쳣����SEH�����ݵ�ָ�롣SEH �� Windows ����ϵͳ�������쳣����Ļ��ơ�
- `_lpContext`��`PCONTEXT`���ͣ���ָ���߳���������Ϣ��ָ�룬�������й��߳�״̬����Ϣ������Ĵ���ֵ��
- `_lpDispatcherContext`��`PVOID`���ͣ���һ��ָ�룬ͨ�����ڴ�����������Ϣ���Ա����쳣�����ڼ�ִ���ض�������

������������ `EXCEPTION_DISPOSITION` ��ʾ��������һ��ֵ��ָʾ�쳣����Ľ�������ݺ�����ʵ��ʵ�֣������Է�����������ֵ�е�һ�����Ը�֪����ϵͳ��μ��������쳣��
*/
EXCEPTION_DISPOSITION __cdecl _handler(PEXCEPTION_RECORD _lpException, PVOID _lpSEH, 
	PCONTEXT _lpContext, PVOID _lpDispatcherContext)
{
	// �ȵ���messagebox��֤���������쳣������
	MessageBox(NULL, TEXT("SEH Error"), NULL, MB_OK);

	// *(PDWORD)0 = 0�����ָ��Ϊmov dword ptr ds:[0],0x0��ռ10���ֽڣ�eip+10��������ָ��
	_lpContext->Eip += 10;

	// ����һ
	// �������쳣�ѱ��ú����ӹ�
	return ExceptionContinueExecution;


	//���Զ�
	//�������쳣δ���ú����ӹ�
	//return ExceptionContinueSearch;
}


int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	// ����try
	__asm
	{
		push _handler
		push fs : [0]
		mov fs : [0], esp
	}

	*(PDWORD)0 = 0;
	
_safePlace:
	// ����catch
	__asm
	{
		pop dword ptr fs : [0]
		pop eax
	}

	MessageBox(NULL, TEXT("HelloWorldPE"), NULL, MB_OK);
	return 0;

	

}