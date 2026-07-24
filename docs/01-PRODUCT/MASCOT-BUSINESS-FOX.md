# Mascot — Business Fox (Tổng Tài)

**Status:** Mascot species DECIDED = **Business Fox** (Founder Direction,
2026-07-24). Resolves the last open item of WTM-11. Concept selection (pick 3
of 10) is pending Founder review — see the gallery.

## Founder Direction (verbatim intent)

```
Business Fox → AI Design Team → 10 concepts → pick the best 3
→ apply to: App icon · Splash · Onboarding · Empty State
           · AI Avatar · Loading · Marketing
```

## Why a fox fits Tổng Tài

- **Tổng Tài = "the Boss"** (I Like a Boss). A fox reads as *clever, resourceful,
  quick* — the trader's instinct — without arrogance. Concept 7 leans into the
  "Boss" idea directly (bow-tie + glasses).
- Foxes are **warm orange** — which is already Tổng Tài's `inventoryOrange`
  (#F59E0B), so the mascot sits inside the existing domain palette rather than
  fighting it.

## Palette (reuse of the domain tokens)

| Token | Hex | Mascot role |
|---|---|---|
| inventoryOrange | `#F59E0B` | fox primary coat |
| — burnt | `#C2410C` / `#EA580C` | inner ears, shadow facets |
| cream | `#FFF7ED` / `#FFFFFF` | muzzle, cheeks, tail tip |
| producerGreen | `#10B981` | badge ring (concept 3) |
| consumerBlue | `#3B82F6` | bow-tie, emblem ring |
| copilotViolet | `#A78BFA` | AI/tech accents (concept 6) |
| navy | `#111827` | eyes, nose, dark backgrounds |

## The 10 concepts

All are **self-contained SVG vector** files in
[`concepts/mascot/`](concepts/mascot/), one shared fox geometry (triangular
ears, angular snout, cream muzzle) varied by treatment. Each maps to the
touchpoint it suits best.

| # | Concept | Treatment | Best for |
|---|---|---|---|
| 1 | Geometric Minimal | flat 2-tone on navy | **App icon** |
| 2 | Friendly Flat | big eyes, blush, smile | **Onboarding · Empty State** |
| 3 | Bold Badge | fox in a green ring | App icon · Marketing |
| 4 | Monoline | single-weight line art | **Loading · small UI** |
| 5 | Gradient Modern | green→blue→violet fill | **Splash** |
| 6 | Tech Fox | circuit motif, violet eyes | **AI Avatar** |
| 7 | The Boss | seated, bow-tie + glasses | **Marketing · brand hero** |
| 8 | Origami Low-poly | faceted triangles | Splash · Marketing |
| 9 | Emblem Ring | front face in blue ring | AI Avatar · Loading spinner |
| 10 | Wink Mascot | winking, cheeky tongue | Empty State · Loading |

## Agent recommendation (Founder decides)

For a coherent system across every touchpoint, three concepts cover the whole
map with one visual language:

1. **Concept 1 — Geometric Minimal** → app icon (reads at 48px, strong on
   dark).
2. **Concept 5 — Gradient Modern** → splash + hero (uses the full domain
   gradient; feels premium).
3. **Concept 2 — Friendly Flat** → onboarding, empty states, in-app warmth
   (approachable for first-time SME sellers).

Concept 6 (Tech Fox) is the natural pick for the AI Copilot avatar if the
Founder wants a 4th; Concept 7 (Boss) is the marketing hero if brand
personality should be louder.

## Honest limitation

These are **AI-generated vector concepts** (code SVG), production-ready for the
vector touchpoints (icon, splash, loading, avatar, empty-state illustration).
High-fidelity **raster marketing art / rich onboarding illustration** is out of
a coding agent's reach — that needs a human illustrator or an image-generation
asset. Flagged in the application backlog so nothing is over-promised.

## Application pipeline (Jira)

Parent: **WTM-109** (this concept round). Application stories are created once
the Founder picks the 3 (or names specific concepts per touchpoint):
app icon + splash · AI avatar in chat · loading indicator · empty-state
illustrations · onboarding illustrations · marketing kit (flagged: needs
designer/image-gen).

Selection: Founder replies with the 3 concept numbers (or a per-touchpoint
mapping) on WTM-109; the agent then implements the in-app ones and updates
this doc + OPEN-DECISIONS.
