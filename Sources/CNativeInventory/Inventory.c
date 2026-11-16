#include "CNativeInventory.h"
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/sysctl.h>

#if !defined(__APPLE__) || !defined(__x86_64__)
#error Native inventory currently supports Intel macOS builds only
#endif
_Static_assert(sizeof(uint64_t) == 8, "Inventory memory width");
_Static_assert(sizeof(int) == 4, "Inventory CPU count width");
_Static_assert(__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__, "Inventory byte order");

mtc_inventory_result mtc_inventory_read(mtc_inventory_field field, size_t capacity) {
    const char *name;
    size_t expected;
    switch (field) {
        case MTC_MODEL: name = "hw.model"; expected = 128; break;
        case MTC_MACHINE: name = "hw.machine"; expected = 128; break;
        case MTC_CPU_BRAND: name = "machdep.cpu.brand_string"; expected = 256; break;
        case MTC_OS_BUILD: name = "kern.osversion"; expected = 256; break;
        case MTC_MEMORY: name = "hw.memsize"; expected = sizeof(uint64_t); break;
        case MTC_LOGICAL_CPUS: name = "hw.logicalcpu"; expected = sizeof(int); break;
        case MTC_PHYSICAL_CPUS: name = "hw.physicalcpu"; expected = sizeof(int); break;
        default: return (mtc_inventory_result){.status = MTC_INVENTORY_INVALID};
    }
    if (capacity != expected) {
        return (mtc_inventory_result){.status = MTC_INVENTORY_INVALID};
    }
    /* Aligned, initialized storage for every permitted native representation.
     * No dereference through a cast; bytes are copied only after success. */
    union {
        uint64_t memory;
        int cpu_count;
        unsigned char bytes[256];
    } storage;
    memset(&storage, 0, sizeof(storage));
    size_t length = expected;
    int result = sysctlbyname(name, &storage, &length, NULL, 0);
    int saved_errno = errno;
    if (result != 0) {
        mtc_inventory_status status;
        switch (saved_errno) {
            case EACCES: case EPERM: status = MTC_INVENTORY_DENIED; break;
            case ENOENT: case ENOTSUP: status = MTC_INVENTORY_UNSUPPORTED; break;
            case ENOMEM: status = MTC_INVENTORY_BUFFER_TOO_SMALL; break;
            default: status = MTC_INVENTORY_ERROR; break;
        }
        return (mtc_inventory_result){.status = status};
    }
    if (length == 0 || length > expected ||
        ((field == MTC_MEMORY || field == MTC_LOGICAL_CPUS || field == MTC_PHYSICAL_CPUS)
         && length != expected)) {
        return (mtc_inventory_result){.status = MTC_INVENTORY_INVALID};
    }
    mtc_inventory_result output = {.status = MTC_INVENTORY_OK, .count = length};
    memcpy(output.bytes, &storage, length);
    return output;
}
