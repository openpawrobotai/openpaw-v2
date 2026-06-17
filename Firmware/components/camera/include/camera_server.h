// OpenPaw camera + control HTTP server (XIAO ESP32-S3 Sense / OV2640).
//
// Serves the contract the Flutter app expects:
//   port 80 : GET /status (JSON), GET /motor?drive=&turn=, GET /laser, GET /beep
//   port 81 : GET /stream  (multipart MJPEG)
//
// Sensor/motor endpoints are stubs for now (drivers land later); the camera
// stream is live. Call once the station has an IP.
#pragma once

#ifdef __cplusplus
extern "C" {
#endif

// Initialise the camera and start both HTTP servers. Idempotent.
void camera_server_start(void);

#ifdef __cplusplus
}
#endif
