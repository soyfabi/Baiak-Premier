local action = Action()

function action.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You advanced your Bosstiary entry for Black Knight and earned 90 boss points.")
	return true
end

action:id(9692)
action:register()
