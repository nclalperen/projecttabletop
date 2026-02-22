# Rendering Support Matrix

## Target Matrix

| Platform | Renderer | Driver/API | Support Tier | Notes |
|---|---|---|---|---|
| Windows Desktop | Forward+ | D3D12 | Supported | Default desktop target for this phase. |
| Android (modern Vulkan devices) | Forward+ | Vulkan | Supported | Main Android target in this phase. |
| Android (legacy / non-Vulkan devices) | Compatibility | OpenGL ES 3.0 | Not supported in this phase | Explicitly out of scope for current migration. |

## Policy

- This project currently targets **modern Android Vulkan devices only**.
- No OpenGL compatibility fallback is committed in this phase.
- If Android validation fails, rollback to previous renderer policy is required before release.

## QA Gate (Required Before Keeping Forward+ Default)

Validate on **two real Android devices**:

1. Device A: modern Adreno midrange Vulkan device.
2. Device B: modern Mali midrange Vulkan device.

Run a 20-minute session on each:

1. round setup/start flow
2. heavy drag/drop across rack, stage, meld, discard
3. multiple round transitions
4. bot turn progression and end-round/new-round loops

Pass criteria:

- no crash / no black screen / no shader lockup
- board+rack+tiles+HUD render correctly
- touch/input stays responsive
- average FPS >= 50 with no prolonged stutter bursts
- no severe thermal-throttle degradation

## Rollback Plan

If either Android device fails the gate:

1. Set `project.godot` back to previous renderer mode (`mobile` or prior baseline).
2. Keep Windows D3D12 unchanged.
3. Mark Android Forward+ as experimental in docs until re-validated.
