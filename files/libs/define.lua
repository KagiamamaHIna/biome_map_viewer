ModDir = "mods/biome_map_viewer/"
ModID = "biome_map_viewer"
local ModID2 = ModID .. "."
-- ModVersion = "0.0.1"
-- ModLink = "none"
Int64Max = 2^63-1
Int32Max = 2^31-1

QuietNaN = 0/0

---Returns the value of a mod setting. 'id' should normally be in the format 'mod_name.setting_id'. Cache the returned value in your lua context if possible.
---@param id string
---@return boolean|number|string|nil
function SettingGet(id)
    return ModSettingGet(ModID2 .. id)
end

---Sets the value of a mod setting. 'id' should normally be in the format 'mod_name.setting_id'.
---@param id string
---@param value boolean|number|string
function SettingSet(id, value)
    ModSettingSet(ModID2 .. id, value)
end

---@param id string
---@return boolean was_removed
function SettingRemove(id)
    return ModSettingRemove(ModID2 .. id)
end
