# OpenPaw — Roadmap

## Product & business
- Enable & verify each sensor on hardware board
- Modify and document schematics (diff vs. original)
- Implement all sensors and finalize firmware
- Build Captive Portal for Wi-Fi setup & controls
- Build Flutter app for robot onboarding
- Research remote (public IP) access to robot
- Implement edge data collection & pet health capture
- Aggregate fleet data to build the pet AI model
- Ship the pet companion app (iOS + Android)
- Connect bank/monetization to unblock App Store

## Marketing (build in public)
- Launch social media pages (Instagram + Facebook)
- Produce social content tied to daily trends
- Outreach & collabs with pet businesses (groomers, pet shops)
- Automate devlog posts from firmware progress (see `openpaw-marketing`)

## Firmware build sequence (ordered)
1. Replicate ESP-32 Ball firmware with ESP-IDF
2. Add OTA support
3. Video recording of test
4. Extend ESP-32 Ball with laser pointer + temp sensors
5. Test on 2nd version of hardware
6. Video recording of test
7. Test firmware on the OpenPaw robot
8. Video recording of firmware
9. Extend Flutter app: video feed, remote control, sensor data
10. Add sensor data + video feed logging to Firebase bucket
11. Add remote viewing of video over internet on the mobile app
