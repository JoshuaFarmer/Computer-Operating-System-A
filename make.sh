gcc "FormImage.c" -o "FormImage" -Wall -Wextra -Werror

fasm "src/Bootloader.asm" "bin/Bootloader.bin"
fasm "src/Kernel.asm" "bin/Kernel.bin"

cat "bin/Bootloader.bin" "bin/Kernel.bin" > "bin/COSA.bin"

cd software
fasm "headers/header_v1.asm" "headers/header_v1.bin"
fasm "default.asm" "default.bin"
fasm "hellorld.asm" "hellorld.bin"
cd ..

./FormImage.exe Bin/COSA.img Bin/COSA.bin 4096 Software/Default.bin Software/Hellorld.bin
