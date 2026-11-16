#ifndef MTC_NATIVE_INVENTORY_H
#define MTC_NATIVE_INVENTORY_H

#include <stddef.h>
#include <stdint.h>

typedef enum {
    MTC_MODEL, MTC_MACHINE, MTC_CPU_BRAND, MTC_OS_BUILD,
    MTC_MEMORY, MTC_LOGICAL_CPUS, MTC_PHYSICAL_CPUS
} mtc_inventory_field;

typedef enum {
    MTC_INVENTORY_OK, MTC_INVENTORY_DENIED, MTC_INVENTORY_UNSUPPORTED,
    MTC_INVENTORY_BUFFER_TOO_SMALL, MTC_INVENTORY_ERROR, MTC_INVENTORY_INVALID
} mtc_inventory_status;

typedef struct {
    mtc_inventory_status status;
    size_t count;
    uint8_t bytes[256];
} mtc_inventory_result;

/* One synchronous read, with no retry, allocation, setter or deadline guarantee.
 * Only the exact fixed capacity for the field is accepted. Failures carry no data.
 * The future worker owns isolation; this function must not run on a parent path. */
mtc_inventory_result mtc_inventory_read(mtc_inventory_field field, size_t capacity);

#endif
