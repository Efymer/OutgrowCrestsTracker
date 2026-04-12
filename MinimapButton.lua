local addonName, addon = ...

local ICON_TEXTURE   = "Interface\\Icons\\Achievement_General"
local BUTTON_RADIUS  = 104

-- ------------------------------------------------------------------ button
local button = CreateFrame("Button", "OutgrowCrestsTrackerMinimapBtn", Minimap)
button:SetSize(33, 33)
button:SetFrameStrata("MEDIUM")
button:SetFrameLevel(8)
button:SetMovable(true)
button:RegisterForDrag("LeftButton")
button:RegisterForClicks("LeftButtonUp")

local overlay = button:CreateTexture(nil, "OVERLAY")
overlay:SetSize(53, 53)
overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
overlay:SetPoint("TOPLEFT")

local bg = button:CreateTexture(nil, "BACKGROUND")
bg:SetSize(20, 20)
bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
bg:SetPoint("TOPLEFT", 7, -5)

local icon = button:CreateTexture(nil, "ARTWORK")
icon:SetSize(17, 17)
icon:SetTexture(ICON_TEXTURE)
icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
icon:SetPoint("TOPLEFT", 7, -6)

button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

-- ------------------------------------------------------------------ position
local function UpdatePosition(degrees)
    local angle = math.rad(degrees)
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(angle) * BUTTON_RADIUS,
        math.sin(angle) * BUTTON_RADIUS)
end

-- ------------------------------------------------------------------ events
button:SetScript("OnClick", function()
    addon:ToggleDisplay()
end)

button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Outgrow Crests Tracker", 1.0, 0.82, 0.0)
    GameTooltip:AddLine("|cffffffffLeft-click|r to toggle window", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("|cffffffffDrag|r to reposition", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end)

button:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

button:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale  = Minimap:GetEffectiveScale()
        local degrees = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
        if addon.db then
            addon.db.minimap.degrees = degrees
        end
        UpdatePosition(degrees)
    end)
end)

button:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
end)

-- ------------------------------------------------------------------ init
button:Hide()

function addon:InitMinimapButton()
    local degrees = (addon.db and addon.db.minimap and addon.db.minimap.degrees) or 220
    UpdatePosition(degrees)
    button:Show()

    -- Addon compartment (10.x+)
    if AddonCompartmentFrame and AddonCompartmentFrame.RegisterAddon then
        AddonCompartmentFrame:RegisterAddon({
            text = "Outgrow Crests Tracker",
            icon = ICON_TEXTURE,
            notCheckable = true,
            registerForAnyClick = true,
            func = function() addon:ToggleDisplay() end,
        })
    end
end
