#include "board_i2c.h"
#include "esp_log.h"

static const char *TAG = "board_i2c";
static i2c_master_bus_handle_t s_bus = NULL;

i2c_master_bus_handle_t board_i2c_bus(void)
{
    if (s_bus) {
        return s_bus;
    }
    i2c_master_bus_config_t cfg = {
        .i2c_port = I2C_NUM_0,
        .sda_io_num = 5,
        .scl_io_num = 6,
        .clk_source = I2C_CLK_SRC_DEFAULT,
        .glitch_ignore_cnt = 7,
        .flags = { .enable_internal_pullup = 1 },
    };
    if (i2c_new_master_bus(&cfg, &s_bus) != ESP_OK) {
        ESP_LOGE(TAG, "i2c_new_master_bus failed");
        s_bus = NULL;
    } else {
        ESP_LOGI(TAG, "Shared I2C bus ready (SDA=5, SCL=6)");
    }
    return s_bus;
}
