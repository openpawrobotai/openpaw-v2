// Shared I2C master bus for the XIAO S3 Sense (SDA=GPIO5, SCL=GPIO6).
// Lazily initialised once and shared by the temp sensor, distance sensor,
// and LED face — call board_i2c_bus() from any of them.
#pragma once

#include "driver/i2c_master.h"

#ifdef __cplusplus
extern "C" {
#endif

// Returns the shared I2C0 bus handle, initialising it on first call.
// Returns NULL if init fails.
i2c_master_bus_handle_t board_i2c_bus(void);

#ifdef __cplusplus
}
#endif
