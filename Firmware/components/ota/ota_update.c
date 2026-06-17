#include "ota_update.h"

#include <string.h>
#include <stdarg.h>

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/semphr.h"
#include "esp_log.h"
#include "esp_ota_ops.h"
#include "esp_app_desc.h"
#include "esp_https_ota.h"
#include "esp_http_client.h"
#include "esp_crt_bundle.h"
#include "sdkconfig.h"
#include "cJSON.h"

static const char *TAG = "ota";

// --- shared progress state (written by the OTA task, read by the httpd) -----

static SemaphoreHandle_t s_lock;
static ota_state_t s_state = OTA_IDLE;
static int  s_percent = 0;
static char s_msg[96] = "Idle";
static TaskHandle_t s_task = NULL;
static char s_manifest_url[256];
static char s_board[40] = "esp32_ball_v1";  // manifest.boards key; set at boot

void ota_set_board(const char *board)
{
    if (board && board[0]) strlcpy(s_board, board, sizeof(s_board));
}

static void set_state(ota_state_t st, int percent, const char *fmt, ...)
{
    if (s_lock) xSemaphoreTake(s_lock, portMAX_DELAY);
    s_state = st;
    s_percent = percent;
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(s_msg, sizeof(s_msg), fmt, ap);
    va_end(ap);
    if (s_lock) xSemaphoreGive(s_lock);
}

void ota_get_progress(ota_state_t *state, int *percent, char *msg, int msg_cap)
{
    if (s_lock) xSemaphoreTake(s_lock, portMAX_DELAY);
    if (state)   *state = s_state;
    if (percent) *percent = s_percent;
    if (msg && msg_cap > 0) strlcpy(msg, s_msg, msg_cap);
    if (s_lock) xSemaphoreGive(s_lock);
}

const char *ota_running_version(void)
{
    const esp_app_desc_t *desc = esp_app_get_description();
    return desc ? desc->version : "unknown";
}

const char *ota_running_partition(void)
{
    return esp_ota_get_running_partition()->label;
}

void ota_update_init(void)
{
    if (!s_lock) s_lock = xSemaphoreCreateMutex();

    const esp_partition_t *running = esp_ota_get_running_partition();
    esp_ota_img_states_t state;
    if (esp_ota_get_state_partition(running, &state) == ESP_OK &&
        state == ESP_OTA_IMG_PENDING_VERIFY) {
        ESP_LOGW(TAG, "Booted a pending-verify image — confirm with ota_mark_valid()");
    }
    ESP_LOGI(TAG, "Running version: %s (partition '%s')",
             ota_running_version(), running->label);
}

// --- on-demand rollback -----------------------------------------------------

// The spare slot (the one we'd write the next update to) holds the previously
// running app. If it's marked VALID, we can boot it again; if it's empty or
// invalid (e.g. never updated), refuse so we can't roll into a brick.
bool ota_can_rollback(void)
{
    const esp_partition_t *other = esp_ota_get_next_update_partition(NULL);
    esp_ota_img_states_t st;
    return other &&
           esp_ota_get_state_partition(other, &st) == ESP_OK &&
           st == ESP_OTA_IMG_VALID;
}

esp_err_t ota_rollback(void)
{
    const esp_partition_t *other = esp_ota_get_next_update_partition(NULL);
    esp_ota_img_states_t st;
    if (!other || esp_ota_get_state_partition(other, &st) != ESP_OK ||
        st != ESP_OTA_IMG_VALID) {
        ESP_LOGW(TAG, "rollback refused: no valid previous image");
        return ESP_ERR_NOT_FOUND;
    }
    ESP_LOGW(TAG, "Rolling back to '%s' and rebooting", other->label);
    esp_err_t err = esp_ota_set_boot_partition(other);
    if (err == ESP_OK) {
        vTaskDelay(pdMS_TO_TICKS(800));
        esp_restart();
    }
    return err;
}

