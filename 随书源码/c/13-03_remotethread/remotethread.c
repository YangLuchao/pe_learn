//��ַ0x00400000
//release��
//��ֹ�Ż�
//����δʹ�õĺ���������
//���ð�ȫ��� (/GS-)
//
//��ע������е�����д�ɾֲ������������Ͳ���Ҫ�ض�λ��

#include <Windows.h>
#include<Richedit.h>
#include "resource.h"



HINSTANCE hInstance;


/*
��ȡkernel32.dll�Ļ���ַ
xp��KERNEL32Ϊ�ڶ�����
win7��KERNEL32Ϊ������
Ϊ��ʵ�ã����ñ��������Ƚϵ�������dll���ֵķ�ʽ
*/
DWORD _getKernelBase()
{
	DWORD dwPEB;
	DWORD dwLDR;
	DWORD dwInitList;
	DWORD dwDllBase;//��ǰ��ַ
	PIMAGE_DOS_HEADER pImageDosHeader;//ָ��DOSͷ��ָ��
	PIMAGE_NT_HEADERS pImageNtHeaders;//ָ��NTͷ��ָ��
	DWORD dwVirtualAddress;//������ƫ�Ƶ�ַ
	PIMAGE_EXPORT_DIRECTORY pImageExportDirectory;//ָ�򵼳����ָ��
	PTCHAR lpName;//ָ��dll���ֵ�ָ��
	TCHAR szkernel32[] = { 'K', 'E', 'R', 'N', 'E', 'L', '3', '2', '.', 'd', 'l', 'l', 0 };

	__asm
	{
		mov eax, FS:[0x30]//fs:[30h]ָ��PEB
			mov dwPEB, eax
	}

	dwLDR = *(PDWORD)(dwPEB + 0xc);//PEBƫ��0xc��LDRָ��
	dwInitList = *(PDWORD)(dwLDR + 0x1c);//LDRƫ��0x1c��ָ�� ���ճ�ʼ��˳������ �ĵ�һ��ģ��Ľṹ ��ָ��



	for (;
		dwDllBase = *(PDWORD)(dwInitList + 8);//�ṹƫ��0x8�����ģ���ַ
		dwInitList = *(PDWORD)dwInitList//�ṹƫ��0�������һģ��ṹ��ָ��
		)
	{
		pImageDosHeader = (PIMAGE_DOS_HEADER)dwDllBase;
		pImageNtHeaders = (PIMAGE_NT_HEADERS)(dwDllBase + pImageDosHeader->e_lfanew);
		dwVirtualAddress = pImageNtHeaders->OptionalHeader.DataDirectory[0].VirtualAddress;//������ƫ�� 
		pImageExportDirectory = (PIMAGE_EXPORT_DIRECTORY)(dwDllBase + dwVirtualAddress);//�������ַ
		lpName = (PTCHAR)(dwDllBase + pImageExportDirectory->Name);//dll����

		for (int i = 0; 1; ++i)//�ж��Ƿ�Ϊ��KERNEL32.dll��
		{
			if (lpName[i] != szkernel32[i])
			{
				break;
			}

			if (lpName[i] == 0)
			{
				return dwDllBase;
			}
		}
	}
	return 0;

}



