# OpenPaw WebRTC remote-access signaling contract

Shared contract for the **robot** (`esp-webrtc`, offerer) and the **app**
(`flutter_webrtc`, answerer). Firebase Realtime Database is the signaling
channel — no signaling server to run.

## Roles
- **Robot = offerer.** It owns the camera, so it creates the SDP offer.
- **App = answerer.** It reads the offer and replies with an answer.
- `deviceId` = the robot's stable id (BT/Wi-Fi MAC, no colons, lowercase),
  e.g. `b8f862f87174`.

## RTDB schema (`<db>/webrtc/{deviceId}`)
```
webrtc/{deviceId}/
  session:   string   # random id the app sets to start a NEW call (forces robot to re-offer)
  offer:     {type:"offer",  sdp:"..."}    # written by robot
  answer:    {type:"answer", sdp:"..."}    # written by app
  robotCandidates/{pushId}: {candidate, sdpMid, sdpMLineIndex}   # robot ICE
  appCandidates/{pushId}:   {candidate, sdpMid, sdpMLineIndex}   # app ICE
  updatedAt: number   # ms epoch
```

## Flow
1. App writes a fresh `session` id (and clears `offer`/`answer`/`*Candidates`).
2. Robot sees the new `session`, creates offer, sets local description, writes `offer`.
3. App reads `offer`, sets remote description, creates answer, writes `answer`.
4. Each side writes its own ICE candidates as they're gathered and listens to the
   *other* side's candidate list, calling `addIceCandidate` for each new one.
5. DataChannel `control` carries the same JSON the HTTP control API uses
   (`{cmd:"motor",drive,turn}` / `{cmd:"laser"}` / `{cmd:"beep"}`) plus periodic
   `{status:{distance,temp_ambient,temp_object,laser,drive,turn}}` pushes.

## ICE servers
- STUN: `stun:stun.l.google.com:19302`
- TURN: required for symmetric-NAT fallback — managed (Cloudflare/Metered) for now.

## Auth / ownership
- `devices/{deviceId}/owner = <uid>` is written when the user pairs the robot.
- The robot authenticates to RTDB with a **device token handed over BLE** during
  Wi-Fi provisioning (extends the CRED characteristic), scoped to its own
  `webrtc/{deviceId}` path by the rules below.
