//������������
//
//��ֹ�Ż� �ѽ��� (/Od)


#include <Windows.h>


//�������ͷ�ʱ���޸Ĵ˴�������ֵ�������ʼ���������ʽ�Ƿ���������ǵ��ļ�ƫ��
DWORD hProcessID=0x11111111;	//��������̺�
DWORD oldMajor=0x22222222;		//���ɰ汾��ֵ
DWORD oldMinor=0x33333333;		//�ξɰ汾��ֵ

int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	DWORD newMajor;// ���汾��
	DWORD newMinor;// �°汾��
	HANDLE hProcess;// ���̾��

	STARTUPINFO stStartUp;// ָ������ʱ���̵Ĵ��ڹ���վ�����桢��׼�����main���ڵ����
	PROCESS_INFORMATION stProcInfo;// ������Ϣ

	TCHAR szDataBuffer[256];
	TCHAR szBuffer[256];


	TCHAR szINI[] = TEXT("���������ļ�");
	TCHAR szINIURL[] = TEXT("http://127.0.0.1/version.ini");
	TCHAR szLINI[] = TEXT(".\\_tmp.ini"); 
	TCHAR szSectionName[] = TEXT("13-01_DPatchPEInfo.exe"); //��Բ�ͬ�ĳ����޸Ĵ˴���ֵ
	TCHAR szKeyName1[] = TEXT("majorImageVersion");
	TCHAR szKeyName2[] = TEXT("minorImageVersion");
	TCHAR szKeyName3[] = TEXT("downloadfile");
	TCHAR szIsNewVesion[] = TEXT("�����Ѿ������°汾");
 	TCHAR szOut2[] = TEXT("���ز����ļ�");
	TCHAR szPROCURL[] = TEXT("http://127.0.0.1/%s"); //Ҫ���ص�EXE�ļ�

	// �����Ի���
	MessageBox(NULL, szINIURL, szINI, MB_OK);
	//����ini�ļ�,��Ҫֱ���ڱ��ش��web����������ini�ļ�������վ��Ŀ¼
/*
URLDownloadToFile ���ڴ�ָ����URL�����ļ������䱣�浽�����ļ�ϵͳ��ָ��λ��

pCaller: ����һ��ָ�������(IUnknown)��ָ�룬ͨ����������ΪNULL��
szURL: ����һ��ָ�����Ҫ�����ļ���URL���ַ�����ָ�롣
szFileName: ����һ��ָ�򱾵��ļ������ַ�����ָ�룬����ָ�����غ��ļ��ı���λ�á�
dwReserved: �������������ͨ������Ϊ0��
lpfnCB: ����һ���ص�������ָ�룬���ڽ������ؽ��ȵ�֪ͨ����������ΪNULL���������Ҫ���ؽ���֪ͨ��
*/
	URLDownloadToFile(0, szINIURL, szLINI, 0, 0);
	// GetPrivateProfileInt: �������ʼ���ļ���ָ�����еļ�����������
	newMajor = GetPrivateProfileInt(szSectionName, szKeyName1, 0, szLINI);
	newMinor = GetPrivateProfileInt(szSectionName, szKeyName2, 0, szLINI);

	//�ж��Ƿ����°汾PE
	if (newMajor == oldMajor && newMinor == oldMinor)
	{
		// ��ʾ�Ѿ������°汾 
		MessageBox(NULL, szIsNewVesion, NULL, MB_OK);
	}
	else
	{
		// �����°汾�������ظ�PE����ʵʩ�滻
		// ��ջ�����
		RtlZeroMemory(szDataBuffer, 256);
		// ȡ�ļ���
		GetPrivateProfileString(szSectionName, szKeyName3, NULL, szDataBuffer, sizeof(szDataBuffer), szLINI); 
		wsprintf(szBuffer, szPROCURL, szDataBuffer);
		MessageBox(NULL, szBuffer, szOut2, MB_OK);
		// ����exe�ļ�����Ҫֱ���ڱ��ش��web����������exe�ļ�������վ��Ŀ¼
		URLDownloadToFile(0, szBuffer, szDataBuffer, 0, 0);
		// ������ǰ������
		hProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, hProcessID);
		Sleep(1000);
		// �жϽ���
		TerminateProcess(hProcess, 0);
		CloseHandle(hProcess);
		Sleep(1000);

		//�����ص��ļ��滻ΪPE�ļ�
		DeleteFile(szSectionName);
		CopyFile(szDataBuffer, szSectionName, TRUE);
		Sleep(1000);

		// ����PE����
		// GetStartupInfo: �����������ý���ʱָ���� STARTUPINFO �ṹ������
		GetStartupInfo(&stStartUp);
		CreateProcess(NULL, szSectionName, NULL, NULL, FALSE, NORMAL_PRIORITY_CLASS, 
			NULL, NULL, &stStartUp, &stProcInfo);

	}

	return 0;
}