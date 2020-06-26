CAHelper = {}

CAHelper.name = "CleverAlchemistHelper"

local currentHotbar
local slotIndex
local SET_ID = 225 -- hardcoded Clever Alchemist set ID
local pastState
local ZoneIsPvP
local pvpOnly = false

local gear = {}

local STATE -- an attempt to make an ENUM

local NEVER = 'never'
local ALWAYS = 'always'
local MAINBAR = 'mainBar'
local OFFBAR = 'offBar'

local SLOTS = { -- a lot of rudimentary experimental/debug stuff here, will remove later.
    [EQUIP_SLOT_HEAD] = { EQUIP_SLOT_HEAD, 0, 'Head'},
    [EQUIP_SLOT_NECK] = { EQUIP_SLOT_NECK, 1, 'Neck' },
    [EQUIP_SLOT_CHEST] = { EQUIP_SLOT_CHEST, 2, 'Chest' },
    [EQUIP_SLOT_SHOULDERS] =  { EQUIP_SLOT_SHOULDERS, 3, 'Shoulder'},
    [EQUIP_SLOT_MAIN_HAND] = { EQUIP_SLOT_MAIN_HAND, 4, 'MainHand'},
    [EQUIP_SLOT_OFF_HAND] =  { EQUIP_SLOT_OFF_HAND, 5, 'OffHand' },
    [EQUIP_SLOT_WAIST] =  { EQUIP_SLOT_WAIST, 6, 'Belt' },
    -- [7] = { EQUIP_SLOT_WRIST, 7 , 'wut' },
    [EQUIP_SLOT_LEGS] =  { EQUIP_SLOT_LEGS, 8, 'Leg' },
    [EQUIP_SLOT_FEET] =  { EQUIP_SLOT_FEET, 9, 'Foot' },
    -- [10] = { EQUIP_SLOT_COSTUME, 10, 'disguise?' },
    [EQUIP_SLOT_RING1] =  { EQUIP_SLOT_RING1, 11, 'Ring1' },
    [EQUIP_SLOT_RING2] =  { EQUIP_SLOT_RING2, 12, 'Ring2' },
    --[13] = { EQUIP_SLOT_POISON, 13, 'poison1'},
    --[14] = { EQUIP_SLOT_BACKUP_POISON, 14, 'poison2'},
    -- [15] = { EQUIP_SLOT_RANGED, 15, 'wut'},
    [EQUIP_SLOT_HAND] = { EQUIP_SLOT_HAND, 16, 'Glove'},
    -- [17] = { EQUIP_SLOT_CLASS1, 17, 'wut'},
    -- [18] = { EQUIP_SLOT_CLASS2, 18, 'wut'},
    -- [19] = { EQUIP_SLOT_CLASS3, 19, 'wut'},
    [EQUIP_SLOT_BACKUP_MAIN] =  { EQUIP_SLOT_BACKUP_MAIN, 20, 'BackupMain' },
    [EQUIP_SLOT_BACKUP_OFF] = { EQUIP_SLOT_BACKUP_OFF, 21, 'BackupOff' }
}

local TYPE = {
    [0] = { EQUIP_TYPE_INVALID, 0, 'Empty' },
    [1] = { EQUIP_TYPE_HEAD, 1, 'helmet' },
    [2] = { EQUIP_TYPE_NECK, 2, 'necklace' },
    [3] = { EQUIP_TYPE_CHEST, 3, 'chest' },
    [4] = { EQUIP_TYPE_SHOULDERS, 4, 'shoulders' },
    [5] = { EQUIP_TYPE_ONE_HAND, 5, 'oneHand' },
    [6] = { EQUIP_TYPE_TWO_HAND, 6, 'twoHand' },
    [7] = { EQUIP_TYPE_OFF_HAND, 7, 'offHand'},
    [8] = { EQUIP_TYPE_WAIST, 8, 'waist' },
    [9] = { EQUIP_TYPE_LEGS, 9, 'legs' },
    [10] = { EQUIP_TYPE_FEET, 10, 'feet' },
    [11] = { EQUIP_TYPE_COSTUME, 11, 'costume' },
    [12] = { EQUIP_TYPE_RING, 12, 'ring' },
    [13] = { EQUIP_TYPE_HAND, 13, 'hand' },
    [14] = { EQUIP_TYPE_MAIN_HAND, 14, 'mainHand' },
    [15] = { EQUIP_TYPE_POISON, 15, 'poison' }
}

