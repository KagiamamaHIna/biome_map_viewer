local nxml = dofile_once("mods/biome_map_viewer/files/libs/nxml.lua")
dofile_once("mods/biome_map_viewer/files/libs/utilities.lua")
dofile_once("mods/biome_map_viewer/files/libs/EntityClass.lua")
dofile_once("mods/biome_map_viewer/files/libs/define.lua")

local mapfile, mapimage
local lastPlayerID
local BiomeMap
local PinList
local ImgDef = 6
if SettingGet("ImgScale") == nil then
    SettingSet("ImgScale", ImgDef)
end
local ImgScale = SettingGet("ImgScale")

---初始化窗口参数
---@param UI any
function InitUIParam(UI)
    if UI.UserData["UIParamInit"] ~= nil then
        return
    end
    UI.UserData["UIParamInit"] = true
    UI.UserData["SmallWindow"] = false
end

---fn可以自定义在判断需要重载的时候加载
---@param fn function?
function InitMap(fn)
    --小技巧，BiomeMapLoad_KeepPlayer会重新加载玩家导致玩家id变化，以此检测需要刷新的情况
    local player = GetPlayer()
    if player ~= 0 and lastPlayerID ~= player then
        if lastPlayerID ~= nil then --第一次加载玩家的时候不用进行重置
            mapfile = nil
            mapimage = nil
        end
        lastPlayerID = GetPlayer()
    end
    if mapfile == nil or mapfile ~= SessionNumbersGetValue("BIOME_MAP") then
        mapfile, mapimage = GetBiomeMapData()
        if type(fn) == "function" then
            fn()
        end
    end
end

---@return string mapfile, string mapimage
function GetMapDatas()
    return mapfile, mapimage
end

---@param UI Gui
---@param x number
---@param y number
---@param save boolean?
function SetMapXY(UI, x, y, save)
    if save then
        SettingSet("MapX", x)
        SettingSet("MapY", y)
    end

    UI.UserData["MapX"] = x
    UI.UserData["MapY"] = y
end

---@param UI Gui
function ResetMapXY(UI)
    SettingRemove("MapX")
    SettingRemove("MapY")
    UI.UserData["MapX"] = nil
    UI.UserData["MapY"] = nil
end

---@param UI Gui
---@return number x
---@return number y
---@return number w
---@return number h
function GetMapXYandSize(UI)
    InitMap()
    local imgW, imgH = UI.ImgDimension(mapimage, ImgScale)
    if UI.UserData["MapX"] and UI.UserData["MapY"] then
        return UI.UserData["MapX"], UI.UserData["MapY"], imgW, imgH
    else
        local x = SettingGet("MapX")
        local y = SettingGet("MapY")
        if type(x) ~= "number" or type(y) ~= "number" then
            x = UI.ScreenWidth / 2 - imgW / 2
            y = UI.ScreenHeight / 2 - imgH / 2 + 18--因为屏蔽不掉原版的ui点击，所以往下偏一点隐藏问题
        end
        SetMapXY(UI, x, y)
        return x, y, imgW, imgH
    end
end

---@param UI Gui
---@param x number
---@param y number
---@param save boolean?
function SetMapIconXY(UI, x, y, save)
    if save then
        SettingSet("MapIconX", x)
        SettingSet("MapIconY", y)
    end

    UI.UserData["MapIconX"] = x
    UI.UserData["MapIconY"] = y
end

---@param UI Gui
function ResetMapIconXY(UI)
    SettingRemove("MapIconX")
    SettingRemove("MapIconY")
    UI.UserData["MapIconX"] = nil
    UI.UserData["MapIconY"] = nil
end

---@param UI Gui
---@return integer
---@return number
function GetMapIconXY(UI)
    local x = 205
    local y = 17.5
    if UI.UserData["MapIconX"] and UI.UserData["MapIconY"] then
        return UI.UserData["MapIconX"], UI.UserData["MapIconY"]
    else
        local sx = SettingGet("MapIconX")
        local sy = SettingGet("MapIconY")
        if type(sx) ~= "number" or type(sy) ~= "number" then
            sx = x
            sy = y
        end
        SetMapIconXY(UI, sx, sy)
        return sx, sy
    end
end

---获取地图零点
---@return number x, number y
function GetMapZero()
    local WorldWidth = BiomeMapGetSize()
    return math.floor(WorldWidth / 2), 14
end

