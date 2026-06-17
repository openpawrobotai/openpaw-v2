// OpenPaw firmware entry point.
// Instinct layer: command dispatch + motion + sensors. AI runs off-MCU.
// License: MIT (c) 2026 aeropriest

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "nvs_flash.h"
#include "sdkconfig.h"

#include "wifi_manager.h"
#include "ota_update.h"
#include "ble_prov.h"
#include "camera_server.h"
#include "motion.h"
#include "sensors.h"

static const char *TAG = "openpaw";

// Runs (in the Wi-Fi event task) the first time the station gets an IP.
static void on_wifi_connected(void)
{
    // Reaching the network is our boot health check: confirm this image so the
    // bootloader won't roll it back on the next reboot.
    ota_mark_valid();
    ble_prov_set_status(BLE_PROV_CONNECTED);

    // Now that we have an IP, bring up the camera + control server (idempotent).
    camera_server_start();

#if CONFIG_OPENPAW_OTA_CHECK_ON_BOOT
    if (CONFIG_OPENPAW_OTA_MANIFEST_URL[0] != '\0') {
        ESP_LOGI(TAG, "Checking for firmware update...");
        ota_check_and_update(CONFIG_OPENPAW_OTA_MANIFEST_URL, CONFIG_OPENPAW_BOARD_NAME);
    }
#endif
}

// Connecting gave up (bad SSID/password or radio contention) — tell the app.
static void on_wifi_failed(int reason)
{
    ESP_LOGW(TAG, "Wi-Fi provisioning failed (reason %d)", reason);
    ble_prov_set_status_reason(BLE_PROV_FAILED, (uint8_t)reason);
}

// TODO(#14): init servo, imu, sensors, command dispatcher, BLE provisioning
void app_main(void)
{
    ESP_LOGI(TAG, "OpenPaw booting (board=%s, version=%s)",
             CONFIG_OPENPAW_BOARD_NAME, ota_running_version());

    esp_err_t err = nvs_flash_init();
    if (err == ESP_ERR_NVS_NO_FREE_PAGES || err == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        err = nvs_flash_init();
    }
    ESP_ERROR_CHECK(err);

    motion_init();   // motors + laser ready before networking
    sensors_init();  // temp + distance polling (shared I2C)
    ota_update_init();
    ota_set_board(CONFIG_OPENPAW_BOARD_NAME);  // for app-triggered manifest lookups
    wifi_manager_init(on_wifi_connected, on_wifi_failed);
    ble_prov_init();

    // command_dispatcher_start();   // UART/BLE token loop (k/m/i/d)
    // motion_engine_init();         // load gait tables, start playback timer
    // sensors_init();               // temp, laser pointer

    while (true) {
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}