local function stateChat()
    if pastState ~= STATE and pastState then
        if (STATE == MAINBAR) then
            d("[Clever Alchemist Helper]: Set detected on Mainbar")
        elseif (STATE == OFFBAR) then
            d("[Clever Alchemist Helper]: Set detected on Offbar")
        elseif (STATE == NEVER) then
            d("[Clever Alchemist Helper]: Not enough pieces equipped. Addon is OFF.")
            CAHelperReticleIcon:SetHidden(false)
        elseif (STATE == ALWAYS) then
            d("[Clever Alchemist Helper]: Too many set pieces equipped. Addon is OFF.")
            CAHelperReticleIcon:SetHidden(false)
        end
    end
    pastState = STATE
end

function eval()
    local equipped = 0
    local totalBonus = 0
    local armorBonus = 0
    local mainBarBonus = 0
    local offBarBonus = 0

    for i, v in pairs(gear) do
        if gear[i]["isAlchemist"] == true then
            equipped = equipped + 1
            if gear[i]["type"] == ITEMTYPE_ARMOR then
                armorBonus = armorBonus + 1
            elseif gear[i]["slot"] == EQUIP_SLOT_MAIN_HAND or gear[i]["slot"] == EQUIP_SLOT_OFF_HAND then
                if gear[i]["type"] == EQUIP_TYPE_TWO_HAND then
                    mainBarBonus = mainBarBonus + 2
                elseif gear[i]["type"] == EQUIP_TYPE_ONE_HAND then
                    mainBarBonus = mainBarBonus + 1
                end
            elseif gear[i]["slot"] == EQUIP_SLOT_BACKUP_MAIN or gear[i]["slot"] == EQUIP_SLOT_BACKUP_OFF then
                if gear[i]["type"] == EQUIP_TYPE_TWO_HAND then
                    offBarBonus = offBarBonus + 2
                elseif gear[i]["type"] == EQUIP_TYPE_ONE_HAND then
                    offBarBonus = offBarBonus + 1
                end
            end
        end
    end

    if equipped < 4 then
        STATE = NEVER
    elseif armorBonus >= 5 then
        STATE = ALWAYS
    elseif armorBonus <= 2 then
        STATE = NEVER
    elseif mainBarBonus == offBarBonus == 2 then
        STATE = ALWAYS
    elseif mainBarBonus + armorBonus >= 5 then
        STATE = MAINBAR
    elseif offBarBonus + armorBonus >= 5 then
        STATE = OFFBAR
    else
        STATE = NEVER
    end

    stateChat()
end

function parseSlot(eventCode, bagId, slotIndex, isNewItem, itemSoundCategory, updateReason, stackCountChange)
	local itemType
	itemType, _ = GetItemType(BAG_WORN, slotIndex)
	if itemType == ITEMTYPE_WEAPON then
		_, _, _, _, _, itemType, _, _ = GetItemInfo(BAG_WORN, slotIndex)
	end
    local link = GetItemLink(BAG_WORN, slotIndex)
	local hasSet, setName, numBonuses, numEquipped, _, setId = GetItemLinkSetInfo(link)
	if hasSet and setId == SET_ID then
		gear[slotIndex] = { link = itemLink, type = itemType, isAlchemist = true, slot = slotIndex }
	else
		gear[slotIndex] = { link = itemLink, type = itemType, isAlchemist = false, slot = slotIndex }
	end
	if CAHelper.ready then
		eval()
	end
end

function getEquippedGear()
 --   for x = 1, #SLOTS do
    for i, v in pairs(SLOTS) do
        parseSlot(0, 0, v[1], 0, 0, 0, 0)
    end
end

local function createReticleControl()
	CAHelperReticleIcon = WINDOW_MANAGER:CreateControl("CAHelperRecticleControl", ZO_ReticleContainer, CT_TEXTURE)
	CAHelperReticleIcon:ClearAnchors()
	CAHelperReticleIcon:SetAnchor(CENTER, ZO_ReticleContainer, CENTER, 45, 0)
	CAHelperReticleIcon:SetTexture("/esoui/art/treeicons/gamepad/progression_levelup_choiceofpotion.dds")
	CAHelperReticleIcon:SetDimensions(32, 32)
	CAHelperReticleIcon:SetColor(240, 240, 240, 0.5)
	CAHelperReticleIcon:SetHidden(true)
end

