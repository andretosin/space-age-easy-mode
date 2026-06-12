# Space Age Easy Mode

Factorio mod that reduces grind and accelerates progression by applying global buffs during the data loading stage. Compatible with the base game and the Space Age expansion.

## Effects

### Global Machine Buff (all assembling machines, furnaces, mining drills, labs)
- **+100% Speed**
- **+100% Productivity**
- **-40% Energy Consumption**

Bonuses are applied as base effects and stack normally with installed modules.

### Module Rebalance
All module bonuses are doubled:

| Module         | Vanilla | Mod    |
| -------------- | ------- | ------ |
| Speed 3        | +50%    | +100%  |
| Productivity 3 | +10%    | +20%   |
| Efficiency 3   | -50%    | -100%  |

### Drone Buff (logistics and construction robots)
- **Speed** ×2
- **Cargo capacity** ×2

No research required — active from the start of the game.

### Power Generation Buff
- **Power generation** ×2 for all electric generators
- Covers steam engine, steam turbine, plasma/fusion generators, solar panels, lightning rod and advanced lightning rod

### Roboport Upgrades
- **Logistics radius** ×2
- **Construction radius** ×2
- **Charging slots** ×4
- **Charging speed** ×4

## Compatibility

- Factorio 2.0+ (base game)
- Space Age (optional dependency)
- All modifications use generic prototype iteration — no hardcoded entity names, so modded content is covered automatically.

## Technical Notes

- All logic runs in `data-updates.lua` (data stage only).
- No `control.lua`, no runtime events, no per-tick logic.
- Zero performance impact during gameplay.

## Installation

Copy the `space-age-easy-mode_<version>` folder into your Factorio `mods/` directory and enable it from the in-game mod manager.


## Packaging

Set the target release version in `info.json`, then run `./scripts/package.sh` to generate a zip in this format:

- `space-age-easy-mode_<version>.zip`
- containing folder `space-age-easy-mode_<version>/` with all project files

Pushes to `develop` build the same versioned zip as a workflow artifact for local testing. Pushes to `main` build the zip, create the matching GitHub release tag, attach the zip to the GitHub Release, and publish the package to the Factorio Mod Portal. Configure the GitHub Actions secret `FACTORIO_MOD_PORTAL_TOKEN` with a Mod Portal API token before publishing from `main`.

## Version History

- `1.0.6` - Updated release automation to use the version declared in `info.json` and publish main-branch releases to the Factorio Mod Portal.
- `1.0.5` - Kept vanilla module energy consumption penalties unchanged while continuing to double speed, productivity, and quality module bonuses; added develop build packaging.
- `1.0.4` - Excluded repository automation files and scripts from release zips for Mod Portal compatibility.
- `1.0.3` - Added automated main-branch release workflow with version bump commits, tags, GitHub Releases, and zip uploads.
- `1.0.2` - Added version-bumping packaging script and documented versioned release artifacts.
- `1.0.1` - Added robot speed/cargo buffs and 2x power generation coverage for generators, solar panels, fusion generators, and lightning attractors.
- `1.0.0` - Initial release with global productive machine buffs, module rebalance, roboport upgrades, Factorio 2.0 support, and optional Space Age compatibility.

Maintainer note: whenever `info.json` version changes for a release, append a new section to the top of `changelog.txt` using Factorio's official changelog format.
