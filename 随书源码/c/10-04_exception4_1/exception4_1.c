//�����쳣����
//��exception4��֮ͬ����ע����쳣�������Ϊ_handler2
//safe Handler�б�������������������ע��
//
//
//Release��
//��ַ0x00400000
//������δ���õĺ�����/������
//�ر�SafeSEH
//
//vs���������������Ϣ�����Բ��ù���IMAGE_LOAD_CONFIG_STRUCT��ֱ���޸ľ����ˣ����ļ�ƫ��Ϊ0x1158��
//�ڽڵ�ĩβ��һ���յ�λ�ã���� ��ע����쳣�ص����� ��ƫ�Ƶ�ַ
//�ļ�ƫ��0x1640����Ϊ����β����ת��Ϊ�ڴ��ַΪ0x00402640
//���԰�0x1198����Ϊ 40 26 40 00 ����������������  02 00 00 00
//����1���ڴ��е�ַΪ0x00401000�������ļ�ƫ��0x1640�޸�Ϊ�������ڴ�ƫ�� 00 10 00 00
//����2���ڴ��е�ַΪ0x00401030�������ļ�ƫ��0x1644�޸�Ϊ�������ڴ�ƫ�� 30 10 00 00
//


#include <Windows.h>


/*
��ע����쳣�ص�����1
*/
EXCEPTION_DISPOSITION __cdecl _handler1(PEXCEPTION_RECORD _lpException, PVOID _lpSEH,
	PCONTEXT _lpContext, PVOID _lpDispatcherContext)
{
	MessageBox(NULL, TEXT("safeHandler!"), NULL, MB_OK);

	_lpContext->Eip += 10;//*(PDWORD)0 = 0�����ָ��Ϊmov dword ptr ds:[0],0x0��ռ10���ֽڣ�eip+10��������ָ��

	return ExceptionContinueExecution;
}



/*
��ע����쳣�ص�����2
*/
EXCEPTION_DISPOSITION __cdecl _handler2(PEXCEPTION_RECORD _lpException, PVOID _lpSEH,
	PCONTEXT _lpContext, PVOID _lpDispatcherContext)
{
	MessageBox(NULL, TEXT("nosafeHandler!"), NULL, MB_OK);

	_lpContext->Eip += 10;//*(PDWORD)0 = 0�����ָ��Ϊmov dword ptr ds:[0],0x0��ռ10���ֽڣ�eip+10��������ָ��

	return ExceptionContinueExecution;
}




int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{



	__asm
	{
		push _handler2// ָ���ĸ������ĸ������ʹ���
			push fs : [0]
			mov fs : [0], esp
	}

	*(PDWORD)0 = 0;//����Խ���쳣

_safePlace:
	__asm
	{
		pop dword ptr fs : [0]
			pop eax
	}

	MessageBox(NULL, TEXT("HelloWorldPE"), NULL, MB_OK);
	return 0;



}