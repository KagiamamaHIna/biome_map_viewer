local SrcCsv = ModTextFileGetContent("data/translations/common.csv") --设置新语言文件
local AddCsv = dofile_once("mods/biome_map_viewer/files/lang/tocsv.lua")
ModTextFileSetContent("data/translations/common.csv", SrcCsv .. AddCsv)

local GUIData = dofile("mods/biome_map_viewer/files/gui/update.lua")
function OnWorldPostUpdate()
    GUIData[1]()
end
