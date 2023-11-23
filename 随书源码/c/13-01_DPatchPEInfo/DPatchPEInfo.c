// 02-04_PEInfo��ַ0x00400000
// �˳����ַ0x00400000
// ��Դ����Ϊ�ɶ�д
#include <Windows.h>
#include<Richedit.h>
#include "resource.h"


#define STOP_FLAG_POSITION  0x0041c000  //02-04_PEInfo��dwFlag���ڴ��еĵ�ַ

#define MAJOR_IMAGE_VERSION  1//��ǰ��������汾��
#define MINOR_IMAGE_VERSION  0//��ǰ����Ĵΰ汾��

HINSTANCE hInstance;



/*
��ʼ�����ڳ���
*/
void _Init(HWND hWinMain)
{
	HWND hWinEdit;

	HICON hIcon;
	CHARFORMAT stCf;
	TCHAR szFont[] = TEXT("����");


	hWinEdit = GetDlgItem(hWinMain, IDC_INFO);
	hIcon = LoadIcon(hInstance, MAKEINTRESOURCE(ICO_MAIN));
	SendMessage(hWinMain, WM_SETICON, ICON_BIG, (LPARAM)hIcon);	//Ϊ��������ͼ��
	SendMessage(hWinEdit, EM_SETTEXTMODE, TM_PLAINTEXT, 0);		//���ñ༭�ؼ�

	RtlZeroMemory(&stCf, sizeof(stCf));
	stCf.cbSize = sizeof(stCf);
	stCf.yHeight = 9 * 20;
	stCf.dwMask = CFM_FACE | CFM_SIZE | CFM_BOLD;
	lstrcpy(stCf.szFaceName, szFont);
	SendMessage(hWinEdit, EM_SETCHARFORMAT, 0, (LPARAM)&stCf);

	SendMessage(hWinEdit, EM_EXLIMITTEXT, 0, -1);
}



/*
д�ڴ�ʾ��
���Է�������������PEInfo.exe
          ��ʾKernel32.dll����Ϣ
�����ó���,��kernel32.dll��ʾ�ض�λʱ�����˵���һ��
�ᷢ��PEInfo.exe�ı����ض�λ��Ϣ����ֹ
*/
void _writeToPEInfo()
{
	HWND phwnd;// ���ھ��
	DWORD parent = 0;
	DWORD hProcessID;
	HANDLE hProcess;
	DWORD dwFlag;
	DWORD dwPatchDD = 1;


	TCHAR strTitle[256];
	TCHAR szTitle[] = TEXT("PEInfo");
	TCHAR szErr1[] = TEXT("Error happend when openning.");
	TCHAR szErr2[] = TEXT("Error happend when reading.");

	//ͨ�������ý��̵�handle	
	// GetDesktopWindow�� ��ȡ���洰�ھ��
	// GetWindow�� ��ȡָ�����ھ��
	// GW_CHILD�����ָ���Ĵ����Ǹ����ڣ���������ľ����ʶ Z ˳�򶥲����Ӵ���
	// GW_HWNDFIRST:�����ľ����ʶ Z ˳����������͵Ĵ���
	phwnd = GetWindow(GetWindow(GetDesktopWindow(), GW_CHILD), GW_HWNDFIRST);
	// �ж��Ƿ�Ϊ���㴰��
	if (!GetParent(phwnd))
	{
		parent = 1;
	}
	// ----------------------------------------------��һ�������Ŀ�괰�ڵľ��
	while (phwnd)
	{
		if (parent)
		{
			parent = 0; //��λ��־
			GetWindowText(phwnd, strTitle, sizeof(strTitle));//�õ����ڱ�������
			if (!lstrcmp(strTitle, szTitle))
			{
				break;
			}
		}

		// Ѱ��������ڵ���һ���ֵܴ���
		phwnd = GetWindow(phwnd, GW_HWNDNEXT);
		if (!GetParent(phwnd) && IsWindowVisible(phwnd))
		{
			parent = 1;
		}
	}
	// ----------------------------------------------��һ�������Ŀ�괰�ڵľ��

	//���ݴ��ھ����ȡ����ID
	GetWindowThreadProcessId(phwnd, &hProcessID);	
	if (hProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, hProcessID))//�ҵ��Ľ��̾����hProcess��
	{
		if (ReadProcessMemory(hProcess, (LPCVOID)STOP_FLAG_POSITION, &dwFlag, 4, NULL))//���ڴ�
		{
			WriteProcessMemory(hProcess,(LPVOID)STOP_FLAG_POSITION, &dwPatchDD,	4, NULL);//д�ڴ棬����־λ��ֵ
		}
		else
		{
			MessageBox(NULL, szErr2, NULL, MB_OK);
		}
		CloseHandle(hProcess);
	}
	else
	{
		MessageBox(NULL, szErr1, NULL, MB_OK);
	}
}


