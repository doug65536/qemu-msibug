// This file is part of qemu-bmibug.
//
//    qemu-bmibug is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    qemu-bmibug is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with Foobar.  If not, see <https://www.gnu.org/licenses/>.
//
// Copyright 2019 Doug Gale


.code32
.section .text

.global _start
_start:
	// Setup stack ASAP
	mov $stack_end,%esp

	// Load GDT ASAP
	lgdt gdtr
	ljmp $0x8,$.Lloadcs
.Lloadcs:
	mov $0x10,%eax
	mov %eax,%ds
	mov %eax,%es
	mov %eax,%fs
	mov %eax,%gs
	mov %eax,%ss

	// Fixup the IDT to the ridiculous i386 layout
	xor %ebx,%ebx
.Lnextidt:
	mov idt_00(,%ebx,8),%eax
	shr $16,%eax
	movw $0x8,idt_00+2(,%ebx,8)
	movw $0x8E00,idt_00+4(,%ebx,8)
	movw %ax,idt_00+6(,%ebx,8)
	add $1,%ebx
	cmp $32,%ebx
	jl .Lnextidt

	// Load IDTR
	push $idt_00
	push $((32 * 8 - 1) << 16)
	lidt 2(%esp)
	add $8,%esp

	jmp start_test

.section .data
.align 16
idt_00: .int 0, 0
idt_01: .int 0, 0
idt_02: .int 0, 0
idt_03: .int 0, 0
idt_04: .int 0, 0
idt_05: .int 0, 0
idt_06: .int 0, 0
idt_07: .int 0, 0
idt_08: .int 0, 0
idt_09: .int 0, 0
idt_0A: .int 0, 0
idt_0B: .int 0, 0
idt_0C: .int 0, 0
idt_0D: .int 0, 0
idt_0E: .int 0, 0
idt_0F: .int 0, 0
idt_10: .int 0, 0
idt_11: .int 0, 0
idt_12: .int 0, 0
idt_13: .int 0, 0
idt_14: .int 0, 0
idt_15: .int 0, 0
idt_16: .int 0, 0
idt_17: .int 0, 0
idt_18: .int 0, 0
idt_19: .int 0, 0
idt_1A: .int 0, 0
idt_1B: .int 0, 0
idt_1C: .int 0, 0
idt_1D: .int 0, 0
idt_1E: .int 0, 0
idt_1F: .int 0, 0

gdt:
	.short 0
gdtr:
	.short gdt_en - gdt - 1
	.int gdt

	// Code
	.short 0xFFFF
	.short 0
	.byte 0
	.byte 0x9b
	.byte 0xCF
	.byte 0

	// Data
	.short 0xFFFF
	.short 0
	.byte 0
	.byte 0x93
	.byte 0xCF
	.byte 0

gdt_en:

.section .bss
.align 16
stack: .space 65536
stack_end:
