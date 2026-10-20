local event = Event()

local decayStateNames = {
	[0] = "inactive",
	[1] = "running",
	[2] = "pending",
	[3] = "stopping"
}

local function formatSeconds(seconds)
	seconds = math.max(0, math.floor(tonumber(seconds) or 0))
	return Game.getTimeInWords(seconds)
end

local function formatMilliseconds(milliseconds)
	milliseconds = math.max(0, math.floor(tonumber(milliseconds) or 0))
	return string.format("%s (%d ms)", formatSeconds(math.ceil(milliseconds / 1000)), milliseconds)
end

local function formatDefaultDecayTime(itemType)
	local durationMin = tonumber(itemType:getDurationMin()) or 0
	local durationMax = tonumber(itemType:getDurationMax()) or 0

	if durationMin <= 0 and durationMax <= 0 then
		return nil
	end

	if durationMax > 0 and durationMax ~= durationMin then
		return string.format("%s - %s", formatSeconds(durationMin), formatSeconds(durationMax))
	end
	return formatSeconds(durationMin)
end

local function appendDecayInfo(description, item, itemType)
	local hasDuration = item:hasAttribute(ITEM_ATTRIBUTE_DURATION)
	local hasDecayState = item:hasAttribute(ITEM_ATTRIBUTE_DECAYSTATE)
	local hasDurationTimestamp = item:hasAttribute(ITEM_ATTRIBUTE_DURATION_TIMESTAMP)
	local defaultDecayTime = formatDefaultDecayTime(itemType)

	if not hasDuration and not hasDecayState and not hasDurationTimestamp and not defaultDecayTime then
		return description
	end

	if defaultDecayTime then
		description = string.format("%s\nDefault decay time: %s", description, defaultDecayTime)
	end

	if hasDecayState then
		local decayState = tonumber(item:getAttribute(ITEM_ATTRIBUTE_DECAYSTATE)) or 0
		description = string.format(
			"%s\nDecay state: %s (%d)",
			description,
			decayStateNames[decayState] or "unknown",
			decayState
		)
	end

	if hasDuration then
		local duration = tonumber(item:getAttribute(ITEM_ATTRIBUTE_DURATION)) or 0
		local decayState = tonumber(item:getAttribute(ITEM_ATTRIBUTE_DECAYSTATE)) or 0
		local label = (hasDurationTimestamp or decayState == 1 or decayState == 3) and "Expires in" or "Stored duration"
		description = string.format("%s\n%s: %s", description, label, formatMilliseconds(duration))
	end

	return description
end

