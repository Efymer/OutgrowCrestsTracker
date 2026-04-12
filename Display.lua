local addonName, addon = ...

local frame         = nil
local achievRows    = {}
local detailLines   = {}
local detailCount   = 0
local selectedIndex = nil

local FRAME_WIDTH   = 420
local LINE_HEIGHT   = 22
local DETAIL_HEIGHT = 18
local SECTION_GAP   = 8
local PAD           = 16
local CONTENT_W     = FRAME_WIDTH - PAD * 2

-- ------------------------------------------------------------------ icons
local ICON_CHECK = "|A:common-icon-checkmark:14:14|a"
local ICON_CROSS = "|A:common-icon-redx:14:14|a"

local GREEN  = "00ff00"
local RED    = "ff4444"
local YELLOW = "ffcc00"
local GRAY   = "888888"
local WHITE  = "ffffff"
local DIM    = "666666"

-- ------------------------------------------------------------------ detail line pool
local function GetOrCreateDetailLine(parent)
    detailCount = detailCount + 1
    if detailLines[detailCount] then
        return detailLines[detailCount]
    end

    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(DETAIL_HEIGHT)
    row:SetWidth(CONTENT_W)

    local left = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    left:SetPoint("LEFT", 4, 0)
    left:SetJustifyH("LEFT")
    left:SetWidth(CONTENT_W * 0.45)
    left:SetWordWrap(false)

    local right = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    right:SetPoint("RIGHT", -4, 0)
    right:SetJustifyH("RIGHT")
    right:SetWidth(CONTENT_W * 0.53)
    right:SetWordWrap(false)

    row.left  = left
    row.right = right
    detailLines[detailCount] = row
    return row
end

local function HideDetailLines()
    for _, row in ipairs(detailLines) do row:Hide() end
    detailCount = 0
end

-- ------------------------------------------------------------------ achievement rows
local function CreateAchievRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(LINE_HEIGHT)
    row:SetWidth(CONTENT_W)
    row:EnableMouse(true)

    -- selection / hover highlight
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(1, 1, 1, 0)
    row.bg = bg

    -- left-edge accent bar for selected row
    local accent = row:CreateTexture(nil, "ARTWORK")
    accent:SetWidth(3)
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("BOTTOMLEFT", 0, 0)
    accent:Hide()
    row.accent = accent

    local left = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    left:SetPoint("LEFT", 8, 0)
    left:SetJustifyH("LEFT")
    left:SetWidth(CONTENT_W * 0.60)
    left:SetWordWrap(false)

    local right = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    right:SetPoint("RIGHT", -8, 0)
    right:SetJustifyH("RIGHT")
    right:SetWidth(CONTENT_W * 0.38)
    right:SetWordWrap(false)

    row.left  = left
    row.right = right
    row.achievIndex = index

    row:SetScript("OnMouseUp", function(self)
        selectedIndex = self.achievIndex
        addon:RefreshDisplay()
    end)

    row:SetScript("OnEnter", function(self)
        if selectedIndex ~= self.achievIndex then
            self.bg:SetColorTexture(1, 1, 1, 0.04)
        end
    end)

    row:SetScript("OnLeave", function(self)
        if selectedIndex ~= self.achievIndex then
            self.bg:SetColorTexture(1, 1, 1, 0)
        end
    end)

    return row
end

-- ------------------------------------------------------------------ separators
local separators = {}
local function GetOrCreateSep(parent, idx)
    if separators[idx] then return separators[idx] end
    local sep = parent:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetColorTexture(0.40, 0.40, 0.40, 0.50)
    separators[idx] = sep
    return sep
end

-- ------------------------------------------------------------------ main frame
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
    sep:SetPoint("TOPLEFT",  PAD, -36)
    sep:SetPoint("TOPRIGHT", -PAD, -36)
    sep:SetColorTexture(0.40, 0.40, 0.40, 0.50)

    f.contentTop = -42

    -- create the 5 fixed achievement rows
    for i = 1, #addon.Config.achievements do
        achievRows[i] = CreateAchievRow(f, i)
    end

    tinsert(UISpecialFrames, "OutgrowCrestsTrackerFrame")

    f:Hide()
    return f
