#include <stdint.h>

void puts(const char *string);

uint16_t *vga_buffer = (uint16_t *) 0xb8000;
uint16_t vga_index = 0;

void kmain() {
	puts("Hi!");
	for (;;) {}
}

void puts(const char *string) {
	while (*string) {
		vga_buffer[vga_index] = (uint16_t) *string | (uint16_t) 0x02 << 8;
		vga_index++;
		string++;
	}
}
