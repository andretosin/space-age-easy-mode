-- data-updates.lua
-- Space Age Easy Mode — all prototype modifications.
--
-- Runs after every mod's data.lua and data-updates.lua, so Space Age entities
-- are already registered and will be patched automatically.
--
-- No runtime logic. No control.lua. No events.

-- =============================================================================
-- Helpers
-- =============================================================================

-- Multiplies the numeric portion of a Factorio Energy string (e.g. "1000kW" → "4000kW").
local function multiply_energy(s, m)
  local value, unit = s:match("^([%d%.]+)(%a*)")
  if not value then return s end
  return tostring(tonumber(value) * m) .. unit
end

-- Returns a + b, treating nil as 0.
local function add(a, b)
  return (a or 0) + b
end

-- Extracts the numeric bonus from an EffectValue.
-- Handles both the table form {bonus = n} and the plain number form n.
local function get_bonus(v)
  if not v then return 0 end
  if type(v) == "number" then return v end
  return v.bonus or 0
end

-- =============================================================================
-- FR-1: Global Machine Buff
--
-- Applies base effect bonuses to all productive entity types.
-- Uses effect_receiver.base_effect so bonuses stack correctly with modules.
-- Types are iterated generically — no hardcoded entity names.
-- =============================================================================

local BUFF_SPEED        =  1.0   -- +100% crafting / mining / research speed
local BUFF_PRODUCTIVITY =  1.0   -- +100% productivity
local BUFF_CONSUMPTION  = -0.4   -- -40% energy consumption

local productive_types = {
  "assembling-machine",  -- assemblers, chemical plant, oil refinery, centrifuge, foundry, em plant, biochamber, cryogenic plant
  "furnace",             -- stone / steel / electric furnace
  "mining-drill",        -- electric mining drill, pumpjack
  "lab",                 -- research labs
  "rocket-silo",         -- rocket silo
  "recycling-machine",   -- recycler (Space Age)
  "agricultural-tower",  -- agricultural tower (Space Age / Gleba)
}

for _, entity_type in pairs(productive_types) do
  if data.raw[entity_type] then
    for _, entity in pairs(data.raw[entity_type]) do

      -- Initialise effect_receiver if the prototype omits it
      if not entity.effect_receiver then
        entity.effect_receiver = {}
      end

      -- Initialise base_effect if absent
      if not entity.effect_receiver.base_effect then
        entity.effect_receiver.base_effect = {}
      end

      local base = entity.effect_receiver.base_effect

      -- Accumulate over any pre-existing base values so other mods are respected.
      -- base_effect fields are plain numbers, NOT {bonus=n} tables.
      base.speed        = get_bonus(base.speed)        + BUFF_SPEED
      base.productivity = get_bonus(base.productivity) + BUFF_PRODUCTIVITY
      base.consumption  = get_bonus(base.consumption)  + BUFF_CONSUMPTION
    end
  end
end

-- =============================================================================
-- FR-2: Module Rebalance
--
-- Doubles every effect bonus on every module.
-- Works generically across speed, productivity, efficiency and quality modules.
-- Future modules with any combination of effects are handled automatically.
-- =============================================================================

if data.raw["module"] then
  for _, module in pairs(data.raw["module"]) do
    if module.effect then
      local e = module.effect

      if e.speed        then e.speed        = get_bonus(e.speed)        * 2 end
      if e.productivity then e.productivity = get_bonus(e.productivity) * 2 end
      if e.consumption  then e.consumption  = get_bonus(e.consumption)  * 2 end
      if e.quality      then e.quality      = get_bonus(e.quality)      * 2 end
      -- pollution is intentionally left unchanged (not a goal of this mod)
    end
  end
end

-- =============================================================================
-- FR-3: Roboport Upgrades
--
-- Expands logistics and construction radius (×2).
-- Quadruples charging station count and charging energy per station (×4).
-- =============================================================================

if data.raw["roboport"] then
  for _, roboport in pairs(data.raw["roboport"]) do

    -- Double coverage radii
    roboport.logistics_radius    = roboport.logistics_radius    * 2
    roboport.construction_radius = roboport.construction_radius * 2

    -- logistics_connection_distance must remain >= logistics_radius (docs requirement)
    if roboport.logistics_connection_distance then
      roboport.logistics_connection_distance = roboport.logistics_connection_distance * 2
    end

    -- Quadruple charging slot count.
    -- When charging_station_count == 0 the engine derives the count from
    -- charging_offsets, so we compute an explicit value from that array.
    if roboport.charging_station_count and roboport.charging_station_count > 0 then
      roboport.charging_station_count = roboport.charging_station_count * 4
    elseif roboport.charging_offsets and #roboport.charging_offsets > 0 then
      roboport.charging_station_count = #roboport.charging_offsets * 4
    end

    -- Quadruple charging energy per station (Energy is stored as a string, e.g. "1000kW")
    if roboport.charging_energy then
      roboport.charging_energy = multiply_energy(roboport.charging_energy, 4)
    end
  end
end
