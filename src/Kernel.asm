	KeyBoardBuffer = 0xE820
	SIZE_OF_OS = 4096
	START_OF_FS = (SIZE_OF_OS/512)+1
start:
	cli
	pop dx
	mov [es:disknum],dx
	lea bx, [int80]
	mov di, 0x80
	call set_int

	lea bx, [PIT_Handler]
	mov di, 0x08
	call set_int

	; init PIT
	mov al, 0x36
	out 43h, al

	mov ax, 11931
	out 40h, al
	mov al, ah
	out 40h, al

	call clear_scr
	call splash    
	jmp kernel_mainloop
set_int: ; DI = interrupt, BX = offset
	push ds
	mov ax, 0x0000
	mov ds, ax

	mov ax, bx
	imul di, 4

	mov [ds:di], ax
	mov [ds:di+2], cs
	pop ds
	ret
int80:
	cli
	cmp ah, 1
	je  .exit
	cmp ah, 2
	je  .puts
	cmp ah, 3
	je  .getc
	cmp ah, 0x40
	je  ._int
.end:
	sti
	iret
.exit:
	push 0
	pop ds
	push 0x1000
	pop es
	mov byte[dat.inapp], 0
	jmp kernel_mainloop
.puts:
	call puts
	jmp .end
.getc:
	call getc
	jmp .end
._int:
	call set_int
	jmp .end

PIT_Handler:
	cli
	push ax             ; Save registers that need to be preserved
	mov ax, 0x20
	out 20h, al
	pop ax

	cmp byte[dat.inapp], 1
	jne .exit

	push es
	push 0x1000
	pop es
	call clearBuffer
	
	mov di, dat.prompt
	call puts
	
	mov di, KeyBoardBuffer
	call gets

   call system
	pop es
.exit:
	sti
	iret

clear_scr:
	pusha
	mov ah, 0x00
	mov al, 0x03
	int 0x10
	mov ah, 09h
	mov cx, 1000h
	mov al, 20h

	mov bl, [es:dat.col]
	int 10h
	popa
	ret
splash:
	mov di, dat.desc
	call puts
	ret
putc:
	mov ah, 0eh
	int 10h
	ret
puts:
	mov al, [es:di]
	cmp al, 0
	jne .next
	ret
.next:
	call putc
	inc di
	jmp puts
getc:
	mov ah, 0
	int 16h
	ret
gets:
	push di
	push cx
	mov cx, [es:dat.kbd_b_l]
._loop:
	call getc
	call putc
	cmp al, 8
	je .backspace
	mov [es:di], al
	inc di
	cmp cx, 0
	je ._2
	dec cx
._:
	cmp al, 13
	jne ._loop
._2:
	mov al, 10
	int 10h
	pop cx
	pop di
	ret
.backspace:
	mov al, 20h
	call putc
	mov al, 8
	call putc
	dec di
	mov byte[es:di], 0
	jmp ._

; strcpy:
; ._loop:
	; mov al, [es:si]
	; mov [es:di], al
	; inc si
	; inc di
	; cmp al, 0
	; je .done
	; jmp ._loop
; .done:
	; ret

str_cmp:
	push di
._loop:
	mov al, [es:SI]
	mov bl, [es:DI]
	inc si
	inc di
	cmp al, 0
	je .eq 
	cmp al, bl
	jne .ne
	jmp ._loop
.ne:
	clc
	pop di
	ret
.eq:
	stc
	pop di
	ret

clearBuffer:
	push di
	push cx
	xor cx, cx
	mov cl, [es:dat.kbd_b_l]
	mov di, KeyBoardBuffer
._:
	mov byte[es:di], 0
	inc di
	loop ._
.exit:
	pop cx
	pop di
	ret

atoi:
	mov ax, 0              ; Set initial total to 0
	push bx
.convert:
	xor bx, bx
	mov bl, [es:di]   ; Get the current character
	test bl, bl           ; Check for \0
	je .done
	
	cmp bl, 48             ; Anything less than 0 is invalid
	jl .err
	
	cmp bl, 57             ; Anything greater than 9 is invalid
	jg .err
	
	sub bl, 48             ; Convert from ASCII to decimal 
	imul ax, 10            ; Multiply total by 10
	add ax, bx            ; Add current digit to total
	
	inc di                 ; Get the address of the next character
	jmp .convert

.err:
	pop bx
	stc
	ret
.done:
	pop bx
	clc
	ret                     ; Return total or error code

itoa:
	mov cx, 10          ; Set divisor to 10
	mov si, di          ; Save start position of output string
._loop:
	xor dx, dx          ; Clear dx
	div cx              ; Divide ax by 10
	add dl, '0'         ; Convert remainder to ASCII
	mov [es:di], dl        ; Store character
	inc di              ; Move to next position in string
	test ax, ax         ; Check if quotient is zero
	jnz ._loop
	mov byte [es:di], 0    ; Null-terminate the string
	call .reverse_string ; Reverse the string in place
	ret

.reverse_string:
	mov cx, di          ; cx = end position of string + 1
	dec cx              ; cx = end position of string
	sub cx, si          ; cx = length of string
	shr cx, 1           ; cx = length / 2 (number of swaps)
.reverse_loop:
	mov al, [es:si]        ; Load character from start
	mov bl, [es:di-1]      ; Load character from end
	mov [es:si], bl        ; Swap characters
	mov [es:di-1], al
	inc si              ; Move start position forward
	dec di              ; Move end position backward
	loop .reverse_loop   ; Repeat for the entire string
	ret

