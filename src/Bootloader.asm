	org 0x7C00
	
	KERNELSEG = 0x1000
	use16
header:
	jmp _start
	nop
	nop
	nop
	nop
	nop
	nop
progstart:
_start:
	cli
	xor ax, ax
	mov ss, ax
	mov ds, ax
	mov es, ax
	mov sp, 0xFFFF
	sti 
	push dx    
	mov al, 3
	int 0x10
	mov ah, 2
	mov al, 10
	mov cx, 2
	cmp dl, 0xFF
	je from_floppy
	cmp dl, 0x80
	jge from_disk
	mov dl, 0x80
	jmp from_disk       
from_floppy:
	mov bp, 5
	jmp from_disk
check_if_repeat:
	sub bp, 1
	cmp bp, 0
	je spin
from_disk: 
	mov bx, KERNELSEG
	mov es, bx
	xor bx, bx
	int 0x13
	cmp dl, 0xFF
	je check_for_errors
check_for_errors:
	jnc done_with_disk
	cmp ah, 0
	je done_with_disk
	jmp spin 
done_with_disk:
	push 0x1000
	push 0
	pop ds
	pop ss
	push 0x1000
	pop es
	mov sp, 0x8000

	xor bx, bx
	xor dx, dx
	mov ah, 02h
	int 10h
	
	jmp KERNELSEG:0000
spin:
	hlt
inf:
	jmp inf

times 510-($ - $$) db 0
dw 0xAA55