/*
��ȡָ���ַ�����API�����ĵ��õ�ַ
��ڲ�����_hModuleΪ��̬���ӿ�Ļ�ַ
		   _lpApiΪAPI����������ַ
���ڲ����������������ַ�ռ��е���ʵ��ַ
*/
DWORD _getApi(DWORD _hModule, PTCHAR _lpApi)
{
	DWORD i;
	PIMAGE_DOS_HEADER pImageDosHeader;//ָ��DOSͷ��ָ��
	PIMAGE_NT_HEADERS pImageNtHeaders;//ָ��NTͷ��ָ��
	DWORD dwVirtualAddress;//������ƫ�Ƶ�ַ
	PIMAGE_EXPORT_DIRECTORY pImageExportDirectory;//ָ�򵼳����ָ��
	TCHAR ** lpAddressOfNames;
	PWORD lpAddressOfNameOrdinals;


	pImageDosHeader = (PIMAGE_DOS_HEADER)_hModule;
	pImageNtHeaders = (PIMAGE_NT_HEADERS)(_hModule + pImageDosHeader->e_lfanew);
	dwVirtualAddress = pImageNtHeaders->OptionalHeader.DataDirectory[0].VirtualAddress;//������ƫ�� 
	pImageExportDirectory = (PIMAGE_EXPORT_DIRECTORY)(_hModule + dwVirtualAddress);//�������ַ
	lpAddressOfNames = (TCHAR **)(_hModule + pImageExportDirectory->AddressOfNames);//�����ֵ��������б�
	for (i = 0; _hModule + lpAddressOfNames[i]; ++i)
	{
		for (int j = 0; 1; ++j)//�ж��Ƿ�Ϊ_lpApi
		{
			if (_lpApi[j] != (_hModule + lpAddressOfNames[i])[j])
			{
				break;
			}

			if (_lpApi[j] == 0)
			{
				lpAddressOfNameOrdinals = (PWORD)(_hModule + 
					pImageExportDirectory->AddressOfNameOrdinals);//�����ֵ������������б�

				return _hModule + ((PDWORD)(_hModule + pImageExportDirectory->AddressOfFunctions))
					[lpAddressOfNameOrdinals[i]];//���ݺ��������ҵ�������ַ
			}
		}
	}
	return 0;
}


