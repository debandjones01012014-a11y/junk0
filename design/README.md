# Design evolution

How the Junk0 name and icon came to be — every round, including the ideas that didn't make it.
All icons are drawn in code (Swift + Core Graphics); the scripts that produced each round are in
[`name-options/`](name-options) so any icon can be redrawn or tweaked.

<p align="center"><img src="name-options/ref-f-layers.png" width="200" alt="Final icon"><br><b>Final icon — Layers clear</b></p>

---

## 0. The original — Junk Cleaner

A gradient tile with white sparkles. Friendly, but generic, and the name was shared with dozens of apps.

<img src="name-options/icon-v1-junk-cleaner.png" width="120" alt="Original Junk Cleaner icon">

## 1. Naming

Candidates were checked against the Mac and iPhone App Stores, domains and GitHub:

| Name | Outcome |
|---|---|
| Tidy / Tidy Up | Taken by Mac apps; Apple also discourages "Mac" in app names |
| Spaceful, Broom, Sweepy, GigBack | Already used by storage-cleaner apps (GigBack and Sweepy on the Mac) |
| SpaceUp | Two iPhone storage cleaners with the same name |
| SpaceCheck | Free as one word, but sounds like a disk viewer, not a cleaner |
| JCB | A credit-card network and a construction-equipment brand — trademark risk |
| **Junk0** | **Chosen** — "junk, zeroed out"; no Mac app uses it |

## 2. First icons — letters and arrows

| SpaceUp A | SpaceUp B | Junk0 A | Junk0 B |
|---|---|---|---|
| <img src="name-options/spaceup-a.png" width="140"> | <img src="name-options/spaceup-b.png" width="140"> | <img src="name-options/junk0-a.png" width="140"> | <img src="name-options/junk0-b.png" width="140"> |

A refined "JØ" monogram followed:

<img src="name-options/junk0-pro.png" width="160" alt="JØ monogram">

**Verdict:** letter marks need a type designer's hand — the J and Ø didn't share a baseline and read as amateur.
Direction changed to **symbols, not letters**.

## 3. Symbol concepts

<img src="name-options/concepts-sheet.png" width="640" alt="Symbol concepts A, B, C at several sizes">

- **A · Zero ring** — the gap was moved to the top-right so it wouldn't read as a power button.
- **B · Layers clear** — stacked caches dissolving into sparkles. *The favourite.*
- **C · Clean disk** — clear, but closest to what other cleaners use.

## 4. Reference-driven round

Two references set the direction:
1. **Frame** — near-black tile, violet glow rising from the bottom edge, white → lavender symbol.
2. **Interior** — Swiss typographic poster: bold vertical bars, a crossing line, letters cut out as negative space.

<img src="name-options/ref-concepts-sheet.png" width="640" alt="Reference round: Layers, Zero cut, Cleared">

The "Zero cut" was refined twice — a strict 5-column grid and a true numeral zero (D2), then a rounder zero with
the bars removed and the horizontal line kept (D3):

| D · first try | D2 · strict grid | D3 · rounder zero, no bars |
|---|---|---|
| <img src="name-options/ref-d-zero-cut.png" width="160"> | <img src="name-options/ref-d2-zero-cut.png" width="160"> | <img src="name-options/ref-d3-zero.png" width="160"> |

<img src="name-options/ref-concepts-sheet-v3.png" width="640" alt="F, D2 and D3 compared at small sizes">

## 5. Final

D3 shipped briefly as the app icon (v2.1, tag `v2.1-zero-icon`). After seeing both on the GitHub page,
**F · Layers clear** became the icon for the app and the site (v2.2): it stays crisp down to 32 px and carries
the "caches clearing into sparkle" story without any text.

| Size check |
|---|
| <img src="name-options/ref-concepts-sheet-v2.png" width="640" alt="Small-size checks"> |

## Files

| Script | Draws |
|---|---|
| `name-options/icons.swift` | Round 2 — SpaceUp and Junk0 letter icons |
| `name-options/junk0-pro.swift` | Round 2 — refined JØ monogram |
| `name-options/concepts.swift` | Round 3 — zero ring, layers, disk |
| `name-options/ref-concepts.swift` | Round 4 — reference frame + D, D2, D3, E, F (final icon) |

Compile any of them with `swiftc <file> -o draw && ./draw <output-folder>`.
