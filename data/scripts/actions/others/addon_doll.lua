local OUTFIT_WINDOW_ID = 87780
local CONFIRM_WINDOW_ID = 87781
local MODAL_EVENT_NAME = "AddonDollModal"

local outfits = {
	{ femaleLookType = 136, maleLookType = 128, name = "Citizen" },
	{ femaleLookType = 137, maleLookType = 129, name = "Hunter" },
	{ femaleLookType = 138, maleLookType = 130, name = "Mage" },
	{ femaleLookType = 139, maleLookType = 131, name = "Knight" },
	{ femaleLookType = 140, maleLookType = 132, name = "Noblewoman" },
	{ femaleLookType = 141, maleLookType = 133, name = "Summoner" },
	{ femaleLookType = 142, maleLookType = 134, name = "Warrior" },
	{ femaleLookType = 147, maleLookType = 143, name = "Barbarian" },
	{ femaleLookType = 148, maleLookType = 144, name = "Druid" },
	{ femaleLookType = 149, maleLookType = 145, name = "Wizard" },
	{ femaleLookType = 150, maleLookType = 146, name = "Oriental" },
	{ femaleLookType = 155, maleLookType = 151, name = "Pirate" },
	{ femaleLookType = 156, maleLookType = 152, name = "Assassin" },
	{ femaleLookType = 157, maleLookType = 153, name = "Beggar" },
	{ femaleLookType = 158, maleLookType = 154, name = "Shaman" },
	{ femaleLookType = 252, maleLookType = 251, name = "Norsewoman" },
	{ femaleLookType = 269, maleLookType = 268, name = "Nightmare" },
	{ femaleLookType = 270, maleLookType = 273, name = "Jester" },
	{ femaleLookType = 279, maleLookType = 278, name = "Brotherhood" },
	{ femaleLookType = 288, maleLookType = 289, name = "Demon Hunter" },
	{ femaleLookType = 324, maleLookType = 325, name = "Yalaharian" },
	{ femaleLookType = 336, maleLookType = 335, name = "Warmaster" },
	{ femaleLookType = 366, maleLookType = 367, name = "Wayfarer" },
}

local pendingOutfits = {}
local availableOutfits = {}

local modalEvent = CreatureEvent(MODAL_EVENT_NAME)
modalEvent:type("modalwindow")

function modalEvent.onModalWindow(player, modalWindowId, buttonId, choiceId)
	if modalWindowId == OUTFIT_WINDOW_ID then
		if buttonId ~= 1 then
			return true
		end

		local choices = availableOutfits[player:getId()]
		local outfit = choices and choices[choiceId]
		availableOutfits[player:getId()] = nil
		if not outfit then
			return true
		end

		pendingOutfits[player:getId()] = outfit
		local confirmWindow = ModalWindow(CONFIRM_WINDOW_ID, "Confirm outfit", "Are you sure you want to unlock the remaining addons for the " .. outfit.name .. " outfit?")
		confirmWindow:addButton(1, "Yes")
		confirmWindow:addButton(2, "No")
		confirmWindow:setDefaultEnterButton(1)
		confirmWindow:setDefaultEscapeButton(2)
		confirmWindow:sendToPlayer(player)
		return true
	end

	if modalWindowId == CONFIRM_WINDOW_ID then
		local outfit = pendingOutfits[player:getId()]
		pendingOutfits[player:getId()] = nil
		if buttonId ~= 1 or not outfit then
			return true
		end

		local needsAddon1 = not player:hasOutfit(outfit.lookType, 1)
		local needsAddon2 = not player:hasOutfit(outfit.lookType, 2)
		if not needsAddon1 and not needsAddon2 then
			player:sendTextMessage(MESSAGE_STATUS_SMALL, "This outfit already has both addons unlocked.")
			return true
		end
		if not player:removeItem(53633, 1) then
			player:sendTextMessage(MESSAGE_STATUS_SMALL, "You need an outfit doll to unlock this outfit.")
			return true
		end

		player:addOutfit(outfit.lookType)
		if needsAddon1 then
			player:addOutfitAddon(outfit.lookType, 1)
		end
		if needsAddon2 then
			player:addOutfitAddon(outfit.lookType, 2)
		end
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, outfit.name .. " outfit addons unlocked.")
		return true
	end

	return true
end

modalEvent:register()

local addonDoll = Action()

function addonDoll.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	player:registerEvent(MODAL_EVENT_NAME)

	-- Correct prior grants made with the opposite-sex looktype.
	for _, outfit in ipairs(outfits) do
		local correctLookType = player:getSex() == PLAYERSEX_MALE and outfit.maleLookType or outfit.femaleLookType
		local oldLookType = player:getSex() == PLAYERSEX_MALE and outfit.femaleLookType or outfit.maleLookType
		local hasAddon1 = player:hasOutfit(oldLookType, 1)
		local hasAddon2 = player:hasOutfit(oldLookType, 2)
		if hasAddon1 or hasAddon2 then
			player:addOutfit(correctLookType)
			if hasAddon1 then
				player:addOutfitAddon(correctLookType, 1)
			end
			if hasAddon2 then
				player:addOutfitAddon(correctLookType, 2)
			end
		end
	end

	local outfitWindow = ModalWindow(OUTFIT_WINDOW_ID, "Choose an outfit", "Select the outfit you want to unlock:")
	local choices = {}
	local choiceId = 0
	for _, outfit in ipairs(outfits) do
		local lookType = player:getSex() == PLAYERSEX_MALE and outfit.maleLookType or outfit.femaleLookType
		local hasAddon1 = player:hasOutfit(lookType, 1)
		local hasAddon2 = player:hasOutfit(lookType, 2)
		if not (hasAddon1 and hasAddon2) then
			choiceId = choiceId + 1
			choices[choiceId] = { name = outfit.name, lookType = lookType }
			outfitWindow:addChoice(choiceId, outfit.name)
		end
	end
	if choiceId == 0 then
		player:sendTextMessage(MESSAGE_STATUS_SMALL, "You already have all addons for these outfits.")
		return true
	end
	availableOutfits[player:getId()] = choices
	outfitWindow:addButton(1, "Select")
	outfitWindow:addButton(2, "Cancel")
	outfitWindow:setDefaultEnterButton(1)
	outfitWindow:setDefaultEscapeButton(2)
	outfitWindow:sendToPlayer(player)
	return true
end

addonDoll:id(53633)
addonDoll:register()