isplash:
	call splash
	jmp kernel_mainloop
ihelp:
	mov di, dat.hlptxt
	call puts
	jmp kernel_mainloop

irun:
	mov al, [es:KeyBoardBuffer+4] ; get drive
	mov dl, al
	sub dl, 'A'
	cmp dl, 1
	jg .err

	mov [es:dat.drive], dl

	; read header
	mov ah, 02h ; read function.
 	mov al, 1  ; sectors to read.
 	mov ch, 0   ; cylinder.
 	mov cl, 1   ; sector.
 	mov dh, 0   ; head.
 	mov bx, dat.temp
 	int 13h

	; parse header
	mov di, dat.sign
	mov si, dat.temp+8
	call str_cmp
	jc .is_cosa_exe
	jmp .err
.is_cosa_exe:
	mov dx, [es:dat.temp+7+8] ; entry
	cmp dx, 0x00
	je .err
	mov [es:dat.entryp], dx

	mov dx, [es:dat.temp+9+8] ; ver
	cmp dx, [es:dat.supver]
	jg .err
	mov [es:dat.vers], dx
	
	mov cx, [es:dat.temp+11+8] ; SIZE_OF_OS(sectors)
	cmp cx, 0x00
	je .err
	mov [es:dat.sz], cl

	mov al, [es:dat.temp+0x12+8]
	cmp al, 0xAA ; magic
	jne .err

	mov dx, [es:dat.temp+0x13+8] ; origin
	cmp dx, 0x2000
	jl .err1
.m0:
	mov [es:dat.origin], dx

	mov ah, 02h ; read function.
 	mov al, [es:dat.sz]  ; sectors to read.
 	mov ch, 0   ; cylinder.
 	mov cl, 1   ; sector.
 	mov dh, 0   ; head.
 	mov dl, [es:dat.drive]   ; drive.
 	mov bx, [es:dat.origin]
	mov es, bx
	xor bx, bx
 	int 13h

	mov bx, 0x1000
	mov es, bx

	mov bx, [es:dat.origin]
	mov es, bx
	mov bx, [es:dat.entryp]

	mov byte[dat.inapp], 1

	push cs
	push kernel_mainloop

	push es
	push bx
	retf
.err:
	mov bx, 0x1000
	mov es, bx
	mov bx, 0
	mov di, dat.rerr0
	call puts
	mov bx, 0x1000   
	mov es, bx
	mov bx, 0
	jmp kernel_mainloop
.err1:
	push es
	push 0x1000
	pop es
	mov di, dat.rerr1
	call puts
	pop es
	mov dx, 0x2000
	jmp .m0
icls:
	call clear_scr
	jmp kernel_mainloop

iPEEK:
	call clearBuffer
	mov di, KeyBoardBuffer
	call gets
	mov di, KeyBoardBuffer
	call atoi
	
	mov si, ax
	xor ax, ax
	mov al, [es:si]

	mov di, dat.temp
	call itoa
	mov di, dat.temp
	call puts
	jmp kernel_mainloop
iPOKE:
	jmp kernel_mainloop

system:
	mov si, dat.help
	call str_cmp
	jc ihelp

	mov si, dat.list
	call str_cmp
	jc _LIST

	mov si, dat.splash
	call str_cmp
	jc isplash

	; mov si, dat.disk
	; call str_cmp
	; jc idisk

	mov si, dat.cls
	call str_cmp
	jc icls

	mov si, dat.poke
	call str_cmp
	jc iPOKE

	mov si, dat.peek
	call str_cmp
	jc iPEEK

	mov si, dat.shutdown
	call str_cmp
	jc restart

	mov si, KeyBoardBuffer
	call _RUN_FILE
	ret

kernel_mainloop:
	sti
	mov di, KeyBoardBuffer
	call clearBuffer
	mov di, dat.prompt
	call puts
	
	mov di, KeyBoardBuffer ; gets restored, dont need to set again
	call gets

   call system
	jmp kernel_mainloop
restart:
	int 19h

	include "io.asm"

	disknum:    db 0
dat:
	.rerr0:		db "Unable to start program.", 10, 13, 0
	.rerr1:		db "Cant have same origin as kernel, moving to 0x2000", 10, 13, 0

	.hlptxt:		db "A List of commands for COSA.", 10, 13
					db "restart     |       restart the computer", 10, 13
					db "splash      |       display the splash screen", 10, 13
					db "help        |       show this list", 10, 13
					db "cls         |       clear screen", 10, 13
					db "RUN A       |       run code from Disk A", 10, 13
					db "RUN B       |       run code from Disk B", 10, 13
	.desc:		db "Computer Operating System A.", 10, 13, "Kernel Version 0.1 Revision 0", 10, 13, "(C) Joshua Farmer 2023", 10, 13, 0
	.prompt:		db "> ", 0
	.splash:		db "splash", 0
	.help:		db "help", 0
	.cls:			db "cls", 0

	.list:		db "Ls", 0
	.run:			db "RUN", 0
	
	.poke:		db "poke", 0
	.peek:		db "peek", 0

	.shutdown:	db "restart", 0
	.kbd_b_l:	db 64
	.col:			db 15
	
	; programs
	.sign:		db "COSA E", 0
	.supver:		dw 0x1
	.vers:		dw 0x0
	.sz:			db 0x0
	.origin:		dw 0x0
	.entryp:		dw 0x0000
	.drive:		db 0x01

	.inapp:		db 0x00
	
	; other
	.temp:		times 1024 db 0

	times SIZE_OF_OS-($-$$) nop