-- Journal.lua  (Boss Tactics)
-- Pre-pull briefing window for raid leaders: full read-only overview of a
-- boss (TLDR + abilities + tips + active affix tips) with per-item chat
-- sharing. Read-only — safe to keep open in combat (opening is manual only).
--
-- Filters (role + difficulty) are LOCAL to the journal: they never touch
-- db.roleFilter or Detection.activeDifficulty.

local BT = BossTactics
local C = BT.Components
local D = BT.Detection
local Theme = BT.Theme

local J = {}
BT.Journal = J

J.selectedKey = nil
J.roleFilter  = "ALL"                              -- journal-local
J.difficulty  = nil                                -- journal-local; set on open
J.requestedDifficulty = nil                         -- preservada ao visitar masmorras fixas
J.view        = "TLDR"                             -- OVERVIEW | TRASH | TLDR | ABILITIES | TIPS
J.selections  = {}                                 -- session-only, per boss+difficulty

local VIEWS = {
    { key = "OVERVIEW",  labelKey = "JN_SEC_OVERVIEW" },
    { key = "TRASH",     labelKey = "JN_SEC_TRASH" },
    { key = "TLDR",      labelKey = "JN_SEC_TLDR" },
    { key = "ABILITIES", labelKey = "JN_SEC_ABILITIES" },
    { key = "TIPS",      labelKey = "JN_SEC_TIPS" },
}

local SECTION_GAP = 16
local ITEM_GAP    = 6
local PANE_GAP    = 14
local TOOLBAR_H   = 24
local HEADER_ROWS_H = 56
local FOOTER_H    = 30
local WIDE_THRESHOLD = 1000

local SIDEBAR_BACKDROP = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local function Clamp(value, low, high)
    value = tonumber(value) or low
    return math.max(low, math.min(high, value))
end

local FONT_DEFS = {
    title       = { name = "BossTacticsJournalTitleFont",       base = function() return GameFontNormalLarge end },
    subtitle    = { name = "BossTacticsJournalSubtitleFont",    base = function() return GameFontHighlightSmall end },
    section     = { name = "BossTacticsJournalSectionFont",     base = function() return GameFontNormalLarge end },
    body        = { name = "BossTacticsJournalBodyFont",        base = function() return GameFontHighlight end },
    small       = { name = "BossTacticsJournalSmallFont",       base = function() return GameFontHighlightSmall end },
    listSection = { name = "BossTacticsJournalListSectionFont", base = function() return GameFontNormalLarge end },
    listDungeon = { name = "BossTacticsJournalListDungeonFont", base = function() return GameFontNormal or GameFontHighlight end },
    listRow     = { name = "BossTacticsJournalListRowFont",     base = function() return GameFontHighlight end },
}

local DIFF_CYCLE = { "NORMAL", "HEROIC", "MYTHIC" }

local ROLE_CHAT_PREFIX = {
    tank = "TANQUE: ", healer = "CURADOR: ", dps = "DPS: ", interrupt = "INTERROMPER: ",
}

--- Default journal difficulty: current runtime context mapped into the
--- N/H/M cycle, NORMAL when outside an instance. Defaulting to Mythic made
--- the badge look like a claim about the tactic data instead of a filter.
local function DefaultDifficulty()
    local d = D.activeDifficulty
    if d == "LFR" then d = "NORMAL" end
    for _, v in ipairs(DIFF_CYCLE) do
        if v == d then return d end
    end
    return "NORMAL"
end

local function SelectionID(kind, sourceIndex, groupKey)
    if groupKey then
        return tostring(kind) .. "\031" .. tostring(groupKey) .. "\031" .. tostring(sourceIndex)
    end
    return tostring(kind) .. "\031" .. tostring(sourceIndex)
end

function J:GetSelectionContext()
    if not self.selectedKey then return nil end
    return tostring(self.selectedKey) .. "\030" .. tostring(self.difficulty or "MYTHIC")
end

