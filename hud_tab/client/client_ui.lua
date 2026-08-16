local iOpenTick = 0

local pingCache       = {}
local pingLastUpdate  = 0
local PING_UPDATE_MS  = 3000

local sx, sy = 600 * cfX, scy - 150 * cfY
local px, py = (scx - sx) / 2, 130 * cfY

local function makeFont(file, size)
    return dxCreateFont("files/fonts/" .. file, math.floor(size * cfY), false, "cleartype")
end

local fonts = {
    medium_10  = makeFont("gothampro_medium.ttf",  10),
    regular_10 = makeFont("gothampro_regular.ttf", 10),
    regular_7  = makeFont("gothampro_regular.ttf",  7),
    regular_6  = makeFont("gothampro_regular.ttf",  6),
}

local graphical    = exports.graphical
local shPingBorder = nil

local sortColumn = nil
local sortAsc    = true

local TabSettings = {
    opened = false,
    coloredNames = false,
    iconBox = nil,
    colorBox = nil,
}

local function isMouseIn(x, y, w, h)
    if not isCursorShowing() then return false end
    local cx, cy = getCursorPosition()
    if not cx then return false end
    cx, cy = cx * scx, cy * scy
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

local function loadTabSettings()
    local xml = xmlLoadFile("@tab_settings.xml")
    if not xml then
        TabSettings.coloredNames = false
        return
    end

    local value = xmlNodeGetAttribute(xml, "coloredNames")
    TabSettings.coloredNames = (value == "true" or value == "1")
    xmlUnloadFile(xml)
end

local function saveTabSettings()
    local xml = xmlLoadFile("@tab_settings.xml")
    if not xml then
        xml = xmlCreateFile("@tab_settings.xml", "settings")
    end
    if not xml then return end

    xmlNodeSetAttribute(xml, "coloredNames", TabSettings.coloredNames and "true" or "false")
    xmlSaveFile(xml)
    xmlUnloadFile(xml)
end

loadTabSettings()

local TestOnline = {
    enabled = true,
    clans = {
        {
            name = "Администрация",
            color = {255, 0, 0},
            players = {
                {name = "#FF0000codecvv", time = "115 ч.", ping = 24, premium = true, admin = true},
                {name = "#FFFFFFenotov", time = "74 ч.", ping = 36, admin = true},
            }
        },
        {
            name = "Need For Speed",
            color = {254, 184, 95},
            players = {
			    {name = "#FEB85FTarasiuk", time = "42 ч.", ping = 58, premium = true, afk = true, afkSeconds = 125},
                {name = "#4B7DFATimur", time = "201 ч.", ping = 26, premium = true},
                {name = "#4B7DFAGambino", time = "61 ч.", ping = 101, premium = true},
                {name = "#FEB85FJason_Statham", time = "33 ч.", ping = 47, afk = true, afkSeconds = 235},
                {name = "#FF6B6BSixSeven", time = "19 ч.", ping = 92, premium = true},
                {name = "#B56CFFfredi", time = "211 ч.", ping = 41, afk = true, afkSeconds = 543},
                {name = "#4BD8FARENAS", time = "88 ч.", ping = 67},
            }
        },
        {
            name = "Игроки без клана",
            color = {35, 125, 250},
            players = {
			    {name = "#A0C4FFabez9na", time = "97 ч.", ping = 46},
                {name = "#FDFFB6Nik1ta", time = "25 ч.", ping = 86},
                {name = "#CAFFBFAlexXx", time = "170 ч.", ping = 52, premium = true},
                {name = "#FFADADAnGel", time = "7 ч.", ping = 112, afk = true, afkSeconds = 47},
                {name = "#BDB2FFbengal", time = "44 ч.", ping = 65},
                {name = "#FFC6FFnoname", time = "132 ч.", ping = 39},
                {name = "#FF6B6BMontana", time = "82 ч.", ping = 73},
                {name = "#B56CFFMichael", time = "18 ч.", ping = 135},
                {name = "#4BD8FADragonStar", time = "56 ч.", ping = 55},
                {name = "#80FFB0Durden", time = "109 ч.", ping = 34, premium = true},
                {name = "#FFD166Warter", time = "29 ч.", ping = 89},
                {name = "#9AD0FFODeLuca", time = "147 ч.", ping = 43},
                {name = "#C4F000Anderson", time = "72 ч.", ping = 118, afk = true, afkSeconds = 278},
                {name = "#FF9F1CMarco", time = "11 ч.", ping = 64},
                {name = "#A0C4FFConti", time = "95 ч.", ping = 49},
				{name = "#80FFB0starik", time = "36 ч.", ping = 120, afk = true, afkSeconds = 314},
                {name = "#FFD166balbes", time = "53 ч.", ping = 28},
                {name = "#9AD0FFGUF", time = "128 ч.", ping = 75, premium = true},
                {name = "#C4F000shwed", time = "13 ч.", ping = 144},
                {name = "#FF9F1Ckuklovod", time = "64 ч.", ping = 31},
                {name = "#CAFFBFLGBT+", time = "156 ч.", ping = 37, premium = true},
				
            }
        },
    }
}

