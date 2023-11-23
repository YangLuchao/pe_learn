patch.exe 是要打的补丁
bind.exe 是打补丁用的程序

用bind.exe对notepad.exe打补丁，最终生成patch_notepad.exe

第一次运行patch_notepad.exe，因为校验和未写入，所以会显示病毒提示，提示完成后会打开与记事本程序一样的界面，此时的病毒提示是错误的。

将校验和0F34Bh手动写入patch_notepad.exe文件PE头部4CH处。并更改文件名为virNote.exe
再次运行virNote.exe，此时不会有任何提示。我们的病毒提示器就算完成了
将virNote.exe拷贝到c:\windows目录中，提示器就处于工作状态了。


一旦哪天PE文件病毒侵犯了我们的电脑，提示器会再次弹出提示窗口，此时虽无法杜绝病毒的运行，但可以明确告诉用户您的电脑受到PE病毒的攻击了。
