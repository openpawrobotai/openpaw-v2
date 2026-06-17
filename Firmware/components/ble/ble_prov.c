#include "ble_prov.h"

#include <string.h>
#include <stdio.h>

#include "esp_log.h"
#include "esp_mac.h"
#include "esp_app_desc.h"
#include "nvs_flash.h"
#include "cJSON.h"

#include "nimble/nimble_port.h"
#include "nimble/nimble_port_freertos.h"
#include "host/ble_hs.h"
#include "host/util/util.h"
#include "services/gap/ble_svc_gap.h"
#include "services/gatt/ble_svc_gatt.h"

#include "wifi_manager.h"

static const char *TAG = "ble_prov";

// Service 6e40...; characteristics differ in byte [12]: 0x01 cred, 0x02 status, 0x03 info.
static const ble_uuid128_t svc_uuid =
    BLE_UUID128_INIT(0x23,0xd1,0xbc,0xea,0x5f,0x78,0x23,0x15,0xde,0xef,0x12,0x12,0x00,0x40,0x6e,0x00);
static const ble_uuid128_t cred_uuid =
    BLE_UUID128_INIT(0x23,0xd1,0xbc,0xea,0x5f,0x78,0x23,0x15,0xde,0xef,0x12,0x12,0x01,0x40,0x6e,0x00);
static const ble_uuid128_t status_uuid =
    BLE_UUID128_INIT(0x23,0xd1,0xbc,0xea,0x5f,0x78,0x23,0x15,0xde,0xef,0x12,0x12,0x02,0x40,0x6e,0x00);
static const ble_uuid128_t info_uuid =
    BLE_UUID128_INIT(0x23,0xd1,0xbc,0xea,0x5f,0x78,0x23,0x15,0xde,0xef,0x12,0x12,0x03,0x40,0x6e,0x00);
static const ble_uuid128_t networks_uuid =
    BLE_UUID128_INIT(0x23,0xd1,0xbc,0xea,0x5f,0x78,0x23,0x15,0xde,0xef,0x12,0x12,0x04,0x40,0x6e,0x00);

static uint8_t  s_addr_type;
static uint16_t s_conn_handle = BLE_HS_CONN_HANDLE_NONE;
static uint16_t s_status_val_handle;
static uint16_t s_networks_val_handle;
static ble_prov_status_t s_status = BLE_PROV_IDLE;
static uint8_t s_status_reason;  // wifi disconnect reason for the FAILED state
static char s_name[20];
static char s_networks[1024] = "[]";  // JSON array of scanned SSIDs

static void start_advertising(void);

static void handle_credentials(const char *json)
{
    cJSON *root = cJSON_Parse(json);
    if (!root) {
        ESP_LOGE(TAG, "credentials payload is not JSON");
        return;
    }
    const cJSON *jssid = cJSON_GetObjectItemCaseSensitive(root, "ssid");
    const cJSON *jpass = cJSON_GetObjectItemCaseSensitive(root, "pass");
    if (cJSON_IsString(jssid) && jssid->valuestring[0] != '\0') {
        int pass_len = cJSON_IsString(jpass) ? (int)strlen(jpass->valuestring) : 0;
        ESP_LOGI(TAG, "Provisioning via BLE: ssid='%s' pass_len=%d", jssid->valuestring, pass_len);
        ble_prov_set_status(BLE_PROV_CONNECTING);
        wifi_manager_set_credentials(jssid->valuestring,
                                     cJSON_IsString(jpass) ? jpass->valuestring : "");
    } else {
        ESP_LOGE(TAG, "credentials missing 'ssid'");
    }
    cJSON_Delete(root);
}

