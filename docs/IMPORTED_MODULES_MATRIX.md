# Imported Modules Matrix

This file tracks prototype imports and their runtime posture.

| Module ID | Source Folder | Local Path | Status | Runtime Requirement | Notes |
|---|---|---|---|---|---|
| `tabletop_club` | `Tabletop-club` | `res://prototype/imported/tabletop_club` | enabled | none | Primary prototype 3D tabletop layer (Room/CameraController/Pieces/Chat/Ruler). |
| `buckshot` | `Buckshot Roulette` | `res://prototype/imported/buckshot` | enabled | none | Host-authoritative packet verification is wired in `HostMatchController`; smoothing helper is exposed through `ImportedTable3D`. |
| `dome_keeper` | `Dome Keeper` | `res://prototype/imported/dome_keeper` | enabled | none | Input processor-chain, telemetry sender, mod-loader, JSON schema validator. |
| `halls_torment` | `Halls of Torment` | `res://prototype/imported/halls_torment` | enabled | none | Thread pool addon and tracer utility. |
| `brotato` | `Brotato` | `res://prototype/imported/brotato` | enabled | none | Platform facade and versioned save loader scaffolding. |
| `slay2` | `Slay the Spire 2` | `res://prototype/imported/slay2` | requires_sdk | optional singletons (`IEOS`/`EOS`) | Editor/runtime addons are imported but remain optional and guarded. |
| `cruelty_squad` | `Cruelty Squad` | `res://prototype/imported/cruelty_squad` | enabled | optional `Steam` singleton for `godotsteam` bridge | Addons imported as optional plugin bridges. |

## Flags

Runtime enablement is controlled by:

- `res://prototype/ImportedFeatureFlags.gd`
- persisted state at `user://imported_feature_flags.cfg`

Global prototype routing:

- `prototype_table_enabled`

Per-module toggles:

- `tabletop_club`
- `buckshot`
- `dome_keeper`
- `halls_torment`
- `brotato`
- `slay2`
- `cruelty_squad`