/*
�ͷ���Դ
*/
void _createDll()
{
	HRSRC hRes;
	DWORD dwResSize;
	HGLOBAL hGlobal;
	PVOID lpRes;
	HANDLE hFile;
	DWORD dwWritten;

	if (hRes = FindResource(hInstance, MAKEINTRESOURCE(IDB_UPDATE), "UPDATE"))
	{
		dwResSize = SizeofResource(hInstance, hRes); //��ȡ��Դ�ߴ�
		if (hGlobal = LoadResource(hInstance, hRes))//װ����Դ
		{
			lpRes = LockResource(hGlobal); //������Դ,����Դ�ڴ��ַ��lpRes
				
			//���ļ�д��
			hFile = CreateFile(TEXT("update.exe"), GENERIC_WRITE, FILE_SHARE_READ, 0,
				CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
			WriteFile(hFile, lpRes, dwResSize, &dwWritten, NULL);
			CloseHandle(hFile);
		}
	}
}


/*
���ڳ���
*/
INT_PTR CALLBACK _ProcDlgMain(HWND hWnd, UINT wMsg, WPARAM wParam, LPARAM lParam)
{
	STARTUPINFO	stStartUp;// ����������ʱ����Ϣ�ṹ
	PROCESS_INFORMATION stProcInfo;// ��Դ��Ϣָ��


	DWORD value;
	switch (wMsg)
	{
	case WM_CLOSE:
		EndDialog(hWnd, 0);
		break;

	case WM_INITDIALOG:			//��ʼ��
		_Init(hWnd);
		break;

	case WM_COMMAND:			//�˵�
		switch (LOWORD(wParam))
		{
		case IDM_EXIT:			//�˳�
			EndDialog(hWnd, 0);
			break;

		case IDM_OPEN:			//ֹͣ
			_writeToPEInfo();
			break;

		case IDM_1:				//����
			GetWindowThreadProcessId(hWnd, &value);
			*(PDWORD)0x00406484 = value;//0x0040647c��Ϊupdate�е�hProcessID
			*(PDWORD)0x0040648c = MAJOR_IMAGE_VERSION;//0x00406484��Ϊupdate�е�oldMajor
			*(PDWORD)0x00406488 = MINOR_IMAGE_VERSION;//0x00406480��Ϊupdate�е�oldMinor

			_createDll();//�ͷ�update.exe����

			//����update.exe����
			GetStartupInfo(&stStartUp);
			CreateProcess(NULL, TEXT("update.exe"), NULL, NULL, FALSE, NORMAL_PRIORITY_CLASS, 
				NULL, NULL, &stStartUp, &stProcInfo);



			break;
		case IDM_2:
		case IDM_3:
		default:
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
	HMODULE hRichEdit;// �ı��ؼ����

	hInstance = hInst;//��ǰ���̾��
	hRichEdit = LoadLibrary(TEXT("RichEd20.dll"));//�����ı��ؼ�
	DialogBoxParam(hInstance, MAKEINTRESOURCE(DLG_MAIN), NULL, _ProcDlgMain, (LPARAM)NULL);// ִ��_ProcDlgMain���������򿪶Ի���
	FreeLibrary(hRichEdit);// �ͷ��ı��ؼ�
	return 0;
}