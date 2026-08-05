# AuraContainer API Reference (12.1.0)

Compiled by Claire, 2026-08-05, from the actual Blizzard_AuraContainer source at the
[Gethe 12.1.0 tag](https://github.com/Gethe/wow-ui-source/tree/12.1.0/Interface/AddOns/Blizzard_AuraContainer)
(local copies in `docs/blizzard-aura-source/`) plus the
[12.1.0 API changes blue posts](https://warcraft.wiki.gg/wiki/Patch_12.1.0/API_changes).
This supersedes the API sketch in PTR-12.1-FINDINGS.md §4 where they disagree.
Field names below are quoted from the source validators—they are exact.

## 1. Container creation

```lua
local container = CreateFrame("AuraContainer", nil, parent, "CustomAuraContainerTemplate")
container:SetSize(1, 1)          -- flow layout overwrites this (with SECRET dimensions)
container:SetPoint(...)          -- normal anchoring; we position it, it sizes itself
container:SetUnit(unit)
```

- Containers **can** be created during combat (PTR 7).
- Multiple containers per unit are fine—nothing in the source registers per-unit
  singletons. A container is just a frame with mixins.
- Containers get the `EventRegistrations` forbidden aspect (no addon event
  registration on them). Adding a group also applies
  `UntrustedLayoutScriptExecution` to the container: no `OnSizeChanged` on it
  or on frames anchored **to** it. Anchoring the container to our frames is
  unaffected (direction matters).
- Container auto-resize sets a **secret size** (`OnLayoutComplete` →
  `SetSize(secretwrap(w, h))`). Never anchor NivUI frames to the container and
  never read its size.
- `ClearAuraGroups` is intentionally **not** exposed to addons ("prefer
  reconfiguring filters"). To remove an overlay's display entirely, the whole
  container must be destroyed/abandoned and rebuilt (out of combat), or its
  filters mutated to match nothing.
- When a container is disabled (`Disable`?—PTR 8 note), all its AuraButtons
  and ItemEnchantments are cleared.

## 2. AddAuraGroup

```lua
container:AddAuraGroup(groupKey --[[non-empty string]], filterString, options)
```

Options table (defaults from `CustomAuraContainerGroupDefaultOptions`):

| Field | Type | Default | Notes |
|---|---|---|---|
| `maxFrameCount` | non-negative integer or `math.huge` | `math.huge` | our `maxIcons` |
| `templateNames` | table of template names | nil | inherited after `CustomAuraButtonTemplate` |
| `initializeFrame` | `function(auraButton)` | nil | called per button, before access restrictions applied |
| `candidateFilters` | table (§5) | nil | |
| `sortMethod` | `AuraContainerSortMethod` | `Default` | |
| `sortDirection` | `AuraContainerSortDirection` | `Normal` | |
| `layout` | table (§4 per-group options) | nil | |

Buttons are created in batches of 10 (`FrameCreationBatchSize`); one batch is
pre-allocated at `AddAuraGroup` time so addons can't observe the zero→nonzero
transition.

Post-creation mutators (all on the container):
`SetAuraGroupFilterString(groupKey, filterString)`,
`SetAuraGroupMaxFrameCount(groupKey, n)`,
`SetAuraGroupCandidateFilters(groupKey, filters)`,
`SetAuraGroupSortMethod(groupKey, method, direction)`,
`SetAuraGroupLayout(groupKey, layoutOptions)`,
`GetAuraGroupFrame(groupKey, frameIndex)`, `GetAuraGroupFrameCount(groupKey)`,
`HasAuraGroup(groupKey)`.
**Everything about a group is reconfigurable after creation. Only removal is not.**

## 3. AddAuraSlot

```lua
local auraFrame = container:AddAuraSlot(slotKey, filterString, options)
```

- Returns the slot's AuraButton frame. Slots take **no part in flow layout and
  must be manually anchored** (`docs` comment in Shared). Anchor the returned
  frame; do it at creation time (buttons are forbidden while auras are secret).
- Options: `templateNames`, `initializeFrame`, `candidateFilters`,
  `sortMethod`, `sortDirection` (defaults as for groups). No
  `maxFrameCount`, no `layout`.
- The slot shows the single preferred aura per its sort; "can be used to
  replicate big-defensive displays, dispel indicators, or indicators for
  specific spells by ID" (source comment). This is the FRAME/BORDER activation
  replacement: button shown = overlay active, and we never observe it.
- Mutators: `SetAuraSlotFilterString`, `SetAuraSlotCandidateFilters`,
  `SetAuraSlotSortMethod`, `HasAuraSlot`.

## 4. Layout

Two levels. **Container-level flow layout** (shared by all groups in the
container; defaults from `CustomAuraContainerLayoutDefaults`):

```lua
container:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Horizontal|Vertical)   -- default Horizontal
container:SetFlowLayoutAnchorPoint("TOPLEFT")                                 -- default TOPLEFT; origin corner
container:SetFlowLayoutGrowthDirection(hDir, vDir)                            -- AnchorUtil.FlowDirection; default Right, Down
container:SetFlowLayoutPadding(l, r, t, b)                                    -- default 0s
container:SetFlowLayoutMaximumLineSize(px)                                    -- default math.huge; PIXELS, primary axis
container:ResetFlowLayoutOptions()
```

`AnchorUtil.FlowDirection = { Left = -1, Right = 1, Up = 1, Down = -1 }`.
Wrap check (AnchorUtil.FlowLayoutMixin): a line wraps when
`linePrimarySize + nextElementSize > maximumLineSize`, sizes accumulated in
pixels including `elementSpacing`. Exact `perRow` mapping:
`maximumLineSize = perRow * iconSize + (perRow - 1) * elementSpacing`.

**Per-group layout options** (defaults from
`CustomAuraContainerGroupLayoutDefaultOptions`):

| Field | Type | Default |
|---|---|---|
| `elementSpacing` | number | 0 |
| `lineSpacing` | number | 0 |
| `groupSpacing` | number | 0 |
| `groupLineSpacing` | number | 0 |
| `forceNewLine` | boolean | false |
| `elementWidth` | non-negative number | nil (= button's own size) |
| `elementHeight` | non-negative number | nil |
| `layoutIndex` | number | nil (falls back to registration order) |

The container anchors every button itself (`ClearAllPoints` + `SetPoint` to
the container with secret-wrapped offsets). Addon `SetPoint`/`SetSize` on
grouped buttons is pointless and forbidden in combat anyway.

### NivUI growth/wrap → flow layout mapping (1:1 with our ORIGIN_CORNER table)

| growth | wrap | axis | hDir | vDir | anchorPoint |
|---|---|---|---|---|---|
| RIGHT | DOWN | Horizontal | Right | Down | TOPLEFT |
| RIGHT | UP | Horizontal | Right | Up | BOTTOMLEFT |
| LEFT | DOWN | Horizontal | Left | Down | TOPRIGHT |
| LEFT | UP | Horizontal | Left | Up | BOTTOMRIGHT |
| UP | RIGHT | Vertical | Right | Up | BOTTOMLEFT |
| UP | LEFT | Vertical | Left | Up | BOTTOMRIGHT |
| DOWN | RIGHT | Vertical | Right | Down | TOPLEFT |
| DOWN | LEFT | Vertical | Left | Down | TOPRIGHT |

Anchoring semantics change: the old widget was sized to one icon and the user
anchor pinned icon 1; the container spans the whole (secret-sized) grid. To
preserve "user anchor pins icon 1", anchor the container BY its flow origin
corner, offsetting from the user's configured point by the fixed
one-icon-rect delta (computable from iconSize).

## 5. candidateFilters (exact fields, from ValidateCandidateFilters)

| Field | Type | Notes |
|---|---|---|
| `includeSpellIDs` | map `[spellID]=truthy` | see restriction below |
| `excludeSpellIDs` | map | |
| `includeDispelTypes` | map `["Magic"]=truthy` | dispel type names |
| `excludeDispelTypes` | map | |
| `maxDuration` | non-negative number | max TOTAL duration (not remaining); non-nil hides permanent auras |
| `processedAuraType` | `AuraUtil.AuraUpdateChangedType` | requires `SetAuraProcessingPolicy(ProcessAura)` |
| booleans | `true`/`false`/nil | `isFromPlayerOrPlayerPet`, `isRoleAura`, `isPriorityAura`, `isStealable`, `nameplateShowAll`, `nameplateShowPersonal`, `canApplyAura`, `isBossAura`, `isBossOrRoleAura` — `false` negates, nil ignores |

**RESTRICTION (source comment, lines 79–82):** spell-ID matching is only
permitted for **helpful auras on assistable units** and **harmful auras on
non-assistable units**. Non-secret spells are exempt (PTR 6: filterable
"without restrictions on any unit"). Practical consequence: a custom spell
list on friendly-unit DEBUFFS will not match while auras are secret. NivUI's
filter UI should surface this.

filterString: standard tokens (`HELPFUL`, `HARMFUL`, `PLAYER`, `RAID`, ...,
`DISPELLABLE` new, `IMPORTANT` re-added), `|` separator, `!` negation on most
tokens. Validated by `AuraUtil.IsValidFilterString`.

## 6. Sorting

```lua
AuraContainerSortMethod = { Default=0, BigDefensive=1, UnitFrameDebuff=2, ImportantOnly=3,
                            Expiration=4, ExpirationOnly=5, Name=6, NameOnly=7, AuraInstanceIDOnly=8 }
AuraContainerSortDirection = { Normal=0, Reverse=1 }
```

## 7. AuraButton styling API (CustomAuraButtonSharedMixin)

All bindings are set on the button, typically inside `initializeFrame`. The
button applies secret aspects to bound regions itself. Every Set has a Clear;
most have a Get.

| API | Binds | NivUI use |
|---|---|---|
| `SetIcon(texture)` | Texture | ICON display |
| `SetDurationCooldown(cooldown)` | Cooldown frame | swipe (`showSwipe`); applies Cooldown+Shown secret aspects |
| `SetDurationText(fontString, options)` | FontString | duration text; options: `binding`, `textFormat {formatString, components}`, `textFormatter`, `textColor {curve, property}`; default formatter = secondsFormatter |
| `SetDurationBar(statusBar, options)` | StatusBar | (new feature potential) |
| `SetApplicationCount(fontString, options)` | FontString | stacks |
| `SetApplicationBar(statusBar, options)` | StatusBar | (new) |
| `SetAuraBorder(texture, options)` | Texture | dispel-type border; `DefaultAuraBorderOptions`; PTR 8 added `stealable`/`showAlways` |
| `AddDispelTypeTexture(texture, options)` / multiple | Texture | |
| `SetDispelTypeText(fontString, options)` | FontString | |
| `SetSpellName(fontString)` | FontString | |
| `AddPandemicRegion(region)` | Region | (new) |
| `SetCancelAuraButtons(...)` | | click-to-cancel |
| `SetMouseMotionEnabled(bool)` | | disable automatic tooltips |

- `initializeFrame(auraButton)` runs immediately after button creation,
  **before** access restrictions are applied (securecallfunction'd, so taint
  is fine). Style everything here.
- Access restriction: `DenyTaintedAccessWhenAurasAreSecret`—buttons are
  forbidden objects while auras are secret, usable again out of combat
  (restyling on config change out of combat is legal, and PTR 7 fixed calling
  button APIs outside initializeFrame).
- Buttons additionally permit native calls (SetPoint/SetSize) during UI load
  until `PLAYER_LOGIN`.
- No reparenting of buttons; child components can't be reparented once
  configured.

## 8. NivUI migration mapping (agreed direction)

**One AuraContainer per overlay widget** (flow layout is container-global, so
per-overlay anchoring/growth requires per-overlay containers).

| Overlay type | Construct | Notes |
|---|---|---|
| ICON | container + one AuraGroup | icon/cooldown/stacks bound per button in `initializeFrame` |
| COLOR | container + one AuraGroup | colored texture on button, no `SetIcon` binding (verify in-game: button shown ⇒ texture shown) |
| FRAME | container + one AuraSlot | slot frame anchored over target bar, translucent color texture; covers whole bar (fill edge unknowable in combat—accepted semantic change) |
| BORDER | container + one AuraSlot | slot frame anchored around target at ±thickness with 4 edge textures |

Filter spec translation (BuildSpec → container):
- allow-builtin tokens → appended to the group's `filterString` (`HELPFUL|RAID|...`)—
  but tokens OR'd in one filter string? **Verify**: filter string semantics are
  AND (`HELPFUL|RAID` = helpful AND raid-filter) — multiple allow-builtins may
  need multiple groups or slots. (Open question Q4 from PTR-12.1-FINDINGS §6.)
- block-builtin → `!TOKEN` appended to filterString (AND NOT).
- allowSpells → `candidateFilters.includeSpellIDs` (merged map).
- blockSpells → `candidateFilters.excludeSpellIDs` (merged map).
- Empty allow set = show all (just the base HELPFUL/HARMFUL string).
- Allow-OR across a builtin token AND a spell list cannot be expressed in one
  group (includeSpellIDs restricts, it doesn't extend). Needs two groups/slots
  feeding one visual, or a documented behavior change.

Event flow after migration: no UNIT_AURA handling for overlays at all; the
container updates itself. Config changes rebuild or mutate containers out of
combat only (queue on PLAYER_REGEN_ENABLED if needed). Preview mode keeps the
old hand-built icon grid (PopulateTestAuras touches no aura APIs).

## 9. Remaining in-game verification

1. COLOR pattern: unbound colored texture on a button—does show/hide track
   assignment correctly? (It should: the container shows/hides the BUTTON.)
2. Slot anchoring to addon frames (health bar) with offsets—no implicit
   forbidden-aspect error (PTR 2 rule) in either direction?
3. Multiple allow-builtin tokens: is `HELPFUL|RAID|CANCELABLE` AND-semantics
   (expected) and therefore multi-group required for OR?
4. Riptide test: de-listed healer HoT in includeSpellIDs on a raid member
   group shows in combat (the §1 compensation claim).
5. `SetDurationText` with NivUI fonts; `SetApplicationCount` options shape.
6. Container anchor-by-origin-corner offset math visually matches the old grid.