local function stripColorCodes(text)
    return tostring(text or ""):gsub("#%x%x%x%x%x%x", "")
end

local function formatAFKTime(seconds)
    seconds = math.max(0, tonumber(seconds) or 0)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local sec = math.floor(seconds % 60)
    if h > 0 then
        return string.format("%02d:%02d:%02d", h, m, sec)
    end
    return string.format("%02d:%02d", m, sec)
end

local function getTestOnlineCount()
    local count = 0
    for _, clan in ipairs(TestOnline.clans) do
        count = count + #clan.players
    end
    return count
end

addCommandHandler("tabtest", function(_, mode)
    mode = tostring(mode or ""):lower()
    if mode == "on" or mode == "1" then
        TestOnline.enabled = true
        outputChatBox("Тестовый TAB включен.", 75, 125, 250)
    elseif mode == "off" or mode == "0" then
        TestOnline.enabled = false
        outputChatBox("Тестовый TAB выключен.", 75, 125, 250)
    else
        outputChatBox("Использование: /tabtest on или /tabtest off", 255, 255, 255)
    end
end)

function GetTeamsList()
    local list        = {}
    local teamPlayers = {}
    local localTeam   = getPlayerTeam(localPlayer)

    if TestOnline.enabled then
        local fakeID = 0
        for _, clan in ipairs(TestOnline.clans) do
            table.insert(list, { type = "team", fake = true, name = clan.name, color = clan.color })
            for _, playerData in ipairs(clan.players) do
                fakeID = fakeID + 1
                table.insert(list, { type = "player", fake = true, id = fakeID, data = playerData, clan = clan.name })
            end
        end
        return list
    end

    local function sortPlayers(arr)
        if not sortColumn then return end
        table.sort(arr, function(a, b)
            local va, vb
            if sortColumn == "name" then
                va = string.lower((getPlayerName(a.player) or ""):gsub("#%x%x%x%x%x%x", ""):gsub("^@+", ""))
                vb = string.lower((getPlayerName(b.player) or ""):gsub("#%x%x%x%x%x%x", ""):gsub("^@+", ""))
            elseif sortColumn == "time" then
                va = tonumber((tostring(getElementData(a.player, "timePlayed") or "")):match("^(%S+)")) or 0
                vb = tonumber((tostring(getElementData(b.player, "timePlayed") or "")):match("^(%S+)")) or 0
            elseif sortColumn == "ping" then
                va = pingCache[a.player] or getPlayerPing(a.player)
                vb = pingCache[b.player] or getPlayerPing(b.player)
            end
            if va == vb then return false end
            if sortAsc then return va < vb else return va > vb end
        end)
    end

    if not localTeam then
        teamPlayers[localPlayer] = true
        table.insert(list, { type = "player", player = localPlayer })
    end

    local orderedTeams = {}
    for _, team in pairs(getElementsByType("team")) do
        local playersInTeam = getPlayersInTeam(team)
        if #playersInTeam > 0 then
            if team == localTeam then
                table.insert(orderedTeams, 1, team)
            else
                table.insert(orderedTeams, team)
            end
        end
    end

    for _, team in ipairs(orderedTeams) do
        local members = {}
        for _, player in pairs(getPlayersInTeam(team)) do
            teamPlayers[player] = true
            table.insert(members, { type = "player", player = player })
        end
        sortPlayers(members)
        if team == localTeam then
            for i, m in ipairs(members) do
                if m.player == localPlayer then
                    table.remove(members, i)
                    table.insert(members, 1, m)
                    break
                end
            end
        end
        table.insert(list, { type = "team", team = team })
        for _, m in ipairs(members) do table.insert(list, m) end
    end

    local noTeam = {}
    for _, player in pairs(getElementsByType("player")) do
        if not teamPlayers[player] then
            table.insert(noTeam, { type = "player", player = player })
        end
    end

    if #noTeam > 0 then
        if #list > 0 then table.insert(list, { type = "separator" }) end
        sortPlayers(noTeam)
        for _, p in ipairs(noTeam) do table.insert(list, p) end
    end

    return list
end

-- Hover
local hoveredPlayer   = nil
local hoverAlphas     = {}
local HOVER_SPEED_IN  = 0.08
local HOVER_SPEED_OUT = 0.05

local playtimeBgAlpha     = 0
local PLAYTIME_FADE_IN  = 0.04
local PLAYTIME_FADE_OUT = 0.006
local prevTimePlayed  = {}

local afkIconAlpha    = {}
local AFK_ICON_SPEED  = 0.05

local headerHitboxes  = {}
local scrollThumbRect = nil 

local SCROLL_MIN_PLAYERS = 10

