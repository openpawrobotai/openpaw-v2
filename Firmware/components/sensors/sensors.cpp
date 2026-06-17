#include "sensors.h"

#include "board_i2c.h"
#include "driver/i2c_master.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "VL53L0X.h"

static const char *TAG = "sensors";

/* MLX90614 IR temperature sensor (I2C 0x5A; regs 0x06 ambient, 0x07 object) */
#define MLX90614_ADDR 0x5A
static i2c_master_dev_handle_t s_temp_dev = NULL;
static volatile float s_temp_ambient = 0.0f;
static volatile float s_temp_object = 0.0f;
static volatile bool s_temp_ok = false;

static volatile uint16_t s_distance_mm = 0;

static bool read_temp_reg(uint8_t reg, float *out)
{
    uint8_t buf[2] = { 0 };
    if (i2c_master_transmit_receive(s_temp_dev, &reg, 1, buf, 2, 100) != ESP_OK) {
        return false;
    }
    int16_t raw = (int16_t)(buf[0] | (buf[1] << 8));
    float t = (float)raw * 0.02f - 273.15f;
    if (t > -50.0f && t < 150.0f) {
        *out = t;
        return true;
    }
    return false;
}

static void init_temp(i2c_master_bus_handle_t bus)
{
    if (i2c_master_probe(bus, MLX90614_ADDR, 100) != ESP_OK) {
        ESP_LOGW(TAG, "MLX90614 not found at 0x%02x", MLX90614_ADDR);
        return;
    }
    i2c_device_config_t dev_cfg = {
        .dev_addr_length = I2C_ADDR_BIT_LEN_7,
        .device_address = MLX90614_ADDR,
        .scl_speed_hz = 100000,
    };
    if (i2c_master_bus_add_device(bus, &dev_cfg, &s_temp_dev) != ESP_OK) {
        ESP_LOGW(TAG, "MLX90614 add_device failed");
        return;
    }
    float t;
    if (read_temp_reg(0x06, &t)) {
        s_temp_ok = true;
        ESP_LOGI(TAG, "MLX90614 ready (ambient=%.1fC)", t);
    }
}

static void sensors_task(void *pv)
{
    // Let the board's rails (and the camera) settle before probing I2C —
    // matches d_wip, which inits the sensors after the camera comes up.
    vTaskDelay(pdMS_TO_TICKS(4000));

    i2c_master_bus_handle_t bus = board_i2c_bus();

    // Diagnostic: scan the bus so we can see what (if anything) is wired.
    ESP_LOGI(TAG, "I2C scan (SDA5/SCL6):");
    int found = 0;
    for (uint8_t a = 1; a < 0x78; a++) {
        if (i2c_master_probe(bus, a, 50) == ESP_OK) {
            ESP_LOGI(TAG, "  device @ 0x%02x", a);
            found++;
        }
    }
    ESP_LOGI(TAG, "I2C scan done: %d device(s) found", found);

    for (int i = 0; i < 3 && !s_temp_ok; i++) {
        init_temp(bus);
        if (!s_temp_ok) vTaskDelay(pdMS_TO_TICKS(300));
    }

    VL53L0X *vl = new VL53L0X(I2C_NUM_0);
    vl->setBusHandle(bus);
    vl->addDevice(400000);
    bool dist_ok = false;
    for (int retry = 0; retry < 5; retry++) {
        vTaskDelay(pdMS_TO_TICKS(100 * (retry + 1)));
        if (vl->init()) { dist_ok = true; break; }
        ESP_LOGW(TAG, "VL53L0X init attempt %d/5 failed", retry + 1);
    }
    if (dist_ok) {
        ESP_LOGI(TAG, "VL53L0X ready");
    } else {
        ESP_LOGE(TAG, "VL53L0X init failed");
        delete vl;
        vl = nullptr;
    }

    int tick = 0;
    while (true) {
        if (vl) {
            uint16_t d = 0;
            if (vl->read(&d)) {
                s_distance_mm = d;
            }
        }
        if (s_temp_ok && (tick % 5 == 0)) {  // temp every ~500ms
            float t;
            if (read_temp_reg(0x06, &t)) s_temp_ambient = t;
            if (read_temp_reg(0x07, &t)) s_temp_object = t;
        }
        tick++;
        vTaskDelay(pdMS_TO_TICKS(100));
    }
}

extern "C" void sensors_init(void)
{
    xTaskCreate(sensors_task, "sensors", 4096, NULL, 3, NULL);
}

extern "C" int sensors_distance_mm(void) { return s_distance_mm; }
extern "C" float sensors_temp_ambient(void) { return s_temp_ambient; }
extern "C" float sensors_temp_object(void) { return s_temp_object; }