end

-- ------------------------------------------------------------------ refresh
function addon:RefreshDisplay()
    if not frame or not frame:IsShown() then return end

    HideDetailLines()

    local slotData   = self:GetSlotData()
    local totalSlots = #slotData
    local y          = frame.contentTop

    -- pre-compute achievement status
    local achStatus = {}
    local firstIncomplete = nil
    for i, achiev in ipairs(addon.Config.achievements) do
        local _, _, _, completed = GetAchievementInfo(achiev.id)
        local ready = 0
        for _, slot in ipairs(slotData) do
            if slot.charWatermark >= achiev.ilvl then
                ready = ready + 1
            end
        end
        achStatus[i] = { completed = completed, ready = ready }
        if not completed and not firstIncomplete then
            firstIncomplete = i
        end
    end

    -- auto-select first incomplete achievement
    if not selectedIndex then
        selectedIndex = firstIncomplete or #addon.Config.achievements
    end

    -- ---- achievement rows -------------------------------------------
    for i, achiev in ipairs(addon.Config.achievements) do
        local st  = achStatus[i]
        local row = achievRows[i]
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, y)

        -- icon: green check or red X
        local icon = st.completed and ICON_CHECK or ICON_CROSS

        -- name color: green if done, white if next target, dim if future
        local nameHex
        if st.completed then
            nameHex = GREEN
        elseif i == firstIncomplete then
            nameHex = WHITE
        else
            nameHex = DIM
        end

        row.left:SetText(string.format("%s  |cff%s%s|r", icon, nameHex, achiev.name))

        -- right: ilvl (green/red) + slot count
        local ilvlHex = st.completed and GREEN or RED
        local countHex = (st.ready >= totalSlots and totalSlots > 0) and GREEN or YELLOW
        row.right:SetText(string.format(
            "|cff%s%d|r     |cff%s%d/%d|r",
            ilvlHex, achiev.ilvl, countHex, st.ready, totalSlots))

        -- selection highlight
        if selectedIndex == i then
            local cr, cg, cb = achiev.color[1], achiev.color[2], achiev.color[3]
            row.bg:SetColorTexture(cr, cg, cb, 0.12)
            row.accent:SetColorTexture(cr, cg, cb, 0.90)
            row.accent:Show()
        else
            row.bg:SetColorTexture(1, 1, 1, 0)
            row.accent:Hide()
        end

        row:Show()
        y = y - LINE_HEIGHT
    end

    y = y - SECTION_GAP

    -- ---- separator 1 ------------------------------------------------
    local sep1 = GetOrCreateSep(frame, 1)
    sep1:ClearAllPoints()
    sep1:SetPoint("TOPLEFT",  frame, "TOPLEFT",  PAD, y)
    sep1:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, y)
    y = y - SECTION_GAP

    -- ---- selected achievement detail --------------------------------
    local selAchiev = addon.Config.achievements[selectedIndex]
    local selSt     = achStatus[selectedIndex]

    -- header
    local header = GetOrCreateDetailLine(frame)
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, y)
    header:SetHeight(LINE_HEIGHT)

    local cr, cg, cb = selAchiev.color[1], selAchiev.color[2], selAchiev.color[3]

    if selSt.completed then
        header.left:SetText(string.format(
            "|cff%02x%02x%02x%s|r |cff%s(%d)|r  %s",
            cr * 255, cg * 255, cb * 255,
            selAchiev.tier, GRAY, selAchiev.ilvl, ICON_CHECK))
        header.right:SetText(string.format("|cff%sCompleted|r", GREEN))
    else
        local laggingCount = totalSlots - selSt.ready
        header.left:SetText(string.format(
            "|cff%sSlots below|r |cff%02x%02x%02x%s|r |cff%s(%d):|r",
            YELLOW, cr * 255, cg * 255, cb * 255,
            selAchiev.tier, YELLOW, selAchiev.ilvl))
        header.right:SetText(string.format("|cff%s%d remaining|r", RED, laggingCount))
    end
    header:Show()
    y = y - LINE_HEIGHT

    if totalSlots == 0 then
        local row = GetOrCreateDetailLine(frame)
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + 14, y)
        row:SetHeight(DETAIL_HEIGHT)
        row.left:SetText(string.format("|cff%sNo slot data available.|r", GRAY))
        row.right:SetText("")
        row:Show()
        y = y - DETAIL_HEIGHT
    elseif not selSt.completed then
        -- lagging slots sorted by watermark (worst first)
        local lagging = {}
        for _, slot in ipairs(slotData) do
            if slot.charWatermark < selAchiev.ilvl then
                lagging[#lagging + 1] = slot
            end
        end
        table.sort(lagging, function(a, b) return a.charWatermark < b.charWatermark end)

        if #lagging > 0 then
            for _, slot in ipairs(lagging) do
                local row = GetOrCreateDetailLine(frame)
                row:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + 14, y)
                row:SetHeight(DETAIL_HEIGHT)

                row.left:SetText(string.format("|cff%s%s|r", RED, slot.name))

                local diff = selAchiev.ilvl - slot.charWatermark
                row.right:SetText(string.format(
                    "|cff%s%d|r    |cff%s+%d needed|r",
                    RED, slot.charWatermark, RED, diff))

                row:Show()
                y = y - DETAIL_HEIGHT
            end
        else
            local row = GetOrCreateDetailLine(frame)
            row:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + 14, y)
            row:SetHeight(DETAIL_HEIGHT)
            row.left:SetText(string.format("|cff%sAll slots meet the threshold!|r", GREEN))
            row.right:SetText("")
            row:Show()
            y = y - DETAIL_HEIGHT
        end
    end

    y = y - SECTION_GAP

    -- ---- separator 2 ------------------------------------------------
    local sep2 = GetOrCreateSep(frame, 2)
    sep2:ClearAllPoints()
    sep2:SetPoint("TOPLEFT",  frame, "TOPLEFT",  PAD, y)
    sep2:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, y)
    y = y - SECTION_GAP

    -- ---- all slots overview -----------------------------------------
    local allHeader = GetOrCreateDetailLine(frame)
    allHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, y)
    allHeader:SetHeight(LINE_HEIGHT)
    allHeader.left:SetText(string.format("|cff%sAll Slots:|r", YELLOW))
    allHeader.right:SetText("")
    allHeader:Show()
    y = y - LINE_HEIGHT

    if totalSlots == 0 then
        local row = GetOrCreateDetailLine(frame)
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + 14, y)
        row:SetHeight(DETAIL_HEIGHT)
        row.left:SetText(string.format("|cff%sNo data — equip gear and reopen.|r", GRAY))
        row.right:SetText("")
        row:Show()
        y = y - DETAIL_HEIGHT
    else
        -- sort by slot index for natural equipment order
        local sorted = {}
        for i, slot in ipairs(slotData) do sorted[i] = slot end
        table.sort(sorted, function(a, b) return a.slotIndex < b.slotIndex end)

        for _, slot in ipairs(sorted) do
            local row = GetOrCreateDetailLine(frame)
            row:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + 14, y)
            row:SetHeight(DETAIL_HEIGHT)

            local meets = slot.charWatermark >= selAchiev.ilvl
            local color = meets and GREEN or RED
            local icon  = meets and ICON_CHECK or ICON_CROSS

            row.left:SetText(string.format("|cff%s%s|r", color, slot.name))
            row.right:SetText(string.format(
                "|cff%s%d|r  %s", color, slot.charWatermark, icon))

            row:Show()
            y = y - DETAIL_HEIGHT
        end
    end

    -- ---- resize to fit content --------------------------------------
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
