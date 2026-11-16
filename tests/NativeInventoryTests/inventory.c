/* Compile the real implementation with its sole syscall replaced. This test
 * translation unit cannot resolve a call to the real sysctlbyname symbol. */
#define sysctlbyname fixture_sysctlbyname
#include "../../Sources/CNativeInventory/Inventory.c"
#undef sysctlbyname
#include <assert.h>
#include <stdio.h>

static const char *expected_name;
static size_t expected_capacity;
static size_t returned_length;
static int failure_errno;
static int return_code;
static unsigned calls;
static unsigned char payload[256];

int fixture_sysctlbyname(const char *name, void *oldp, size_t *oldlenp,
                        void *newp, size_t newlen) {
    ++calls;
    assert(strcmp(name, expected_name) == 0);
    assert(newp == NULL && newlen == 0);
    assert(oldp != NULL && oldlenp != NULL && *oldlenp == expected_capacity);
    assert((uintptr_t)oldp % _Alignof(uint64_t) == 0);
    for (size_t i = 0; i < expected_capacity; ++i) {
        assert(((unsigned char *)oldp)[i] == 0);
    }
    /* Only write within the original capacity, even when reporting oversize. */
    memcpy(oldp, payload, expected_capacity);
    *oldlenp = returned_length;
    errno = failure_errno;
    return return_code;
}

static void empty_failure(mtc_inventory_result result, mtc_inventory_status status) {
    assert(result.status == status && result.count == 0);
    for (size_t i = 0; i < sizeof(result.bytes); ++i) assert(result.bytes[i] == 0);
}

int main(void) {
    const char *names[] = {"hw.model", "hw.machine", "machdep.cpu.brand_string",
                          "kern.osversion", "hw.memsize", "hw.logicalcpu", "hw.physicalcpu"};
    const size_t capacities[] = {128, 128, 256, 256, 8, 4, 4};
    const int errors[] = {EACCES, EPERM, ENOENT, ENOTSUP, ENOMEM, EIO, EINVAL, EINTR, 0};
    const mtc_inventory_status statuses[] = {
        MTC_INVENTORY_DENIED, MTC_INVENTORY_DENIED,
        MTC_INVENTORY_UNSUPPORTED, MTC_INVENTORY_UNSUPPORTED,
        MTC_INVENTORY_BUFFER_TOO_SMALL, MTC_INVENTORY_ERROR,
        MTC_INVENTORY_ERROR, MTC_INVENTORY_ERROR, MTC_INVENTORY_ERROR};
    for (int field = MTC_MODEL; field <= MTC_PHYSICAL_CPUS; ++field) {
        expected_name = names[field];
        expected_capacity = capacities[field];
        memset(payload, 0xA5, sizeof(payload));
        returned_length = expected_capacity;
        failure_errno = EACCES; // Stale errno must be ignored after success.
        return_code = 0;
        unsigned before = calls;
        mtc_inventory_result result = mtc_inventory_read((mtc_inventory_field)field, expected_capacity);
        assert(calls == before + 1 && result.status == MTC_INVENTORY_OK);
        assert(result.count == expected_capacity);
        assert(memcmp(result.bytes, payload, result.count) == 0);
        for (size_t i = result.count; i < sizeof(result.bytes); ++i) assert(result.bytes[i] == 0);
        for (size_t n = 0; n < sizeof(errors) / sizeof(errors[0]); ++n) {
            failure_errno = errors[n];
            return_code = -1;
            returned_length = SIZE_MAX;
            before = calls;
            empty_failure(mtc_inventory_read((mtc_inventory_field)field, expected_capacity), statuses[n]);
            assert(calls == before + 1); // No retry, size probe or fallback.
        }
        return_code = 0;
        const size_t invalid_lengths[] = {0, expected_capacity + 1, SIZE_MAX};
        for (size_t n = 0; n < 3; ++n) {
            returned_length = invalid_lengths[n];
            empty_failure(mtc_inventory_read((mtc_inventory_field)field, expected_capacity), MTC_INVENTORY_INVALID);
        }
        for (size_t length = 1; length < expected_capacity; ++length) {
            returned_length = length;
            result = mtc_inventory_read((mtc_inventory_field)field, expected_capacity);
            if (field >= MTC_MEMORY) empty_failure(result, MTC_INVENTORY_INVALID);
            else {
                assert(result.status == MTC_INVENTORY_OK && result.count == length);
                assert(memcmp(result.bytes, payload, length) == 0);
                for (size_t i = length; i < sizeof(result.bytes); ++i) assert(result.bytes[i] == 0);
            }
        }
        before = calls;
        const size_t invalid_capacities[] = {0, expected_capacity - 1, expected_capacity + 1, SIZE_MAX};
        for (size_t n = 0; n < 4; ++n) {
            empty_failure(mtc_inventory_read((mtc_inventory_field)field, invalid_capacities[n]), MTC_INVENTORY_INVALID);
        }
        assert(calls == before);
    }
    unsigned before = calls;
    empty_failure(mtc_inventory_read((mtc_inventory_field)-1, 128), MTC_INVENTORY_INVALID);
    empty_failure(mtc_inventory_read((mtc_inventory_field)7, 128), MTC_INVENTORY_INVALID);
    assert(calls == before);
    puts("PASS native selector/arguments, alignment, initialization, status, length and failure erasure (fake syscall only)");
    return 0;
}
