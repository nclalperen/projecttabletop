# Config Pattern (Registry-First)

This project uses a registry pattern so runtime code does not hardcode resource paths or magic constants.

## Core rules

1. Define stable IDs in an `Ids` script (`StringName` constants).
2. Map IDs to values in a `Catalog` script.
3. Provide typed access via a `Registry` facade.
4. Keep consumer scripts ID-only. No direct literals in runtime code.
5. Add guard tests that fail when direct literals appear.

## Asset implementation

- IDs: `res://gd/assets/AssetIds.gd`
- Catalog: `res://gd/assets/AssetCatalog.gd`
- Loader/cache: `res://gd/assets/AssetLoader.gd`
- Public entrypoint: `res://gd/assets/AssetRegistry.gd`

## Rollout model

1. Introduce IDs + catalog while preserving behavior.
2. Refactor consumers to registry usage.
3. Move physical files to canonical root.
4. Tighten tests to block direct literals.
