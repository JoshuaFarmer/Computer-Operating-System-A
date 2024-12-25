	; Improved for Simple FS
	use16
headerv2:
	sign:       db "COSA E", 0 ; executable, else just load data
	entryp:     dw progstart
	version:    dw 0x02
	memory_size:dw (end_of_prog / 512)
	reserved:   db 0, 0, 0, 0, 0
	magic:		db 0xAA
	origin:		dw 0x2000
	namel:      db FILENAMEL
	name:       db FILENAME
progstart: