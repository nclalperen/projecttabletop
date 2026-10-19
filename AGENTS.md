# Project workflow (tmux supervisor/worker)

This repo is developed with:
- Supervisor: Codex CLI (tmux pane 1)
- Worker: Codex CLI (tmux pane 2)

Rules:
- Implementation work is delegated to Codex.
- Supervisor reviews diffs + test/export output.
- Prefer running Godot via repo wrappers:
  - Standard: ./tools/godot ...
  - .NET/C#:  ./tools/godot dotnet ...
  - Windows PowerShell/CMD: .\tools\godot.cmd ...
  - Export helper: ./tools/export_windows.sh

When coordinating between panes:
- Use /tmux-cli skill (send -> wait_idle -> capture).
- Do NOT use raw tmux send-keys directly.

Definition of Done for tasks:
- Changes compile/run.
- Export succeeds (Windows Desktop preset) OR relevant Godot CLI command succeeds.
- No uncommitted junk files; only intended changes.

## Codex Code Review: project invariants

Review pull requests for concrete functional regressions, security/privacy failures, and violated invariants. Give actionable findings with affected lines, a failure scenario, and an appropriate fix. Do not flag style-only preferences or claim test results you did not observe.

1. **Rules and determinism** (`core/`): Respect `docs/SEOKEY11_CANONICAL.md` as the complete Okey 101 rules specification (`docs/RULES_CANONICAL.md` is its short summary). Preserve tile counts, fake-okey/wildcard semantics, opening/discard conditions, validated-action-to-reducer sequencing, and reproducible seeded outcomes. A deliberate rule change needs updated canonical documentation and focused tests.
2. **Network authority and information secrecy** (`core/network/`, `net/`): A seat-specific state view must never reveal other players' hidden hands or unrevealed deck state. Network inputs must not bypass server/host validation. Changes to `StateCodec`, `SeatViewAdapter`, and the EOS protocol must preserve compatible serialization and reject malformed or unauthorized actions.
3. **Gameplay interaction** (`ui/game_table/`): Preserve the canonical 24-slot Draft Grid (12 per row) and shared resolution in `InteractionResolver.gd`, `DraftGrid.gd`, and `InteractionTuning.gd`. Tap targets may draw/take/select/add-to-meld, not implicitly place into draft or discard. Check both 2D and 3D paths for tile duplication/loss and inconsistent drag/drop outcomes.
4. **EOS release policy and credentials** (`net/`, `tools/`): Do not leak EOS credentials or secrets. Preserve the difference between `mock_allowed`, `runtime_preferred`, and `runtime_required`; required runtime must not silently fall back to mocks. `BLOCKED_ENV_MISSING` from runtime validation is not a passing test.
5. **Assets and platform gates**: New shipping art/audio must satisfy the CC0/public-domain policy and have an `approved` entry in `docs/ASSET_LICENSES.md`. Check changed `res://` references, autoloads, Godot 4.6 compatibility, and Windows D3D12 / Android Vulkan behavior when affected.

Relevant test commands are documented in `docs/README_DEV.md`. The core headless suite is `godot --headless --path . -s res://tests/run_tests.gd`; use the strict matrix for changes that may affect multiple platforms or EOS.
