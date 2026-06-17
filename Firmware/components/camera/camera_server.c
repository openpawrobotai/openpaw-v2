#include "camera_server.h"

#include <stdlib.h>
#include <stdio.h>

#include "esp_camera.h"
#include "esp_http_server.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#include "motion.h"
#include "sensors.h"
#include "ota_update.h"

static const char *TAG = "camera";

/* Seeed Studio XIAO ESP32-S3 Sense camera pins */
#define PWDN_GPIO_NUM   -1
#define RESET_GPIO_NUM  -1
#define XCLK_GPIO_NUM   10
#define SIOD_GPIO_NUM   40
#define SIOC_GPIO_NUM   39
#define Y9_GPIO_NUM     48
#define Y8_GPIO_NUM     11
#define Y7_GPIO_NUM     12
#define Y6_GPIO_NUM     14
#define Y5_GPIO_NUM     16
#define Y4_GPIO_NUM     18
#define Y3_GPIO_NUM     17
#define Y2_GPIO_NUM     15
#define VSYNC_GPIO_NUM  38
#define HREF_GPIO_NUM   47
#define PCLK_GPIO_NUM   13

static httpd_handle_t s_web = NULL;     /* port 80: control + status */
static httpd_handle_t s_stream = NULL;  /* port 81: MJPEG */
static bool s_started = false;

static esp_err_t camera_init(void)
{
    camera_config_t config = {
        .pin_pwdn = PWDN_GPIO_NUM,
        .pin_reset = RESET_GPIO_NUM,
        .pin_xclk = XCLK_GPIO_NUM,
        .pin_sccb_sda = SIOD_GPIO_NUM,
        .pin_sccb_scl = SIOC_GPIO_NUM,
        .pin_d7 = Y9_GPIO_NUM,
        .pin_d6 = Y8_GPIO_NUM,
        .pin_d5 = Y7_GPIO_NUM,
        .pin_d4 = Y6_GPIO_NUM,
        .pin_d3 = Y5_GPIO_NUM,
        .pin_d2 = Y4_GPIO_NUM,
        .pin_d1 = Y3_GPIO_NUM,
        .pin_d0 = Y2_GPIO_NUM,
        .pin_vsync = VSYNC_GPIO_NUM,
        .pin_href = HREF_GPIO_NUM,
        .pin_pclk = PCLK_GPIO_NUM,
        .xclk_freq_hz = 20000000,
        .ledc_timer = LEDC_TIMER_1,    /* TIMER_0/CH0-3 are the motors */
        .ledc_channel = LEDC_CHANNEL_4,
        .pixel_format = PIXFORMAT_JPEG,
        .frame_size = FRAMESIZE_QVGA,
        .jpeg_quality = 12,
        .fb_count = 2,
        .fb_location = CAMERA_FB_IN_PSRAM,
        .grab_mode = CAMERA_GRAB_LATEST,
    };
    esp_err_t err = esp_camera_init(&config);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "esp_camera_init failed: 0x%x (camera attached?)", err);
    } else {
        ESP_LOGI(TAG, "Camera ready (QVGA JPEG)");
    }
    return err;
}

static void cors(httpd_req_t *req)
{
    httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");
}

static esp_err_t stream_handler(httpd_req_t *req)
{
    httpd_resp_set_type(req, "multipart/x-mixed-replace;boundary=frame");
    cors(req);

    while (true) {
        camera_fb_t *fb = esp_camera_fb_get();
        if (!fb) {
            ESP_LOGE(TAG, "camera capture failed");
            return ESP_FAIL;
        }
        esp_err_t res = httpd_resp_send_chunk(req, "--frame\r\n", HTTPD_RESP_USE_STRLEN);
        if (res == ESP_OK) {
            res = httpd_resp_send_chunk(req, "Content-Type: image/jpeg\r\n\r\n", HTTPD_RESP_USE_STRLEN);
        }
        if (res == ESP_OK) {
            res = httpd_resp_send_chunk(req, (const char *)fb->buf, fb->len);
        }
        if (res == ESP_OK) {
            res = httpd_resp_send_chunk(req, "\r\n", HTTPD_RESP_USE_STRLEN);
        }
        esp_camera_fb_return(fb);
        if (res != ESP_OK) {
            break;  /* client disconnected */
        }
        vTaskDelay(pdMS_TO_TICKS(66));  /* ~15 fps */
    }
    return ESP_OK;
}

static esp_err_t status_handler(httpd_req_t *req)
{
    cors(req);
    httpd_resp_set_type(req, "application/json");
    char json[176];
    snprintf(json, sizeof(json),
             "{\"distance\":%d,\"temp_ambient\":%.1f,\"temp_object\":%.1f,"
             "\"laser\":%s,\"drive\":%d,\"turn\":%d}",
             sensors_distance_mm(), sensors_temp_ambient(), sensors_temp_object(),
             motion_laser_on() ? "true" : "false", motion_drive(), motion_turn());
    return httpd_resp_sendstr(req, json);
}

static esp_err_t motor_handler(httpd_req_t *req)
{
    cors(req);
    char q[64], val[16];
    int drive = 0, turn = 0;
    if (httpd_req_get_url_query_str(req, q, sizeof(q)) == ESP_OK) {
        if (httpd_query_key_value(q, "drive", val, sizeof(val)) == ESP_OK) drive = atoi(val);
        if (httpd_query_key_value(q, "turn", val, sizeof(val)) == ESP_OK) turn = atoi(val);
    }
    motion_set_motor(drive, turn);
    return httpd_resp_sendstr(req, "ok");
}

