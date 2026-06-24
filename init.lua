local SrcCsv = ModTextFileGetContent("data/translations/common.csv") --设置新语言文件
local AddCsv = dofile_once("mods/biome_map_viewer/files/lang/tocsv.lua")
ModTextFileSetContent("data/translations/common.csv", SrcCsv .. AddCsv)

local GUIData
function OnWorldPostUpdate()
    if GUIData == nil then
        GUIData = dofile("mods/biome_map_viewer/files/gui/update.lua")
    end
    GUIData[1]()
end
