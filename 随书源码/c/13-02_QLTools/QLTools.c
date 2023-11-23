#include <Windows.h>
#include<tlhelp32.h>
#include "resource.h"




HINSTANCE hInstance;



/*
��ȡָ�����̹���ģ���б�
hModuleShowList�������������б�ؼ�
dwIndex����ѡ�н��̾��
*/
void _GetModuleList(HWND hModuleShowList, DWORD dwIndex)
{
	HANDLE hModuleSnapshot;// 
/*
typedef struct tagMODULEENTRY32 {
  DWORD   dwSize;		// �ṹ��С�����ֽ�Ϊ��λ��
  DWORD   th32ModuleID;	// �˳�Ա����ʹ�ã�����ʼ������Ϊ 1
  DWORD   th32ProcessID;// Ҫ�����ģ��Ľ��̱�ʶ��
  DWORD   GlblcntUsage;	// ģ��ĸ��ؼ�����ͨ��û�����壬ͨ������0xFFFF
  DWORD   ProccntUsage;	// ģ��ĸ��ؼ��� (GlblcntUsage) ��ͬ����ͨ��û�����壬ͨ������0xFFFF
  BYTE    *modBaseAddr;	// ӵ�н�����������ģ��Ļ�ַ
  DWORD   modBaseSize;	// ģ��Ĵ�С�����ֽ�Ϊ��λ��
  HMODULE hModule;		// ӵ�н�����������ģ��ľ��
  char    szModule[MAX_MODULE_NAME32 + 1];	// ģ����
  char    szExePath[MAX_PATH];				// ģ��·��
} MODULEENTRY32;
*/
	MODULEENTRY32 process_ME;// ��������ָ�����̵�ģ���б��е���Ŀ
	BOOL bModule;// �Ƿ����ѭ����ʶ

	// ����ϸ�ؼ��з�����Ϣ������б��
	// LB_RESETCONTENT�����б�����Ƴ�������
	SendMessage(hModuleShowList, LB_RESETCONTENT, 0, 0);
	// �������̿��ա����ؾ��
	// TH32CS_SNAPMODULE��ֻ��Ҫ���ؽ�����Ϣ
	// dwIndex��Ŀ����̾��
	hModuleSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, dwIndex);
	// �õ�������Ϣ����װ��MODULEENTRY32��
	bModule = Module32First(hModuleSnapshot, &process_ME);

	while (bModule)// ��ѯ
	{
		// ��ѯ���еı�����ģ��
		// �����ǰģ��Ľ���id���ڵ�ǰ��ѡ���id������ӿؼ���չʾ
		if (process_ME.th32ProcessID == dwIndex)
		{
			SendMessage(hModuleShowList, LB_ADDSTRING, 0, (LPARAM)&process_ME.szExePath);
		}
		// ������һ��ģ��
		bModule = Module32Next(hModuleSnapshot, &process_ME);
	}

	CloseHandle(hModuleSnapshot);
}


