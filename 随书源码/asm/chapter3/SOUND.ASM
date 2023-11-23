code      segment
main      proc   far
          assume cs:code
          org 100h
start:    mov cx,50d
new_shot: push cx
          call shoot
          mov cx,0ffffh
silent:   loop silent
          pop cx
          loop new_shot
          mov al,48h
          out 61h,al
          mov ah,4ch
          int 21h
main      endp
shoot     proc  near
          mov dx,140h
          mov bx,20h
          in al,61h
          and al,11111100b
sound:    xor al,2
          out 61h,al
          add dx,9248h
          mov cl,3
          ror dx,cl
          mov cx,dx
          and cx,1ffh
          or cx,10
wait1:
          loop wait1
          dec bx
          jnz sound
          and al,11111100b
          out 61h,al
          ret
shoot     endp
code      ends
          end start

