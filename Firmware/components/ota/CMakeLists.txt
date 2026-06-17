idf_component_register(
    SRCS "ota_update.c"
    INCLUDE_DIRS "include"
    REQUIRES esp_https_ota esp_http_client app_update esp_app_format json esp-tls mbedtls
)