/*
��ȡ�����б�
*/
void _GetProcessList(HWND hWnd, HWND hProcessListBox, HWND hModuleShowList)
{
	/*
typedef struct tagPROCESSENTRY32 {
  DWORD     dwSize;				// �ṹ��С�����ֽ�Ϊ��λ��
  DWORD     cntUsage;			// �˳�Ա����ʹ�ã�����ʼ������Ϊ��
  DWORD     th32ProcessID;		// ���̱�ʶ��
  ULONG_PTR th32DefaultHeapID;	// �˳�Ա����ʹ�ã�����ʼ������Ϊ��
  DWORD     th32ModuleID;		// �˳�Ա����ʹ�ã�����ʼ������Ϊ��
  DWORD     cntThreads;			// ����������ִ���߳���
  DWORD     th32ParentProcessID;// �����˽��̵Ľ��̵ı�ʶ�� (�丸����) 
  LONG      pcPriClassBase;		// �˽��̴������κ��̵߳Ļ������ȼ�
  DWORD     dwFlags;			// �˳�Ա����ʹ�ã�����ʼ������Ϊ��
  CHAR      szExeFile[MAX_PATH];// ���̵Ŀ�ִ���ļ������ơ� ��Ҫ������ִ���ļ�������·��������� Module32First ��������鷵�ص� MODULEENTRY32 �ṹ�� szExePath ��Ա�� ���ǣ�������ý����� 32 λ���̣��������� QueryFullProcessImageName ���������� 64 λ���̵Ŀ�ִ���ļ�������·��
} PROCESSENTRY32;
	*/
	PROCESSENTRY32 process_PE;// ������ȡ����ʱפ����ϵͳ��ַ�ռ��еĽ��̵��б��е���Ŀ
	HANDLE hProcessSnapshot;// ���վ��
	BOOL bProcess;// �Ƿ�����ɱ�ʶ
	DWORD dwProcessID;// 
	DWORD dwIndex;// ����˳���ʶ

	RtlZeroMemory(&process_PE, sizeof(process_PE));// ��ʼ��һ��ռ�
	SendMessage(hProcessListBox, LB_RESETCONTENT, 0, 0);// ������Ϣ����ս����б�Ի�����

	process_PE.dwSize = sizeof(process_PE);// ���ý����б��С��С
	// ��ȡָ�������Լ���Щ����ʹ�õĶѡ�ģ����̵߳Ŀ���
	// TH32CS_SNAPPROCESS��ֻ��Ҫ������Ϣ
	// �ڶ�������Ϊ0����ʾ��ǰ����
	hProcessSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
	// ��ȡ�й�ϵͳ�����������ĵ�һ�����̵���Ϣ
	// hProcessSnapshot�����յľ�����þ���Ǵ��ϴε��� CreateToolhelp32Snapshot �������ص�
	// process_PE��ָ�� PROCESSENTRY32 �ṹ��ָ�롣 ������������Ϣ�������ִ���ļ������ơ����̱�ʶ���͸����̵Ľ��̱�ʶ��
	bProcess = Process32First(hProcessSnapshot, &process_PE);

	// ѭ������ȫ��������Ϣ
	while (bProcess)
	{	
		// �������б�����Ϣ�����string����
		// LB_ADDSTRING�����ַ�����ӵ��б��
		// �ַ�����ַ
		dwIndex = SendMessage(hProcessListBox, LB_ADDSTRING, 0, (LPARAM)&process_PE.szExeFile);
		// �������б��з�����Ϣ
		// LB_SETITEMDATA���������б����ָ���������ֵ
		// dwIndex�����б��е�λ��
		// ��������ʱ�˽��̵ı�ʶ��
		SendMessage(hProcessListBox, LB_SETITEMDATA, dwIndex, process_PE.th32ProcessID);
		// ������һ��
		bProcess = Process32Next(hProcessSnapshot, &process_PE);
	}
	// ������ɣ��رվ��
	CloseHandle(hProcessSnapshot);

	// ѡ�е�һ��
	// LB_SETCURSEL��ѡ��һ���ַ����������������ͼ��
	dwIndex = SendMessage(hProcessListBox, LB_SETCURSEL, 0, 0);
	// LB_GETITEMDATA��ָ���б���������Ӧ�ó�����ֵ
	// ��ȡ��һ�����Ľ���id
	dwProcessID = SendMessage(hProcessListBox, LB_GETITEMDATA, dwIndex, 0);
	// ��ȡָ�����̹���ģ���б�
	_GetModuleList(hModuleShowList, dwProcessID);
	EnableWindow(GetDlgItem(hWnd, IDOK), FALSE);
}



