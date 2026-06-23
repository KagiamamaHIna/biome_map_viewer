dofile_once("mods/biome_map_viewer/files/libs/utilities.lua")
dofile_once("mods/biome_map_viewer/files/libs/EntityClass.lua")
dofile_once("mods/biome_map_viewer/files/interface/MapPin.lua")
dofile_once("mods/biome_map_viewer/files/gui/mapHelper.lua")

local PosFormat = "%.2f"
local isMapOpen = false

---@param UI Gui
---@param player NoitaEntity
local function MapOpen(UI, player)
    local mapfile, mapimage = GetMapDatas()
    local ImgScale = GetImgScale()
    local ScaleRatio = GetScaleRatio()
    local PinList = GetPinList()
    local WorldWidth, WorldHeight = BiomeMapGetSize()
    local BiomeMap = GetBiomeMap()
    local MapX, MapY, MapW, MapH = GetMapXYandSize(UI)

    local ParallelWorld = GetParallelWorldPosition(player.attr.x, 0)
    if GetShowTopText() then
        --显示玩家坐标
        local PlayerPosStr = GameTextGet("$biome_map_viewer_playerxy", PosFormat:format(player.attr.x),
            PosFormat:format(player.attr.y))
        local PlayerPosStrWidth, PlayerPosStrHeight = UI.TextDimensions(PlayerPosStr)
        UI.Text(MapX + MapW / 2 - PlayerPosStrWidth / 2, MapY - 25, PlayerPosStr)

        --显示平行世界
        local ParallelWorldStr
        if ParallelWorld == 0 then
            ParallelWorldStr = GameTextGet("$biome_map_viewer_overworld")
        elseif ParallelWorld > 0 then
            ParallelWorldStr = GameTextGet("$biome_map_viewer_east", tostring(ParallelWorld))
        else
            ParallelWorldStr = GameTextGet("$biome_map_viewer_west", tostring(-ParallelWorld))
        end
        local biomeName = BiomeMapGetName(player.attr.x, player.attr.y)
        biomeName = GameTextGetTranslatedOrNot(biomeName ~= "_EMPTY_" and biomeName or "$biome_map_viewer_nameless")
        ParallelWorldStr = ParallelWorldStr .. GameTextGet("$menupause_location", biomeName)
        local ParallelWorldStrWidth = UI.TextDimensions(ParallelWorldStr)
        UI.Text(MapX + MapW / 2 - ParallelWorldStrWidth / 2, MapY - 23 - PlayerPosStrHeight, ParallelWorldStr)
    end
    
    --地图
    GuiBeginAutoBox(UI.gui)
    UI.NextZDeep(0)
    UI.Image("mapimage", MapX, MapY, mapimage, 0.8, ImgScale)
    local MapImageInfo = UI.WidgetInfoTable()
    UI.NextZDeep(-100)
    GuiEndAutoBoxNinePiece(UI.gui, 1, 0, 0, false, 0, "mods/biome_map_viewer/files/gfx/9piece_purple.png",
        "mods/biome_map_viewer/files/gfx/9piece_purple.png")
    UI.InputBlockEasy("MapBlock", MapImageInfo)

    --地图顶
    GuiBeginAutoBox(UI.gui)
    local MapIcon = "mods/biome_map_viewer/files/gfx/map.png"
    local MapIconW,MapIconH = UI.ImgDimension(MapIcon)
    UI.NextZDeep(0)
    UI.Image("MapIcon", MapX, MapY - MapIconH - 2, MapIcon)
    local MapIconInfo = UI.WidgetInfoTable()
    UI.GuiTooltip("$biome_map_viewer_close_map")
    if not UI.UserData["LastIconIsDrag"] and MapIconInfo.clicked then
        isMapOpen = not isMapOpen
        ClickSound()
    elseif not UI.UserData["LastIconIsDrag"] and MapIconInfo.right_clicked then
        ResetMapXY(UI)
        ClickSound()
    end
    local BarText = string.format("%s(%dx%d)",mapimage, WorldWidth, WorldHeight)
    local mapStrW,mapStrH = UI.TextDimensions(BarText,1,1,"data/fonts/font_pixel.xml")
    local TopBarY = MapY - mapStrH - 1
    local TopTextX = MapX + MapIconW + 2
    UI.NextZDeep(0)
    if mapStrW + MapIconW + 12 < MapW then
        UI.Text(TopTextX,TopBarY, BarText, 1,"data/fonts/font_pixel.xml")
    else
        UI.Text(TopTextX, TopBarY, "$biome_map_viewer_hover_to_show", 1, "data/fonts/font_pixel.xml")
        UI.GuiTooltip(BarText)
    end
    local SmallBtnImg = "mods/biome_map_viewer/files/gfx/window/null.png"
    local SmallBtnW = UI.ImgDimension(SmallBtnImg)
    UI.NextZDeep(0)
    UI.NextOption(GUI_OPTION.ClickCancelsDoubleClick)
    UI.Image("TopNull", MapX + MapW - SmallBtnW - 1, TopBarY, SmallBtnImg)
    local TopNullInfo = UI.WidgetInfoTable()
    if UI.UserData["TopNullClickCount"] and UI.UserData["TopNullClickCount"] >= 13 then
        local path = UI.UserData["TopNullTooltipPath"]
        if path == nil then
            local _,_,_,_,_,second= GameGetDateAndTimeLocal()
            SetRandomSeed(GameGetFrameNum(), second)
            path = string.format("mods/biome_map_viewer/files/gfx/window/yukimi%d.png",Random(1,5))
            UI.UserData["TopNullTooltipPath"] = path
        end
        UI.BetterTooltips(function ()
            UI.Image("yukimi", 0, 0,path,1,0.5)
        end,UI.GetZDeep() - 100)
    end
    if TopNullInfo.hovered and InputIsMouseButtonJustDown(Mouse_left)then
        if UI.UserData["TopNullClickCount"] == nil then
            UI.UserData["TopNullClickCount"] = 0
        end
        UI.UserData["TopNullClickCount"] = UI.UserData["TopNullClickCount"] + 1
    elseif not TopNullInfo.hovered then
        UI.UserData["TopNullClickCount"] = nil
        UI.UserData["TopNullTooltipPath"] = nil
    end
    UI.NextZDeep(-99)
    GuiEndAutoBoxNinePiece(UI.gui, 1, MapW, 0, false, 0, "mods/biome_map_viewer/files/gfx/9piece_purple_top.png",
        "mods/biome_map_viewer/files/gfx/9piece_purple_top.png")
    local isDrag, dx, dy = UI.Drag(MapX, MapY)
    if isDrag then
        SetMapXY(UI, dx, dy)
    elseif UI.UserData["LastIconIsDrag"] then
        SetMapXY(UI, dx, dy, true)
    end
    UI.UserData["LastIconIsDrag"] = isDrag

    --图标
    local activeObj
    for i, v in ipairs(PinList) do
        if not GetPinEnable() then
            break
        end
        if v.Pin.world and v.Pin.world ~= ParallelWorld then
            goto continue
        end
        if type(v.Pin.isEnabled) == "function" and not v.Pin.isEnabled(v.Map.world_x + ParallelWorld*512*WorldWidth, v.Map.world_y) then
            goto continue
        end
        local key = "Pin" .. i
        local alpha = v.Pin.alpha and v.Pin.alpha or 1
        local alphaKey = key .. "alpha"
        local maxKey = key .. "alpha_max"
        local scale = v.Pin.scale and v.Pin.scale or 1
        scale = scale * ScaleRatio
        UI.NextZDeep(50)
        if UI.UserData[key] then
            if UI.UserData[alphaKey] == nil then
                UI.UserData[alphaKey] = alpha
                UI.UserData[maxKey] = math.max(0, alpha - 0.5)
            elseif UI.UserData[alphaKey] > UI.UserData[maxKey] then
                UI.UserData[alphaKey] = UI.UserData[alphaKey] - 0.015
                UI.UserData[maxKey] = math.max(0, alpha - 0.5)
            else
                UI.UserData[alphaKey] = UI.UserData[alphaKey] + 0.015
                UI.UserData[maxKey] = alpha
            end
            alpha = UI.UserData[alphaKey]
            scale = scale * 1.1
        else
            UI.UserData[alphaKey] = nil
        end
        local iw, ih = UI.ImgDimension(v.Pin.icon, scale)
        local PinX = v.Map.x * ImgScale + MapX - iw / 2
        local PinY = v.Map.y * ImgScale + MapY - ih / 2
        if not GetOutsidePinEnable() and not (PinX > MapX and PinX < MapX + MapW and PinY > MapY and PinY < MapY + MapH) then
            goto continue
        end
        UI.Image(key, PinX, PinY, v.Pin.icon, alpha, scale)
        local info = UI.WidgetInfoTable()
        UI.UserData[key] = info.hovered
        if info.hovered then
            activeObj = v
        end
        ::continue::
    end

    local PlayerPinStatus = GetPlayerPinStatus()
    if PlayerPinStatus.id ~= "player_close" then
        --玩家位置换算地图坐标
        local PlayerMapX, PlayerMapY = WorldPosToMapPos(player.attr.x, player.attr.y, ParallelWorld)
        local PlayerIcon = "data/particles/spatial_map_player.png"
        local PlayerUIY = MapY + PlayerMapY
        if PlayerUIY >= MapY + MapH then
            PlayerUIY = MapY + MapH
            PlayerIcon = "mods/biome_map_viewer/files/gfx/playerdown.png"
        elseif PlayerUIY <= MapY then
            PlayerUIY = MapY
            PlayerIcon = "mods/biome_map_viewer/files/gfx/playerup.png"
        end
        local PlayerIconW, PlayerIconH = UI.ImgDimension(PlayerIcon)
        PlayerUIY = PlayerUIY - PlayerIconH / 2

        UI.NextZDeep(150)
        UI.ImageButton("PlayerIcon", MapX + PlayerMapX - PlayerIconW / 2, PlayerUIY, PlayerIcon)
        local PlayerUIIconInfo = UI.WidgetInfoTable()
        if PlayerPinStatus.id == "player_with_arrow" then
            local info = PlayerUIIconInfo
            local you = GameTextGet("$biome_map_viewer_your")
            UI.NextZDeep(25)
            local w = UI.ImgDimension(mapimage, ImgScale)
            if info.x > MapX + w / 2 then
                local str = you .. GameTextGet("$biome_map_viewer_right_arrow")
                local sw, sh = UI.TextDimensions(str)
                UI.Text(info.x - sw, info.y - sh + sh / 2 + info.height / 2, str)
            else
                local str = GameTextGet("$biome_map_viewer_left_arrow") .. you
                local _, h = UI.TextDimensions(str)
                UI.Text(info.x + info.width, info.y - h + h / 2 + info.height / 2, str)
            end
        end
    end


    --往左一个世界
    local UpWorldWidth, UpWorldHeight = UI.ImgDimension("mods/biome_map_viewer/files/gfx/up_world.png",ScaleRatio)
    GuiBeginAutoBox(UI.gui)
    UI.NextZDeep(0)
    UI.Image("UpWorld", MapX - UpWorldWidth, MapY + MapH / 2 - UpWorldHeight / 2, "mods/biome_map_viewer/files/gfx/up_world.png" , 1,ScaleRatio)
    local UpInfo = UI.WidgetInfoTable()
    UI.GuiTooltip("$biome_map_viewer_up_world")
    UI.NextZDeep(-99)
    GuiEndAutoBoxNinePiece(UI.gui, 1, 0, 0, false, 0, "mods/biome_map_viewer/files/gfx/9piece_purple.png",
    "mods/biome_map_viewer/files/gfx/9piece_purple.png")
    
    if UpInfo.clicked then
        SetCameraPlayerXY(player.attr.x - WorldWidth * 512)
        ClickSound()
    end

    --往右一个世界
    local NextWorldWidth, NextWorldHeight = UI.ImgDimension("mods/biome_map_viewer/files/gfx/next_world.png",ScaleRatio)
    GuiBeginAutoBox(UI.gui)
    UI.NextZDeep(0)
    UI.Image("NextWorld", MapX + MapW, MapY + MapH / 2 - NextWorldHeight / 2, "mods/biome_map_viewer/files/gfx/next_world.png", 1 ,ScaleRatio)
    local NextInfo = UI.WidgetInfoTable()
    UI.GuiTooltip("$biome_map_viewer_next_world")
    UI.NextZDeep(-99)
    GuiEndAutoBoxNinePiece(UI.gui, 1, 0, 0, false, 0, "mods/biome_map_viewer/files/gfx/9piece_purple.png",
    "mods/biome_map_viewer/files/gfx/9piece_purple.png")
    
    if NextInfo.clicked then
        SetCameraPlayerXY(player.attr.x + WorldWidth * 512)
        ClickSound()
    end
    
    local mx, my = UI.GetMousePosHasScale()
    if (mx > MapX and mx < MapX + MapW and my > MapY and my < MapY + MapH) or activeObj then
        local posx, posy = MapPosToWorldPos(UI, mx, my, ParallelWorld)

        UI.BetterTooltipsNoCenter(function(flag, inputX, leftOrRight, OffsetW, OffsetH)
            local NewLine = function(str, yoffset)
                yoffset = yoffset and yoffset or 0
                if not leftOrRight then
                    UI.Text(0, yoffset, str)
                else
                    local w = UI.TextDimensions(str)
                    UI.Text(-inputX - w, yoffset, str)
                end
            end
            local xOffset = leftOrRight and -8 or 8
            UI.CurrentZDeep(100)
            UI.BeginVertical(xOffset, 0, true, 0, -1)
            if not flag then
                GuiBeginAutoBox(UI.gui)
            end

            if activeObj then
                NewLine(activeObj.Pin.name)
            end
            NewLine(string.format("x:%.2f y:%.2f", posx, posy))
            local biome = BiomeMap[DebugBiomeMapGetFilename(posx, posy)]
            if biome then
                local location = GameTextGetTranslatedOrNot(biome.name ~= "_EMPTY_" and biome.name or "$biome_map_viewer_nameless")
                NewLine(strip(GameTextGet("$menupause_location", location)))
                NewLine(biome.file)
            else
                UI.NextColor(155, 173, 183, 255)
                NewLine("$biome_map_viewer_no_file_error")
            end

            if not GetIsHorizontal() then
                if not flag and activeObj and activeObj.Pin.image then
                    local scale = activeObj.Pin.imageScale and activeObj.Pin.imageScale or 1
                    local w, h = UI.ImgDimension(activeObj.Pin.image, scale)
                    if leftOrRight then
                        UI.Image("Pinimage", -w - 10, -h, activeObj.Pin.image, 1, scale)
                    else
                        UI.Image("Pinimage", OffsetW, -h, activeObj.Pin.image, 1, scale)
                    end
                end
            elseif GetIsHorizontal() and activeObj and activeObj.Pin.image then
                local scale = activeObj.Pin.imageScale and activeObj.Pin.imageScale or 1
                if not leftOrRight then
                    UI.Image("Pinimage",0, 0, activeObj.Pin.image, 1, scale)
                else
                    local w, h = UI.ImgDimension(activeObj.Pin.image, scale)
                    UI.Image("Pinimage",-inputX - w, 0, activeObj.Pin.image, 1, scale)
                end
            end

            UI.LayoutEnd()
            if not flag then
                UI.NextZDeep(70)
                GuiEndAutoBoxNinePiece(UI.gui, 2, 0, 0, false, 0, "mods/biome_map_viewer/files/gfx/9piece0_blue.png",
                    "mods/biome_map_viewer/files/gfx/9piece0_blue.png")
            end
            UI.CurrentZDeep(-100)
        end, UI.GetZDeep() - 100, 0, 6, 0, 0, true, mx, my, false, true)

        if InputIsMouseButtonJustDown(Mouse_right) then
            SetCameraPlayerXY(posx, posy)
            TeleSound(posx,posy)
            if GetTeleAfterCloseMap() then
                isMapOpen = false
            end
        elseif activeObj and InputIsMouseButtonJustDown(Mouse_left) then
            local x = activeObj.Map.world_x
            if activeObj.Pin.world == nil then
                x = x + ParallelWorld * 512 * WorldWidth
            end
            local y = activeObj.Map.world_y
            local tpXOffset = activeObj.Pin.tpXOffset and activeObj.Pin.tpXOffset or 0
            local tpYOffset = activeObj.Pin.tpYOffset and activeObj.Pin.tpYOffset or 0
            SetCameraPlayerXY(x + tpXOffset, y + tpYOffset)
            TeleSound(x + tpXOffset, y + tpYOffset)
            if GetTeleAfterCloseMap() then
                isMapOpen = false
            end
        end

        if InputIsMouseButtonJustDown(Mouse_wheel_up) then
            AddImgScale()
        elseif InputIsMouseButtonJustDown(Mouse_wheel_down) then
            ReduceImgScale()
        end
    end
    
    -- --左部按钮
    -- UI.BeginVertical(MapX - 12, MapY + 4, true,2,4)
    -- GuiBeginAutoBox(UI.gui)

    -- UI.NextOption(GUI_OPTION.ClickCancelsDoubleClick)
    -- UI.NextZDeep(0)
    -- local addScaleClick = UI.ImageButton("addScale", 0, 0, "mods/biome_map_viewer/files/gfx/bottom/add.png")
    -- if addScaleClick and ImgScale < 6 then
    --     ImgScale = ImgScale + 0.25
    -- end

    -- UI.NextOption(GUI_OPTION.ClickCancelsDoubleClick)
    -- UI.NextZDeep(0)
    -- local reduceScaleClick = UI.ImageButton("reduceScale", 0, 0, "mods/biome_map_viewer/files/gfx/bottom/reduce.png")
    -- if reduceScaleClick and ImgScale > 2 then
    --     ImgScale = ImgScale - 0.25
    -- end
    
    -- UI.NextZDeep(-99)
    -- GuiEndAutoBoxNinePiece(UI.gui, 1, 0, 0, false, 0, "mods/biome_map_viewer/files/gfx/9piece_purple_left.png",
    --     "mods/biome_map_viewer/files/gfx/9piece_purple_left.png")
    -- UI.InputBlockEasy("LeftBtns", UI.WidgetInfoTable())
    --底部按钮
    UI.BeginHorizontal(MapX, MapY + MapH + 2, true,4)
    GuiBeginAutoBox(UI.gui)

    UI.NextOption(GUI_OPTION.DrawWaveAnimateOpacity)
    UI.NextZDeep(0)
    UI.ImageButton("TipsBtn", 0, 0, "mods/biome_map_viewer/files/gfx/bottom/unknown.png")
    UI.GuiTooltip("$biome_map_viewer_tips")

    if not GetPinEnable() then
        UI.NextOption(GUI_OPTION.DrawSemiTransparent)
    end
    UI.NextZDeep(0)
    local MapPinClick = UI.ImageButton("MapPinEnable", 0, 0, "mods/biome_map_viewer/files/gfx/bottom/pinicon.png")
    UI.GuiTooltip("$biome_map_viewer_hide_pin")
    if MapPinClick then
        SetPinEnable(not GetPinEnable())
        ClickSound()
    end

    if not GetOutsidePinEnable() then
        UI.NextOption(GUI_OPTION.DrawSemiTransparent)
    end
    UI.NextZDeep(0)
    local OutsidePinClick = UI.ImageButton("OutsidePinEnable", 0, 0, "mods/biome_map_viewer/files/gfx/bottom/outside_pin.png")
    UI.GuiTooltip("$biome_map_viewer_hide_outside_pin")
    if OutsidePinClick then
        SetOutsidePinEnable(not GetOutsidePinEnable())
        ClickSound()
    end
    
    UI.NextZDeep(0)
    local PlayerPinStatusClick,PlayerPinStatusRightClick = UI.ImageButton("PlayerPinStauts", 0, 0, PlayerPinStatus.icon)
    UI.GuiTooltip(PlayerPinStatus.desc)
    if PlayerPinStatusClick then
        NextPlayerPinStatus()
        ClickSound()
    elseif PlayerPinStatusRightClick then
        UpPlayerPinStatus()
        ClickSound()
    end

    if not GetTeleAfterCloseMap() then
        UI.NextOption(GUI_OPTION.DrawSemiTransparent)
    end
    UI.NextZDeep(0)
    local Tele1Click = UI.ImageButton("TeleAfterCloseMap", 0, 0, "mods/biome_map_viewer/files/gfx/bottom/tele1.png")
    UI.GuiTooltip("$biome_map_viewer_tele_close_map")
    if Tele1Click then
        SetTeleAfterCloseMap(not GetTeleAfterCloseMap())
        ClickSound()
    end

    if not GetIsHorizontal() then
        UI.NextOption(GUI_OPTION.DrawSemiTransparent)
    end
    UI.NextZDeep(0)
    local ImageSwitchClick = UI.ImageButton("IsHorizontal", 0, 0, "mods/biome_map_viewer/files/gfx/bottom/image_switch.png")
    UI.GuiTooltip("$biome_map_viewer_horizontal2vertical_img")
    if ImageSwitchClick then
        SetIsHorizontal(not GetIsHorizontal())
        ClickSound()
    end

    if not GetShowTopText() then
        UI.NextOption(GUI_OPTION.DrawSemiTransparent)
    end
    UI.NextZDeep(0)
    local ShowTopTextClick = UI.ImageButton("ShowTopText", 0, 0, "mods/biome_map_viewer/files/gfx/bottom/toptext.png")
    UI.GuiTooltip("$biome_map_viewer_show_top_text")
    if ShowTopTextClick then
        SetShowTopText(not GetShowTopText())
        ClickSound()
    end

    UI.NextZDeep(-99)
    GuiEndAutoBoxNinePiece(UI.gui, 1, 0, 0, false, 0, "mods/biome_map_viewer/files/gfx/9piece_purple_bottom.png",
        "mods/biome_map_viewer/files/gfx/9piece_purple_bottom.png")
    UI.LayoutEnd()
