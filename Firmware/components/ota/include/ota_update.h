// OpenPaw OTA updater. App-mediated, GitHub-hosted firmware updates over HTTPS
// with bootloader rollback safety.
//
// Flow: a manifest JSON ({"version","url","sha256","board"}) advertises the
// latest build. If its version differs from the running build, the .bin at
// "url" is downloaded straight to the spare OTA slot, verified, and booted.
// The new image boots in PENDING_VERIFY; it must call ota_mark_valid() after a
// health check or the bootloader reverts on the next reboot.
#pragma once

#include <stdbool.h>
#include "esp_err.h"

#ifdef __cplusplus
extern "C" {
#endif

// Progress state for an app-triggered update (polled via /ota/status).
typedef enum {
    OTA_IDLE = 0,
    OTA_CHECKING,     // fetching + parsing the manifest
    OTA_DOWNLOADING,  // streaming the .bin into the spare slot
    OTA_UP_TO_DATE,   // manifest matched the running version; nothing to do
    OTA_SUCCESS,      // image written + verified; device is about to reboot
    OTA_ERROR,        // see message
} ota_state_t;

// Log running version and pending-verify state. Call early in app_main.
void ota_update_init(void);

// Confirm the current app is healthy, cancelling any pending rollback.
// No-op if the image is already marked valid.
void ota_mark_valid(void);

// Fetch the manifest at manifest_url and look up this board's entry
// (manifest.boards[board]); if it advertises a different version, download and
// apply it, then reboot (does not return on success). Blocking — call only once
// Wi-Fi is connected. Returns ESP_OK when already up to date.
esp_err_t ota_check_and_update(const char *manifest_url, const char *board);

// Set the board key used to look up this device's entry in the manifest
// (manifest.boards[board]). Call once at boot; defaults to "esp32_ball_v1".
void ota_set_board(const char *board);

// Kick off an update in a background task (non-blocking). Pass NULL/"" to use
// the built-in CONFIG_OPENPAW_OTA_MANIFEST_URL. Ignored if one is already
// running. Watch progress with ota_get_progress().
void ota_start(const char *manifest_url);

// Snapshot the current update progress. Any out-param may be NULL.
void ota_get_progress(ota_state_t *state, int *percent, char *msg, int msg_cap);

// Roll back to the previously-running app slot and reboot (does not return on
// success). Returns ESP_ERR_NOT_FOUND if there's no valid image to roll back to.
esp_err_t ota_rollback(void);

// True if the spare OTA slot holds a valid app we could roll back to.
bool ota_can_rollback(void);

// Label of the running partition, e.g. "ota_0".
const char *ota_running_partition(void);

// Running firmware version string from esp_app_desc (the git tag/describe).
const char *ota_running_version(void);

#ifdef __cplusplus
}
#endif
