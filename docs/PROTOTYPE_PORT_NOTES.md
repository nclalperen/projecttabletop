# Prototype Port Notes

## Scope

This prototype wave imports reusable systems from:

- Tabletop-club
- Buckshot Roulette
- Dome Keeper
- Halls of Torment
- Slay the Spire 2
- Brotato
- Cruelty Squad

The imports are under `res://prototype/imported/*` and are intentionally isolated from production gameplay code.

## Routing

`TabletopGameCatalog.launch_scene_path()` now routes to:

- `res://ui/ImportedTable3D.tscn` when `ImportedFeatureFlags.prototype_table_enabled == true`
- existing scenes otherwise

Online lobby launch preserves fallback behavior and only bypasses legacy Okey direct-routing when prototype routing is enabled.

## Godot 3 -> 4 Porting

Imported tabletop modules were ported to Godot 4.6 semantics:

- `Spatial` -> `Node3D`
- `RigidBody` -> `RigidBody3D`
- `MeshInstance` -> `MeshInstance3D`
- `Transform` -> `Transform3D`
- `Quat` -> `Quaternion`
- legacy network methods (`master/puppet/remotesync`) -> `@rpc`
- `File`/`Directory` style operations -> `FileAccess`/`DirAccess`

## Runtime Safety

- `ImportedRuntimeBridge` centralizes module availability checks.
- Module checks include feature flags, plugin file presence, and required runtime singletons.
- SDK-dependent imports are guarded and do not block boot.
- Optional editor plugins are present in import directories but are not force-enabled in `project.godot`.

## Network Integration

- `HostMatchController` now runs imported Buckshot-style packet verification before applying client action requests.
- `ImportedTable3D` exposes `apply_remote_piece_transform(piece_name, target_transform, duration_sec)` and uses imported Buckshot separate-lerp smoothing.

## Dev Toggle Surface

Feature toggles are available via:

- persistent config (`user://imported_feature_flags.cfg`)
- settings UI section in `SettingsMenu` titled `Imported Prototype Runtime`

## Current Limitations

- Imported systems are prototype-level and not full parity ports.
- Some imported SDK-dependent modules are intentionally no-op stubs until dependencies are wired.
- `ImportedTable3D` currently serves as a prototype runtime scene with imported interaction scaffolding.
