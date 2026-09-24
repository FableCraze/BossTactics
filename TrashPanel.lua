-- TrashPanel.lua (Boss Tactics 4.2.1)
-- Independent, resizable dungeon-trash companion. The compact view keeps the
-- mob and its important ability visible; clicking a mob expands its details.

local BT = BossTactics
local C = BT.Components
local D = BT.Detection
local Theme = BT.Theme

local TP = {
    dungeon = nil,
    difficulty = nil,
    cards = {},
    cardPool = {},
    expandedEnemies = {},
}
BT.TrashPanel = TP

local PAD = 6
local HEADER_H = 34
local MIN_W, MIN_H = 220, 100
local MAX_W, MAX_H = 700, 700

local PRIORITY_COLORS = {
    [1] = { 1.00, 0.30, 0.30, "|cffff5555" },
    [2] = { 1.00, 0.78, 0.15, "|cffffcc00" },
    [3] = { 0.35, 0.80, 1.00, "|cff66ccff" },
}

local function PriorityColor(priority)
    return PRIORITY_COLORS[tonumber(priority) or 3] or PRIORITY_COLORS[3]
end

local function ApplyTrashFont(fs, kind, fontObject)
    local base = type(fontObject) == "string" and _G[fontObject] or fontObject
    fs:SetFontObject(base or GameFontHighlight)
    local db = BT.db or {}
    local face = db.trashPanelFontFace
    local size = db.trashPanelFontSize
    if not face and not size then return end
    local currentFace, currentSize, flags = fs:GetFont()
    local sharedFace = GameFontHighlight and select(1, GameFontHighlight:GetFont())
    face = C:NormalizeFontPath(face or sharedFace or currentFace)
    size = size or currentSize or 12
    if kind == "title" then size = size + 2 end
    if kind == "small" then size = math.max(9, size - 1) end
    fs:SetFont(face, size, flags or "")
end

