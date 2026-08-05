# NivUI × Patch 12.1.0 (Curse of Ula'tek) — Findings & Migration Notes

Compiled by Sage, 2026-08-05, from the [12.1.0 API changes page](https://warcraft.wiki.gg/wiki/Patch_12.1.0/API_changes) cross-referenced against NivUI 2.1.0 source. PTR is on weekly builds (PTR 8 landed 2026-08-04) and the aura APIs are still moving, so verify anything load-bearing against the live build before designing around it.

**TOC bump required:** `## Interface: 120100`. Until then, check "Load out of date AddOns" on the PTR.

---

## 1. The headline

12.1 is the aura lockdown patch. While auras are secret (combat, encounters, M+, PvP):

- All C_UnitAuras APIs that access aura data **by index, slot, or instance ID now Lua error** when called by addons. This is not "returns a secret"—it throws.
- The `UNIT_AURA` event payload is fully secret. `AuraData` structs are always fully secret.
- Spell-ID/spell-name access (`GetPlayerAuraBySpellID`, `GetAuraDataBySpellName`, etc.) still works, and non-secret spells still return non-secret data.
- The sanctioned replacement is a new managed widget system: **AuraContainer → AuraGroup / AuraSlot → AuraButton**. Addons declare filters and style buttons; the container does all tracking, filtering, sorting, and layout internally. Addon code never touches aura data and cannot observe which buttons are shown (`IsShown` returns secrets, script handlers forbidden, event registration forbidden, `OnSizeChanged` suppressed—PTR 8 explicitly patched an `OnSizeChanged`-counting exploit).
- `SecureAuraHeaderTemplate` is removed from Mainline (NivUI never used it).
- Blizzard removed ~50 healer buffs/HoTs from the "never secret" list (Rejuv, Riptide, Renewing Mist, PW:S, Atonement, Beacon, Prescience, Echo, etc.). The 12.0-era trick of reading friendly player-cast `spellId`s in combat is explicitly revoked for exactly the spells a healer layout cares about. The stated compensation: aura containers can filter secret auras by spell ID server-side—the filtering works, we just never see the results.

**Consequence: the 12.0 combat-safe pattern (`GetAuraSlots` + `GetAuraDataBySlot` + `issecretvalue` guards + `IsAuraFilteredOutByInstanceID`) is dead. The overlay system requires a rewrite onto AuraContainers.**

## 2. Scope decisions already made (Niv, 2026-08-05)

These were agreed during the initial evaluation and simplify the work considerably:

1. **Transformative overlay priority resolution is not worth preserving.** If multiple FRAME/BORDER overlays are active on the same target, visual stacking is acceptable. The claims/winners logic in `ResolveTransformativeOverlays` does not need a replacement.
2. **Mid-combat roster changes do not need instant rendering.** Role sorting and roster-derived display may be computed out of combat and cached; members who join mid-combat can render unsorted/uncolored until combat drops.
3. **Role comparisons, class colors, and class icons all move to the same cache.** Class is immutable and role cannot change in combat, so the cache is semantically correct, not an approximation.

## 3. Exact break inventory (file:line, current source)

### 3a. Aura pipeline — hard errors in combat, requires rewrite

| Site | Call | Failure mode |
|---|---|---|
| `modules/unitframes/UnitFrameBase.lua:1071` | `C_UnitAuras.GetAuraSlots` (in `CollectAuras`) | Lua error while auras secret; not pcall-wrapped |
| `UnitFrameBase.lua:1073` | `C_UnitAuras.GetAuraDataBySlot` | Lua error while auras secret |
| `UnitFrameBase.lua:1005` | `C_UnitAuras.GetAuraDuration(unit, instanceID)` | instance-ID access; pcall swallows the error but every cooldown goes blank |
| `UnitFrameBase.lua:1027` | `C_UnitAuras.IsAuraFilteredOutByInstanceID` (in `MatchesAnyBuiltin`) | instance-ID access; Lua error, not pcall-wrapped |
| `UnitFrameBase.lua:1135-1136` | `C_UnitAuras.GetAuraApplicationDisplayCount(unit, instanceID)` | instance-ID access; Lua error, not pcall-wrapped |
| `UnitFrameBase.lua:1178` | `#CollectAuras(...) > 0` (in `UpdateTransformativeActivation`) | dies with CollectAuras; see §5—the *premise* is also revoked |
| `UnitFrameBase.lua:1456, 1484` | `UNIT_AURA` dispatch/registration | event still fires but payload fully secret; handler calls the erroring pipeline |
| `modules/unitframes/MultiUnitFrameBase.lua:449` | `UNIT_AURA` registration | same |

An error thrown inside the `UNIT_AURA` handler aborts the whole update, so the practical symptom without migration is either taint errors every combat frame or all aura widgets blank in combat.

### 3b. Roster/identity APIs — new secrets, fixed by the cache (§6)

PTR 7: `UnitClass`, `UnitClassBase`, `UnitGroupRolesAssigned`, `UnitIsGroupLeader`, `UnitIsGroupAssistant`, `UnitInRaid`, `UnitSex`, `UnitRace`, `UnitIsPVP`, `UnitIsRaidOfficer`, `UnitLeadsAnyGroup`, `GetInspectSpecialization`, and friends return **secret values when the unit's identity is secret**. Operations that throw on secrets: comparison (`==`, `~=`, `<`), arithmetic, `#`, table-indexing with the secret, calling it. Truthiness tests are safe.

| Site | Consumption | Failure mode |
|---|---|---|
| `modules/unitframes/PartyFrame.lua:29-31` | `ROLE_PRIORITY[UnitGroupRolesAssigned(a)]` inside `table.sort` | secret table key → throws |
| `modules/unitframes/RaidFrame.lua:89-90` | same pattern | throws |
| `modules/unitframes/CustomRaidGroup.lua:28-30, 59-61` | `role == roleValue` | secret comparison → throws |
| `UnitFrameBase.lua:470-471` (`ShouldShowPowerBar`) | `role == "HEALER"` | throws |
| `UnitFrameBase.lua:783-784` (`UpdateRoleIcon`) | `role ~= "NONE"`, then `GetMicroIconForRole(role)` | throws |
| `UnitFrameBase.lua:655-657` (portrait class mode) | `CLASS_ICON_TCOORDS[class]` | secret table key → throws |
| `modules/unitframes/WidgetFactories.lua:5-7` (`GetClassColor`) | `RAID_CLASS_COLORS[class]` | secret table key → throws |
| `WidgetFactories.lua:265-267` (class portrait factory) | `CLASS_ICON_TCOORDS[class]` | throws |
| `WidgetFactories.lua:492-493, 545` | leader/assist/role widget factories | leader icon consumes via truthiness → degrades, not errors; role path throws |
| `UnitFrameBase.lua:760-761` (`UpdateLeaderIcon`) | truthiness only | degrades (may misrender in combat), guard anyway |

**Open question:** the wiki says these go secret "when the unit's identity is secret" without defining when a *friendly party member's* identity is secret. Verify on the PTR how often this actually fires for party/raid units (see §7 Q1).

### 3c. Not broken

- **`modules/bars/StaggerBar.lua:47-49`** — `GetPlayerAuraBySpellID` is spell-ID access; still legal.
- **`modules/overlays/OverlayLogic.lua`** — pure layout/resolution math, no API calls. Survives as-is; the transformative resolver just loses its caller.
- **Edit Mode support** — NivUI uses no `Enum.EditMode*` values, so the `IconSize` → `BuffIconSize`/`DebuffIconSize` split is irrelevant.
- **`UnitName`** — already `issecretvalue`-guarded everywhere it matters (`UnitFrameBase.lua:806-807`, `WidgetFactories.lua:342-343`); and 12.1 actually *loosens* it (no longer secret in active PvP matches).
- No usage of `SecureAuraHeaderTemplate`, `GetWeaponEnchantInfo`, `getglobal`/`setglobal`, `UIParentLoadAddOn`, `CanAccessObject`, `TargetFrame_UpdateBuffAnchor`, or any removed FrameXML symbol.
- Config-UI `OnSizeChanged` scripts (`ConfigFrame.lua:162`, `config/Bars.lua:686`, `ConfigTab.lua:407/636/1703`) are on our own frames—unaffected.

## 4. Migration map: overlay system → AuraContainers

Current architecture: `Overlays.lua` (config schema) → `SpellFilters.lua` (`BuildSpec`: allow/block over 9 builtin tokens + custom spell lists) → `UnitFrameBase.lua` (`CollectAuras`/`UpdateAuraWidget` render, `UpdateTransformativeActivation` for FRAME/BORDER) → `OverlayLogic.lua` (grid math, conflict resolution).

Target APIs (verbatim from PTR notes; exact signatures in the Blizzard_AuraContainer docs):

- `CreateFrame("AuraContainer", ...)`; container is created per unit frame, `SetUnit(unit)`. Containers can be created in combat as of PTR 7; there is also a new `SecureGroupHeaderTemplate` for safe creation at unit-frame build time.
- `container:AddAuraGroup(groupKey, filterString, options)` — options include `maxFrameCount`, `sortMethod`/`sortDirection` (`Enum.AuraContainerSortMethod`), `initializeFrame` callback, `templateNames`, and `candidateFilters` (include/exclude spell-ID maps, dispel types, `maxDuration`, boolean AuraData fields like `isStealable`/`isFromPlayerOrPlayerPet`; booleans support `= false` negation as of PTR 6).
- `container:AddAuraSlot(slotKey, filterString, options)` — single-aura group; **slots may be manually anchored** (groups anchor themselves).
- `container:SetAuraGroupLayout(...)` / `layoutIndex` for ordering; groups lay out in rows or columns; containers auto-resize; batches of 10 buttons created on demand.
- `container:SetAuraGroupFilterString(...)` to change filters after creation (PTR 6).
- AuraButton styling inside `initializeFrame`: `SetIcon(texture)`, `SetDurationText(fontString)`, `SetApplicationCount(...)`, `SetAuraBorder(texture, options)` (dispel colors, color curves; `stealable`/`showAlways` options in PTR 8), `SetAuraSymbol(fontString, options)`, ApplicationBar APIs (PTR 6), pandemic-state texture APIs (PTR 8), `SetCancelAuraButtons(...)` for click-to-cancel. Tooltips are automatic (disable via `SetMouseMotionEnabled`; anchor/hide-in-combat configurable as of PTR 7). Buttons permit native calls (SetPoint/SetSize) during reload until `PLAYER_LOGIN`.
- Filter strings support `!` negation (e.g. `!PLAYER`); `DISPELLABLE` is new; `IMPORTANT` is back (it was removed in 12.0.7—the filter model can re-add it); `RAID_PLAYER_DISPELLABLE` now includes stealable enemy buffs.
- Aura buttons become **forbidden objects whenever auras are secret** (PTR 5): API calls from tainted code error, no reparenting, child components locked once configured. Style everything up front.

Mapping per overlay display type:

| Overlay type | Today | Target |
|---|---|---|
| ICON | `CollectAuras` + manual icon grid | `AddAuraGroup`; `BuildSpec` → `filterString` + `candidateFilters`; grid config → group layout options; duration/stacks/border via button bindings |
| COLOR | same collection, `SetColorTexture` cells | group whose `initializeFrame` puts a colored texture on the button and simply never binds `SetIcon`; container drives show/hide (verify—§7 Q2) |
| FRAME (bar tint) | `overlayActive` boolean → recolors bar via `frameOverlayColors` in `UpdateHealthBar` | `AddAuraSlot` anchored over the target bar; button visual = translucent color texture. **Semantic change:** covers the whole bar region, not just the fill—we cannot know the fill edge in combat. |
| BORDER | `overlayActive` boolean → shows border holder around target | `AddAuraSlot` anchored around the target at ±thickness; button visual = border/nineslice texture |

The `#CollectAuras > 0` presence-boolean has no legal replacement—by design. The container decides visibility; our code must never branch on it. Priority resolution is intentionally dropped (§2.1); frame-level stacking is the fallback if ordering ever matters again.

`BuildSpec` semantics to preserve in translation: Block = veto, Allow = OR-inclusion, empty allow set = show all. Block-builtin maps to `!TOKEN` in the filter string or negated candidate filters; block-spells maps to `excludeSpellIDs`; allow-spells to `includeSpellIDs`. Watch for combinations the declarative model cannot express (an OR across a builtin token and a spell list within one group may require two groups feeding the same visual row—verify layout implications, §7 Q4).

## 5. Roster cache design sketch (§3b fixes)

One shared module (suggest `modules/unitframes/RosterCache.lua` or a `NivUI.Roster` namespace):

- Snapshot on `GROUP_ROSTER_UPDATE`, `PLAYER_ROLES_ASSIGNED`, `PARTY_LEADER_CHANGED`, `PLAYER_ENTERING_WORLD`, and `PLAYER_REGEN_ENABLED`—**only writing when values pass `issecretvalue` checks** (i.e., effectively out of combat).
- Cache per unit token: `role`, `classFilename`, `isLeader`, `isAssist`. Key by GUID→token mapping if token identity churns; plain token keys are probably sufficient given §2.2.
- All consumers listed in §3b read the cache; live API reads stay only inside the snapshot function. New units mid-combat get `nil` → render as unsorted/uncolored/roleless until combat drops.
- Match the existing `issecretvalue()` guard idiom (already used at `UnitFrameBase.lua:584/716/719/807/873/882/921` and `RangeCheck.lua:88`; whitelisted in `.luacheckrc`).

## 6. PTR verification checklist (the open questions)

Concrete things to test in-game, roughly in dependency order:

1. **When is a friendly unit's identity secret?** In a party in open world, in a dungeon out of combat, in combat, in M+, in raid combat: call `UnitClass("party1")` / `UnitGroupRolesAssigned("party1")` and check `issecretvalue()` on the results. This determines how aggressive the cache rollout needs to be.
2. **Does an AuraButton work with no `SetIcon` binding?** Create a group whose `initializeFrame` only adds a colored texture. If the button shows/hides correctly with a plain texture, COLOR overlays are portable. Also check `SetAlpha` behavior on the button from inside `initializeFrame`.
3. **AuraSlot manual anchoring:** can a slot be anchored to an arbitrary addon frame (our health bar) with negative/positive offsets, and does it stay put? Does anchoring *our* frames relative to slot/container trip the "implicit Forbidden Aspect" error from PTR 2 (`SetParent`/`SetPoint` error if an object would implicitly gain aspects)?
4. **Filter expressiveness:** can one group express `(builtin token OR custom spell list) AND NOT (block list)`? If not, do two groups visually interleave or render as separate runs? Affects whether a NivUI overlay maps to one group or several.
5. **`initializeFrame` limits:** what styling calls are legal inside it vs. erroring; confirm buttons return to non-forbidden state out of combat (PTR 5 notes say they do) so restyling on config change works.
6. **Secret-spell filtering claim:** put a de-listed healer HoT (e.g. Riptide 61295) in `includeSpellIDs` on a raid-member group and confirm the button appears in combat.
7. **Duration/stacks bindings:** `SetDurationText` + `SetApplicationCount` against NivUI's font config; PTR 8 fixed a duration-showing-0 bug, so retest on current build.
8. **Container sizing vs. our layout:** containers auto-resize and suppress `OnSizeChanged` for themselves *and frames anchored to them*. Check interaction with the raid-container sizing approach from commit `6e05b26`, and whether `Frame:ResizeToBoundsRect` helps.
9. **Roleset system curiosity (low priority):** `C_Roleset` / `Frame:AddRoleset` might interact with frame visibility management; confirm it ignores our frames by default.

Useful while testing: CVar `tooltipShowAuraSpellIDs` (session-only) shows spell IDs in aura tooltips. CVar `taintLogObjectSecrets` adds taint-log entries when objects gain secret aspects.

## 7. Opportunities (after the migration lands)

- **Free features from AuraButtons:** automatic tooltips, dispel-type borders with color curves, application-count bars, pandemic-state textures, click-to-cancel on player buffs (`SetCancelAuraButtons`)—all things NivUI never had or hand-rolled.
- **Private auras become visible:** containers treat private auras like regular auras for display/sorting. Previously invisible to addons entirely.
- **`C_UnitAuras.AddAuraSound` / `RemoveAuraSound`:** audio alerts on any aura (added/applications/removed), no combat data needed. Cheap feature for the Filters config.
- **Radial progress on textures/status bars** (`SetRadialProgressBarPercent` et al.): cooldown-swipe effects on segmented bars without Cooldown-frame hacks.
- **`Frame:SetOnUpdateMode`:** cleaner control of the RangeCheck ticker cadence.
- **`Frame:ResizeToBoundsRect`:** possibly simplifies container sizing (see §6 Q8).
- **`tooltipShowAuraSpellIDs`:** surface in the Filters config UI so users can read spell IDs off tooltips while building custom lists.
- **SVG textures / `VectorGraphics`**, `StatusBar:SetRenderMode`, `Minimap:SetIconScale`: nice-to-haves.
- **`UnitName` un-secreted in PvP:** arena/BG name display can stop degrading.

## 8. References

- Patch notes source: https://warcraft.wiki.gg/wiki/Patch_12.1.0/API_changes
- Blizzard container implementation: https://github.com/Gethe/wow-ui-source/tree/12.1.0/Interface/AddOns/Blizzard_AuraContainer (see `Blizzard_CustomAuraButton.lua` for `DefaultAuraBorderOptions` / `DefaultAuraSymbolOptions`)
- Full 12.0.7→12.1.0 diff: https://github.com/Gethe/wow-ui-source/compare/12.0.7..12.1.0
- Blizzard's ManagedAuraContainer usage example: the 12.1 Blizzard Target Frame
- NivUI 12.0 secret-values background: memory note `wow-aura-secret-values.md` (combat-safe pattern now obsolete, but the secret-value operation rules still apply)
