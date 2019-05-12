#include <stdint.h>

#define EXPORT
#define assert(...) ((void)0)
#define PCI_ADDR    0xCF8
#define PCI_DATA    0xCFC

typedef uintptr_t size_t;
#define _always_inline inline __attribute__((__always_inline__))

typedef uint16_t ioport_t;

static _always_inline uint8_t inb(ioport_t port)
{
    uint8_t result;
    __asm__ __volatile__ (
        "inb %w[port],%b[result]\n\t"
        : [result] "=a" (result)
        : [port] "Nd" (port)
    );
    return result;
}

static _always_inline uint16_t inw(ioport_t port)
{
    uint16_t result;
    __asm__ __volatile__ (
        "inw %w[port],%w[result]"
        : [result] "=a" (result)
        : [port] "Nd" (port)
    );
    return result;
}

static _always_inline uint32_t ind(ioport_t port)
{
    uint32_t result;
    __asm__ __volatile__ (
        "inl %w[port],%k[result]"
        : [result] "=a" (result)
        : [port] "Nd" (port)
    );
    return result;
}

static _always_inline void outb(ioport_t port, uint8_t value)
{
    __asm__ __volatile__ (
        "outb %b[value],%w[port]\n\t"
        :
        : [value] "a" (value)
        , [port] "Nd" (port)
    );
}

static _always_inline void outw(ioport_t port, uint16_t value)
{
    __asm__ __volatile__ (
        "outw %w[value],%w[port]\n\t"
        :
        : [value] "a" (value)
        , [port] "Nd" (port)
    );
}

static _always_inline void outd(ioport_t port, uint32_t value)
{
    __asm__ __volatile__ (
        "outl %k[value],%w[port]\n\t"
        :
        : [value] "a" (value)
        , [port] "Nd" (port)
    );
}

//
// Block I/O

static _always_inline void insb(ioport_t port, void *values, intptr_t count)
{
    __asm__ __volatile__ (
        "rep insb\n\t"
        : [value] "+D" (values)
        , [count] "+c" (count)
        : [port] "d" (port)
        : "memory"
    );
}

static _always_inline void insw(ioport_t port, void *values, intptr_t count)
{
    __asm__ __volatile__ (
        "rep insw\n\t"
        : [value] "+D" (values)
        , [count] "+c" (count)
        : [port] "d" (port)
        : "memory"
    );
}

static _always_inline void insd(ioport_t port, void *values, intptr_t count)
{
    __asm__ __volatile__ (
        "rep insl\n\t"
        : [value] "+D" (values)
        , [count] "+c" (count)
        : [port] "d" (port)
        : "memory"
    );
}

static _always_inline void outsb(
        ioport_t port, void const *values, size_t count)
{
    __asm__ __volatile__ (
        "rep outsb\n\t"
        : "+S" (values)
        , "+c" (count)
        : "d" (port)
        : "memory"
    );
}

static _always_inline void outsw(
        ioport_t port, void const *values, size_t count)
{
    __asm__ __volatile__ (
        "rep outsw\n\t"
        : "+S" (values)
        , "+c" (count)
        : "d" (port)
        : "memory"
    );
}

static _always_inline void outsd(
        ioport_t port, void const *values, size_t count)
{
    __asm__ __volatile__ (
        "rep outsl\n\t"
        : "+S" (values)
        , "+c" (count)
        : "d" (port)
        : "memory"
    );
}

template<int size>
struct io_helper
{
};

template<>
struct io_helper<1> {
    typedef uint8_t value_type;

    static _always_inline value_type inp(ioport_t port)
    {
        return inb(port);
    }

    static _always_inline void outp(ioport_t port, value_type val)
    {
        return outb(port, val);
    }

    static _always_inline void ins(
            ioport_t port, void *values, size_t count)
    {
        insb(port, values, count);
    }

    static _always_inline void outs(
            ioport_t port, void *values, size_t count)
    {
        outsb(port, values, count);
    }
};

template<>
struct io_helper<2>
{
    typedef uint16_t value_type;

    static _always_inline value_type inp(ioport_t port)
    {
        return inw(port);
    }

    static _always_inline void outp(ioport_t port, value_type val)
    {
        return outw(port, val);
    }

    static _always_inline void ins(
            ioport_t port, void *values, size_t count)
    {
        insw(port, values, count);
    }

    static _always_inline void outs(
            ioport_t port, void const *values, size_t count)
    {
        outsw(port, values, count);
    }
};

template<>
struct io_helper<4>
{
    typedef uint32_t value_type;

    static _always_inline value_type inp(ioport_t port)
    {
        return ind(port);
    }

    static _always_inline void outp(ioport_t port, value_type val)
    {
        return outd(port, val);
    }

    static _always_inline void ins(
            ioport_t port, void *values, size_t count)
    {
        insd(port, values, count);
    }

    static _always_inline void outs(
            ioport_t port, void const *values, size_t count)
    {
        outsd(port, values, count);
    }
};

