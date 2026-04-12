local addonName, addon = ...

local eventFrame = CreateFrame("Frame")

-- Query all equipment slot watermarks, selecting only the best weapon group
function addon:GetSlotData()
    local slots = {}
    if not C_ItemUpgrade or not C_ItemUpgrade.GetHighWatermarkForSlot then
        return slots
    end

    -- Collect raw watermarks for all slots
    local raw = {}
    for i = 0, 16 do
        local ok, charWM, acctWM = pcall(C_ItemUpgrade.GetHighWatermarkForSlot, i)
        if ok and charWM and charWM > 0 then
            raw[i] = {
                slotIndex     = i,
                name          = addon.Config.slotNames[i] or ("Slot " .. i),
                charWatermark = charWM,
                acctWatermark = acctWM or 0,
            }
        end
    end

    -- Armor slots (0-11): always included
    for i = 0, 11 do
        if raw[i] then
            slots[#slots + 1] = raw[i]
        end
    end

    -- Weapon slots (12-16): pick the best active group
    -- A group is "active" when all its slots have non-zero watermarks
    -- Among active groups, pick the one with the highest minimum watermark
    local bestGroup, bestMin = nil, -1
    for _, group in ipairs(addon.Config.weaponGroups) do
        local active = true
        local minWM  = math.huge
        for _, idx in ipairs(group) do
            if not raw[idx] then
                active = false
                break
            end
            if raw[idx].charWatermark < minWM then
                minWM = raw[idx].charWatermark
            end
        end
        if active and minWM > bestMin then
            bestMin   = minWM
            bestGroup = group
        end
    end

    if bestGroup then
        for _, idx in ipairs(bestGroup) do
            slots[#slots + 1] = raw[idx]
        end
    end

    return slots
end

-- Initialize saved variables
local function InitDB()
    if not OutgrowCrestsTrackerDB then
        OutgrowCrestsTrackerDB = {}
    end
    local db = OutgrowCrestsTrackerDB
    if not db.minimap then
        db.minimap = { degrees = 220 }
    end
    addon.db = db
end

eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        InitDB()
        addon:InitMinimapButton()
    end
end)
eventFrame:RegisterEvent("PLAYER_LOGIN")

SLASH_OUTGROWCRESTSTRACKER1 = "/outgrow"
SLASH_OUTGROWCRESTSTRACKER2 = "/crests"
SlashCmdList["OUTGROWCRESTSTRACKER"] = function()
    addon:ToggleDisplay()
end