local function registerAnimations(control)
    local isValidAnchor, point, relativeTo, relativePoint, offsetX, offsetY = control:GetAnchor()

    local TranslateAnimation, TranslateTimeline = CreateSimpleAnimation(ANIMATION_TRANSLATE, control)
        TranslateAnimation:SetTranslateOffsets(offsetX, offsetY, offsetX - 15, offsetY)
        TranslateAnimation:SetDuration(70)
        TranslateAnimation:SetEasingFunction(ZO_EaseInQuadratic)

    local fadeInAnimation, FadeInTimeline = CreateSimpleAnimation(ANIMATION_ALPHA, control)
        fadeInAnimation:SetAlphaValues(0, 0.5)
        fadeInAnimation:SetDuration(200)
        fadeInAnimation:SetEasingFunction(ZO_EaseOutQuadratic)

    return TranslateTimeline, FadeInTimeline
end

local function checkIfZoneIsPvP()
    if IsPlayerInAvAWorld() or IsActiveWorldBattleground() then
        ZoneIsPvP = true
    end
end

function Initialize()
    EVENT_MANAGER:UnregisterForEvent(CAHelper.name, EVENT_ADD_ON_LOADED)

    createReticleControl()
    local TranslateTimeline, FadeInTimeline = registerAnimations(CAHelperReticleIcon)

    for i, v in pairs(SLOTS) do
        gear[i] = { id = 0, link = 0, type = 0, isAlchemist = false, slot = 0 }
    end

    getEquippedGear()
    eval()
    CAHelper.ready = true

    EVENT_MANAGER:RegisterForEvent(CAHelper.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, parseSlot)
    EVENT_MANAGER:AddFilterForEvent(CAHelper.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_WORN)
    EVENT_MANAGER:AddFilterForEvent(CAHelper.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)

    if pvpOnly then
        EVENT_MANAGER:RegisterForEvent(CAHelper.name, EVENT_ZONE_CHANGED, checkIfZoneIsPvP)
        checkIfZoneIsPvP() -- if we are in AvA/BG on login
    end

    if (pvpOnly and ZoneIsPvP) or not pvpOnly then
        CAHelperReticleIcon:SetHidden(false)
        local currentHotbar = ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbarCategory() -- get initial bar
        EVENT_MANAGER:RegisterForEvent(CAHelper.name, EVENT_ACTION_SLOTS_FULL_UPDATE, function(eventCode, isHotbarSwap) 
			if isHotbarSwap then
				currentHotbar = 1 - currentHotbar -- switch between 0 and 1
			end
			if (currentHotbar == 0 and STATE == MAINBAR) or 
				(currentHotbar == 1 and STATE == OFFBAR) then
				FadeInTimeline:PlayForward()
			else
				FadeInTimeline:PlayBackward() -- fadeOut :P
			end
		end)

		SecurePostHook(ZO_Reticle, "OnUpdate", function(self)
			local interactionPossible = not self.interact:IsHidden()
			if (interactionPossible or PLAYER_TO_PLAYER:HasTarget() or IsGameCameraUnitHighlightedAttackable()) and (GetUnitStealthState("player") == 0) then
				TranslateTimeline:PlayForward()
			else
				TranslateTimeline:PlayBackward()
			end
		end)

		ZO_PreHook("ZO_ActionBar_CanUseActionSlots", function()
			-- flag = not flag -- Since ZO_ActionBar_CanUseActionSlots is called twice for each ability cast
			-- if flag then
			local slotNum = tonumber(debug.traceback():match('keybind = "ACTION_BUTTON_(%d)')) -- get pressed button
				if slotNum == 9 then -- break if consumable or empty slot
					if (currentHotbar == 0 and STATE ~= MAINBAR) or 
					(currentHotbar == 1 and STATE ~= OFFBAR) then
					-- alert() -- notify player
						return true -- ESO won't run ability press if PreHook returns true
					end
				else return false end
		end)
    end
end


--  ACTION_BAR_ASSIGNMENT_MANAGER:RegisterCallback("CurrentHotbarUpdated", -- to keep currentHotbar relevant
    --function(hotbarCategory, oldHotbarCategory)
    --  currentHotbar
--       = hotbarCategory

--  if (currentHotbar == 0 and STATE == MAINBAR) or 
--      (currentHotbar == 1 and STATE == OFFBAR) then
--          FadeInTimeline:PlayForward()
--  else
    --  FadeInTimeline:PlayBackward() -- fadeOut :P
--  end

--  end)

-- local flag = true

local function OnAddOnLoaded(event, addonName)
	if addonName == CAHelper.name then
		Initialize()
	end
end

EVENT_MANAGER:RegisterForEvent(CAHelper.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