struct pci_addr_t {
    // Legacy PCI supports 256 busses, 32 slots, 8 functions, and 64 dwords
    // PCIe supports 16777216 busses, 32 slots, 8 functions, 1024 dwords
    // PCIe organizes the busses into up to 65536 segments of 256 busses

    //        43       28 27   20 19  15 14  12 11       2 1  0
    //       +-----------+-------+------+------+----------+----+
    //  PCIe |  segment  |  bus  | slot | func |   dword  |byte|
    //       +-----------+-------+------+------+----------+----+
    //            16         8       5      3       10       2
    //
    //                    27   20 19  15 14  12 .. 7     2 1  0
    //                   +-------+------+------+--+-------+----+
    //  PCI              |  bus  | slot | func |xx| dword |byte|
    //                   +-------+------+------+--+-------+----+
    //                       8       5      3       10       2
    //
    //                        31       16 15    8 7    3 2    0
    //                       +-----------+-------+------+------+
    //  addr                 |  segment  |  bus  | slot | func |
    //                       +-----------+-------+------+------+
    //                            16         8       5      3

    pci_addr_t();
    pci_addr_t(int seg, int bus, int slot, int func);
    int bus() const;
    int slot() const;
    int func() const;

    // Returns true if segment is zero
    bool is_legacy() const;
    uint64_t get_addr() const;

private:
    uint32_t addr;
};

size_t pioofs(pci_addr_t addr, size_t offset)
{
    return (1 << 31) |
            (addr.bus() << 16) |
            (addr.slot() << 11) |
            (addr.func() << 8) |
            (offset & -4);
}

EXPORT pci_addr_t::pci_addr_t()
    : addr(0)
{
}

EXPORT pci_addr_t::pci_addr_t(int seg, int bus, int slot, int func)
    : addr((uint32_t(seg) << 16) | (bus << 8) | (slot << 3) | (func))
{
    assert(seg >= 0);
    assert(seg < 65536);
    assert(bus >= 0);
    assert(bus < 256);
    assert(slot >= 0);
    assert(slot < 32);
    assert(func >= 0);
    assert(func < 8);
}

EXPORT int pci_addr_t::bus() const
{
    return (addr >> 8) & 0xFF;
}

EXPORT int pci_addr_t::slot() const
{
    return (addr >> 3) & 0x1F;
}

EXPORT int pci_addr_t::func() const
{
    return addr & 0x7;
}

EXPORT bool pci_addr_t::is_legacy() const
{
    return (addr < 65536);
}

EXPORT uint64_t pci_addr_t::get_addr() const
{
    return addr << 12;
}

uint32_t pci_config_read(pci_addr_t addr, size_t offset,
                         unsigned bit_count = 32)
{
    uint32_t pci_address = pioofs(addr, offset);
    outd(PCI_ADDR, pci_address);
    if (bit_count == 32)
        return ind(PCI_DATA);
    uint32_t bit_offset = (offset & 3) << 3;
    return (ind(PCI_DATA) >> bit_offset) & ~(-1 << bit_count);
}

uint16_t pci_config_read_status(pci_addr_t addr)
{
    return pci_config_read(addr, 6, 16);
}

void pci_config_write(pci_addr_t addr, size_t offset, uint32_t value,
                      unsigned bit_count = 32)
{
    uint32_t pci_address = pioofs(addr, offset);
    outd(PCI_ADDR, pci_address);
    if (bit_count == 32) {
        outd(PCI_DATA, value);
        return;
    }

    uint32_t bit_offset = (offset & 3) << 3;
    uint32_t orig = ind(PCI_DATA);

    uint32_t lsb_mask = ~(-1 << bit_count);
    uint32_t pos_mask = lsb_mask << bit_offset;

    value = (orig & ~pos_mask) |
            ((value << bit_offset) & pos_mask);

    outd(PCI_ADDR, pci_address);
    outd(PCI_DATA, value);
}

extern "C" int test_msi()
{
    int bus = 0;
    for (int slot = 0; slot < 32; ++slot) {
        for (int func = 0; func < 8; ++func) {
            pci_addr_t addr{0, 0, slot, func};

            uint32_t volatile vendor = pci_config_read(addr, 0, 16);
            uint32_t volatile device = pci_config_read(addr, 2, 16);

            int status = pci_config_read_status(addr);

            // No device there?
            if (status == 0xFFFF) {
                func = 7;
                continue;
            }

            // No capability chain? Can't be virtio!
            if (!(status & 0x10))
                continue;

            uint32_t caps_ptr = pci_config_read(addr, 0x34, 8);

            while (caps_ptr != 0) {
                uint16_t type_next = pci_config_read(addr, caps_ptr, 16);
                uint8_t type = type_next & 0xFF;
                uint8_t next = (type_next >> 8) & 0xFF;
                if (type == 5)
                    return 1;
                if (type == 0x11)
                    return 1;
                caps_ptr = next;
            }

            // Failed if we fell off the end of a PCI device
            if (vendor == 0x1AF4 && device == 0x1050)
                return 0;
        }
    }

    return 0;
}
