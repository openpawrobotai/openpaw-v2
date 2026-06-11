# 🐾 openpaw-ml

Python home for OpenPaw's pet-health intelligence: the **open knowledge base & signal mapping**, plus the tooling to train models. Open source (MIT).

> Part of [OpenPaw](https://github.com/ayvalabs) by Ayva Labs. Maintainer: **@aeropriest**.

## ⚠️ What is and isn't here
- **Public (this repo):** the veterinary knowledge base, signal→sensor mapping, data schemas, training/eval code.
- **Private (`openpaw-ai`):** the proprietary collected dataset and trained model weights — **the moat**. They are never committed here.

## Layout
```
openpaw-ml/
├── knowledge/
│   ├── canine-health-indicators.md   vet knowledge, structured
│   └── signal-to-sensor-map.md       indicator → sensor → AI flag
├── src/openpaw_ml/                   training/eval/feature code
├── notebooks/                        exploration
└── data/                             LOCAL ONLY — gitignored (never commit pet data)
```

## Setup
```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -e .
```

## Principles
- Surfaces early-warning signals — **not** diagnoses; never replaces a vet.
- Consent-gated capture; privacy first.
- Breed-, age-, and environment-aware — the edge over general models.

## License
MIT © 2026 aeropriest
