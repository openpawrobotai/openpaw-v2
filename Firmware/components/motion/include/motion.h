// OpenPaw motion: DRV8833 drive motors + laser pointer + head-tilt servo.
//
// LEDC allocation (must not collide with the camera, which uses TIMER_1/CH4):
//   motors -> TIMER_0, channels 0..3
//   servo  -> TIMER_2, channel 5
#pragma once

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Init motors (DRV8833), laser (GPIO9), centre the servo, and start the
// ramp + safety-timeout tasks. Call once at boot.
void motion_init(void);

// Latch a drive/turn command (each -255..255). A ramp task eases toward it;
// a 2s safety timeout stops the motors if no fresh command arrives.
void motion_set_motor(int drive, int turn);

// Toggle the laser; returns the new on/off state.
bool motion_toggle_laser(void);
bool motion_laser_on(void);

// Last commanded drive/turn (for /status).
int motion_drive(void);
int motion_turn(void);

#ifdef __cplusplus
}
#endif
