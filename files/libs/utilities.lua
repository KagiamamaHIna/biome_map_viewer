local sandbox = dofile("mods/biome_map_viewer/files/libs/SandBox.lua")

---获取地图文件
---@return string path,string image
function GetBiomeMapData()
    local BiomeMap = SessionNumbersGetValue("BIOME_MAP")
    if BiomeMap:sub(-3) == "png" then
        return BiomeMap, BiomeMap
    end
    local fn, env = sandbox(loadfile(BiomeMap))
    local ImageFilename
    env.BiomeMapLoadImage = function(_, _, img)
        ImageFilename = img
    end
    pcall(fn)
    return BiomeMap, ImageFilename
end

function ClickSound()
	GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", GameGetCameraPos())
end

function TeleSound(x,y)
    GamePlaySound("data/audio/Desktop/misc.bank", "game_effect/teleport/tick", x,y)
end

---可以同时设置相机和玩家位置的函数
---@param x number?
---@param y number?
function SetCameraPlayerXY(x, y)
    local player = GetPlayerObj()
    if player == nil then
        return
    end
    x = x and x or player.attr.x
    y = y and y or player.attr.y
    player.attr.x = x
    player.attr.y = y
    local pspc = player.comp.PlatformShooterPlayerComponent
    if pspc then
        local SrcPos = pspc[1].attr.mSmoothedCameraPosition
        local Desired = pspc[1].attr.mDesiredCameraPos
        local xOffset = Desired.x - SrcPos.x
        local yOffset = Desired.y - SrcPos.y
        pspc[1].set_attrs = {
            mSmoothedCameraPosition = { x = x, y = y },
            mDesiredCameraPos = {x = x + xOffset, y = y + yOffset}
        }
    end
end
