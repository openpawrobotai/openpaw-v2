// OpenPaw BLE provisioning + control service (NimBLE).
//
// Advertises an "OpenPaw-XXYY" peripheral with one GATT service:
//   - CRED   (write)        : JSON {"ssid":"..","pass":".."} -> wifi_manager
//   - STATUS (read/notify)  : 1 byte ble_prov_status_t (Wi-Fi connection state)
//   - INFO   (read)         : "<fw-version>|<sta-mac>" for the app / OTA trigger
#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    BLE_PROV_IDLE       = 0,
    BLE_PROV_CONNECTING = 1,
    BLE_PROV_CONNECTED  = 2,
    BLE_PROV_FAILED     = 3,
} ble_prov_status_t;

// Start the BLE stack, GATT service, and advertising. Call once after Wi-Fi init.
void ble_prov_init(void);

// Update the STATUS characteristic and notify any subscribed client.
void ble_prov_set_status(ble_prov_status_t status);

// Like ble_prov_set_status but also carries a failure reason code (the esp-idf
// Wi-Fi disconnect reason) so the app can show a specific message. The STATUS
// characteristic value is 2 bytes: [status, reason].
void ble_prov_set_status_reason(ble_prov_status_t status, uint8_t reason);

#ifdef __cplusplus
}
#endif
