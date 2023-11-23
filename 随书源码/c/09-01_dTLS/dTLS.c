//��̬TLS��ʾ

#include <Windows.h>


#define MAX_THREAD_COUNT 4


DWORD hTlsIndex;


/*
��ʼ��
*/
void _initTime()
{
	//��õ�ǰʱ�䣬
	//���̵߳Ĵ���ʱ�����̶߳��������
	if (!TlsSetValue(hTlsIndex, (PVOID)GetTickCount()))
	{
		MessageBox(NULL, TEXT("д��TLS������ʱʧ�ܣ�"), NULL, MB_OK);
	}
}


/*
��ȡ��ʱ
*/
DWORD _getLostTime()
{
	//��õ�ǰʱ�䣬
	//���ص�ǰʱ����̴߳���ʱ��Ĳ�ֵ
	DWORD dwTemp = GetTickCount();
	DWORD dwStart = (DWORD)TlsGetValue(hTlsIndex);
	if (dwStart == 0)
	{
		MessageBox(NULL, TEXT("��ȡTLS������ʱʧ�ܣ�"), NULL, MB_OK);
	}

	return dwTemp -= dwStart;
}


/*
�̺߳���
*/
void WINAPI _tFun(LPVOID lpParam)
{
	TCHAR szBuffer[500];// �ַ���������

	_initTime();// ��ʼ��ʱ��

	//ģ���ʱ����
	DWORD dwCount = 1000 * 10000;
	while (--dwCount > 0);
	// �����Ի���
	wsprintf(szBuffer, TEXT("�߳�%d��ֹ����ʱ��%d���롣"), GetCurrentThreadId(), _getLostTime());
	MessageBox(NULL, szBuffer, NULL, MB_OK);
}






int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	DWORD dwCount;// ѭ������
	HANDLE hThreadID[MAX_THREAD_COUNT];//�߳�id����
	DWORD dwThreadID;// �����̴߳���


	//ͨ���ڽ���λ����������һ��������
	//��ʼ���߳�����ʱ���¼ϵͳ
	hTlsIndex = TlsAlloc();

	dwCount = MAX_THREAD_COUNT;// �������߳���
	while (dwCount > 0)
	{
		// LPTHREAD_START_ROUTINE: ָ��֪ͨ�����߳��ѿ�ʼִ�еĺ���
		// �����̣߳���ִ��_tFun����
		hThreadID[MAX_THREAD_COUNT - dwCount] = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)_tFun,
			NULL, 0, &dwThreadID);
		// �߳���-1
		--dwCount;
	}

	//�ȴ������߳�
	dwCount = MAX_THREAD_COUNT;
	while (dwCount > 0)
	{
		// �ȴ����߳���ɷ���
		WaitForSingleObject(hThreadID[MAX_THREAD_COUNT - dwCount], INFINITE);
		// �ر����߳�
		CloseHandle(hThreadID[MAX_THREAD_COUNT - dwCount]);
		--dwCount;
	}

	//ͨ���ͷ��ֲ߳̾��洢������
	//�ͷ�ʱ���¼ϵͳռ�õ���Դ
	TlsFree(hTlsIndex);

	return 0;
}