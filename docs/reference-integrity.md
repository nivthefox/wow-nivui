# Reference Integrity

NivUI stores profiles, unit-frame styles, custom filters, and overlays by display name. These names remain part of the saved-variable schema, so model operations maintain every dependent reference synchronously.

## Policies

Profile renames cascade through specialization mappings for every character in `NivUI_DB.charMeta`. Profile deletion clears those mappings. It does not silently remap a specialization to Default.

Style renames cascade through standard `unitFrameAssignments` and `customRaidGroups[*].styleName`. The final style cannot be deleted. Deleting any other style reassigns its dependents to the lexicographically first remaining style.

Deleting a custom filter removes its name from every overlay's `allow` and `block` sets. Blizzard built-in filter tokens are independent and remain intact.

Deleting an overlay removes its name from every style's `overlays` set.

Creating an assignment, custom raid-group style reference, or specialization mapping rejects a missing target. Deleting and recreating the same display name does not restore any relationship that the deletion removed.

## Reconciliation

Database initialization reconciles all saved profiles and character specialization mappings before configuration UI can open. Profile import and profile activation reconcile the affected profile through the same model policy.

Reconciliation creates a Default style when a profile has no styles, replaces dangling required style references with the deterministic fallback, and removes dangling optional profile, filter, and overlay references.

The model reports affected dependents in mutation event payloads. Configuration UI may present those details, but it does not repair persisted data.
