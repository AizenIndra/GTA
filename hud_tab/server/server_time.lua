
local timePlayed = {}
local lastTimeUpdate = {}

-- AFK system
local lastActiveTick = {}
local afkState = {}

addEventHandler("onPlayerJoin", root, function()
    -- Пока игрок не вошёл в аккаунт, в TAB будет отображаться "Загрузка.."
    lastActiveTick[source] = getTickCount()
    afkState[source] = false
    setElementData(source, "isAFK", false)
    setElementData(source, "afk", false)
    setElementData(source, "afk:seconds", 0)
    setElementData(source, "timePlayed", "Загрузка..")
end)

 
local function onPlayerLogin(_, playerAccount)
	if (playerAccount) then
		local played = getAccountData(playerAccount, "timePlayed")
		local oldPlayed
		if getAccountData(playerAccount, "Time Played") then
			oldPlayed = {}
			oldPlayed.h = getAccountData(playerAccount, "Time Played-hours")
			oldPlayed.m = getAccountData(playerAccount, "Time Played-min")
			oldPlayed.s = getAccountData(playerAccount, "Time Played-sec")
			setAccountData(playerAccount, "Time Played", 0)
			setAccountData(playerAccount, "Time Played-hours", 0)
			setAccountData(playerAccount, "Time Played-min", 0)
			setAccountData(playerAccount, "Time Played-sec", 0)
			setAccountData(playerAccount, "Time Played", false)
			setAccountData(playerAccount, "Time Played-hours", false)
			setAccountData(playerAccount, "Time Played-min", false)
			setAccountData(playerAccount, "Time Played-sec", false)
		end
		if (played) then
			timePlayed[source] = tonumber(played) or 0
		elseif (oldPlayed) then
			timePlayed[source] = (tonumber(oldPlayed.h) or 0)*3600 + (tonumber(oldPlayed.m) or 0)*60 + (tonumber(oldPlayed.s) or 0)
		else
			timePlayed[source] = 0
		end
		lastTimeUpdate[source] = getRealTime().timestamp
		setElementData(source, "timePlayed", math.floor(timePlayed[source]/3600).." ч.")
		lastActiveTick[source] = getTickCount()
		afkState[source] = false
		setElementData(source, "isAFK", false)
    setElementData(source, "afk", false)
    setElementData(source, "afk:seconds", 0)
		--setElementData(source, "timePlayed", tostring(timePlayed[source]).." сек.")
	end
end
addEventHandler("onPlayerLogin", root, onPlayerLogin)

local function onPlayerQuit()
	local playerAccount = getPlayerAccount(source)
	if (playerAccount) and not isGuestAccount(playerAccount) then
		setAccountData(playerAccount, "timePlayed", timePlayed[source] or 0)
	end
	timePlayed[source] = nil
end
addEventHandler("onPlayerQuit", root, onPlayerQuit)

function onPlayerBuyDonateTime ( p, time )
    local account     = getPlayerAccount( p )
	local accountName = getAccountName( account )
	
	timePlayed[ p ] = timePlayed[ p ] + time
	
	setAccountData( account, "timePlayed", timePlayed[ p ] )
	setElementData( p, "timePlayed", math.floor( timePlayed[ p ] / 3600 ).." ч." )
	
end
addEvent( "onPlayerBuyDonateTime", true )
addEventHandler( "onPlayerBuyDonateTime", getRootElement(), onPlayerBuyDonateTime )

local counter = 0
local function updateTime()
	local saveTime = false
	if (counter % 5 == 0) then saveTime = true end
	counter = counter + 1
	
	local curTimestamp = getRealTime().timestamp
	for player, pTime in pairs(timePlayed) do
		timePlayed[player] = pTime + (curTimestamp - lastTimeUpdate[player])
		lastTimeUpdate[player] = curTimestamp
		setElementData(player, "timePlayed", math.floor(timePlayed[player]/3600).." ч.")
		--setElementData(player, "timePlayed", tostring(timePlayed[player]).." сек.")
		
		if (saveTime) then
			local acc = getPlayerAccount(player)
			if (acc) and not isGuestAccount(acc) then
				setAccountData(acc, "timePlayed", timePlayed[player])
			end
		end
	end
	collectgarbage()
end
setTimer(updateTime, 300000, 0)

local function onResourceStart()
	for _, player in ipairs(getElementsByType("player")) do
		local account = getPlayerAccount(player)
		if (account) and not isGuestAccount(account) then
			source = player
			onPlayerLogin(_, account)
		end
	end
end
addEventHandler("onResourceStart", resourceRoot, onResourceStart)

