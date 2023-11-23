#include <windows.h>
#include <Richedit.h>
#include "resource.h"


HINSTANCE hInstance;

DWORD dwStop;
HWND hWinEdit;	//���ı�����


/*
��ʼ�����ڳ���
*/
void _Init(HWND hWinMain)
{
	HICON hIcon;
	CHARFORMAT stCf;
	TCHAR szFont[] = TEXT("����");


	hWinEdit = GetDlgItem(hWinMain, IDC_INFO);
	hIcon = LoadIcon(hInstance, MAKEINTRESOURCE(ICO_MAIN));
	SendMessage(hWinMain, WM_SETICON, ICON_BIG, (LPARAM)hIcon);//Ϊ��������ͼ��
	SendMessage(hWinEdit, EM_SETTEXTMODE, TM_PLAINTEXT, 0);//���ñ༭�ؼ�

	RtlZeroMemory(&stCf, sizeof(stCf));
	stCf.cbSize = sizeof(stCf);
	stCf.yHeight = 10 * 20;
	stCf.dwMask = CFM_FACE | CFM_SIZE | CFM_BOLD;
	lstrcpy(stCf.szFaceName, szFont);
	SendMessage(hWinEdit, EM_SETCHARFORMAT, 0, (LPARAM)&stCf);
	SendMessage(hWinEdit, EM_EXLIMITTEXT, 0, -1);
}


/*
���ı�����׷���ı�
*/
void _appendInfo(TCHAR * _lpsz)
{
	CHARRANGE stCR;

	stCR.cpMin = GetWindowTextLength(hWinEdit);
	stCR.cpMax = GetWindowTextLength(hWinEdit);
	SendMessage(hWinEdit, EM_EXSETSEL, 0, (LPARAM)&stCR); //��������ƶ������
	SendMessage(hWinEdit, EM_REPLACESEL, FALSE, (LPARAM)_lpsz);
}



