	define FILENAME "Hello"
	define FILENAMEL 5
	include "headers/header_v2.asm"

start:
	mov ah, 2
	mov di, msg
	int 0x80
	retf
msg:
	db "Hellorld!", 10, 13, 0

times 512-($-$$) db 0
end_of_prog:
