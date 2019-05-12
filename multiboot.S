// This file is part of qemu-msibug.
//
//    qemu-msibug is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    qemu-msibug is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with Foobar.  If not, see <https://www.gnu.org/licenses/>.
//
// Copyright 2019 Doug Gale

.section .head

multiboot_st:
.int 0x1BADB002
.int 0x10000
.int -(0x10000+0x1BADB002)
// Load address
.int __load_st
.int __load_st
.int __load_en
.int __bss_en
.int _start
// mode
.int 0
// width
.int 0
// height
.int 0
// depth
.int 0
