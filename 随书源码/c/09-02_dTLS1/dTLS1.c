//��̬TLS�Ա���ʾ
//��ʹ��TLS�Ķ��߳�Ӧ�ó���

#include <Windows.h>

#define MAX_THREAD_COUNT 4


/*
�̺߳���
*/
void WINAPI _tFun(LPVOID lpParam)
{
	TCHAR szBuffer[500];


	//��õ�ǰʱ�䣬
	//���̵߳Ĵ���ʱ�����̶߳��������
	DWORD dwStart = GetTickCount();

	//ģ���ʱ����
	DWORD dwCount = 1000 * 10000;
	while (--dwCount > 0);

	DWORD dwEnd = GetTickCount();
	// ������Ϣ��
	wsprintf(szBuffer, TEXT("�߳�%d��ֹ����ʱ��%d���롣"), GetCurrentThreadId(), dwEnd - dwStart);
	MessageBox(NULL, szBuffer, NULL, MB_OK);
}






int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	DWORD dwCount;// �̼߳���
	HANDLE hThreadID[MAX_THREAD_COUNT];// ���߳̾���б�
	DWORD dwThreadID;// �����̴߳���


	dwCount = MAX_THREAD_COUNT;// �������߳���
	while (dwCount > 0)
	{
		// �������̣߳���ִ��_tFun����
		hThreadID[MAX_THREAD_COUNT - dwCount] = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)_tFun,
			NULL, 0, &dwThreadID);
		--dwCount;
	}

	//�ȴ������߳�
	dwCount = MAX_THREAD_COUNT;
	while (dwCount > 0)
	{
		// �ȴ��߳�ִ�����
		WaitForSingleObject(hThreadID[MAX_THREAD_COUNT - dwCount], INFINITE);
		// �ر��߳�
		CloseHandle(hThreadID[MAX_THREAD_COUNT - dwCount]);
		--dwCount;
	}

	return 0;
}