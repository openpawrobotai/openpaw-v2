# Signal → Sensor Map

Bridges the [veterinary indicators](canine-health-indicators.md) to OpenPaw's hardware/edge capabilities. Drives sensing requirements for #7 (edge data collection) and defines what the model (private `openpaw-ai`) is trained to flag.

| Vet indicator | Observable signal | Modality / sensor | Edge feature | What AI flags |
|---|---|---|---|---|
| Feeding habits (1,2) | bowl visits, eating duration | camera + motion near feeding zone | meals/day, time-at-bowl | sustained drop in appetite |
| Activity & energy (2) | movement frequency/range | IMU + motion detection | activity score / day | sudden lethargy |
| Coat condition (3,4) | shine, roughness, hair loss | periodic skin/coat photos | texture/colour features | dull coat, alopecia, mange patches |
| Biphasic fever (5) | body/ambient temp trend | temperature sensor | temp time-series | fever → recovery → fever |
| Mucous membranes (6,7) | gum / conjunctiva colour | close-up eye/gum photos | colour analysis | pale gums (possible anemia) |
| Behaviour change (8) | engagement, aggression | camera behaviour model | behaviour baseline + deviation | sudden disinterest / aggression |
| Rabies signs (9) | aggression, drooling | camera | drooling/aggression detection | classic rabies triad |
| Tail posture (10,11) | up vs tucked, wagging | camera pose estimation | tail-state classifier | prolonged tucked/inactive tail |
| Repetitive vices (12) | tail-chasing, self-biting | camera action recognition | repetitive-action detector | abnormal self-directed behaviour |

## Notes
- Capture imagery under **consistent conditions** (distance, lighting) so longitudinal comparison is valid — this consistency is a core advantage over ad-hoc owner photos.
- Correlate every signal with **breed, age, geography, ambient temperature** — the breed-specific, environment-aware angle is the dataset's edge over general models.
- All capture is **consent-gated**; see privacy policy (to be authored with legal).
