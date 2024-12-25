use16
header:
	blank:		times 8 nop
	sign:       db "COSA E", 0
	entryp:     dw progstart
	version:    dw 0x1
	memory_size:dw 0x1 ; size in sectors
	reserved:   db 0, 0, 0, 0, 0
	magic:		db 0xAA
	origin:		dw 0x2000

progstart: