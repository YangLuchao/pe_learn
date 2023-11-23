searchFile.exe        显示c:\ql目录下所有文件的程序
checkRun.exe          模拟测试执行多个程序
multiProcess.exe      顺序执行多个EXE文件的程序


_host.asm             依次执行程序的后台调度程序
host.asm              宿主程序
bind.asm              捆绑程序

通过bind.exe对宿主程序host.exe进行捆绑，宿主程序执行捆绑文件释放和_host.exe程序。由_host.exe程序调度其他捆绑文件中EXE文件的顺序运行。



