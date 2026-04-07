# Health Bar Prediction System

## Status

Draft — ready for implementation.

## Motivation

NivUI's unit frames currently display damage absorbs (shields like Power Word: Shield) but provide no visibility into two critical pieces of healing information:

1. **Heal absorbs** — debuffs like Necrotic Strike that consume incoming healing. Without seeing these, healers waste casts on targets whose healing is being eaten.
2. **Incoming heal prediction** — pending heals from other healers (or the player). Without this, multiple healers double-cast on the same target.

Both omissions matter most in dungeons and raids, where unit frames matter most.

This spec covers a unified refactor of the health bar update path. Heal absorbs and heal prediction are new display elements. The existing damage absorb display is preserved visually but migrated onto the same data pipeline so all four health-related values (current health, damage absorbs, heal absorbs, heal prediction) flow through a single `UnitHealPredictionCalculator` populated by a single API call per update. The refactor also adds user-configurable layering and overflow glow support to the damage absorb display.

## Goals

- Display heal absorbs as a magnitude indicator anchored to the HP bar's left edge, growing rightward as the absorb increases.
- Preserve the existing damage absorb visual (a magnitude indicator anchored to the HP bar's right edge, growing leftward as the shield increases), symmetric with heal absorbs.
- Display incoming heal prediction as an extension beyond current health, clamped to missing health.
- Display max HP reduction (debuffs that shrink a unit's maximum HP) by visually compressing the active HP region from the right and showing the lost portion with a distinct texture.
- Migrate all four data points (current health, damage absorbs, heal absorbs, heal prediction) onto a single `UnitHealPredictionCalculator` pipeline.
- Provide per-element configuration (toggle, color, and layering) for each prediction overlay, including the pre-existing damage absorb.
- Add overflow glows to both absorbs to signal when magnitude exceeds max HP.
- Maintain compatibility with the 12.0 secret value system: no Lua arithmetic, comparisons, or boolean tests on combat-derived values.

## Non-Goals

- This spec does not change the health bar's update frequency, animation, or smoothing behavior.
- This spec does not introduce per-healer prediction filtering beyond a binary "self vs all" choice.
- This spec does not implement true overheal estimation. It does enable the calculator's built-in incoming heal clamp (strict, overflow percent zero) as crude overheal clipping: predictions that would land past full health are clipped to missing health. Predictions that would overheal due to other factors (stacking absorbs, HoT ticks arriving later, etc.) are not accounted for.
- This spec does not add a numeric absorb text overlay. Numeric display is a separate widget concern.
- This spec does not address how the health bar handles the player being out of range or dead.

## Visual Design

### The Core Visual Model

The health bar is a canvas with four optional overlays drawn on top of the underlying green health fill. Each overlay is a full-width StatusBar positioned and filled using the MSUF anchoring trick (described in the Frame Construction section), which avoids Lua arithmetic on secret values by letting the C-side fill math compute proportions against a known full bar width.

The four overlays are:

- **Heal absorb** — anchored to the HP bar's LEFT edge, forward fill, grows rightward as absorb magnitude increases. Clamped to max HP.
- **Damage absorb** — anchored to the HP bar's RIGHT edge, reverse fill, grows leftward as shield magnitude increases. Clamped to max HP.
- **Heal prediction** — anchored to the live right edge of the health fill texture, forward fill, extends rightward into the empty portion of the bar. Clamped to missing health so it cannot overflow the right edge.
- **Health fill** — the standard green health bar, rendered by the existing health bar StatusBar. Not a new element; listed here for completeness.

Each overlay is rendered on top of the underlying health fill. When an overlay covers part of the green fill, the overlay's color replaces the green visually — this is intentional and expresses the overlay's magnitude as a proportion of the full bar.

### Example Layouts

**Example 1: healthy unit, 90% health, 30% shield, no other overlays.**

```
Green:  [=========.]   (0–90% fill)
Shield: [.......OOO]   (70–100%, grows from right edge)
Visible:[=======OOO]
```

The shield overlays the right 30% of the bar. Where the shield covers the green (70–90%), the shield color wins. The player can see at a glance that they have 30% of their max HP in shield magnitude.

**Example 2: low-HP unit with heal absorb.**

40% health, 20% heal absorb, no other overlays.

```
Green:       [====......]  (0–40% fill)
Heal Absorb: [##........]  (0–20%, grows from left edge)
Visible:     [##==......]
```

The heal absorb occupies the leftmost 20% of the bar. The player sees 20% heal absorb + 20% visible green + 60% empty, communicating both the absorb magnitude and the remaining healable health.

**Example 3: all four overlays active.**

80% health, 40% heal absorb, 10% incoming heal prediction, 30% damage absorb.

```
Green:      [========..]  (0–80% fill)
Heal Abs:   [####......]  (0–40%)
Heal Pred:  [........#.]  (80–90%, anchored to health fill edge)
Dmg Abs:    [.......OOO]  (70–100%)
Visible:    [####===OOO]
                     ^
                     damage absorb covers heal prediction in 80–90%
                     because damage absorb layer > heal prediction layer by default
```

Where overlays overlap, the user-configurable layering (`frameLevel` offsets) determines which wins. Default layering from bottom to top: heal prediction, damage absorb, heal absorb.

The example layouts above assume the unit's maximum HP is unmodified. When a max HP reduction is active, the bar's active region shrinks from the right and the lost portion is filled with a distinct texture; see the Max HP Reduction Display section below.

### Max HP Reduction Display

Some boss mechanics and debuffs reduce a unit's maximum HP. The clearest visual model: the bar's "active" region shrinks to match the reduced max, and the lost portion is shown at the right end of the bar with a distinct texture, signaling "this part of your max HP is gone."

This mirrors Blizzard's `TempMaxHealthLossMixin` pattern (used in `PlayerFrame`, `TargetFrame`, party frames, and the personal resource display): the actual health bar's pixel width is shrunk, and a secondary "lost max" StatusBar fills the remaining right portion of the original bar area with the special texture.

**Behavior:**

- The unit's reduction percentage is read via `GetUnitTotalModifiedMaxHealthPercent(unit)`, which returns a plain number in the range `[0, 1]` representing the fraction of the unit's max HP that remains active. `1.0` = unreduced, `0.7` = 30% reduced, etc. The value is clamped to `[0, 1]` defensively (Blizzard's mixin does this and so should we).
- The HP bar's pixel width is set to `originalBarWidth * fillPercent`. The original bar width is captured at frame init (or on layout/style change) and stored on the frame so it can be re-applied as the percentage changes.
- A secondary "lost max" StatusBar covers the original bar area, sits behind the HP bar, and fills its right `(1 - fillPercent)` portion via reverse fill.
- All prediction overlays (heal absorb, damage absorb, heal prediction) anchor to the HP bar's edges and the health fill texture, so they automatically scale and reposition with the shrunken HP bar. No special-case handling is required for the overlays; they compose correctly via the existing anchoring mechanism.
- When the reduction clears (`fillPercent` returns to `1.0`), the HP bar's pixel width returns to the original full width and the lost max bar is hidden.

**Texture source.**

The lost max bar's texture is user-configurable via the `tempMaxHealthLossTextureSource` field, with two options:

- `"blizzardAtlas"` (default) — use Blizzard's `TempMaxHealthLoss` atlas variants where they exist, matching the visual of Blizzard's default unit frames. The atlas is selected per frame type (see mapping below). For frame types that have no Blizzard atlas variant (raid, boss), this mode automatically falls back to the `"healthBarTexture"` behavior.
- `"healthBarTexture"` — reuse the healthBar's existing statusbar texture, tinted with `tempMaxHealthLossColor`. Consistent with NivUI's custom styling and works uniformly across all frame types.

**Atlas mapping per frame type** (used when `tempMaxHealthLossTextureSource = "blizzardAtlas"`):

| NivUI Frame          | Blizzard Atlas                                                  |
| -------------------- | --------------------------------------------------------------- |
| PlayerFrame          | `UI-HUD-UnitFrame-Player-PortraitOn-Bar-TempHPLoss`             |
| PartyFrame           | `UI-HUD-UnitFrame-Player-PortraitOn-Bar-TempHPLoss`             |
| TargetFrame (normal) | `UI-HUD-UnitFrame-Target-PortraitOn-Bar-TempHPLoss`             |
| TargetFrame (small)  | `UI-HUD-UnitFrame-Target-MinusMob-PortraitOn-Bar-TempHPLoss`    |
| FocusFrame           | `UI-HUD-UnitFrame-Target-PortraitOn-Bar-TempHPLoss`             |
| TargetOfTargetFrame  | `UI-HUD-UnitFrame-Target-MinusMob-PortraitOn-Bar-TempHPLoss`    |
| PetFrame             | `UI-HUD-UnitFrame-Target-MinusMob-PortraitOn-Bar-TempHPLoss`    |
| RaidFrame            | (no atlas; falls back to `healthBarTexture` mode)               |
| BossFrame            | (no atlas; falls back to `healthBarTexture` mode)               |

The TargetFrame's atlas should swap between the normal and MinusMob variants at runtime based on the target's classification, matching Blizzard's `TargetFrame.lua` behavior.

**Divider graphic not included.** Blizzard's `PlayerFrame` adds an optional divider graphic at the boundary between the active region and the lost max region (a three-piece assembly of divider, shadow, and mask). Only `PlayerFrame` uses it. This spec does not include the divider; the texture transition itself is sufficient signal.

### Overflow Glows

When either absorb's raw magnitude exceeds the unit's maximum health, the calculator clamps the displayed value to max HP and raises the `clamped` flag on that absorb. This triggers an **overflow glow** — a small texture rendered at the corresponding edge of the HP bar to signal "this value is larger than your max HP and you can't see the full magnitude in the bar."

- **Heal absorb overflow glow** renders at the LEFT edge of the HP bar.
- **Damage absorb overflow glow** renders at the RIGHT edge of the HP bar.

Each glow is independently configurable: separate enable toggle, color, and pixel width. Both default to enabled, ~3px wide, with bright saturated colors (red family for heal absorb glow, gold/yellow family for damage absorb glow).

Glow visibility is driven by the non-secret `clamped` boolean returned alongside each amount from the calculator. The `clamped` flag is safe to test with a Lua `if` statement.

### Color Defaults

All colors are user-configurable RGBA values. Defaults:

Color values use the existing NivUI convention: hash tables with `r`, `g`, `b`, `a` fields.

| Element                        | Default Color                                      |
| ------------------------------ | -------------------------------------------------- |
| Heal Absorb                    | `{ r = 0.40, g = 0.10, b = 0.10, a = 0.85 }`       |
| Heal Prediction                | `{ r = 0.40, g = 1.00, b = 0.40, a = 0.50 }`       |
| Damage Absorb                  | `{ r = 0.80, g = 0.80, b = 0.20, a = 0.50 }` (unchanged from current `absorbColor`) |
| Heal Absorb Overflow Glow      | `{ r = 1.00, g = 0.20, b = 0.20, a = 0.80 }`       |
| Damage Absorb Overflow Glow    | `{ r = 1.00, g = 0.80, b = 0.20, a = 0.80 }`       |
| Temp Max HP Loss (tinted mode) | `{ r = 0.20, g = 0.20, b = 0.20, a = 0.80 }`       |

### Layering

The three prediction overlays render on top of the health bar, and users can configure which sits on top of which via relative `frameLevel` offsets in the healthBar widget config. The offsets are relative to the healthBar's own `frameLevel`, matching the pattern the existing absorb bar uses today (hardcoded `+1`).

Default offsets, bottom to top:

| Overlay          | Default Offset | Rationale |
| ---------------- | -------------- | --------- |
| Heal Prediction  | +1             | Least time-sensitive; a forecast. Sits just above the health fill. |
| Damage Absorb    | +2             | Important but situational. Middle layer. |
| Heal Absorb      | +3             | Most urgent information for a healer. Top layer by default so it's never obscured. |

Overflow glows render one level above their corresponding overlay (e.g., the heal absorb overflow glow renders at the heal absorb bar's frameLevel + 1). This is handled internally and not exposed to the user.

### Heal Absorb Display Mode

The heal absorb amount displayed is the **full pending total**, not reduced by incoming heals. This reflects the actual debuff state and lets healers see the magnitude of the problem they need to solve, regardless of which heals are inbound from elsewhere.

This is implemented via `SetHealAbsorbMode(Enum.UnitHealAbsorbMode.Total)`. This is not user-configurable in v1.

## Calculator Integration

### Calculator Lifecycle

Each unit frame owns one `UnitHealPredictionCalculator` instance, created once during the frame's init path and stored on the frame. The calculator is reused across unit changes (e.g., when the target switches); it does not need to be recreated.

At init, the calculator is configured with these modes:

- **Maximum health mode**: `Default` — base max health, not adjusted for damage absorb shields.
- **Damage absorb clamp mode**: `MaximumHealth` — damage absorb display values are clamped to max HP. Shields larger than max HP have their display value capped, and the `clamped` flag is raised to drive the overflow glow.
- **Heal absorb clamp mode**: `MaximumHealth` — symmetric with damage absorbs. Heal absorbs larger than max HP have their display value capped, and the `clamped` flag drives the overflow glow.
- **Heal absorb mode**: `Total` — show the full pending heal absorb regardless of incoming heals.
- **Incoming heal clamp mode**: clamp to missing health (the calculator's standard "don't show overhealing" mode).
- **Incoming heal overflow percent**: `0` — strict clamping, no visual overflow past max HP.

These modes must be reapplied whenever a style is reapplied to the frame via the Designer, because they are per-instance state on the calculator and not part of the frame's saved style data.

### Update Path

The new `UpdateHealthBar` path replaces the existing direct calls to `UnitHealth`, `UnitHealthMax`, and `UnitGetTotalAbsorbs`. The new sequence is:

1. Look up max HP via `UnitHealthMax(unit)`. This is a plain number, not secret, and is safe for `SetMinMaxValues`.
2. Resolve the heal source unit from config: `"player"` if `healPredictionSource == "self"`, otherwise `nil`.
3. Call `UnitGetDetailedHealPrediction(unit, healSourceUnit, calculator)` to populate the calculator in one shot.
4. Retrieve values from the calculator:
   - `GetCurrentHealth()` — current health amount (may be secret)
   - `GetHealAbsorbs()` → `amount, clamped` (amount may be secret; `clamped` is a non-secret boolean)
   - `GetIncomingHeals()` — incoming heal amount (may be secret)
   - `GetDamageAbsorbs()` → `amount, clamped` (amount may be secret; `clamped` is a non-secret boolean)
5. Pass amount values directly to their corresponding StatusBar `SetValue` calls. **No Lua arithmetic, comparisons, or boolean tests on any amount value.** The `clamped` flags are safe to test because they are plain Lua booleans returned by the calculator alongside the amounts.

## Frame Construction

This section specifies the frame structure required to implement the visual model. The key insight is the MSUF anchoring trick: by giving every prediction StatusBar the full HP bar width as its frame width and letting the C-side fill math compute `(value / max) * fullBarWidth`, the segment size is always correct regardless of where the bar is anchored. Lua never performs arithmetic on secret values.

### Frames Owned by Each Unit Frame

A unit frame with prediction support owns the following display elements:

- **Lost max bar** — a StatusBar, sibling to the HP bar (not a child), covers the original HP bar area, sits behind the HP bar at a lower frame level, reverse fill. Used for the max HP reduction display. Its texture is set per frame type (see Atlas mapping in the Visual Design section). When `tempMaxHealthLossTextureSource = "healthBarTexture"`, the texture is the healthBar's statusbar texture tinted with the configured color.
- **Heal absorb bar** — a StatusBar, parented to the HP bar, full HP bar width, left edge anchored to the HP bar's left edge, forward fill. Used for the left-side heal absorb indicator.
- **Damage absorb bar** — a StatusBar, parented to the HP bar, full HP bar width, right edge anchored to the HP bar's right edge, reverse fill. Used for the right-side shield indicator. Replaces the existing hardcoded absorb bar.
- **Heal prediction bar** — a StatusBar, parented to the HP bar, full HP bar width, left edge anchored to the live right edge of the health fill texture, forward fill. Used for incoming heal prediction.
- **Heal absorb overflow glow** — a thin texture anchored to the HP bar's left edge. Visibility driven by the `clamped` flag from `GetHealAbsorbs()`.
- **Damage absorb overflow glow** — a thin texture anchored to the HP bar's right edge. Visibility driven by the `clamped` flag from `GetDamageAbsorbs()`.

The original HP bar pixel width is captured at frame init (and re-captured on layout/style change) and stored on the frame as `frame.originalHpBarWidth`. This is the reference width used to compute the shrunken HP bar width and the lost max bar size. The HP bar's actual pixel width is set to `frame.originalHpBarWidth * fillPercent` per update.

All bars and glows are created hidden and shown only when their corresponding `show*` config flag is enabled.

There is **no** clip frame. Because both absorbs are clamped to max HP and heal prediction is clamped to missing health, none of the bars can render past the HP bar's bounds. No clipping is required.

### Init Sequence

When the unit frame is constructed:

1. Create the calculator instance and store it on the frame. Apply the six calculator mode settings from the Calculator Lifecycle section. Store these settings so a style reapplication can re-run this step.
2. Create the heal absorb bar, damage absorb bar, and heal prediction bar as children of the HP bar. Apply their configured colors. Set their `frameLevel` to `hpBar:GetFrameLevel() + offset` for their respective offset from config. Leave them hidden and unanchored; per-update anchors them.
3. Create the two overflow glow textures as children of the HP bar. Set their colors, widths, and frame levels (each glow sits one level above its corresponding bar). Leave them hidden.
4. Retire the existing hardcoded absorb bar and its `frameLevel + 1` logic. The new damage absorb bar replaces it entirely.

### Per-Update Sequence

`UpdateHealthBar` is invoked on `UNIT_HEALTH`, `UNIT_MAXHEALTH`, `UNIT_ABSORB_AMOUNT_CHANGED`, `UNIT_HEAL_ABSORB_AMOUNT_CHANGED`, `UNIT_HEAL_PREDICTION`, and on style/layout changes. Pseudocode:

```
function UpdateHealthBar(frame, unit):
    maxHP ← UnitHealthMax(unit)
    if maxHP is nil: abort

    healSource ← "player" if config.healPredictionSource == "self" else nil
    UnitGetDetailedHealPrediction(unit, healSource, frame.calculator)

    # Apply max HP reduction first — this resizes the HP bar's pixel width,
    # which the prediction overlays will then anchor to.
    UpdateMaxHealthLossDisplay(frame, unit)

    # Main health bar — pass secret value straight through
    hpBar.minMax ← (0, maxHP)
    hpBar.value  ← frame.calculator.GetCurrentHealth()

    UpdateHealAbsorbDisplay(frame, maxHP)
    UpdateDamageAbsorbDisplay(frame, maxHP)
    UpdateHealPredictionDisplay(frame, maxHP)
```

Order matters: `UpdateMaxHealthLossDisplay` runs first because it changes `hpBar:GetWidth()`, and the prediction overlays read that width to size themselves. Running them in any other order would leave them sized to the previous width for one frame.

#### UpdateMaxHealthLossDisplay

```
function UpdateMaxHealthLossDisplay(frame, unit):
    if not config.showTempMaxHealthLoss:
        # Restore HP bar to full original width and hide the lost max bar
        hpBar.width ← frame.originalHpBarWidth
        hide lostMaxBar
        return

    fillPercent ← GetUnitTotalModifiedMaxHealthPercent(unit)
    clamp fillPercent to [0, 1]                            # plain number, no secrets

    # Resize the HP bar to match the active max
    hpBar.width ← frame.originalHpBarWidth * fillPercent

    if fillPercent ≥ 1.0:
        hide lostMaxBar
        return

    # Configure the lost max bar to fill the right (1 - fillPercent) of the original area
    lostMaxBar.width ← frame.originalHpBarWidth
    lostMaxBar.minMax ← (0, 1)
    lostMaxBar.value  ← (1 - fillPercent)
    lostMaxBar.reverseFill ← true
    show lostMaxBar
```

The `fillPercent` clamping is defensive against the API ever returning a value slightly outside the documented `[0, 1]` range. Both operands of the multiplication and subtraction are plain numbers (not secrets), so the arithmetic is safe.

When the HP bar's pixel width changes here, the prediction overlays' cached "last applied bar width" becomes stale. The implementation must invalidate that cache so the next per-update call re-anchors the overlays. The simplest approach: call the existing re-anchoring logic at the end of `UpdateMaxHealthLossDisplay` if the width changed.

#### UpdateHealAbsorbDisplay

```
function UpdateHealAbsorbDisplay(frame, maxHP):
    if not config.showHealAbsorb:
        hide healAbsorbBar
        hide healAbsorbOverflowGlow
        return

    barWidth ← hpBar.GetWidth()
    if barWidth ≤ 0: return

    healAbsorbBar.width ← barWidth                        # full HP bar width, plain number
    anchor healAbsorbBar.TOPLEFT    to hpBar.TOPLEFT
    anchor healAbsorbBar.BOTTOMLEFT to hpBar.BOTTOMLEFT
    healAbsorbBar.reverseFill ← false
    healAbsorbBar.minMax ← (0, maxHP)

    amount, clamped ← frame.calculator.GetHealAbsorbs()
    healAbsorbBar.value ← amount                          # secret, passed through
    show healAbsorbBar

    # Overflow glow driven by the non-secret clamped flag
    if config.showHealAbsorbOverflowGlow and clamped:
        show healAbsorbOverflowGlow
    else:
        hide healAbsorbOverflowGlow
```

#### UpdateDamageAbsorbDisplay

```
function UpdateDamageAbsorbDisplay(frame, maxHP):
    if not config.showDamageAbsorb:
        hide damageAbsorbBar
        hide damageAbsorbOverflowGlow
        return

    barWidth ← hpBar.GetWidth()
    if barWidth ≤ 0: return

    damageAbsorbBar.width ← barWidth
    anchor damageAbsorbBar.TOPRIGHT    to hpBar.TOPRIGHT
    anchor damageAbsorbBar.BOTTOMRIGHT to hpBar.BOTTOMRIGHT
    damageAbsorbBar.reverseFill ← true
    damageAbsorbBar.minMax ← (0, maxHP)

    amount, clamped ← frame.calculator.GetDamageAbsorbs()
    damageAbsorbBar.value ← amount
    show damageAbsorbBar

    if config.showDamageAbsorbOverflowGlow and clamped:
        show damageAbsorbOverflowGlow
    else:
        hide damageAbsorbOverflowGlow
```

#### UpdateHealPredictionDisplay

Heal prediction extends rightward from the live right edge of the health fill texture. This is the only overlay that anchors to the moving health fill edge; the two absorbs anchor to fixed HP bar edges.

```
function UpdateHealPredictionDisplay(frame, maxHP):
    if not config.showHealPrediction:
        hide healPredictionBar
        return

    hpTex ← hpBar.GetStatusBarTexture()
    barWidth ← hpBar.GetWidth()
    if hpTex is nil or barWidth ≤ 0: return

    healPredictionBar.width ← barWidth
    anchor healPredictionBar.TOPLEFT    to hpTex.TOPRIGHT
    anchor healPredictionBar.BOTTOMLEFT to hpTex.BOTTOMRIGHT
    healPredictionBar.reverseFill ← false
    healPredictionBar.minMax ← (0, maxHP)
    healPredictionBar.value  ← frame.calculator.GetIncomingHeals()
    show healPredictionBar
```

Because `IncomingHealClampMode` is set to clamp to missing health and `IncomingHealOverflowPercent` is zero, the calculator guarantees `incomingHeals ≤ (maxHealth - currentHealth)`. The C-side fill math renders the bar at exactly the portion of the empty space the prediction will cover; it cannot overflow the HP bar's right edge.

### Why the Anchoring Trick Works

A StatusBar fills `(value / max) * frameWidth` of pixels in C, against its own current frame width. By giving every prediction bar the **full HP bar width** as its frame width, the proportion is computed against the correct denominator (max HP), regardless of where the bar's outer edge is anchored. The anchor points determine *where the segment starts*, not *how wide the segment is*. Lua never touches a secret value except to pass it directly through to `SetValue`.

- Heal absorb anchors its LEFT edge to the HP bar's left edge, forward fill → segment grows rightward from the bar's left edge.
- Damage absorb anchors its RIGHT edge to the HP bar's right edge, reverse fill → segment grows leftward from the bar's right edge.
- Heal prediction anchors its LEFT edge to the live health fill texture's right edge, forward fill → segment grows rightward from wherever the green fill currently ends.

### Re-anchoring on Resize

The anchoring described above must be re-applied whenever any of the following changes:

- The HP bar's pixel width (layout change, frame style switch, edit mode resize).
- Which prediction overlays are enabled.

The implementation should cache the last-applied bar width and skip redundant re-anchoring when it has not changed. The MSUF reference implementation has this caching pattern.

**Reverse-fill HP bars are out of scope.** NivUI does not currently use reverse fill on health bars, and this spec does not define behavior for that case. The implementation may assume forward fill.

## Configuration Schema

The `healthBar` widget config gains the following fields. All new toggles default to false (opt-in) except the overflow glows, which default to true. Existing fields are preserved except for the rename of `showAbsorb` to `showDamageAbsorb`.

RGBA fields follow the existing NivUI convention: hash tables with `r`, `g`, `b`, `a` fields.

| Field                             | Type    | Default                                              | Notes |
| --------------------------------- | ------- | ---------------------------------------------------- | ----- |
| `showDamageAbsorb`                | boolean | `true`                                               | Renamed from `showAbsorb`. Default preserves existing user behavior. |
| `absorbColor`                     | RGBA    | `{ r = 0.80, g = 0.80, b = 0.20, a = 0.50 }`         | Existing field, untouched. |
| `damageAbsorbFrameLevelOffset`    | integer | `2`                                                  | Relative to healthBar's frameLevel. |
| `showHealAbsorb`                  | boolean | `false`                                              | New, opt-in. |
| `healAbsorbColor`                 | RGBA    | `{ r = 0.40, g = 0.10, b = 0.10, a = 0.85 }`         | Dark red. |
| `healAbsorbFrameLevelOffset`      | integer | `3`                                                  | Relative. Default puts heal absorb on top of damage absorb. |
| `showHealPrediction`              | boolean | `false`                                              | New, opt-in. |
| `healPredictionColor`             | RGBA    | `{ r = 0.40, g = 1.00, b = 0.40, a = 0.50 }`         | Light translucent green. |
| `healPredictionSource`            | string  | `"all"`                                              | One of `"all"`, `"self"`. |
| `healPredictionFrameLevelOffset`  | integer | `1`                                                  | Relative. Default puts heal prediction at the bottom of the overlay stack. |
| `showHealAbsorbOverflowGlow`      | boolean | `true`                                               | Heal absorb overflow glow (left edge of bar). |
| `healAbsorbOverflowGlowColor`     | RGBA    | `{ r = 1.00, g = 0.20, b = 0.20, a = 0.80 }`         | Bright red. |
| `healAbsorbOverflowGlowWidth`     | integer | `3`                                                  | Pixels. |
| `showDamageAbsorbOverflowGlow`    | boolean | `true`                                               | Damage absorb overflow glow (right edge of bar). |
| `damageAbsorbOverflowGlowColor`   | RGBA    | `{ r = 1.00, g = 0.80, b = 0.20, a = 0.80 }`         | Gold. |
| `damageAbsorbOverflowGlowWidth`   | integer | `3`                                                  | Pixels. |
| `showTempMaxHealthLoss`           | boolean | `true`                                               | Max HP reduction display. Default on because it's always useful when it applies and has no cost when it doesn't. |
| `tempMaxHealthLossTextureSource`  | string  | `"blizzardAtlas"`                                    | One of `"blizzardAtlas"`, `"healthBarTexture"`. |
| `tempMaxHealthLossColor`          | RGBA    | `{ r = 0.20, g = 0.20, b = 0.20, a = 0.80 }`         | Used when source is `"healthBarTexture"` or when atlas mode falls back on raid/boss frames. Dark gray signals "inactive/lost" without looking like alarm. |

When all three `show*` overlay flags are false, the calculator is still used internally for the main health value (single source of truth), but no overlay bars are created or updated. The calculator overhead is minimal (one C call per update) and centralizing the data path is worth more than the savings from skipping it.

### Designer UI

The Designer's healthBar widget config tab gains:

- A toggle, color picker, and frameLevel offset slider for "Heal Absorbs"
- A toggle, color picker, and frameLevel offset slider for "Heal Prediction", plus a "Heal Source" dropdown with options "All Healers" and "Only Me"
- A toggle, color picker, and width slider for each overflow glow
- A frameLevel offset slider for Damage Absorbs (the existing damage absorb toggle and color picker remain)
- The existing damage absorb toggle is renamed in the UI from "Show Absorbs" to "Show Damage Absorbs"
- A toggle for "Temp Max HP Loss", a "Texture Source" dropdown with options "Blizzard Atlas" and "Health Bar Texture", and a color picker for the tinted-mode color

Overlay controls are disabled when their parent toggle is off. Overflow glow controls are disabled when the corresponding overlay toggle is off. The temp max HP loss color picker is enabled regardless of texture source (it's used directly by `"healthBarTexture"` mode and as the fallback color in `"blizzardAtlas"` mode).

## Configuration Migration

The rename of `showAbsorb` to `showDamageAbsorb` requires a one-time migration of existing user configs. The migration runs once on addon load, after saved variables are loaded but before any unit frame is constructed.

For each unit frame style in saved variables, the migration walks the style's `healthBar` widget config and, if `showAbsorb` is set and `showDamageAbsorb` is not, copies the value from the old field to the new and clears the old field. This is idempotent: running it a second time on already-migrated data does nothing because the precondition fails.

The migration is gated by a saved variable flag `migrations.healthBarShowAbsorbRename`, set to true after the migration runs successfully. This prevents the migration from running on every load and provides a clear marker for debugging.

New fields introduced by this spec (`showHealAbsorb`, `healAbsorbColor`, frameLevel offsets, overflow glow fields, etc.) are populated from defaults on first load via the existing default-merge path and do not require explicit migration.

## Events

The unit frame must register the following events to keep the prediction display fresh.

| Event                                 | Currently Registered? | After This Spec |
| ------------------------------------- | --------------------- | --------------- |
| `UNIT_HEALTH`                         | Yes                   | Yes             |
| `UNIT_MAXHEALTH`                      | Yes                   | Yes             |
| `UNIT_ABSORB_AMOUNT_CHANGED`          | Yes                   | Yes             |
| `UNIT_HEAL_ABSORB_AMOUNT_CHANGED`     | **No (add)**          | Yes             |
| `UNIT_HEAL_PREDICTION`                | **No (add)**          | Yes             |
| `UNIT_MAX_HEALTH_MODIFIERS_CHANGED`   | **No (add)**          | Yes             |

All six events trigger the same `UpdateHealthBar` path. The calculator is repopulated on every event so the display stays consistent across all overlays, and the max HP reduction is re-read so the bar's pixel width is current.

## Edge Cases

The following cases are explicitly handled by this spec:

1. **Unit becomes invalid mid-update.** If `UnitHealthMax` returns nil for a unit that no longer exists, the update path aborts cleanly at the top and leaves the bars in their previous state. The existing invalid-unit handling in the unit frame base continues to apply.
2. **Heal absorb exceeds max HP.** The calculator clamps the display value to max HP, the heal absorb bar renders at full width, and the `clamped` flag triggers the left-edge overflow glow (if enabled). The player sees an entirely-absorb-colored bar on the left side with a glow, signaling the critical state.
3. **Damage absorb exceeds max HP.** Symmetric. Shield bar renders at full width, right-edge glow lights up.
4. **Heal absorb overlay is disabled but absorb is non-zero.** The calculator still computes the value, but the overlay bar and glow are hidden. Health bar displays normally with no indication of the absorb. This is the user's explicit choice.
5. **All three overlays disabled.** The calculator runs but only `GetCurrentHealth` and `GetMaximumHealth` results are used. This is the minimal code path that replaces today's `UnitHealth` / `UnitHealthMax` calls.
6. **Frame is hidden.** Overlays do not update while the frame is hidden. On show, a single `UpdateHealthBar` call refreshes everything.
7. **Style switch via Designer.** When a style is reapplied, the calculator's clamp modes must be reconfigured (they are per-instance state, not saved with the style). Any frameLevel offset changes must also be reapplied to each bar and glow.
8. **Pet, vehicle, or possessed unit.** The calculator works on any valid unit ID without special handling. The heal prediction `"self"` source filter always resolves to `"player"` (the player character's heals), even when the player is in a vehicle. Vehicle healing is rare in modern WoW and the simpler behavior is preferred.
9. **Overlapping overlays (e.g., low HP + large heal absorb + large shield).** The heal absorb and damage absorb can visually overlap when their combined magnitude is large relative to max HP. The user-configured `frameLevel` offsets determine which overlay paints on top in the overlap region. Default layering: heal absorb > damage absorb > heal prediction.
10. **HP bar resized after frame init.** The implementation must re-anchor the heal absorb, damage absorb, and heal prediction bars whenever the HP bar's width changes. A cache-and-compare on the last-applied width works.
11. **Heal prediction would overheal.** `IncomingHealClampMode` with overflow percent zero clamps the prediction to missing health. The calculator returns a clamped value, the bar fills only the empty portion of the HP bar, and no visual overflow occurs.
12. **Max HP reduction lands or clears.** `UNIT_MAX_HEALTH_MODIFIERS_CHANGED` fires; the update path resizes the HP bar's pixel width and re-anchors the prediction overlays (which automatically scale to the new width via the existing anchoring logic). When the reduction clears, `fillPercent` returns to `1.0`, the HP bar returns to its original width, and the lost max bar hides.
13. **Max HP reduction larger than current max would imply.** `GetUnitTotalModifiedMaxHealthPercent` is clamped defensively to `[0, 1]` before use. Values outside the documented range are treated as the nearest endpoint.
14. **Atlas mode falls back on raid/boss frames.** When `tempMaxHealthLossTextureSource = "blizzardAtlas"` and the frame type has no Blizzard atlas variant (RaidFrame, BossFrame), the lost max bar uses the healthBar's statusbar texture tinted with `tempMaxHealthLossColor`. The fallback is automatic and not exposed to the user.
15. **Max HP reduction overlaps with prediction overlays.** When the HP bar shrinks, all prediction overlays automatically reposition because they anchor to `hpBar:GetWidth()` and `hpBar:GetStatusBarTexture()`. A heal absorb of fixed magnitude appears as a larger fraction of the shrunken bar (correct: it's a larger fraction of the unit's effective max HP). The overflow glow logic continues to work because the calculator's clamping uses the unit's current effective max.

## Testing Plan

Niv tests in WoW directly. The following scenarios should be covered:

1. **Healthy unit, no absorbs, no incoming heals** — only the green health bar is visible. All overlays hidden.
2. **Damaged unit, damage absorb only** — green fill plus a shield segment anchored to the right edge of the bar, growing leftward, covering the right portion of the green fill when the shield is large enough.
3. **Damaged unit, heal absorb only** — green fill plus a heal absorb segment anchored to the left edge of the bar, growing rightward, covering the left portion of the green fill when the absorb is large enough.
4. **Unit with heal absorb larger than max HP** — heal absorb bar fills the entire HP bar, left-edge overflow glow appears.
5. **Unit with shield larger than max HP** — damage absorb bar fills the entire HP bar, right-edge overflow glow appears.
6. **Damaged unit, incoming heals only, source `"all"`** — green fill plus heal prediction segment extending rightward from the health fill edge into the empty portion.
7. **Damaged unit, incoming heals only, source `"self"`** — heal prediction shows only the player's own heals. Validate with a party member also healing the target.
8. **Damaged unit with incoming heals that would overheal** — heal prediction is clipped at the HP bar's right edge; no visual overflow.
9. **Damaged unit, all four overlays simultaneously** — heal absorb on left, damage absorb on right, heal prediction in the empty portion, green health in the middle where not covered. Default layering produces the expected paint order.
10. **Change frameLevel offsets via Designer** — reorder the overlays (e.g., put heal prediction on top) and verify the paint order changes.
11. **Toggle overflow glows off** — when the toggle is off, even a max-HP-exceeding absorb produces no glow.
12. **Player in vehicle, source `"self"`** — the heal prediction filter tracks the player character's heals, not vehicle heals.
13. **Style switch via Designer** — change a style's prediction config while the frame is visible; display updates immediately and correctly.
14. **Frame hidden then shown** — on show, the display refreshes immediately to current state.
15. **Pet frame** — overlays work on the pet unit.
16. **Raid frame** — overlays render correctly on the smaller raid frame size.
17. **Migration from a saved variable with `showAbsorb` set** — after upgrade, the saved variable has `showDamageAbsorb` with the same value and `showAbsorb` is cleared. The `migrations.healthBarShowAbsorbRename` flag is set.
18. **Max HP reduction lands** — apply a debuff that reduces the unit's max HP (e.g., a boss mechanic). The HP bar's active region shrinks from the right and the lost max region appears with the configured texture. Existing prediction overlays scale correctly and stay anchored to the shrunken bar.
19. **Max HP reduction clears** — remove the debuff. The HP bar returns to its original width, the lost max region disappears, and the prediction overlays return to their original sizes.
20. **Texture source = `"blizzardAtlas"` on Player, Target, Party** — verify the correct Blizzard atlas variant is shown for each frame type.
21. **Texture source = `"blizzardAtlas"` on Raid and Boss** — verify the fallback to the healthBar texture with the configured color works on frame types that have no atlas variant.
22. **Texture source = `"healthBarTexture"`** — verify all frame types use the healthBar texture tinted with the configured color, regardless of whether a Blizzard atlas exists for that frame type.
23. **TargetFrame classification swap** — target a small/minor mob (which uses the MinusMob atlas variant) and verify the atlas swaps correctly. Then target a normal mob and verify it swaps back.
24. **Max HP reduction with `showTempMaxHealthLoss = false`** — the bar stays full width and the lost max region is never shown, even when a reduction is active.

## Reference Implementations

- `../midnightsimpleunitframes/MidnightSimpleUnitFrames/Core/MSUF_Bars.lua` — the original source of the full-width StatusBar + C-side fill math technique this spec adapts. MSUF applies the technique to anchor absorb bars to the *live health fill edge* (mode 3 for heal absorbs, mode 1 for damage absorbs). This spec borrows the same underlying mechanism (full-width bar, anchor to an edge, let C compute the proportion) but applies it to the *fixed HP bar edges* instead of the moving health fill edge. The result is a simpler implementation: no clip frame is needed because both absorb values are clamped to max HP, so their fill widths can never exceed the HP bar. The only overlay in this spec that anchors to the live health fill edge is heal prediction, and it is clamped to missing health, so its fill also cannot overflow.
- `../platynator/Display/HealthBar.lua` — clean reference for the calculator-based health bar update pattern. Does not implement heal absorbs; useful only as a shape reference for how to create, configure, and populate a `UnitHealPredictionCalculator` per frame.
- `../wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitHealPredictionCalculatorAPIDocumentation.lua` — full method list for `UnitHealPredictionCalculator`. Canonical source for clamp mode enum values and setter signatures.
- `../wow-ui-source/Interface/AddOns/Blizzard_UnitFrame/Shared/UnitFrame.lua` (lines 1-53) — `TempMaxHealthLossMixin`, the canonical reference for the max HP reduction display mechanism. Defines the bar resize + secondary fill bar pattern.
- `../wow-ui-source/Interface/AddOns/Blizzard_UnitFrame/Mainline/TargetFrame.lua` (lines 389, 415) — example of swapping the atlas at runtime based on target classification. Use this pattern for the NivUI TargetFrame's atlas swap.
- `../wow-ui-source/Interface/AddOns/Blizzard_UnitFrame/Mainline/PlayerFrame.xml` (line 145), `TargetFrame.xml` (line 224), `PartyFrameTemplates.xml` (line 144) — atlas declarations for the player, target, and party frames. Use these to confirm atlas names if any have been renamed.
- `../wow-ui-source/Interface/AddOns/Blizzard_PersonalResourceDisplay/Blizzard_PersonalResourceDisplay.lua` (lines 235-301) — full consumer example of the `TempMaxHealthLossMixin` pattern.