static int chr_access(uint16_t conn_handle, uint16_t attr_handle,
                      struct ble_gatt_access_ctxt *ctxt, void *arg)
{
    if (ctxt->op == BLE_GATT_ACCESS_OP_WRITE_CHR &&
        ble_uuid_cmp(ctxt->chr->uuid, &cred_uuid.u) == 0) {
        char buf[192];
        uint16_t len = 0;
        if (ble_hs_mbuf_to_flat(ctxt->om, buf, sizeof(buf) - 1, &len) != 0) {
            return BLE_ATT_ERR_UNLIKELY;
        }
        buf[len] = '\0';
        handle_credentials(buf);
        return 0;
    }
    if (ctxt->op == BLE_GATT_ACCESS_OP_READ_CHR &&
        ble_uuid_cmp(ctxt->chr->uuid, &status_uuid.u) == 0) {
        uint8_t v[2] = { (uint8_t)s_status, s_status_reason };
        return os_mbuf_append(ctxt->om, v, sizeof(v)) == 0 ? 0 : BLE_ATT_ERR_INSUFFICIENT_RES;
    }
    if (ctxt->op == BLE_GATT_ACCESS_OP_READ_CHR &&
        ble_uuid_cmp(ctxt->chr->uuid, &info_uuid.u) == 0) {
        const esp_app_desc_t *desc = esp_app_get_description();
        uint8_t mac[6] = { 0 };
        esp_read_mac(mac, ESP_MAC_WIFI_STA);
        char ip[16] = { 0 };
        wifi_manager_get_ip(ip, sizeof(ip));
        char info[112];
        int n = snprintf(info, sizeof(info), "%s|%02x:%02x:%02x:%02x:%02x:%02x|%s",
                         desc ? desc->version : "?",
                         mac[0], mac[1], mac[2], mac[3], mac[4], mac[5], ip);
        return os_mbuf_append(ctxt->om, info, n) == 0 ? 0 : BLE_ATT_ERR_INSUFFICIENT_RES;
    }
    if (ctxt->op == BLE_GATT_ACCESS_OP_READ_CHR &&
        ble_uuid_cmp(ctxt->chr->uuid, &networks_uuid.u) == 0) {
        return os_mbuf_append(ctxt->om, s_networks, strlen(s_networks)) == 0
                   ? 0 : BLE_ATT_ERR_INSUFFICIENT_RES;
    }
    return BLE_ATT_ERR_UNLIKELY;
}

static const struct ble_gatt_svc_def gatt_svcs[] = {
    {
        .type = BLE_GATT_SVC_TYPE_PRIMARY,
        .uuid = &svc_uuid.u,
        .characteristics = (struct ble_gatt_chr_def[]) {
            { .uuid = &cred_uuid.u,   .access_cb = chr_access, .flags = BLE_GATT_CHR_F_WRITE },
            { .uuid = &status_uuid.u, .access_cb = chr_access,
              .flags = BLE_GATT_CHR_F_READ | BLE_GATT_CHR_F_NOTIFY, .val_handle = &s_status_val_handle },
            { .uuid = &info_uuid.u,   .access_cb = chr_access, .flags = BLE_GATT_CHR_F_READ },
            { .uuid = &networks_uuid.u, .access_cb = chr_access,
              .flags = BLE_GATT_CHR_F_READ | BLE_GATT_CHR_F_NOTIFY, .val_handle = &s_networks_val_handle },
            { 0 }
        },
    },
    { 0 }
};

// Scan Wi-Fi (blocking) off the BLE host task, then notify the app the list is ready.
static void scan_task(void *arg)
{
    wifi_manager_scan_json(s_networks, sizeof(s_networks));
    if (s_networks_val_handle != 0) {
        ble_gatts_chr_updated(s_networks_val_handle);
    }
    vTaskDelete(NULL);
}

