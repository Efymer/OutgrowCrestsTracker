local addonName, addon = ...

local frame       = nil
local lines       = {}
local lineCount   = 0

local FRAME_WIDTH  = 340
local LINE_HEIGHT  = 18
local DETAIL_HEIGHT = 16
local SECTION_GAP  = 8
local PAD          = 14

-- ------------------------------------------------------------------ helpers
local function GetOrCreateLine(parent)
    lineCount = lineCount + 1
    if lines[lineCount] then
        return lines[lineCount]
    end

    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(LINE_HEIGHT)
    row:SetWidth(FRAME_WIDTH - PAD * 2)

    local left = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    left:SetPoint("LEFT")
    left:SetJustifyH("LEFT")
    left:SetWidth((FRAME_WIDTH - PAD * 2) * 0.55)
    left:SetWordWrap(false)

    local right = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    right:SetPoint("RIGHT")
    right:SetJustifyH("RIGHT")
    right:SetWidth((FRAME_WIDTH - PAD * 2) * 0.44)
    right:SetWordWrap(false)

    row.left  = left
    row.right = right
    lines[lineCount] = row
    return row
end

local function HideAllLines()
    for _, row in ipairs(lines) do row:Hide() end
    lineCount = 0
end

-- ------------------------------------------------------------------ frame
local function CreateMainFrame()
    local f = CreateFrame("Frame", "OutgrowCrestsTrackerFrame", UIParent, "BackdropTemplate")
    f:SetSize(FRAME_WIDTH, 300)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:SetFrameStrata("DIALOG")

    f:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetBackdropColor(0.06, 0.06, 0.06, 0.92)
    f:SetBackdropBorderColor(0.50, 0.50, 0.50, 0.80)

    -- title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -PAD)
    title:SetText("Outgrow Crests Tracker")
    title:SetTextColor(1.0, 0.82, 0.0)

    -- close button
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    -- separator below title
    local sep = f:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  PAD, -34)
    sep:SetPoint("TOPRIGHT", -PAD, -34)
    sep:SetColorTexture(0.40, 0.40, 0.40, 0.50)

    f.contentTop = -40

    -- ESC to close
    tinsert(UISpecialFrames, "OutgrowCrestsTrackerFrame")

    f:Hide()
    return f
end

