	include "headers/header_v2.asm"

start:
	mov ah, 2
	mov di, msg
	int 0x80

	mov ah, 1
	int 0x80
	retf
msg:
	db "Hello, World!", 10, 13, 0

times 512-($-$$) db 0
end_of_prog:
