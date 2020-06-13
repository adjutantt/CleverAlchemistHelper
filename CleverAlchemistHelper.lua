alchemist = {}

local ADDON_NAME = "CleverAlchemistHelper"
local ADDON_VERSION	= "1.0"

local variableVersion = 7
local savedVarsName = "CleverAlchemistHelperVars"


-- local ESOUI_URL = ""
local currentHotbar

local slotIndex

local SET_ID = 225 -- hardcoded Clever Alchemist ID

local STATE

local NEVER = 'never'
local ALWAYS = 'always'
local MAINBAR = 'mainBar'
local OFFBAR = 'offBar'

  local SLOTS = {
  [EQUIP_SLOT_HEAD] = { EQUIP_SLOT_HEAD, 0, 'Head'},
    [EQUIP_SLOT_NECK] = { EQUIP_SLOT_NECK, 1, 'Neck' },
  [EQUIP_SLOT_CHEST] = { EQUIP_SLOT_CHEST, 2, 'Chest' },
  [EQUIP_SLOT_SHOULDERS] =  { EQUIP_SLOT_SHOULDERS, 3, 'Shoulder'},
   [EQUIP_SLOT_MAIN_HAND] = { EQUIP_SLOT_MAIN_HAND, 4, 'MainHand'},
  [EQUIP_SLOT_OFF_HAND] =  { EQUIP_SLOT_OFF_HAND, 5, 'OffHand' },
  [EQUIP_SLOT_WAIST] =  { EQUIP_SLOT_WAIST, 6, 'Belt' },
    -- [7] = { EQUIP_SLOT_WRIST, 7 , 'wtf' },
  [EQUIP_SLOT_LEGS] =  { EQUIP_SLOT_LEGS, 8, 'Leg' },
  [EQUIP_SLOT_FEET] =  { EQUIP_SLOT_FEET, 9, 'Foot' },
    -- [10] = { EQUIP_SLOT_COSTUME, 10, 'wtf' },
  [EQUIP_SLOT_RING1] =  { EQUIP_SLOT_RING1, 11, 'Ring1' },
  [EQUIP_SLOT_RING2] =  { EQUIP_SLOT_RING2, 12, 'Ring2' },
    --[13] = { EQUIP_SLOT_POISON, 13, 'wtf'},
    --[14] = { EQUIP_SLOT_BACKUP_POISON, 14, 'wtf'},
    -- [15] = { EQUIP_SLOT_RANGED, 15, 'wtf'},
   [EQUIP_SLOT_HAND] = { EQUIP_SLOT_HAND, 16, 'Glove'},
    -- [17] = { EQUIP_SLOT_CLASS1, 17, 'wtf'},
    -- [18] = { EQUIP_SLOT_CLASS2, 18, 'wtf'},
    -- [19] = { EQUIP_SLOT_CLASS3, 19, 'wtf'},
  [EQUIP_SLOT_BACKUP_MAIN] =  { EQUIP_SLOT_BACKUP_MAIN, 20, 'BackupMain' },
   [EQUIP_SLOT_BACKUP_OFF] = { EQUIP_SLOT_BACKUP_OFF, 21, 'BackupOff' }

}

local weaponSlots = {
    [EQUIP_SLOT_MAIN_HAND] = true,
    [EQUIP_SLOT_OFF_HAND] = true,
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

local gear = {}

local defaults = {
    left = 300,
    top = 300
}

local function switch()
    if STATE == NEVER then
        AG_UI_Button:SetNormalTexture("/esoui/art/tradinghouse/tradinghouse_potions_potionsolvent_disabled.dds")
    elseif STATE == MAINBAR or STATE == OFFBAR then
        AG_UI_Button:SetNormalTexture("/esoui/art/tradinghouse/tradinghouse_potions_potionsolvent_up.dds")
    end
end

function alchemist.RestorePosition()
    AG_UI_ButtonBg:ClearAnchors()
    AG_UI_ButtonBg:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, alchemist.Account.left, alchemist.Account.top)
 end

function alchemist.StorePosition(control)
   local name = control:GetName()
    alchemist.Account.left = control:GetLeft()
    alchemist.Account.top = control:GetTop()
end


local function createCustomReticle()
  CleverAlchemistReticleIcon = WINDOW_MANAGER:CreateControl("visualSwapCrosshair", ZO_ReticleContainer, CT_TEXTURE)
  CleverAlchemistReticleIcon:ClearAnchors()
  CleverAlchemistReticleIcon:SetAnchor(CENTER, ZO_ReticleContainer, CENTER, 45, 0)
  CleverAlchemistReticleIcon:SetTexture("/esoui/art/treeicons/gamepad/progression_levelup_choiceofpotion.dds")
  CleverAlchemistReticleIcon:SetDimensions( 32, 32 )
  CleverAlchemistReticleIcon:SetColor(240, 240, 240, 0.5)
end



local function Initialize()

	EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)
    alchemist.Account = ZO_SavedVars:NewAccountWide(savedVarsName, variableVersion, "globals", defaults, GetWorldName(), "AllAccountsTheSame")
alchemist.RestorePosition()
    createCustomReticle()

    for i, v in pairs(SLOTS) do
        gear[i] = { id = 0, link = 0, type = 0, isAlchemist = false, slot = 0 }
    end

    getEquippedGear()
    alchemist.ready = true
    eval()

    local currentHotbar

ACTION_BAR_ASSIGNMENT_MANAGER:RegisterCallback("CurrentHotbarUpdated", -- to keep currentHotbar relevant
    function(hotbarCategory, oldHotbarCategory)
        currentHotbar
         = hotbarCategory

    if (currentHotbar == 0 and STATE == MAINBAR) or 
        (currentHotbar == 1 and STATE == OFFBAR) then
            CleverAlchemistReticleIcon:SetHidden(false)
    else
        CleverAlchemistReticleIcon:SetHidden(true)
    end

    end)

local flag = true

    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, parseSlot)
    EVENT_MANAGER:AddFilterForEvent(ADDON_NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_WORN)
    EVENT_MANAGER:AddFilterForEvent(ADDON_NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)

    ZO_PreHook("ZO_ActionBar_CanUseActionSlots", function()
   --     flag = not flag -- Since ZO_ActionBar_CanUseActionSlots is called twice for each ability cast
    --    if flag then
            local slotNum = tonumber(debug.traceback():match('keybind = "ACTION_BUTTON_(%d)')) -- get pressed button
            if slotNum == 9 then -- break if consumable or empty slot
                if (currentHotbar == 0 and STATE ~= MAINBAR) or 
                (currentHotbar == 1 and STATE ~= OFFBAR) then
                 --   alert() -- notify player
                    return true -- ESO won't run ability press if PreHook returns true
            end
        else return false end
   --     end
    end)

    
  -- for i = 1, #SLOTS do gear[i] = { id = 0, link = 0, type = 0, isAlchemist = false} end

    
end

function getEquippedGear()
 --   for x = 1, #SLOTS do
    for i, v in pairs(SLOTS) do
        parseSlot(0, 0, v[1], 0, 0, 0, 0)
    end
end

local function stateChat()
    if pastState ~= STATE then
        if (STATE == MAINBAR) then
            d("[Clever Alchemist Helper]: Set detected on Mainbar")
        elseif (STATE == OFFBAR) then
            d("[Clever Alchemist Helper]: Set detected on Offbar")
        elseif (STATE == NEVER) then
            d("[Clever Alchemist Helper]: Off")
            CleverAlchemistReticleIcon:SetHidden(false)
        elseif (STATE == ALWAYS) then
            d("[Clever Alchemist Helper]: always")
            CleverAlchemistReticleIcon:SetHidden(false)
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

 --   if gear[i]["isAlchemist"] then
 --       d("Type: "..gear[i]["type"].." Slot: "..gear[i]["slot"].." "..tostring(gear[i]["isAlchemist"]))
 --   end


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
--d("equipped:"..equipped)
--d("Armor: "..armorBonus)
--d("mainBar: "..mainBarBonus)
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
    d(STATE)
    stateChat()
    switch()
 --   d("Armor: "..armorBonus)
  --  
 --   d("offBar: "..offBarBonus)
 --  d(totalBonus)
end

local pastState





    


function parseSlot(eventCode, bagId, slotIndex, isNewItem, itemSoundCategory, updateReason, stackCountChange)
    local itemType
  --  d("slot: "..slotIndex)
    itemType, _ = GetItemType(BAG_WORN, slotIndex)
    if itemType == ITEMTYPE_WEAPON then
        _, _, _, _, _, itemType, _, _ = GetItemInfo(BAG_WORN, slotIndex)
    end
     --   d(slotIndex.." "..TYPE[equipType][3])
    local link = GetItemLink(BAG_WORN, slotIndex)
    local hasSet, setName, numBonuses, numEquipped, _, setId = GetItemLinkSetInfo(link)
    if hasSet and setId == SET_ID then
        gear[slotIndex] = { link = itemLink, type = itemType, isAlchemist = true, slot = slotIndex }
        --    d(SLOTS[slotIndex][3].." = piece")
    else
        gear[slotIndex] = { link = itemLink, type = itemType, isAlchemist = false, slot = slotIndex }
          --    d(SLOTS[slotIndex][3].." = not piece")
    end
      --  d(gear[slotIndex]["isAlchemist"])

        if alchemist.ready then
            eval()
        end
      --    d(SLOTS[slotIndex][3].." = empty")
end

local function OnAddOnLoaded(event, addonName)
	if addonName == ADDON_NAME then
    	Initialize()
  	end
end

function alchemist.GetIdTypeAndLink(bag, slot)
    local itemType = GetItemType(bag, slot)
    local link = GetItemLink(bag, slot)
    local id

    id = Id64ToString(GetItemUniqueId(bag, slot))


    return id, itemType, link
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)