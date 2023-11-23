//����ʱ��̬����dll
//
//����ǰ
//��		 05-01_winResult.dll1(��ʼdll)
//������Ϊ	 05-01_winResult.dll
//���ڵ�ǰĿ¼
//���ӳټ��ص�dll�����05-01_winResult.dll
//
//����ǰ
//��05-01_winResult.dllɾ�����޸����֣���Ȼ������

#include <Windows.h>
#include <Richedit.h>
#include "resource.h"
#include"..//05-01_winResult//winResult.h"





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
���ڳ���
*/
INT_PTR CALLBACK _ProcDlgMain(HWND hWnd, UINT wMsg, WPARAM wParam, LPARAM lParam)
{
	switch (wMsg)
	{
	case WM_CLOSE:
		EndDialog(hWnd, 0);
		break;

	case WM_INITDIALOG:			//��ʼ��
		AnimateOpen(hWnd);
		_Init(hWnd);
		break;

	case WM_COMMAND:			//�˵�
		switch (LOWORD(wParam))
		{
		case IDM_EXIT:			//�˳�
			EndDialog(hWnd, 0);
			break;

		case IDM_OPEN:			//���ļ�
		case IDM_1:
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



//��̬����winResult.dll
void _createDll(HINSTANCE  _hInstance)
{
	HRSRC hRes;// ָ����Դ����Ϣ��ľ��
	DWORD dwResSize;// ��Դ��С
	HGLOBAL hGlobal;// ��������ɹ����򷵻�ֵ������Դ���������ݵľ��
	PVOID lpRes;	// ������ص���Դ���ã��򷵻�ֵ��ָ����Դ��һ���ֽڵ�ָ��
	HANDLE hFile;	// ��������ɹ����򷵻�ֵ��ָ���ļ����豸�������ܵ����ʼ��۵Ĵ򿪾��
	DWORD dwWritten;


	// Ѱ����Դ
	// FindResource: ȷ��ָ��ģ���о���ָ�����ͺ����Ƶ���Դ��λ��
	if (hRes = FindResource(_hInstance, TEXT("IDB_WINRESULT"), TEXT("DLLTYPE")))
	{
		// ��ȡ��Դ�ߴ� 
		// SizeofResource: ����ָ����Դ�Ĵ�С�����ֽ�Ϊ��λ��
		dwResSize = SizeofResource(_hInstance, hRes); 
		// װ����Դ
		// LoadResource: ���������ڻ�ȡָ���ڴ���ָ����Դ��һ���ֽڵ�ָ��ľ��
		if (hGlobal = LoadResource(_hInstance, hRes))
		{
			// LockResource: ����ָ���ڴ���ָ����Դ��ָ��
			if (lpRes = LockResource(hGlobal)) //������Դ
			{
				// ���ļ�д��
				// �������ߴ��ļ��� I/O �豸
				hFile = CreateFile(TEXT("05-01_winResult.dll"), GENERIC_WRITE, FILE_SHARE_READ,
					0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
				// ������д��ָ�����ļ�������/��� (I/O) �豸
				// dwWritten: ָ�������ָ�룬�ñ�������ʹ��ͬ�� hFile ����ʱд����ֽ���
				WriteFile(hFile, lpRes, dwResSize, &dwWritten, NULL);
				// �رմ򿪵Ķ�����
				CloseHandle(hFile);
			}
		}
	}
}




int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	HMODULE hRichEdit;

	hInstance = hInst;
	hRichEdit = LoadLibrary(TEXT("RichEd20.dll"));
	_createDll(hInstance);//��δ����DLL����ǰ���ͷŸ�DLL�ļ�
	DialogBoxParam(hInstance, MAKEINTRESOURCE(DLG_MAIN), NULL, _ProcDlgMain, (LPARAM)NULL);
	FreeLibrary(hRichEdit);
	return 0;
}