event.onLook = function(self, thing, position, distance, description)
	local minDist = 3
	if thing:isCreature() and thing:isNpc() and distance <= minDist then
		self:say("hi", TALKTYPE_PRIVATE_PN, false, thing)
		self:say("trade", TALKTYPE_PRIVATE_PN, false, thing)
		return false
	end

	local description = "You see "

	if thing:isItem() then
		description = description .. thing:getDescription(distance, nil, nil, self)
		local itemType = thing:getType()
		if itemType:isHelmet() then
			local criticalApplied = tonumber(thing:getCustomAttribute("equipmentCriticalApplied")) or 0
			criticalApplied = math.max(0, math.min(20, criticalApplied))
			description = string.format("%s\nCritical Applied: %d/20", description, criticalApplied)
		end
		if itemType:isBoots() then
			local reflectApplied = tonumber(thing:getCustomAttribute("equipmentReflectApplied")) or 0
			reflectApplied = math.max(0, math.min(55, reflectApplied))
			description = string.format("%s\nReflect Applied: %d/55", description, reflectApplied)
		end
		if thing:getId() == 49272 then
			local now = os.time()
			local expiresAt = math.max(0, tonumber(self:getStorageValue(987650)) or 0)
			local charges = tonumber(thing:getCharges()) or 0
			if charges <= 0 then
				charges = 3
			end
			local lines = { string.format("Charges: %d/3", charges) }
			if expiresAt > now then
				local souls = math.max(0, tonumber(self:getStorageValue(987651)) or 0)
				local lastKill = math.max(0, tonumber(self:getStorageValue(987652)) or 0)
				if souls > 0 and (lastKill == 0 or now - lastKill >= 120) then
					souls = 0
				end
				local timeRemaining = expiresAt - now
				table.insert(lines, "Crimson Essence: active")
				table.insert(lines, string.format("Healing: %d HP every 3 seconds", 30 + souls))
				table.insert(lines, string.format("Souls collected: %d", souls))
				table.insert(lines, string.format("Time remaining: %02d:%02d", math.floor(timeRemaining / 60), timeRemaining % 60))
				if souls > 0 then
					local resetIn = math.max(0, 120 - (now - lastKill))
					table.insert(lines, string.format("Healing resets to 30 in: %02d:%02d without a monster kill", math.floor(resetIn / 60), resetIn % 60))
				else
					table.insert(lines, "Kill monsters to increase the healing.")
				end
			else
				table.insert(lines, "Crimson Essence: inactive")
			end
			self:popupFYI(table.concat(lines, "\n"))
		end
		if itemType:isArmor() or itemType:isLegs() then
			local dodgeApplied = tonumber(thing:getCustomAttribute("equipmentDodgeApplied")) or 0
			dodgeApplied = math.max(0, math.min(4, dodgeApplied))
			description = string.format("%s\nDodge Applied: %d/4 (%d%%)", description, dodgeApplied, dodgeApplied * 25)

			local armor = self:getSlotItem(CONST_SLOT_ARMOR)
			local legs = self:getSlotItem(CONST_SLOT_LEGS)
			if armor and legs then
				local armorDodge = math.max(0, math.min(4, tonumber(armor:getCustomAttribute("equipmentDodgeApplied")) or 0))
				local legsDodge = math.max(0, math.min(4, tonumber(legs:getCustomAttribute("equipmentDodgeApplied")) or 0))
				local totalApplied = armorDodge + legsDodge
				description = string.format("%s\nTotal Dodge Applied: %d/8 (%d%%)", description, totalApplied, math.floor(totalApplied * 100 / 8))
			end
		end
		
	else
		description = description .. thing:getDescription(distance)
		
		-- Familiar summon time display
		if thing:isCreature() and configManager.getBoolean(configKeys.FAMILIAR_SYSTEM_ENABLED) then
			local master = thing:getMaster()
			if master then
				local isFamiliar = false
				local ok, famName = pcall(function() return master:getFamiliarName() end)
				if ok and famName and famName ~= "" then
					isFamiliar = (thing:getName():lower() == famName:lower())
				else
					local summons = { "sorcerer familiar", "knight familiar", "druid familiar", "paladin familiar", "monk familiar" }
					isFamiliar = table.contains(summons, thing:getName():lower())
				end
				if isFamiliar then
					local familiarSummonTime = master:getStorageValue(STORAGE_FAMILIAR_SUMMON_TIME) or 0
					local remainingSeconds = math.floor((familiarSummonTime - os.mtime()) / 1000)
					description = description .. " (Master: " .. master:getName() .. "). \z
						It will disappear in " .. Game.getTimeInWords(remainingSeconds)
				end
			end
		end
	end

	if self:getGroup():getAccess() or self:getAccountType() >= ACCOUNT_TYPE_GAMEMASTER then
		if thing:isItem() then
			local itemType = thing:getType()
			
			description = string.format("%s\nItem ID: %d", description, thing:getId())

			local actionId = thing:getActionId()
			if actionId ~= 0 then
				description = string.format("%s, Action ID: %d", description, actionId)
			end

			local uniqueId = thing:getAttribute(ITEM_ATTRIBUTE_UNIQUEID)
			if uniqueId > 0 and uniqueId < 65536 then
				description = string.format("%s, Unique ID: %d", description, uniqueId)
			end

			if thing:hasItemUID() then
				description = string.format("%s\nHASH: %s", description, thing:getItemUID())
			end

			local transformEquipId = itemType:getTransformEquipId()
			local transformDeEquipId = itemType:getTransformDeEquipId()
			if transformEquipId ~= 0 then
				description = string.format("%s\nTransforms to: %d (onEquip)", description, transformEquipId)
			elseif transformDeEquipId ~= 0 then
				description = string.format("%s\nTransforms to: %d (onDeEquip)", description, transformDeEquipId)
			end

			local decayId = itemType:getDecayId()
			if decayId ~= -1 then
				description = string.format("%s\nDecays to: %d", description, decayId)
			end

			description = appendDecayInfo(description, thing, itemType)
			
		elseif thing:isCreature() then
			local str = "%s\nHealth: %d / %d"
			if thing:isPlayer() and thing:getMaxMana() > 0 then
				str = string.format("%s, Mana: %d / %d", str, thing:getMana(), thing:getMaxMana())
			end
			description = string.format(str, description, thing:getHealth(), thing:getMaxHealth()) .. "."
		end

		local position = thing:getPosition()
		description = string.format(
			"%s\nPosition: %d, %d, %d",
			description, position.x, position.y, position.z
		)

		if thing:isCreature() then
			if thing:isPlayer() then
			    description = string.format("%s\nGUID: %s", description, thing:getGuid())
				description = string.format("%s\nIP: %s.", description, Game.convertIpToString(thing:getIp()))
			end
		end
	end
	return description
end
event:register()