local function ReleaseCards(self)
    for _, card in ipairs(self.cards) do
        card:Hide()
        card:ClearAllPoints()
        for _, line in ipairs(card.lines) do
            line:Hide()
            line:ClearAllPoints()
        end
        card._lineIndex = 0
        self.cardPool[#self.cardPool + 1] = card
    end
    wipe(self.cards)
end

local function AcquireCard(self)
    local card = table.remove(self.cardPool)
    if not card then
        card = CreateFrame("Button", nil, self.content)
        card.lines = {}

        card.hover = card:CreateTexture(nil, "BACKGROUND")
        card.hover:SetAllPoints()
        card.hover:SetColorTexture(1, 1, 1, 0.055)
        card.hover:Hide()

        card.stripe = card:CreateTexture(nil, "ARTWORK")
        card.stripe:SetPoint("TOPLEFT", 0, -2)
        card.stripe:SetPoint("BOTTOMLEFT", 0, 2)
        card.stripe:SetWidth(2)

        card.enemy = card:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        card.enemy:SetPoint("TOPLEFT", 7, -4)
        card.enemy:SetJustifyH("LEFT")
        card.enemy:SetWordWrap(false)

        card.arrow = card:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        card.arrow:SetPoint("TOPRIGHT", -5, -5)
        card.arrow:SetJustifyH("RIGHT")
        card.arrow:SetTextColor(1, 0.82, 0)

        card:SetScript("OnEnter", function(btn)
            btn.hover:Show()
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText(BT:L(TP.expandedEnemies[btn._enemyKey]
                and "TRASH_CLICK_COLLAPSE" or "TRASH_CLICK_EXPAND"), 1, 1, 1)
            GameTooltip:Show()
        end)
        card:SetScript("OnLeave", function(btn)
            btn.hover:Hide()
            GameTooltip:Hide()
        end)
        card:SetScript("OnClick", function(btn)
            if not btn._enemyKey then return end
            TP.expandedEnemies[btn._enemyKey] = not TP.expandedEnemies[btn._enemyKey]
            TP:Refresh()
        end)
    end
    card._lineIndex = 0
    card:Show()
    self.cards[#self.cards + 1] = card
    return card
end

local function CardLine(card, text, y, width, fontObject, indent, fontKind)
    card._lineIndex = card._lineIndex + 1
    local fs = card.lines[card._lineIndex]
    if not fs then
        fs = card:CreateFontString(nil, "ARTWORK", fontObject or "GameFontHighlight")
        card.lines[card._lineIndex] = fs
    end
    ApplyTrashFont(fs, fontKind or "body", fontObject or "GameFontHighlight")
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", indent or 8, y)
    fs:SetWidth(width - (indent or 8) - 7)
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    fs:SetWordWrap(true)
    fs:SetNonSpaceWrap(true)
    fs:SetText(text)
    fs:Show()
    local h = fs:GetStringHeight()
    if not h or h < 1 then h = 12 end
    return y - h - 4
end

local function GroupEntries(entries)
    local groups, byEnemy = {}, {}
    for _, entry in ipairs(entries) do
        local enemy = BT:Localize(entry.enemy) or entry.enemy or BT:L("JN_TRASH_UNKNOWN_ENEMY")
        -- Localized enemy fields are tables; use the resolved name as the
        -- stable grouping key so multiple mechanics from one enemy remain on
        -- the same card in translated clients.
        local key = tostring(enemy)
        local group = byEnemy[key]
        if not group then
            group = { key = key, enemy = enemy, priority = tonumber(entry.priority) or 99, entries = {} }
            byEnemy[key] = group
            groups[#groups + 1] = group
        end
        group.entries[#group.entries + 1] = entry
        group.priority = math.min(group.priority, tonumber(entry.priority) or 99)
    end
    table.sort(groups, function(a, b)
        if a.priority ~= b.priority then return a.priority < b.priority end
        return tostring(a.enemy) < tostring(b.enemy)
    end)
    return groups
end

function TP:Create()
    if self.frame then return end
    local f = CreateFrame("Frame", "BossTacticsTrashPanel", UIParent)
    self.frame = f
    local db = BT.db or {}
    f:SetSize(db.trashPanelWidth or 330, db.trashPanelHeight or 260)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetResizable(true)
    f:SetFrameStrata("MEDIUM")
    f:SetToplevel(true)
    f:EnableMouse(true)
    if f.SetResizeBounds then
        f:SetResizeBounds(MIN_W, MIN_H, MAX_W, MAX_H)
    elseif f.SetMinResize and f.SetMaxResize then
        f:SetMinResize(MIN_W, MIN_H)
        f:SetMaxResize(MAX_W, MAX_H)
    end

    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetColorTexture(0, 0, 0, 0.90)
    f.bg:SetPoint("TOPLEFT", -4, 4)
    f.bg:SetPoint("BOTTOMRIGHT", 4, -4)

    local header = CreateFrame("Button", nil, f)
    f.header = header
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    header:SetHeight(HEADER_H)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function()
        if not (BT.db and BT.db.trashPanelLocked) then f:StartMoving() end
    end)
    header:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local point, _, _, x, y = f:GetPoint(1)
        if BT.db then BT.db.trashPanelPosition = { point = point, x = x, y = y } end
    end)

    f.title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalMed2")
    f.title:SetPoint("TOPLEFT", PAD, -2)
    f.title:SetPoint("RIGHT", -24, 0)
    f.title:SetJustifyH("LEFT")
    f.title:SetWordWrap(false)

    f.subtitle = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.subtitle:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -2)
    f.subtitle:SetPoint("RIGHT", -PAD, 0)
    f.subtitle:SetJustifyH("LEFT")
    f.subtitle:SetWordWrap(false)

    local close = CreateFrame("Button", nil, header)
    f.close = close
    close:SetSize(16, 16)
    close:SetPoint("TOPRIGHT", -2, -1)
    close.label = close:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    close.label:SetPoint("CENTER")
    close.label:SetText("X")
    close.label:SetTextColor(1, 0.35, 0.35)
    local closeHL = close:CreateTexture(nil, "HIGHLIGHT")
    closeHL:SetAllPoints()
    closeHL:SetColorTexture(1, 1, 1, 0.12)
    close:SetScript("OnClick", function() TP:Hide() end)
    close:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:SetText(BT:L("TOOLTIP_PANEL_CLOSE"), 1, 1, 1)
        GameTooltip:Show()
    end)
    close:SetScript("OnLeave", function() GameTooltip:Hide() end)

    f.headerLine = f:CreateTexture(nil, "ARTWORK")
    f.headerLine:SetPoint("TOPLEFT", 0, -HEADER_H)
    f.headerLine:SetPoint("TOPRIGHT", 0, -HEADER_H)
    f.headerLine:SetHeight(1)
    f.headerLine:SetColorTexture(0.65, 0.55, 0.20, 0.65)

    f.scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    f.scroll:SetPoint("TOPLEFT", PAD, -HEADER_H - 4)
    f.scroll:SetPoint("BOTTOMRIGHT", -26, 10)
    f.content = CreateFrame("Frame", nil, f.scroll)
    self.content = f.content
    f.content:SetSize((db.trashPanelWidth or 330) - 34, 1)
    f.scroll:SetScrollChild(f.content)
    f.scroll:EnableMouseWheel(true)
    f.scroll:SetScript("OnMouseWheel", function(scroll, delta)
        local maxScroll = math.max(0, scroll:GetVerticalScrollRange() or 0)
        scroll:SetVerticalScroll(math.max(0,
            math.min(maxScroll, scroll:GetVerticalScroll() - delta * 32)))
    end)

    local grip = CreateFrame("Button", nil, f)
    self.resizeGrip = grip
    grip:SetSize(18, 18)
    grip:SetPoint("BOTTOMRIGHT", -1, 1)
    local gripTexture = grip:CreateTexture(nil, "ARTWORK")
    gripTexture:SetAllPoints()
    gripTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and not (BT.db and BT.db.trashPanelLocked) then
            f:StartSizing("BOTTOMRIGHT")
        end
    end)
    grip:SetScript("OnMouseUp", function()
        f:StopMovingOrSizing()
        if BT.db then
            BT.db.trashPanelWidth = math.floor(f:GetWidth() + 0.5)
            BT.db.trashPanelHeight = math.floor(f:GetHeight() + 0.5)
        end
        TP:Refresh()
    end)

    f:SetScript("OnSizeChanged", function(frame)
        if frame._trashResizePending then return end
        frame._trashResizePending = true
        C_Timer.After(0, function()
            frame._trashResizePending = nil
            if TP:IsShown() then TP:Refresh() end
        end)
    end)

    local pos = db.trashPanelPosition
    f:SetPoint(pos and pos.point or "RIGHT", UIParent, pos and pos.point or "RIGHT",
        pos and pos.x or -390, pos and pos.y or 60)
    if Theme then
        Theme:StyleSurface(f, "window", true)
        Theme:StyleAddonTree(f)
        Theme:StyleTitle(f.title)
    end
    f:Hide()
