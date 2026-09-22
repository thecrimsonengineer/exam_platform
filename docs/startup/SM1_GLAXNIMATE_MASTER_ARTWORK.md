# SM-1 — CSP11 Glaxnimate Master Artwork

## Purpose
This document freezes the first production vector language for the CSP11 startup animation.

## Master timeline
Canvas: 512 × 512
Frame rate: 30 fps
Duration: 144 frames / 4.8 seconds
Runtime export: Lottie JSON

### Frames 0–18 — ignition
- central core scales into view
- three concentric knowledge rings establish depth
- seven domain nodes appear progressively
- motion remains geometric and restrained

### Frames 18–52 — Learn
- two glass-like pages unfold from the core
- left and right pages use different CSP11 accent strokes
- the book disappears back toward the core rather than flying off-screen

### Frames 44–78 — Practice
- three target rings build concentrically
- the target briefly becomes the dominant symbol
- scale-in is used instead of a heavy spin

### Frames 70–106 — Decision LAB
- a central decision trunk appears
- the trunk splits into two routes
- two endpoint nodes make the branching model readable at a glance
- branch geometry remains abstract so the animation is not tied to a single scenario

### Frames 96–136 — Remember
- two rounded flashcards assemble
- the front card rotates subtly
- a memory dot appears at the card centre

### Frames 126–144 — convergence
- feature geometry collapses visually back into the knowledge core
- a final pulse prepares the Flutter overlay for its dissolve into the app

## Visual rules
- no text embedded in Lottie
- no raster images
- no remote assets
- no copyrighted third-party artwork
- no feature icon should depend on a platform font
- prefer rounded geometry and thin luminous strokes
- avoid excessive bloom that would fight the glassmorphism Home UI
- keep the core centered so the same asset works on phone, tablet, web and Windows

## Colour intent
The JSON stores normalized RGBA values and currently uses:
- near-white for the core
- cool blue for Learn / Practice structure
- cyan for memory and safe-route accents
- violet for secondary depth
- dark transparent fills for glass cards/pages

The Flutter screen owns the full-screen background and all readable text.

## Glaxnimate workflow
The production file `assets/startup/csp11_startup_master.json` is valid Lottie JSON and is the editable interchange master for this phase.

Open/import the Lottie JSON in Glaxnimate for visual refinement. Export back to the same Lottie path after editing. The Flutter code must not need to change when artwork is refined.

## Frozen SM-1 acceptance
- 512 × 512 vector master exists
- 144-frame sequence exists
- five feature beats exist
- seven domain nodes exist
- no learner data is embedded
- no network assets are required
- placeholder is no longer used by the startup screen
