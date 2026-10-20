local ITEM_ID = 49272
local MAX_CHARGES = 3
local DURATION_SECONDS = 10 * 60
local SOUL_TIMEOUT_SECONDS = 2 * 60
local HEAL_INTERVAL_MS = 3000
local BASE_HEAL = 30

local STORAGE_EXPIRES_AT = 987650
local STORAGE_SOULS = 987651
local STORAGE_LAST_KILL = 987652
local STORAGE_GENERATION = 987653

local KILL_EVENT_NAME = "CrimsonEssenceJarKill"

local function getStorage(player, key)
	local value = tonumber(player:getStorageValue(key)) or 0
	return math.max(0, value)
end

local function getSouls(player, now)
	local souls = getStorage(player, STORAGE_SOULS)
	local lastKill = getStorage(player, STORAGE_LAST_KILL)
	if souls > 0 and (lastKill == 0 or now - lastKill >= SOUL_TIMEOUT_SECONDS) then
		player:setStorageValue(STORAGE_SOULS, 0)
		player:setStorageValue(STORAGE_LAST_KILL, 0)
		return 0, 0
	end
	return souls, lastKill
end

local function clearEffect(player)
	player:setStorageValue(STORAGE_EXPIRES_AT, 0)
	player:setStorageValue(STORAGE_SOULS, 0)
	player:setStorageValue(STORAGE_LAST_KILL, 0)
end

local function crimsonTick(playerId, generation)
	local player = Player(playerId)
	if not player or getStorage(player, STORAGE_GENERATION) ~= generation then
		return
	end

	local now = os.time()
	local expiresAt = getStorage(player, STORAGE_EXPIRES_AT)
	if expiresAt <= now then
		clearEffect(player)
		return
	end

	local souls = getSouls(player, now)
	player:addHealth(BASE_HEAL + souls)

	local delay = math.min(HEAL_INTERVAL_MS, (expiresAt - now) * 1000)
	addEvent(crimsonTick, delay, playerId, generation)
end

local function startEffect(player)
	local now = os.time()
	local wasActive = getStorage(player, STORAGE_EXPIRES_AT) > now
	if wasActive then
		getSouls(player, now)
	else
		player:setStorageValue(STORAGE_SOULS, 0)
		player:setStorageValue(STORAGE_LAST_KILL, 0)
	end

	player:setStorageValue(STORAGE_EXPIRES_AT, now + DURATION_SECONDS)
	local generation = getStorage(player, STORAGE_GENERATION) + 1
	player:setStorageValue(STORAGE_GENERATION, generation)
	player:registerEvent(KILL_EVENT_NAME)
	addEvent(crimsonTick, HEAL_INTERVAL_MS, player:getId(), generation)
end

local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function sendStatus(player)
	local now = os.time()
	local expiresAt = getStorage(player, STORAGE_EXPIRES_AT)
	if expiresAt <= now then
		player:popupFYI("Crimson Essence: inactive. Use a Crimson Essence Jar to activate it for 10 minutes.")
		return
	end

	local souls, lastKill = getSouls(player, now)
	local lines = {
		"Crimson Essence: active",
		string.format("Healing: %d HP every 3 seconds", BASE_HEAL + souls),
		string.format("Souls collected: %d", souls),
		string.format("Time remaining: %s", formatTime(expiresAt - now)),
	}
	if souls > 0 then
		table.insert(lines, string.format("Healing resets to %d after %s without a monster kill", BASE_HEAL, formatTime(SOUL_TIMEOUT_SECONDS - (now - lastKill))))
	else
		table.insert(lines, "Kill monsters to increase the healing.")
	end
	player:popupFYI(table.concat(lines, "\n"))
end

local killEvent = CreatureEvent(KILL_EVENT_NAME)
function killEvent.onKill(player, target)
	if not player or not target or not Monster(target) then
		return true
	end

	local now = os.time()
	if getStorage(player, STORAGE_EXPIRES_AT) <= now then
		return true
	end

	local souls = getSouls(player, now)
	player:setStorageValue(STORAGE_SOULS, souls + 1)
	player:setStorageValue(STORAGE_LAST_KILL, now)
	return true
end
killEvent:type("kill")
killEvent:register()

local loginEvent = CreatureEvent("CrimsonEssenceJarLogin")
function loginEvent.onLogin(player)
	local now = os.time()
	local expiresAt = getStorage(player, STORAGE_EXPIRES_AT)
	if expiresAt > now then
		getSouls(player, now)
		player:registerEvent(KILL_EVENT_NAME)
		local generation = getStorage(player, STORAGE_GENERATION) + 1
		player:setStorageValue(STORAGE_GENERATION, generation)
		addEvent(crimsonTick, HEAL_INTERVAL_MS, player:getId(), generation)
	elseif expiresAt > 0 then
		clearEffect(player)
	end
	return true
end
loginEvent:type("login")
loginEvent:register()

local jarAction = Action()
function jarAction.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local now = os.time()
	local expiresAt = getStorage(player, STORAGE_EXPIRES_AT)
	if expiresAt > now then
		player:sendCancelMessage(string.format(
			"Crimson Essence is already active. You can use another charge in %s.",
			formatTime(expiresAt - now)
		))
		return true
	end

	local charges = item:getCharges()
	if charges <= 0 then
		charges = MAX_CHARGES
	end

	startEffect(player)
	if charges <= 1 then
		item:remove(1)
	else
		item:transform(ITEM_ID, charges - 1)
	end

	local souls = getSouls(player, os.time())
	player:sendTextMessage(MESSAGE_INFO_DESCR, string.format(
		"The Crimson Essence is active for 10 minutes. It heals %d HP every 3 seconds.", BASE_HEAL + souls
	))
	return true
end
jarAction:id(ITEM_ID)
jarAction:register()

local crimsonTalk = TalkAction("!crimson")
function crimsonTalk.onSay(player, words, param)
	sendStatus(player)
	return false
end
crimsonTalk:register()
