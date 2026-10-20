local reflectStone = Action()

local REFLECT_STONE_ID = 23729
local REFLECT_ATTRIBUTE = "equipmentReflectApplied"
local MAX_REFLECT_PER_ITEM = 55

function reflectStone.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not target or not target:isItem() then
		player:sendCancelMessage("Use the Reflect Stone on boots.")
		return true
	end

	if not target:getType():isBoots() then
		player:sendCancelMessage("Reflect Applied can only be added to boots.")
		return true
	end

	local applied = tonumber(target:getCustomAttribute(REFLECT_ATTRIBUTE)) or 0
	if applied >= MAX_REFLECT_PER_ITEM then
		player:sendCancelMessage("These boots already have the maximum Reflect Applied (55/55).")
		return true
	end

	target:setCustomAttribute(REFLECT_ATTRIBUTE, applied + 1)
	item:remove(1)
	player:sendTextMessage(MESSAGE_INFO_DESCR, string.format("Reflect Applied: %d/%d.", applied + 1, MAX_REFLECT_PER_ITEM))
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
	return true
end

reflectStone:id(REFLECT_STONE_ID)
reflectStone:register()
