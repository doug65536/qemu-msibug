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

.section .rodata
pass_txt:
	.asciz "Passed"

fail_txt:
	.asciz "FAILED!"

.section .text

.global start_test
start_test:
	// Hardcoded to walk PCI bus and find virtio-vga with MSI or MSIX
	// fail the test if no MSI or MSI-X found
	and $-16,%esp
	call test_msi
	test %eax,%eax
	jz fail
	jmp pass

.global fail
fail:
	mov $fail_txt,%esi
	jmp .Lexit_with_message

	// Passed
.global pass
pass:
	// Write '1' to port e9
	mov $pass_txt,%esi

.Lexit_with_message:
	mov (%esi),%al
	test %al,%al
	jz .Lpoweroff
	out %al,$0xE9
	add $1,%esi
	jmp .Lexit_with_message

.Lfail:
	// Write '0' to port e9
	mov $0x30,%al
	out %al,$0xE9

.Lpoweroff:
	// Write newline to port e9
	mov $0xA,%al
	out %al,$0xE9

.Lpoweroff_loop:
	// QEMU ACPI poweroff
	mov $0x604,%edx
	mov $0x2000,%eax
	out %ax,%dx
	hlt
	jmp .Lpoweroff_loop