void ota_mark_valid(void)
{
    const esp_partition_t *running = esp_ota_get_running_partition();
    esp_ota_img_states_t state;
    if (esp_ota_get_state_partition(running, &state) == ESP_OK &&
        state == ESP_OTA_IMG_PENDING_VERIFY) {
        if (esp_ota_mark_app_valid_cancel_rollback() == ESP_OK) {
            ESP_LOGI(TAG, "Image confirmed valid; rollback cancelled");
        } else {
            ESP_LOGE(TAG, "Failed to mark image valid");
        }
    }
}

// --- manifest fetch ---------------------------------------------------------

typedef struct {
    char *buf;
    int   len;
    int   cap;
} resp_buf_t;

static esp_err_t http_event(esp_http_client_event_t *evt)
{
    if (evt->event_id == HTTP_EVENT_ON_DATA && evt->user_data) {
        resp_buf_t *r = (resp_buf_t *)evt->user_data;
        if (r->len + evt->data_len < r->cap) {
            memcpy(r->buf + r->len, evt->data, evt->data_len);
            r->len += evt->data_len;
            r->buf[r->len] = '\0';
        } else {
            ESP_LOGE(TAG, "manifest larger than buffer");
        }
    }
    return ESP_OK;
}

static esp_err_t fetch_manifest(const char *url, char *out, int cap)
{
    resp_buf_t r = { .buf = out, .len = 0, .cap = cap };
    esp_http_client_config_t cfg = {
        .url               = url,
        .crt_bundle_attach = esp_crt_bundle_attach,
        .event_handler     = http_event,
        .user_data         = &r,
        .timeout_ms        = 15000,
    };
    esp_http_client_handle_t client = esp_http_client_init(&cfg);
    esp_err_t err = esp_http_client_perform(client);
    int status = esp_http_client_get_status_code(client);
    esp_http_client_cleanup(client);

    if (err == ESP_OK && status == 200) {
        return ESP_OK;
    }
    ESP_LOGE(TAG, "manifest fetch failed: %s (HTTP %d)", esp_err_to_name(err), status);
    return ESP_FAIL;
}

// Stream the .bin into the spare slot using the handle-based API so we can
// report download progress. On success this reboots and does not return.
static esp_err_t download_and_apply(const char *url, const char *version)
{
    set_state(OTA_DOWNLOADING, 0, "Downloading %s", version);
    ESP_LOGI(TAG, "Updating to %s from %s", version, url);

    esp_http_client_config_t http = {
        .url               = url,
        .crt_bundle_attach = esp_crt_bundle_attach,
        .timeout_ms        = 20000,
        .keep_alive_enable = true,
    };
    esp_https_ota_config_t cfg = { .http_config = &http };

    esp_https_ota_handle_t handle = NULL;
    esp_err_t err = esp_https_ota_begin(&cfg, &handle);
    if (err != ESP_OK || !handle) {
        set_state(OTA_ERROR, 0, "Download failed to start");
        return ESP_FAIL;
    }

    int total = esp_https_ota_get_image_size(handle);
    while ((err = esp_https_ota_perform(handle)) == ESP_ERR_HTTPS_OTA_IN_PROGRESS) {
        int read = esp_https_ota_get_image_len_read(handle);
        int pct = (total > 0) ? (int)((int64_t)read * 100 / total) : 0;
        set_state(OTA_DOWNLOADING, pct, "Downloading %s", version);
    }

    if (err == ESP_OK && esp_https_ota_is_complete_data_received(handle)) {
        err = esp_https_ota_finish(handle);
        if (err == ESP_OK) {
            set_state(OTA_SUCCESS, 100, "Installed %s — rebooting", version);
            ESP_LOGI(TAG, "OTA succeeded — rebooting");
            vTaskDelay(pdMS_TO_TICKS(800));
            esp_restart();   // does not return
            return ESP_OK;
        }
    } else {
        esp_https_ota_abort(handle);
    }
    set_state(OTA_ERROR, 0, "Update failed (%s)", esp_err_to_name(err));
    ESP_LOGE(TAG, "OTA failed: %s", esp_err_to_name(err));
    return (err == ESP_OK) ? ESP_FAIL : err;
}

