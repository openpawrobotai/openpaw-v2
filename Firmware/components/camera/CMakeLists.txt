idf_component_register(
    SRCS "camera_server.c"
    INCLUDE_DIRS "include"
    REQUIRES esp_http_server esp32-camera motion sensors ota
)
