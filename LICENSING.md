# Licensing

This project is licensed in three parts, because it is three kinds of work and
a software licence has nothing coherent to say about manufacturing a physical
object.

| What | Where | Licence |
|---|---|---|
| Firmware, application code, tooling | `Firmware/`, `Web/`, repository root | [Apache-2.0](LICENSE) |
| Mechanical CAD, PCB layouts, industrial design | `Mechanical/`, `Electrical/`, `Design/` | [CERN-OHL-S-2.0](Mechanical/LICENSE) |
| Documentation, photographs, video | `Docs/`, `Marketing/` | [CC BY-SA 4.0](Docs/LICENSE) |

## Why these, and not MIT

**Apache-2.0 rather than MIT.** Equally permissive in practice, but it carries
an explicit patent grant. This is robotics, the category has active patents, and
MIT is silent on them — which leaves contributors and users exposed to a risk
they did not choose.

**CERN-OHL-S rather than a software licence on the CAD.** CERN-OHL is the
open-hardware standard, and the strongly reciprocal variant means a modified
design has to stay open. That reciprocity is the point: under a permissive
hardware licence a larger manufacturer could take these files, close them, and
ship a product while contributing nothing back — using the only advantage this
project has against it.

It also makes the central promise enforceable rather than sentimental. If
everyone here stops, the design stays available and anyone may continue.

## Ownership, stated plainly

Ayva Labs sponsors this project: it funds development and staff time, and
manufactures and sells assembled units. It does not own or direct the project,
and the governance rules give it no casting vote on technical decisions, no
ability to close the design, and no gatekeeping on forks.

**Copyright currently sits with Ayva Labs** by default, because Ayva paid for
the work. Moving to contributor-held copyright is an outstanding legal step, not
a decision that has been taken — and this file says so rather than claiming a
community ownership the paperwork does not yet support.

The licences above already do the substantive work: under them, nobody — Ayva
included — can take this design private.

## V1 is not covered by any of this

The V1 repository replicates [ESP-ROLL](https://www.instructables.com/ESP-ROLL-Ball-Robot-With-Camera/)
by Max Imagination, published under CC BY-NC-SA — non-commercial, share-alike.
It is published for reference and credit only, is not relicensed, and is not
cleared for commercial use. See `NOTICE.md` in that repository.

V2 and V3 are independent designs. A two-wheeled companion with a tilting head
shares no mechanical design with a spherical ball-bot.