end

---@param UI Gui
---@param player NoitaEntity
local function MapClose(UI,player)
    local WorldWidth, WorldHeight = BiomeMapGetSize()
    MapCacheUpdate(UI)
    local MapX, MapY = GetMapIconXY(UI)

    GuiBeginAutoBox(UI.gui)
    local MapIcon = "mods/biome_map_viewer/files/gfx/map.png"
    local MapIconW,MapIconH = UI.ImgDimension(MapIcon)
    UI.NextZDeep(0)
    UI.Image("MapIcon", MapX, MapY - MapIconH - 2, MapIcon)
    local MapIconInfo = UI.WidgetInfoTable()
    UI.GuiTooltip("$biome_map_viewer_open_map")
    if not UI.UserData["LastIconIsDrag"] and MapIconInfo.clicked then
        isMapOpen = not isMapOpen
        ClickSound()
    elseif not UI.UserData["LastIconIsDrag"] and MapIconInfo.right_clicked then
        ResetMapIconXY(UI)
        ClickSound()
    end
    UI.NextZDeep(-99)
    GuiEndAutoBoxNinePiece(UI.gui, 1, 0, 0, false, 0, "mods/biome_map_viewer/files/gfx/9piece_purple.png",
        "mods/biome_map_viewer/files/gfx/9piece_purple.png")
    local isDrag, dx, dy = UI.Drag(MapX, MapY)
    if isDrag then
        SetMapIconXY(UI, dx, dy)
    elseif UI.UserData["LastIconIsDrag"] then
        SetMapIconXY(UI, dx, dy, true)
    end
    UI.UserData["LastIconIsDrag"] = isDrag
end

---@param UI Gui
---@param player NoitaEntity
function MapUpdate(UI, player)
    InitUIParam(UI)
    MapCacheUpdate(UI)

    local SrcZ = UI.GetZDeep()
    UI.SetZDeep(-10000)
    if InputIsKeyDown(Key_n) and InputIsKeyDown(Key_m) then
        if UI.UserData["OpenMapKey"] == nil then
            UI.UserData["OpenMapKey"] = true
            isMapOpen = not isMapOpen
        end
    else
        UI.UserData["OpenMapKey"] = nil
    end
    if isMapOpen then
        MapOpen(UI, player)
    else
        MapClose(UI, player)
    end
    
    UI.SetZDeep(SrcZ)
end
