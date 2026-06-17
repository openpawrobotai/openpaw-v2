// OpenPaw Wi-Fi station manager.
// Connects in STA mode using credentials from NVS, falling back to the dev
// credentials compiled in via Kconfig. BLE provisioning calls
// wifi_manager_set_credentials() to store new creds and (re)connect.
#pragma once

#include <stdbool.h>
#include "esp_err.h"

#ifdef __cplusplus
extern "C" {
#endif

// Called from the Wi-Fi event task once an IP has been acquired. Keep it short.
typedef void (*wifi_manager_connected_cb_t)(void);

// Called when connecting gives up after repeated failures (e.g. bad password).
// `reason` is the esp-idf wifi disconnect reason code. Keep it short.
typedef void (*wifi_manager_failed_cb_t)(int reason);

// Bring up Wi-Fi in station mode. Non-blocking: if credentials are available
// (NVS or Kconfig) it begins connecting and invokes on_connected on success.
// If no credentials exist, it stays idle until wifi_manager_set_credentials().
void wifi_manager_init(wifi_manager_connected_cb_t on_connected,
                       wifi_manager_failed_cb_t on_failed);

// Persist new credentials to NVS and (re)connect. Safe to call after init,
// e.g. from a BLE characteristic write handler.
esp_err_t wifi_manager_set_credentials(const char *ssid, const char *pass);

// True once the station has an IP address.
bool wifi_manager_is_connected(void);

// Copy the current station IP ("a.b.c.d") into buf, or "" if not connected.
void wifi_manager_get_ip(char *buf, size_t cap);

// Run a blocking Wi-Fi scan and write a JSON array of unique SSIDs (strongest
// first) into buf, e.g. ["HomeNet","Cafe"]. Returns the count. Call from a task,
// not a BLE/event callback (it blocks for a few seconds).
int wifi_manager_scan_json(char *buf, size_t cap);

#ifdef __cplusplus
}
#endif