/*
ִ�н������̵ĳ���
����Ϊ��ntsd
����Ϊ��-c q -p PID
*/
void _RunThread(DWORD  dwIndex)
{
	// ָ������ʱ���̵Ĵ��ڹ���վ�����桢��׼�����main���ڵ����
	STARTUPINFO stStartUp;
	// stProcInfo�������й��´����Ľ��̼������̵߳���Ϣ
/*
typedef struct _PROCESS_INFORMATION {
  HANDLE hProcess;	// �´������̵ľ��
  HANDLE hThread;	// �´����Ľ��̵����̵߳ľ��
  DWORD  dwProcessId;	// ����id
  DWORD  dwThreadId;	// �߳�id
} PROCESS_INFORMATION, *PPROCESS_INFORMATION, *LPPROCESS_INFORMATION;
*/
	PROCESS_INFORMATION stProcInfo;

	TCHAR szProcessFileName[256];

	wsprintf(szProcessFileName, TEXT("ntsd -c q -p %u"), dwIndex);
	// ��ѯ�������ý���ʱָ���� STARTUPINFO �ṹ������
	GetStartupInfo(&stStartUp);
	// 64λϵͳ����ҪC:\Windows\SysWOW64����ntsd.exe
	// 32λϵͳ����ҪC:\Windows\System32����ntsd.exe
	if (CreateProcess(NULL, szProcessFileName, NULL, NULL, FALSE, NORMAL_PRIORITY_CLASS,
		NULL, NULL, &stStartUp, &stProcInfo))// �����ɹ�
	{
		WaitForSingleObject(stProcInfo.hProcess, INFINITE);
		CloseHandle(stProcInfo.hProcess);
		CloseHandle(stProcInfo.hThread);
	}
	else
	{	// ����ʧ��
		MessageBox(NULL, TEXT("����Ӧ�ó������"), NULL, MB_OK | MB_ICONERROR);
	}

}



/*
���ڳ���
*/
INT_PTR CALLBACK _ProcKillMain(HWND hWnd, UINT wMsg, WPARAM wParam, LPARAM lParam)
{
	HICON hIcon;
	static HWND hProcessListBox;
	static HWND hModuleShowList;
	DWORD dwProcessID;
	DWORD dwIndex;


	switch (wMsg)
	{
	case WM_CLOSE:
		EndDialog(hWnd, 0);
		break;

	case WM_INITDIALOG:			//��ʼ��
		hIcon = LoadIcon(hInstance, MAKEINTRESOURCE(ICO_MAIN));
		SendMessage(hWnd, WM_SETICON, ICON_BIG, (LPARAM)hIcon);
		// GetDlgItem����ȡָ���Ի����пؼ��ľ��
		hProcessListBox = GetDlgItem(hWnd, IDC_PROCESS);
		hModuleShowList = GetDlgItem(hWnd, IDC_PROCESS_MODEL);
		// ��ȡ�����б�
		_GetProcessList(hWnd, hProcessListBox, hModuleShowList);//��ʾ���̣����ѵ�һ����̵�ӳ��ģ��Ҳ��ʾ����
		break;

	case WM_COMMAND:			
		switch (LOWORD(wParam))
		{
		case IDOK:	// ��ֹ
			dwIndex = SendMessage(hProcessListBox, LB_GETCURSEL, 0, 0);
			dwProcessID = SendMessage(hProcessListBox, LB_GETITEMDATA, dwIndex, 0);
			_RunThread(dwProcessID);
			Sleep(200);
			_GetProcessList(hWnd, hProcessListBox, hModuleShowList);
			break;

		case IDC_REFRESH:// ˢ�°�ť			
			_GetProcessList(hWnd, hProcessListBox, hModuleShowList);
			break;

		case IDC_PROCESS:// �����б�ؼ�
			// LBN_SELCHANGE��֪ͨӦ�ó����б���е�ѡ�������û����������
			if (HIWORD(wParam) == LBN_SELCHANGE)
			{
				// LB_GETCURSEL����ȡ��ѡ�б���е�ǰ��ѡ�������
				dwIndex = SendMessage(hProcessListBox, LB_GETCURSEL, 0, 0);
				// LB_GETITEMDATA����ȡ��ָ���б���������Ӧ�ó�����ֵ
				dwProcessID = SendMessage(hProcessListBox, LB_GETITEMDATA, dwIndex, 0);
				_GetModuleList(hModuleShowList,dwProcessID); //������ʾӳ���ģ��
				EnableWindow(GetDlgItem(hWnd, IDOK), TRUE);
			}
			break;
		}
		break;

	default:
		return FALSE;
	}

	return TRUE;
}




int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	hInstance = hInst;
	DialogBoxParam(hInstance, MAKEINTRESOURCE(PROCESSDLG_KILL), NULL, _ProcKillMain, (LPARAM)NULL);
	return 0;
}