--- Return every boss belonging to the selected boss's instance in the same
--- stable encounter order used by the shared Journal list. Custom bosses with
--- the same dungeon name naturally appear after shipped encounter IDs.
function J:GetOverviewBossKeys(data)
    local keys = {}
    if not data then return keys end
    local dungeonName = C.ResolveDungeonName(data)
    local instanceID = tonumber(data.instanceID)
    for _, bossKey in ipairs(C.SortedBossKeys()) do
        local candidate = BT_BossData[bossKey]
        local sameDungeon = dungeonName and C.ResolveDungeonName(candidate) == dungeonName
        local sameInstance = instanceID and tonumber(candidate.instanceID) == instanceID
        if sameDungeon or (not dungeonName and sameInstance) then
            keys[#keys + 1] = bossKey
        end
    end
    return keys
end

function J:GetSelectionBucket(create)
    local context = self:GetSelectionContext()
    if not context then return nil end
    local bucket = self.selections[context]
    if not bucket and create then
        bucket = {}
        self.selections[context] = bucket
    end
    return bucket
end

function J:IsSelected(selectionId)
    local bucket = self:GetSelectionBucket(false)
    return bucket and bucket[selectionId] and true or false
end

function J:ToggleSelection(selectionId)
    if not selectionId then return end
    local bucket = self:GetSelectionBucket(true)
    bucket[selectionId] = not bucket[selectionId] or nil
    self:RenderBoss(true)
end

function J:ClearSelection()
    local context = self:GetSelectionContext()
    if context then self.selections[context] = nil end
    self:RenderBoss(true)
end

function J:BuildSelectedRecords(data, diff)
    local records = {}
    local bucket = self:GetSelectionBucket(false)
    if not data or not bucket then return records end

    local bullets = C.FilterTLDRBullets(data.tldr, diff, "ALL")
    for _, entry in ipairs(bullets) do
        local id = SelectionID("TLDR", entry.sourceIndex)
        if bucket[id] then
            records[#records + 1] = {
                id = id,
                preview = entry.text,
                chat = (ROLE_CHAT_PREFIX[entry.role] or "") .. entry.text,
            }
        end
    end

    local abilities, abilityIndices = C.FilterAbilities(data.abilities, diff, "ALL")
    for i, ability in ipairs(abilities) do
        local id = SelectionID("ABILITY", abilityIndices[i])
        if bucket[id] then
            local title = BT:Localize(ability.title) or ""
            local description = BT:Localize(ability.description) or ""
            local chat = BT:L("JN_CHAT_ABILITY") .. ": " .. title
            if description ~= "" then chat = chat .. " — " .. description end
            records[#records + 1] = { id = id, preview = title, chat = chat }
        end
    end

    for sourceIndex, tip in ipairs(data.tips or {}) do
        local id = SelectionID("TIP", sourceIndex)
        if bucket[id] then
            local text = type(tip) == "table" and (BT:Localize(tip.text) or "")
                or (BT:Localize(tip) or "")
            if text ~= "" then
                records[#records + 1] = {
                    id = id,
                    preview = text,
                    chat = BT:L("JN_CHAT_TIP") .. ": " .. text,
                }
            end
        end
    end

    for affixIndex, entry in ipairs(D:GetActiveAffixTips(data)) do
        local groupKey = entry.id or entry.name or affixIndex
        local name = entry.name or ("Affix#" .. tostring(entry.id or "?"))
        for sourceIndex, tip in ipairs(entry.tips or {}) do
            local id = SelectionID("AFFIX", sourceIndex, groupKey)
            if bucket[id] then
                local text = BT:Localize(tip) or ""
                if text ~= "" then
                    records[#records + 1] = {
                        id = id,
                        preview = name .. ": " .. text,
                        chat = name .. ": " .. text,
                    }
                end
            end
        end
    end
    return records
end

function J:GetPersonalNote()
    local notes = BT.db and BT.db.journalNotes
    local bossNotes = type(notes) == "table" and notes[self.selectedKey]
    if type(bossNotes) ~= "table" then return "" end
    local note = bossNotes[self.difficulty or "MYTHIC"]
    return type(note) == "string" and note or ""
end

function J:SavePersonalNote(text)
    if not BT.db or not self.selectedKey then return end
    if type(BT.db.journalNotes) ~= "table" then BT.db.journalNotes = {} end
    local notes = BT.db.journalNotes
    local diff = self.difficulty or "MYTHIC"
    text = tostring(text or "")
    if strtrim(text) == "" then
        local bossNotes = notes[self.selectedKey]
        if type(bossNotes) == "table" then
            bossNotes[diff] = nil
            if not next(bossNotes) then notes[self.selectedKey] = nil end
        end
    else
        if type(notes[self.selectedKey]) ~= "table" then notes[self.selectedKey] = {} end
        notes[self.selectedKey][diff] = text
    end
    self:UpdateNotePlaceholder()
end

function J:UpdateNotePlaceholder()
    if not self.noteEdit or not self.notePlaceholder then return end
    self.notePlaceholder:SetShown((self.noteEdit:GetText() or "") == "" and not self.noteEdit:HasFocus())
end

function J:LoadPersonalNote()
    if not self.noteEdit then return end
    local context = self:GetSelectionContext() or ""
    if self.noteContext ~= context then
        self.noteContext = context
        self.loadingNote = true
        self.noteEdit:SetText(self:GetPersonalNote())
        self.noteEdit:SetCursorPosition(0)
        self.loadingNote = false
    end
    self:UpdateNotePlaceholder()
end

-- ─── Window ─────────────────────────────────────────────────────────────────

function J:GetWindow()
    if self.window then return self.window end

    local f = CreateFrame("Frame", "BossTacticsJournalFrame", UIParent, "ButtonFrameTemplate")
    self.window = f
    local screenW = (UIParent and UIParent:GetWidth()) or 1280
    local screenH = (UIParent and UIParent:GetHeight()) or 720
    local maxW = math.max(720, screenW - 60)
    local maxH = math.max(520, screenH - 60)
    local minW = math.min(860, maxW)
    local minH = math.min(560, maxH)
    local db = BT.db or {}
    f:SetSize(Clamp(db.journalWidth, minW, math.min(1320, maxW)),
        Clamp(db.journalHeight, minH, math.min(840, maxH)))
    local pos = db.journalPosition or { point = "CENTER", x = 0, y = 0 }
    f:SetPoint(pos.point or "CENTER", UIParent, pos.point or "CENTER", pos.x or 0, pos.y or 0)
    f:SetToplevel(true)
    f:SetMovable(true)
    f:SetResizable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    if f.SetResizeBounds then
        f:SetResizeBounds(minW, minH, math.min(1320, maxW), math.min(840, maxH))
    elseif f.SetMinResize and f.SetMaxResize then
        f:SetMinResize(minW, minH)
        f:SetMaxResize(math.min(1320, maxW), math.min(840, maxH))
    end

    if f.SetTitle then
        f:SetTitle(BT:L("JN_TITLE"))
    elseif f.TitleText then
        f.TitleText:SetText(BT:L("JN_TITLE"))
    end
    local PORTRAIT_ICON = "Interface\\Icons\\INV_Misc_Book_09"
    if f.SetPortraitToAsset then
        f:SetPortraitToAsset(PORTRAIT_ICON)
    elseif SetPortraitToAsset and f.PortraitContainer and f.PortraitContainer.portrait then
        SetPortraitToAsset(f.PortraitContainer.portrait, PORTRAIT_ICON)
    end

    local drag = CreateFrame("Frame", nil, f)
    drag:SetPoint("TOPLEFT", 8, 0)
    drag:SetPoint("TOPRIGHT", -28, 0)
    drag:SetHeight(24)
    drag:EnableMouse(true)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function() f:StartMoving() end)
    drag:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local point, _, _, x, y = f:GetPoint(1)
        BT.db.journalPosition = { point = point or "CENTER", x = x or 0, y = y or 0 }
    end)

    tinsert(UISpecialFrames, "BossTacticsJournalFrame")

    local content = CreateFrame("Frame", nil, f)
    if f.Inset then
        content:SetPoint("TOPLEFT", f.Inset, "TOPLEFT", 10, -10)
        content:SetPoint("BOTTOMRIGHT", f.Inset, "BOTTOMRIGHT", -10, 10)
    else
        content:SetPoint("TOPLEFT", 14, -64)
        content:SetPoint("BOTTOMRIGHT", -14, 30)
    end
    self.content = content

    -- ── Navigation pane ──
    local nav = CreateFrame("Frame", nil, content)
    self.nav = nav
    self.bossList = C.CreateBossList(nav, 270, function(key)
        J.selectedKey = key
        J.difficulty = C.ResolveContentDifficulty(BT_BossData and BT_BossData[key],
            J.requestedDifficulty or J.difficulty)
        J:UpdateFilterBar()
        J:RenderBoss()
    end)
    self.bossList.frame:SetPoint("TOPLEFT", 0, 0)
    self.bossList.frame:SetPoint("BOTTOMLEFT", 0, 0)

    -- ── Main toolbar: local filters + accessibility ──
    local bar = CreateFrame("Frame", nil, content)
    self.filterBar = bar
    bar:SetHeight(TOOLBAR_H)

    self.roleButtons = {}
    local prevBtn = nil
    for _, role in ipairs(C.ROLE_CYCLE) do
        local btn = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
        local atlas = C.ROLE_ATLAS[role]
        if atlas then
            btn:SetSize(28, 22)
            btn:SetText("|A:" .. atlas .. ":14:14|a")
        else
            btn:SetSize(44, 22)
            btn:SetText(BT:L(C.ROLE_LABEL_KEYS[role]))
        end
        if prevBtn then
            btn:SetPoint("LEFT", prevBtn, "RIGHT", 3, 0)
        else
            btn:SetPoint("LEFT", 0, 0)
        end
        btn:SetScript("OnClick", function()
            J.roleFilter = role
            J:UpdateFilterBar()
            J:RenderBoss()
        end)
        self.roleButtons[role] = btn
        prevBtn = btn
    end

    local diffBtn = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
    self.diffBtn = diffBtn
    diffBtn:SetSize(96, 22)
    diffBtn:SetPoint("LEFT", prevBtn, "RIGHT", 10, 0)
    diffBtn:SetScript("OnClick", function()
        local selectedData = J.selectedKey and BT_BossData and BT_BossData[J.selectedKey]
        if not C.ShouldShowDifficultySelector(selectedData) then return end
        local idx = 1
        for i, v in ipairs(DIFF_CYCLE) do
            if v == (J.requestedDifficulty or J.difficulty) then idx = i break end
        end
        J.requestedDifficulty = DIFF_CYCLE[(idx % #DIFF_CYCLE) + 1]
        J.difficulty = C.ResolveContentDifficulty(selectedData, J.requestedDifficulty)
        J:UpdateFilterBar()
        J:RenderBoss()
        local MP = BT.MiniPanel
        local panelBoss = MP and MP:GetActiveDisplay()
        if MP and MP:IsShown() and panelBoss == J.selectedKey then
            MP:SetManualDifficulty(J.difficulty)
        end
    end)
    diffBtn:SetScript("OnEnter", function(button)
        GameTooltip:SetOwner(button, "ANCHOR_TOP")
        GameTooltip:SetText(BT:L("TOOLTIP_DIFFICULTY_FILTER"))
        GameTooltip:Show()
    end)
    diffBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local fontPlus = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
    self.fontPlusBtn = fontPlus
    fontPlus:SetSize(38, 22)
    fontPlus:SetPoint("RIGHT", 0, 0)
    fontPlus:SetText("A+")
    fontPlus:SetScript("OnClick", function() J:AdjustFontScale(0.1) end)

    local fontValue = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
    self.fontValueBtn = fontValue
    fontValue:SetSize(62, 22)
    fontValue:SetPoint("RIGHT", fontPlus, "LEFT", -3, 0)
    fontValue:SetScript("OnClick", function()
        J:SetFontScale(C.DEFAULT_WORKSPACE_FONT_SCALE or 1.2)
    end)

    local fontMinus = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
    self.fontMinusBtn = fontMinus
    fontMinus:SetSize(38, 22)
    fontMinus:SetPoint("RIGHT", fontValue, "LEFT", -3, 0)
    fontMinus:SetText("A-")
    fontMinus:SetScript("OnClick", function() J:AdjustFontScale(-0.1) end)

    -- ── View tabs + compact briefing drawer toggle ──
    local bar2 = CreateFrame("Frame", nil, content)
    self.viewBar = bar2
    bar2:SetHeight(24)

    self.viewButtons = {}
    self.viewButtonOrder = {}
    local prevTab = nil
    for _, view in ipairs(VIEWS) do
        local btn = CreateFrame("Button", nil, bar2, "UIPanelButtonTemplate")
        btn:SetSize(view.key == "ABILITIES" and 104 or 92, 22)
        btn:SetText(BT:L(view.labelKey))
        if prevTab then
            btn:SetPoint("LEFT", prevTab, "RIGHT", 3, 0)
        else
            btn:SetPoint("LEFT", 0, 0)
        end
        btn:SetScript("OnClick", function()
            J.view = view.key
            J:UpdateFilterBar()
            J:RenderBoss()
        end)
        self.viewButtons[view.key] = btn
        self.viewButtonOrder[#self.viewButtonOrder + 1] = btn
        prevTab = btn
    end

    local briefingToggle = CreateFrame("Button", nil, bar2, "UIPanelButtonTemplate")
    self.briefingToggleBtn = briefingToggle
    briefingToggle:SetSize(112, 22)
    briefingToggle:SetPoint("RIGHT", 0, 0)
    briefingToggle:SetText(BT:L("JN_BRIEFING"))
    briefingToggle:SetScript("OnClick", function()
        J.briefingOverlay = not J.briefingOverlay
        J:Layout()
    end)

    -- ── Scrollable reading pane ──
    local scroll = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
    self.scroll = scroll

    local body = CreateFrame("Frame", nil, scroll)
    self.body = body
    body:SetSize(420, 10)
    scroll:SetScrollChild(body)

    -- Static header elements (positioned once, content set per render)
    self.titleFS = body:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.titleFS:SetPoint("TOPLEFT", 0, 0)
    self.titleFS:SetJustifyH("LEFT")
    self.titleFS:SetWordWrap(true)

    self.subtitleFS = body:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.subtitleFS:SetPoint("TOPLEFT", self.titleFS, "BOTTOMLEFT", 0, -3)
    self.subtitleFS:SetJustifyH("LEFT")
    self.subtitleFS:SetWordWrap(false)

    -- Pools — render path only acquires/releases
    self.headerPool = CreateFontStringPool(body, "ARTWORK", 0, "GameFontNormalLarge")
    self.linePool   = CreateFontStringPool(body, "ARTWORK", 0, "GameFontHighlight")
    self.selectLinePool = CreateFramePool("Button", body)
    self.cardPool   = CreateFramePool("Frame", body)
    self.overviewBossPool = CreateFramePool("Button", body)

    -- Section share buttons (anchored to their pooled section header per render)
    local function MakeShareButton(labelKey, handler)
        local btn = CreateFrame("Button", nil, body, "UIPanelButtonTemplate")
        btn:SetSize(110, 20)
        btn:SetText(BT:L(labelKey))
        btn:SetScript("OnClick", handler)
        btn:Hide()
        return btn
    end
    self.shareTldrBtn = MakeShareButton("BTN_SHARE_TLDR", function() J:ShareTLDR() end)
    self.shareTipsBtn = MakeShareButton("BTN_SHARE_TIPS", function() J:ShareTips() end)

    -- ── Briefing / Selected foundation ──
    local briefing = CreateFrame("Frame", nil, content, "BackdropTemplate")
    self.briefing = briefing
    briefing:SetBackdrop(SIDEBAR_BACKDROP)
    briefing:SetBackdropColor(0.025, 0.025, 0.035, 0.96)
    briefing:SetBackdropBorderColor(0.32, 0.32, 0.38, 0.9)

    self.briefingTitle = briefing:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.briefingTitle:SetPoint("TOPLEFT", 14, -14)
    self.briefingTitle:SetPoint("RIGHT", -158, 0)
    self.briefingTitle:SetText(BT:L("JN_BRIEFING"))

    self.openStudioBtn = CreateFrame("Button", nil, briefing, "UIPanelButtonTemplate")
    self.openStudioBtn:SetPoint("TOPRIGHT", -28, -8)
    self.openStudioBtn:SetSize(124, 22)
    self.openStudioBtn:SetText(BT:L("BTN_RAID_STUDIO"))
    self.openStudioBtn:SetScript("OnClick", function()
        BT:OpenRaidStudio(J.selectedKey, J.difficulty)
    end)

    self.briefingClose = CreateFrame("Button", nil, briefing, "UIPanelCloseButton")
    self.briefingClose:SetPoint("TOPRIGHT", 2, 2)
    self.briefingClose:SetScript("OnClick", function()
        J.briefingOverlay = false
        J:Layout()
    end)

    self.briefingBoss = briefing:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.briefingBoss:SetPoint("TOPLEFT", self.briefingTitle, "BOTTOMLEFT", 0, -14)
    self.briefingBoss:SetPoint("RIGHT", -14, 0)
    self.briefingBoss:SetHeight(36)
    self.briefingBoss:SetJustifyH("LEFT")
    self.briefingBoss:SetJustifyV("TOP")
    self.briefingBoss:SetWordWrap(true)

    self.briefingSummary = briefing:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.briefingSummary:SetPoint("TOPLEFT", self.briefingBoss, "BOTTOMLEFT", 0, -12)
    self.briefingSummary:SetPoint("RIGHT", -14, 0)
    self.briefingSummary:SetHeight(48)
    self.briefingSummary:SetJustifyH("LEFT")
    self.briefingSummary:SetJustifyV("TOP")
    self.briefingSummary:SetWordWrap(true)

    self.briefingSelected = briefing:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.briefingSelected:SetPoint("TOPLEFT", self.briefingSummary, "BOTTOMLEFT", 0, -8)
    self.briefingSelected:SetText(string.format(BT:L("JN_SELECTED_COUNT"), 0))

    local selectedScroll = CreateFrame("ScrollFrame", nil, briefing, "UIPanelScrollFrameTemplate")
    self.selectedScroll = selectedScroll
    selectedScroll:SetPoint("TOPLEFT", self.briefingSelected, "BOTTOMLEFT", 0, -6)
    selectedScroll:SetPoint("BOTTOMRIGHT", briefing, "BOTTOMRIGHT", -28, 178)

    local selectedBody = CreateFrame("Frame", nil, selectedScroll)
    self.selectedBody = selectedBody
    selectedBody:SetSize(220, 10)
    selectedScroll:SetScrollChild(selectedBody)
    self.selectedPreviewPool = CreateFontStringPool(selectedBody, "ARTWORK", 0, "GameFontHighlightSmall")

    self.briefingEmpty = selectedBody:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    self.briefingEmpty:SetPoint("TOPLEFT", 0, 0)
    self.briefingEmpty:SetJustifyH("LEFT")
    self.briefingEmpty:SetJustifyV("TOP")
    self.briefingEmpty:SetWordWrap(true)
    self.briefingEmpty:SetNonSpaceWrap(true)
    self.briefingEmpty:SetText(BT:L("JN_BRIEFING_EMPTY"))

    self.noteLabel = briefing:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.noteLabel:SetPoint("BOTTOMLEFT", briefing, "BOTTOMLEFT", 14, 154)
    self.noteLabel:SetText(BT:L("JN_PERSONAL_NOTES"))

    local noteInset = CreateFrame("Frame", nil, briefing, "InsetFrameTemplate")
    self.noteInset = noteInset
    noteInset:SetPoint("BOTTOMLEFT", briefing, "BOTTOMLEFT", 14, 48)
    noteInset:SetPoint("BOTTOMRIGHT", briefing, "BOTTOMRIGHT", -14, 48)
    noteInset:SetHeight(96)

    local noteScroll = CreateFrame("ScrollFrame", nil, noteInset, "UIPanelScrollFrameTemplate")
    self.noteScroll = noteScroll
    noteScroll:SetPoint("TOPLEFT", 6, -6)
    noteScroll:SetPoint("BOTTOMRIGHT", -24, 6)

    local noteEdit = CreateFrame("EditBox", nil, noteScroll)
    self.noteEdit = noteEdit
    noteEdit:SetMultiLine(true)
    noteEdit:SetAutoFocus(false)
    noteEdit:SetMaxLetters(2000)
    noteEdit:SetFontObject(GameFontHighlightSmall)
    noteEdit:SetWidth(210)
    if noteEdit.SetSpacing then noteEdit:SetSpacing(2) end
    noteEdit:SetScript("OnEscapePressed", function(edit) edit:ClearFocus() end)
    noteEdit:SetScript("OnEditFocusGained", function() J:UpdateNotePlaceholder() end)
    noteEdit:SetScript("OnEditFocusLost", function(edit)
        if not J.loadingNote then J:SavePersonalNote(edit:GetText()) end
        J:UpdateNotePlaceholder()
    end)
    noteEdit:SetScript("OnTextChanged", function(edit, userInput)
        if userInput and not J.loadingNote then J:SavePersonalNote(edit:GetText()) end
    end)
    noteScroll:SetScrollChild(noteEdit)
    noteScroll:EnableMouse(true)
    noteScroll:SetScript("OnMouseDown", function() noteEdit:SetFocus() end)

    self.notePlaceholder = noteInset:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    self.notePlaceholder:SetPoint("TOPLEFT", 9, -9)
    self.notePlaceholder:SetPoint("RIGHT", -28, 0)
    self.notePlaceholder:SetJustifyH("LEFT")
    self.notePlaceholder:SetJustifyV("TOP")
    self.notePlaceholder:SetWordWrap(true)
    self.notePlaceholder:SetText(BT:L("JN_NOTE_PLACEHOLDER"))

    self.shareSelectedBtn = CreateFrame("Button", nil, briefing, "UIPanelButtonTemplate")
    self.shareSelectedBtn:SetPoint("BOTTOMLEFT", 14, 14)
    self.shareSelectedBtn:SetSize(140, 24)
    self.shareSelectedBtn:SetText(BT:L("BTN_SHARE_SELECTED"))
    self.shareSelectedBtn:SetScript("OnClick", function() J:ShareSelected() end)

    self.clearSelectedBtn = CreateFrame("Button", nil, briefing, "UIPanelButtonTemplate")
    self.clearSelectedBtn:SetPoint("LEFT", self.shareSelectedBtn, "RIGHT", 8, 0)
    self.clearSelectedBtn:SetSize(80, 24)
    self.clearSelectedBtn:SetText(BT:L("BTN_CLEAR"))
    self.clearSelectedBtn:SetScript("OnClick", function() J:ClearSelection() end)

    -- ── Footer actions ──
    local footer = CreateFrame("Frame", nil, content)
    self.footer = footer
    footer:SetHeight(FOOTER_H)

    local showBtn = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
    self.showOnPanelBtn = showBtn
    showBtn:SetSize(140, 24)
    showBtn:SetPoint("LEFT", 0, 0)
    showBtn:SetText(BT:L("BTN_SHOW_ON_PANEL"))
    showBtn:SetScript("OnClick", function()
        local MP = BT.MiniPanel
        local data = J.selectedKey and BT_BossData and BT_BossData[J.selectedKey]
        if not data then return end
        if MP.testMode then MP:ExitTestMode(true) end

        if J.view == "TRASH" then
            local dungeon = C.ResolveDungeonName(data)
            local TP = BT.TrashPanel
            if not (dungeon and BT_TrashData and BT_TrashData[dungeon] and TP) then return end
            TP:ShowDungeon(dungeon, J.difficulty)
            if TP.frame then
                if TP.frame.SetToplevel then TP.frame:SetToplevel(true) end
                if TP.frame.Raise then TP.frame:Raise() end
            end
            return
        end

        MP:ShowBoss(J.selectedKey, J.difficulty)
        if MP.frame then
            if MP.frame.SetToplevel then MP.frame:SetToplevel(true) end
            if MP.frame.Raise then MP.frame:Raise() end
        end
    end)

    local editBtn = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
    editBtn:SetSize(120, 24)
    editBtn:SetPoint("LEFT", showBtn, "RIGHT", 8, 0)
    editBtn:SetText(BT:L("BTN_EDIT_BOSS"))
    editBtn:SetScript("OnClick", function() BT:OpenEditor(J.selectedKey) end)

    local optionsBtn = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
    optionsBtn:SetSize(100, 24)
    optionsBtn:SetPoint("LEFT", editBtn, "RIGHT", 8, 0)
    optionsBtn:SetText(BT:L("BTN_OPTIONS"))
    optionsBtn:SetScript("OnClick", function() BT:OpenSettings() end)

    local closeBtn = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
    closeBtn:SetSize(90, 24)
    closeBtn:SetPoint("RIGHT", 0, 0)
    closeBtn:SetText(BT:L("BTN_CLOSE"))
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    self.navSeparator = content:CreateTexture(nil, "BACKGROUND")
    self.navSeparator:SetColorTexture(0.32, 0.32, 0.36, 0.5)
    self.briefingSeparator = content:CreateTexture(nil, "BACKGROUND")
    self.briefingSeparator:SetColorTexture(0.32, 0.32, 0.36, 0.5)

    -- Bottom-right resize grip.
    local grip = CreateFrame("Button", nil, f)
    self.resizeGrip = grip
    grip:SetSize(24, 24)
    grip:SetPoint("BOTTOMRIGHT", -5, 5)
    local gripTex = grip:CreateTexture(nil, "ARTWORK")
    gripTex:SetAllPoints()
    gripTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then f:StartSizing("BOTTOMRIGHT") end
    end)
    grip:SetScript("OnMouseUp", function()
        f:StopMovingOrSizing()
        BT.db.journalWidth = math.floor(f:GetWidth() + 0.5)
        BT.db.journalHeight = math.floor(f:GetHeight() + 0.5)
        J:Layout()
    end)

    f:SetScript("OnShow", function()
        J:ApplyAccessibilityFonts()
        J:Layout()
        J:RefreshAll()
    end)
    f:SetScript("OnSizeChanged", function()
        if J.content then J:ScheduleLayout() end
    end)
    if Theme then
        Theme:StyleWindow(f)
        Theme:StyleAddonTree(f)
        Theme:StyleTitle(self.briefingTitle)
    end
    f:Hide()
    return f
end

function J:GetFontScale()
    return Clamp((BT.db and BT.db.journalFontScale)
        or C.DEFAULT_WORKSPACE_FONT_SCALE or 1.2, 0.8, 1.6)
end

local function CopyScaledFont(target, source, scale)
    if not target or not source then return end
    local path, size, flags = source:GetFont()
    if path and size then
        target:SetFont(C:NormalizeFontPath(path), math.max(8, math.floor(size * scale + 0.5)), flags or "")
    end
    if source.GetTextColor and target.SetTextColor then
        target:SetTextColor(source:GetTextColor())
    end
    if source.GetShadowColor and target.SetShadowColor then
        target:SetShadowColor(source:GetShadowColor())
    end
    if source.GetShadowOffset and target.SetShadowOffset then
        target:SetShadowOffset(source:GetShadowOffset())
    end
end

function J:EnsureJournalFonts()
    if self.fonts then return end
    self.fonts = {}
    for key, def in pairs(FONT_DEFS) do
        self.fonts[key] = _G[def.name] or CreateFont(def.name)
    end
end

function J:ApplyAccessibilityFonts()
    if not self.window then return end
    self:EnsureJournalFonts()
    local scale = self:GetFontScale()
    for key, def in pairs(FONT_DEFS) do
        CopyScaledFont(self.fonts[key], def.base(), scale)
    end

    self.titleFS:SetFontObject(self.fonts.title)
    self.subtitleFS:SetFontObject(self.fonts.subtitle)
    self.briefingTitle:SetFontObject(self.fonts.section)
    self.briefingBoss:SetFontObject(self.fonts.body)
    self.briefingBoss:SetHeight(math.floor(36 * scale + 0.5))
    self.briefingSummary:SetFontObject(self.fonts.small)
    self.briefingSummary:SetHeight(math.floor(48 * scale + 0.5))
    self.briefingSelected:SetFontObject(self.fonts.body)
    self.briefingEmpty:SetFontObject(self.fonts.small)
    self.noteLabel:SetFontObject(self.fonts.body)
    self.noteEdit:SetFontObject(self.fonts.small)
    self.notePlaceholder:SetFontObject(self.fonts.small)
    self.bossList:SetFontObjects(self.fonts.listSection, self.fonts.listDungeon,
        self.fonts.listRow, math.floor(22 * scale + 0.5))
    self.fontValueBtn:SetText(string.format("%d%%", math.floor(scale * 100 + 0.5)))
end

function J:SetFontScale(value)
    value = Clamp(math.floor((tonumber(value) or 1) * 10 + 0.5) / 10, 0.8, 1.6)
    BT.db.journalFontScale = value
    self:ApplyAccessibilityFonts()
    self:RenderBoss(true)
end

function J:AdjustFontScale(delta)
    self:SetFontScale(self:GetFontScale() + (tonumber(delta) or 0))
end

function J:ScheduleLayout()
    self.layoutToken = (self.layoutToken or 0) + 1
    local token = self.layoutToken
    C_Timer.After(0.03, function()
        if J.window and token == J.layoutToken then
            J:Layout()
        end
    end)
end

function J:Layout()
    if not self.window or not self.content or self.layouting then return end
    self.layouting = true

    local contentW = self.content:GetWidth()
    if not contentW or contentW < 400 then
        contentW = math.max(760, self.window:GetWidth() - 50)
    end
    local navW = Clamp(math.floor(contentW * 0.25 + 0.5), 260, 330)
    local mainX = navW + PANE_GAP
    local wide = contentW >= WIDE_THRESHOLD
    local sidebarW = Clamp(math.floor(contentW * 0.25 + 0.5), 270, 330)
    local mainRight = wide and (sidebarW + PANE_GAP) or 0
    local mainWidth = math.max(240, contentW - mainX - mainRight)

    self.briefingToggleBtn:SetShown(not wide)
    local reserve = 0
    if Theme then
        if not wide then
            local toggleW = Theme:FitButton(self.briefingToggleBtn, { compact = true })
            reserve = toggleW + Theme.spacing.sm
        end
        Theme:LayoutButtonBar(self.viewBar, self.viewButtonOrder,
            math.max(160, mainWidth - reserve), { buttonOptions = { compact = true } })
    end
    local viewBarH = math.max(24, self.viewBar:GetHeight() or 24)
    local headerRowsH = TOOLBAR_H + 4 + viewBarH + 4

    self.nav:ClearAllPoints()
    self.nav:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, 0)
    self.nav:SetPoint("BOTTOMLEFT", self.content, "BOTTOMLEFT", 0, 0)
    self.nav:SetWidth(navW)
    self.bossList:SetWidth(navW)

    self.filterBar:ClearAllPoints()
    self.filterBar:SetPoint("TOPLEFT", self.content, "TOPLEFT", mainX, 0)
    self.filterBar:SetPoint("TOPRIGHT", self.content, "TOPRIGHT", -mainRight, 0)

    self.viewBar:ClearAllPoints()
    self.viewBar:SetPoint("TOPLEFT", self.content, "TOPLEFT", mainX, -28)
    self.viewBar:SetPoint("TOPRIGHT", self.content, "TOPRIGHT", -mainRight, -28)

    self.footer:ClearAllPoints()
    self.footer:SetPoint("BOTTOMLEFT", self.content, "BOTTOMLEFT", mainX, 0)
    self.footer:SetPoint("BOTTOMRIGHT", self.content, "BOTTOMRIGHT", -mainRight, 0)

    self.scroll:ClearAllPoints()
    self.scroll:SetPoint("TOPLEFT", self.content, "TOPLEFT", mainX, -headerRowsH)
    self.scroll:SetPoint("BOTTOMRIGHT", self.content, "BOTTOMRIGHT", -mainRight - 24, FOOTER_H + 4)

    self.navSeparator:ClearAllPoints()
    self.navSeparator:SetPoint("TOPLEFT", self.content, "TOPLEFT", navW + math.floor(PANE_GAP / 2), 0)
    self.navSeparator:SetPoint("BOTTOMLEFT", self.content, "BOTTOMLEFT", navW + math.floor(PANE_GAP / 2), 0)
    self.navSeparator:SetWidth(1)

    self.briefing:ClearAllPoints()
    self.briefingSeparator:ClearAllPoints()
    if wide then
        self.briefingOverlay = false
        self.briefing:SetPoint("TOPRIGHT", self.content, "TOPRIGHT", 0, -headerRowsH)
        self.briefing:SetPoint("BOTTOMRIGHT", self.content, "BOTTOMRIGHT", 0, FOOTER_H + 4)
        self.briefing:SetWidth(sidebarW)
        self.briefing:SetFrameLevel(self.content:GetFrameLevel() + 2)
        self.briefing:Show()
        self.briefingClose:Hide()
        self.briefingToggleBtn:Hide()
        self.briefingSeparator:SetPoint("TOPRIGHT", self.content, "TOPRIGHT",
            -sidebarW - math.floor(PANE_GAP / 2), -headerRowsH)
        self.briefingSeparator:SetPoint("BOTTOMRIGHT", self.content, "BOTTOMRIGHT",
            -sidebarW - math.floor(PANE_GAP / 2), FOOTER_H + 4)
        self.briefingSeparator:SetWidth(1)
        self.briefingSeparator:Show()
    else
        self.briefingToggleBtn:Show()
        self.briefingSeparator:Hide()
        if self.briefingOverlay then
            self.briefing:SetPoint("TOPRIGHT", self.content, "TOPRIGHT", 0, -headerRowsH)
            self.briefing:SetPoint("BOTTOMRIGHT", self.content, "BOTTOMRIGHT", 0, FOOTER_H + 4)
            self.briefing:SetWidth(math.min(340, math.max(270, contentW - mainX - 20)))
            self.briefing:SetFrameLevel(self.content:GetFrameLevel() + 10)
            self.briefingClose:Show()
            self.briefing:Show()
        else
            self.briefing:Hide()
        end
    end

    if BT.db and self.window:IsShown() then
        BT.db.journalWidth = math.floor(self.window:GetWidth() + 0.5)
        BT.db.journalHeight = math.floor(self.window:GetHeight() + 0.5)
    end
    self.noteEdit:SetWidth(math.max(180, self.noteScroll:GetWidth() - 8))
    self.layouting = false
    self:RenderBoss(true)
end

local function StringHeight(fs, fallback)
    local h = fs:GetStringHeight()
    if not h or h < 1 then h = fallback end
    return h
end

function J:RefreshBriefingSidebar(data, diff)
    if not self.briefingBoss then return end
    self.selectedPreviewPool:ReleaseAll()
    if not data or not self.selectedKey then
        self.briefingBoss:SetText("")
        self.briefingSummary:SetText("")
        self.briefingSelected:SetText(string.format(BT:L("JN_SELECTED_COUNT"), 0))
        self.briefingEmpty:Show()
        self.shareSelectedBtn:Disable()
        self.clearSelectedBtn:Disable()
        self.selectedBody:SetHeight(10)
        self:LoadPersonalNote()
        return
    end
    local bullets = C.FilterTLDRBullets(data.tldr, diff, self.roleFilter)
    local abilities = C.FilterAbilities(data.abilities, diff, self.roleFilter)
    local tipCount = data.tips and #data.tips or 0
    local selected = self:BuildSelectedRecords(data, diff)
    self.briefingBoss:SetText(self.selectedKey)
    self.briefingSummary:SetText(string.format(BT:L("JN_BRIEFING_SUMMARY"),
        #bullets, #abilities, tipCount))
    self.briefingSelected:SetText(string.format(BT:L("JN_SELECTED_COUNT"), #selected))

    local width = self.selectedScroll:GetWidth() - 8
    if not width or width < 100 then width = 220 end
    self.selectedBody:SetWidth(width)
    self.briefingEmpty:SetWidth(width)
    if #selected == 0 then
        self.briefingEmpty:SetText(BT:L("JN_BRIEFING_EMPTY"))
        self.briefingEmpty:Show()
        self.selectedBody:SetHeight(math.max(60, StringHeight(self.briefingEmpty, 42)))
        self.shareSelectedBtn:Disable()
        self.clearSelectedBtn:Disable()
    else
        self.briefingEmpty:Hide()
        local y = 0
        local gap = math.max(3, math.floor(4 * self:GetFontScale() + 0.5))
        for _, record in ipairs(selected) do
            local line = self.selectedPreviewPool:Acquire()
            line:SetFontObject(self.fonts and self.fonts.small or GameFontHighlightSmall)
            line:SetPoint("TOPLEFT", self.selectedBody, "TOPLEFT", 0, y)
            line:SetWidth(width)
            line:SetJustifyH("LEFT")
            line:SetJustifyV("TOP")
            line:SetWordWrap(true)
            line:SetNonSpaceWrap(true)
            line:SetText("|cff66ccff•|r " .. record.preview)
            line:Show()
            y = y - StringHeight(line, 12 * self:GetFontScale()) - gap
        end
        self.selectedBody:SetHeight(math.max(-y, 10))
        self.shareSelectedBtn:Enable()
        self.clearSelectedBtn:Enable()
    end
    self.selectedScroll:SetVerticalScroll(0)
    self:LoadPersonalNote()
end

function J:UpdateFilterBar()
    local data = self.selectedKey and BT_BossData and BT_BossData[self.selectedKey]
    self.difficulty = C.ResolveContentDifficulty(data,
        self.requestedDifficulty or self.difficulty or DefaultDifficulty())
    for role, btn in pairs(self.roleButtons) do
        if role == self.roleFilter then
            btn:LockHighlight()
        else
            btn:UnlockHighlight()
        end
        if Theme then Theme:SetSelected(btn, role == self.roleFilter) end
    end
    for viewKey, btn in pairs(self.viewButtons) do
        if viewKey == self.view then
            btn:LockHighlight()
        else
            btn:UnlockHighlight()
        end
        if Theme then Theme:SetSelected(btn, viewKey == self.view) end
    end
    local diff = self.difficulty or "MYTHIC"
    local labelKey = C.DIFF_LABEL_KEYS[diff]
    local label = labelKey and BT:L(labelKey) or diff
    local color = C.DIFF_COLORS[diff]
    self.diffBtn:SetText(color and (color .. label .. "|r") or label)
    self.diffBtn:SetShown(C.ShouldShowDifficultySelector(data))
    if Theme and self.diffBtn:IsShown() then Theme:FitButton(self.diffBtn, { compact = true }) end
end

function J:RefreshAll()
    if not self.window then return end
    if not self.selectedKey or not (BT_BossData and BT_BossData[self.selectedKey]) then
        self.selectedKey = C.SortedBossKeys()[1]   -- no empty states
    end
    self.bossList.selectedKey = self.selectedKey
    self.bossList:Refresh()
    self:UpdateFilterBar()
    self:RenderBoss()
end

-- ─── Render ─────────────────────────────────────────────────────────────────

function J:RenderBoss(preserveScroll)
    if not self.window then return end
    local previousScroll = preserveScroll and self.scroll:GetVerticalScroll() or 0
    local body = self.body
    local W = self.scroll:GetWidth() - 8
    if not W or W < 100 then W = 420 end
    body:SetWidth(W)

    self.headerPool:ReleaseAll()
    self.linePool:ReleaseAll()
    self.selectLinePool:ReleaseAll()
    self.cardPool:ReleaseAll()
    self.overviewBossPool:ReleaseAll()
    self.shareTldrBtn:Hide()
    self.shareTipsBtn:Hide()

    local key = self.selectedKey
    local data = key and BT_BossData and BT_BossData[key]
    if not data then
        self.titleFS:SetText("")
        self.subtitleFS:SetText("")
        body:SetHeight(10)
        self:RefreshBriefingSidebar(nil)
        return
    end

    local scale = self:GetFontScale()
    local sectionGap = math.floor(SECTION_GAP * scale + 0.5)
    local itemGap = math.floor(ITEM_GAP * scale + 0.5)
    local view = self.view or "TLDR"
    local overviewKeys = view == "OVERVIEW" and self:GetOverviewBossKeys(data) or nil

    -- Header
    self.titleFS:SetWidth(W)
    local dn = C.ResolveDungeonName(data)
    self.titleFS:SetText((view == "OVERVIEW" or view == "TRASH") and (dn or key) or key)
    local segs = {}
    local diff = C.ResolveContentDifficulty(data, self.difficulty or DefaultDifficulty())
    self.difficulty = diff
    local labelKey = C.DIFF_LABEL_KEYS[diff]
    local dLabel = labelKey and BT:L(labelKey) or diff
    local dColor = C.DIFF_COLORS[diff]
    if view == "OVERVIEW" or view == "TRASH" then
        segs[#segs + 1] = BT:L(data.isRaid and "ED_TYPE_RAID" or "ED_TYPE_DUNGEON")
        local season = C.ResolveSeason(data)
        local seasonKey = season == 2 and "ED_SEASON_2"
            or (season == 1 and "ED_SEASON_1" or "ED_SEASON_OTHER")
        segs[#segs + 1] = BT:L(seasonKey)
        segs[#segs + 1] = dColor and (dColor .. dLabel .. "|r") or dLabel
        segs[#segs + 1] = string.format(BT:L("JN_BOSS_COUNT"), #(overviewKeys or {}))
    else
        if dn then segs[#segs + 1] = dn end
        segs[#segs + 1] = dColor and (dColor .. dLabel .. "|r") or dLabel
    end
    self.subtitleFS:SetWidth(W)
    self.subtitleFS:SetText(table.concat(segs, " |cff666666\226\128\162|r "))

    local y = -(StringHeight(self.titleFS, 16 * scale) + 3
        + StringHeight(self.subtitleFS, 10 * scale) + sectionGap)

    local function PlaceSectionHeader(text, shareBtn)
        local hdr = self.headerPool:Acquire()
        hdr:SetFontObject(self.fonts and self.fonts.section or GameFontNormalLarge)
        hdr:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
        hdr:SetWidth(W - (shareBtn and 120 or 0))
        hdr:SetJustifyH("LEFT")
        hdr:SetWordWrap(false)
        hdr:SetText(text)
        hdr:Show()
        if shareBtn then
            shareBtn:ClearAllPoints()
            shareBtn:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, y + 2)
            shareBtn:Show()
        end
        y = y - StringHeight(hdr, 16 * scale) - math.floor(8 * scale + 0.5)
    end

    local function PlaceSubHeader(text)
        local hdr = self.headerPool:Acquire()
        hdr:SetFontObject(self.fonts and self.fonts.body or GameFontNormal)
        hdr:SetPoint("TOPLEFT", body, "TOPLEFT", 26, y)
        hdr:SetWidth(W - 26)
        hdr:SetJustifyH("LEFT")
        hdr:SetWordWrap(false)
        hdr:SetText("|cff66ccff" .. text .. "|r")
        hdr:Show()
        y = y - StringHeight(hdr, 13 * scale) - math.floor(5 * scale + 0.5)
    end

    local function PlaceLine(text, indent, fontObject)
        indent = indent or 0
        local fs = self.linePool:Acquire()
        fs:SetFontObject(fontObject or (self.fonts and self.fonts.body or GameFontHighlight))
        fs:SetWidth(W - indent)
        fs:SetJustifyH("LEFT")
        fs:SetJustifyV("TOP")
        fs:SetWordWrap(true)
        fs:SetNonSpaceWrap(true)
        fs:SetText(text)
        fs:SetPoint("TOPLEFT", body, "TOPLEFT", indent, y)
        fs:Show()
        y = y - StringHeight(fs, 12 * scale) - itemGap
    end

    local function PlaceSelectableLine(text, selectionId)
        local row = self.selectLinePool:Acquire()
        if not row.label then
            row.box = row:CreateTexture(nil, "ARTWORK")
            row.box:SetPoint("TOPLEFT", 0, 1)
            row.box:SetSize(20, 20)
            row.box:SetAtlas("checkbox-minimal")
            row.mark = row:CreateTexture(nil, "OVERLAY")
            row.mark:SetPoint("CENTER", row.box, "CENTER", 0, 0)
            row.mark:SetSize(14, 14)
            row.mark:SetAtlas("checkmark-minimal")
            row.label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            row.label:SetPoint("TOPLEFT", 26, 0)
            row.label:SetJustifyH("LEFT")
            row.label:SetJustifyV("TOP")
            row.label:SetWordWrap(true)
            row.label:SetNonSpaceWrap(true)
            local highlight = row:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints()
            highlight:SetColorTexture(0.894, 0.776, 0.459, 0.10)
            row:SetScript("OnClick", function(button)
                J:ToggleSelection(button._selectionId)
            end)
        end
        row._selectionId = selectionId
        row.mark:SetShown(self:IsSelected(selectionId))
        row.label:SetFontObject(self.fonts and self.fonts.body or GameFontHighlight)
        row.label:SetWidth(W - 26)
        row.label:SetText(text)
        local rowH = math.max(20, StringHeight(row.label, 12 * scale))
        row:SetSize(W, rowH)
        row:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
        row:Show()
        y = y - rowH - itemGap
    end

    local function PlaceOverviewBossHeader(bossKey, bossIndex)
        local button = self.overviewBossPool:Acquire()
        if not button.label then
            button.label = button:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
            button.label:SetPoint("LEFT", 4, 0)
            button.label:SetPoint("RIGHT", -28, 0)
            button.label:SetJustifyH("LEFT")
            button.label:SetWordWrap(false)
            button.arrow = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            button.arrow:SetPoint("RIGHT", -6, 0)
            button.arrow:SetText("›")
            local highlight = button:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints()
            highlight:SetColorTexture(0.894, 0.776, 0.459, 0.12)
            button:SetScript("OnClick", function(clicked)
                local selectedBoss = clicked._bossKey
                if not selectedBoss then return end
                J.selectedKey = selectedBoss
                J.bossList:SetSelected(selectedBoss)
                J.view = "TLDR"
                J:UpdateFilterBar()
                J:RenderBoss()
            end)
            button:SetScript("OnEnter", function(clicked)
                GameTooltip:SetOwner(clicked, "ANCHOR_RIGHT")
                GameTooltip:SetText(BT:L("JN_TOOLTIP_OPEN_BOSS"), 1, 1, 1)
                GameTooltip:Show()
            end)
            button:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end
        button._bossKey = bossKey
        button.label:SetFontObject(self.fonts and self.fonts.section or GameFontNormalLarge)
        button.arrow:SetFontObject(self.fonts and self.fonts.body or GameFontHighlight)
        button.label:SetText(string.format("%d. %s", bossIndex, bossKey))
        if bossKey == key then
            button.label:SetTextColor(0.4, 0.8, 1, 1)
        else
            button.label:SetTextColor(1, 0.82, 0, 1)
        end
        local height = math.max(22, StringHeight(button.label, 16 * scale) + 4)
        button:SetSize(W, height)
        button:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
        button:Show()
        y = y - height - math.floor(6 * scale + 0.5)
    end

    -- Curated dungeon trash priorities. The selected boss supplies the stable
    -- dungeon key, so every boss in an instance opens the same Trash page.
    if view == "TRASH" then
        local trash = dn and BT_TrashData and BT_TrashData[dn]
        if data.isRaid then
            PlaceSectionHeader(BT:L("JN_SEC_TRASH"))
            PlaceLine(BT:L("JN_TRASH_NOT_APPLICABLE"), 18,
                self.fonts and self.fonts.small or GameFontHighlightSmall)
        elseif not trash then
            PlaceSectionHeader(BT:L("JN_SEC_TRASH"))
            PlaceLine(BT:L("JN_NO_TRASH_DATA"), 18,
                self.fonts and self.fonts.small or GameFontHighlightSmall)
        else
            PlaceSectionHeader(BT:L("JN_TRASH_ENEMIES"))
            local enemies = C.FilterAbilities(trash.enemies, diff, self.roleFilter)
            C.SortTrashEntries(enemies)
            if #enemies == 0 then
                PlaceLine(BT:L("JN_NO_ROLE_TRASH_DATA"), 18,
                    self.fonts and self.fonts.small or GameFontHighlightSmall)
            else
                local lastEnemy = nil
                for _, entry in ipairs(enemies) do
                    local enemy = BT:Localize(entry.enemy) or entry.enemy or BT:L("JN_TRASH_UNKNOWN_ENEMY")
                    if enemy ~= lastEnemy then
                        PlaceSubHeader(enemy)
                        lastEnemy = enemy
                    end
                    PlaceLine(C.FormatTrashMechanic(entry), 18)
                    local description = BT:Localize(entry.description) or ""
                    if description ~= "" then
                        PlaceLine("|cffbbbbbb" .. description .. "|r", 30,
                            self.fonts and self.fonts.small or GameFontHighlightSmall)
                    end
                end
            end
        end

        body:SetHeight(math.max(-y, 10))
        self.scroll:SetVerticalScroll(previousScroll or 0)
        self:RefreshBriefingSidebar(data, diff)
        return
    end

    -- Dungeon / raid overview: encounter order, curated quick wipe checks and
    -- the currently active affix advice for every boss on one scrollable page.
    if view == "OVERVIEW" then
        PlaceSectionHeader(BT:L("JN_ACTIVE_AFFIXES"))
        if data.isRaid then
            PlaceLine(BT:L("JN_AFFIXES_NOT_APPLICABLE"), 18,
                self.fonts and self.fonts.small or GameFontHighlightSmall)
        else
            local activeNames = {}
            for _, affix in ipairs(D.activeAffixes or {}) do
                if affix.name and affix.name ~= "" then activeNames[#activeNames + 1] = affix.name end
            end
            if #activeNames > 0 then
                PlaceLine(table.concat(activeNames, ", "), 18)
            else
                PlaceLine(BT:L("JN_NO_ACTIVE_AFFIXES"), 18,
                    self.fonts and self.fonts.small or GameFontHighlightSmall)
            end
        end
        y = y - (sectionGap - itemGap)

        if not data.isRaid then
            local overviewTrash = dn and BT_TrashData and BT_TrashData[dn]
            local importantTrash = overviewTrash
                and C.FilterAbilities(overviewTrash.enemies, diff, self.roleFilter) or {}
            C.SortTrashEntries(importantTrash)
            PlaceSectionHeader(BT:L("TRASH_IMPORTANT_HEADER"))
            local placedTrash = 0
            for _, entry in ipairs(importantTrash) do
                if (tonumber(entry.priority) or 99) == 1 then
                    local enemy = BT:Localize(entry.enemy) or entry.enemy or BT:L("JN_TRASH_UNKNOWN_ENEMY")
                    PlaceLine("|cff66ccff" .. enemy .. "|r  " .. C.FormatTrashMechanic(entry), 18)
                    placedTrash = placedTrash + 1
                end
            end
            if placedTrash == 0 then
                PlaceLine(BT:L("JN_NO_ROLE_TRASH_DATA"), 18,
                    self.fonts and self.fonts.small or GameFontHighlightSmall)
            end
            y = y - (sectionGap - itemGap)
        end

        for bossIndex, overviewKey in ipairs(overviewKeys or {}) do
            local bossData = BT_BossData[overviewKey]
            PlaceOverviewBossHeader(overviewKey, bossIndex)
            PlaceLine("|cff66ccff" .. BT:L("JN_WIPE_MECHANICS") .. "|r", 18,
                self.fonts and self.fonts.small or GameFontHighlightSmall)
            local bossBullets = C.FilterTLDRBullets(bossData.tldr, diff, self.roleFilter)
            if #bossBullets == 0 then
                PlaceLine(BT:L("JN_NO_WIPE_MECHANICS"), 30,
                    self.fonts and self.fonts.small or GameFontHighlightSmall)
            else
                for _, entry in ipairs(bossBullets) do
                    PlaceLine(C.FormatBullet(entry), 30)
                end
            end

            if not data.isRaid then
                local bossAffixTips = D:GetActiveAffixTips(bossData)
                for _, affixEntry in ipairs(bossAffixTips) do
                    local affixName = affixEntry.name or ("Affix#" .. tostring(affixEntry.id or "?"))
                    PlaceLine("|cffffcc00" .. affixName .. "|r", 18,
                        self.fonts and self.fonts.small or GameFontHighlightSmall)
                    for _, affixTip in ipairs(affixEntry.tips or {}) do
                        local text = BT:Localize(affixTip) or ""
                        if text ~= "" then
                            PlaceLine("|cff999999\226\128\162|r  " .. text, 30,
                                self.fonts and self.fonts.small or GameFontHighlightSmall)
                        end
                    end
                end
            end
            y = y - sectionGap
        end

        body:SetHeight(math.max(-y, 10))
        self.scroll:SetVerticalScroll(previousScroll or 0)
        self:RefreshBriefingSidebar(data, diff)
        return
    end

    -- Boss detail views are separate screens (TLDR / Abilities / Tips); only
    -- the active one renders, and active affix tips ride with the TLDR view.

    -- ── TLDR ──
    local bullets = view == "TLDR" and C.FilterTLDRBullets(data.tldr, diff, self.roleFilter) or {}
    if #bullets > 0 then
        PlaceSectionHeader(BT:L("JN_SEC_TLDR"), self.shareTldrBtn)
        for _, entry in ipairs(bullets) do
            PlaceSelectableLine(C.FormatBullet(entry), SelectionID("TLDR", entry.sourceIndex))
        end
        y = y - (sectionGap - itemGap)
    end

    -- ── Abilities (cards with mouseover chat icon) ──
    local abilities, abilityIndices
    if view == "ABILITIES" then
        abilities, abilityIndices = C.FilterAbilities(data.abilities, diff, self.roleFilter)
    else
        abilities, abilityIndices = {}, {}
    end
    if #abilities > 0 then
        PlaceSectionHeader(BT:L("JN_SEC_ABILITIES"))
        local lastPhase = nil
        for abilityIndex, ab in ipairs(abilities) do
            if ab.phase ~= nil and ab.phase ~= lastPhase then
                lastPhase = ab.phase
                PlaceSubHeader(string.format(BT:L("JN_PHASE"), tostring(ab.phase)))
            end
            local card = self.cardPool:Acquire()
            if not card.title then
                card:EnableMouse(true)   -- hover only; wheel passes through
                card.title = card:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
                card.title:SetPoint("TOPLEFT", 26, 0)
                card.title:SetJustifyH("LEFT")
                card.title:SetJustifyV("TOP")
                card.title:SetWordWrap(true)
                card.desc = card:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
                card.desc:SetPoint("TOPLEFT", card.title, "BOTTOMLEFT", 0, -2)
                card.desc:SetJustifyH("LEFT")
                card.desc:SetJustifyV("TOP")
                card.desc:SetWordWrap(true)
                card.desc:SetNonSpaceWrap(true)

                card.selectBtn = CreateFrame("Button", nil, card)
                card.selectBtn:SetSize(20, 20)
                card.selectBtn:SetPoint("TOPLEFT", 0, 1)
                card.selectBtn.box = card.selectBtn:CreateTexture(nil, "ARTWORK")
                card.selectBtn.box:SetAllPoints()
                card.selectBtn.box:SetAtlas("checkbox-minimal")
                card.selectBtn.mark = card.selectBtn:CreateTexture(nil, "OVERLAY")
                card.selectBtn.mark:SetPoint("CENTER")
                card.selectBtn.mark:SetSize(14, 14)
                card.selectBtn.mark:SetAtlas("checkmark-minimal")
                card.selectBtn:SetScript("OnClick", function(button)
                    J:ToggleSelection(button:GetParent()._selectionId)
                end)

                card.shareBtn = CreateFrame("Button", nil, card)
                card.shareBtn:SetSize(18, 18)
                card.shareBtn:SetPoint("TOPRIGHT", 0, 0)
                local tex = card.shareBtn:CreateTexture(nil, "ARTWORK")
                tex:SetAllPoints()
                tex:SetTexture("Interface\\GossipFrame\\ChatBubbleGossipIcon")
                card.shareBtn:Hide()
                card.shareBtn:SetScript("OnClick", function(b)
                    J:ShareAbility(b:GetParent()._ab)
                end)
                card.shareBtn:SetScript("OnEnter", function(b)
                    b:Show()
                    GameTooltip:SetOwner(b, "ANCHOR_TOP")
                    GameTooltip:SetText(
                        string.format(BT:L("TOOLTIP_SHARE_ABILITY"), C.ResolveChannel():lower()), 1, 1, 1)
                    GameTooltip:Show()
                end)
                card.shareBtn:SetScript("OnLeave", function(b)
                    GameTooltip:Hide()
                    if not b:GetParent():IsMouseOver() then b:Hide() end
                end)
                card:SetScript("OnEnter", function(c) c.shareBtn:Show() end)
                card:SetScript("OnLeave", function(c)
                    if not c:IsMouseOver() then c.shareBtn:Hide() end
                end)
            end
            card._ab = ab
            card._selectionId = SelectionID("ABILITY", abilityIndices[abilityIndex])
            card.selectBtn.mark:SetShown(self:IsSelected(card._selectionId))
            card.shareBtn:Hide()
            card.title:SetFontObject(self.fonts and self.fonts.body or GameFontHighlight)
            card.desc:SetFontObject(self.fonts and self.fonts.small or GameFontHighlightSmall)
            card.title:SetWidth(W - 48)
            card.title:SetText(C.FormatAbilityTitle(ab))
            card.desc:SetWidth(W - 26)
            card.desc:SetText(BT:Localize(ab.description) or "")

            local titleH = StringHeight(card.title, 12 * scale)
            local descH = card.desc:GetStringHeight()
            if not descH or descH < 1 then descH = 0 end
            local cardH = math.max(20, titleH + (descH > 0 and (2 + descH) or 0))
            card:SetSize(W, cardH)
            card:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
            card:Show()
            y = y - cardH - itemGap - 2
        end
        y = y - (sectionGap - itemGap)
    end

    -- ── Tips ──
    local tips = view == "TIPS" and data.tips or nil
    if tips and #tips > 0 then
        PlaceSectionHeader(BT:L("JN_SEC_TIPS"), self.shareTipsBtn)
        for sourceIndex, tip in ipairs(tips) do
            local text = type(tip) == "table" and (BT:Localize(tip.text) or "") or (BT:Localize(tip) or "")
            if text ~= "" then
                PlaceSelectableLine("|cff999999\226\128\162|r  " .. text,
                    SelectionID("TIP", sourceIndex))
            end
        end
        y = y - (sectionGap - itemGap)
    end

    -- ── Active affix tips (TLDR view only) ──
    local affixTips = view == "TLDR" and D:GetActiveAffixTips(data) or {}
    if #affixTips > 0 then
        PlaceSectionHeader(BT:L("JN_SEC_AFFIXES"))
        for affixIndex, entry in ipairs(affixTips) do
            local name = entry.name or ("Affix#" .. tostring(entry.id or "?"))
            PlaceLine("|cffffcc00" .. name .. "|r")
            local groupKey = entry.id or entry.name or affixIndex
            for sourceIndex, tip in ipairs(entry.tips) do
                local text = BT:Localize(tip) or ""
                if text ~= "" then
                    PlaceSelectableLine("|cff999999\226\128\162|r  " .. text,
                        SelectionID("AFFIX", sourceIndex, groupKey))
                end
            end
        end
    end

    body:SetHeight(math.max(-y, 10))
    self.scroll:SetVerticalScroll(previousScroll or 0)
    self:RefreshBriefingSidebar(data, diff)
end

-- ─── Chat sharing ───────────────────────────────────────────────────────────

local function Truncate(msg)
    if #msg > 240 then
        return msg:sub(1, 237) .. "..."
    end
    return msg
end

function J:ShareSelected()
    local key = self.selectedKey
    local data = key and BT_BossData and BT_BossData[key]
    if not data then return end
    local records = self:BuildSelectedRecords(data, self.difficulty or "MYTHIC")
    if #records == 0 then return end
    local parts = {}
    for _, record in ipairs(records) do
        parts[#parts + 1] = record.chat
    end
    C.SendChatParts(tostring(key), parts, C.ResolveChannel())
end

function J:ShareTLDR()
    local key = self.selectedKey
    local data = key and BT_BossData and BT_BossData[key]
    if not data then return end
    local bullets = C.FilterTLDRBullets(data.tldr, self.difficulty, self.roleFilter)
    if #bullets == 0 then return end
    local parts = {}
    for _, entry in ipairs(bullets) do
        parts[#parts + 1] = (ROLE_CHAT_PREFIX[entry.role] or "") .. entry.text
    end
    C.SendChatParts(tostring(key), parts, C.ResolveChannel())
end

function J:ShareTips()
    local key = self.selectedKey
    local data = key and BT_BossData and BT_BossData[key]
    if not data or not data.tips or #data.tips == 0 then return end
    local parts = {}
    for _, tip in ipairs(data.tips) do
        local text = type(tip) == "table" and (BT:Localize(tip.text) or "") or (BT:Localize(tip) or "")
        if text ~= "" then parts[#parts + 1] = text end
    end
    if #parts == 0 then return end
    C.SendChatParts(tostring(key), parts, C.ResolveChannel())
end

function J:ShareAbility(ab)
    local key = self.selectedKey
    if not ab or not key then return end
    local title = BT:Localize(ab.title) or ""
    local desc = BT:Localize(ab.description) or ""
    local msg = "[" .. tostring(key) .. "] " .. title
    if desc ~= "" then
        msg = msg .. ": " .. desc
    end
    C.PreFillChat(Truncate(msg), C.ResolveChannel())
end

-- ─── Entry point ────────────────────────────────────────────────────────────

--- /bosstactics journal, the options button, and the panel's book icon.
--- No combat gate — read-only window, opening is always manual.
function BT:OpenJournal(bossKey, difficulty)
    local J2 = self.Journal
    local w = J2:GetWindow()
    if w:IsShown() and not bossKey then
        w:Hide()
        return
    end
    if bossKey and BT_BossData and BT_BossData[bossKey] then
        J2.selectedKey = bossKey
    end
    if difficulty == "LFR" then difficulty = "NORMAL" end
    if difficulty ~= "NORMAL" and difficulty ~= "HEROIC" and difficulty ~= "MYTHIC" then
        difficulty = J2.difficulty or DefaultDifficulty()
    end
    local selectedData = J2.selectedKey and BT_BossData and BT_BossData[J2.selectedKey]
    if C.IsRaidData(selectedData) or C.IsDungeonDifficultySelectionEnabled() then
        J2.requestedDifficulty = difficulty
    elseif not J2.requestedDifficulty then
        J2.requestedDifficulty = difficulty
    end
    J2.difficulty = C.ResolveContentDifficulty(selectedData, difficulty)
    w:Show()
    J2:RefreshAll()
end
