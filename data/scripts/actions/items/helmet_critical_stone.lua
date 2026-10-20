local criticalStone = Action()

local CRITICAL_STONE_ID = 28709
local CRITICAL_ATTRIBUTE = "equipmentCriticalApplied"
local MAX_CRITICAL_PER_ITEM = 20

function criticalStone.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not target or not target:isItem() then
		player:sendCancelMessage("Use the Critical Stone on a helmet.")
		return true
	end

	if not target:getType():isHelmet() then
		player:sendCancelMessage("Critical Applied can only be added to a helmet.")
		return true
	end

	local applied = tonumber(target:getCustomAttribute(CRITICAL_ATTRIBUTE)) or 0
	if applied >= MAX_CRITICAL_PER_ITEM then
		player:sendCancelMessage("This helmet already has the maximum Critical Applied (20/20).")
		return true
	end

	target:setCustomAttribute(CRITICAL_ATTRIBUTE, applied + 1)
	item:remove(1)
	player:sendTextMessage(MESSAGE_INFO_DESCR, string.format("Critical Applied: %d/%d.", applied + 1, MAX_CRITICAL_PER_ITEM))
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
	return true
end

criticalStone:id(CRITICAL_STONE_ID)
criticalStone:register()