function RenderTab()
    local now = getTickCount()
    if now - pingLastUpdate >= PING_UPDATE_MS then
        pingLastUpdate = now
        for _, p in ipairs(getElementsByType("player")) do
            pingCache[p] = getPlayerPing(p)
        end
    end

    local progress
    if IS_WINDOW_OPENED then
        progress = getEasingValue(Clamp(0.0, (getTickCount() - iOpenTick) / 450, 1.0), "InOutQuad")
    else
        progress = interpolateBetween(1, 0, 0, 0, 0, 0, (getTickCount() - iOpenTick) / 450, "InOutQuad")
        if progress <= 0 then
            removeEventHandler("onClientRender", root, RenderTab)
            return
        end
    end

    local white_color = tocolor(255, 255, 255, 255 * progress)
    local players     = getElementsByType("player")
    local teams       = GetTeamsList()
    local onlineCount = TestOnline.enabled and getTestOnlineCount() or #players

    dxDrawImage(0, 0, scx, scy, "files/img/shadow_bg.png", 0, 0, 0, white_color)

    if not shPingBorder and graphical then
        local refH = (dxGetFontHeight(1, fonts.medium_10) or 14) + 8 * cfY
        shPingBorder = graphical:getRectangle(false, tocolor(255, 255, 255, 255), 4, cfY / refH)
    end

    -- Онлайн строка
    local onlineFontH = dxGetFontHeight(1, fonts.medium_10) or 14
    local onlineIconW = 14 * cfX
    local onlineIconH = onlineIconW
    local onlineGap   = 6 * cfX
    local onlineY     = py + 10 * cfY
    local onlineMidY  = onlineY + onlineFontH / 2
    local countStr    = tostring(onlineCount)
    local countW      = dxGetTextWidth(countStr, 1, fonts.regular_10)
    local labelStr    = "Онлайн"
    local labelW      = dxGetTextWidth(labelStr, 1, fonts.regular_10)
    local blockRight  = px + sx - 2 * cfX

    local settingsSize = 24 * cfX
    local settingsX = blockRight - settingsSize
    local settingsY = onlineMidY - settingsSize / 2

    local countX  = settingsX - 12 * cfX - countW
    local iconX   = countX - onlineGap - onlineIconW
    local labelX  = iconX - onlineGap - labelW

    dxDrawText(labelStr, labelX, onlineY, 0, 0,
        tocolor(160, 160, 160, 155 * progress), 1, fonts.regular_10)
    dxDrawImage(iconX, onlineMidY - onlineIconH / 2,
        onlineIconW, onlineIconH, "files/img/online.png", 0, 0, 0, white_color)
    dxDrawText(countStr, countX, onlineY, 0, 0,
        tocolor(255, 255, 255, 255 * progress), 1, fonts.medium_10)
		
    local settingsHover = isMouseIn(settingsX, settingsY, settingsSize, settingsSize)
    TabSettings.iconBox = {x = settingsX, y = settingsY, w = settingsSize, h = settingsSize}
    dxDrawImage(settingsX, settingsY, settingsSize, settingsSize,
        settingsHover and "files/img/settings_.png" or "files/img/settings.png",
        0, 0, 0, tocolor(255, 255, 255, 255 * progress))

    if TabSettings.opened then
        local panelW, panelH = 180 * cfX, 62 * cfY
        local panelX, panelY = settingsX - panelW + settingsSize, settingsY + settingsSize + 8 * cfY
        local panelBg = shPingBorder
        if panelBg and graphical then
            graphical:modulateColor(panelBg, tocolor(18, 18, 22, math.floor(235 * progress)))
            dxDrawImage(panelX, panelY, panelW, panelH, panelBg, 0, 0, 0, tocolor(255, 255, 255, 255))
        else
            dxDrawRectangle(panelX, panelY, panelW, panelH, tocolor(18, 18, 22, math.floor(235 * progress)))
        end

        dxDrawText("Настройки", panelX + 12 * cfX, panelY + 8 * cfY, 0, 0,
            tocolor(255, 255, 255, 230 * progress), 1, fonts.regular_10)

        local rowX, rowY, rowW, rowH = panelX + 12 * cfX, panelY + 31 * cfY, panelW - 24 * cfX, 22 * cfY
        local rowHover = isMouseIn(rowX, rowY, rowW, rowH)
        TabSettings.colorBox = {x = rowX, y = rowY, w = rowW, h = rowH}
        if rowHover then
            dxDrawRectangle(rowX, rowY, rowW, rowH, tocolor(255, 255, 255, 18 * progress))
        end

        local boxSize = 10 * cfX
        local boxX = rowX
        local boxY = rowY + rowH / 2 - boxSize / 2
        dxDrawRectangle(boxX, boxY, boxSize, boxSize,
            TabSettings.coloredNames and tocolor(75, 125, 250, 230 * progress) or tocolor(90, 90, 95, 210 * progress))
        if TabSettings.coloredNames then
            dxDrawText("✓", boxX, boxY - 2 * cfY, boxX + boxSize, boxY + boxSize,
                tocolor(255, 255, 255, 255 * progress), 1, fonts.regular_7, "center", "center")
        end
        dxDrawText("Цветные никнеймы", boxX + boxSize + 8 * cfX, rowY + 3 * cfY, 0, 0,
            tocolor(210, 210, 215, 235 * progress), 1, fonts.regular_10)
    else
        TabSettings.colorBox = nil
    end

    -- Логотип
    local logoW = 100 * cfX
    local logoH = logoW / 2  -- 500x250 → 2:1
    dxDrawImage(px + sx / 2 - logoW / 2, onlineMidY - logoH / 2, logoW, logoH, "files/img/logo.png", 0, 0, 0, white_color)

    local sepY = onlineMidY + logoH / 2 + 40 * cfY

    local statusIconSz = 14 * cfX
    local colNameLeft  = 14 * cfX   -- левый край колонки (иконка + заголовок)
    local colName      = colNameLeft + statusIconSz + 5 * cfX  -- где начинается текст ника
    local colTime      = sx / 2
    local colPing      = sx - 19 * cfX

    local ROW_H           = math.floor(40 * cfY)
    local PLAYER_ROW_H    = math.floor(40 * cfY)
    local CLAN_PLAYER_GAP = math.floor(12 * cfY)
    local SEP_EXTRA_H     = math.floor(52 * cfY)
    local cGrey           = tocolor(160, 160, 160, 155 * progress)

    -- Заголовки
    local hdrFontH  = dxGetFontHeight(1, fonts.regular_10) or 12
    local hdrY      = sepY + 20 * cfY + (ROW_H - hdrFontH) / 2

    local function drawHeader(label, col, x, align)
        local lw     = dxGetTextWidth(label, 1, fonts.regular_10)
        local isAct  = (sortColumn == col)
        local color  = isAct and tocolor(255, 255, 255, 220 * progress) or cGrey

        local drawX
        if align == "left" then
            drawX = px + x
        elseif align == "center" then
            drawX = px + x - lw / 2
        else
            drawX = px + x - lw
        end

        dxDrawText(label, drawX, hdrY, 0, 0, color, 1, fonts.regular_10)

        if isAct then
            local arrowSym = sortAsc and "▴" or "▾"
            local arrowX   = drawX + lw + 3 * cfX
            dxDrawText(arrowSym, arrowX, hdrY, 0, 0,
                tocolor(255, 255, 255, 255 * progress), 1, fonts.medium_10)
        end

        local arrowExtra = isAct and (dxGetTextWidth("▴", 1, fonts.medium_10) + 4 * cfX) or 0
        headerHitboxes[col] = { x1 = drawX, y1 = hdrY, x2 = drawX + lw + arrowExtra, y2 = hdrY + hdrFontH }
    end

    local pingRightX = colPing + 5 * cfX  -- правый край колонки пинга

    drawHeader("Никнейм", "name", colNameLeft, "left")
    drawHeader("Стаж",    "time", colTime, "center")
    drawHeader("Пинг",    "ping", pingRightX, "right")

    local RT_Y = sepY + 20 * cfY + ROW_H

    local trackH      = py + sy - RT_Y           -- точная высота области списка до нижнего края таба
    local scrollBarX  = px + sx + 10 * cfX        -- X позиция полосы
    local scrollBarW  = 3 * cfX                   -- ширина ползунка

    scrollThumbRect = nil  -- сбрасываем хитбокс

    if onlineCount >= SCROLL_MIN_PLAYERS and sScrollMaxValue > 0 then
        -- Общая высота контента = trackH + sScrollMaxValue
        local contentH  = trackH + sScrollMaxValue
        -- Высота ползунка: пропорционально видимой части, но не меньше 30px
        local thumbH    = math.max(30 * cfY, trackH * trackH / contentH)
        -- Диапазон движения ползунка = trackH - thumbH
        local thumbRange = trackH - thumbH
        -- Текущая позиция ползунка
        local scrollRatio = Clamp(0, scroll / sScrollMaxValue, 1)
        local thumbY    = RT_Y + scrollRatio * thumbRange

        -- Фоновая полоса дорожки (от RT_Y до RT_Y + trackH)
        dxDrawRectangle(scrollBarX, RT_Y, scrollBarW, trackH,
            tocolor(100, 100, 100, 80 * progress))

        -- Ползунок
        dxDrawImage(scrollBarX - scrollBarW / 2, thumbY,
            scrollBarW * 2, thumbH,
            "files/img/scroll.png", 0, 0, 0, white_color)

        -- Сохраняем хитбокс ползунка для обработки мыши
        scrollThumbRect = { x = scrollBarX - scrollBarW / 2, y = thumbY, w = scrollBarW * 2, h = thumbH }

        -- Передаём trackH в scrollDrag для корректного расчёта при перетаскивании
        scrollDrag.trackH = thumbRange
    end
    -- ────────────────────────────────────────────────────────────────────────

    local tabBottom = RT_Y + trackH

    local py_start    = 0
    local playerBgs   = {}
    local teamBgs     = {}
    local separators  = {}  -- set: separators[y] = true, чтобы не рисовать дважды на стыке строк
    local playerRows  = {}

    local prevWasTeam   = true
    local prevWasPlayer = false

    for i, v in ipairs(teams) do
        local rowY = py_start - scroll

        if v.type == "separator" then
            local screenY  = RT_Y + rowY
            local sepMidY  = screenY + SEP_EXTRA_H / 2
            if sepMidY >= RT_Y and sepMidY <= tabBottom then
                local sepStr   = "ВСЕ ИГРОКИ"
                local sepStrW  = dxGetTextWidth(sepStr, 1, fonts.regular_10)
                local sepFontH = dxGetFontHeight(1, fonts.regular_10) or 12
                local textPad  = 8 * cfX
                local lineClr  = tocolor(255, 255, 255, 20 * progress)
                dxDrawRectangle(px, sepMidY, (sx - sepStrW) / 2 - textPad, 1, lineClr)
                dxDrawText(sepStr, px + (sx - sepStrW) / 2, sepMidY - sepFontH / 2, 0, 0,
                    cGrey, 1, fonts.regular_10)
                dxDrawRectangle(px + (sx + sepStrW) / 2 + textPad, sepMidY,
                    sx - (sx + sepStrW) / 2 - textPad, 1, lineClr)
            end
            py_start    = py_start + SEP_EXTRA_H
            prevWasTeam = true

        elseif v.type == "team" then
            if prevWasPlayer then
                py_start = py_start + CLAN_PLAYER_GAP
                rowY = py_start - scroll
            end

            local screenY = RT_Y + rowY
            if screenY < tabBottom and screenY + ROW_H > RT_Y then
                local teamName = ""
                local color = tocolor(255, 255, 255, 255 * progress)

                if v.fake then
                    local c = v.color or {255, 255, 255}
                    teamName = v.name or "Клан"
                    color = ColorMulAlpha(tocolor(c[1] or 255, c[2] or 255, c[3] or 255, 255), 255 * progress)
                elseif isElement(v.team) then
                    teamName = getTeamName(v.team) or "Клан"
                    color = ColorMulAlpha(tocolor(getTeamColor(v.team)), 255 * progress)
                end

                if teamName ~= "" then
                    table.insert(teamBgs, {
                        y     = screenY,
                        name  = teamName,
                        color = color,
                    })
                end
            end

            py_start = py_start + ROW_H + CLAN_PLAYER_GAP
            prevWasTeam   = true
            prevWasPlayer = false

        elseif v.type == "player" then
            local screenRowY = math.floor(RT_Y + rowY)
            local lineH      = dxGetFontHeight(1, fonts.medium_10) or 16
            local textY      = screenRowY + (PLAYER_ROW_H - lineH) / 2

            local teamR, teamG, teamB = 255, 255, 255
            if v.fake then
                for _, clan in ipairs(TestOnline.clans) do
                    if clan.name == v.clan then
                        teamR, teamG, teamB = clan.color[1] or 255, clan.color[2] or 255, clan.color[3] or 255
                        break
                    end
                end
            else
                local playerTeam = getPlayerTeam(v.player)
                if playerTeam then
                    teamR, teamG, teamB = getTeamColor(playerTeam)
                end
            end

            table.insert(playerBgs, {
                y      = screenRowY,
                player = v.fake and ("fake_" .. tostring(v.id)) or v.player,
                isSelf = (not v.fake and v.player == localPlayer),
                tr     = teamR,
                tg     = teamG,
                tb     = teamB,
                fake   = v.fake,
            })
            separators[screenRowY] = true
            separators[screenRowY + PLAYER_ROW_H] = true

            if screenRowY < tabBottom and screenRowY + PLAYER_ROW_H > RT_Y then
                local rawName, isAdmin, isPremium, timePlayed, ping, isAFK, afkSeconds

                local displayName, cleanName
                if v.fake then
                    displayName = tostring(v.data.name or ""):gsub("^@+", "")
                    cleanName   = stripColorCodes(displayName):gsub("^@+", "")
                    rawName     = TabSettings.coloredNames and displayName or cleanName
                    isAdmin    = v.data.admin == true
                    isPremium  = v.data.premium == true
                    timePlayed = v.data.time
                    ping       = v.data.ping or 0
                    isAFK      = v.data.afk == true
                    afkSeconds = tonumber(v.data.afkSeconds) or 0
                else
                    displayName = tostring(getPlayerName(v.player) or ""):gsub("^@+", "")
                    cleanName   = stripColorCodes(displayName):gsub("^@+", "")
                    rawName     = TabSettings.coloredNames and displayName or cleanName
                    isAdmin    = getElementData(v.player, "Admin") == true or getElementData(v.player, "Admins") == true
                    isPremium  = getElementData(v.player, "Premium") == true
                    timePlayed = getElementData(v.player, "timePlayed")
                    ping       = pingCache[v.player] or getPlayerPing(v.player)
                    isAFK      = getElementData(v.player, "afk") == true or getElementData(v.player, "isAFK") == true
                    afkSeconds = tonumber(getElementData(v.player, "afk:seconds")) or 0
                end

                table.insert(playerRows, {
                    player     = v.fake and ("fake_" .. tostring(v.id)) or v.player,
                    fake       = v.fake,
                    textY      = textY,
                    lineH      = lineH,
                    rawName    = rawName,
                    cleanName  = cleanName or stripColorCodes(rawName),
                    colorCoded = TabSettings.coloredNames,
                    isAdmin    = isAdmin,
                    isPremium  = isPremium,
                    timePlayed = timePlayed,
                    ping       = ping,
                    pingStr    = tostring(ping),
                    isAFK      = isAFK,
                    afkSeconds = afkSeconds,
                })
            end

            py_start      = py_start + PLAYER_ROW_H
            prevWasTeam   = false
            prevWasPlayer = true
        end
    end

    -- Hover-определение
    hoveredPlayer = nil
    if isCursorShowing() then
        local cx, cy = getCursorPosition()
        if cx then
            cx = cx * scx
            cy = cy * scy
            for _, bg in ipairs(playerBgs) do
                if not bg.isSelf and cx >= px and cx <= px + sx
                and cy >= bg.y and cy <= bg.y + PLAYER_ROW_H then
                    hoveredPlayer = bg.player
                    break
                end
            end
        end
    end

    -- 1. list.png (фон команд)
    for _, tb in ipairs(teamBgs) do
        dxDrawImage(px, tb.y, sx, ROW_H, "files/img/list.png", 0, 0, 0, tb.color)
        dxDrawText(tb.name, px, tb.y, px + sx, tb.y + ROW_H,
            tocolor(255, 255, 255, 255 * progress), 1, fonts.medium_10, "center", "center")
    end

    -- 2. player.png (подсветка строки игрока)
    for _, bg in ipairs(playerBgs) do
        if bg.isSelf then
            dxDrawImage(px, bg.y, sx, PLAYER_ROW_H, "files/img/player.png",
                0, 0, 0, tocolor(bg.tr, bg.tg, bg.tb, math.floor(255 * progress)))
        elseif bg.player == hoveredPlayer then
            local alpha = hoverAlphas[bg.player] or 0
            if alpha > 0 then
                dxDrawImage(px, bg.y, sx, PLAYER_ROW_H, "files/img/player.png",
                    0, 0, 0, tocolor(bg.tr, bg.tg, bg.tb, math.floor(alpha * 255 * progress)))
            end
        end
    end

    -- 3. Текст игроков поверх player.png
    local ptBgW  = 73 * cfX
    local ptBgH  = 34 * cfY

    for _, row in ipairs(playerRows) do
        -- Иконка статуса (слева от ника)
        local afkA  = afkIconAlpha[row.player] or (row.isAFK and 1 or 0)
        local iconX = px + colNameLeft
        local iconY = row.textY + (row.lineH - statusIconSz) / 2
        if afkA < 1 then
            dxDrawImage(iconX, iconY, statusIconSz, statusIconSz, "files/img/player_online.png",
                0, 0, 0, tocolor(255, 255, 255, math.floor(255 * (1 - afkA) * progress)))
        end
        if afkA > 0 then
            -- Иконку AFK не перекрашиваем, оставляем оригинальный цвет файла player_afk.png
            dxDrawImage(iconX, iconY, statusIconSz, statusIconSz, "files/img/player_afk.png",
                0, 0, 0, tocolor(255, 255, 255, math.floor(255 * afkA * progress)))
        end

        -- Ник
        dxDrawText(row.rawName, px + colName, row.textY, 0, 0,
            tocolor(255, 255, 255, 255 * progress), 1, fonts.medium_10, "left", "top", false, false, false, row.colorCoded)

        -- Правый край ника; растёт вместе с бейджами
        local nameEndX = px + colName + dxGetTextWidth(row.cleanName or stripColorCodes(row.rawName), 1, fonts.medium_10)

        if row.isAdmin then
            local aLabel  = "ADMIN"
            local aTextW  = dxGetTextWidth(aLabel, 1, fonts.regular_6)
            local aTextH  = dxGetFontHeight(1, fonts.regular_6) or 8
            local aPad    = 4 * cfX
            local aBadgeW = aTextW + aPad * 2
            local aBadgeH = aTextH + aPad * 2
            local aBadgeX = nameEndX + 5 * cfX
            local aBadgeY = row.textY + (row.lineH - aBadgeH) / 2
            if shPingBorder and graphical then
                -- ADMIN: красная плашка + красный текст
                graphical:modulateColor(shPingBorder, tocolor(145, 25, 35, math.floor(170 * progress)))
                dxDrawImage(aBadgeX, aBadgeY, aBadgeW, aBadgeH, shPingBorder, 0, 0, 0, tocolor(255, 255, 255, 255))
            end
            dxDrawText(aLabel, aBadgeX, aBadgeY, aBadgeX + aBadgeW, aBadgeY + aBadgeH,
                tocolor(255, 70, 80, 255 * progress), 1, fonts.regular_6, "center", "center")
            nameEndX = aBadgeX + aBadgeW
        end


        if row.isPremium then
            local pLabel  = "PREMIUM"
            local pTextW  = dxGetTextWidth(pLabel, 1, fonts.regular_6)
            local pTextH  = dxGetFontHeight(1, fonts.regular_6) or 8
            local pPad    = 4 * cfX
            local pBadgeW = pTextW + pPad * 2
            local pBadgeH = pTextH + pPad * 2
            local pBadgeX = nameEndX + 5 * cfX
            local pBadgeY = row.textY + (row.lineH - pBadgeH) / 2
            if shPingBorder and graphical then
                graphical:modulateColor(shPingBorder, tocolor(82, 82, 88, math.floor(150 * progress)))
                dxDrawImage(pBadgeX, pBadgeY, pBadgeW, pBadgeH, shPingBorder, 0, 0, 0, tocolor(255, 255, 255, 255))
            end
            dxDrawText(pLabel, pBadgeX, pBadgeY, pBadgeX + pBadgeW, pBadgeY + pBadgeH,
                tocolor(215, 215, 220, 235 * progress), 1, fonts.regular_6, "center", "center")
            nameEndX = pBadgeX + pBadgeW
        end

        -- AFK: оранжевая плашка, оранжевый текст и время рядом
        if row.isAFK then
            local fLabel  = "AFK"
            local fTextW  = dxGetTextWidth(fLabel, 1, fonts.regular_6)
            local fTextH  = dxGetFontHeight(1, fonts.regular_6) or 8
            local fPad    = 4 * cfX
            local fBadgeW = fTextW + fPad * 2
            local fBadgeH = fTextH + fPad * 2
            local fBadgeX = nameEndX + 5 * cfX
            local fBadgeY = row.textY + (row.lineH - fBadgeH) / 2
            if shPingBorder and graphical then
                graphical:modulateColor(shPingBorder, tocolor(125, 65, 20, math.floor(175 * progress)))
                dxDrawImage(fBadgeX, fBadgeY, fBadgeW, fBadgeH, shPingBorder, 0, 0, 0, tocolor(255, 255, 255, 255))
            end
            dxDrawText(fLabel, fBadgeX, fBadgeY, fBadgeX + fBadgeW, fBadgeY + fBadgeH,
                tocolor(255, 155, 35, 255 * progress), 1, fonts.regular_6, "center", "center")

            local afkTime = formatAFKTime(row.afkSeconds)
            local afkTimeH = dxGetFontHeight(1, fonts.regular_6) or fTextH
            local afkTimeY = row.textY + (row.lineH - afkTimeH) / 2
            dxDrawText(afkTime, fBadgeX + fBadgeW + 5 * cfX, afkTimeY, 0, 0,
                tocolor(255, 155, 35, 235 * progress), 1, fonts.regular_6, "left", "top")

            nameEndX = fBadgeX + fBadgeW + 5 * cfX + dxGetTextWidth(afkTime, 1, fonts.regular_6)
        end

        if row.timePlayed then
            local numPart, sufPart = tostring(row.timePlayed):match("^(%S+)%s*(.*)$")
            numPart = numPart or tostring(row.timePlayed)
            sufPart = sufPart or ""
            local numW   = dxGetTextWidth(numPart, 1, fonts.medium_10)
            local sufW   = sufPart ~= "" and dxGetTextWidth(" " .. sufPart, 1, fonts.regular_10) or 0
            local totalW = numW + sufW
            local timeCX = px + colTime
            local timeCY = row.textY + row.lineH / 2

            if playtimeBgAlpha > 0 then
                dxDrawImage(
                    timeCX - ptBgW / 2,
                    timeCY - ptBgH / 2,
                    ptBgW, ptBgH,
                    "files/img/playtime_bg.png", 0, 0, 0,
                    tocolor(255, 255, 255, 255 * playtimeBgAlpha * progress))
            end

            local baseX = timeCX - totalW / 2
            dxDrawText(numPart, baseX, row.textY, 0, 0,
                tocolor(255, 255, 255, 255 * progress), 1, fonts.medium_10)
            if sufPart ~= "" then
                dxDrawText(" " .. sufPart, baseX + numW, row.textY, 0, 0,
                    cGrey, 1, fonts.regular_10)
            end
        else
            local loadStr = "загрузка"
            dxDrawText(loadStr, px + colTime - dxGetTextWidth(loadStr, 1, fonts.regular_10) / 2, row.textY, 0, 0,
                cGrey, 1, fonts.regular_10)
        end

        local pingW   = dxGetTextWidth(row.pingStr, 1, fonts.regular_7)
        local pingH   = dxGetFontHeight(1, fonts.regular_7) or 9
        local pad     = 4 * cfX
        local badgeW  = pingW + pad * 2
        local badgeH  = pingH + pad * 2
        local badgeX  = px + pingRightX - badgeW
        local badgeY  = row.textY + (row.lineH - badgeH) / 2
        if shPingBorder and graphical then
            graphical:modulateColor(shPingBorder, tocolor(255, 255, 255, math.floor(80 * progress)))
            dxDrawImage(badgeX, badgeY, badgeW, badgeH, shPingBorder, 0, 0, 0, tocolor(255, 255, 255, 255))
        end
        dxDrawText(row.pingStr, badgeX, badgeY, badgeX + badgeW, badgeY + badgeH,
            cGrey, 1, fonts.regular_7, "center", "center")
    end

    -- 4. Разделители
    for y in pairs(separators) do
        if y >= RT_Y - 1 and y <= tabBottom then
            dxDrawRectangle(px, y, sx, 1, tocolor(255, 255, 255, 20 * progress))
        end
    end

    sScrollMaxValue = math.max(0, py_start - trackH)
