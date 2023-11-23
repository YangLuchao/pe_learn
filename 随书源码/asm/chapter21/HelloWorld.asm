;------------------------
; 加密压缩算法
; 戚利
; 2006.2.28
;------------------------
    .386
    .model flat,stdcall
    option casemap:none

include    windows.inc
include    user32.inc
includelib user32.lib
include    kernel32.inc
includelib kernel32.lib

;数据段
    .data
szText     db  'encrypted complete!',0
szSrc      db  13h,15h,0A0h,00h,17h,01h,00h,0ffh
szDst      db  00h,00h,00h,00h,00h,00h,00h,00h

;代码段
    .code
jmp start


EncryptionTable db 256 dup(0),0


;-----------------------------------------------------
; 产生范围从 _dwMin 到  _dwMax 的随机数过程
; 传入参数： _dwMin  = 下限， _dwMax = 上限
; 返回参数： eax = Rand_Number
; 所用公式： Rand_Number = (Rand_Seed * X + Y) mod Z
; 补充说明： (1)本例中用 GetTickCount 
;                来取得随机数种子，在实际应用中，可用
;                别的方法代替。
;           (2)要产生随机数，X和Y其中之一必须是素数，
;                所以 X = 23, Y = 7 （可用别的素数代替）
;--------------------------------------------------------
_getRandom proc _dwMin:dword, _dwMax:dword
  local @dwRet:dword
  pushad

  ; 取得随机数种子，当然，可用别的方法代替

  invoke GetTickCount
  mov ecx, 19    ; X = ecx = 19
  mul ecx    ; eax = eax * X
  add eax, 37    ; eax = eax + Y （Y = 37）
  mov ecx, _dwMax   ; ecx = 上限
  sub ecx, _dwMin   ; ecx = 上限 - 下限
  inc ecx    ; Z = ecx + 1 （得到了范围）
  xor edx, edx    ; edx = 0
  div ecx    ; eax = eax mod Z （余数在edx里面）
  add edx,_dwMin
  mov @dwRet, edx
  popad
  mov eax, @dwRet   ; eax = Rand_Number
  ret
_getRandom endp

_isExists proc _byte
  local @ret
  pushad
  mov esi,offset EncryptionTable
  mov ecx,0
  .while TRUE
    mov al,byte ptr [esi]
    .if al==0
      mov @ret,FALSE
      .break
    .endif
    mov ebx,_byte
    .if al==bl
      mov @ret,TRUE
      .break
    .endif

    inc esi
    inc ecx
    .if ecx==0ffh
      mov @ret,FALSE
      .break
    .endif
  .endw
  popad
  mov eax,@ret
  ret
_isExists endp

;---------------
; 获取一个可用字节
;---------------
_getAByte  proc
  local @ret

  pushad
loc1:
  ; 取随机数
  invoke _getRandom,1,255
  mov @ret,eax

  ; 判断随机数是否在基表中
  invoke _isExists,eax
  .if eax
    jmp loc1
  .endif
  popad
  mov eax,@ret
  ret
_getAByte  endp


;-------------------------------
; 创建加密用的基表
;-------------------------------
_encrptAlg proc
  local @temp
  local @dwCount
  pushad

  ;生成加密基表
  mov @dwCount,0
  mov edi,offset EncryptionTable
  .while TRUE 
     invoke _getAByte
     mov byte ptr [edi],al
     inc edi
     inc @dwCount
     .break .if @dwCount==0ffh
  .endw
  popad
  ret
_encrptAlg endp


;-------------------------------
; 加密算法，可逆算法，字节数不变
; 入口参数：
;   _src:要加密的字节码起始地址
;   _dst:生成加密后的字节码起始地址
;   _size:要加密的字节码的数量
;-------------------------------
_encrptIt  proc _src,_dst,_size
  local @ret
  
  pushad
  ;开始按照基表对字节进行加密
  mov esi,_src
  mov edi,_dst
  .while TRUE
   mov al,byte ptr [esi]
   xor ebx,ebx
   mov bl,al
   mov al,byte ptr EncryptionTable[ebx]
   mov byte ptr [edi],al

   inc esi
   inc edi
   dec _size
   .break .if _size==0
  .endw
  popad
  ret
_encrptIt endp

start:
    invoke _encrptAlg
    invoke _encrptIt,addr szSrc,addr szDst,8
    nop
    invoke MessageBox,NULL,offset szText,NULL,MB_OK
    invoke ExitProcess,NULL
    end start
