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

-- True if a prototype declares the given entity flag (e.g. "player-creation").
local function has_flag(entity, flag)
  if not entity.flags then return false end
  for _, f in pairs(entity.flags) do
    if f == flag then return true end
  end
  return false
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
      -- consumption is intentionally left unchanged — vanilla energy penalty is kept as-is
      if e.quality      then e.quality      = get_bonus(e.quality)      * 2 end
      -- pollution is intentionally left unchanged (not a goal of this mod)
    end
  end
end

-- =============================================================================
-- FR-3: Drone (Robot) Buff
--
-- Doubles base speed of all logistics and construction robots.
-- Doubles cargo capacity (max_payload_size) of all robots.
-- Applied as a base prototype modification — no research required.
-- =============================================================================

local drone_types = { "logistic-robot", "construction-robot" }

for _, robot_type in pairs(drone_types) do
  if data.raw[robot_type] then
    for _, robot in pairs(data.raw[robot_type]) do
      if robot.speed then
        robot.speed = robot.speed * 2
      end
      -- Double cargo capacity for all robots
      if robot.max_payload_size then
        robot.max_payload_size = robot.max_payload_size * 2
      end
    end
  end
end

-- =============================================================================
-- FR-4: Power Generation Buff
--
-- Doubles electricity production for all power generators.
-- Covers steam/combustion/turbines, solar panels, fusion/plasma generators,
-- and lightning rods (normal + advanced).
-- Player-built lightning rods also gain 2× lightning collection range.
-- Applied as a base prototype modification — no research required.
-- =============================================================================

local function double_effectivity(prototype)
  if prototype and prototype.effectivity then
    prototype.effectivity = prototype.effectivity * 2
  end
end

if data.raw["generator"] then
  for _, generator in pairs(data.raw["generator"]) do
    double_effectivity(generator)
  end
end

if data.raw["solar-panel"] then
  for _, panel in pairs(data.raw["solar-panel"]) do
    if panel.production then
      panel.production = multiply_energy(panel.production, 2)
    end
  end
end

if data.raw["fusion-generator"] then
  for _, fusion_generator in pairs(data.raw["fusion-generator"]) do
    double_effectivity(fusion_generator)
  end
end

-- Space Age lightning rod entities are lightning-attractor prototypes.
if data.raw["lightning-attractor"] then
  for _, attractor in pairs(data.raw["lightning-attractor"]) do
    -- Handle both field names for compatibility with different game/mod prototypes.
    if attractor.efficiency then
      attractor.efficiency = attractor.efficiency * 2
    end
    if attractor.effectivity then
      attractor.effectivity = attractor.effectivity * 2
    end

    if attractor.energy_source then
      local source = attractor.energy_source
      if source.input_flow_limit then
        source.input_flow_limit = multiply_energy(source.input_flow_limit, 2)
      end
      if source.output_flow_limit then
        source.output_flow_limit = multiply_energy(source.output_flow_limit, 2)
      end
      if source.buffer_capacity then
        source.buffer_capacity = multiply_energy(source.buffer_capacity, 2)
      end
    end

    -- Double the lightning collection range of the player-built rods (lightning
    -- rod and lightning collector / advanced rod). Gated on player-creation so
    -- Fulgoran ruin attractors keep their vanilla range.
    if attractor.range_elongation and has_flag(attractor, "player-creation") then
      attractor.range_elongation = attractor.range_elongation * 2
    end
  end
end

-- =============================================================================
-- FR-5: Roboport Upgrades
--
-- Expands logistics and construction radius (×2).
-- Quadruples the charging slot count (×4) and charging energy/speed (×4).
-- The extra slots are generated as evenly spaced charging_offsets on a ring
-- around the port, so robots charge in a tidy halo instead of stacking.
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

    -- Quadruple the charging slots, spread cleanly around the port.
    --
    -- charging_offsets sets both the slot count (when charging_station_count is
    -- 0) and where each robot parks to charge. charging_station_count must stay
    -- 0/nil: a non-zero value makes the engine ignore the offsets and stack
    -- every robot on the port centre (the original bug). And clustering the
    -- offsets tightly makes charging robots overlap into a blob. So we generate
    -- 4x as many offsets evenly spaced on a ring, with enough spacing that
    -- neighbouring robots do not overlap.
    if roboport.charging_offsets and #roboport.charging_offsets > 0 then
      local originals = roboport.charging_offsets
      local slot_count = #originals * 4

      -- Keep the ring at least at the original charging distance.
      local base_radius = 0
      for _, offset in pairs(originals) do
        local ox = offset[1] or offset.x or 0
        local oy = offset[2] or offset.y or 0
        local r = math.sqrt(ox * ox + oy * oy)
        if r > base_radius then base_radius = r end
      end
      if base_radius == 0 then base_radius = 1.5 end

      -- Grow the radius so neighbours keep ~0.85 tiles of spacing no matter how
      -- many slots we end up generating (spacing = 2*pi*radius / slot_count).
      local spacing = 0.85
      local radius = math.max(base_radius, slot_count * spacing / (2 * math.pi))

      local expanded = {}
      for i = 0, slot_count - 1 do
        local angle = (2 * math.pi * i) / slot_count
        expanded[#expanded + 1] = { radius * math.cos(angle), radius * math.sin(angle) }
      end
      roboport.charging_offsets = expanded
      -- Stay 0/nil so the engine derives the slot count from the offsets above.
      roboport.charging_station_count = nil
    elseif roboport.charging_station_count and roboport.charging_station_count > 0 then
      -- Roboport that defines a slot count but no offsets (the engine
      -- auto-positions those stations); just multiply the count.
      roboport.charging_station_count = roboport.charging_station_count * 4
    end

    -- Quadruple charging energy per station (Energy is stored as a string, e.g. "1000kW")
    if roboport.charging_energy then
      roboport.charging_energy = multiply_energy(roboport.charging_energy, 4)
    end
  end
end