end

-- PreRender handler
local function onClientPreRender_tabHandler()
    -- Hover
    for player, alpha in pairs(hoverAlphas) do
        if player == hoveredPlayer then
            hoverAlphas[player] = math.min(1, alpha + HOVER_SPEED_IN)
        else
            hoverAlphas[player] = alpha - HOVER_SPEED_OUT
            if hoverAlphas[player] <= 0 then hoverAlphas[player] = nil end
        end
    end
    if hoveredPlayer and not hoverAlphas[hoveredPlayer] then
        hoverAlphas[hoveredPlayer] = 0
    end

    local anyTimeChanged = false
    for _, player in ipairs(getElementsByType("player")) do
        if isElement(player) then
            local tp      = tostring(getElementData(player, "timePlayed") or "")
            local prev_tp = prevTimePlayed[player]
            if prev_tp ~= nil and prev_tp ~= tp then
                anyTimeChanged = true
            end
            prevTimePlayed[player] = tp

            local isAfk = getElementData(player, "afk") == true or getElementData(player, "isAFK") == true
            local cur   = afkIconAlpha[player]
            if cur == nil then cur = isAfk and 1 or 0 end
            afkIconAlpha[player] = isAfk
                and math.min(1, cur + AFK_ICON_SPEED)
                or  math.max(0, cur - AFK_ICON_SPEED)
        end
    end

    if anyTimeChanged then
        playtimeBgAlpha = math.min(1, playtimeBgAlpha + PLAYTIME_FADE_IN * 3)
    elseif playtimeBgAlpha > 0 then
        playtimeBgAlpha = playtimeBgAlpha - PLAYTIME_FADE_OUT
        if playtimeBgAlpha < 0 then playtimeBgAlpha = 0 end
    end
