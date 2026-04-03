# Movement System Addon Release Checklist

Use this checklist when publishing a new GitHub release of the addon.

## 1) Versioning

- Update `addons/movement_system/plugin.cfg`:
  - `version="x.y.z"`
- Commit with a versioned message:
  - Example: `release: movement-system addon v1.1.0`

## 2) Validate In Editor

- Open project in Godot 4.6.
- Enable plugin in `Project Settings -> Plugins`.
- Confirm custom node types appear in `Add Child Node`:
  - `MovementManager`
  - `MovementModeManager`
  - `MovementMode`
  - `Locomotion`, `Rotation`, `Jump`, `Gravity`, `Stance`
  - `*ExtensionOverride` types
- Verify no parser errors in Output.

## 3) Runtime Smoke Test

- Open your test scene.
- Confirm movement works with plugin enabled.
- Confirm mode switching still works:
  - `activate_mode_by_name(...)`
  - `deactivate_mode_by_name(...)`
  - `set_mode_active_by_name(...)`
- Confirm debug mode chain output (if enabled) is correct.

## 4) Package Contents

Release package should include:

- `addons/movement_system/`
- `movement_system/`

Do not include:

- `.godot/`
- local test scenes not intended for distribution
- unrelated addons

## 5) Build Release Zip

From repo root:

```bash
mkdir -p dist
rm -f dist/movement-system-addon-vX.Y.Z.zip
zip -r dist/movement-system-addon-vX.Y.Z.zip addons/movement_system movement_system
```

Replace `X.Y.Z` with your release version.

## 6) Git Tag + Push

```bash
git tag vX.Y.Z
git push origin main --tags
```

## 7) GitHub Release

- Create a new release for tag `vX.Y.Z`.
- Upload: `dist/movement-system-addon-vX.Y.Z.zip`
- Include release notes:
  - New features
  - Breaking changes (if any)
  - Migration steps (if any)

## 8) Post-Release Verification

- Download release zip into a clean Godot project.
- Extract to project root.
- Enable plugin.
- Confirm types/scripts/icons load with no missing-resource errors.
