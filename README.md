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

Run `./scripts/package.sh` to bump the patch version in `info.json` and generate a zip in this format:

- `space-age-easy-mode_<version>.zip`
- containing folder `space-age-easy-mode_<version>/` with all project files