end

function TP:ShowDungeon(dungeon, difficulty)
    if not dungeon or not (BT_TrashData and BT_TrashData[dungeon]) then return end
    self:Create()
    self.dungeon = dungeon
    self.difficulty = C.ResolveContentDifficulty(nil,
        difficulty or D.activeDifficulty or "NORMAL")
    self.frame:Show()
    self.frame:Raise()
    self:Refresh()
    if BT.MiniPanel and BT.MiniPanel.UpdateQuickButtons then
        BT.MiniPanel:UpdateQuickButtons()
    end
end

function TP:Hide()
    if self.frame then self.frame:Hide() end
    if BT.MiniPanel and BT.MiniPanel.UpdateQuickButtons then
        BT.MiniPanel:UpdateQuickButtons()
    end
end

function TP:IsShown()
    return self.frame and self.frame:IsShown()
end

function TP:ApplyLook()
    if not self.frame then return end
    local db = BT.db or {}
    self.frame:SetScale(db.trashPanelScale or 1.0)
    self.frame:SetAlpha(db.trashPanelAlpha or 1.0)
    local color = db.trashBackdropColor or { a = 0.96 }
    self.frame.bg:Hide()
    if self.frame._btThemeBackground then
        local alpha = db.trashBackdropMode == false and 0 or (color.a or 0.96)
        self.frame._btThemeBackground:SetColorTexture(0.063, 0.063, 0.063, alpha)
    end
    if self.resizeGrip then
        self.resizeGrip:SetShown(not db.trashPanelLocked)
    end
