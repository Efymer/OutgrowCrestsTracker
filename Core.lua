local addonName, addon = ...

local eventFrame = CreateFrame("Frame")

-- Query all equipment slot watermarks, filtering out irrelevant weapon slots
function addon:GetSlotData()
    local slots = {}
    for i = 0, 16 do
        local charWM, acctWM = C_ItemUpgrade.GetHighWatermarkForSlot(i)
        if charWM and charWM > 0 then
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

-- Return the highest tier this ilvl has outgrown (or nil if below Adventurer)
function addon:GetTierForIlvl(ilvl)
    local best = nil
    for _, achiev in ipairs(addon.Config.achievements) do
        if ilvl >= achiev.ilvl then
            best = achiev
        end
    end
    return best
end

-- Return r,g,b for the tier this ilvl belongs to
function addon:GetTierColor(ilvl)
    local tier = self:GetTierForIlvl(ilvl)
    if tier then
        return tier.color[1], tier.color[2], tier.color[3]
    end
    return 0.50, 0.50, 0.50
end

eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        -- Frame is created on first /outgrow
    end
end)
eventFrame:RegisterEvent("PLAYER_LOGIN")

SLASH_OUTGROWCRESTSTRACKER1 = "/outgrow"
SLASH_OUTGROWCRESTSTRACKER2 = "/crests"
SlashCmdList["OUTGROWCRESTSTRACKER"] = function()
    addon:ToggleDisplay()
end
