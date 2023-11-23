patch1.exe   补丁程序，无导入表，无资源表，无需修正的重定位代码，无全局变量，无数据段
bind.exe     为PE打补丁的程序
bind1.exe    改进以后的为PE打补丁的程序

使用程序bind.exe打补丁：
patch1_helloworld  补丁程序为patch1，目标PE为helloworld
patch1_winword  补丁程序为patch1，目标PE为WinWord


使用程序bind1.exe打补丁
patch1_helloworld1.exe  补丁程序为patch1，目标PE为helloworld
patch1_notepad1.exe    补丁程序为patch1，目标PE为notepad