static int gap_event(struct ble_gap_event *event, void *arg)
{
    switch (event->type) {
    case BLE_GAP_EVENT_CONNECT:
        if (event->connect.status == 0) {
            s_conn_handle = event->connect.conn_handle;
            ESP_LOGI(TAG, "BLE client connected");
            // Scan nearby Wi-Fi so the app can offer a picker.
            xTaskCreate(scan_task, "wifi_scan", 4096, NULL, 4, NULL);
        } else {
            start_advertising();
        }
        return 0;
    case BLE_GAP_EVENT_DISCONNECT:
        ESP_LOGI(TAG, "BLE client disconnected; re-advertising");
        s_conn_handle = BLE_HS_CONN_HANDLE_NONE;
        start_advertising();
        return 0;
    case BLE_GAP_EVENT_ADV_COMPLETE:
        start_advertising();
        return 0;
    default:
        return 0;
    }
}

static void start_advertising(void)
{
    struct ble_hs_adv_fields adv = { 0 };
    adv.flags = BLE_HS_ADV_F_DISC_GEN | BLE_HS_ADV_F_BREDR_UNSUP;
    adv.name = (uint8_t *)s_name;
    adv.name_len = strlen(s_name);
    adv.name_is_complete = 1;
    if (ble_gap_adv_set_fields(&adv) != 0) {
        ESP_LOGE(TAG, "adv_set_fields failed");
        return;
    }
    // 128-bit service UUID goes in the scan response (won't fit alongside the name in 31 bytes).
    struct ble_hs_adv_fields rsp = { 0 };
    rsp.uuids128 = (ble_uuid128_t *)&svc_uuid;
    rsp.num_uuids128 = 1;
    rsp.uuids128_is_complete = 1;
    ble_gap_adv_rsp_set_fields(&rsp);

    struct ble_gap_adv_params params = { 0 };
    params.conn_mode = BLE_GAP_CONN_MODE_UND;
    params.disc_mode = BLE_GAP_DISC_MODE_GEN;
    // Slow advertising (~500-800ms) so BLE doesn't starve Wi-Fi on the shared
    // 2.4GHz radio — keeps the camera stream/control responsive. Units: 0.625ms.
    params.itvl_min = 0x320;
    params.itvl_max = 0x500;
    int rc = ble_gap_adv_start(s_addr_type, NULL, BLE_HS_FOREVER, &params, gap_event, NULL);
    if (rc != 0) {
        ESP_LOGE(TAG, "adv_start failed: %d", rc);
    } else {
        ESP_LOGI(TAG, "Advertising as '%s'", s_name);
    }
}

static void on_sync(void)
{
    ble_hs_util_ensure_addr(0);
    ble_hs_id_infer_auto(0, &s_addr_type);
    start_advertising();
}

static void on_reset(int reason)
{
    ESP_LOGW(TAG, "BLE host reset, reason=%d", reason);
}

static void host_task(void *param)
{
    nimble_port_run();
    nimble_port_freertos_deinit();
}

void ble_prov_set_status(ble_prov_status_t status)
{
    ble_prov_set_status_reason(status, 0);
}

void ble_prov_set_status_reason(ble_prov_status_t status, uint8_t reason)
{
    s_status = status;
    s_status_reason = reason;
    if (s_status_val_handle != 0) {
        ble_gatts_chr_updated(s_status_val_handle); // notify subscribers
    }
}

void ble_prov_init(void)
{
    uint8_t mac[6] = { 0 };
    esp_read_mac(mac, ESP_MAC_BT);
    snprintf(s_name, sizeof(s_name), "OpenPaw-%02X%02X", mac[4], mac[5]);

    esp_err_t err = nimble_port_init();
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "nimble_port_init failed: %s", esp_err_to_name(err));
        return;
    }

    ble_hs_cfg.sync_cb = on_sync;
    ble_hs_cfg.reset_cb = on_reset;

    ble_svc_gap_init();
    ble_svc_gatt_init();

    if (ble_gatts_count_cfg(gatt_svcs) != 0 || ble_gatts_add_svcs(gatt_svcs) != 0) {
        ESP_LOGE(TAG, "failed to register GATT services");
        return;
    }
    ble_svc_gap_device_name_set(s_name);

    nimble_port_freertos_init(host_task);
    ESP_LOGI(TAG, "BLE provisioning started (device '%s')", s_name);
}
