idf_component_register(
    SRCS "sensors.cpp"
    INCLUDE_DIRS "include"
    REQUIRES driver board_i2c ESP32_VL53L0X
)