end

addEventHandler("onClientPlayerQuit", root, function()
    local p = source
    hoverAlphas[p]    = nil
    prevTimePlayed[p] = nil
    pingCache[p]      = nil
    afkIconAlpha[p]   = nil
    if hoveredPlayer == p then hoveredPlayer = nil end
end)

addEventHandler("onClientClick", root, function(button, state)
    if button ~= "left" then return end
    if not IS_WINDOW_OPENED then return end

    local cx, cy = getCursorPosition()
    if not cx then return end
    cx = cx * scx
    cy = cy * scy

    if state == "down" then
        if TabSettings.iconBox then
            local b = TabSettings.iconBox
            if cx >= b.x and cx <= b.x + b.w and cy >= b.y and cy <= b.y + b.h then
                TabSettings.opened = not TabSettings.opened
                return
            end
        end
        if TabSettings.opened and TabSettings.colorBox then
            local b = TabSettings.colorBox
            if cx >= b.x and cx <= b.x + b.w and cy >= b.y and cy <= b.y + b.h then
                TabSettings.coloredNames = not TabSettings.coloredNames
                saveTabSettings()
                return
            end
        end

        if scrollThumbRect then
            local t = scrollThumbRect
            if cx >= t.x and cx <= t.x + t.w and cy >= t.y and cy <= t.y + t.h then
                scrollDrag.active   = true
                scrollDrag.startY   = cy
                scrollDrag.startVal = sScrollValue
                return
            end
        end
    elseif state == "up" then
        if scrollDrag.active then
            scrollDrag.active = false
            return
        end
        for col, box in pairs(headerHitboxes) do
            if cx >= box.x1 and cx <= box.x2 and cy >= box.y1 and cy <= box.y2 then
                if sortColumn == col then
                    sortAsc = not sortAsc
                else
                    sortColumn = col
                    sortAsc    = true
                end
                return
            end
        end
    end
end)