end

function TP:Refresh()
    local f = self.frame
    local trash = self.dungeon and BT_TrashData and BT_TrashData[self.dungeon]
    if not f or not trash then return end
    self.difficulty = C.ResolveContentDifficulty(nil, self.difficulty or "NORMAL")
    ReleaseCards(self)

    local db = BT.db or {}
    local contentWidth = math.max(160, f:GetWidth() - 34)
    f.content:SetWidth(contentWidth)
    self:ApplyLook()
    ApplyTrashFont(f.title, "title", GameFontNormalMed2 or GameFontNormal)
    ApplyTrashFont(f.subtitle, "small", GameFontHighlightSmall)
    f.title:SetText("|cffffcc00" .. BT:L("TRASH_PANEL_TITLE") .. "|r")
    f.subtitle:SetText(self.dungeon)

    local role = db.roleFilter or "ALL"
    local entries = C.FilterAbilities(trash.enemies, self.difficulty, role)
    C.SortTrashEntries(entries)
    local groups = GroupEntries(entries)
    local y = 0

    for _, group in ipairs(groups) do
        local card = AcquireCard(self)
        local expanded = self.expandedEnemies[group.key]
        local color = PriorityColor(group.priority)
        card._enemyKey = group.key
        card:SetPoint("TOPLEFT", 0, y)
        card:SetWidth(contentWidth)
        card.enemy:SetWidth(contentWidth - 30)
        card.enemy:SetText(color[4] .. group.enemy .. "|r")
        card.arrow:SetText(expanded and "-" or "+")
        card.stripe:SetColorTexture(color[1], color[2], color[3], 0.95)
        ApplyTrashFont(card.enemy, "body", GameFontNormal)
        ApplyTrashFont(card.arrow, "small", GameFontNormalSmall)

        local lineY = -24
        for _, entry in ipairs(group.entries) do
            lineY = CardLine(card, C.FormatTrashMechanic(entry), lineY,
                contentWidth, "GameFontHighlight", 9, "body")
            if expanded then
                local description = BT:Localize(entry.description) or ""
                if description ~= "" then
                    lineY = CardLine(card, "|cffbbbbbb" .. description .. "|r", lineY,
                        contentWidth, "GameFontHighlightSmall", 19, "small")
                end
            end
        end
        local cardH = math.max(38, -lineY + 1)
        card:SetHeight(cardH)
        y = y - cardH - 3
    end

    if #groups == 0 then
        local card = AcquireCard(self)
        card._enemyKey = nil
        card:SetPoint("TOPLEFT", 0, y)
        card:SetWidth(contentWidth)
        card.enemy:SetText("|cff888888" .. BT:L("JN_NO_ROLE_TRASH_DATA") .. "|r")
        card.enemy:SetWidth(contentWidth - 12)
        card.arrow:SetText("")
        card.stripe:SetColorTexture(0.4, 0.4, 0.4, 0.6)
        ApplyTrashFont(card.enemy, "small", GameFontHighlightSmall)
        card:SetHeight(34)
        y = y - 37
    end

    f.content:SetHeight(math.max(1, -y))
    local maxScroll = math.max(0, f.scroll:GetVerticalScrollRange() or 0)
    f.scroll:SetVerticalScroll(math.min(f.scroll:GetVerticalScroll() or 0, maxScroll))
end