// Fetch + parse the manifest, then update if it advertises a newer version.
// Shared by the boot-time check and the app-triggered task.
static esp_err_t run_update(const char *manifest_url, const char *board)
{
    if (!manifest_url || manifest_url[0] == '\0' || !board || board[0] == '\0') {
        set_state(OTA_ERROR, 0, "No manifest URL / board configured");
        return ESP_ERR_INVALID_ARG;
    }

    set_state(OTA_CHECKING, 0, "Checking for updates");
    char json[2048];
    if (fetch_manifest(manifest_url, json, sizeof(json)) != ESP_OK) {
        set_state(OTA_ERROR, 0, "Could not reach update server");
        return ESP_FAIL;
    }

    cJSON *root = cJSON_Parse(json);
    if (!root) {
        ESP_LOGE(TAG, "manifest is not valid JSON");
        set_state(OTA_ERROR, 0, "Bad manifest from server");
        return ESP_FAIL;
    }

    // manifest schema: { "boards": { "<board>": {"version","url","sha256","size"} } }
    const cJSON *boards = cJSON_GetObjectItemCaseSensitive(root, "boards");
    const cJSON *entry  = boards ? cJSON_GetObjectItemCaseSensitive(boards, board) : NULL;
    const cJSON *jver = entry ? cJSON_GetObjectItemCaseSensitive(entry, "version") : NULL;
    const cJSON *jurl = entry ? cJSON_GetObjectItemCaseSensitive(entry, "url") : NULL;

    if (!cJSON_IsString(jver) || !cJSON_IsString(jurl)) {
        ESP_LOGE(TAG, "manifest has no version/url for board '%s'", board);
        set_state(OTA_ERROR, 0, "No build available for this board");
        cJSON_Delete(root);
        return ESP_FAIL;
    }

    const char *running = ota_running_version();
    ESP_LOGI(TAG, "running=%s  latest=%s", running, jver->valuestring);

    if (strcmp(jver->valuestring, running) == 0) {
        set_state(OTA_UP_TO_DATE, 100, "Up to date (%s)", running);
        ESP_LOGI(TAG, "Firmware already up to date");
        cJSON_Delete(root);
        return ESP_OK;
    }

    // Copy out of the cJSON tree before freeing it.
    char url[256], version[48];
    strlcpy(url, jurl->valuestring, sizeof(url));
    strlcpy(version, jver->valuestring, sizeof(version));
    cJSON_Delete(root);

    return download_and_apply(url, version);
}

esp_err_t ota_check_and_update(const char *manifest_url, const char *board)
{
    return run_update(manifest_url, board);
}

static void ota_task(void *arg)
{
    run_update(s_manifest_url, s_board);
    s_task = NULL;
    vTaskDelete(NULL);
}

void ota_start(const char *manifest_url)
{
    ota_state_t st;
    ota_get_progress(&st, NULL, NULL, 0);
    if (st == OTA_CHECKING || st == OTA_DOWNLOADING) {
        ESP_LOGW(TAG, "ota_start ignored: update already in progress");
        return;
    }

    const char *url = (manifest_url && manifest_url[0]) ? manifest_url
                                                        : CONFIG_OPENPAW_OTA_MANIFEST_URL;
    if (!url || url[0] == '\0') {
        set_state(OTA_ERROR, 0, "No manifest URL configured");
        return;
    }
    strlcpy(s_manifest_url, url, sizeof(s_manifest_url));
    set_state(OTA_CHECKING, 0, "Starting update");
    // TLS + HTTPS-OTA needs a generous stack.
    xTaskCreate(ota_task, "ota", 8192, NULL, 5, &s_task);
}