static esp_err_t laser_handler(httpd_req_t *req)
{
    cors(req);
    bool on = motion_toggle_laser();
    return httpd_resp_sendstr(req, on ? "LASER_ON" : "LASER_OFF");
}

/* /beep stays a stub until the sound branch lands. */
static esp_err_t ok_handler(httpd_req_t *req)
{
    cors(req);
    return httpd_resp_sendstr(req, "ok");
}

/* ==================== OTA (firmware update) ==================== */

/* Current firmware version + whether a rollback target exists. */
static esp_err_t ota_info_handler(httpd_req_t *req)
{
    cors(req);
    httpd_resp_set_type(req, "application/json");
    char json[192];
    snprintf(json, sizeof(json),
             "{\"version\":\"%s\",\"partition\":\"%s\",\"can_rollback\":%s}",
             ota_running_version(), ota_running_partition(),
             ota_can_rollback() ? "true" : "false");
    return httpd_resp_sendstr(req, json);
}

static const char *ota_state_str(ota_state_t s)
{
    switch (s) {
        case OTA_CHECKING:    return "checking";
        case OTA_DOWNLOADING: return "downloading";
        case OTA_UP_TO_DATE:  return "up_to_date";
        case OTA_SUCCESS:     return "success";
        case OTA_ERROR:       return "error";
        default:              return "idle";
    }
}

/* Live progress of an in-flight update, polled by the app. */
static esp_err_t ota_status_handler(httpd_req_t *req)
{
    cors(req);
    httpd_resp_set_type(req, "application/json");
    ota_state_t st;
    int pct;
    char msg[96];
    ota_get_progress(&st, &pct, msg, sizeof(msg));
    char json[224];
    snprintf(json, sizeof(json),
             "{\"state\":\"%s\",\"percent\":%d,\"message\":\"%s\"}",
             ota_state_str(st), pct, msg);
    return httpd_resp_sendstr(req, json);
}

/* Trigger an update. Uses the firmware's built-in manifest URL (no body). */
static esp_err_t ota_update_handler(httpd_req_t *req)
{
    cors(req);
    httpd_resp_set_type(req, "application/json");
    ota_start(NULL);
    return httpd_resp_sendstr(req, "{\"started\":true}");
}

/* Revert to the previously-installed firmware (reboots if it succeeds). */
static esp_err_t ota_rollback_handler(httpd_req_t *req)
{
    cors(req);
    httpd_resp_set_type(req, "application/json");
    if (!ota_can_rollback()) {
        return httpd_resp_sendstr(req,
            "{\"ok\":false,\"error\":\"no previous firmware to roll back to\"}");
    }
    httpd_resp_sendstr(req, "{\"ok\":true}");  /* answer before we reboot */
    vTaskDelay(pdMS_TO_TICKS(300));
    ota_rollback();  /* does not return on success */
    return ESP_OK;
}

static httpd_handle_t start_httpd(uint16_t port, uint16_t ctrl_port)
{
    httpd_config_t config = HTTPD_DEFAULT_CONFIG();
    config.server_port = port;
    config.ctrl_port = ctrl_port;  /* distinct per instance or httpd_start collides */
    config.stack_size = 8192;
    config.max_uri_handlers = 16;  /* control + status + OTA routes */
    config.lru_purge_enable = true;
    httpd_handle_t server = NULL;
    if (httpd_start(&server, &config) != ESP_OK) {
        ESP_LOGE(TAG, "httpd_start failed on port %u", port);
        return NULL;
    }
    return server;
}

void camera_server_start(void)
{
    if (s_started) {
        return;
    }
    if (camera_init() != ESP_OK) {
        return;  /* no camera — skip the servers */
    }

    s_web = start_httpd(80, 32080);
    if (s_web) {
        const httpd_uri_t routes[] = {
            { .uri = "/status", .method = HTTP_GET, .handler = status_handler },
            { .uri = "/motor",  .method = HTTP_GET, .handler = motor_handler },
            { .uri = "/laser",  .method = HTTP_GET, .handler = laser_handler },
            { .uri = "/beep",   .method = HTTP_GET, .handler = ok_handler },
            { .uri = "/ota/info",     .method = HTTP_GET, .handler = ota_info_handler },
            { .uri = "/ota/status",   .method = HTTP_GET, .handler = ota_status_handler },
            { .uri = "/ota/update",   .method = HTTP_GET, .handler = ota_update_handler },
            { .uri = "/ota/rollback", .method = HTTP_GET, .handler = ota_rollback_handler },
        };
        for (size_t i = 0; i < sizeof(routes) / sizeof(routes[0]); i++) {
            httpd_register_uri_handler(s_web, &routes[i]);
        }
    }

    s_stream = start_httpd(81, 32081);
    if (s_stream) {
        const httpd_uri_t stream_uri = {
            .uri = "/stream", .method = HTTP_GET, .handler = stream_handler };
        httpd_register_uri_handler(s_stream, &stream_uri);
    }

    s_started = true;
    ESP_LOGI(TAG, "Camera HTTP server up: control :80, MJPEG :81/stream");
}
