local addonName, addon = ...

local eventFrame = CreateFrame("Frame")

-- Query all equipment slot watermarks, filtering out irrelevant weapon slots
function addon:GetSlotData()
    local slots = {}
    if not C_ItemUpgrade or not C_ItemUpgrade.GetHighWatermarkForSlot then
        return slots
    end
    for i = 0, 16 do
        local ok, charWM, acctWM = pcall(C_ItemUpgrade.GetHighWatermarkForSlot, i)
        if ok and charWM and charWM > 0 then
            slots[#slots + 1] = {
                slotIndex      = i,
                name           = addon.Config.slotNames[i] or ("Slot " .. i),
                charWatermark  = charWM,
                acctWatermark  = acctWM or 0,
            }
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
