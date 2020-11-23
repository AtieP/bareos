org 0x7c00
bits 16
cpu 8086

main:
	cli

	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7c00
	mov bp, sp

	test al, 0x70
	je read_sectors

	mov al, 0x80 ; Reject floppy, embrace hard disk

read_sectors:
	; Load 512-byte kernel right after the bootloader
	mov ah, 0x41
	mov bx, 0x55AA
	int 0x13
	jc disk_error
	cmp bx, 0xAA55
	jne disk_error

	; Nice, running in an 386+
	cpu 386

	; Now load
	mov ax, (2 << 8) | 1 ; AH = 0x02, AL = 0x01
	mov bx, eof
	mov cx, 0x02
	xor dh, dh
	int 0x13
	jc disk_error

	test ah, ah
	jnz disk_error

	cmp al, 1
	jne disk_error

enable_a20:
	; Enable A20 gate
	call ps2_wait_write
	mov al, 0xAD
	out 0x64, al

	call ps2_wait_write
	mov al, 0xD0
	out 0x64, al

	call ps2_wait_read
	in al, 0x60
	mov bl, al

	call ps2_wait_write
	mov al, 0xD1
	out 0x64, al

	call ps2_wait_write
	mov al, bl
	or al, 2
	out 0x60, al

	call ps2_wait_write
	mov al, 0xAE
	out 0x64, al

load_gdt:
	cli
	lgdt [gdt.descriptor]

set_protected_bit:
	mov eax, cr0
	or eax, 1
	mov cr0, eax
	jmp code_segment:protected_mode

disk_error:
	mov si, .string
	call print_string
	jmp restart

.string: db "Disk error, press any key to restart...",0x00

; ------------------
; PS/2 functions
; ------------------
ps2_wait_read:
	push ax

.check:
	in al, 0x64
	test al, 1
	jz .check
	pop ax
	ret

ps2_wait_write:
	push ax
.check:
	in al, 0x64
	test al, 2
	jnz .check
	pop ax
	ret

; ------------------
; Miscelaneous functions
; ------------------
print_string:
	mov ah, 0x0e

.print_loop:
	lodsb
	test al, al
	jz .end
	int 0x10
	jmp .print_loop

.end:
	ret

restart:
	xor ah, ah
	int 0x16

.send_byte:
	call ps2_wait_write
	mov al, 0xFE
	out 0x64, al
	jmp .send_byte

; ------------------
; GDT
; ------------------
gdt:

.null:
	dq 0x0

.code:
	dw 0xffff
	dw 0x0000
	db 0x00
	db 10011010b
	db 11001111b
	db 0x00

.data:
	dw 0xffff
	dw 0x0000
	db 0x00
	db 10010010b
	db 11001111b
	db 0x00

.end:

.descriptor:
	dw .end - gdt - 1
	dd gdt

code_segment equ gdt.code - gdt
data_segment equ gdt.data - gdt

; This code is running in protected mode
bits 32
protected_mode:
	; Reload segments
	mov ax, data_segment
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov fs, ax
	mov gs, ax
	jmp 0x7e00

times 510 - ($ - $$) db 0x00
dw 0xAA55

eof:
incbin "kernel.bin"

times (512 - (($ - $$ + 0x7c00) & 511) + 1) / 2 db 0x00 ; Pad (thanks midn)