bindKey("mouse2", "down", function()
    if not IS_WINDOW_OPENED then return end
    showCursor(true)
end)
bindKey("mouse2", "up", function()
    if not IS_WINDOW_OPENED then return end
    showCursor(false)
    scrollDrag.active = false
end)

function ShowTab(state)
    removeEventHandler("onClientPreRender", root, onClientPreRender_tabHandler)
    removeEventHandler("onClientKey",       root, onClientKey_handler)
    removeEventHandler("onClientPreRender", root, onClientPreRender_handler)

    if state then
        showCursor(true)
        removeEventHandler("onClientRender", root, RenderTab)
        addEventHandler("onClientRender",    root, RenderTab)
        addEventHandler("onClientPreRender", root, onClientPreRender_tabHandler)
        addEventHandler("onClientKey",       root, onClientKey_handler)
        addEventHandler("onClientPreRender", root, onClientPreRender_handler)
    else
        showCursor(false)
        scrollDrag.active = false
        TabSettings.opened = false
        hoveredPlayer     = nil
        hoverAlphas       = {}
        sortColumn        = nil
        sortAsc           = true
        playtimeBgAlpha       = 0
        prevTimePlayed    = {}
        sScrollValue      = 0
        sScrollMaxValue   = 0
        scroll            = 0
    end
    iOpenTick        = getTickCount()
    IS_WINDOW_OPENED = state
end

function onClientKey_handler(key, state)
    if key == "mouse_wheel_down" then
        if sScrollValue >= sScrollMaxValue then return end
        sScrollValue = math.min(sScrollMaxValue, sScrollValue + 45)
    elseif key == "mouse_wheel_up" then
        if sScrollValue <= 0 then return end
        sScrollValue = math.max(0, sScrollValue - 45)
    end
end

bindKey("tab", "both", function(_, state)
    ShowTab(state == "down")
end)
