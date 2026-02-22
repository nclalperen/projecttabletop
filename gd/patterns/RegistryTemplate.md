# Registry Template

Use this template for any domain (`config`, `content`, `tuning`, etc.).

## Files

- `XIds.gd`: stable `StringName` identifiers.
- `XCatalog.gd`: ID -> raw value mapping.
- `XRegistry.gd`: public typed accessors.
- `tests/test_x_registry.gd`: resolution/contract checks.
- `tests/test_no_direct_x_literals.gd`: strict consumer guard.

## Naming

- IDs: uppercase snake case constants.
- ID values: namespaced lowercase, e.g. `"config/video/profile_high"`.
- Registry methods: short, typed, and side-effect free when possible.

## Consumer rule

Runtime scripts never embed domain literals directly. They resolve via registry IDs only.

## Guard strategy

- Allowlist only registry/catalog/template/docs/tests.
- Fail CI on literal use in runtime scripts.