---将世界中的坐标转换为地图上的坐标
---@param x number
---@param y number
---@param ParallelWorld number
---@return number x,number y
function WorldPosToMapPos(x, y, ParallelWorld)
    local WorldWidth = BiomeMapGetSize()
    local inZeroX, inZeroY = GetMapZero()
    local resultX = ((x - (ParallelWorld * WorldWidth * 512)) / 512 + inZeroX) * ImgScale
    local resultY = (y / 512 + inZeroY) * ImgScale
    return resultX,resultY
end

---将地图中的坐标转换成世界中的坐标
---@param UI Gui
---@param x number
---@param y number
---@param ParallelWorld number
---@return number x,number y
function MapPosToWorldPos(UI, x, y, ParallelWorld)
    local MapX, MapY, MapW, MapH = GetMapXYandSize(UI)
    local WorldWidth = BiomeMapGetSize()
    local inMapX = (x - MapX) / ImgScale
    local inMapY = (y - MapY) / ImgScale
    local inZeroX, inZeroY = GetMapZero()
    local posx = (inMapX - inZeroX) * 512 + (ParallelWorld * WorldWidth * 512)
    local posy = (inMapY - inZeroY) * 512
    return posx,posy
end

function RefreshBiomeMap(UI)
    BiomeMap = {}
    PinList = {}
    --进行地图扫描
    local MapX, MapY, MapW, MapH = GetMapXYandSize(UI)
    local WorldWidth, WorldHeight = BiomeMapGetSize()
    print("world:",WorldWidth,",",WorldHeight)
    for i = 0, WorldWidth - 1 do
        for j = 0, WorldHeight - 1 do
            local CenterX = i + 0.5
            local CenterY = j + 0.5
            local posx, posy = MapPosToWorldPos(UI, CenterX * ImgScale + MapX, CenterY * ImgScale + MapY, 0)
            local file = DebugBiomeMapGetFilename(posx, posy)

            local name = "_EMPTY_"
            local wang_title
            local fileText = ModTextFileGetContent(file)
            if fileText == nil or fileText == "" then
                goto continue
            end
            local xml = nxml.parse(fileText)
            for _, elem in ipairs(xml.children) do
                if elem.name ~= "Topology" then
                    goto continue
                end
                name = elem.attr.name
                wang_title = elem.attr.wang_template_file
                ::continue::
            end
            BiomeMap[file] = {
                x = CenterX,
                y = CenterY,
                world_x = posx,
                world_y = posy,
                xml = xml,
                name = name,
                wang_title = wang_title,
                file = file
            }
            if MapPin[file] then
                PinList[#PinList + 1] = { Map = BiomeMap[file], Pin = MapPin[file] }
            end
            ::continue::
        end
    end
    --扫描PixelScene
    local psfile = SessionNumbersGetValue("BIOME_MAP_PIXEL_SCENES")
    local ps = nxml.parse(ModTextFileGetContent(psfile))
    for _,v in ipairs(ps.children)do
        if v.name ~= "mBufferedPixelScenes" then
            goto continue
        end
        for _,elem in ipairs(v.children)do
            if elem.name ~= "PixelScene" then
                goto continue
            end
            if elem.attr.just_load_an_entity == nil then
                goto continue
            end
            local pin = MapPin[elem.attr.just_load_an_entity]
            if pin == nil then
                goto continue
            end
            local x = tonumber(elem.attr.pos_x)
            local y = tonumber(elem.attr.pos_y)
            if x == nil or y == nil then
                goto continue
            end
            local world = GetParallelWorldPosition(x, 0)
            local mx, my = WorldPosToMapPos(x, y, world)
            local NewPin = DeepCopy(pin)
            NewPin.world = world
            PinList[#PinList + 1] = {
                Map = {x = mx / ImgScale,y = my / ImgScale, world_x = x, world_y = y},
                Pin = NewPin,
            }
            ::continue::
        end
        ::continue::
    end
    --固定坐标转换
    for _,v in ipairs(FixedPin)do
        local world = GetParallelWorldPosition(v.x, 0)
        local x, y = WorldPosToMapPos(v.x, v.y, world)
        local NewPin = DeepCopy(v)
        if not v.HasParallel then
            NewPin.world = world
        end
        PinList[#PinList + 1] = {
            Map = {x = x / ImgScale,y = y / ImgScale, world_x = v.x, world_y = v.y},
            Pin = NewPin,
        }
    end
end

function GetScaleRatio()
    return ImgScale / ImgDef
end

function GetImgScale()
    return ImgScale
end

function GetPinList()
    return PinList
end

function GetBiomeMap()
    return BiomeMap
end

function AddImgScale()
    if ImgScale < 6 then
        ImgScale = ImgScale + 0.25
    end
    SettingSet("ImgScale", ImgScale)
end

function ReduceImgScale()
    if ImgScale > 2 then
        ImgScale = ImgScale - 0.25
    end
    SettingSet("ImgScale", ImgScale)
end

---@return boolean
function GetPinEnable()
    local result = SettingGet("PinEnable")
    if result == nil then
        SettingSet("PinEnable", true)
        result = true
    end
    return result
end

---@param enable boolean
function SetPinEnable(enable)
    SettingSet("PinEnable", enable)
end

---@return boolean
function GetOutsidePinEnable()
    local result = SettingGet("OutsidePinEnable")
    if result == nil then
        SettingSet("OutsidePinEnable", true)
        result = true
    end
    return result
end

---@param enable boolean
function SetOutsidePinEnable(enable)
    SettingSet("OutsidePinEnable", enable)
end

function MapCacheUpdate(UI)
    InitMap(function ()
        RefreshBiomeMap(UI)
    end)
end

local PlayerPinStatus = {
    {
        id = "player_with_arrow",
        icon = "mods/biome_map_viewer/files/gfx/bottom/player_arrow.png",
        desc = "$biome_map_viewer_player_pin_with_arrow"
    },
    {
        id = "player",
        icon = "mods/biome_map_viewer/files/gfx/bottom/player.png",
        desc = "$biome_map_viewer_player_pin"
    },
    {
        id = "player_close",
        icon = "mods/biome_map_viewer/files/gfx/bottom/player_grey.png",
        desc = "$biome_map_viewer_close_player_pin"
    }
}

function GetPlayerPinStatus()
    local index = SettingGet("PlayerPinStatus")
    if index == nil then
        index = 1
        SettingSet("PlayerPinStatus", index)
    end
    return PlayerPinStatus[index]
end

function NextPlayerPinStatus()
    local index = SettingGet("PlayerPinStatus") + 1
    if index > #PlayerPinStatus then
        index = 1
    end
    SettingSet("PlayerPinStatus", index)
end

function UpPlayerPinStatus()
    local index = SettingGet("PlayerPinStatus") - 1
    if index < 1 then
        index = #PlayerPinStatus
    end
    SettingSet("PlayerPinStatus", index)
end

local TeleStatus = {
    {
        id = "close_tele1",
        icon = "mods/biome_map_viewer/files/gfx/bottom/tele1_grey.png",
        desc = "$biome_map_viewer_tele_close_map_close"
    },
    {
        id = "tele1_with_pw",
        icon = "mods/biome_map_viewer/files/gfx/bottom/tele1_with_pw.png",
        desc = "$biome_map_viewer_tele_close_map"
    },
    {
        id = "tele1",
        icon = "mods/biome_map_viewer/files/gfx/bottom/tele1.png",
        desc = "$biome_map_viewer_tele_close_map_2"
    }
}

function GetTeleAfterCloseMap()
    local index = SettingGet("TeleAfterCloseMapStatus")
    if index == nil then
        index = 1
        SettingSet("TeleAfterCloseMapStatus", index)
    end
    return TeleStatus[index]
end

function NextTeleAfterCloseMap()
    local index = SettingGet("TeleAfterCloseMapStatus") + 1
    if index > #TeleStatus then
        index = 1
    end
    SettingSet("TeleAfterCloseMapStatus", index)
end

function UpTeleAfterCloseMap()
    local index = SettingGet("TeleAfterCloseMapStatus") - 1
    if index < 1 then
        index = #TeleStatus
    end
    SettingSet("TeleAfterCloseMapStatus", index)
end

function GetIsHorizontal()
    local result = SettingGet("HorizontalImg")
    if result == nil then
        SettingSet("HorizontalImg", false)
        result = false
    end
    return result
end

---@param enable boolean
function SetIsHorizontal(enable)
    SettingSet("HorizontalImg", enable)
end

function GetShowTopText()
    local result = SettingGet("ShowTopText")
    if result == nil then
        SettingSet("ShowTopText", true)
        result = true
    end
    return result
end

---@param enable boolean
function SetShowTopText(enable)
    SettingSet("ShowTopText", enable)
end