local function onResourceStop()
	for _, player in ipairs(getElementsByType("player")) do
		source = player
		onPlayerQuit()
	end
end

local function isInAnyACLGroup(p, groups)
    if not isElement(p) then return false end
    local acc = getPlayerAccount(p)
    if not acc or isGuestAccount(acc) then return false end

    local accName = getAccountName(acc)
    for _, groupName in ipairs(groups) do
        local group = aclGetGroup(groupName)
        if group and isObjectInACLGroup("user." .. accName, group) then
            return true
        end
    end
    return false
end

local function isAFKKickImmune(p)
    -- сюда добавляй любые группы, кому нельзя кик за AFK
    return isInAnyACLGroup(p, {
        "Console",
        "GLAdmin",
        -- "Admin",
        -- "Moderator",
        -- "SuperModerator",
    })
end


local function isConsoleAdmin(p)
    if not isElement(p) then return false end
    local acc = getPlayerAccount(p)
    if not acc or isGuestAccount(acc) then return false end
    return isObjectInACLGroup("user." .. getAccountName(acc), aclGetGroup("Console"))
end

addCommandHandler("timeset", function(player, cmd, login, hours)
    if not isConsoleAdmin(player) then
        outputChatBox("Нет доступа.", player, 255, 50, 50)
        return
    end

    if not login or not hours then
        outputChatBox("Использование: /timeset login hours", player, 255, 255, 255)
        outputChatBox("Пример: /timeset codecvv 115", player, 255, 255, 255)
        return
    end

    local h = tonumber(hours)
    if not h or h < 0 then
        outputChatBox("hours должно быть числом (>= 0).", player, 255, 50, 50)
        return
    end

    -- ищем игрока по логину аккаунта
    local target
    for _, p in ipairs(getElementsByType("player")) do
        local acc = getPlayerAccount(p)
        if acc and not isGuestAccount(acc) and getAccountName(acc) == login then
            target = p
            break
        end
    end

    if not target then
        outputChatBox("Игрок с логином '" .. tostring(login) .. "' должен быть в сети.", player, 255, 50, 50)
        return
    end

    -- timePlayed хранится в секундах
    local seconds = math.floor(h * 3600)

    timePlayed[target] = seconds
    lastTimeUpdate[target] = getRealTime().timestamp

    local acc = getPlayerAccount(target)
    if acc and not isGuestAccount(acc) then
        setAccountData(acc, "timePlayed", seconds)
    end

    setElementData(target, "timePlayed", math.floor(seconds / 3600) .. " ч.")

    outputChatBox("Стаж для " .. getPlayerName(target) .. " установлен: " .. h .. " ч.", player, 50, 255, 50)
end)


addEventHandler("onResourceStop", resourceRoot, onResourceStop)

-- =========================
-- AFK logic (server side)
-- =========================

addEvent("afk:playerActive", true)
addEventHandler("afk:playerActive", resourceRoot, function()
    if client and isElement(client) and getElementType(client) == "player" then
        lastActiveTick[client] = getTickCount()
        if afkState[client] then
            afkState[client] = false
            setElementData(client, "isAFK", false)
        end
    end
end)

setTimer(function()
    local now = getTickCount()
    for _, p in ipairs(getElementsByType("player")) do
        if not lastActiveTick[p] then
            lastActiveTick[p] = now
            afkState[p] = false
            setElementData(p, "isAFK", false)
        end

        -- Если игрок ещё НЕ вошёл в аккаунт (guest) — не считаем AFK и не кикаем
        local acc = getPlayerAccount(p)
        if not acc or isGuestAccount(acc) then
            lastActiveTick[p] = now
            if afkState[p] then
                afkState[p] = false
                setElementData(p, "isAFK", false)
            end
        else
            local idleMs = now - lastActiveTick[p]

            if idleMs >= 30000 and not afkState[p] then
                afkState[p] = true
                setElementData(p, "isAFK", true)
            end

            if idleMs >= 300000 then
                if not isAFKKickImmune(p) then
                    kickPlayer(p, "AFK более 5 минут")
                end
            end
        end
    end
end, 1000, 0)

-- Совместимость для TAB: старые системы читали "afk", новая — "isAFK".
setTimer(function()
    local now = getTickCount()
    for _, p in ipairs(getElementsByType("player")) do
        local isAfk = getElementData(p, "isAFK") == true
        setElementData(p, "afk", isAfk)

        local last = lastActiveTick[p] or now
        local seconds = isAfk and math.floor((now - last) / 1000) or 0
        setElementData(p, "afk:seconds", seconds)
    end
end, 1000, 0)
