dofile_once("mods/biome_map_viewer/files/libs/utilities.lua")
dofile_once("mods/biome_map_viewer/files/libs/EntityClass.lua")
dofile_once("mods/biome_map_viewer/files/gui/map.lua")
---@type Gui
local UI = dofile_once("mods/biome_map_viewer/files/libs/gui.lua")

UI.MainTickFn["Main"] = function()
    MapCacheUpdate(UI)
    local player = GetPlayerObj()
    if player == nil or GameIsInventoryOpen() then --下面只是按钮绘制
        return
    end

    MapUpdate(UI,player)
end

return {UI.DispatchMessage, UI.Destroy}
