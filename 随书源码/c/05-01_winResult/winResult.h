#define EXPORT __declspec (dllexport)


EXPORT void AnimateOpen	(HWND hWin);
EXPORT void AnimateClose(HWND hWin);
EXPORT void FadeInOpen	(HWND hWin);
EXPORT void FadeOutClose(HWND hWin);