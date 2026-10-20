local dodgeCrystal = Action()

local DODGE_CRYSTAL_ID = 8828
local DODGE_ATTRIBUTE = "equipmentDodgeApplied"
local MAX_DODGE_PER_ITEM = 4

local function isSupportedEquipment(itemType)
	return itemType:isArmor() or itemType:isLegs()
end

function dodgeCrystal.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not target or not target:isItem() then
		player:sendCancelMessage("Use the Dodge Crystal on armor or legs.")
		return true
	end

	local targetType = target:getType()
	if not isSupportedEquipment(targetType) then
		player:sendCancelMessage("This item cannot receive Dodge Applied.")
		return true
	end

	local applied = tonumber(target:getCustomAttribute(DODGE_ATTRIBUTE)) or 0
	if applied >= MAX_DODGE_PER_ITEM then
		player:sendCancelMessage("This equipment already has the maximum Dodge Applied (4/4).")
		return true
	end

	target:setCustomAttribute(DODGE_ATTRIBUTE, applied + 1)
	item:remove(1)
	player:sendTextMessage(MESSAGE_INFO_DESCR, string.format("Dodge Applied: %d/%d (%d%%).", applied + 1, MAX_DODGE_PER_ITEM, (applied + 1) * 25))
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
	return true
end

dodgeCrystal:id(DODGE_CRYSTAL_ID)
dodgeCrystal:register()