/*
ִ��Զ���߳�
*/
void _remoteThread()
{
	DWORD hKernel32Base;// kernel32.dll��ַ
	PROC _getProcAddress;// getProcAddress������ַ
	PROC _loadLibrary;// loadLibrary������ַ
	HMODULE hUser32Base;// user32��ַ
	PROC _messageBox;// messageBox������ַ


	TCHAR szGetProcAddr[] = { 'G', 'e', 't', 'P', 'r', 'o', 'c', 'A', 'd', 'd', 'r', 'e', 's', 's' ,0};
	TCHAR szLoadLib[] = { 'L', 'o', 'a', 'd', 'L', 'i', 'b', 'r', 'a', 'r', 'y', 'A' ,0};
	TCHAR user32_DLL[] = { 'u', 's', 'e', 'r', '3', '2', '.', 'd', 'l', 'l' ,0};
	TCHAR szMessageBox[] = { 'M', 'e', 's', 's', 'a', 'g', 'e', 'B', 'o', 'x', 'A' ,0};
	TCHAR szText[] = { 'H', 'e', 'l', 'l', 'o', 'W', 'o', 'r', 'l', 'd', 'P', 'E' ,0};

	// ��ȡkernel32.dll�Ļ���ַ
	hKernel32Base = _getKernelBase();
	// �ӻ���ַ��������GetProcAddress��������ַ
	_getProcAddress = (PROC)_getApi(hKernel32Base, szGetProcAddr);
	// ʹ��GetProcAddress��������ַ
	// ����������������GetProcAddress���������LoadLibraryA����ַ
	_loadLibrary = (PROC)_getProcAddress(hKernel32Base, szLoadLib);
	// ʹ��LoadLibrary��ȡuser32.dll�Ļ���ַ
	hUser32Base = (HMODULE)_loadLibrary(user32_DLL);
	// ʹ��GetProcAddress��������ַ����ú���MessageBoxA����ַ
	_messageBox = (PROC)_getProcAddress(hUser32Base, szMessageBox);
	// ���ú���MessageBoxA
	_messageBox(NULL, szText, NULL, MB_OK);
}






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
��Զ���̴߳򵽽���PEInfo.exe��
���Է�������������PEInfo.exe
�����ó���,������һ���˵��ĵ�һ��
�ᷢ�������ϵ���HelloWorldPE�Ի���
*/
void _patchPEInfo()
{
	HWND phwnd;
	DWORD parent = 0;
	DWORD hProcessID;
	HANDLE hProcess;
	DWORD dwPatchDD = 1;
	LPVOID lpRemote;
	DWORD dwTemp;


	TCHAR strTitle[256];
	TCHAR szTitle[] = TEXT("PEInfo");
	TCHAR szErr1[] = TEXT("Error happend when openning.");
	TCHAR szErr2[] = TEXT("Error happend when virtualing.");



	//ͨ�������ý��̵�handle	
	phwnd = GetWindow(GetWindow(GetDesktopWindow(), GW_CHILD), GW_HWNDFIRST);
	if (!GetParent(phwnd))
	{
		parent = 1;
	}

	while (phwnd)
	{
		if (parent)
		{
			parent = 0;//��λ��־
			GetWindowText(phwnd, strTitle, sizeof(strTitle));//�õ����ڱ�������
			if (!lstrcmp(strTitle, szTitle))
			{
				break;
			}
		}

		//Ѱ��������ڵ���һ���ֵܴ���
		phwnd = GetWindow(phwnd, GW_HWNDNEXT);
		if (!GetParent(phwnd) && IsWindowVisible(phwnd))
		{
			parent = 1;
		}
	}


	GetWindowThreadProcessId(phwnd, &hProcessID);	//���ݴ��ھ����ȡ����ID
/*
HANDLE OpenProcess(
	DWORD dwDesiredAccess,	//����Ȩ��
	BOOL bInheritHandle,	//�̳б�־������������ӽ��̼̳У�������ΪTRUE
	DWORD dwProcessId		//���̺�
);
*/
	if (hProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, hProcessID))//�ҵ��Ľ��̾����hProcess��
	{
/*
LPVOID VirtualAllocEx(
	HANDLE hProcess,		//�����ڴ����ڵĽ��̾��
	LPVOID lpAddress,		//����ҳ����ڴ��ַ��NULL��ʾ�Զ�����
	SIZE_T dwSize,			//��������ڴ��С
	DWORD flAllocationType, //�ڴ��������
	DWORD flProtect			//������ҳ������,PAGE_EXECUTE_READWRITE �����ִ�еĶ�/д�ڴ�
);
*/
		if (lpRemote = VirtualAllocEx(hProcess, NULL, ((DWORD)_Init - (DWORD)_getKernelBase),
			MEM_COMMIT, PAGE_EXECUTE_READWRITE))//����ռ�
		{
/*
BOOL WriteProcessMemory(
	HANDLE hProcess,		//Զ�̽��̾��
	PVOID pvAddressRemote,	//Զ�̽��̵�ַVAֵ
	PVOID pvBufferLocal,	//������ݵĻ�����
	DWORD dwSize,			//��������С
	PDWORD pdwNumBytesRead	//��д���ֽ������Ƿ���ֵ
);
*/
			WriteProcessMemory(hProcess, lpRemote, _getKernelBase,
				((DWORD)_Init - (DWORD)_getKernelBase), &dwTemp);//д���̴߳���
			
/*
HANDLE CreateRemoteThread(
	HANDLE hProcess,							//Ŀ����̾��
	LPSECURITY_ATTRIBUTES lpThreadAttributes,	//��ȫ����
	SIZE_T dwStackSize,							//�߳�ջ��С
	LPTHREAD_START_ROUTINE lpStartAddress,		//�߳���ʼ��ַ
	LPVOID lpParameter,							//�������
	DWORD dwCreationFlags,						//������־��
	LPDWORD lpThreadId							//��������߳̾��
);
*/
			CreateRemoteThread(hProcess, NULL, 0, 
				// VA��ַ������Զ���̺߳�ֱ�ӿ�ʼִ��
				(LPTHREAD_START_ROUTINE)((DWORD)lpRemote + (DWORD)_remoteThread - (DWORD)_getKernelBase),
				0, 0, NULL);
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

		case IDM_OPEN:			
			_patchPEInfo();
			break;

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




int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	HMODULE hRichEdit;

	hInstance = hInst;
	hRichEdit = LoadLibrary(TEXT("RichEd20.dll"));
	DialogBoxParam(hInstance, MAKEINTRESOURCE(DLG_MAIN), NULL, _ProcDlgMain, (LPARAM)NULL);
	FreeLibrary(hRichEdit);
	return 0;
}