-- ------------------------------------------------------------------ refresh
function addon:RefreshDisplay()
    if not frame or not frame:IsShown() then return end

    HideAllLines()

    local slotData   = self:GetSlotData()
    local totalSlots = #slotData
    local y          = frame.contentTop
    local nextGoal   = nil

    -- ---- achievement rows -------------------------------------------
    for _, achiev in ipairs(addon.Config.achievements) do
        local _, _, _, completed = GetAchievementInfo(achiev.id)

        local ready = 0
        for _, slot in ipairs(slotData) do
            if slot.charWatermark >= achiev.ilvl then
                ready = ready + 1
            end
        end

        local row = GetOrCreateLine(frame)
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, y)
        row:SetHeight(LINE_HEIGHT)

        -- left: status icon + tier name
        local icon
        if completed then
            icon = "|cff00ff00\226\156\147|r"                -- green checkmark
        else
            icon = "|cffff4444\226\156\151|r"                -- red X
        end

        local nameHex
        if completed then
            nameHex = "00ff00"
        elseif not nextGoal then
            nameHex = "ffffff"                                -- next target: bright
        else
            nameHex = "666666"                                -- future: dim
        end

        row.left:SetText(string.format("%s |cff%s%s|r", icon, nameHex, achiev.name))

        -- right: ilvl threshold + slot count
        local countHex = (ready >= totalSlots) and "00ff00" or "ffcc00"
        row.right:SetText(string.format("|cff888888%d|r  |cff%s%d/%d|r",
            achiev.ilvl, countHex, ready, totalSlots))

        row:Show()
        y = y - LINE_HEIGHT

        if not completed and not nextGoal then
            nextGoal = achiev
        end
    end

    y = y - SECTION_GAP

    -- ---- separator --------------------------------------------------
    do
        local row = GetOrCreateLine(frame)
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, y)
        row:SetHeight(1)

        -- reuse left fontstring as a thin separator texture trick
        row.left:SetText("")
        row.right:SetText("")

        -- create a separator texture if not already
        if not row.sep then
            local sep = row:CreateTexture(nil, "ARTWORK")
            sep:SetHeight(1)
            sep:SetPoint("TOPLEFT")
            sep:SetPoint("TOPRIGHT")
            sep:SetColorTexture(0.40, 0.40, 0.40, 0.50)
            row.sep = sep
        end
        row:Show()
        y = y - SECTION_GAP
    end

    -- ---- next goal detail -------------------------------------------
    if nextGoal then
        local header = GetOrCreateLine(frame)
        header:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, y)
        header:SetHeight(LINE_HEIGHT)

        local cr, cg, cb = nextGoal.color[1], nextGoal.color[2], nextGoal.color[3]
        header.left:SetText(string.format(
            "|cffffcc00Slots below|r |cff%02x%02x%02x%s|r |cffffcc00(%d):|r",
            cr * 255, cg * 255, cb * 255, nextGoal.tier, nextGoal.ilvl))
        header.right:SetText("")
        header:Show()
        y = y - LINE_HEIGHT

        -- sort lagging slots by watermark ascending (worst first)
        local lagging = {}
        for _, slot in ipairs(slotData) do
            if slot.charWatermark < nextGoal.ilvl then
                lagging[#lagging + 1] = slot
            end
        end
        table.sort(lagging, function(a, b) return a.charWatermark < b.charWatermark end)

        if #lagging > 0 then
            for _, slot in ipairs(lagging) do
                local row = GetOrCreateLine(frame)
                row:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + 12, y)
                row:SetHeight(DETAIL_HEIGHT)

                local r, g, b = addon:GetTierColor(slot.charWatermark)
                row.left:SetText(string.format("|cffcccccc%s|r", slot.name))

                local diff = nextGoal.ilvl - slot.charWatermark
                row.right:SetText(string.format(
                    "|cff%02x%02x%02x%d|r  |cffff6666+%d needed|r",
                    r * 255, g * 255, b * 255, slot.charWatermark, diff))

                row:Show()
                y = y - DETAIL_HEIGHT
            end
        else
            -- all slots meet threshold but achievement not yet granted (edge case)
            local row = GetOrCreateLine(frame)
            row:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + 12, y)
            row:SetHeight(DETAIL_HEIGHT)
            row.left:SetText("|cff00ff00All slots meet the threshold!|r")
            row.right:SetText("")
            row:Show()
            y = y - DETAIL_HEIGHT
        end
    else
        -- all achievements done
        local row = GetOrCreateLine(frame)
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, y)
        row:SetHeight(LINE_HEIGHT)
        row.left:SetText("|cff00ff00All Dawn achievements completed!|r")
        row.right:SetText("")
        row:Show()
        y = y - LINE_HEIGHT
    end

    y = y - SECTION_GAP

    -- ---- separator --------------------------------------------------
    do
        local row = GetOrCreateLine(frame)
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, y)
        row:SetHeight(1)
        row.left:SetText("")
        row.right:SetText("")
        if not row.sep then
            local sep = row:CreateTexture(nil, "ARTWORK")
            sep:SetHeight(1)
            sep:SetPoint("TOPLEFT")
            sep:SetPoint("TOPRIGHT")
            sep:SetColorTexture(0.40, 0.40, 0.40, 0.50)
            row.sep = sep
        end
        row:Show()
        y = y - SECTION_GAP
    end

    -- ---- all slots overview -----------------------------------------
    local allHeader = GetOrCreateLine(frame)
    allHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, y)
    allHeader:SetHeight(LINE_HEIGHT)
    allHeader.left:SetText("|cffffcc00All Slots:|r")
    allHeader.right:SetText("|cff888888Char  /  Acct|r")
    allHeader:Show()
    y = y - LINE_HEIGHT

    -- sort by slot index for a natural equipment order
    local sorted = {}
    for i, slot in ipairs(slotData) do sorted[i] = slot end
    table.sort(sorted, function(a, b) return a.slotIndex < b.slotIndex end)

    for _, slot in ipairs(sorted) do
        local row = GetOrCreateLine(frame)
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + 12, y)
        row:SetHeight(DETAIL_HEIGHT)

        row.left:SetText(string.format("|cffcccccc%s|r", slot.name))

        local r, g, b = addon:GetTierColor(slot.charWatermark)
        local charText = string.format("|cff%02x%02x%02x%d|r", r * 255, g * 255, b * 255, slot.charWatermark)

        local acctText = ""
        if slot.acctWatermark > 0 and slot.acctWatermark ~= slot.charWatermark then
            local ar, ag, ab = addon:GetTierColor(slot.acctWatermark)
            acctText = string.format("  /  |cff%02x%02x%02x%d|r", ar * 255, ag * 255, ab * 255, slot.acctWatermark)
        end

        row.right:SetText(charText .. acctText)
        row:Show()
        y = y - DETAIL_HEIGHT
    end

    -- ---- resize frame to fit content --------------------------------
    frame:SetHeight(math.abs(y) + PAD)
end

-- ------------------------------------------------------------------ toggle
function addon:ToggleDisplay()
    if not frame then
        frame = CreateMainFrame()
    end

    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        self:RefreshDisplay()
    end
end
