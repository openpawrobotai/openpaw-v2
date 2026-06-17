idf_component_register(
    SRCS "ble_prov.c"
    INCLUDE_DIRS "include"
    REQUIRES bt nvs_flash json net esp_wifi esp_app_format
)
