This package replaces the overbroad Phase 1 analysis, NOT Sol's local AI tooling.

1. Extract the folder to D:\Projects\projecttabletop\localaiphasemanual\tabletop_phase1_scoped
2. From PowerShell:
   powershell -NoProfile -ExecutionPolicy Bypass -File "D:\Projects\projecttabletop\localaiphasemanual\tabletop_phase1_scoped\RUN_PHASE1_SCOPED.ps1"
3. To run one task: append -Only games (or assets, or tavla).

The script uses Sol's existing 4e6a detached checkout, verifies HEAD, does not rerun model installation, indexing or core checks, and never requests writes. Read-only agent transcripts/logs are written to .local-ai/manual-phase1-scoped and .local-ai/runs.
It does not inspect uncommitted changes in the separate ae46 worktree. Results are review drafts; failures are retained and not treated as passes.
