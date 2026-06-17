// OpenPaw sensors: MLX90614 IR temperature + VL53L0X time-of-flight distance,
// both on the shared I2C bus. A background task polls them; getters are cheap.
#pragma once

#ifdef __cplusplus
extern "C" {
#endif

// Probe both sensors and start the polling task. Call once after boot.
void sensors_init(void);

int   sensors_distance_mm(void);   // 0 if no reading
float sensors_temp_ambient(void);  // degrees C
float sensors_temp_object(void);   // degrees C

#ifdef __cplusplus
}
#endif