/*
��PE�ļ�������
*/
void _openFile(HWND hWinMain)
{
	OPENFILENAME stOF;
	HANDLE hFile, hMapFile;
	DWORD totalSize;		//�ļ���С
	LPVOID lpMemory;		//�ڴ�ӳ���ļ����ڴ����ʼλ��

	TCHAR szFileName[MAX_PATH] = {0};	//Ҫ�򿪵��ļ�·����������
	TCHAR bufTemp1[10];					//ÿ���ַ���ʮ�������ֽ���
	TCHAR bufTemp2[20];					//��һ��
	TCHAR lpServicesBuffer[100];		//һ�е���������
	TCHAR bufDisplay[50];				//������ASCII���ַ�
	DWORD dwCount;						//��������16�����¼�
	DWORD dwCount1;						//��ַ˳��
	DWORD dwBlanks;						//���һ�пո���

	TCHAR szExtPe[] = TEXT("PE Files\0*.exe;*.dll;*.scr;*.fon;*.drv\0All Files(*.*)\0*.*\0\0"); 
	
	// ��������ڴ�
	RtlZeroMemory(&stOF, sizeof(stOF));
	stOF.lStructSize = sizeof(stOF);
	stOF.hwndOwner = hWinMain;
	stOF.lpstrFilter = szExtPe;
	stOF.lpstrFile = szFileName;
	stOF.nMaxFile = MAX_PATH;
	stOF.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST;
	if (GetOpenFileName(&stOF))		//���û�ѡ��򿪵��ļ�
	{
		// �����ļ����
		hFile = CreateFile(szFileName, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE,
			NULL, OPEN_EXISTING, FILE_ATTRIBUTE_ARCHIVE, NULL);
		// �ж��ļ��Ƿ�Ƿ�
		if (hFile != INVALID_HANDLE_VALUE)
		{
			totalSize = GetFileSize(hFile, NULL);//��ȡ�ļ���С
			if (totalSize)
			{
				// �����ڴ�ӳ��
				hMapFile = CreateFileMapping(hFile, NULL, PAGE_READONLY, 0, 0, NULL);//�ڴ�ӳ���ļ�
				if (hMapFile)
				{
					// ��ȡӳ����ʼλ��
					lpMemory = MapViewOfFile(hMapFile, FILE_MAP_READ, 0, 0, 0);//����ļ����ڴ��ӳ����ʼλ��
					if (lpMemory)
					{
						//��ʼ�����ļ�

						//��������ʼ��
						RtlZeroMemory(bufTemp1, 10);
						RtlZeroMemory(bufTemp2, 20);
						RtlZeroMemory(lpServicesBuffer, 100);
						RtlZeroMemory(bufDisplay, 50);

						dwCount = 1;

						//����һ��д��lpServicesBuffer
						dwCount1 = 0;
						wsprintf(bufTemp2, TEXT("%08x  "), dwCount1);
						lstrcat(lpServicesBuffer, bufTemp2);
					
						dwBlanks = (16 - totalSize % 16) * 3;//�����һ�еĿո���

						while (TRUE)
						{
							if (totalSize == 0)//���һ��
							{
								while (dwBlanks)//���ո�
								{
									lstrcat(lpServicesBuffer, TEXT(" "));
									--dwBlanks;
								}
							
								lstrcat(lpServicesBuffer, TEXT("  "));//�ڶ�����������м�Ŀո�							
								lstrcat(lpServicesBuffer, bufDisplay);//����������							
								lstrcat(lpServicesBuffer, TEXT("\n"));//�س����з���
								break;
							}

							//����ɿ�����ʾ��ascii����,д������е�ֵ
							if (*(TCHAR *)lpMemory > 0x20 && *(TCHAR *)lpMemory < 0x7e)
							{
								bufDisplay[dwCount-1] = *(TCHAR *)lpMemory;
							}
							else
							{
								bufDisplay[dwCount-1] = 0x2e;//�������ASCII��ֵ������ʾ��.��
							}
							
							wsprintf(bufTemp1, TEXT("%02X "), *(TBYTE *)lpMemory);//�ֽڵ�ʮ�������ַ�����@bufTemp1��							
							lstrcat(lpServicesBuffer, bufTemp1);//���ڶ���д��lpServicesBuffer

							if (dwCount == 16)//�ѵ�16���ֽڣ�
							{
								lstrcat(lpServicesBuffer, TEXT("  "));//�ڶ�����������м�Ŀո�
								lstrcat(lpServicesBuffer, bufDisplay);//��ʾ�������ַ� 
								lstrcat(lpServicesBuffer, TEXT("\n"));//�س�����

								_appendInfo(lpServicesBuffer);//д������
								RtlZeroMemory(lpServicesBuffer, 100);

								if (dwStop == 1)
								{
									break;
								}

								wsprintf(bufTemp2, TEXT("%08X  "), (++dwCount1) * 16); // ��ʾ��һ�еĵ�ַ
								lstrcat(lpServicesBuffer, bufTemp2);

								dwCount = 0;
								RtlZeroMemory(bufDisplay, 50);
							}
							--totalSize;
							++dwCount;
							++(TCHAR *)lpMemory;

						}

						_appendInfo(lpServicesBuffer); //������һ��
						// ж�ؾ���
						UnmapViewOfFile(lpMemory);
					}
					// �رվ���
					CloseHandle(hMapFile);
				}
			}
			// �ر��ļ�
			CloseHandle(hFile);
		}
	}
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
		_Init(hWnd);
		break;

	case WM_COMMAND:			//�˵�
		switch (LOWORD(wParam))
		{
		case IDM_EXIT:			//�˳�
			EndDialog(hWnd, 0);
			break;

		case IDM_OPEN:			//���ļ�
			dwStop = 0;
			// �����̣߳�ִ��openfile����
			CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)_openFile, hWnd, 0, NULL);
			break;
		
		case IDM_1:
			dwStop = 1;
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
	HMODULE hRichEdit;

	hInstance = hInst;
	// ���ظ��ı�����
	hRichEdit = LoadLibrary(TEXT("RichEd20.dll"));
	// ���ô��ں���չʾ����
	DialogBoxParam(hInstance, MAKEINTRESOURCE(DLG_MAIN), NULL, _ProcDlgMain, (LPARAM)NULL);
	FreeLibrary(hRichEdit);
	return 0;
}