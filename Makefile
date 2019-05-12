SOURCES = multiboot.S boot.S test.S testmsi.cc
OBJS = $(patsubst %.S,%.o,$(SOURCES))
QEMU ?= qemu-system-i386
MKFIFO = mkfifo
GREP = grep
CAT = cat

QEMU_CHARDEVS = \
	-chardev socket,id=qemu-monitor,host=localhost,port=7777,server,nowait,telnet \
	-mon qemu-monitor,mode=readline \
	-chardev file,path=debug.out,id=qemu-debug-out \
	-device isa-debugcon,chardev=qemu-debug-out

all: qemu-bmibug

clean:
	rm qemu-bmibug
	echo check rm $(OBJS)

.PHONY: all clean

qemu-bmibug: $(SOURCES) Makefile kernel.ld
	$(CXX) -o "$@" \
		-Wl,-Tkernel.ld \
		-Wl,-melf_i386 \
		-m32 \
		-ggdb3 -static -nostdlib \
		-ffreestanding -Og \
		$(SOURCES)

run: qemu-bmibug Makefile
	$(QEMU) -kernel qemu-bmibug -s -cpu max \
		-vga virtio \
		$(QEMU_CHARDEVS)
	$(GREP) 'Passed' debug.out && \
		printf '*** Passed\n' || \
		(printf 'XXX Failed!\n'; $(CAT) debug.out; exit 1)

run-kvm: qemu-bmibug Makefile
	$(QEMU) -kernel qemu-bmibug -s -cpu max \
		-enable-kvm -vga virtio \
		$(QEMU_CHARDEVS)
	$(GREP) 'Passed' debug.out && \
		printf '*** Passed\n' || \
		(printf 'XXX Failed!\n'; $(CAT) debug.out; exit 1)

debug: qemu-bmibug Makefile
	$(QEMU) -kernel qemu-bmibug -S -s -cpu max \
		-vga virtio \
		$(QEMU_CHARDEVS)

debug-kvm: qemu-bmibug Makefile
	$(QEMU) -kernel qemu-bmibug -S -s -cpu max \
		-enable-kvm \
		-vga virtio \
		$(QEMU_CHARDEVS)

attach-gdb:
	gdb qemu-bmibug \
		-iex 'target remote localhost:1234' \
		-ex 'hbreak _start'

.PHONY: run run-kvm debug debug-kvm attach-gdb
